// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/raw_channel.h"

#include <errno.h>
#include <sys/uio.h>
#include <unistd.h>

#include <algorithm>
#include <deque>
#include <iterator>
#include <memory>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_handle_watcher.h"
#include "mojo/edk/platform/platform_pipe_utils_posix.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/transport_data.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/weak_ptr.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::kPlatformPipeMaxNumHandles;
using mojo::platform::PlatformHandle;
using mojo::platform::PlatformHandleWatcher;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::MakeUnique;
using mojo::util::MutexLocker;
using mojo::util::WeakPtrFactory;

namespace mojo {
namespace system {

namespace {

class RawChannelPosix final : public RawChannel {
 public:
  explicit RawChannelPosix(ScopedPlatformHandle handle);
  ~RawChannelPosix() override;

  // |RawChannel| public methods:
  size_t GetSerializedPlatformHandleSize() const override;

 private:
  // |RawChannel| protected methods:
  // Actually override this so that we can send multiple messages with (only)
  // FDs if necessary.
  void EnqueueMessageNoLock(std::unique_ptr<MessageInTransit> message) override
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(write_mutex());
  // Override this to handle those extra FD-only messages.
  bool OnReadMessageForRawChannel(
      const MessageInTransit::View& message_view) override;
  IOResult Read(size_t* bytes_read) override;
  IOResult ScheduleRead() override;
  std::unique_ptr<std::vector<ScopedPlatformHandle>> GetReadPlatformHandles(
      size_t num_platform_handles,
      const void* platform_handle_table) override;
  IOResult WriteNoLock(size_t* platform_handles_written,
                       size_t* bytes_written) override;
  IOResult ScheduleWriteNoLock() override;
  void OnInit() override;
  void OnShutdownNoLock(std::unique_ptr<ReadBuffer> read_buffer,
                        std::unique_ptr<WriteBuffer> write_buffer) override;

  // Called when we can read/write from/to |fd_| without blocking.
  void OnCanReadWithoutBlocking();
  void OnCanWriteWithoutBlocking();

  // Implements most of |Read()| (except for a bit of clean-up):
  IOResult ReadImpl(size_t* bytes_read);

  // Watches for |fd_| to become writable. Must be called on the I/O thread.
  void WaitToWrite();

  ScopedPlatformHandle fd_;

  // The following members are only used on the I/O thread:
  std::unique_ptr<PlatformHandleWatcher::WatchToken> read_watch_token_;
  std::unique_ptr<PlatformHandleWatcher::WatchToken> write_watch_token_;

  bool pending_read_;

  std::deque<ScopedPlatformHandle> read_platform_handles_;

  bool pending_write_ MOJO_GUARDED_BY(write_mutex());

  // This is used for posting tasks from write threads to the I/O thread. The
  // weak pointers it produces are only used/invalidated on the I/O thread.
  WeakPtrFactory<RawChannelPosix> weak_ptr_factory_
      MOJO_GUARDED_BY(write_mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(RawChannelPosix);
};

RawChannelPosix::RawChannelPosix(ScopedPlatformHandle handle)
    : fd_(handle.Pass()),
      pending_read_(false),
      pending_write_(false),
      weak_ptr_factory_(this) {
  DCHECK(fd_.is_valid());
}

RawChannelPosix::~RawChannelPosix() {
  DCHECK(!pending_read_);
  DCHECK(!pending_write_);

  // No need to take |write_mutex()| here -- if there are still weak pointers
  // outstanding, then we're hosed anyway (since we wouldn't be able to
  // invalidate them cleanly, since we might not be on the I/O thread).
  DCHECK(!weak_ptr_factory_.HasWeakPtrs());

  // These must have been shut down/destroyed on the I/O thread.
  DCHECK(!read_watch_token_);
  DCHECK(!write_watch_token_);
}

size_t RawChannelPosix::GetSerializedPlatformHandleSize() const {
  // We don't actually need any space on POSIX (since we just send FDs).
  return 0;
}

void RawChannelPosix::EnqueueMessageNoLock(
    std::unique_ptr<MessageInTransit> message) {
  if (message->transport_data()) {
    std::vector<ScopedPlatformHandle>* const platform_handles =
        message->transport_data()->platform_handles();
    if (platform_handles &&
        platform_handles->size() > kPlatformPipeMaxNumHandles) {
      // We can't attach all the FDs to a single message, so we have to "split"
      // the message. Send as many control messages as needed first with FDs
      // attached (and no data).
      size_t i = 0;
      for (; platform_handles->size() - i > kPlatformPipeMaxNumHandles;
           i += kPlatformPipeMaxNumHandles) {
        std::unique_ptr<MessageInTransit> fd_message(new MessageInTransit(
            MessageInTransit::Type::RAW_CHANNEL,
            MessageInTransit::Subtype::RAW_CHANNEL_POSIX_EXTRA_PLATFORM_HANDLES,
            0, nullptr));
        using IteratorType = std::vector<ScopedPlatformHandle>::iterator;
        std::unique_ptr<std::vector<ScopedPlatformHandle>> fds(
            MakeUnique<std::vector<ScopedPlatformHandle>>(
                std::move_iterator<IteratorType>(platform_handles->begin() + i),
                std::move_iterator<IteratorType>(platform_handles->begin() + i +
                                                 kPlatformPipeMaxNumHandles)));
        fd_message->SetTransportData(MakeUnique<TransportData>(
            std::move(fds), GetSerializedPlatformHandleSize()));
        RawChannel::EnqueueMessageNoLock(std::move(fd_message));
      }

      // Remove the handles that we "moved" into the other messages.
      platform_handles->erase(platform_handles->begin(),
                              platform_handles->begin() + i);
    }
  }

  RawChannel::EnqueueMessageNoLock(std::move(message));
}

bool RawChannelPosix::OnReadMessageForRawChannel(
    const MessageInTransit::View& message_view) {
  DCHECK_EQ(message_view.type(), MessageInTransit::Type::RAW_CHANNEL);

  if (message_view.subtype() ==
      MessageInTransit::Subtype::RAW_CHANNEL_POSIX_EXTRA_PLATFORM_HANDLES) {
    // We don't need to do anything. |RawChannel| won't extract the platform
    // handles, and they'll be accumulated in |Read()|.
    return true;
  }

  return RawChannel::OnReadMessageForRawChannel(message_view);
}

RawChannel::IOResult RawChannelPosix::Read(size_t* bytes_read) {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());
  DCHECK(!pending_read_);

  IOResult rv = ReadImpl(bytes_read);
  if (rv != IO_SUCCEEDED && rv != IO_PENDING) {
    // Make sure that |OnCanReadWithoutBlocking()| won't be called again.
    read_watch_token_.reset();
  }
  return rv;
}

RawChannel::IOResult RawChannelPosix::ScheduleRead() {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());
  DCHECK(!pending_read_);

  pending_read_ = true;

  return IO_PENDING;
}

std::unique_ptr<std::vector<ScopedPlatformHandle>>
RawChannelPosix::GetReadPlatformHandles(size_t num_platform_handles,
                                        const void* /*platform_handle_table*/) {
  DCHECK_GT(num_platform_handles, 0u);

  if (read_platform_handles_.size() < num_platform_handles) {
    read_platform_handles_.clear();
    return nullptr;
  }

  auto rv = MakeUnique<std::vector<ScopedPlatformHandle>>(num_platform_handles);
  using IteratorType = std::deque<ScopedPlatformHandle>::iterator;
  rv->assign(std::move_iterator<IteratorType>(read_platform_handles_.begin()),
             std::move_iterator<IteratorType>(read_platform_handles_.begin() +
                                              num_platform_handles));
  read_platform_handles_.erase(
      read_platform_handles_.begin(),
      read_platform_handles_.begin() + num_platform_handles);
  return rv;
}

RawChannel::IOResult RawChannelPosix::WriteNoLock(
    size_t* platform_handles_written,
    size_t* bytes_written) {
  write_mutex().AssertHeld();

  DCHECK(!pending_write_);

  size_t num_platform_handles = 0;
  ssize_t write_result;
  if (write_buffer_no_lock()->HavePlatformHandlesToSend()) {
    PlatformHandle* platform_handles;
    void* serialization_data;  // Actually unused.
    write_buffer_no_lock()->GetPlatformHandlesToSend(
        &num_platform_handles, &platform_handles, &serialization_data);
    DCHECK_GT(num_platform_handles, 0u);
    DCHECK_LE(num_platform_handles, kPlatformPipeMaxNumHandles);
    DCHECK(platform_handles);

    // TODO(vtl): Reduce code duplication. (This is duplicated from below.)
    std::vector<WriteBuffer::Buffer> buffers;
    write_buffer_no_lock()->GetBuffers(&buffers);
    DCHECK(!buffers.empty());
    const size_t kMaxBufferCount = 10;
    iovec iov[kMaxBufferCount];
    size_t buffer_count = std::min(buffers.size(), kMaxBufferCount);
    for (size_t i = 0; i < buffer_count; ++i) {
      iov[i].iov_base = const_cast<char*>(buffers[i].addr);
      iov[i].iov_len = buffers[i].size;
    }

    write_result = PlatformPipeSendmsgWithHandles(
        fd_.get(), iov, buffer_count, platform_handles, num_platform_handles);
    if (write_result >= 0) {
      for (size_t i = 0; i < num_platform_handles; i++)
        platform_handles[i].CloseIfNecessary();
    }
  } else {
    std::vector<WriteBuffer::Buffer> buffers;
    write_buffer_no_lock()->GetBuffers(&buffers);
    DCHECK(!buffers.empty());

    if (buffers.size() == 1) {
      write_result =
          PlatformPipeWrite(fd_.get(), buffers[0].addr, buffers[0].size);
    } else {
      const size_t kMaxBufferCount = 10;
      iovec iov[kMaxBufferCount];
      size_t buffer_count = std::min(buffers.size(), kMaxBufferCount);
      for (size_t i = 0; i < buffer_count; ++i) {
        iov[i].iov_base = const_cast<char*>(buffers[i].addr);
        iov[i].iov_len = buffers[i].size;
      }

      write_result = PlatformPipeWritev(fd_.get(), iov, buffer_count);
    }
  }

  if (write_result >= 0) {
    *platform_handles_written = num_platform_handles;
    *bytes_written = static_cast<size_t>(write_result);
    return IO_SUCCEEDED;
  }

  if (errno == EPIPE)
    return IO_FAILED_SHUTDOWN;

  if (errno != EAGAIN && errno != EWOULDBLOCK) {
    int saved_errno = errno;  // Don't rely on logging preserving errno.
    LOG(WARNING) << "sendmsg/write/writev: errno = " << saved_errno;
    return IO_FAILED_UNKNOWN;
  }

  return ScheduleWriteNoLock();
}

RawChannel::IOResult RawChannelPosix::ScheduleWriteNoLock() {
  write_mutex().AssertHeld();

  DCHECK(!pending_write_);

  // Set up to wait for the FD to become writable.
  // If we're not on the I/O thread, we have to post a task to do this.
  if (!io_task_runner()->RunsTasksOnCurrentThread()) {
    // TODO(vtl): Need C++14 lambdas sooner.
    auto weak_self = weak_ptr_factory_.GetWeakPtr();
    io_task_runner()->PostTask([weak_self]() {
      if (weak_self)
        weak_self->WaitToWrite();
    });
    pending_write_ = true;
    return IO_PENDING;
  }

  write_watch_token_ = io_watcher()->Watch(
      fd_.get(), false, nullptr, [this]() { OnCanWriteWithoutBlocking(); });
  if (!write_watch_token_)
    return IO_FAILED_UNKNOWN;

  pending_write_ = true;
  return IO_PENDING;
}

void RawChannelPosix::OnInit() {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());

  DCHECK(!read_watch_token_);
  DCHECK(!write_watch_token_);

  // I don't know how this can fail (unless |fd_| is bad, in which case it's a
  // bug in our code). I also don't know if |WatchFileDescriptor()| actually
  // fails cleanly.
  read_watch_token_ = io_watcher()->Watch(
      fd_.get(), true, [this]() { OnCanReadWithoutBlocking(); }, nullptr);
  CHECK(read_watch_token_);
}

void RawChannelPosix::OnShutdownNoLock(
    std::unique_ptr<ReadBuffer> /*read_buffer*/,
    std::unique_ptr<WriteBuffer> /*write_buffer*/) {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());
  write_mutex().AssertHeld();

  read_watch_token_.reset();   // This will stop watching (if necessary).
  write_watch_token_.reset();  // This will stop watching (if necessary).

  pending_read_ = false;
  pending_write_ = false;

  DCHECK(fd_.is_valid());
  fd_.reset();

  weak_ptr_factory_.InvalidateWeakPtrs();
}

void RawChannelPosix::OnCanReadWithoutBlocking() {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());

  if (!pending_read_) {
    NOTREACHED();
    return;
  }

  pending_read_ = false;
  size_t bytes_read = 0;
  IOResult io_result = Read(&bytes_read);
  if (io_result != IO_PENDING) {
    OnReadCompleted(io_result, bytes_read);
    // TODO(vtl): If we weren't destroyed, we'd like to do
    //
    //   DCHECK(!read_watch_token_ || pending_read_);
    //
    // On failure, |read_watch_token_| must have been reset; on success, we
    // assume that |OnReadCompleted()| always schedules another read. Otherwise,
    // we could end up spinning -- getting |OnCanReadWithoutBlocking()| again
    // and again but not doing any actual read.
    // TODO(yzshen): An alternative is to stop watching if RawChannel doesn't
    // schedule a new read. But that code won't be reached under the current
    // RawChannel implementation.
    return;  // |this| may have been destroyed in |OnReadCompleted()|.
  }

  DCHECK(pending_read_);
}

void RawChannelPosix::OnCanWriteWithoutBlocking() {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());

  // Our write-watching is one-shot, so we can get rid of the token.
  DCHECK(write_watch_token_);
  write_watch_token_.reset();

  IOResult io_result;
  size_t platform_handles_written = 0;
  size_t bytes_written = 0;
  {
    MutexLocker locker(&write_mutex());

    DCHECK(pending_write_);

    pending_write_ = false;
    io_result = WriteNoLock(&platform_handles_written, &bytes_written);
  }

  if (io_result != IO_PENDING) {
    OnWriteCompleted(io_result, platform_handles_written, bytes_written);
    return;  // |this| may have been destroyed in |OnWriteCompleted()|.
  }
}

RawChannel::IOResult RawChannelPosix::ReadImpl(size_t* bytes_read) {
  char* buffer = nullptr;
  size_t bytes_to_read = 0;
  read_buffer()->GetBuffer(&buffer, &bytes_to_read);

  size_t old_num_platform_handles = read_platform_handles_.size();
  ssize_t read_result = PlatformPipeRecvmsg(fd_.get(), buffer, bytes_to_read,
                                            &read_platform_handles_);
  if (read_platform_handles_.size() > old_num_platform_handles) {
    DCHECK_LE(read_platform_handles_.size() - old_num_platform_handles,
              kPlatformPipeMaxNumHandles);

    // We should never accumulate more than |TransportData::kMaxPlatformHandles
    // + kPlatformPipeMaxNumHandles| handles. (The latter part is possible
    // because we could have accumulated all the handles for a message, then
    // received the message data plus the first set of handles for the next
    // message in the subsequent |recvmsg()|.)
    if (read_platform_handles_.size() >
        (TransportData::GetMaxPlatformHandles() + kPlatformPipeMaxNumHandles)) {
      LOG(ERROR) << "Received too many platform handles";
      read_platform_handles_.clear();
      return IO_FAILED_UNKNOWN;
    }
  }

  if (read_result > 0) {
    *bytes_read = static_cast<size_t>(read_result);
    return IO_SUCCEEDED;
  }

  // |read_result == 0| means "end of file".
  if (read_result == 0)
    return IO_FAILED_SHUTDOWN;

  if (errno == EAGAIN || errno == EWOULDBLOCK)
    return ScheduleRead();

  if (errno == ECONNRESET)
    return IO_FAILED_BROKEN;

  int saved_errno = errno;  // Don't rely on logging preserving errno.
  LOG(WARNING) << "recvmsg: errno = " << saved_errno;
  return IO_FAILED_UNKNOWN;
}

void RawChannelPosix::WaitToWrite() {
  DCHECK(io_task_runner()->RunsTasksOnCurrentThread());

  DCHECK(!write_watch_token_);

  write_watch_token_ = io_watcher()->Watch(
      fd_.get(), false, nullptr, [this]() { OnCanWriteWithoutBlocking(); });
  if (!write_watch_token_) {
    {
      MutexLocker locker(&write_mutex());

      DCHECK(pending_write_);
      pending_write_ = false;
    }
    OnWriteCompleted(IO_FAILED_UNKNOWN, 0, 0);
    return;  // |this| may have been destroyed in |OnWriteCompleted()|.
  }
}

}  // namespace

// -----------------------------------------------------------------------------

// Static factory method declared in raw_channel.h.
// static
std::unique_ptr<RawChannel> RawChannel::Create(ScopedPlatformHandle handle) {
  return MakeUnique<RawChannelPosix>(handle.Pass());
}

}  // namespace system
}  // namespace mojo
