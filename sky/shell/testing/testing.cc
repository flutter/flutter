// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/testing/testing.h"

#include "sky/engine/public/web/WebRuntimeFeatures.h"
#include "base/command_line.h"
#include "sky/shell/switches.h"
#include "sky/shell/testing/test_runner.h"

namespace sky {
namespace shell {

void InitForTesting() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  blink::WebRuntimeFeatures::enableObservatory(
      !command_line.HasSwitch(switches::kNonInteractive));

  // Explicitly boot the shared test runner.
  TestRunner& runner = TestRunner::Shared();

  std::string package_root =
      command_line.GetSwitchValueASCII(switches::kPackageRoot);
  runner.set_package_root(package_root);

  scoped_ptr<TestRunner::SingleTest> single_test;
  if (command_line.HasSwitch(switches::kSnapshot)) {
    single_test.reset(new TestRunner::SingleTest);
    single_test->path = command_line.GetSwitchValueASCII(switches::kSnapshot);
    single_test->is_snapshot = true;
  } else {
    auto args = command_line.GetArgs();
    if (!args.empty()) {
      single_test.reset(new TestRunner::SingleTest);
      single_test->path = args[0];
    }
  }

  runner.Start(single_test.Pass());
}

}  // namespace shell
}  // namespace sky
