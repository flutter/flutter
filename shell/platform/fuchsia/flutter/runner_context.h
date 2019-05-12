// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_CONTEXT_H_

#include <memory>
#include <unordered_map>

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/vfs/cpp/service.h>
#include <zircon/process.h>
#include <zircon/processargs.h>

#include "flutter/fml/macros.h"

namespace flutter_runner {

class RunnerContext {
 public:
  RunnerContext(std::shared_ptr<sys::ServiceDirectory> svc,
                zx::channel directory_request);
  ~RunnerContext();

  static std::unique_ptr<RunnerContext> CreateFromStartupInfo();

  const std::shared_ptr<sys::ServiceDirectory>& svc() const { return svc_; }
  const std::shared_ptr<vfs::PseudoDir>& root_dir() const { return root_dir_; }
  const std::shared_ptr<vfs::PseudoDir>& public_dir() const {
    return public_dir_;
  }
  const std::shared_ptr<vfs::PseudoDir>& debug_dir() const {
    return debug_dir_;
  }
  const std::shared_ptr<vfs::PseudoDir>& ctrl_dir() const { return ctrl_dir_; }

  template <typename Interface>
  zx_status_t AddPublicService(
      fidl::InterfaceRequestHandler<Interface> handler,
      std::string service_name = Interface::Name_) const {
    return AddPublicService(std::make_unique<vfs::Service>(std::move(handler)),
                            std::move(service_name));
  }

  zx_status_t AddPublicService(std::unique_ptr<vfs::Service> service,
                               std::string service_name) const;

  template <typename Interface>
  zx_status_t RemovePublicService(
      const std::string& name = Interface::Name_) const {
    return public_dir_->RemoveEntry(name);
  }

 private:
  std::shared_ptr<sys::ServiceDirectory> svc_;
  std::shared_ptr<vfs::PseudoDir> root_dir_;
  std::shared_ptr<vfs::PseudoDir> public_dir_;
  std::shared_ptr<vfs::PseudoDir> debug_dir_;
  std::shared_ptr<vfs::PseudoDir> ctrl_dir_;

  FML_DISALLOW_COPY_AND_ASSIGN(RunnerContext);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_CONTEXT_H_
