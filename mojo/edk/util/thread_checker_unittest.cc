// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/thread_checker.h"

#include <thread>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace util {
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
}  // namespace util
}  // namespace mojo
