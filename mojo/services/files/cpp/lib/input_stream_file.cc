// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/files/cpp/input_stream_file.h"

#include <utility>

#include "mojo/public/cpp/environment/logging.h"

namespace files_impl {

InputStreamFile::PendingRead::PendingRead(uint32_t num_bytes,
                                          const ReadCallback& callback)
    : num_bytes(num_bytes), callback(callback) {}

InputStreamFile::PendingRead::~PendingRead() {}

// static
std::unique_ptr<InputStreamFile> InputStreamFile::Create(
    Client* client,
    mojo::InterfaceRequest<mojo::files::File> request) {
  // TODO(vtl): Use make_unique when we have C++14.
  return std::unique_ptr<InputStreamFile>(
      new InputStreamFile(client, request.Pass()));
}

InputStreamFile::~InputStreamFile() {
  if (was_destroyed_)
    *was_destroyed_ = true;
}

InputStreamFile::InputStreamFile(
    Client* client,
    mojo::InterfaceRequest<mojo::files::File> request)
    : client_(client),
      is_closed_(false),
      was_destroyed_(nullptr),
      binding_(this, request.Pass()) {
  binding_.set_connection_error_handler([this]() {
    if (client_)
      client_->OnClosed();
  });
}

void InputStreamFile::Close(const CloseCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Call pending read callbacks?

  is_closed_ = true;
  callback.Run(mojo::files::Error::OK);

  if (client_)
    client_->OnClosed();
}

void InputStreamFile::Read(uint32_t num_bytes_to_read,
                           int64_t offset,
                           mojo::files::Whence whence,
                           const ReadCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  if (offset != 0 || whence != mojo::files::Whence::FROM_CURRENT) {
    // TODO(vtl): Is this the "right" behavior?
    callback.Run(mojo::files::Error::INVALID_ARGUMENT, nullptr);
    return;
  }

  bool should_start_read = pending_read_queue_.empty();
  pending_read_queue_.push_back(PendingRead(num_bytes_to_read, callback));
  if (should_start_read)
    StartRead();
}

void InputStreamFile::Write(mojo::Array<uint8_t> bytes_to_write,
                            int64_t offset,
                            mojo::files::Whence whence,
                            const WriteCallback& callback) {
  MOJO_DCHECK(!bytes_to_write.is_null());

  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, 0);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE, 0);
}

void InputStreamFile::ReadToStream(mojo::ScopedDataPipeProducerHandle source,
                                   int64_t offset,
                                   mojo::files::Whence whence,
                                   int64_t num_bytes_to_read,
                                   const ReadToStreamCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl)
  MOJO_DLOG(ERROR) << "Not implemented";
  callback.Run(mojo::files::Error::UNIMPLEMENTED);
}

void InputStreamFile::WriteFromStream(mojo::ScopedDataPipeConsumerHandle sink,
                                      int64_t offset,
                                      mojo::files::Whence whence,
                                      const WriteFromStreamCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void InputStreamFile::Tell(const TellCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, 0);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE, 0);
}

void InputStreamFile::Seek(int64_t offset,
                           mojo::files::Whence whence,
                           const SeekCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, 0);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE, 0);
}

void InputStreamFile::Stat(const StatCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  // TODO(vtl)
  MOJO_DLOG(ERROR) << "Not implemented";
  callback.Run(mojo::files::Error::UNIMPLEMENTED, nullptr);
}

void InputStreamFile::Truncate(int64_t size, const TruncateCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void InputStreamFile::Touch(mojo::files::TimespecOrNowPtr atime,
                            mojo::files::TimespecOrNowPtr mtime,
                            const TouchCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void InputStreamFile::Dup(mojo::InterfaceRequest<mojo::files::File> file,
                          const DupCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void InputStreamFile::Reopen(mojo::InterfaceRequest<mojo::files::File> file,
                             uint32_t open_flags,
                             const ReopenCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void InputStreamFile::AsBuffer(const AsBufferCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, mojo::ScopedSharedBufferHandle());
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE,
               mojo::ScopedSharedBufferHandle());
}

void InputStreamFile::Ioctl(uint32_t request,
                            mojo::Array<uint32_t> in_values,
                            const IoctlCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  callback.Run(mojo::files::Error::UNIMPLEMENTED, nullptr);
}

void InputStreamFile::StartRead() {
  MOJO_DCHECK(!pending_read_queue_.empty());

  // If we don't have a client, just drain all the reads.
  if (!client_) {
    while (!pending_read_queue_.empty()) {
      // TODO(vtl): Is this what we want?
      pending_read_queue_.front().callback.Run(mojo::files::Error::UNAVAILABLE,
                                               nullptr);
      pending_read_queue_.pop_front();
    }
    return;
  }

  do {
    // Find a non-zero-byte read, completing any zero-byte reads at the front of
    // the queue. Note that we do this in FIFO order (thus couldn't have
    // completed them earlier).
    while (!pending_read_queue_.front().num_bytes) {
      pending_read_queue_.front().callback.Run(mojo::files::Error::OK, nullptr);
      pending_read_queue_.pop_front();

      if (pending_read_queue_.empty())
        return;
    }

    // Binding |this| is OK, since the client must not call the callback if we
    // are destroyed.
    mojo::files::Error error = mojo::files::Error::INTERNAL;
    mojo::Array<uint8_t> data;
    // Detect if we were destroyed inside |RequestData()|.
    bool was_destroyed = false;
    MOJO_CHECK(!was_destroyed_);
    was_destroyed_ = &was_destroyed;
    bool synchronous_completion = client_->RequestData(
        pending_read_queue_.front().num_bytes, &error, &data,
        [this](mojo::files::Error e, mojo::Array<uint8_t> d) {
          CompleteRead(e, d.Pass());
          if (!pending_read_queue_.empty())
            StartRead();
        });
    if (was_destroyed)
      return;
    was_destroyed_ = nullptr;
    if (synchronous_completion)
      CompleteRead(error, data.Pass());
    else
      return;  // Asynchronous completion.
  } while (!pending_read_queue_.empty());
}

void InputStreamFile::CompleteRead(mojo::files::Error error,
                                   mojo::Array<uint8_t> data) {
  MOJO_CHECK(!pending_read_queue_.empty());

  if (error != mojo::files::Error::OK) {
    pending_read_queue_.front().callback.Run(error, nullptr);
    pending_read_queue_.pop_front();
    return;
  }

  MOJO_CHECK(!data.is_null());
  MOJO_CHECK(data.size() <= pending_read_queue_.front().num_bytes);
  pending_read_queue_.front().callback.Run(mojo::files::Error::OK, data.Pass());
  pending_read_queue_.pop_front();
}

}  // namespace files_impl
