// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/testing/test_with_environment.h>

#include <lib/sys/cpp/service_directory.h>

namespace sys {
namespace testing {

TestWithEnvironment::TestWithEnvironment()
    : real_services_(sys::ServiceDirectory::CreateFromNamespace()) {
  real_services_->Connect(real_env_.NewRequest());
  real_env_->GetLauncher(real_launcher_.NewRequest());
}

void TestWithEnvironment::CreateComponentInCurrentEnvironment(
    fuchsia::sys::LaunchInfo launch_info,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> request) {
  real_launcher_.CreateComponent(std::move(launch_info), std::move(request));
}

bool TestWithEnvironment::RunComponentUntilTerminated(
    fuchsia::sys::ComponentControllerPtr component_controller,
    TerminationResult* termination_result) {
  bool is_terminated = false;
  component_controller.events().OnTerminated =
      [&](int64_t return_code, fuchsia::sys::TerminationReason reason) {
        is_terminated = true;
        if (termination_result != nullptr) {
          *termination_result = {
              .return_code = return_code,
              .reason = reason,
          };
        }
      };
  RunLoopUntil([&]() { return is_terminated; });
  return is_terminated;
}

}  // namespace testing
}  // namespace sys
