// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/concurrent_message_loop.h"

#include <algorithm>

#include "flutter/fml/thread.h"
#include "flutter/fml/trace_event.h"

namespace fml {

ConcurrentMessageLoop::ConcurrentMessageLoop()
    : worker_count_(std::max(std::thread::hardware_concurrency(), 1u)),
      shutdown_latch_(worker_count_),
      shutdown_(false) {
  for (size_t i = 0; i < worker_count_; ++i) {
    workers_.emplace_back([i, this]() {
      fml::Thread::SetCurrentThreadName(
          std::string{"io.flutter.worker." + std::to_string(i + 1)});
      WorkerMain();
    });
  }
}

ConcurrentMessageLoop::~ConcurrentMessageLoop() {
  Terminate();
  shutdown_latch_.Wait();
  for (auto& worker : workers_) {
    worker.join();
  }
}

// |fml::MessageLoopImpl|
void ConcurrentMessageLoop::Run() {
  FML_CHECK(false);
}

// |fml::MessageLoopImpl|
void ConcurrentMessageLoop::Terminate() {
  std::scoped_lock lock(wait_condition_mutex_);
  shutdown_ = true;
  wait_condition_.notify_all();
}

// |fml::MessageLoopImpl|
void ConcurrentMessageLoop::WakeUp(fml::TimePoint time_point) {
  // Assume that the clocks are not the same.
  const auto duration = std::chrono::nanoseconds(
      (time_point - fml::TimePoint::Now()).ToNanoseconds());
  next_wake_ = std::chrono::high_resolution_clock::now() + duration;
  wait_condition_.notify_all();
}

void ConcurrentMessageLoop::WorkerMain() {
  while (!shutdown_) {
    std::unique_lock<std::mutex> lock(wait_condition_mutex_);
    if (!shutdown_) {
      wait_condition_.wait(lock);
    }
    TRACE_EVENT0("fml", "ConcurrentWorkerWake");
    RunSingleExpiredTaskNow();
  }

  RunExpiredTasksNow();
  shutdown_latch_.CountDown();
}

}  // namespace fml
