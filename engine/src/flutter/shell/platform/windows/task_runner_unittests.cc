// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/task_runner.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/task_runner_window.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
class MockTaskRunner : public TaskRunner {
 public:
  MockTaskRunner(CurrentTimeProc get_current_time,
                 const TaskExpiredCallback& on_task_expired)
      : TaskRunner(get_current_time, on_task_expired) {}

  virtual bool RunsTasksOnCurrentThread() const override { return true; }

  void SimulateTimerAwake() { ProcessTasks(); }

  void AdvanceTime(std::chrono::milliseconds delay) { current_time_ += delay; }

 protected:
  virtual void WakeUp() override {
    // Do nothing to avoid processing tasks immediately after the tasks is
    // posted.
  }

  virtual TaskTimePoint GetCurrentTimeForTask() const override {
    return current_time_;
  }

 private:
  TaskTimePoint current_time_ = TaskTimePoint(
      std::chrono::duration_cast<std::chrono::steady_clock::duration>(
          std::chrono::nanoseconds(10000)));

  FML_DISALLOW_COPY_AND_ASSIGN(MockTaskRunner);
};

uint64_t MockGetCurrentTime() {
  return 10000;
}
}  // namespace

TEST(TaskRunnerTest, MaybeExecuteTaskWithExactOrder) {
  std::vector<uint64_t> executed_task_order;
  auto runner =
      MockTaskRunner(MockGetCurrentTime,
                     [&executed_task_order](const FlutterTask* expired_task) {
                       executed_task_order.push_back(expired_task->task);
                     });

  uint64_t time_now = MockGetCurrentTime();

  runner.PostFlutterTask(FlutterTask{nullptr, 1}, time_now);
  runner.PostFlutterTask(FlutterTask{nullptr, 2}, time_now);
  runner.PostTask(
      [&executed_task_order]() { executed_task_order.push_back(3); });
  runner.PostTask(
      [&executed_task_order]() { executed_task_order.push_back(4); });

  runner.SimulateTimerAwake();

  std::vector<uint64_t> posted_task_order{1, 2, 3, 4};
  EXPECT_EQ(executed_task_order, posted_task_order);
}

TEST(TaskRunnerTest, MaybeExecuteTaskOnlyExpired) {
  std::set<uint64_t> executed_task;
  auto runner = MockTaskRunner(
      MockGetCurrentTime, [&executed_task](const FlutterTask* expired_task) {
        executed_task.insert(expired_task->task);
      });

  uint64_t task_expired_before_now = 1;
  uint64_t time_before_now = 0;
  runner.PostFlutterTask(FlutterTask{nullptr, task_expired_before_now},
                         time_before_now);

  uint64_t task_expired_after_now = 2;
  uint64_t time_after_now = MockGetCurrentTime() * 2;
  runner.PostFlutterTask(FlutterTask{nullptr, task_expired_after_now},
                         time_after_now);

  runner.SimulateTimerAwake();

  std::set<uint64_t> only_task_expired_before_now{task_expired_before_now};
  EXPECT_EQ(executed_task, only_task_expired_before_now);
}

TEST(TaskRunnerTest, TimerThreadDoesNotCancelEarlierScheduledTasks) {
  std::atomic_bool signaled = false;
  std::optional<std::chrono::high_resolution_clock::time_point> callback_time;
  TimerThread timer_thread([&]() {
    callback_time = std::chrono::high_resolution_clock::now();
    signaled = true;
  });
  timer_thread.Start();
  auto now = std::chrono::high_resolution_clock::now();
  // Make sure that subsequent call to schedule does not cancel earlier task
  // as documented in TimerThread::ScheduleAt.
  timer_thread.ScheduleAt(now + std::chrono::milliseconds(20));
  timer_thread.ScheduleAt(now + std::chrono::seconds(10));

  while (!signaled.load()) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }

  EXPECT_TRUE(callback_time.has_value());
  EXPECT_GE(*callback_time, now + std::chrono::milliseconds(20));

  timer_thread.Stop();
}

TEST(TaskRunnerTest, TimerThreadUsesRescheduledEarlierDeadline) {
  std::mutex mutex;
  std::condition_variable cv;
  bool signaled = false;
  std::optional<std::chrono::high_resolution_clock::time_point> callback_time;
  TimerThread timer_thread([&]() {
    std::lock_guard<std::mutex> lock(mutex);
    callback_time = std::chrono::high_resolution_clock::now();
    signaled = true;
    cv.notify_one();
  });
  timer_thread.Start();

  const auto original_deadline =
      std::chrono::high_resolution_clock::now() + std::chrono::seconds(5);
  timer_thread.ScheduleAt(original_deadline);

  const auto earlier_deadline =
      std::chrono::high_resolution_clock::now() + std::chrono::milliseconds(20);
  timer_thread.ScheduleAt(earlier_deadline);

  std::unique_lock<std::mutex> lock(mutex);
  const bool fired_before_timeout = cv.wait_for(
      lock, std::chrono::seconds(1), [&signaled]() { return signaled; });
  lock.unlock();
  timer_thread.Stop();

  ASSERT_TRUE(fired_before_timeout);
  ASSERT_TRUE(callback_time.has_value());
  EXPECT_GE(*callback_time, earlier_deadline);
  EXPECT_LT(*callback_time, original_deadline);
}

TEST(TaskRunnerTest, TimerThreadCanRescheduleFromCallback) {
  std::mutex mutex;
  std::condition_variable cv;
  int callback_count = 0;
  TimerThread* timer = nullptr;
  TimerThread timer_thread([&]() {
    std::lock_guard<std::mutex> lock(mutex);
    callback_count++;
    if (callback_count == 1) {
      timer->ScheduleAt(std::chrono::high_resolution_clock::now() +
                        std::chrono::milliseconds(20));
    }
    cv.notify_one();
  });
  timer = &timer_thread;
  timer_thread.Start();
  timer_thread.ScheduleAt(std::chrono::high_resolution_clock::now() +
                          std::chrono::milliseconds(20));

  std::unique_lock<std::mutex> lock(mutex);
  const bool fired_twice =
      cv.wait_for(lock, std::chrono::seconds(1),
                  [&callback_count]() { return callback_count == 2; });
  lock.unlock();
  timer_thread.Stop();

  EXPECT_TRUE(fired_twice);
}

class TestTaskRunnerWindow : public TaskRunnerWindow {
 public:
  TestTaskRunnerWindow() : TaskRunnerWindow() {}
};

TEST(TaskRunnerTest, EmptyTaskRunnerReturnsNanoSecondsMax) {
  TaskRunner runner(MockGetCurrentTime, [](const FlutterTask*) {});
  auto res = runner.ProcessTasks();
  EXPECT_EQ(res, std::chrono::nanoseconds::max());
}

TEST(TaskRunnerTest, TaskRunnerWindowCoalescesWakeUpMessages) {
  class Delegate : public TaskRunnerWindow::Delegate {
   public:
    Delegate() {}

    std::chrono::nanoseconds ProcessTasks() override {
      process_tasks_call_count_++;
      return std::chrono::nanoseconds::max();
    }

    int process_tasks_call_count_ = 0;
  };

  Delegate delegate;
  TestTaskRunnerWindow window;

  window.AddDelegate(&delegate);

  window.WakeUp();
  window.WakeUp();

  ::MSG msg;
  while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  EXPECT_EQ(delegate.process_tasks_call_count_, 1);
}

TEST(TaskRunnerTest, PostDelayedTaskRunsAfterDelay) {
  bool ran = false;
  MockTaskRunner runner(MockGetCurrentTime, [](const FlutterTask*) {});

  runner.PostDelayedTask([&ran]() { ran = true; },
                         std::chrono::milliseconds(300));

  runner.SimulateTimerAwake();
  EXPECT_FALSE(ran);

  runner.AdvanceTime(std::chrono::milliseconds(299));
  runner.SimulateTimerAwake();
  EXPECT_FALSE(ran);

  runner.AdvanceTime(std::chrono::milliseconds(1));
  runner.SimulateTimerAwake();
  EXPECT_TRUE(ran);
}

}  // namespace testing
}  // namespace flutter
