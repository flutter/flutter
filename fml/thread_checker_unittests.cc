// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>

#include "flutter/fml/thread_checker.h"
#include "gtest/gtest.h"

TEST(ThreadChecker, CheckCalledOnValidThread) {
  fml::ThreadChecker checker;
  ASSERT_TRUE(checker.IsCalledOnValidThread());
  std::thread thread(
      [&checker]() { ASSERT_FALSE(checker.IsCalledOnValidThread()); });
  thread.join();
}
