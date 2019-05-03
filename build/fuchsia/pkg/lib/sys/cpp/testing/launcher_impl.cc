// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/testing/launcher_impl.h>

#include <lib/sys/cpp/file_descriptor.h>
#include <unistd.h>

namespace sys {
namespace testing {

void LauncherImpl::CreateComponent(
    fuchsia::sys::LaunchInfo launch_info,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> request) {
  if (!launch_info.out) {
    launch_info.out = sys::CloneFileDescriptor(STDOUT_FILENO);
  }
  if (!launch_info.err) {
    launch_info.err = sys::CloneFileDescriptor(STDERR_FILENO);
  }
  launcher_->CreateComponent(std::move(launch_info), std::move(request));
}

}  // namespace testing
}  // namespace sys
