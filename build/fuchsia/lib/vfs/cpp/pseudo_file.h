// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_PSEUDO_FILE_H_
#define LIB_VFS_CPP_PSEUDO_FILE_H_

#include <lib/vfs/cpp/connection.h>
#include <lib/vfs/cpp/file.h>

namespace vfs {

// Buffered pseudo-file.
//
// This variant is optimized for incrementally reading and writing properties
// which are larger than can typically be read or written by the client in
// a single I/O transaction.
//
// In read mode, the pseudo-file invokes its read handler when the file is
// opened and retains the content in a buffer which the client incrementally
// reads from and can seek within.
//
// In write mode, the client incrementally writes into and seeks within the
// buffer which the pseudo-file delivers as a whole to the write handler when
// the file is closed(if there were any writes).  Truncation is also supported.
//
// Instances of this class are thread-safe.
class BufferedPseudoFile : public File {
 public:
  // Handler called to read from the pseudo-file.
  using ReadHandler = fit::function<zx_status_t(std::vector<uint8_t>* output)>;

  // Handler called to write into the pseudo-file.
  using WriteHandler = fit::function<void(std::vector<uint8_t> input)>;

  // Creates a buffered pseudo-file.
  //
  // |read_handler| cannot be null. If the |write_handler| is null, then the
  // pseudo-file is considered not writable. The |buffer_capacity|
  // determines the maximum number of bytes which can be written to the
  // pseudo-file's input buffer when it it opened for writing.
  BufferedPseudoFile(ReadHandler read_handler = ReadHandler(),
                     WriteHandler write_handler = WriteHandler(),
                     size_t buffer_capacity = 1024);

  ~BufferedPseudoFile() override;

  // |Node| implementations:
  zx_status_t GetAttr(
      fuchsia::io::NodeAttributes* out_attributes) const override;

 protected:
  zx_status_t CreateConnection(
      uint32_t flags, std::unique_ptr<Connection>* connection) override;

  uint32_t GetAdditionalAllowedFlags() const override;

  uint32_t GetProhibitiveFlags() const override;

 private:
  class Content final : public Connection, public File {
   public:
    Content(BufferedPseudoFile* file, uint32_t flags,
            std::vector<uint8_t> content);
    ~Content() override;

    // |File| implementations:
    zx_status_t ReadAt(uint64_t count, uint64_t offset,
                       std::vector<uint8_t>* out_data) override;
    zx_status_t WriteAt(std::vector<uint8_t> data, uint64_t offset,
                        uint64_t* out_actual) override;
    zx_status_t Truncate(uint64_t length) override;

    uint64_t GetLength() override;

    size_t GetCapacity() override;

    // Connection implementation:
    zx_status_t Bind(zx::channel request,
                     async_dispatcher_t* dispatcher) override;

    void SendOnOpenEvent(zx_status_t status) override;

    // |Node| implementations:
    std::unique_ptr<Connection> Close(Connection* connection) override;

    void Clone(uint32_t flags, uint32_t parent_flags,
               fidl::InterfaceRequest<fuchsia::io::Node> object,
               async_dispatcher_t* dispatcher) override;

    zx_status_t GetAttr(
        fuchsia::io::NodeAttributes* out_attributes) const override;

   protected:
    uint32_t GetAdditionalAllowedFlags() const override;

    uint32_t GetProhibitiveFlags() const override;

   private:
    void SetInputLength(size_t length);

    BufferedPseudoFile* const file_;

    std::vector<uint8_t> buffer_;
    uint32_t flags_;

    // true if the file was written into
    bool dirty_ = false;
  };

  // |File| implementations:
  uint64_t GetLength() override;

  size_t GetCapacity() override;

  ReadHandler const read_handler_;
  WriteHandler const write_handler_;
  const size_t buffer_capacity_;
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_PSEUDO_FILE_H_
