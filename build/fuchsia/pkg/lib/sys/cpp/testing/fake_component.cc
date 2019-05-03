// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/io/cpp/fidl.h>
#include <lib/sys/cpp/testing/fake_component.h>

namespace sys {
namespace testing {

FakeComponent::FakeComponent() {}

FakeComponent::~FakeComponent() = default;

void FakeComponent::Register(std::string url, FakeLauncher& fake_launcher,
                             async_dispatcher_t* dispatcher) {
  fake_launcher.RegisterComponent(
      url, [this, dispatcher](
               fuchsia::sys::LaunchInfo launch_info,
               fidl::InterfaceRequest<fuchsia::sys::ComponentController> ctrl) {
        ctrls_.push_back(std::move(ctrl));
        zx_status_t status = directory_.Serve(
            fuchsia::io::OPEN_RIGHT_READABLE,
            std::move(launch_info.directory_request), dispatcher);
        ZX_ASSERT(status == ZX_OK);
      });
}

}  // namespace testing
}  // namespace sys
