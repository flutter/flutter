// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/linux_test.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"

namespace flutter {
namespace testing {

LinuxTest::LinuxTest() {
  fl_ensure_gtk_init();
  loop = g_main_loop_new(nullptr, FALSE);
  project = fl_dart_project_new();
  engine = fl_engine_new(project);
}

LinuxTest::~LinuxTest() {
  g_clear_object(&project);
  g_clear_pointer(&loop, g_main_loop_unref);
}

void LinuxTest::TearDown() {
  g_clear_object(&engine);
}

void LinuxTest::StartEngine(FlEngine* engine) {
  g_autoptr(GError) error = nullptr;
  EXPECT_TRUE(fl_engine_start(engine, &error));
  EXPECT_EQ(error, nullptr);
}

}  // namespace testing
}  // namespace flutter
