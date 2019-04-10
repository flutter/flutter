// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_
#define FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <thread>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop_impl.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/thread_annotations.h"

namespace fml {

class ConcurrentMessageLoop : public MessageLoopImpl {
 private:
  const size_t worker_count_;
  std::mutex wait_condition_mutex_;
  std::condition_variable wait_condition_;
  std::vector<std::thread> workers_;
  CountDownLatch shutdown_latch_;
  std::chrono::high_resolution_clock::time_point next_wake_;
  std::atomic_bool shutdown_;

  ConcurrentMessageLoop();

  ~ConcurrentMessageLoop();

  // |fml::MessageLoopImpl|
  void Run() override;

  // |fml::MessageLoopImpl|
  void Terminate() override;

  // |fml::MessageLoopImpl|
  void WakeUp(fml::TimePoint time_point) override;

  static void WorkerMain(ConcurrentMessageLoop* loop);

  void WorkerMain();

  FML_FRIEND_MAKE_REF_COUNTED(ConcurrentMessageLoop);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(ConcurrentMessageLoop);
  FML_DISALLOW_COPY_AND_ASSIGN(ConcurrentMessageLoop);
};

}  // namespace fml

#endif  // FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_
