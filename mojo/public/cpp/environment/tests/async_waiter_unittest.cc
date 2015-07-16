// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/environment/async_waiter.h"
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

  void OnHandleReady(MojoResult result) {
    result_count_++;
    last_result_ = result;
  }

 private:
  int result_count_;
  MojoResult last_result_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestAsyncWaitCallback);
};

// Manual code to create a callback since we don't have mojo::Bind yet.
class ManualCallback {
 public:
  explicit ManualCallback(TestAsyncWaitCallback* callback)
      : callback_(callback) {}

  void Run(MojoResult result) const { callback_->OnHandleReady(result); }

 private:
  TestAsyncWaitCallback* callback_;
};

class AsyncWaiterTest : public testing::Test {
 public:
  AsyncWaiterTest() {}

 private:
  Environment environment_;
  RunLoop run_loop_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AsyncWaiterTest);
};

// Verifies AsyncWaitCallback is notified when pipe is ready.
TEST_F(AsyncWaiterTest, CallbackNotified) {
  TestAsyncWaitCallback callback;
  MessagePipe test_pipe;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe.handle1.get(), std::string()));

  AsyncWaiter waiter(test_pipe.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE,
                     ManualCallback(&callback));
  RunLoop::current()->Run();
  EXPECT_EQ(1, callback.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback.last_result());
}

// Verifies 2 AsyncWaitCallbacks are notified when there pipes are ready.
TEST_F(AsyncWaiterTest, TwoCallbacksNotified) {
  TestAsyncWaitCallback callback1;
  TestAsyncWaitCallback callback2;
  MessagePipe test_pipe1;
  MessagePipe test_pipe2;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe1.handle1.get(), std::string()));
  EXPECT_TRUE(test::WriteTextMessage(test_pipe2.handle1.get(), std::string()));

  AsyncWaiter waiter1(test_pipe1.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE,
                      ManualCallback(&callback1));
  AsyncWaiter waiter2(test_pipe2.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE,
                      ManualCallback(&callback2));

  RunLoop::current()->Run();
  EXPECT_EQ(1, callback1.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback1.last_result());
  EXPECT_EQ(1, callback2.result_count());
  EXPECT_EQ(MOJO_RESULT_OK, callback2.last_result());
}

// Verifies cancel works.
TEST_F(AsyncWaiterTest, CancelCallback) {
  TestAsyncWaitCallback callback;
  MessagePipe test_pipe;
  EXPECT_TRUE(test::WriteTextMessage(test_pipe.handle1.get(), std::string()));

  {
    AsyncWaiter waiter(test_pipe.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE,
                       ManualCallback(&callback));
  }
  RunLoop::current()->Run();
  EXPECT_EQ(0, callback.result_count());
}

}  // namespace
}  // namespace mojo
