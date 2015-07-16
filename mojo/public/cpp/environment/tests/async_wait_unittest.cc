// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

class TestAsyncWaitCallback {
 public:
  TestAsyncWaitCallback() : result_count_(0), last_result_(MOJO_RESULT_OK) {}
  ~TestAsyncWaitCallback() {}

  int result_count() const { return result_count_; }

  MojoResult last_result() const { return last_result_; }

  // MojoAsyncWaitCallback:
  static void OnHandleReady(void* closure, MojoResult result) {
    TestAsyncWaitCallback* self = static_cast<TestAsyncWaitCallback*>(closure);
    self->result_count_++;
    self->last_result_ = result;
  }

 private:
  int result_count_;
  MojoResult last_result_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestAsyncWaitCallback);
};

MojoAsyncWaitID CallAsyncWait(const Handle& handle,
                              MojoHandleSignals signals,
                              TestAsyncWaitCallback* callback) {
  return Environment::GetDefaultAsyncWaiter()->AsyncWait(
      handle.value(),
      signals,
      MOJO_DEADLINE_INDEFINITE,
      &TestAsyncWaitCallback::OnHandleReady,
      callback);
}

void CallCancelWait(MojoAsyncWaitID wait_id) {
  Environment::GetDefaultAsyncWaiter()->CancelWait(wait_id);
}

class AsyncWaitTest : public testing::Test {
 public:
  AsyncWaitTest() {}

 private:
  Environment environment_;
  RunLoop run_loop_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AsyncWaitTest);
};

// Verifies AsyncWaitCallback is notified when pipe is ready.
TEST_F(AsyncWaitTest, CallbackNotified) {
  TestAsyncWaitCallback callback;
  MessagePipe test_pipe;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe.handle1.get(), std::string()));

  CallAsyncWait(
      test_pipe.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE, &callback);
  RunLoop::current()->Run();
  EXPECT_EQ(1, callback.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback.last_result());
}

// Verifies 2 AsyncWaitCallbacks are notified when there pipes are ready.
TEST_F(AsyncWaitTest, TwoCallbacksNotified) {
  TestAsyncWaitCallback callback1;
  TestAsyncWaitCallback callback2;
  MessagePipe test_pipe1;
  MessagePipe test_pipe2;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe1.handle1.get(), std::string()));
  EXPECT_TRUE(test::WriteTextMessage(test_pipe2.handle1.get(), std::string()));

  CallAsyncWait(
      test_pipe1.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE, &callback1);
  CallAsyncWait(
      test_pipe2.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE, &callback2);

  RunLoop::current()->Run();
  EXPECT_EQ(1, callback1.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback1.last_result());
  EXPECT_EQ(1, callback2.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback2.last_result());
}

// Verifies cancel works.
TEST_F(AsyncWaitTest, CancelCallback) {
  TestAsyncWaitCallback callback;
  MessagePipe test_pipe;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe.handle1.get(), std::string()));

  CallCancelWait(CallAsyncWait(
      test_pipe.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE, &callback));
  RunLoop::current()->Run();
  EXPECT_EQ(0, callback.result_count());
}

}  // namespace
}  // namespace mojo
