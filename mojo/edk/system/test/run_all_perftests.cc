// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/perf_test_suite.h"
#include "mojo/edk/system/test/test_command_line.h"

int main(int argc, char** argv) {
  mojo::system::test::InitializeTestCommandLine(argc, argv);
  return base::PerfTestSuite(argc, argv).Run();
}
