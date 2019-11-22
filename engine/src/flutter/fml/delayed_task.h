// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_DELAYED_TASK_H_
#define FLUTTER_FML_DELAYED_TASK_H_

#include "flutter/fml/closure.h"
#include "flutter/fml/time/time_point.h"

#include <queue>

namespace fml {

class DelayedTask {
 public:
  DelayedTask(size_t order,
              const fml::closure& task,
              fml::TimePoint target_time);

  DelayedTask(const DelayedTask& other);

  ~DelayedTask();

  const fml::closure& GetTask() const;

  fml::TimePoint GetTargetTime() const;

  bool operator>(const DelayedTask& other) const;

 private:
  size_t order_;
  fml::closure task_;
  fml::TimePoint target_time_;
};

using DelayedTaskQueue = std::priority_queue<DelayedTask,
                                             std::deque<DelayedTask>,
                                             std::greater<DelayedTask>>;

}  // namespace fml

#endif  // FLUTTER_FML_DELAYED_TASK_H_
