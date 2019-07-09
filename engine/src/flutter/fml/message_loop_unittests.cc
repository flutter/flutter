// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <iostream>
#include <thread>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "gtest/gtest.h"

#define TIME_SENSITIVE(x) TimeSensitiveTest_##x
#if OS_WIN
#define PLATFORM_SPECIFIC_CAPTURE(...) [ __VA_ARGS__, count ]
#else
#define PLATFORM_SPECIFIC_CAPTURE(...) [__VA_ARGS__]
#endif

TEST(MessageLoop, GetCurrent) {
  std::thread thread([]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    ASSERT_TRUE(fml::MessageLoop::GetCurrent().GetTaskRunner());
  });
  thread.join();
}

TEST(MessageLoop, DifferentThreadsHaveDifferentLoops) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });
  latch1.Wait();
  latch2.Wait();
  ASSERT_FALSE(loop1 == loop2);
  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

TEST(MessageLoop, CanRunAndTerminate) {
  bool started = false;
  bool terminated = false;
  std::thread thread([&started, &terminated]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    ASSERT_TRUE(loop.GetTaskRunner());
    loop.GetTaskRunner()->PostTask([&terminated]() {
      fml::MessageLoop::GetCurrent().Terminate();
      terminated = true;
    });
    loop.Run();
    started = true;
  });
  thread.join();
  ASSERT_TRUE(started);
  ASSERT_TRUE(terminated);
}

TEST(MessageLoop, NonDelayedTasksAreRunInOrder) {
  const size_t count = 100;
  bool started = false;
  bool terminated = false;
  std::thread thread([&started, &terminated, count]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    size_t current = 0;
    for (size_t i = 0; i < count; i++) {
      loop.GetTaskRunner()->PostTask(
          PLATFORM_SPECIFIC_CAPTURE(&terminated, i, &current)() {
            ASSERT_EQ(current, i);
            current++;
            if (count == i + 1) {
              fml::MessageLoop::GetCurrent().Terminate();
              terminated = true;
            }
          });
    }
    loop.Run();
    ASSERT_EQ(current, count);
    started = true;
  });
  thread.join();
  ASSERT_TRUE(started);
  ASSERT_TRUE(terminated);
}

TEST(MessageLoop, DelayedTasksAtSameTimeAreRunInOrder) {
  const size_t count = 100;
  bool started = false;
  bool terminated = false;
  std::thread thread([&started, &terminated, count]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    size_t current = 0;
    const auto now_plus_some =
        fml::TimePoint::Now() + fml::TimeDelta::FromMilliseconds(2);
    for (size_t i = 0; i < count; i++) {
      loop.GetTaskRunner()->PostTaskForTime(
          PLATFORM_SPECIFIC_CAPTURE(&terminated, i, &current)() {
            ASSERT_EQ(current, i);
            current++;
            if (count == i + 1) {
              fml::MessageLoop::GetCurrent().Terminate();
              terminated = true;
            }
          },
          now_plus_some);
    }
    loop.Run();
    ASSERT_EQ(current, count);
    started = true;
  });
  thread.join();
  ASSERT_TRUE(started);
  ASSERT_TRUE(terminated);
}

TEST(MessageLoop, CheckRunsTaskOnCurrentThread) {
  fml::RefPtr<fml::TaskRunner> runner;
  fml::AutoResetWaitableEvent latch;
  std::thread thread([&runner, &latch]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    runner = loop.GetTaskRunner();
    latch.Signal();
    ASSERT_TRUE(loop.GetTaskRunner()->RunsTasksOnCurrentThread());
  });
  latch.Wait();
  ASSERT_TRUE(runner);
  ASSERT_FALSE(runner->RunsTasksOnCurrentThread());
  thread.join();
}

TEST(MessageLoop, TIME_SENSITIVE(SingleDelayedTaskByDelta)) {
  bool checked = false;
  std::thread thread([&checked]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    auto begin = fml::TimePoint::Now();
    loop.GetTaskRunner()->PostDelayedTask(
        [begin, &checked]() {
          auto delta = fml::TimePoint::Now() - begin;
          auto ms = delta.ToMillisecondsF();
          ASSERT_GE(ms, 3);
          ASSERT_LE(ms, 7);
          checked = true;
          fml::MessageLoop::GetCurrent().Terminate();
        },
        fml::TimeDelta::FromMilliseconds(5));
    loop.Run();
  });
  thread.join();
  ASSERT_TRUE(checked);
}

TEST(MessageLoop, TIME_SENSITIVE(SingleDelayedTaskForTime)) {
  bool checked = false;
  std::thread thread([&checked]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    auto begin = fml::TimePoint::Now();
    loop.GetTaskRunner()->PostTaskForTime(
        [begin, &checked]() {
          auto delta = fml::TimePoint::Now() - begin;
          auto ms = delta.ToMillisecondsF();
          ASSERT_GE(ms, 3);
          ASSERT_LE(ms, 7);
          checked = true;
          fml::MessageLoop::GetCurrent().Terminate();
        },
        fml::TimePoint::Now() + fml::TimeDelta::FromMilliseconds(5));
    loop.Run();
  });
  thread.join();
  ASSERT_TRUE(checked);
}

TEST(MessageLoop, TIME_SENSITIVE(MultipleDelayedTasksWithIncreasingDeltas)) {
  const auto count = 10;
  int checked = false;
  std::thread thread(PLATFORM_SPECIFIC_CAPTURE(&checked)() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    for (int target_ms = 0 + 2; target_ms < count + 2; target_ms++) {
      auto begin = fml::TimePoint::Now();
      loop.GetTaskRunner()->PostDelayedTask(
          PLATFORM_SPECIFIC_CAPTURE(begin, target_ms, &checked)() {
            auto delta = fml::TimePoint::Now() - begin;
            auto ms = delta.ToMillisecondsF();
            ASSERT_GE(ms, target_ms - 2);
            ASSERT_LE(ms, target_ms + 2);
            checked++;
            if (checked == count) {
              fml::MessageLoop::GetCurrent().Terminate();
            }
          },
          fml::TimeDelta::FromMilliseconds(target_ms));
    }
    loop.Run();
  });
  thread.join();
  ASSERT_EQ(checked, count);
}

TEST(MessageLoop, TIME_SENSITIVE(MultipleDelayedTasksWithDecreasingDeltas)) {
  const auto count = 10;
  int checked = false;
  std::thread thread(PLATFORM_SPECIFIC_CAPTURE(&checked)() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    auto& loop = fml::MessageLoop::GetCurrent();
    for (int target_ms = count + 2; target_ms > 0 + 2; target_ms--) {
      auto begin = fml::TimePoint::Now();
      loop.GetTaskRunner()->PostDelayedTask(
          PLATFORM_SPECIFIC_CAPTURE(begin, target_ms, &checked)() {
            auto delta = fml::TimePoint::Now() - begin;
            auto ms = delta.ToMillisecondsF();
            ASSERT_GE(ms, target_ms - 2);
            ASSERT_LE(ms, target_ms + 2);
            checked++;
            if (checked == count) {
              fml::MessageLoop::GetCurrent().Terminate();
            }
          },
          fml::TimeDelta::FromMilliseconds(target_ms));
    }
    loop.Run();
  });
  thread.join();
  ASSERT_EQ(checked, count);
}

TEST(MessageLoop, TaskObserverFire) {
  bool started = false;
  bool terminated = false;
  std::thread thread([&started, &terminated]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    const size_t count = 25;
    auto& loop = fml::MessageLoop::GetCurrent();
    size_t task_count = 0;
    size_t obs_count = 0;
    auto obs = PLATFORM_SPECIFIC_CAPTURE(&obs_count)() { obs_count++; };
    for (size_t i = 0; i < count; i++) {
      loop.GetTaskRunner()->PostTask(
          PLATFORM_SPECIFIC_CAPTURE(&terminated, i, &task_count)() {
            ASSERT_EQ(task_count, i);
            task_count++;
            if (count == i + 1) {
              fml::MessageLoop::GetCurrent().Terminate();
              terminated = true;
            }
          });
    }
    loop.AddTaskObserver(0, obs);
    loop.Run();
    ASSERT_EQ(task_count, count);
    ASSERT_EQ(obs_count, count);
    started = true;
  });
  thread.join();
  ASSERT_TRUE(started);
  ASSERT_TRUE(terminated);
}

TEST(MessageLoop, CanCreateAndShutdownConcurrentMessageLoopsOverAndOver) {
  for (size_t i = 0; i < 10; ++i) {
    auto loop = fml::ConcurrentMessageLoop::Create(i + 1);
    ASSERT_EQ(loop->GetWorkerCount(), i + 1);
  }
}

TEST(MessageLoop, CanCreateConcurrentMessageLoop) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto task_runner = loop->GetTaskRunner();
  const size_t kCount = 10;
  fml::CountDownLatch latch(kCount);
  std::mutex thread_ids_mutex;
  std::set<std::thread::id> thread_ids;
  for (size_t i = 0; i < kCount; ++i) {
    task_runner->PostTask([&]() {
      std::this_thread::sleep_for(std::chrono::seconds(1));
      std::cout << "Ran on thread: " << std::this_thread::get_id() << std::endl;
      std::scoped_lock lock(thread_ids_mutex);
      thread_ids.insert(std::this_thread::get_id());
      latch.CountDown();
    });
  }
  latch.Wait();
  ASSERT_GE(thread_ids.size(), 1u);
}

TEST(MessageLoop, CanSwapMessageLoopsAndPreserveThreadConfiguration) {
  // synchronization notes:
  // 1. term1 and term2 are to wait for Swap.
  // 2. task_started_1 is to wait for the task runners
  //    to signal that they are done.
  // 3. loop_init_1 and loop_init_2 are to wait for the message loops to
  //    get initialized.

  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent loop_init_1;
  fml::AutoResetWaitableEvent task_started_1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &loop_init_1, &term1, &task_started_1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    // this task will be run on thread1 after Swap.
    loop1->GetTaskRunner()->PostTask([&task_started_1]() {
      task_started_1.Signal();
      fml::MessageLoop::GetCurrent().Terminate();
    });
    loop_init_1.Signal();
    term1.Wait();
    loop1->Run();
  });

  loop_init_1.Wait();

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent loop_init_2;
  fml::AutoResetWaitableEvent task_started_2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2(
      [&loop2, &loop_init_2, &term2, &task_started_2, &loop1]() {
        fml::MessageLoop::EnsureInitializedForCurrentThread();
        loop2 = &fml::MessageLoop::GetCurrent();
        // this task will be run on thread1 after Swap.
        loop2->GetTaskRunner()->PostTask([&task_started_2, &loop1]() {
          // ensure that we run the task on loop1 after the swap.
          ASSERT_TRUE(loop1 == &fml::MessageLoop::GetCurrent());
          task_started_2.Signal();
          fml::MessageLoop::GetCurrent().Terminate();
        });
        loop_init_2.Signal();
        term2.Wait();
        loop2->Run();
      });

  loop_init_2.Wait();

  // swap the loops.
  loop1->SwapTaskQueues(loop2);

  // thread_1 should wait for tr_term2 latch.
  term1.Signal();
  task_started_2.Wait();

  // thread_2 should wait for tr_term2 latch.
  term2.Signal();
  task_started_1.Wait();

  thread1.join();
  thread2.join();
}

TEST(MessageLoop, TIME_SENSITIVE(DelayedTaskSwap)) {
  // Task execution order:
  // time (ms): 0    10   20   30  40
  // thread 1:  A1   A2   A3   A4  TERM
  // thread 2:       B1   B2   B3  TERM

  // At time 15, we swap thread 1 and 2, and assert
  // that tasks run on the right threads.

  std::thread::id t1, t2;
  fml::AutoResetWaitableEvent tid_1, tid_2;
  fml::MessageLoop* loop1 = nullptr;
  fml::MessageLoop* loop2 = nullptr;

  std::thread thread_1([&loop1, &t1, &t2, &tid_1, &tid_2]() {
    t1 = std::this_thread::get_id();
    tid_1.Signal();
    tid_2.Wait();
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    for (int t = 0; t <= 4; t++) {
      loop1->GetTaskRunner()->PostDelayedTask(
          [t, &t1, &t2]() {
            auto cur_tid = std::this_thread::get_id();
            if (t <= 1) {
              ASSERT_EQ(cur_tid, t1);
            } else {
              ASSERT_EQ(cur_tid, t2);
            }

            if (t == 4) {
              fml::MessageLoop::GetCurrent().Terminate();
            }
          },
          fml::TimeDelta::FromMilliseconds(t * 10));
    }
    loop1->Run();
  });

  std::thread thread_2([&loop2, &t1, &t2, &tid_1, &tid_2]() {
    t2 = std::this_thread::get_id();
    tid_2.Signal();
    tid_1.Wait();
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    for (int t = 1; t <= 4; t++) {
      loop2->GetTaskRunner()->PostDelayedTask(
          [t, &t1, &t2]() {
            auto cur_tid = std::this_thread::get_id();
            if (t <= 1) {
              ASSERT_EQ(cur_tid, t2);
            } else {
              ASSERT_EQ(cur_tid, t1);
            }

            if (t == 4) {
              fml::MessageLoop::GetCurrent().Terminate();
            }
          },
          fml::TimeDelta::FromMilliseconds(t * 10));
    }
    loop2->Run();
  });

  // on main thread we swap the threads at 15 ms.
  std::this_thread::sleep_for(std::chrono::milliseconds(15));
  loop1->SwapTaskQueues(loop2);

  thread_1.join();
  thread_2.join();
}
