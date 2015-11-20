// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/files/cpp/output_stream_file.h"

#include "mojo/public/cpp/environment/logging.h"

namespace files_impl {

// static
std::unique_ptr<OutputStreamFile> OutputStreamFile::Create(
    Client* client,
    mojo::InterfaceRequest<mojo::files::File> request) {
  // TODO(vtl): Use make_unique when we have C++14.
  return std::unique_ptr<OutputStreamFile>(
      new OutputStreamFile(client, request.Pass()));
}

OutputStreamFile::~OutputStreamFile() {}

OutputStreamFile::OutputStreamFile(
    Client* client,
    mojo::InterfaceRequest<mojo::files::File> request)
    : client_(client), is_closed_(false), binding_(this, request.Pass()) {
  binding_.set_connection_error_handler([this]() {
    if (client_)
      client_->OnClosed();
  });
}

void OutputStreamFile::Close(const CloseCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  is_closed_ = true;
  callback.Run(mojo::files::Error::OK);

  if (client_)
    client_->OnClosed();
}

void OutputStreamFile::Read(uint32_t num_bytes_to_read,
                            int64_t offset,
                            mojo::files::Whence whence,
                            const ReadCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE, nullptr);
}

void OutputStreamFile::Write(mojo::Array<uint8_t> bytes_to_write,
                             int64_t offset,
                             mojo::files::Whence whence,
                             const WriteCallback& callback) {
  MOJO_DCHECK(!bytes_to_write.is_null());

  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, 0);
    return;
  }

  if (offset != 0 || whence != mojo::files::Whence::FROM_CURRENT) {
    // TODO(vtl): Is this the "right" behavior?
    callback.Run(mojo::files::Error::INVALID_ARGUMENT, 0);
    return;
  }

  if (!bytes_to_write.size()) {
    callback.Run(mojo::files::Error::OK, 0);
    return;
  }

  // We require the client to handle all the output, so we run the callback now.
  // TODO(vtl): This means that the callback will be run (and the response
  // message sent), even if the client decides to destroy us -- and thus close
  // the message pipe -- in |OnDataReceived()|. This may makes throttling
  // slightly less effective -- but increase parallelism -- since the writer may
  // enqueue another write immediately.
  callback.Run(mojo::files::Error::OK,
               static_cast<uint32_t>(bytes_to_write.size()));

  if (client_)
    client_->OnDataReceived(&bytes_to_write.front(), bytes_to_write.size());
}

void OutputStreamFile::ReadToStream(mojo::ScopedDataPipeProducerHandle source,
                                    int64_t offset,
                                    mojo::files::Whence whence,
                                    int64_t num_bytes_to_read,
                                    const ReadToStreamCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void OutputStreamFile::WriteFromStream(
    mojo::ScopedDataPipeConsumerHandle sink,
    int64_t offset,
    mojo::files::Whence whence,
    const WriteFromStreamCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl)
  MOJO_DLOG(ERROR) << "Not implemented";
  callback.Run(mojo::files::Error::UNIMPLEMENTED);
}

void OutputStreamFile::Tell(const TellCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, 0);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE, 0);
}

void OutputStreamFile::Seek(int64_t offset,
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

void OutputStreamFile::Stat(const StatCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  // TODO(vtl)
  MOJO_DLOG(ERROR) << "Not implemented";
  callback.Run(mojo::files::Error::UNIMPLEMENTED, nullptr);
}

void OutputStreamFile::Truncate(int64_t size,
                                const TruncateCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void OutputStreamFile::Touch(mojo::files::TimespecOrNowPtr atime,
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

void OutputStreamFile::Dup(mojo::InterfaceRequest<mojo::files::File> file,
                           const DupCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED);
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE);
}

void OutputStreamFile::Reopen(mojo::InterfaceRequest<mojo::files::File> file,
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

void OutputStreamFile::AsBuffer(const AsBufferCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, mojo::ScopedSharedBufferHandle());
    return;
  }

  // TODO(vtl): Is this what we want? (Also is "unavailable" right? Maybe
  // unsupported/EINVAL is better.)
  callback.Run(mojo::files::Error::UNAVAILABLE,
               mojo::ScopedSharedBufferHandle());
}

void OutputStreamFile::Ioctl(uint32_t request,
                             mojo::Array<uint32_t> in_values,
                             const IoctlCallback& callback) {
  if (is_closed_) {
    callback.Run(mojo::files::Error::CLOSED, nullptr);
    return;
  }

  callback.Run(mojo::files::Error::UNIMPLEMENTED, nullptr);
}

}  // namespace files_impl
