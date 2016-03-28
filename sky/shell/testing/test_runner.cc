// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/testing/test_runner.h"

#include <iostream>

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/string_util.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {
namespace {

static TestRunner* g_test_runner = nullptr;

}  // namespace

TestRunner::TestRunner()
    : shell_view_(new ShellView(Shell::Shared())), weak_ptr_factory_(this) {
  CHECK(!g_test_runner) << "Only create one TestRunner.";

  shell_view_->view()->ConnectToEngine(GetProxy(&sky_engine_));
  ViewportMetricsPtr metrics = ViewportMetrics::New();
  metrics->physical_width = 800;
  metrics->physical_height = 600;
  sky_engine_->OnViewportMetricsChanged(metrics.Pass());
}

TestRunner::~TestRunner() {}

TestRunner& TestRunner::Shared() {
  if (!g_test_runner)
    g_test_runner = new TestRunner();
  return *g_test_runner;
}

void TestRunner::Run(const TestDescriptor& test) {
  sky_engine_->RunFromFile(test.path, test.packages, "");
}

}  // namespace shell
}  // namespace sky
