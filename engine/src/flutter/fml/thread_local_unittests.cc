// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atomic>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/fml/thread_local.h"
#include "gtest/gtest.h"

namespace {

class Box {
 public:
  explicit Box(int value, std::atomic_int* destroys = nullptr)
      : value_(value), destroys_(destroys) {}
  ~Box() {
    if (destroys_) {
      ++*destroys_;
    }
  }

  int value() const { return value_; }

 private:
  int value_;
  std::atomic_int* destroys_;

  FML_DISALLOW_COPY_AND_ASSIGN(Box);
};

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<Box> local;

}  // namespace

TEST(ThreadLocal, SimpleInitialization) {
  std::thread thread([&] {
    ASSERT_EQ(local.get(), nullptr);
    auto value = 100;
    local.reset(new Box(value));
    ASSERT_EQ(local.get()->value(), value);
  });
  thread.join();
}

TEST(ThreadLocal, SimpleInitializationCheckInAnother) {
  std::thread thread([&] {
    ASSERT_EQ(local.get(), nullptr);
    auto value = 100;
    local.reset(new Box(value));
    ASSERT_EQ(local.get()->value(), value);
    std::thread thread2([&]() { ASSERT_EQ(local.get(), nullptr); });
    thread2.join();
  });
  thread.join();
}

TEST(ThreadLocal, DestroyCallback) {
  std::atomic_int destroys{0};
  std::thread thread([&] {
    ASSERT_EQ(local.get(), nullptr);
    auto value = 100;
    local.reset(new Box(value, &destroys));
    ASSERT_EQ(local.get()->value(), value);
    ASSERT_EQ(destroys.load(), 0);
  });
  thread.join();
  ASSERT_EQ(destroys.load(), 1);
}

TEST(ThreadLocal, DestroyCallback2) {
  std::atomic_int destroys{0};
  std::thread thread([&] {
    local.reset(new Box(100, &destroys));
    ASSERT_EQ(local.get()->value(), 100);
    ASSERT_EQ(destroys.load(), 0);
    local.reset(new Box(200, &destroys));
    ASSERT_EQ(local.get()->value(), 200);
    ASSERT_EQ(destroys.load(), 1);
  });
  thread.join();
  ASSERT_EQ(destroys.load(), 2);
}

TEST(ThreadLocal, DestroyThreadTimeline) {
  std::atomic_int destroys{0};
  std::thread thread([&] {
    std::thread thread2([&]() {
      local.reset(new Box(100, &destroys));
      ASSERT_EQ(local.get()->value(), 100);
      ASSERT_EQ(destroys.load(), 0);
      local.reset(new Box(200, &destroys));
      ASSERT_EQ(local.get()->value(), 200);
      ASSERT_EQ(destroys.load(), 1);
    });
    ASSERT_EQ(local.get(), nullptr);
    thread2.join();
    ASSERT_EQ(local.get(), nullptr);
    ASSERT_EQ(destroys.load(), 2);
  });
  thread.join();
  ASSERT_EQ(destroys.load(), 2);
}
