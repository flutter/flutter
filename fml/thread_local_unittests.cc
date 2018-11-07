// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>

#include "flutter/fml/logging.h"
#include "flutter/fml/thread_local.h"
#include "gtest/gtest.h"

// We are only going to test the pthreads based thread local boxes.
#if FML_THREAD_LOCAL_PTHREADS

TEST(ThreadLocal, SimpleInitialization) {
  std::thread thread([&] {
    fml::ThreadLocal local;
    auto value = 100;
    local.Set(value);
    ASSERT_EQ(local.Get(), value);
  });
  thread.join();
}

TEST(ThreadLocal, SimpleInitializationCheckInAnother) {
  std::thread thread([&] {
    fml::ThreadLocal local;
    auto value = 100;
    local.Set(value);
    ASSERT_EQ(local.Get(), value);
    std::thread thread2([&]() { ASSERT_EQ(local.Get(), 0); });
    thread2.join();
  });
  thread.join();
}

TEST(ThreadLocal, DestroyCallback) {
  std::thread thread([&] {
    int destroys = 0;
    fml::ThreadLocal local([&destroys](intptr_t) { destroys++; });
    auto value = 100;
    local.Set(value);
    ASSERT_EQ(local.Get(), value);
    ASSERT_EQ(destroys, 0);
  });
  thread.join();
}

TEST(ThreadLocal, DestroyCallback2) {
  std::thread thread([&] {
    int destroys = 0;
    fml::ThreadLocal local([&destroys](intptr_t) { destroys++; });

    local.Set(100);
    ASSERT_EQ(local.Get(), 100);
    ASSERT_EQ(destroys, 0);
    local.Set(200);
    ASSERT_EQ(local.Get(), 200);
    ASSERT_EQ(destroys, 1);
  });
  thread.join();
}

TEST(ThreadLocal, DestroyThreadTimeline) {
  std::thread thread([&] {
    int destroys = 0;
    fml::ThreadLocal local([&destroys](intptr_t) { destroys++; });

    std::thread thread([&]() {
      local.Set(100);
      ASSERT_EQ(local.Get(), 100);
      ASSERT_EQ(destroys, 0);
      local.Set(200);
      ASSERT_EQ(local.Get(), 200);
      ASSERT_EQ(destroys, 1);
    });
    ASSERT_EQ(local.Get(), 0);
    thread.join();
    ASSERT_EQ(local.Get(), 0);
    ASSERT_EQ(destroys, 2);
  });
  thread.join();
}

TEST(ThreadLocal, SettingSameValue) {
  std::thread thread([&] {
    int destroys = 0;
    {
      fml::ThreadLocal local([&destroys](intptr_t) { destroys++; });

      local.Set(100);
      ASSERT_EQ(destroys, 0);
      local.Set(100);
      local.Set(100);
      local.Set(100);
      ASSERT_EQ(local.Get(), 100);
      local.Set(100);
      local.Set(100);
      ASSERT_EQ(destroys, 0);
      local.Set(200);
      ASSERT_EQ(destroys, 1);
      ASSERT_EQ(local.Get(), 200);
    }

    ASSERT_EQ(destroys, 1);
  });
  thread.join();
}

#endif  // FML_THREAD_LOCAL_PTHREADS
