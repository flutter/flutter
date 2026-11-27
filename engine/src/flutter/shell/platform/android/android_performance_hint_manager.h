// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PERFORMANCE_HINT_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PERFORMANCE_HINT_MANAGER_H_

#include <cstdint>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Manages an Android Dynamic Performance Framework (ADPF)
///             APerformanceHintSession for communicating frame target and
///             actual work durations directly to the Android vendor PowerHAL.
///
///             This informs the system PowerHAL of workload deadlines, enabling
///             proactive DVFS frequency scaling and thread scheduling
///             adjustments for Flutter's UI and Raster threads.
///
class AndroidPerformanceHintManager {
 public:
  static std::unique_ptr<AndroidPerformanceHintManager> Create(
      const std::vector<int32_t>& tids,
      int64_t target_duration_ns);

  ~AndroidPerformanceHintManager();

  void ReportActualWorkDuration(int64_t work_period_start_ns,
                                int64_t actual_total_duration_ns,
                                int64_t actual_cpu_duration_ns,
                                int64_t actual_gpu_duration_ns = 0);

  void UpdateTargetWorkDuration(int64_t target_duration_ns);

  int64_t GetTargetWorkDuration() const;

 private:
  struct Impl;
  explicit AndroidPerformanceHintManager(std::unique_ptr<Impl> impl);

  std::unique_ptr<Impl> impl_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidPerformanceHintManager);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PERFORMANCE_HINT_MANAGER_H_
