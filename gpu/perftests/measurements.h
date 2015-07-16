// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_PERFTESTS_MEASUREMENTS_H_
#define GPU_PERFTESTS_MEASUREMENTS_H_

#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"

namespace gfx {
class GPUTimingClient;
class GPUTimer;
}

namespace gpu {

struct Measurement {
  Measurement();
  Measurement(const Measurement& m);
  Measurement(const std::string& name,
              const base::TimeDelta wall_time,
              const base::TimeDelta cpu_time,
              const base::TimeDelta gpu_time);
  ~Measurement();

  void PrintResult(const std::string& graph) const;
  Measurement& Increment(const Measurement& m);
  Measurement Divide(int a) const;

  std::string name;
  base::TimeDelta wall_time;
  base::TimeDelta cpu_time;
  base::TimeDelta gpu_time;
};

// Class to measure wall, cpu and gpu time deltas.
// The deltas are measured from the time of the object
// creation up to when Record is called.
class MeasurementTimers {
 public:
  explicit MeasurementTimers(gfx::GPUTimingClient* gpu_timing_client);
  void Record();
  Measurement GetAsMeasurement(const std::string& name);
  ~MeasurementTimers();

 private:
  base::TimeTicks wall_time_start_;
  base::TimeTicks cpu_time_start_;
  scoped_ptr<gfx::GPUTimer> gpu_timer_;

  base::TimeDelta wall_time_;
  base::TimeDelta cpu_time_;
};

}  // namespace gpu

#endif  // GPU_PERFTESTS_MEASUREMENTS_H_
