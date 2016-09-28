// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/test/test_timeouts.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_test_base.h"

MojoResult MojoMain(MojoHandle handle) {
  // An AtExitManager instance is needed to construct message loops.
  base::AtExitManager at_exit;

  // Initialize test timeouts, which requires CommandLine::ForCurrentProcess().
  // TODO(msw): Plumb relevant command line args before initializing timeouts.
  base::CommandLine::Init(0, nullptr);
  TestTimeouts::Initialize();

  return mojo::test::RunAllTests(handle);
}
