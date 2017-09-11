// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_INSTRUMENTATION_H_
#define FLUTTER_FLOW_INSTRUMENTATION_H_

#include <vector>

#include "lib/fxl/macros.h"
#include "lib/fxl/time/time_delta.h"
#include "lib/fxl/time/time_point.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flow {

static const double kOneFrameMS = 1e3 / 60.0;

class Stopwatch {
 public:
  Stopwatch();

  ~Stopwatch();

  const fxl::TimeDelta& LastLap() const;

  fxl::TimeDelta CurrentLap() const { return fxl::TimePoint::Now() - start_; }

  fxl::TimeDelta MaxDelta() const;

  void Visualize(SkCanvas& canvas, const SkRect& rect) const;

  void Start();

  void Stop();

  void SetLapTime(const fxl::TimeDelta& delta);

 private:
  fxl::TimePoint start_;
  std::vector<fxl::TimeDelta> laps_;
  size_t current_sample_;

  FXL_DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

class Counter {
 public:
  Counter() : count_(0) {}

  size_t count() const { return count_; }

  void Reset(size_t count = 0) { count_ = count; }

  void Increment(size_t count = 1) { count_ += count; }

 private:
  size_t count_;

  FXL_DISALLOW_COPY_AND_ASSIGN(Counter);
};

class CounterValues {
 public:
  CounterValues();

  ~CounterValues();

  void Add(int64_t value);

  void Visualize(SkCanvas& canvas, const SkRect& rect) const;

  int64_t GetCurrentValue() const;

  int64_t GetMaxValue() const;

  int64_t GetMinValue() const;

 private:
  std::vector<int64_t> values_;
  size_t current_sample_;

  FXL_DISALLOW_COPY_AND_ASSIGN(CounterValues);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_INSTRUMENTATION_H_
