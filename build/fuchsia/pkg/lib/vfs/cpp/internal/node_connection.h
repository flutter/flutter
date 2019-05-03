// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_INTERNAL_NODE_CONNECTION_H_
#define LIB_VFS_CPP_INTERNAL_NODE_CONNECTION_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/vfs/cpp/connection.h>

#include <memory>

namespace vfs {
class Node;

namespace internal {

// Binds an implementation of |fuchsia.io.Node| to a |vfs::Node|.
class NodeConnection final : public Connection, public fuchsia::io::Node {
 public:
  // Create a connection to |vn| with the given |flags|.
  NodeConnection(uint32_t flags, vfs::Node* vn);
  ~NodeConnection() override;

  // Start listening for |fuchsia.io.Node| messages on |request|.
  zx_status_t Bind(zx::channel request,
                   async_dispatcher_t* dispatcher) override;

  // |fuchsia::io::Node| Implementation:
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

  // |Connection| Implementation:
  void SendOnOpenEvent(zx_status_t status) override;

 private:
  vfs::Node* vn_;
  fidl::Binding<fuchsia::io::Node> binding_;
};

}  // namespace internal
}  // namespace vfs

#endif  // LIB_VFS_CPP_INTERNAL_NODE_CONNECTION_H_
