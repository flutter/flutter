// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/outgoing_directory.h>

#include <utility>

#include <zircon/process.h>
#include <zircon/processargs.h>

namespace sys {

OutgoingDirectory::OutgoingDirectory()
    : root_(std::make_unique<vfs::PseudoDir>()),
      public_(GetOrCreateDirectory("public")),
      debug_(GetOrCreateDirectory("debug")),
      ctrl_(GetOrCreateDirectory("ctrl")) {}

OutgoingDirectory::~OutgoingDirectory() = default;

zx_status_t OutgoingDirectory::Serve(zx::channel directory_request,
                                     async_dispatcher_t* dispatcher) {
  return root_->Serve(fuchsia::io::OPEN_RIGHT_READABLE |
                          fuchsia::io::OPEN_RIGHT_WRITABLE,
                      std::move(directory_request), dispatcher);
}

zx_status_t OutgoingDirectory::ServeFromStartupInfo(
    async_dispatcher_t* dispatcher) {
  return Serve(zx::channel(zx_take_startup_handle(PA_DIRECTORY_REQUEST)),
               dispatcher);
}

vfs::PseudoDir* OutgoingDirectory::GetOrCreateDirectory(
    const std::string& name) {
  vfs::Node* node;
  zx_status_t status = root_->Lookup(name, &node);
  if (status != ZX_OK) {
    return AddNewEmptyDirectory(name);
  }
  return static_cast<vfs::PseudoDir*>(node);
}

vfs::PseudoDir* OutgoingDirectory::AddNewEmptyDirectory(std::string name) {
  auto dir = std::make_unique<vfs::PseudoDir>();
  auto ptr = dir.get();
  root_->AddEntry(std::move(name), std::move(dir));
  return ptr;
}

zx_status_t OutgoingDirectory::AddPublicService(
    std::unique_ptr<vfs::Service> service, std::string service_name) const {
  return public_->AddEntry(std::move(service_name), std::move(service));
}

}  // namespace sys
