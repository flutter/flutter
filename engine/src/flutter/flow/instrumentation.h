// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_INSTRUMENTATION_H_
#define FLUTTER_FLOW_INSTRUMENTATION_H_

#include <vector>

#include "lib/ftl/macros.h"
#include "lib/ftl/time/time_delta.h"
#include "lib/ftl/time/time_point.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flow {

static const double kOneFrameMS = 1e3 / 60.0;

class Stopwatch {
 public:
  class ScopedLap {
   public:
    explicit ScopedLap(Stopwatch& stopwatch) : stopwatch_(stopwatch) {
      stopwatch_.Start();
    }

    ~ScopedLap() { stopwatch_.Stop(); }

   private:
    Stopwatch& stopwatch_;

    FTL_DISALLOW_COPY_AND_ASSIGN(ScopedLap);
  };

  explicit Stopwatch();
  ~Stopwatch();

  const ftl::TimeDelta& LastLap() const;
  ftl::TimeDelta CurrentLap() const { return ftl::TimePoint::Now() - start_; }
  ftl::TimeDelta MaxDelta() const;
  void Visualize(SkCanvas& canvas, const SkRect& rect) const;
  void Start();
  void Stop();
  void SetLapTime(const ftl::TimeDelta& delta);

 private:
  ftl::TimePoint start_;
  std::vector<ftl::TimeDelta> laps_;
  size_t current_sample_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

class Counter {
 public:
  explicit Counter() : count_(0) {}

  size_t count() const { return count_; }
  void Reset(size_t count = 0) { count_ = count; }
  void Increment(size_t count = 1) { count_ += count; }

 private:
  size_t count_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Counter);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_INSTRUMENTATION_H_
