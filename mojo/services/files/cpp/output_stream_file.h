// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a helper class for implementing a |mojo::files::File| that behaves
// like an "output stream" ("output" from the point of view of the client --
// i.e., the client can write/stream output to it, but not read or seek).

#ifndef MOJO_SERVICES_FILES_CPP_OUTPUT_STREAM_FILE_H_
#define MOJO_SERVICES_FILES_CPP_OUTPUT_STREAM_FILE_H_

#include <stddef.h>

#include <memory>

#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/services/files/interfaces/file.mojom.h"
#include "mojo/services/files/interfaces/types.mojom.h"

namespace files_impl {

class OutputStreamFile : public mojo::files::File {
 public:
  // The |Client| receives data written to the stream "file" as well as other
  // notifications (e.g., of the "file" being closed). From any of the methods
  // below, the client may choose to destroy the |OutputStreamFile|.
  class Client {
   public:
    // Called when we receive data from the stream "file".
    // TODO(vtl): Maybe add a way to throttle (e.g., for the client to not
    // accept all the data).
    virtual void OnDataReceived(const void* bytes, size_t num_bytes) = 0;

    // Called when the stream "file" is closed, via |Close()| or due to the
    // other end of the message pipe being closed. (This will not be called due
    // the |OutputStreamFile| being destroyed.)
    virtual void OnClosed() = 0;

   protected:
    virtual ~Client() {}
  };

  // Static factory method. |client| may be null, but if not it should typically
  // outlive us (see |set_client()|).
  static std::unique_ptr<OutputStreamFile> Create(
      Client* client,
      mojo::InterfaceRequest<mojo::files::File> request);

  ~OutputStreamFile() override;

  // Sets the client (which may be null, in which case all |Write()|s to the
  // stream "file" will just succeed). If non-null, |client| must be valid
  // whenever the run (a.k.a. message) loop is run, i.e., whenever a client
  // method may be called.
  void set_client(Client* client) { client_ = client; }

 private:
  OutputStreamFile(Client* client,
                   mojo::InterfaceRequest<mojo::files::File> request);

  // We should only be deleted by "ourself" (via the strong binding).
  friend class mojo::Binding<mojo::files::File>;

  // |mojo::files::File| implementation:
  void Close(const CloseCallback& callback) override;
  void Read(uint32_t num_bytes_to_read,
            int64_t offset,
            mojo::files::Whence whence,
            const ReadCallback& callback) override;
  void Write(mojo::Array<uint8_t> bytes_to_write,
             int64_t offset,
             mojo::files::Whence whence,
             const WriteCallback& callback) override;
  void ReadToStream(mojo::ScopedDataPipeProducerHandle source,
                    int64_t offset,
                    mojo::files::Whence whence,
                    int64_t num_bytes_to_read,
                    const ReadToStreamCallback& callback) override;
  void WriteFromStream(mojo::ScopedDataPipeConsumerHandle sink,
                       int64_t offset,
                       mojo::files::Whence whence,
                       const WriteFromStreamCallback& callback) override;
  void Tell(const TellCallback& callback) override;
  void Seek(int64_t offset,
            mojo::files::Whence whence,
            const SeekCallback& callback) override;
  void Stat(const StatCallback& callback) override;
  void Truncate(int64_t size, const TruncateCallback& callback) override;
  void Touch(mojo::files::TimespecOrNowPtr atime,
             mojo::files::TimespecOrNowPtr mtime,
             const TouchCallback& callback) override;
  void Dup(mojo::InterfaceRequest<mojo::files::File> file,
           const DupCallback& callback) override;
  void Reopen(mojo::InterfaceRequest<mojo::files::File> file,
              uint32_t open_flags,
              const ReopenCallback& callback) override;
  void AsBuffer(const AsBufferCallback& callback) override;
  void Ioctl(uint32_t request,
             mojo::Array<uint32_t> in_values,
             const IoctlCallback& callback) override;

  Client* client_;
  bool is_closed_;

  mojo::Binding<mojo::files::File> binding_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(OutputStreamFile);
};

}  // namespace files_impl

#endif  // MOJO_SERVICES_FILES_CPP_OUTPUT_STREAM_FILE_H_
