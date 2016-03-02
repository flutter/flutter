// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/multiprocess_test_helper.h"

#include "base/command_line.h"
#include "base/logging.h"
#include "base/posix/global_descriptors.h"
#include "base/test/test_timeouts.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/scoped_platform_handle.h"

using mojo::platform::PlatformHandle;
using mojo::platform::PlatformPipe;
using mojo::platform::ScopedPlatformHandle;

namespace mojo {
namespace test {

MultiprocessTestHelper::MultiprocessTestHelper()
    : platform_pipe_(new PlatformPipe()) {
  server_platform_handle = platform_pipe_->handle0.Pass();
}

MultiprocessTestHelper::~MultiprocessTestHelper() {
  CHECK(!test_child_.IsValid());
  server_platform_handle.reset();
  platform_pipe_.reset();
}

void MultiprocessTestHelper::StartChild(const std::string& test_child_name) {
  StartChildWithExtraSwitch(test_child_name, std::string(), std::string());
}

void MultiprocessTestHelper::StartChildWithExtraSwitch(
    const std::string& test_child_name,
    const std::string& switch_string,
    const std::string& switch_value) {
  CHECK(platform_pipe_);
  CHECK(!test_child_name.empty());
  CHECK(!test_child_.IsValid());

  std::string test_child_main = test_child_name + "TestChildMain";

  base::CommandLine command_line(
      base::GetMultiProcessTestChildBaseCommandLine());
  if (!switch_string.empty()) {
    CHECK(!command_line.HasSwitch(switch_string));
    if (!switch_value.empty())
      command_line.AppendSwitchASCII(switch_string, switch_value);
    else
      command_line.AppendSwitch(switch_string);
  }

  base::FileHandleMappingVector fds_to_remap;
  fds_to_remap.push_back(
      std::pair<int, int>(platform_pipe_->handle1.get().fd,
                          base::GlobalDescriptors::kBaseDescriptor));
  base::LaunchOptions options;
  options.fds_to_remap = &fds_to_remap;

  test_child_ =
      base::SpawnMultiProcessTestChild(test_child_main, command_line, options);
  platform_pipe_->handle1.reset();

  CHECK(test_child_.IsValid());
}

int MultiprocessTestHelper::WaitForChildShutdown() {
  CHECK(test_child_.IsValid());

  int rv = -1;
  CHECK(
      test_child_.WaitForExitWithTimeout(TestTimeouts::action_timeout(), &rv));
  test_child_.Close();
  return rv;
}

bool MultiprocessTestHelper::WaitForChildTestShutdown() {
  return WaitForChildShutdown() == 0;
}

// static
void MultiprocessTestHelper::ChildSetup() {
  CHECK(base::CommandLine::InitializedForCurrentProcess());
  client_platform_handle = ScopedPlatformHandle(
      PlatformHandle(base::GlobalDescriptors::kBaseDescriptor));
}

// static
ScopedPlatformHandle MultiprocessTestHelper::client_platform_handle;

}  // namespace test
}  // namespace mojo
