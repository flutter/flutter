// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_TIMER_HEAP_H_
#define SKY_ENGINE_TONIC_DART_TIMER_HEAP_H_

#include <unordered_map>

#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_persistent_value.h"

namespace blink {

class DartTimerHeap {
 public:
  DartTimerHeap();
  ~DartTimerHeap();

  struct Task {
    DartPersistentValue closure;
    base::TimeDelta delay;
    bool repeating = false;
  };

  int Add(std::unique_ptr<Task> task);
  void Remove(int id);

 private:
  void Schedule(int id, std::unique_ptr<Task> task);
  void Run(int id);

  int next_timer_id_;
  std::unordered_map<int, std::unique_ptr<Task>> heap_;

  base::WeakPtrFactory<DartTimerHeap> weak_factory_;
};

}

#endif  // SKY_ENGINE_TONIC_DART_TIMER_HEAP_H_
