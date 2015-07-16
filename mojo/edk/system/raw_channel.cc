// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/raw_channel.h"

#include <string.h>

#include <algorithm>

#include "base/bind.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/transport_data.h"

namespace mojo {
namespace system {

const size_t kReadSize = 4096;

// RawChannel::ReadBuffer ------------------------------------------------------

RawChannel::ReadBuffer::ReadBuffer() : buffer_(kReadSize), num_valid_bytes_(0) {
}

RawChannel::ReadBuffer::~ReadBuffer() {
}

void RawChannel::ReadBuffer::GetBuffer(char** addr, size_t* size) {
  DCHECK_GE(buffer_.size(), num_valid_bytes_ + kReadSize);
  *addr = &buffer_[0] + num_valid_bytes_;
  *size = kReadSize;
}

// RawChannel::WriteBuffer -----------------------------------------------------

RawChannel::WriteBuffer::WriteBuffer(size_t serialized_platform_handle_size)
    : serialized_platform_handle_size_(serialized_platform_handle_size),
      platform_handles_offset_(0),
      data_offset_(0) {
}

RawChannel::WriteBuffer::~WriteBuffer() {
  message_queue_.Clear();
}

bool RawChannel::WriteBuffer::HavePlatformHandlesToSend() const {
  if (message_queue_.IsEmpty())
    return false;

  const TransportData* transport_data =
      message_queue_.PeekMessage()->transport_data();
  if (!transport_data)
    return false;

  const embedder::PlatformHandleVector* all_platform_handles =
      transport_data->platform_handles();
  if (!all_platform_handles) {
    DCHECK_EQ(platform_handles_offset_, 0u);
    return false;
  }
  if (platform_handles_offset_ >= all_platform_handles->size()) {
    DCHECK_EQ(platform_handles_offset_, all_platform_handles->size());
    return false;
  }

  return true;
}

void RawChannel::WriteBuffer::GetPlatformHandlesToSend(
    size_t* num_platform_handles,
    embedder::PlatformHandle** platform_handles,
    void** serialization_data) {
  DCHECK(HavePlatformHandlesToSend());

  MessageInTransit* message = message_queue_.PeekMessage();
  TransportData* transport_data = message->transport_data();
  embedder::PlatformHandleVector* all_platform_handles =
      transport_data->platform_handles();
  *num_platform_handles =
      all_platform_handles->size() - platform_handles_offset_;
  *platform_handles = &(*all_platform_handles)[platform_handles_offset_];

  if (serialized_platform_handle_size_ > 0) {
    size_t serialization_data_offset =
        transport_data->platform_handle_table_offset();
    serialization_data_offset +=
        platform_handles_offset_ * serialized_platform_handle_size_;
    *serialization_data = static_cast<char*>(transport_data->buffer()) +
                          serialization_data_offset;
  } else {
    *serialization_data = nullptr;
  }
}

void RawChannel::WriteBuffer::GetBuffers(std::vector<Buffer>* buffers) const {
  buffers->clear();

  if (message_queue_.IsEmpty())
    return;

  const MessageInTransit* message = message_queue_.PeekMessage();
  DCHECK_LT(data_offset_, message->total_size());
  size_t bytes_to_write = message->total_size() - data_offset_;

  size_t transport_data_buffer_size =
      message->transport_data() ? message->transport_data()->buffer_size() : 0;

  if (!transport_data_buffer_size) {
    // Only write from the main buffer.
    DCHECK_LT(data_offset_, message->main_buffer_size());
    DCHECK_LE(bytes_to_write, message->main_buffer_size());
    Buffer buffer = {
        static_cast<const char*>(message->main_buffer()) + data_offset_,
        bytes_to_write};
    buffers->push_back(buffer);
    return;
  }

  if (data_offset_ >= message->main_buffer_size()) {
    // Only write from the transport data buffer.
    DCHECK_LT(data_offset_ - message->main_buffer_size(),
              transport_data_buffer_size);
    DCHECK_LE(bytes_to_write, transport_data_buffer_size);
    Buffer buffer = {
        static_cast<const char*>(message->transport_data()->buffer()) +
            (data_offset_ - message->main_buffer_size()),
        bytes_to_write};
    buffers->push_back(buffer);
    return;
  }

  // TODO(vtl): We could actually send out buffers from multiple messages, with
  // the "stopping" condition being reaching a message with platform handles
  // attached.

  // Write from both buffers.
  DCHECK_EQ(bytes_to_write, message->main_buffer_size() - data_offset_ +
                                transport_data_buffer_size);
  Buffer buffer1 = {
      static_cast<const char*>(message->main_buffer()) + data_offset_,
      message->main_buffer_size() - data_offset_};
  buffers->push_back(buffer1);
  Buffer buffer2 = {
      static_cast<const char*>(message->transport_data()->buffer()),
      transport_data_buffer_size};
  buffers->push_back(buffer2);
}

// RawChannel ------------------------------------------------------------------

RawChannel::RawChannel()
    : message_loop_for_io_(nullptr),
      delegate_(nullptr),
      set_on_shutdown_(nullptr),
      write_stopped_(false),
      weak_ptr_factory_(this) {
}

RawChannel::~RawChannel() {
  DCHECK(!read_buffer_);
  DCHECK(!write_buffer_);

  // No need to take the |write_lock_| here -- if there are still weak pointers
  // outstanding, then we're hosed anyway (since we wouldn't be able to
  // invalidate them cleanly, since we might not be on the I/O thread).
  DCHECK(!weak_ptr_factory_.HasWeakPtrs());
}

void RawChannel::Init(Delegate* delegate) {
  DCHECK(delegate);

  DCHECK(!delegate_);
  delegate_ = delegate;

  CHECK_EQ(base::MessageLoop::current()->type(), base::MessageLoop::TYPE_IO);
  DCHECK(!message_loop_for_io_);
  message_loop_for_io_ =
      static_cast<base::MessageLoopForIO*>(base::MessageLoop::current());

  // No need to take the lock. No one should be using us yet.
  DCHECK(!read_buffer_);
  read_buffer_.reset(new ReadBuffer);
  DCHECK(!write_buffer_);
  write_buffer_.reset(new WriteBuffer(GetSerializedPlatformHandleSize()));

  OnInit();

  IOResult io_result = ScheduleRead();
  if (io_result != IO_PENDING) {
    // This will notify the delegate about the read failure. Although we're on
    // the I/O thread, don't call it in the nested context.
    message_loop_for_io_->PostTask(
        FROM_HERE, base::Bind(&RawChannel::OnReadCompleted,
                              weak_ptr_factory_.GetWeakPtr(), io_result, 0));
  }
  // Note: |ScheduleRead()| failure is treated as a read failure (by notifying
  // the delegate), not an initialization failure.
}

void RawChannel::Shutdown() {
  DCHECK_EQ(base::MessageLoop::current(), message_loop_for_io_);

  base::AutoLock locker(write_lock_);

  LOG_IF(WARNING, !write_buffer_->message_queue_.IsEmpty())
      << "Shutting down RawChannel with write buffer nonempty";

  // Reset the delegate so that it won't receive further calls.
  delegate_ = nullptr;
  if (set_on_shutdown_) {
    *set_on_shutdown_ = true;
    set_on_shutdown_ = nullptr;
  }
  write_stopped_ = true;
  weak_ptr_factory_.InvalidateWeakPtrs();

  OnShutdownNoLock(read_buffer_.Pass(), write_buffer_.Pass());
}

// Reminder: This must be thread-safe.
bool RawChannel::WriteMessage(scoped_ptr<MessageInTransit> message) {
  DCHECK(message);

  base::AutoLock locker(write_lock_);
  if (write_stopped_)
    return false;

  if (!write_buffer_->message_queue_.IsEmpty()) {
    EnqueueMessageNoLock(message.Pass());
    return true;
  }

  EnqueueMessageNoLock(message.Pass());
  DCHECK_EQ(write_buffer_->data_offset_, 0u);

  size_t platform_handles_written = 0;
  size_t bytes_written = 0;
  IOResult io_result = WriteNoLock(&platform_handles_written, &bytes_written);
  if (io_result == IO_PENDING)
    return true;

  bool result = OnWriteCompletedNoLock(io_result, platform_handles_written,
                                       bytes_written);
  if (!result) {
    // Even if we're on the I/O thread, don't call |OnError()| in the nested
    // context.
    message_loop_for_io_->PostTask(
        FROM_HERE,
        base::Bind(&RawChannel::CallOnError, weak_ptr_factory_.GetWeakPtr(),
                   Delegate::ERROR_WRITE));
  }

  return result;
}

// Reminder: This must be thread-safe.
bool RawChannel::IsWriteBufferEmpty() {
  base::AutoLock locker(write_lock_);
  return write_buffer_->message_queue_.IsEmpty();
}

void RawChannel::OnReadCompleted(IOResult io_result, size_t bytes_read) {
  DCHECK_EQ(base::MessageLoop::current(), message_loop_for_io_);

  // Keep reading data in a loop, and dispatch messages if enough data is
  // received. Exit the loop if any of the following happens:
  //   - one or more messages were dispatched;
  //   - the last read failed, was a partial read or would block;
  //   - |Shutdown()| was called.
  do {
    switch (io_result) {
      case IO_SUCCEEDED:
        break;
      case IO_FAILED_SHUTDOWN:
      case IO_FAILED_BROKEN:
      case IO_FAILED_UNKNOWN:
        CallOnError(ReadIOResultToError(io_result));
        return;  // |this| may have been destroyed in |CallOnError()|.
      case IO_PENDING:
        NOTREACHED();
        return;
    }

    read_buffer_->num_valid_bytes_ += bytes_read;

    // Dispatch all the messages that we can.
    bool did_dispatch_message = false;
    // Tracks the offset of the first undispatched message in |read_buffer_|.
    // Currently, we copy data to ensure that this is zero at the beginning.
    size_t read_buffer_start = 0;
    size_t remaining_bytes = read_buffer_->num_valid_bytes_;
    size_t message_size;
    // Note that we rely on short-circuit evaluation here:
    //   - |read_buffer_start| may be an invalid index into
    //     |read_buffer_->buffer_| if |remaining_bytes| is zero.
    //   - |message_size| is only valid if |GetNextMessageSize()| returns true.
    // TODO(vtl): Use |message_size| more intelligently (e.g., to request the
    // next read).
    // TODO(vtl): Validate that |message_size| is sane.
    while (remaining_bytes > 0 && MessageInTransit::GetNextMessageSize(
                                      &read_buffer_->buffer_[read_buffer_start],
                                      remaining_bytes, &message_size) &&
           remaining_bytes >= message_size) {
      MessageInTransit::View message_view(
          message_size, &read_buffer_->buffer_[read_buffer_start]);
      DCHECK_EQ(message_view.total_size(), message_size);

      const char* error_message = nullptr;
      if (!message_view.IsValid(GetSerializedPlatformHandleSize(),
                                &error_message)) {
        DCHECK(error_message);
        LOG(ERROR) << "Received invalid message: " << error_message;
        CallOnError(Delegate::ERROR_READ_BAD_MESSAGE);
        return;  // |this| may have been destroyed in |CallOnError()|.
      }

      if (message_view.type() == MessageInTransit::Type::RAW_CHANNEL) {
        if (!OnReadMessageForRawChannel(message_view)) {
          CallOnError(Delegate::ERROR_READ_BAD_MESSAGE);
          return;  // |this| may have been destroyed in |CallOnError()|.
        }
      } else {
        embedder::ScopedPlatformHandleVectorPtr platform_handles;
        if (message_view.transport_data_buffer()) {
          size_t num_platform_handles;
          const void* platform_handle_table;
          TransportData::GetPlatformHandleTable(
              message_view.transport_data_buffer(), &num_platform_handles,
              &platform_handle_table);

          if (num_platform_handles > 0) {
            platform_handles =
                GetReadPlatformHandles(num_platform_handles,
                                       platform_handle_table).Pass();
            if (!platform_handles) {
              LOG(ERROR) << "Invalid number of platform handles received";
              CallOnError(Delegate::ERROR_READ_BAD_MESSAGE);
              return;  // |this| may have been destroyed in |CallOnError()|.
            }
          }
        }

        // TODO(vtl): In the case that we aren't expecting any platform handles,
        // for the POSIX implementation, we should confirm that none are stored.

        // Dispatch the message.
        // Detect the case when |Shutdown()| is called; subsequent destruction
        // is also permitted then.
        bool shutdown_called = false;
        DCHECK(!set_on_shutdown_);
        set_on_shutdown_ = &shutdown_called;
        DCHECK(delegate_);
        delegate_->OnReadMessage(message_view, platform_handles.Pass());
        if (shutdown_called)
          return;
        set_on_shutdown_ = nullptr;
      }

      did_dispatch_message = true;

      // Update our state.
      read_buffer_start += message_size;
      remaining_bytes -= message_size;
    }

    if (read_buffer_start > 0) {
      // Move data back to start.
      read_buffer_->num_valid_bytes_ = remaining_bytes;
      if (read_buffer_->num_valid_bytes_ > 0) {
        memmove(&read_buffer_->buffer_[0],
                &read_buffer_->buffer_[read_buffer_start], remaining_bytes);
      }
      read_buffer_start = 0;
    }

    if (read_buffer_->buffer_.size() - read_buffer_->num_valid_bytes_ <
        kReadSize) {
      // Use power-of-2 buffer sizes.
      // TODO(vtl): Make sure the buffer doesn't get too large (and enforce the
      // maximum message size to whatever extent necessary).
      // TODO(vtl): We may often be able to peek at the header and get the real
      // required extra space (which may be much bigger than |kReadSize|).
      size_t new_size = std::max(read_buffer_->buffer_.size(), kReadSize);
      while (new_size < read_buffer_->num_valid_bytes_ + kReadSize)
        new_size *= 2;

      // TODO(vtl): It's suboptimal to zero out the fresh memory.
      read_buffer_->buffer_.resize(new_size, 0);
    }

    // (1) If we dispatched any messages, stop reading for now (and let the
    // message loop do its thing for another round).
    // TODO(vtl): Is this the behavior we want? (Alternatives: i. Dispatch only
    // a single message. Risks: slower, more complex if we want to avoid lots of
    // copying. ii. Keep reading until there's no more data and dispatch all the
    // messages we can. Risks: starvation of other users of the message loop.)
    // (2) If we didn't max out |kReadSize|, stop reading for now.
    bool schedule_for_later = did_dispatch_message || bytes_read < kReadSize;
    bytes_read = 0;
    io_result = schedule_for_later ? ScheduleRead() : Read(&bytes_read);
  } while (io_result != IO_PENDING);
}

void RawChannel::OnWriteCompleted(IOResult io_result,
                                  size_t platform_handles_written,
                                  size_t bytes_written) {
  DCHECK_EQ(base::MessageLoop::current(), message_loop_for_io_);
  DCHECK_NE(io_result, IO_PENDING);

  bool did_fail = false;
  {
    base::AutoLock locker(write_lock_);
    DCHECK_EQ(write_stopped_, write_buffer_->message_queue_.IsEmpty());

    if (write_stopped_) {
      NOTREACHED();
      return;
    }

    did_fail = !OnWriteCompletedNoLock(io_result, platform_handles_written,
                                       bytes_written);
  }

  if (did_fail) {
    CallOnError(Delegate::ERROR_WRITE);
    return;  // |this| may have been destroyed in |CallOnError()|.
  }
}

void RawChannel::EnqueueMessageNoLock(scoped_ptr<MessageInTransit> message) {
  write_lock_.AssertAcquired();
  write_buffer_->message_queue_.AddMessage(message.Pass());
}

bool RawChannel::OnReadMessageForRawChannel(
    const MessageInTransit::View& message_view) {
  // No non-implementation specific |RawChannel| control messages.
  LOG(ERROR) << "Invalid control message (subtype " << message_view.subtype()
             << ")";
  return false;
}

// static
RawChannel::Delegate::Error RawChannel::ReadIOResultToError(
    IOResult io_result) {
  switch (io_result) {
    case IO_FAILED_SHUTDOWN:
      return Delegate::ERROR_READ_SHUTDOWN;
    case IO_FAILED_BROKEN:
      return Delegate::ERROR_READ_BROKEN;
    case IO_FAILED_UNKNOWN:
      return Delegate::ERROR_READ_UNKNOWN;
    case IO_SUCCEEDED:
    case IO_PENDING:
      NOTREACHED();
      break;
  }
  return Delegate::ERROR_READ_UNKNOWN;
}

void RawChannel::CallOnError(Delegate::Error error) {
  DCHECK_EQ(base::MessageLoop::current(), message_loop_for_io_);
  // TODO(vtl): Add a "write_lock_.AssertNotAcquired()"?
  if (delegate_) {
    delegate_->OnError(error);
    return;  // |this| may have been destroyed in |OnError()|.
  }
}

bool RawChannel::OnWriteCompletedNoLock(IOResult io_result,
                                        size_t platform_handles_written,
                                        size_t bytes_written) {
  write_lock_.AssertAcquired();

  DCHECK(!write_stopped_);
  DCHECK(!write_buffer_->message_queue_.IsEmpty());

  if (io_result == IO_SUCCEEDED) {
    write_buffer_->platform_handles_offset_ += platform_handles_written;
    write_buffer_->data_offset_ += bytes_written;

    MessageInTransit* message = write_buffer_->message_queue_.PeekMessage();
    if (write_buffer_->data_offset_ >= message->total_size()) {
      // Complete write.
      CHECK_EQ(write_buffer_->data_offset_, message->total_size());
      write_buffer_->message_queue_.DiscardMessage();
      write_buffer_->platform_handles_offset_ = 0;
      write_buffer_->data_offset_ = 0;

      if (write_buffer_->message_queue_.IsEmpty())
        return true;
    }

    // Schedule the next write.
    io_result = ScheduleWriteNoLock();
    if (io_result == IO_PENDING)
      return true;
    DCHECK_NE(io_result, IO_SUCCEEDED);
  }

  write_stopped_ = true;
  write_buffer_->message_queue_.Clear();
  write_buffer_->platform_handles_offset_ = 0;
  write_buffer_->data_offset_ = 0;
  return false;
}

}  // namespace system
}  // namespace mojo
