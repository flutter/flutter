// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/testing/test_runner.h"

#include <iostream>

#include "flutter/common/threads.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/testing/platform_view_test.h"

namespace shell {

TestRunner::TestRunner()
    : platform_view_(new PlatformViewTest()), weak_ptr_factory_(this) {
  platform_view_->ConnectToEngine(GetProxy(&sky_engine_));

  blink::ViewportMetrics metrics;
  metrics.physical_width = 800;
  metrics.physical_height = 600;

  blink::Threads::UI()->PostTask(
      [ engine = platform_view_->engine().GetWeakPtr(), metrics ] {
        if (engine.get())
          engine->SetViewportMetrics(metrics);
      });
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
