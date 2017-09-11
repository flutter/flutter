// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/instrumentation.h"

#include <algorithm>
#include <limits>

#include "third_party/skia/include/core/SkPath.h"

namespace flow {

static const size_t kMaxSamples = 120;
static const size_t kMaxFrameMarkers = 8;

Stopwatch::Stopwatch() : start_(fxl::TimePoint::Now()), current_sample_(0) {
  const fxl::TimeDelta delta = fxl::TimeDelta::Zero();
  laps_.resize(kMaxSamples, delta);
}

Stopwatch::~Stopwatch() = default;

void Stopwatch::Start() {
  start_ = fxl::TimePoint::Now();
  current_sample_ = (current_sample_ + 1) % kMaxSamples;
}

void Stopwatch::Stop() {
  laps_[current_sample_] = fxl::TimePoint::Now() - start_;
}

void Stopwatch::SetLapTime(const fxl::TimeDelta& delta) {
  current_sample_ = (current_sample_ + 1) % kMaxSamples;
  laps_[current_sample_] = delta;
}

const fxl::TimeDelta& Stopwatch::LastLap() const {
  return laps_[(current_sample_ - 1) % kMaxSamples];
}

static inline constexpr double UnitFrameInterval(double frame_time_ms) {
  return frame_time_ms * 60.0 * 1e-3;
}

static inline double UnitHeight(double frame_time_ms,
                                double max_unit_interval) {
  double unitHeight = UnitFrameInterval(frame_time_ms) / max_unit_interval;
  if (unitHeight > 1.0)
    unitHeight = 1.0;
  return unitHeight;
}

fxl::TimeDelta Stopwatch::MaxDelta() const {
  fxl::TimeDelta max_delta;
  for (size_t i = 0; i < kMaxSamples; i++) {
    if (laps_[i] > max_delta)
      max_delta = laps_[i];
  }
  return max_delta;
}

void Stopwatch::Visualize(SkCanvas& canvas, const SkRect& rect) const {
  SkPaint paint;

  // Paint the background.
  paint.setColor(0x99FFFFFF);
  canvas.drawRect(rect, paint);

  // Establish the graph position.
  const SkScalar x = rect.x();
  const SkScalar y = rect.y();
  const SkScalar width = rect.width();
  const SkScalar height = rect.height();
  const SkScalar bottom = y + height;
  const SkScalar right = x + width;

  // Scale the graph to show frame times up to those that are 3 times the frame
  // time.
  const double max_interval = kOneFrameMS * 3.0;
  const double max_unit_interval = UnitFrameInterval(max_interval);

  // Prepare a path for the data.
  // we start at the height of the last point, so it looks like we wrap around
  SkPath path;
  const double sample_unit_width = (1.0 / kMaxSamples);
  const double sample_margin_unit_width = sample_unit_width / 6.0;
  const double sample_margin_width = width * sample_margin_unit_width;
  path.moveTo(x, bottom);
  path.lineTo(x, y +
                     height * (1.0 - UnitHeight(laps_[0].ToMillisecondsF(),
                                                max_unit_interval)));
  double unit_x;
  double unit_next_x = 0.0;
  for (size_t i = 0; i < kMaxSamples; i += 1) {
    unit_x = unit_next_x;
    unit_next_x = (static_cast<double>(i + 1) / kMaxSamples);
    const double sample_y =
        y +
        height *
            (1.0 - UnitHeight(laps_[i].ToMillisecondsF(), max_unit_interval));
    path.lineTo(x + width * unit_x + sample_margin_width, sample_y);
    path.lineTo(x + width * unit_next_x - sample_margin_width, sample_y);
  }
  path.lineTo(
      right,
      y +
          height * (1.0 - UnitHeight(laps_[kMaxSamples - 1].ToMillisecondsF(),
                                     max_unit_interval)));
  path.lineTo(right, bottom);
  path.close();

  // Draw the graph.
  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  // Draw horizontal markers.
  paint.setStrokeWidth(0);  // hairline
  paint.setStyle(SkPaint::Style::kStroke_Style);
  paint.setColor(0xCC000000);

  if (max_interval > kOneFrameMS) {
    // Paint the horizontal markers
    size_t frame_marker_count = static_cast<size_t>(max_interval / kOneFrameMS);

    // Limit the number of markers displayed. After a certain point, the graph
    // becomes crowded
    if (frame_marker_count > kMaxFrameMarkers)
      frame_marker_count = 1;

    for (size_t frame_index = 0; frame_index < frame_marker_count;
         frame_index++) {
      const double frame_height =
          height * (1.0 - (UnitFrameInterval((frame_index + 1) * kOneFrameMS) /
                           max_unit_interval));
      canvas.drawLine(x, y + frame_height, right, y + frame_height, paint);
    }
  }

  // Paint the vertical marker for the current frame.
  // We paint it over the current frame, not after it, because when we
  // paint this we don't yet have all the times for the current frame.
  paint.setStyle(SkPaint::Style::kFill_Style);
  if (UnitFrameInterval(LastLap().ToMillisecondsF()) > 1.0) {
    // budget exceeded
    paint.setColor(SK_ColorRED);
  } else {
    // within budget
    paint.setColor(SK_ColorGREEN);
  }
  double sample_x =
      x + width * (static_cast<double>(current_sample_) / kMaxSamples) -
      sample_margin_width;

  const auto marker_rect = SkRect::MakeLTRB(
      sample_x, y,
      sample_x + width * sample_unit_width + sample_margin_width * 2, bottom);
  canvas.drawRect(marker_rect, paint);
}

CounterValues::CounterValues() : current_sample_(kMaxSamples - 1) {
  values_.resize(kMaxSamples, 0);
}

CounterValues::~CounterValues() = default;

void CounterValues::Add(int64_t value) {
  current_sample_ = (current_sample_ + 1) % kMaxSamples;
  values_[current_sample_] = value;
}

void CounterValues::Visualize(SkCanvas& canvas, const SkRect& rect) const {
  size_t max_bytes = GetMaxValue();

  if (max_bytes == 0) {
    // The backend for this counter probably did not fill in any values.
    return;
  }

  size_t min_bytes = GetMinValue();

  SkPaint paint;

  // Paint the background.
  paint.setColor(0x99FFFFFF);
  canvas.drawRect(rect, paint);

  // Establish the graph position.
  const SkScalar x = rect.x();
  const SkScalar y = rect.y();
  const SkScalar width = rect.width();
  const SkScalar height = rect.height();
  const SkScalar bottom = y + height;
  const SkScalar right = x + width;

  // Prepare a path for the data.
  SkPath path;
  path.moveTo(x, bottom);

  for (size_t i = 0; i < kMaxSamples; ++i) {
    int64_t current_bytes = values_[i];
    double ratio =
        (double)(current_bytes - min_bytes) / (max_bytes - min_bytes);
    path.lineTo(x + (((double)(i) / (double)kMaxSamples) * width),
                y + ((1.0 - ratio) * height));
  }

  path.rLineTo(100, 0);
  path.lineTo(right, bottom);
  path.close();

  // Draw the graph.
  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  // Paint the vertical marker for the current frame.
  const double sample_unit_width = (1.0 / kMaxSamples);
  const double sample_margin_unit_width = sample_unit_width / 6.0;
  const double sample_margin_width = width * sample_margin_unit_width;
  paint.setStyle(SkPaint::Style::kFill_Style);
  paint.setColor(SK_ColorGRAY);
  double sample_x =
      x + width * (static_cast<double>(current_sample_) / kMaxSamples) -
      sample_margin_width;
  const auto marker_rect = SkRect::MakeLTRB(
      sample_x, y,
      sample_x + width * sample_unit_width + sample_margin_width * 2, bottom);
  canvas.drawRect(marker_rect, paint);
}

int64_t CounterValues::GetCurrentValue() const {
  return values_[current_sample_];
}

int64_t CounterValues::GetMaxValue() const {
  auto max = std::numeric_limits<int64_t>::min();
  for (size_t i = 0; i < kMaxSamples; ++i) {
    max = std::max<int64_t>(max, values_[i]);
  }
  return max;
}

int64_t CounterValues::GetMinValue() const {
  auto min = std::numeric_limits<int64_t>::max();
  for (size_t i = 0; i < kMaxSamples; ++i) {
    min = std::min<int64_t>(min, values_[i]);
  }
  return min;
}

}  // namespace flow
