// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/fml/thread.h"

TEST(Thread, CanStartAndEnd) {
  fml::Thread thread;
  ASSERT_TRUE(thread.GetTaskRunner());
}

TEST(Thread, CanStartAndEndWithExplicitJoin) {
  fml::Thread thread;
  ASSERT_TRUE(thread.GetTaskRunner());
  thread.Join();
}

TEST(Thread, HasARunningMessageLoop) {
  fml::Thread thread;
  bool done = false;
  thread.GetTaskRunner()->PostTask([&done]() { done = true; });
  thread.Join();
  ASSERT_TRUE(done);
}
