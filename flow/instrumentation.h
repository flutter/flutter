// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_INSTRUMENTATION_H_
#define FLOW_INSTRUMENTATION_H_

#include <vector>
#include "base/macros.h"
#include "base/time/time.h"
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

    DISALLOW_COPY_AND_ASSIGN(ScopedLap);
  };

  explicit Stopwatch();
  ~Stopwatch();

  const base::TimeDelta& LastLap() const;
  base::TimeDelta CurrentLap() const { return base::TimeTicks::Now() - start_; }
  base::TimeDelta MaxDelta() const;
  void Visualize(SkCanvas& canvas, const SkRect& rect) const;
  void Start();
  void Stop();
  void SetLapTime(const base::TimeDelta& delta);

 private:
  base::TimeTicks start_;
  std::vector<base::TimeDelta> laps_;
  size_t current_sample_;

  DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

class Counter {
 public:
  explicit Counter() : count_(0) {}

  size_t count() const { return count_; }
  void Reset(size_t count = 0) { count_ = count; }
  void Increment(size_t count = 1) { count_ += count; }

 private:
  size_t count_;

  DISALLOW_COPY_AND_ASSIGN(Counter);
};

}  // namespace flow

#endif  // FLOW_INSTRUMENTATION_H_
