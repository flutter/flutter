// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop_task_queues.h"

#include <array>
#include <cassert>
#include <cstdint>
#include <string>
#include <thread>
#include <vector>

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/count_down_latch.h"

namespace fml {
namespace benchmarking {

static void BM_RegisterAndGetTasks(benchmark::State& state) {  // NOLINT
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  const int num_task_queues = 10;
  const int num_tasks_per_queue = 100;

  while (state.KeepRunning()) {
    const fml::TimePoint past = fml::TimePoint::Now();

    std::vector<TaskQueueId> queue_ids;
    queue_ids.reserve(num_task_queues);
    for (int i = 0; i < num_task_queues; i++) {
      queue_ids.push_back(task_queue->CreateTaskQueue());
    }

    std::vector<std::thread> threads;

    CountDownLatch tasks_registered(num_task_queues);
    CountDownLatch tasks_done(num_task_queues);

    threads.reserve(num_task_queues);
    for (int i = 0; i < num_task_queues; i++) {
      threads.emplace_back([queue_id = queue_ids[i], &task_queue, past,
                            &tasks_done, &tasks_registered]() {
        for (int j = 0; j < num_tasks_per_queue; j++) {
          task_queue->RegisterTask(queue_id, [] {}, past);
        }
        tasks_registered.CountDown();
        tasks_registered.Wait();
        const auto now = fml::TimePoint::Now();
        int num_invocations = 0;
        for (;;) {
          fml::closure invocation = task_queue->GetNextTaskToRun(queue_id, now);
          if (!invocation) {
            break;
          }
          num_invocations++;
        }
        assert(num_invocations == num_tasks_per_queue);
        tasks_done.CountDown();
      });
    }

    tasks_done.Wait();

    for (auto& thread : threads) {
      thread.join();
    }
    for (TaskQueueId queue_id : queue_ids) {
      task_queue->Dispose(queue_id);
    }
  }
}

static void BM_RegisterAndGetTasksNonSBO(benchmark::State& state) {  // NOLINT
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  TaskQueueId queue_id = task_queue->CreateTaskQueue();
  const int num_tasks = 256;

  while (state.KeepRunning()) {
    const fml::TimePoint base = fml::TimePoint::Now();
    for (int i = 0; i < num_tasks; ++i) {
      std::array<uint8_t, 48> payload{};
      payload[0] = static_cast<uint8_t>(i);
      // Reverse target times force full priority-queue sift-up on every push.
      task_queue->RegisterTask(
          queue_id, [payload]() { benchmark::DoNotOptimize(payload); },
          base - fml::TimeDelta::FromMicroseconds(i));
    }
    const auto now = fml::TimePoint::Now();
    int drained = 0;
    while (fml::closure invocation =
               task_queue->GetNextTaskToRun(queue_id, now)) {
      benchmark::DoNotOptimize(invocation);
      ++drained;
    }
    FML_CHECK(drained == num_tasks);
  }
  task_queue->Dispose(queue_id);
}

BENCHMARK(BM_RegisterAndGetTasks);
BENCHMARK(BM_RegisterAndGetTasksNonSBO);

}  // namespace benchmarking
}  // namespace fml
