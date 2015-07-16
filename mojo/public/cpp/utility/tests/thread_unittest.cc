// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/thread.h"

#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

class SetIntThread : public Thread {
 public:
  SetIntThread(int* int_to_set, int value)
      : int_to_set_(int_to_set),
        value_(value) {
  }
  SetIntThread(const Options& options, int* int_to_set, int value)
      : Thread(options),
        int_to_set_(int_to_set),
        value_(value) {
  }

  ~SetIntThread() override {}

  void Run() override { *int_to_set_ = value_; }

 private:
  int* const int_to_set_;
  const int value_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SetIntThread);
};

TEST(ThreadTest, CreateAndJoin) {
  int value = 0;

  // Not starting the thread should result in a no-op.
  {
    SetIntThread thread(&value, 1234567);
  }
  EXPECT_EQ(0, value);

  // Start and join.
  {
    SetIntThread thread(&value, 12345678);
    thread.Start();
    thread.Join();
    EXPECT_EQ(12345678, value);
  }

  // Ditto, with non-default (but reasonable) stack size.
  {
    Thread::Options options;
    options.set_stack_size(1024 * 1024);  // 1 MB.
    SetIntThread thread(options, &value, 12345678);
    thread.Start();
    thread.Join();
    EXPECT_EQ(12345678, value);
  }
}

// Tests of assertions for Debug builds.
// Note: It's okay to create threads, despite gtest having to fork. (The threads
// are in the child process.)
#if !defined(NDEBUG)
TEST(ThreadTest, DebugAssertionFailures) {
  // Can only start once.
  EXPECT_DEATH_IF_SUPPORTED({
    int value = 0;
    SetIntThread thread(&value, 1);
    thread.Start();
    thread.Start();
  }, "");

  // Must join (if you start).
  EXPECT_DEATH_IF_SUPPORTED({
    int value = 0;
    SetIntThread thread(&value, 2);
    thread.Start();
  }, "");

  // Can only join once.
  EXPECT_DEATH_IF_SUPPORTED({
    int value = 0;
    SetIntThread thread(&value, 3);
    thread.Start();
    thread.Join();
    thread.Join();
  }, "");

  // Stack too big (we're making certain assumptions here).
  EXPECT_DEATH_IF_SUPPORTED({
    int value = 0;
    Thread::Options options;
    options.set_stack_size(static_cast<size_t>(-1));
    SetIntThread thread(options, &value, 4);
    thread.Start();
    thread.Join();
  }, "");
}
#endif  // !defined(NDEBUG)

}  // namespace
}  // namespace mojo
