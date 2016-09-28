// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/embedder.h"

#include "base/logging.h"
#include "mojo/edk/embedder/test_embedder.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::system::test::TestIOThread;
using mojo::util::ManualResetWaitableEvent;
using mojo::util::Mutex;
using mojo::util::MutexLocker;

namespace mojo {
namespace embedder {
namespace {

class EmbedderTest : public testing::Test {
 public:
  EmbedderTest() : test_io_thread_(TestIOThread::StartMode::AUTO) {}
  ~EmbedderTest() override {}

 protected:
  TestIOThread& test_io_thread() { return test_io_thread_; }

 private:
  void SetUp() override { test::InitWithSimplePlatformSupport(); }

  void TearDown() override { EXPECT_TRUE(test::Shutdown()); }

  // TODO(vtl): We don't really need an I/O thread.
  TestIOThread test_io_thread_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(EmbedderTest);
};

class TestAsyncWaiter {
 public:
  TestAsyncWaiter() : wait_result_(MOJO_RESULT_UNKNOWN) {}

  void Awake(MojoResult result) {
    MutexLocker l(&wait_result_mutex_);
    wait_result_ = result;
    event_.Signal();
  }

  bool TryWait() {
    return !event_.WaitWithTimeout(mojo::system::test::ActionTimeout());
  }

  MojoResult wait_result() const {
    MutexLocker l(&wait_result_mutex_);
    return wait_result_;
  }

 private:
  ManualResetWaitableEvent event_;

  mutable Mutex wait_result_mutex_;
  MojoResult wait_result_ MOJO_GUARDED_BY(wait_result_mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestAsyncWaiter);
};

TEST_F(EmbedderTest, AsyncWait) {
  ScopedMessagePipeHandle client_mp;
  ScopedMessagePipeHandle server_mp;
  EXPECT_EQ(MOJO_RESULT_OK, CreateMessagePipe(nullptr, &client_mp, &server_mp));

  TestAsyncWaiter waiter;
  EXPECT_EQ(MOJO_RESULT_OK,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      [&waiter](MojoResult result) { waiter.Awake(result); }));

  // TODO(vtl): With C++14 lambda captures, we'll be able to avoid this
  // nonsense.
  {
    auto server_mp_value = server_mp.get();
    test_io_thread().PostTask([server_mp_value]() {
      static const char kHello[] = "hello";
      CHECK_EQ(MOJO_RESULT_OK,
               WriteMessageRaw(server_mp_value, kHello,
                               static_cast<uint32_t>(sizeof(kHello)), nullptr,
                               0, MOJO_WRITE_MESSAGE_FLAG_NONE));
    });
  }
  EXPECT_TRUE(waiter.TryWait());
  EXPECT_EQ(MOJO_RESULT_OK, waiter.wait_result());

  // If message is in the queue, it does't allow us to wait.
  TestAsyncWaiter waiter_that_doesnt_wait;
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      [&waiter_that_doesnt_wait](MojoResult result) {
                        waiter_that_doesnt_wait.Awake(result);
                      }));

  char buffer[1000];
  uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
  CHECK_EQ(MOJO_RESULT_OK,
           ReadMessageRaw(client_mp.get(), buffer, &num_bytes, nullptr, nullptr,
                          MOJO_READ_MESSAGE_FLAG_NONE));

  TestAsyncWaiter unsatisfiable_waiter;
  EXPECT_EQ(MOJO_RESULT_OK,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      [&unsatisfiable_waiter](MojoResult result) {
                        unsatisfiable_waiter.Awake(result);
                      }));

  // TODO(vtl): With C++14 lambda captures, we'll be able to avoid this
  // nonsense (and use |Close()| rather than |CloseRaw()|).
  {
    auto server_mp_value = server_mp.release();
    test_io_thread().PostTask(
        [server_mp_value]() { CloseRaw(server_mp_value); });
  }

  EXPECT_TRUE(unsatisfiable_waiter.TryWait());
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            unsatisfiable_waiter.wait_result());
}

}  // namespace
}  // namespace embedder
}  // namespace mojo
