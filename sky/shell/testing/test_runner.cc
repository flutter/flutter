// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/testing/test_runner.h"

#include <iostream>

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/string_util.h"
#include "flutter/sky/shell/platform_view.h"
#include "flutter/sky/shell/shell.h"
#include "flutter/sky/shell/testing/platform_view_test.h"

namespace sky {
namespace shell {

TestRunner::TestRunner()
    : platform_view_(new PlatformViewTest()), weak_ptr_factory_(this) {
  platform_view_->ConnectToEngine(GetProxy(&sky_engine_));

  ViewportMetricsPtr metrics = ViewportMetrics::New();

  metrics->physical_width = 800;
  metrics->physical_height = 600;

  sky_engine_->OnViewportMetricsChanged(metrics.Pass());
}

TestRunner::~TestRunner() = default;

TestRunner& TestRunner::Shared() {
  static TestRunner* g_test_runner = nullptr;
  if (!g_test_runner)
    g_test_runner = new TestRunner();
  return *g_test_runner;
}

void TestRunner::Run(const TestDescriptor& test) {
  sky_engine_->RunFromFile(test.path, test.packages, "");
}

}  // namespace shell
}  // namespace sky
