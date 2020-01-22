// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_GLFW_GLFW_EVENT_LOOP_H_
#define FLUTTER_SHELL_PLATFORM_GLFW_GLFW_EVENT_LOOP_H_

#include <chrono>
#include <deque>
#include <functional>
#include <mutex>
#include <queue>
#include <thread>

#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

// An event loop implementation that supports Flutter Engine tasks scheduling in
// the GLFW event loop.
class GLFWEventLoop {
 public:
  using TaskExpiredCallback = std::function<void(const FlutterTask*)>;
  GLFWEventLoop(std::thread::id main_thread_id,
                const TaskExpiredCallback& on_task_expired);

  ~GLFWEventLoop();

  // Returns if the current thread is the thread used by the GLFW event loop.
  bool RunsTasksOnCurrentThread() const;

  // Wait for an any GLFW or pending Flutter Engine events and returns when
  // either is encountered. Expired engine events are processed. The optional
  // timeout should only be used when non-GLFW or engine events need to be
  // processed in a polling manner.
  void WaitForEvents(
      std::chrono::nanoseconds max_wait = std::chrono::nanoseconds::max());

  // Post a Flutter engine tasks to the event loop for delayed execution.
  void PostTask(FlutterTask flutter_task, uint64_t flutter_target_time_nanos);

 private:
  using TaskTimePoint = std::chrono::steady_clock::time_point;
  struct Task {
    uint64_t order;
    TaskTimePoint fire_time;
    FlutterTask task;

    struct Comparer {
      bool operator()(const Task& a, const Task& b) {
        if (a.fire_time == b.fire_time) {
          return a.order > b.order;
        }
        return a.fire_time > b.fire_time;
      }
    };
  };
  std::thread::id main_thread_id_;
  TaskExpiredCallback on_task_expired_;
  std::mutex task_queue_mutex_;
  std::priority_queue<Task, std::deque<Task>, Task::Comparer> task_queue_;
  std::condition_variable task_queue_cv_;

  GLFWEventLoop(const GLFWEventLoop&) = delete;

  GLFWEventLoop& operator=(const GLFWEventLoop&) = delete;

  static TaskTimePoint TimePointFromFlutterTime(
      uint64_t flutter_target_time_nanos);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_GLFW_GLFW_EVENT_LOOP_H_
