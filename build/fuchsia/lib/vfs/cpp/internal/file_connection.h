// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_INTERNAL_FILE_CONNECTION_H_
#define LIB_VFS_CPP_INTERNAL_FILE_CONNECTION_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/vfs/cpp/connection.h>

#include <memory>

namespace vfs {
class File;

namespace internal {

// Binds an implementation of |fuchsia.io.File| to a |vfs::File|.
class FileConnection final : public Connection, public fuchsia::io::File {
 public:
  // Create a connection to |vn| with the given |flags|.
  FileConnection(uint32_t flags, vfs::File* vn);
  ~FileConnection() override;

  // Start listening for |fuchsia.io.File| messages on |request|.
  zx_status_t Bind(zx::channel request,
                   async_dispatcher_t* dispatcher) override;

  // |fuchsia::io::File| Implementation:
  void Clone(uint32_t flags,
             fidl::InterfaceRequest<fuchsia::io::Node> object) override;
  void Close(CloseCallback callback) override;
  void Describe(DescribeCallback callback) override;
  void Sync(SyncCallback callback) override;
  void GetAttr(GetAttrCallback callback) override;
  void SetAttr(uint32_t flags, fuchsia::io::NodeAttributes attributes,
               SetAttrCallback callback) override;
  void Ioctl(uint32_t opcode, uint64_t max_out, std::vector<zx::handle> handles,
             std::vector<uint8_t> in, IoctlCallback callback) override;
  void Read(uint64_t count, ReadCallback callback) override;
  void ReadAt(uint64_t count, uint64_t offset,
              ReadAtCallback callback) override;
  void Write(std::vector<uint8_t> data, WriteCallback callback) override;
  void WriteAt(std::vector<uint8_t> data, uint64_t offset,
               WriteAtCallback callback) override;
  void Seek(int64_t offset, fuchsia::io::SeekOrigin start,
            SeekCallback callback) override;
  void Truncate(uint64_t length, TruncateCallback callback) override;
  void GetFlags(GetFlagsCallback callback) override;
  void SetFlags(uint32_t flags, SetFlagsCallback callback) override;
  void GetBuffer(uint32_t flags, GetBufferCallback callback) override;

  // |Connection| Implementation:
  void SendOnOpenEvent(zx_status_t status) override;

 private:
  vfs::File* vn_;
  fidl::Binding<fuchsia::io::File> binding_;
};

}  // namespace internal
}  // namespace vfs

#endif  // LIB_VFS_CPP_INTERNAL_FILE_CONNECTION_H_
