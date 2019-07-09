// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/concurrent_message_loop.h"

#include <algorithm>

#include "flutter/fml/thread.h"
#include "flutter/fml/trace_event.h"

namespace fml {

std::shared_ptr<ConcurrentMessageLoop> ConcurrentMessageLoop::Create(
    size_t worker_count) {
  return std::shared_ptr<ConcurrentMessageLoop>{
      new ConcurrentMessageLoop(worker_count)};
}

ConcurrentMessageLoop::ConcurrentMessageLoop(size_t worker_count)
    : worker_count_(std::max<size_t>(worker_count, 1ul)) {
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
  for (auto& worker : workers_) {
    worker.join();
  }
}

size_t ConcurrentMessageLoop::GetWorkerCount() const {
  return worker_count_;
}

std::shared_ptr<ConcurrentTaskRunner> ConcurrentMessageLoop::GetTaskRunner() {
  return std::make_shared<ConcurrentTaskRunner>(weak_from_this());
}

void ConcurrentMessageLoop::PostTask(fml::closure task) {
  if (!task) {
    return;
  }

  std::unique_lock lock(tasks_mutex_);

  // Don't just drop tasks on the floor in case of shutdown.
  if (shutdown_) {
    FML_DLOG(WARNING)
        << "Tried to post a task to shutdown concurrent message "
           "loop. The task will be executed on the callers thread.";
    lock.unlock();
    task();
    return;
  }

  tasks_.push(task);

  // Unlock the mutex before notifying the condition variable because that mutex
  // has to be acquired on the other thread anyway. Waiting in this scope till
  // it is acquired there is a pessimization.
  lock.unlock();

  tasks_condition_.notify_one();
}

void ConcurrentMessageLoop::WorkerMain() {
  while (true) {
    std::unique_lock lock(tasks_mutex_);
    tasks_condition_.wait(lock,
                          [&]() { return tasks_.size() > 0 || shutdown_; });

    if (tasks_.size() == 0) {
      // This can only be caused by shutdown.
      FML_DCHECK(shutdown_);
      break;
    }

    auto task = tasks_.front();
    tasks_.pop();

    // Don't hold onto the mutex while the task is being executed as it could
    // itself try to post another tasks to this message loop.
    lock.unlock();

    TRACE_EVENT0("flutter", "ConcurrentWorkerWake");
    // Execute the one tasks we woke up for.
    task();
  }
}

void ConcurrentMessageLoop::Terminate() {
  std::scoped_lock lock(tasks_mutex_);
  shutdown_ = true;
  tasks_condition_.notify_all();
}

ConcurrentTaskRunner::ConcurrentTaskRunner(
    std::weak_ptr<ConcurrentMessageLoop> weak_loop)
    : weak_loop_(std::move(weak_loop)) {}

ConcurrentTaskRunner::~ConcurrentTaskRunner() = default;

void ConcurrentTaskRunner::PostTask(fml::closure task) {
  if (!task) {
    return;
  }

  if (auto loop = weak_loop_.lock()) {
    loop->PostTask(task);
    return;
  }

  FML_DLOG(WARNING)
      << "Tried to post to a concurrent message loop that has already died. "
         "Executing the task on the callers thread.";
  task();
}

}  // namespace fml
