// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"

#include <vector>

// MOCK_ENGINE_PROC is leaky by design.
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

// Test fixture that provides an engine (with a real binary messenger) and a
// main loop via the shared LinuxTest base.
class FlTaskRunnerTest : public flutter::testing::LinuxTest {};

// Builds a FlutterTask carrying the given identifier. The runner pointer is
// unused as the engine's RunTask is mocked out in these tests.
static FlutterTask make_task(uint64_t id) {
  FlutterTask task = {};
  task.runner = nullptr;
  task.task = id;
  return task;
}

// The default maximum time pump_main_loop_until waits for its predicate to
// become true before giving up.
static constexpr gint64 kDefaultPumpTimeoutMicros = 10 * G_USEC_PER_SEC;

// Iterates the default main context until either the timeout elapses or the
// predicate returns true.
template <typename Predicate>
static void pump_main_loop_until(Predicate predicate,
                                 gint64 timeout = kDefaultPumpTimeoutMicros) {
  gint64 deadline = g_get_monotonic_time() + timeout;
  while (!predicate() && g_get_monotonic_time() < deadline) {
    g_main_context_iteration(nullptr, TRUE);
  }
}

// A posted task is executed on the main loop and forwarded to the engine.
TEST_F(FlTaskRunnerTest, PostTaskExecutedOnMainLoop) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  std::vector<uint64_t> executed;
  fl_engine_get_embedder_api(engine)->RunTask = MOCK_ENGINE_PROC(
      RunTask, ([&executed](auto engine, const FlutterTask* task) {
        executed.push_back(task->task);
        return kSuccess;
      }));

  // A target time in the past means the task is due immediately.
  fl_task_runner_post_flutter_task(task_runner, make_task(42), 0);

  pump_main_loop_until([&executed]() { return !executed.empty(); });

  ASSERT_EQ(executed.size(), 1u);
  EXPECT_EQ(executed[0], 42u);
}

// Multiple posted tasks are all executed.
TEST_F(FlTaskRunnerTest, MultipleTasksExecuted) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  std::vector<uint64_t> executed;
  fl_engine_get_embedder_api(engine)->RunTask = MOCK_ENGINE_PROC(
      RunTask, ([&executed](auto engine, const FlutterTask* task) {
        executed.push_back(task->task);
        return kSuccess;
      }));

  fl_task_runner_post_flutter_task(task_runner, make_task(1), 0);
  fl_task_runner_post_flutter_task(task_runner, make_task(2), 0);
  fl_task_runner_post_flutter_task(task_runner, make_task(3), 0);

  pump_main_loop_until([&executed]() { return executed.size() >= 3; });

  ASSERT_EQ(executed.size(), 3u);
  EXPECT_EQ(executed[0], 1u);
  EXPECT_EQ(executed[1], 2u);
  EXPECT_EQ(executed[2], 3u);
}

// A task whose target time has not yet arrived is still eventually executed.
TEST_F(FlTaskRunnerTest, DelayedTaskExecuted) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  gboolean executed = FALSE;
  fl_engine_get_embedder_api(engine)->RunTask = MOCK_ENGINE_PROC(
      RunTask, ([&executed](auto engine, const FlutterTask* task) {
        executed = TRUE;
        return kSuccess;
      }));

  // Schedule roughly 20ms into the future (target time is in nanoseconds).
  uint64_t target_time_nanos =
      (g_get_monotonic_time() + 20 * G_TIME_SPAN_MILLISECOND) * 1000;
  fl_task_runner_post_flutter_task(task_runner, make_task(7),
                                   target_time_nanos);

  // Not run before its time.
  EXPECT_FALSE(executed);

  pump_main_loop_until([&executed]() { return executed; });

  EXPECT_TRUE(executed);
}

// fl_task_runner_wait runs a task that is already due without needing the main
// loop.
TEST_F(FlTaskRunnerTest, WaitRunsExpiredTask) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  std::vector<uint64_t> executed;
  fl_engine_get_embedder_api(engine)->RunTask = MOCK_ENGINE_PROC(
      RunTask, ([&executed](auto engine, const FlutterTask* task) {
        executed.push_back(task->task);
        return kSuccess;
      }));

  fl_task_runner_post_flutter_task(task_runner, make_task(99), 0);

  // The task is already due, so wait processes it and returns immediately.
  fl_task_runner_wait(task_runner, g_get_monotonic_time() + G_USEC_PER_SEC);

  ASSERT_EQ(executed.size(), 1u);
  EXPECT_EQ(executed[0], 99u);
}

struct StopWaitData {
  FlTaskRunner* task_runner;
  gint done;
};

// Repeatedly interrupts fl_task_runner_wait until the main thread signals that
// the wait has returned. Repeating guards against the interrupt arriving before
// the wait has started blocking.
static gpointer stop_wait_thread(gpointer user_data) {
  StopWaitData* data = static_cast<StopWaitData*>(user_data);
  while (g_atomic_int_get(&data->done) == 0) {
    g_usleep(10 * G_TIME_SPAN_MILLISECOND);
    fl_task_runner_stop_wait(data->task_runner);
  }
  return nullptr;
}

// fl_task_runner_stop_wait causes a blocking fl_task_runner_wait to return.
TEST_F(FlTaskRunnerTest, StopWaitInterruptsWait) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  StopWaitData data = {task_runner, 0};
  GThread* thread = g_thread_new("stop-wait", stop_wait_thread, &data);

  // With no tasks scheduled this would otherwise block until the far-future
  // expiry time.
  gint64 start = g_get_monotonic_time();
  fl_task_runner_wait(task_runner, start + 30 * G_USEC_PER_SEC);
  gint64 elapsed = g_get_monotonic_time() - start;

  g_atomic_int_set(&data.done, 1);
  g_thread_join(thread);

  // The wait returned because of stop_wait, well before the 30s expiry.
  EXPECT_LT(elapsed, 5 * G_USEC_PER_SEC);
}

// Calling fl_task_runner_stop_wait when no wait is in progress is a no-op: the
// runner still works and a later wait runs a due task (the stray signal is not
// "remembered" to interrupt the subsequent wait).
TEST_F(FlTaskRunnerTest, StopWaitWithoutWaitIsNoOp) {
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);

  std::vector<uint64_t> executed;
  fl_engine_get_embedder_api(engine)->RunTask = MOCK_ENGINE_PROC(
      RunTask, ([&executed](auto engine, const FlutterTask* task) {
        executed.push_back(task->task);
        return kSuccess;
      }));

  // No wait is in progress, so this should do nothing.
  fl_task_runner_stop_wait(task_runner);

  // The runner is still functional: a due task is run by a subsequent wait.
  fl_task_runner_post_flutter_task(task_runner, make_task(123), 0);
  fl_task_runner_wait(task_runner, g_get_monotonic_time() + G_USEC_PER_SEC);

  ASSERT_EQ(executed.size(), 1u);
  EXPECT_EQ(executed[0], 123u);
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
