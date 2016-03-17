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
namespace instrumentation {

static const double kOneFrameMS = 1e3 / 60.0;

class Stopwatch {
 public:
  class ScopedLap {
   public:
    explicit ScopedLap(Stopwatch& stopwatch) : _stopwatch(stopwatch) {
      _stopwatch.start();
    }

    ~ScopedLap() { _stopwatch.stop(); }

   private:
    Stopwatch& _stopwatch;

    DISALLOW_COPY_AND_ASSIGN(ScopedLap);
  };

  explicit Stopwatch();
  ~Stopwatch();

  const base::TimeDelta& lastLap() const;

  base::TimeDelta currentLap() const { return base::TimeTicks::Now() - _start; }

  base::TimeDelta maxDelta() const;

  void visualize(SkCanvas& canvas, const SkRect& rect) const;

  void start();

  void stop();

  void setLapTime(const base::TimeDelta& delta);

 private:
  base::TimeTicks _start;
  std::vector<base::TimeDelta> _laps;
  size_t _current_sample;

  DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

class Counter {
 public:
  explicit Counter() : _count(0) {}

  size_t count() const { return _count; }

  void reset(size_t count = 0) { _count = count; }

  void increment(size_t count = 1) { _count += count; }

 private:
  size_t _count;

  DISALLOW_COPY_AND_ASSIGN(Counter);
};

}  // namespace instrumentation
}  // namespace flow

#endif  // FLOW_INSTRUMENTATION_H_
