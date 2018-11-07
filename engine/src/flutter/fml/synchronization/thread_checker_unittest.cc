// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/thread_checker.h"

#include <thread>

#include "gtest/gtest.h"

namespace fml {
namespace {

TEST(ThreadCheckerTest, SameThread) {
  ThreadChecker checker;
  EXPECT_TRUE(checker.IsCreationThreadCurrent());
}

// Note: This test depends on |std::thread| being compatible with
// |pthread_self()|.
TEST(ThreadCheckerTest, DifferentThreads) {
  ThreadChecker checker1;
  EXPECT_TRUE(checker1.IsCreationThreadCurrent());

  std::thread thread([&checker1]() {
    ThreadChecker checker2;
    EXPECT_TRUE(checker2.IsCreationThreadCurrent());
    EXPECT_FALSE(checker1.IsCreationThreadCurrent());
  });
  thread.join();

  // Note: Without synchronization, we can't look at |checker2| from the main
  // thread.
}

}  // namespace
}  // namespace fml
