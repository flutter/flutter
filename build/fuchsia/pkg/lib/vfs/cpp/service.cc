// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/service.h>

#include <lib/fdio/vfs.h>
#include <lib/vfs/cpp/flags.h>

namespace vfs {

Service::Service(Connector connector) : connector_(std::move(connector)) {}

Service::~Service() = default;

void Service::Describe(fuchsia::io::NodeInfo* out_info) {
  out_info->set_service(fuchsia::io::Service());
}

zx_status_t Service::CreateConnection(uint32_t flags,
                                      std::unique_ptr<Connection>* connection) {
  return ZX_ERR_NOT_SUPPORTED;
}

uint32_t Service::GetAdditionalAllowedFlags() const {
  // TODO(ZX-3251): remove OPEN_RIGHT_WRITABLE flag
  return fuchsia::io::OPEN_RIGHT_READABLE | fuchsia::io::OPEN_RIGHT_WRITABLE;
}

zx_status_t Service::Connect(uint32_t flags, zx::channel request,
                             async_dispatcher_t* dispatcher) {
  if (Flags::IsPathOnly(flags)) {
    return Node::Connect(flags, std::move(request), dispatcher);
  }
  if (connector_ == nullptr) {
    SendOnOpenEventOnError(flags, std::move(request), ZX_ERR_NOT_SUPPORTED);
    return ZX_ERR_NOT_SUPPORTED;
  }
  connector_(std::move(request), dispatcher);
  return ZX_OK;
}

bool Service::IsDirectory() const { return false; }

zx_status_t Service::GetAttr(
    fuchsia::io::NodeAttributes* out_attributes) const {
  out_attributes->mode = fuchsia::io::MODE_TYPE_SERVICE | V_IRUSR;
  out_attributes->id = fuchsia::io::INO_UNKNOWN;
  out_attributes->content_size = 0;
  out_attributes->storage_size = 0;
  out_attributes->link_count = 1;
  out_attributes->creation_time = 0;
  out_attributes->modification_time = 0;
  return ZX_OK;
}

}  // namespace vfs
