// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a helper class for implementing a |mojo::files::File| that behaves
// like an "input stream" ("input" from the point of view of the client --
// i.e., the client can write/stream input from it, but not write or seek).

#ifndef MOJO_SERVICES_FILES_CPP_INPUT_STREAM_FILE_H_
#define MOJO_SERVICES_FILES_CPP_INPUT_STREAM_FILE_H_

#include <stddef.h>
#include <stdint.h>

#include <deque>
#include <memory>

#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/services/files/interfaces/file.mojom.h"
#include "mojo/services/files/interfaces/types.mojom.h"

namespace files_impl {

class InputStreamFile : public mojo::files::File {
 public:
  // The |Client| receives data written to the stream "file" as well as other
  // notifications (e.g., of the "file" being closed). From any of the methods
  // below, the client may choose to destroy the |InputStreamFile|.
  class Client {
   public:
    // Called to request data from the stream "file". This can provide data
    // synchronously by returning true and setting |*error| and |*data|, or
    // asynchronously by returning false and calling the callback when data is
    // available.
    //   - In both cases, a data buffer with zero data can be used to signify
    //     "end of stream".
    //   - In both cases, a non-OK error code can be provided instead (in which
    //     case any data buffer is ignored).
    //   - In the asynchronous case, calls to |RequestData()| will not be
    //     overlapped, i.e., no more calls to |RequestData()| will be made until
    //     its callback has been called.
    //   - If this object is destroyed with a callback pending, the callback
    //     should *not* be called.
    //   - The callback should not be called from within |RequestData()|
    //     (instead, the client should complete synchronously by returning a
    //     buffer).
    //   - However, from within the callback, |RequestData()| may be called
    //     again.
    // TODO(vtl): We should also support "nonblocking" I/O (i.e., always respond
    // immediately, possibly with "would block").
    using RequestDataCallback = mojo::Callback<void(mojo::files::Error error,
                                                    mojo::Array<uint8_t> data)>;
    virtual bool RequestData(size_t max_num_bytes,
                             mojo::files::Error* error,
                             mojo::Array<uint8_t>* data,
                             const RequestDataCallback& callback) = 0;

    // Called when the stream "file" is closed, via |Close()| or due to the
    // other end of the message pipe being closed. (This will not be called due
    // the |InputStreamFile| being destroyed.)
    virtual void OnClosed() = 0;

   protected:
    virtual ~Client() {}
  };

  // Static factory method. |client| may be null, but if not it should typically
  // outlive us (see |set_client()|).
  static std::unique_ptr<InputStreamFile> Create(
      Client* client,
      mojo::InterfaceRequest<mojo::files::File> request);

  ~InputStreamFile() override;

  // Sets the client (which may be null, in which case all |Read()|s from the
  // stream "file" will just fail). If non-null, |client| must be valid whenever
  // the run (a.k.a. message) loop is run, i.e., whenever a client method may be
  // called.
  //
  // Note: Since it's unusual for reads to fail and then succeed later, one
  // should avoid setting a null client and then setting a non-null client.
  void set_client(Client* client) { client_ = client; }

 private:
  InputStreamFile(Client* client,
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

  // Warning: |this| may be destroyed by |StartRead()|.
  void StartRead();
  void CompleteRead(mojo::files::Error error, mojo::Array<uint8_t> data);

  struct PendingRead {
    PendingRead(uint32_t num_bytes, const ReadCallback& callback);
    ~PendingRead();

    uint32_t num_bytes;
    ReadCallback callback;
  };

  Client* client_;
  bool is_closed_;
  std::deque<PendingRead> pending_read_queue_;

  // If non-null |*was_destroyed_| is set to true on destruction.
  bool* was_destroyed_;

  mojo::Binding<mojo::files::File> binding_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(InputStreamFile);
};

}  // namespace files_impl

#endif  // MOJO_SERVICES_FILES_CPP_INPUT_STREAM_FILE_H_
