// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runner_context.h"

namespace flutter_runner {

RunnerContext::RunnerContext(std::shared_ptr<sys::ServiceDirectory> svc,
                             zx::channel directory_request)
    : svc_(std::move(svc)),
      root_dir_(std::make_shared<vfs::PseudoDir>()),
      public_dir_(std::make_shared<vfs::PseudoDir>()),
      debug_dir_(std::make_shared<vfs::PseudoDir>()),
      ctrl_dir_(std::make_shared<vfs::PseudoDir>()) {
  root_dir_->AddSharedEntry("svc", public_dir_);
  root_dir_->AddSharedEntry("debug", debug_dir_);
  root_dir_->AddSharedEntry("ctrl", ctrl_dir_);

  root_dir_->Serve(
      fuchsia::io::OPEN_RIGHT_READABLE | fuchsia::io::OPEN_RIGHT_WRITABLE,
      std::move(directory_request));
}

RunnerContext::~RunnerContext() = default;

std::unique_ptr<RunnerContext> RunnerContext::CreateFromStartupInfo() {
  zx_handle_t directory_request = zx_take_startup_handle(PA_DIRECTORY_REQUEST);
  return std::make_unique<RunnerContext>(
      sys::ServiceDirectory::CreateFromNamespace(),
      zx::channel(directory_request));
}

zx_status_t RunnerContext::AddPublicService(
    std::unique_ptr<vfs::Service> service,
    std::string service_name) const {
  return public_dir_->AddEntry(std::move(service_name), std::move(service));
}

}  // namespace flutter_runner
