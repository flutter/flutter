// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/node.h>

#include <algorithm>

#include <fuchsia/io/c/fidl.h>
#include <lib/vfs/cpp/connection.h>
#include <lib/vfs/cpp/flags.h>
#include <lib/vfs/cpp/internal/node_connection.h>
#include <zircon/assert.h>

namespace vfs {
namespace {

constexpr uint32_t kCommonAllowedFlags =
    fuchsia::io::OPEN_FLAG_DESCRIBE | fuchsia::io::OPEN_FLAG_NODE_REFERENCE |
    fuchsia::io::OPEN_FLAG_POSIX | fuchsia::io::CLONE_FLAG_SAME_RIGHTS;

constexpr uint32_t FS_RIGHTS = 0x0000FFFF;

}  // namespace

bool IsValidName(const std::string& name) {
  return name.length() <= NAME_MAX &&
         memchr(name.data(), '/', name.length()) == nullptr && name != "." &&
         name != "..";
}

Node::Node() = default;

Node::~Node() = default;

std::unique_ptr<Connection> Node::Close(Connection* connection) {
  std::lock_guard<std::mutex> guard(mutex_);

  auto connection_iterator = std::find_if(
      connections_.begin(), connections_.end(),
      [connection](const auto& entry) { return entry.get() == connection; });
  auto ret = std::move(*connection_iterator);
  connections_.erase(connection_iterator);
  return ret;
}

zx_status_t Node::Sync() { return ZX_ERR_NOT_SUPPORTED; }

bool Node::IsRemote() const { return false; }

zx_status_t Node::GetAttr(fuchsia::io::NodeAttributes* out_attributes) const {
  return ZX_ERR_NOT_SUPPORTED;
}

void Node::Clone(uint32_t flags, uint32_t parent_flags,
                 fidl::InterfaceRequest<fuchsia::io::Node> object,
                 async_dispatcher_t* dispatcher) {
  // TODO(ZX-3417): This is how libfs clones a node, we should fix this once we
  // have clear picture what clone should do.
  flags |= (parent_flags & (FS_RIGHTS | fuchsia::io::OPEN_FLAG_NODE_REFERENCE |
                            fuchsia::io::OPEN_FLAG_APPEND));
  Serve(flags, object.TakeChannel(), dispatcher);
}

zx_status_t Node::ValidateFlags(uint32_t flags) const {
  bool is_directory = IsDirectory();
  if (!is_directory && Flags::IsDirectory(flags)) {
    return ZX_ERR_NOT_DIR;
  }

  uint32_t allowed_flags = kCommonAllowedFlags | GetAdditionalAllowedFlags();
  if (is_directory) {
    allowed_flags = allowed_flags | fuchsia::io::OPEN_FLAG_DIRECTORY;
  }

  uint32_t prohibitive_flags = GetProhibitiveFlags();

  if ((flags & prohibitive_flags) != 0) {
    return ZX_ERR_INVALID_ARGS;
  }
  if ((flags & ~allowed_flags) != 0) {
    return ZX_ERR_NOT_SUPPORTED;
  }
  return ZX_OK;
}

zx_status_t Node::ValidateMode(uint32_t mode) const {
  fuchsia::io::NodeAttributes attr;
  uint32_t mode_from_attr = 0;
  zx_status_t status = GetAttr(&attr);
  if (status == ZX_OK) {
    mode_from_attr = attr.mode & fuchsia::io::MODE_TYPE_MASK;
  }

  if (((mode & ~fuchsia::io::MODE_PROTECTION_MASK) & ~mode_from_attr) != 0) {
    return ZX_ERR_INVALID_ARGS;
  }
  return ZX_OK;
}

zx_status_t Node::Lookup(const std::string& name, Node** out_node) const {
  ZX_ASSERT(!IsDirectory());
  return ZX_ERR_NOT_DIR;
}

uint32_t Node::GetAdditionalAllowedFlags() const { return 0; }

uint32_t Node::GetProhibitiveFlags() const { return 0; }

zx_status_t Node::SetAttr(uint32_t flags,
                          const fuchsia::io::NodeAttributes& attributes) {
  return ZX_ERR_NOT_SUPPORTED;
}

uint32_t Node::FilterRefFlags(uint32_t flags) {
  if (Flags::IsPathOnly(flags)) {
    return flags & (kCommonAllowedFlags | fuchsia::io::OPEN_FLAG_DIRECTORY);
  }
  return flags;
}

zx_status_t Node::Serve(uint32_t flags, zx::channel request,
                        async_dispatcher_t* dispatcher) {
  flags = FilterRefFlags(flags);
  zx_status_t status = ValidateFlags(flags);
  if (status != ZX_OK) {
    SendOnOpenEventOnError(flags, std::move(request), status);
    return status;
  }
  return Connect(flags, std::move(request), dispatcher);
}

zx_status_t Node::Connect(uint32_t flags, zx::channel request,
                          async_dispatcher_t* dispatcher) {
  zx_status_t status;
  std::unique_ptr<Connection> connection;
  if (Flags::IsPathOnly(flags)) {
    status = Node::CreateConnection(flags, &connection);
  } else {
    status = CreateConnection(flags, &connection);
  }
  if (status != ZX_OK) {
    SendOnOpenEventOnError(flags, std::move(request), status);
    return status;
  }
  status = connection->Bind(std::move(request), dispatcher);
  if (status == ZX_OK) {
    if (Flags::ShouldDescribe(flags)) {
      connection->SendOnOpenEvent(status);
    }
    AddConnection(std::move(connection));
  }  // can't send status as request object is gone.
  return status;
}

zx_status_t Node::ServeWithMode(uint32_t flags, uint32_t mode,
                                zx::channel request,
                                async_dispatcher_t* dispatcher) {
  zx_status_t status = ValidateMode(mode);
  if (status != ZX_OK) {
    SendOnOpenEventOnError(flags, std::move(request), status);
    return status;
  }
  return Serve(flags, std::move(request), dispatcher);
}

void Node::SendOnOpenEventOnError(uint32_t flags, zx::channel request,
                                  zx_status_t status) {
  ZX_DEBUG_ASSERT(status != ZX_OK);

  if (!Flags::ShouldDescribe(flags)) {
    return;
  }

  fuchsia_io_NodeOnOpenEvent msg;
  memset(&msg, 0, sizeof(msg));
  msg.hdr.ordinal = fuchsia_io_NodeOnOpenOrdinal;
  msg.s = status;
  request.write(0, &msg, sizeof(msg), nullptr, 0);
}

void Node::AddConnection(std::unique_ptr<Connection> connection) {
  std::lock_guard<std::mutex> guard(mutex_);
  connections_.push_back(std::move(connection));
}

zx_status_t Node::CreateConnection(uint32_t flags,
                                   std::unique_ptr<Connection>* connection) {
  *connection = std::make_unique<internal::NodeConnection>(flags, this);
  return ZX_OK;
}

}  // namespace vfs
