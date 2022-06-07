// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/instrumentation.h"

#include <algorithm>

#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

static const size_t kMaxSamples = 120;
static const size_t kMaxFrameMarkers = 8;

Stopwatch::Stopwatch(const RefreshRateUpdater& updater)
    : refresh_rate_updater_(updater),
      start_(fml::TimePoint::Now()),
      current_sample_(0) {
  const fml::TimeDelta delta = fml::TimeDelta::Zero();
  laps_.resize(kMaxSamples, delta);
  cache_dirty_ = true;
  prev_drawn_sample_index_ = 0;
}

Stopwatch::~Stopwatch() = default;

FixedRefreshRateStopwatch::FixedRefreshRateStopwatch(
    fml::Milliseconds frame_budget)
    : Stopwatch(fixed_delegate_), fixed_delegate_(frame_budget) {}

FixedRefreshRateUpdater::FixedRefreshRateUpdater(
    fml::Milliseconds fixed_frame_budget)
    : fixed_frame_budget_(fixed_frame_budget) {}

void Stopwatch::Start() {
  start_ = fml::TimePoint::Now();
  current_sample_ = (current_sample_ + 1) % kMaxSamples;
}

void Stopwatch::Stop() {
  laps_[current_sample_] = fml::TimePoint::Now() - start_;
}

void Stopwatch::SetLapTime(const fml::TimeDelta& delta) {
  current_sample_ = (current_sample_ + 1) % kMaxSamples;
  laps_[current_sample_] = delta;
}

const fml::TimeDelta& Stopwatch::LastLap() const {
  return laps_[(current_sample_ - 1) % kMaxSamples];
}

double Stopwatch::UnitFrameInterval(double raster_time_ms) const {
  return raster_time_ms / GetFrameBudget().count();
}

double Stopwatch::UnitHeight(double raster_time_ms,
                             double max_unit_interval) const {
  double unitHeight = UnitFrameInterval(raster_time_ms) / max_unit_interval;
  if (unitHeight > 1.0) {
    unitHeight = 1.0;
  }
  return unitHeight;
}

fml::TimeDelta Stopwatch::MaxDelta() const {
  fml::TimeDelta max_delta;
  for (size_t i = 0; i < kMaxSamples; i++) {
    if (laps_[i] > max_delta) {
      max_delta = laps_[i];
    }
  }
  return max_delta;
}

fml::TimeDelta Stopwatch::AverageDelta() const {
  fml::TimeDelta sum;  // default to 0
  for (size_t i = 0; i < kMaxSamples; i++) {
    sum = sum + laps_[i];
  }
  return sum / kMaxSamples;
}

// Initialize the SkSurface for drawing into. Draws the base background and any
// timing data from before the initial Visualize() call.
void Stopwatch::InitVisualizeSurface(const SkRect& rect) const {
  // Mark as dirty if the size has changed.
  if (visualize_cache_surface_) {
    if (rect.width() != visualize_cache_surface_->width() ||
        rect.height() != visualize_cache_surface_->height()) {
      cache_dirty_ = true;
    };
  }

  if (!cache_dirty_) {
    return;
  }
  cache_dirty_ = false;

  // TODO(garyq): Use a GPU surface instead of a CPU surface.
  visualize_cache_surface_ =
      SkSurface::MakeRasterN32Premul(rect.width(), rect.height());

  SkCanvas* cache_canvas = visualize_cache_surface_->getCanvas();

  // Establish the graph position.
  const SkScalar x = 0;
  const SkScalar y = 0;
  const SkScalar width = rect.width();
  const SkScalar height = rect.height();

  SkPaint paint;
  paint.setColor(0x99FFFFFF);
  cache_canvas->drawRect(SkRect::MakeXYWH(x, y, width, height), paint);

  // Scale the graph to show frame times up to those that are 3 times the frame
  // time.
  const double one_frame_ms = GetFrameBudget().count();
  const double max_interval = one_frame_ms * 3.0;
  const double max_unit_interval = UnitFrameInterval(max_interval);

  // Draw the old data to initially populate the graph.
  // Prepare a path for the data. We start at the height of the last point, so
  // it looks like we wrap around
  SkPath path;
  path.setIsVolatile(true);
  path.moveTo(x, height);
  path.lineTo(x, y + height * (1.0 - UnitHeight(laps_[0].ToMillisecondsF(),
                                                max_unit_interval)));
  double unit_x;
  double unit_next_x = 0.0;
  for (size_t i = 0; i < kMaxSamples; i += 1) {
    unit_x = unit_next_x;
    unit_next_x = (static_cast<double>(i + 1) / kMaxSamples);
    const double sample_y =
        y + height * (1.0 - UnitHeight(laps_[i].ToMillisecondsF(),
                                       max_unit_interval));
    path.lineTo(x + width * unit_x, sample_y);
    path.lineTo(x + width * unit_next_x, sample_y);
  }
  path.lineTo(
      width,
      y + height * (1.0 - UnitHeight(laps_[kMaxSamples - 1].ToMillisecondsF(),
                                     max_unit_interval)));
  path.lineTo(width, height);
  path.close();

  // Draw the graph.
  paint.setColor(0xAA0000FF);
  cache_canvas->drawPath(path, paint);
}

void Stopwatch::Visualize(SkCanvas* canvas, const SkRect& rect) const {
  // Initialize visualize cache if it has not yet been initialized.
  InitVisualizeSurface(rect);

  SkCanvas* cache_canvas = visualize_cache_surface_->getCanvas();
  SkPaint paint;

  // Establish the graph position.
  const SkScalar x = 0;
  const SkScalar y = 0;
  const SkScalar width = rect.width();
  const SkScalar height = rect.height();

  // Scale the graph to show frame times up to those that are 3 times the frame
  // time.
  const double one_frame_ms = GetFrameBudget().count();
  const double max_interval = one_frame_ms * 3.0;
  const double max_unit_interval = UnitFrameInterval(max_interval);

  const double sample_unit_width = (1.0 / kMaxSamples);

  // Draw vertical replacement bar to erase old/stale pixels.
  paint.setColor(0x99FFFFFF);
  paint.setStyle(SkPaint::Style::kFill_Style);
  paint.setBlendMode(SkBlendMode::kSrc);
  double sample_x =
      x + width * (static_cast<double>(prev_drawn_sample_index_) / kMaxSamples);
  const auto eraser_rect = SkRect::MakeLTRB(
      sample_x, y, sample_x + width * sample_unit_width, height);
  cache_canvas->drawRect(eraser_rect, paint);

  // Draws blue timing bar for new data.
  paint.setColor(0xAA0000FF);
  paint.setBlendMode(SkBlendMode::kSrcOver);
  const auto bar_rect = SkRect::MakeLTRB(
      sample_x,
      y + height * (1.0 -
                    UnitHeight(laps_[current_sample_ == 0 ? kMaxSamples - 1
                                                          : current_sample_ - 1]
                                   .ToMillisecondsF(),
                               max_unit_interval)),
      sample_x + width * sample_unit_width, height);
  cache_canvas->drawRect(bar_rect, paint);

  // Draw horizontal frame markers.
  paint.setStrokeWidth(0);  // hairline
  paint.setStyle(SkPaint::Style::kStroke_Style);
  paint.setColor(0xCC000000);

  if (max_interval > one_frame_ms) {
    // Paint the horizontal markers
    size_t frame_marker_count =
        static_cast<size_t>(max_interval / one_frame_ms);

    // Limit the number of markers displayed. After a certain point, the graph
    // becomes crowded
    if (frame_marker_count > kMaxFrameMarkers) {
      frame_marker_count = 1;
    }

    for (size_t frame_index = 0; frame_index < frame_marker_count;
         frame_index++) {
      const double frame_height =
          height * (1.0 - (UnitFrameInterval((frame_index + 1) * one_frame_ms) /
                           max_unit_interval));
      cache_canvas->drawLine(x, y + frame_height, width, y + frame_height,
                             paint);
    }
  }

  // Paint the vertical marker for the current frame.
  // We paint it over the current frame, not after it, because when we
  // paint this we don't yet have all the times for the current frame.
  paint.setStyle(SkPaint::Style::kFill_Style);
  paint.setBlendMode(SkBlendMode::kSrcOver);
  if (UnitFrameInterval(LastLap().ToMillisecondsF()) > 1.0) {
    // budget exceeded
    paint.setColor(SK_ColorRED);
  } else {
    // within budget
    paint.setColor(SK_ColorGREEN);
  }
  sample_x = x + width * (static_cast<double>(current_sample_) / kMaxSamples);
  const auto marker_rect = SkRect::MakeLTRB(
      sample_x, y, sample_x + width * sample_unit_width, height);
  cache_canvas->drawRect(marker_rect, paint);
  prev_drawn_sample_index_ = current_sample_;

  // Draw the cached surface onto the output canvas.
  visualize_cache_surface_->draw(canvas, rect.x(), rect.y());
}

fml::Milliseconds Stopwatch::GetFrameBudget() const {
  return refresh_rate_updater_.GetFrameBudget();
}

fml::Milliseconds FixedRefreshRateUpdater::GetFrameBudget() const {
  return fixed_frame_budget_;
}

}  // namespace flutter
