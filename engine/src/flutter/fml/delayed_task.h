// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_DELAYED_TASK_H_
#define FLUTTER_FML_DELAYED_TASK_H_

#include <cstddef>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_source_grade.h"
#include "flutter/fml/time/time_point.h"

namespace fml {

class DelayedTask {
 public:
  DelayedTask(size_t order,
              fml::closure task,
              fml::TimePoint target_time,
              fml::TaskSourceGrade task_source_grade);

  DelayedTask(const DelayedTask& other) = default;
  DelayedTask(DelayedTask&& other) = default;
  DelayedTask& operator=(const DelayedTask& other) = default;
  DelayedTask& operator=(DelayedTask&& other) = default;

  ~DelayedTask();

  const fml::closure& GetTask() const;

  fml::closure TakeTask();

  fml::TimePoint GetTargetTime() const;

  fml::TaskSourceGrade GetTaskSourceGrade() const;

  bool operator>(const DelayedTask& other) const;

 private:
  size_t order_;
  fml::closure task_;
  fml::TimePoint target_time_;
  fml::TaskSourceGrade task_source_grade_;
};

}  // namespace fml

#endif  // FLUTTER_FML_DELAYED_TASK_H_
