// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_INTERNAL_DIRECTORY_CONNECTION_H_
#define LIB_VFS_CPP_INTERNAL_DIRECTORY_CONNECTION_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/vfs/cpp/connection.h>

#include <memory>

namespace vfs {
class Directory;

namespace internal {

// Binds an implementation of |fuchsia.io.Directory| to a |vfs::Directory|.
class DirectoryConnection final : public Connection,
                                  public fuchsia::io::Directory {
 public:
  // Create a connection to |vn| with the given |flags|.
  DirectoryConnection(uint32_t flags, vfs::Directory* vn);
  ~DirectoryConnection() override;

  // Start listening for |fuchsia.io.Directory| messages on |request|.
  zx_status_t Bind(zx::channel request,
                   async_dispatcher_t* dispatcher) override;

  // |fuchsia::io::Directory| Implementation:
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
  void Open(uint32_t flags, uint32_t mode, std::string path,
            fidl::InterfaceRequest<fuchsia::io::Node> object) override;
  void Unlink(std::string path, UnlinkCallback callback) override;
  void ReadDirents(uint64_t max_bytes, ReadDirentsCallback callback) override;
  void Rewind(RewindCallback callback) override;
  void GetToken(GetTokenCallback callback) override;
  void Rename(std::string src, zx::handle dst_parent_token, std::string dst,
              RenameCallback callback) override;
  void Link(std::string src, zx::handle dst_parent_token, std::string dst,
            LinkCallback callback) override;
  void Watch(uint32_t mask, uint32_t options, zx::channel watcher,
             WatchCallback callback) override;

  // |Connection| Implementation:
  void SendOnOpenEvent(zx_status_t status) override;

 private:
  vfs::Directory* vn_;
  fidl::Binding<fuchsia::io::Directory> binding_;
};

}  // namespace internal
}  // namespace vfs

#endif  // LIB_VFS_CPP_INTERNAL_DIRECTORY_CONNECTION_H_
