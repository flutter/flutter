// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/testing/fake_launcher.h>

namespace sys {
namespace testing {

using fuchsia::sys::Launcher;

FakeLauncher::FakeLauncher() {}

FakeLauncher::~FakeLauncher() = default;

void FakeLauncher::CreateComponent(
    fuchsia::sys::LaunchInfo launch_info,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  auto it = connectors_.find(launch_info.url);
  if (it != connectors_.end()) {
    it->second(std::move(launch_info), std::move(controller));
  }
}

void FakeLauncher::RegisterComponent(std::string url,
                                     ComponentConnector connector) {
  connectors_[url] = std::move(connector);
}

fidl::InterfaceRequestHandler<Launcher> FakeLauncher::GetHandler(
    async_dispatcher_t* dispatcher) {
  return [this, dispatcher](fidl::InterfaceRequest<Launcher> request) {
    binding_set_.AddBinding(this, std::move(request), dispatcher);
  };
}

}  // namespace testing
}  // namespace sys
