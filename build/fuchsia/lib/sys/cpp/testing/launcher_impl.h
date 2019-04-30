// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_LAUNCHER_IMPL_H_
#define LIB_SYS_CPP_TESTING_LAUNCHER_IMPL_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fidl/cpp/binding_set.h>

namespace sys {
namespace testing {

// Launcher impl to wrap and override CreateComponent of real launcher service.
class LauncherImpl : public fuchsia::sys::Launcher {
 public:
  void AddBinding(fidl::InterfaceRequest<fuchsia::sys::Launcher> launcher) {
    bindings_.AddBinding(this, std::move(launcher));
  }

  ::fidl::InterfaceRequest<fuchsia::sys::Launcher> NewRequest() {
    return launcher_.NewRequest();
  }

  // Overrides stdout and stderr to current stdout and stderr if not passed in
  // |launch_info| and creates a component.
  void CreateComponent(fuchsia::sys::LaunchInfo launch_info,
                       fidl::InterfaceRequest<fuchsia::sys::ComponentController>
                           request) override;

 private:
  fuchsia::sys::LauncherPtr launcher_;
  fidl::BindingSet<fuchsia::sys::Launcher> bindings_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_LAUNCHER_IMPL_H_
