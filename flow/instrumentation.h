// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_INSTRUMENTATION_H_
#define FLUTTER_FLOW_INSTRUMENTATION_H_

#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

class Stopwatch {
 public:
  /// The refresh rate interface for `Stopwatch`.
  class RefreshRateUpdater {
   public:
    /// Time limit for a smooth frame.
    /// See: `DisplayManager::GetMainDisplayRefreshRate`.
    virtual fml::Milliseconds GetFrameBudget() const = 0;
  };

  /// The constructor with a updater parameter, it will update frame_budget
  /// everytime when `GetFrameBudget()` is called.
  explicit Stopwatch(const RefreshRateUpdater& updater);

  ~Stopwatch();

  const fml::TimeDelta& LastLap() const;

  fml::TimeDelta MaxDelta() const;

  fml::TimeDelta AverageDelta() const;

  void InitVisualizeSurface(const SkRect& rect) const;

  void Visualize(SkCanvas* canvas, const SkRect& rect) const;

  void Start();

  void Stop();

  void SetLapTime(const fml::TimeDelta& delta);

  /// All places which want to get frame_budget should call this function.
  fml::Milliseconds GetFrameBudget() const;

 private:
  inline double UnitFrameInterval(double time_ms) const;
  inline double UnitHeight(double time_ms, double max_height) const;

  const RefreshRateUpdater& refresh_rate_updater_;
  fml::TimePoint start_;
  std::vector<fml::TimeDelta> laps_;
  size_t current_sample_;

  // Mutable data cache for performance optimization of the graphs. Prevents
  // expensive redrawing of old data.
  mutable bool cache_dirty_;
  mutable sk_sp<SkSurface> visualize_cache_surface_;
  mutable size_t prev_drawn_sample_index_;

  FML_DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

/// Used for fixed refresh rate query cases.
class FixedRefreshRateUpdater : public Stopwatch::RefreshRateUpdater {
  fml::Milliseconds GetFrameBudget() const override;

 public:
  explicit FixedRefreshRateUpdater(
      fml::Milliseconds fixed_frame_budget = fml::kDefaultFrameBudget);

 private:
  fml::Milliseconds fixed_frame_budget_;
};

/// Used for fixed refresh rate cases.
class FixedRefreshRateStopwatch : public Stopwatch {
 public:
  explicit FixedRefreshRateStopwatch(
      fml::Milliseconds fixed_frame_budget = fml::kDefaultFrameBudget);

 private:
  FixedRefreshRateUpdater fixed_delegate_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_INSTRUMENTATION_H_
