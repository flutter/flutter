// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/test_command_line.h"

#include "base/logging.h"
#include "mojo/edk/util/command_line.h"

namespace mojo {
namespace system {
namespace test {

static util::CommandLine* g_test_command_line = nullptr;

void InitializeTestCommandLine(int argc, const char* const* argv) {
  CHECK(!g_test_command_line);
  // TODO(vtl): May have to annotate the following "leak", if we run with LSan.
  g_test_command_line =
      new util::CommandLine(util::CommandLineFromArgcArgv(argc, argv));
}

const util::CommandLine* GetTestCommandLine() {
  return g_test_command_line;
}

}  // namespace test
}  // namespace system
}  // namespace mojo
