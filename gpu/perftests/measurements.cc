// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/perftests/measurements.h"

#include "base/logging.h"
#include "testing/perf/perf_test.h"
#include "ui/gl/gpu_timing.h"

namespace gpu {

Measurement::Measurement() : name(), wall_time(), cpu_time(), gpu_time() {
}
Measurement::Measurement(const Measurement& m)
    : name(m.name),
      wall_time(m.wall_time),
      cpu_time(m.cpu_time),
      gpu_time(m.gpu_time) {
}
Measurement::Measurement(const std::string& name,
                         const base::TimeDelta wall_time,
                         const base::TimeDelta cpu_time,
                         const base::TimeDelta gpu_time)
    : name(name), wall_time(wall_time), cpu_time(cpu_time), gpu_time(gpu_time) {
}

void Measurement::PrintResult(const std::string& graph) const {
  perf_test::PrintResult(graph, "", name + "_wall", wall_time.InMillisecondsF(),
                         "ms", true);
  if (cpu_time.InMicroseconds() >= 0) {
    perf_test::PrintResult(graph, "", name + "_cpu", cpu_time.InMillisecondsF(),
                           "ms", true);
  }
  if (gpu_time.InMicroseconds() >= 0) {
    perf_test::PrintResult(graph, "", name + "_gpu", gpu_time.InMillisecondsF(),
                           "ms", true);
  }
}

Measurement& Measurement::Increment(const Measurement& m) {
  wall_time += m.wall_time;
  cpu_time += m.cpu_time;
  gpu_time += m.gpu_time;
  return *this;
}

Measurement Measurement::Divide(int a) const {
  return Measurement(name, wall_time / a, cpu_time / a, gpu_time / a);
}

Measurement::~Measurement() {
}

MeasurementTimers::MeasurementTimers(gfx::GPUTimingClient* gpu_timing_client)
    : wall_time_start_(), cpu_time_start_(), gpu_timer_() {
  DCHECK(gpu_timing_client);
  wall_time_start_ = base::TimeTicks::NowFromSystemTraceTime();
  if (base::TimeTicks::IsThreadNowSupported()) {
    cpu_time_start_ = base::TimeTicks::ThreadNow();
  } else {
    static bool logged_once = false;
    LOG_IF(WARNING, !logged_once) << "ThreadNow not supported.";
    logged_once = true;
  }

  if (gpu_timing_client->IsAvailable()) {
    gpu_timer_ = gpu_timing_client->CreateGPUTimer();
    gpu_timer_->Start();
  }
}

void MeasurementTimers::Record() {
  wall_time_ = base::TimeTicks::NowFromSystemTraceTime() - wall_time_start_;
  if (base::TimeTicks::IsThreadNowSupported()) {
    cpu_time_ = base::TimeTicks::ThreadNow() - cpu_time_start_;
  }
  if (gpu_timer_.get()) {
    gpu_timer_->End();
  }
}

Measurement MeasurementTimers::GetAsMeasurement(const std::string& name) {
  DCHECK_NE(base::TimeDelta(),
            wall_time_);  // At least wall_time_ has been set.

  if (!base::TimeTicks::IsThreadNowSupported()) {
    cpu_time_ = base::TimeDelta::FromMicroseconds(-1);
  }
  int64 gpu_time = -1;
  if (gpu_timer_.get() != nullptr && gpu_timer_->IsAvailable()) {
    gpu_time = gpu_timer_->GetDeltaElapsed();
  }
  return Measurement(name, wall_time_, cpu_time_,
                     base::TimeDelta::FromMicroseconds(gpu_time));
}

MeasurementTimers::~MeasurementTimers() {
  if (gpu_timer_.get()) {
    gpu_timer_->Destroy(true);
  }
}

}  // namespace gpu
