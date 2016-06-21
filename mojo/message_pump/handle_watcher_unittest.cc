// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/message_pump/handle_watcher.h"

#include <string>

#include "base/at_exit.h"
#include "base/auto_reset.h"
#include "base/bind.h"
#include "base/memory/scoped_vector.h"
#include "base/run_loop.h"
#include "base/test/simple_test_tick_clock.h"
#include "base/threading/thread.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "mojo/message_pump/time_helper.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace test {

enum MessageLoopConfig {
  MESSAGE_LOOP_CONFIG_DEFAULT = 0,
  MESSAGE_LOOP_CONFIG_MOJO = 1
};

void ObserveCallback(bool* was_signaled,
                     MojoResult* result_observed,
                     MojoResult result) {
  *was_signaled = true;
  *result_observed = result;
}

void RunUntilIdle() {
  base::RunLoop run_loop;
  run_loop.RunUntilIdle();
}

void DeleteWatcherAndForwardResult(
    HandleWatcher* watcher,
    base::Callback<void(MojoResult)> next_callback,
    MojoResult result) {
  delete watcher;
  next_callback.Run(result);
}

std::unique_ptr<base::MessageLoop> CreateMessageLoop(MessageLoopConfig config) {
  std::unique_ptr<base::MessageLoop> loop;
  if (config == MESSAGE_LOOP_CONFIG_DEFAULT)
    loop.reset(new base::MessageLoop());
  else
    loop.reset(new base::MessageLoop(MessagePumpMojo::Create()));
  return loop;
}

// Helper class to manage the callback and running the message loop waiting for
// message to be received. Typical usage is something like:
//   Schedule callback returned from GetCallback().
//   RunUntilGotCallback();
//   EXPECT_TRUE(got_callback());
//   clear_callback();
class CallbackHelper {
 public:
  CallbackHelper()
      : got_callback_(false),
        run_loop_(NULL),
        weak_factory_(this) {}
  ~CallbackHelper() {}

  // See description above |got_callback_|.
  bool got_callback() const { return got_callback_; }
  void clear_callback() { got_callback_ = false; }

  // Runs the current MessageLoop until the callback returned from GetCallback()
  // is notified.
  void RunUntilGotCallback() {
    ASSERT_TRUE(run_loop_ == NULL);
    base::RunLoop run_loop;
    base::AutoReset<base::RunLoop*> reseter(&run_loop_, &run_loop);
    run_loop.Run();
  }

  base::Callback<void(MojoResult)> GetCallback() {
    return base::Bind(&CallbackHelper::OnCallback, weak_factory_.GetWeakPtr());
  }

  void Start(HandleWatcher* watcher, const MessagePipeHandle& handle) {
    StartWithCallback(watcher, handle, GetCallback());
  }

  void StartWithCallback(HandleWatcher* watcher,
                         const MessagePipeHandle& handle,
                         const base::Callback<void(MojoResult)>& callback) {
    watcher->Start(handle, MOJO_HANDLE_SIGNAL_READABLE,
                   MOJO_DEADLINE_INDEFINITE, callback);
  }

 private:
  void OnCallback(MojoResult result) {
    got_callback_ = true;
    if (run_loop_)
      run_loop_->Quit();
  }

  // Set to true when the callback is called.
  bool got_callback_;

  // If non-NULL we're in RunUntilGotCallback().
  base::RunLoop* run_loop_;

  base::WeakPtrFactory<CallbackHelper> weak_factory_;

 private:
  DISALLOW_COPY_AND_ASSIGN(CallbackHelper);
};

class HandleWatcherTest : public testing::TestWithParam<MessageLoopConfig> {
 public:
  HandleWatcherTest() : message_loop_(CreateMessageLoop(GetParam())) {}
  ~HandleWatcherTest() override {
    test::SetTickClockForTest(NULL);
  }

 protected:
  void TearDownMessageLoop() {
    message_loop_.reset();
  }

  void InstallTickClock() {
    test::SetTickClockForTest(&tick_clock_);
  }

  base::SimpleTestTickClock tick_clock_;

 private:
  base::ShadowingAtExitManager at_exit_;
  std::unique_ptr<base::MessageLoop> message_loop_;

  DISALLOW_COPY_AND_ASSIGN(HandleWatcherTest);
};

INSTANTIATE_TEST_CASE_P(
    MultipleMessageLoopConfigs, HandleWatcherTest,
    testing::Values(MESSAGE_LOOP_CONFIG_DEFAULT, MESSAGE_LOOP_CONFIG_MOJO));

// Trivial test case with a single handle to watch.
TEST_P(HandleWatcherTest, SingleHandler) {
  MessagePipe test_pipe;
  ASSERT_TRUE(test_pipe.handle0.is_valid());
  CallbackHelper callback_helper;
  HandleWatcher watcher;
  callback_helper.Start(&watcher, test_pipe.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper.got_callback());
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe.handle1.get(),
                                           std::string()));
  callback_helper.RunUntilGotCallback();
  EXPECT_TRUE(callback_helper.got_callback());
}

// Creates three handles and notfies them in reverse order ensuring each one is
// notified appropriately.
TEST_P(HandleWatcherTest, ThreeHandles) {
  MessagePipe test_pipe1;
  MessagePipe test_pipe2;
  MessagePipe test_pipe3;
  CallbackHelper callback_helper1;
  CallbackHelper callback_helper2;
  CallbackHelper callback_helper3;
  ASSERT_TRUE(test_pipe1.handle0.is_valid());
  ASSERT_TRUE(test_pipe2.handle0.is_valid());
  ASSERT_TRUE(test_pipe3.handle0.is_valid());

  HandleWatcher watcher1;
  callback_helper1.Start(&watcher1, test_pipe1.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());

  HandleWatcher watcher2;
  callback_helper2.Start(&watcher2, test_pipe2.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());

  HandleWatcher watcher3;
  callback_helper3.Start(&watcher3, test_pipe3.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());

  // Write to 3 and make sure it's notified.
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe3.handle1.get(),
                                           std::string()));
  callback_helper3.RunUntilGotCallback();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_TRUE(callback_helper3.got_callback());
  callback_helper3.clear_callback();

  // Write to 1 and 3. Only 1 should be notified since 3 was is no longer
  // running.
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe1.handle1.get(),
                                           std::string()));
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe3.handle1.get(),
                                           std::string()));
  callback_helper1.RunUntilGotCallback();
  EXPECT_TRUE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());
  callback_helper1.clear_callback();

  // Write to 1 and 2. Only 2 should be notified (since 1 was already notified).
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe1.handle1.get(),
                                           std::string()));
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe2.handle1.get(),
                                           std::string()));
  callback_helper2.RunUntilGotCallback();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_TRUE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());
}

// Verifies Start() invoked a second time works.
TEST_P(HandleWatcherTest, Restart) {
  MessagePipe test_pipe1;
  MessagePipe test_pipe2;
  CallbackHelper callback_helper1;
  CallbackHelper callback_helper2;
  ASSERT_TRUE(test_pipe1.handle0.is_valid());
  ASSERT_TRUE(test_pipe2.handle0.is_valid());

  HandleWatcher watcher1;
  callback_helper1.Start(&watcher1, test_pipe1.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());

  HandleWatcher watcher2;
  callback_helper2.Start(&watcher2, test_pipe2.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());

  // Write to 1 and make sure it's notified.
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe1.handle1.get(),
                                           std::string()));
  callback_helper1.RunUntilGotCallback();
  EXPECT_TRUE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  callback_helper1.clear_callback();
  EXPECT_TRUE(mojo::test::DiscardMessage(test_pipe1.handle0.get()));

  // Write to 2 and make sure it's notified.
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe2.handle1.get(),
                                           std::string()));
  callback_helper2.RunUntilGotCallback();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_TRUE(callback_helper2.got_callback());
  callback_helper2.clear_callback();

  // Listen on 1 again.
  callback_helper1.Start(&watcher1, test_pipe1.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());

  // Write to 1 and make sure it's notified.
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe1.handle1.get(),
                                           std::string()));
  callback_helper1.RunUntilGotCallback();
  EXPECT_TRUE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
}

// Verifies Start() invoked a second time on the same handle works.
TEST_P(HandleWatcherTest, RestartOnSameHandle) {
  MessagePipe test_pipe;
  CallbackHelper callback_helper;
  ASSERT_TRUE(test_pipe.handle0.is_valid());

  HandleWatcher watcher;
  callback_helper.Start(&watcher, test_pipe.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper.got_callback());

  callback_helper.Start(&watcher, test_pipe.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper.got_callback());
}

// Verifies deadline is honored.
TEST_P(HandleWatcherTest, Deadline) {
  InstallTickClock();

  MessagePipe test_pipe1;
  MessagePipe test_pipe2;
  MessagePipe test_pipe3;
  CallbackHelper callback_helper1;
  CallbackHelper callback_helper2;
  CallbackHelper callback_helper3;
  ASSERT_TRUE(test_pipe1.handle0.is_valid());
  ASSERT_TRUE(test_pipe2.handle0.is_valid());
  ASSERT_TRUE(test_pipe3.handle0.is_valid());

  // Add a watcher with an infinite timeout.
  HandleWatcher watcher1;
  callback_helper1.Start(&watcher1, test_pipe1.handle0.get());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());

  // Add another watcher wth a timeout of 500 microseconds.
  HandleWatcher watcher2;
  watcher2.Start(test_pipe2.handle0.get(), MOJO_HANDLE_SIGNAL_READABLE, 500,
                 callback_helper2.GetCallback());
  RunUntilIdle();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_FALSE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());

  // Advance the clock passed the deadline. We also have to start another
  // watcher to wake up the background thread.
  tick_clock_.Advance(base::TimeDelta::FromMicroseconds(501));

  HandleWatcher watcher3;
  callback_helper3.Start(&watcher3, test_pipe3.handle0.get());

  callback_helper2.RunUntilGotCallback();
  EXPECT_FALSE(callback_helper1.got_callback());
  EXPECT_TRUE(callback_helper2.got_callback());
  EXPECT_FALSE(callback_helper3.got_callback());
}

TEST_P(HandleWatcherTest, DeleteInCallback) {
  MessagePipe test_pipe;
  CallbackHelper callback_helper;

  HandleWatcher* watcher = new HandleWatcher();
  callback_helper.StartWithCallback(watcher, test_pipe.handle1.get(),
                                    base::Bind(&DeleteWatcherAndForwardResult,
                                               watcher,
                                               callback_helper.GetCallback()));
  EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe.handle0.get(),
                                           std::string()));
  callback_helper.RunUntilGotCallback();
  EXPECT_TRUE(callback_helper.got_callback());
}

TEST_P(HandleWatcherTest, AbortedOnMessageLoopDestruction) {
  bool was_signaled = false;
  MojoResult result = MOJO_RESULT_OK;

  MessagePipe pipe;
  HandleWatcher watcher;
  watcher.Start(pipe.handle0.get(),
                MOJO_HANDLE_SIGNAL_READABLE,
                MOJO_DEADLINE_INDEFINITE,
                base::Bind(&ObserveCallback, &was_signaled, &result));

  // Now, let the MessageLoop get torn down. We expect our callback to run.
  TearDownMessageLoop();

  EXPECT_TRUE(was_signaled);
  EXPECT_EQ(MOJO_RESULT_ABORTED, result);
}

void NeverReached(MojoResult result) {
  FAIL() << "Callback should never be invoked " << result;
}

// Called on the main thread when a thread is done. Decrements |active_count|
// and if |active_count| is zero quits |run_loop|.
void StressThreadDone(base::RunLoop* run_loop, int* active_count) {
  (*active_count)--;
  EXPECT_GE(*active_count, 0);
  if (*active_count == 0)
    run_loop->Quit();
}

// See description of StressTest. This is called on the background thread.
// |count| is the number of HandleWatchers to create. |active_count| is the
// number of outstanding threads, |task_runner| the task runner for the main
// thread and |run_loop| the run loop that should be quit when there are no more
// threads running. When done StressThreadDone() is invoked on the main thread.
// |active_count| and |run_loop| should only be used on the main thread.
void RunStressTest(int count,
                   scoped_refptr<base::TaskRunner> task_runner,
                   base::RunLoop* run_loop,
                   int* active_count) {
  struct TestData {
    MessagePipe pipe;
    HandleWatcher watcher;
  };
  ScopedVector<TestData> data_vector;
  for (int i = 0; i < count; ++i) {
    if (i % 20 == 0) {
      // Every so often we wait. This results in some level of thread balancing
      // as well as making sure HandleWatcher has time to actually start some
      // watches.
      MessagePipe test_pipe;
      ASSERT_TRUE(test_pipe.handle0.is_valid());
      CallbackHelper callback_helper;
      HandleWatcher watcher;
      callback_helper.Start(&watcher, test_pipe.handle0.get());
      RunUntilIdle();
      EXPECT_FALSE(callback_helper.got_callback());
      EXPECT_TRUE(mojo::test::WriteTextMessage(test_pipe.handle1.get(),
                                               std::string()));
      base::MessageLoop::ScopedNestableTaskAllower scoper(
          base::MessageLoop::current());
      callback_helper.RunUntilGotCallback();
      EXPECT_TRUE(callback_helper.got_callback());
    } else {
      std::unique_ptr<TestData> test_data(new TestData);
      ASSERT_TRUE(test_data->pipe.handle0.is_valid());
      test_data->watcher.Start(test_data->pipe.handle0.get(),
                    MOJO_HANDLE_SIGNAL_READABLE,
                    MOJO_DEADLINE_INDEFINITE,
                    base::Bind(&NeverReached));
      data_vector.push_back(test_data.release());
    }
    if (i % 15 == 0)
      data_vector.clear();
  }
  task_runner->PostTask(FROM_HERE,
                        base::Bind(&StressThreadDone, run_loop,
                                   active_count));
}

// This test is meant to stress HandleWatcher. It uses from various threads
// repeatedly starting and stopping watches. It spins up kThreadCount
// threads. Each thread creates kWatchCount watches. Every so often each thread
// writes to a pipe and waits for the response.
TEST(HandleWatcherCleanEnvironmentTest, StressTest) {
#if defined(NDEBUG)
  const int kThreadCount = 15;
  const int kWatchCount = 400;
#else
  const int kThreadCount = 10;
  const int kWatchCount = 250;
#endif

  base::ShadowingAtExitManager at_exit;
  base::MessageLoop message_loop;
  base::RunLoop run_loop;
  ScopedVector<base::Thread> threads;
  int threads_active_counter = kThreadCount;
  // Starts the threads first and then post the task in hopes of having more
  // threads running at once.
  for (int i = 0; i < kThreadCount; ++i) {
    std::unique_ptr<base::Thread> thread(new base::Thread("test thread"));
    if (i % 2) {
      base::Thread::Options thread_options;
      thread_options.message_pump_factory =
          base::Bind(&MessagePumpMojo::Create);
      thread->StartWithOptions(thread_options);
    } else {
      thread->Start();
    }
    threads.push_back(thread.release());
  }
  for (int i = 0; i < kThreadCount; ++i) {
    threads[i]->task_runner()->PostTask(
        FROM_HERE, base::Bind(&RunStressTest, kWatchCount,
                              message_loop.task_runner(),
                              &run_loop, &threads_active_counter));
  }
  run_loop.Run();
  ASSERT_EQ(0, threads_active_counter);
}

}  // namespace test
}  // namespace common
}  // namespace mojo
