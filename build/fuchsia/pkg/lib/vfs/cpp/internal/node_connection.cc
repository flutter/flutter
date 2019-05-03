// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/internal/node_connection.h>

#include <utility>

#include <lib/vfs/cpp/flags.h>
#include <lib/vfs/cpp/node.h>

namespace vfs {
namespace internal {

NodeConnection::NodeConnection(uint32_t flags, vfs::Node* vn)
    : Connection(flags), vn_(vn), binding_(this) {}

NodeConnection::~NodeConnection() = default;

zx_status_t NodeConnection::Bind(zx::channel request,
                                 async_dispatcher_t* dispatcher) {
  zx_status_t status = binding_.Bind(std::move(request), dispatcher);
  if (status != ZX_OK) {
    return status;
  }
  binding_.set_error_handler([this](zx_status_t status) { vn_->Close(this); });
  return ZX_OK;
}

void NodeConnection::Clone(uint32_t flags,
                           fidl::InterfaceRequest<fuchsia::io::Node> object) {
  Connection::Clone(vn_, flags, std::move(object), binding_.dispatcher());
}

void NodeConnection::Close(CloseCallback callback) {
  Connection::Close(vn_, std::move(callback));
}

void NodeConnection::Describe(DescribeCallback callback) {
  Connection::Describe(vn_, std::move(callback));
}

void NodeConnection::Sync(SyncCallback callback) {
  Connection::Sync(vn_, std::move(callback));
}

void NodeConnection::GetAttr(GetAttrCallback callback) {
  Connection::GetAttr(vn_, std::move(callback));
}

void NodeConnection::SetAttr(uint32_t flags,
                             fuchsia::io::NodeAttributes attributes,
                             SetAttrCallback callback) {
  Connection::SetAttr(vn_, flags, attributes, std::move(callback));
}

void NodeConnection::Ioctl(uint32_t opcode, uint64_t max_out,
                           std::vector<zx::handle> handles,
                           std::vector<uint8_t> in, IoctlCallback callback) {
  Connection::Ioctl(vn_, opcode, max_out, std::move(handles), std::move(in),
                    std::move(callback));
}

void NodeConnection::SendOnOpenEvent(zx_status_t status) {
  binding_.events().OnOpen(status, NodeInfoIfStatusOk(vn_, status));
}

}  // namespace internal
}  // namespace vfs
