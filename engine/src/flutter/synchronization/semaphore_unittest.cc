// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>

#include "flutter/synchronization/semaphore.h"
#include "gtest/gtest.h"

TEST(SemaphoreTest, SimpleValidity) {
  flutter::Semaphore sem(100);
  ASSERT_TRUE(sem.IsValid());
}

TEST(SemaphoreTest, WaitOnZero) {
  flutter::Semaphore sem(0);
  ASSERT_FALSE(sem.TryWait());
}

TEST(SemaphoreTest, WaitOnZeroSignalThenWait) {
  flutter::Semaphore sem(0);
  ASSERT_FALSE(sem.TryWait());
  std::thread thread([&sem]() { sem.Signal(); });
  thread.join();
  ASSERT_TRUE(sem.TryWait());
  ASSERT_FALSE(sem.TryWait());
}
