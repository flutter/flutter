// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/instrumentation.h"

#include <algorithm>

#include "third_party/skia/include/core/SkPath.h"

namespace flow {
namespace instrumentation {

static const size_t kMaxSamples = 120;
static const size_t kMaxFrameMarkers = 8;

Stopwatch::Stopwatch() : _start(base::TimeTicks::Now()), _current_sample(0) {
  const base::TimeDelta delta;
  _laps.resize(kMaxSamples, delta);
}

void Stopwatch::start() {
  _start = base::TimeTicks::Now();
  _current_sample = (_current_sample + 1) % kMaxSamples;
}

void Stopwatch::stop() {
  _laps[_current_sample] = base::TimeTicks::Now() - _start;
}

void Stopwatch::setLapTime(const base::TimeDelta& delta) {
  _current_sample = (_current_sample + 1) % kMaxSamples;
  _laps[_current_sample] = delta;
}

const base::TimeDelta& Stopwatch::lastLap() const {
  return _laps[(_current_sample - 1) % kMaxSamples];
}

static inline constexpr double UnitFrameInterval(double frameTimeMS) {
  return frameTimeMS * 60.0 * 1e-3;
}

static inline double UnitHeight(double frameTimeMS, double maxUnitInterval) {
  double unitHeight = UnitFrameInterval(frameTimeMS) / maxUnitInterval;
  if (unitHeight > 1.0)
    unitHeight = 1.0;
  return unitHeight;
}

base::TimeDelta Stopwatch::maxDelta() const {
  base::TimeDelta maxDelta;
  for (size_t i = 0; i < kMaxSamples; i++) {
    if (_laps[i] > maxDelta) {
      maxDelta = _laps[i];
    }
  }
  return maxDelta;
}

void Stopwatch::visualize(SkCanvas& canvas, const SkRect& rect) const {
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

  // Scale the graph to show frame times up to those that are 4 times the frame time.
  const double maxInterval = kOneFrameMS * 3.0;
  const double maxUnitInterval = UnitFrameInterval(maxInterval);

  // Prepare a path for the data.
  // we start at the height of the last point, so it looks like we wrap around
  SkPath path;
  const double sampleUnitWidth = (1.0 / kMaxSamples);
  const double sampleMarginUnitWidth = sampleUnitWidth / 6.0;
  const double sampleMarginWidth = width * sampleMarginUnitWidth;
  path.moveTo(x, bottom);
  path.lineTo(x, y + height * (1.0 - UnitHeight(_laps[0].InMillisecondsF(),
                                                maxUnitInterval)));
  double unitX;
  double unitNextX = 0.0;
  for (size_t i = 0; i < kMaxSamples; i += 1) {
    unitX = unitNextX;
    unitNextX = (static_cast<double>(i + 1) / kMaxSamples);
    const double sampleY = y + height * (1.0 - UnitHeight(_laps[i].InMillisecondsF(),
                                                          maxUnitInterval));
    path.lineTo(x + width * unitX + sampleMarginWidth, sampleY);
    path.lineTo(x + width * unitNextX - sampleMarginWidth, sampleY);
  }
  path.lineTo(right, y + height * (1.0 - UnitHeight(_laps[kMaxSamples - 1].InMillisecondsF(),
                                                    maxUnitInterval)));
  path.lineTo(right, bottom);
  path.close();

  // Draw the graph.
  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  // Draw horizontal markers.
  paint.setStrokeWidth(0); // hairline
  paint.setStyle(SkPaint::Style::kStroke_Style);
  paint.setColor(0xCC000000);

  if (maxInterval > kOneFrameMS) {
    // Paint the horizontal markers
    size_t frameMarkerCount = static_cast<size_t>(maxInterval / kOneFrameMS);

    // Limit the number of markers displayed. After a certain point, the graph
    // becomes crowded
    if (frameMarkerCount > kMaxFrameMarkers) {
      frameMarkerCount = 1;
    }

    for (size_t frameIndex = 0; frameIndex < frameMarkerCount; frameIndex++) {
      const double frameHeight =
          height * (1.0 - (UnitFrameInterval((frameIndex + 1) * kOneFrameMS) /
                           maxUnitInterval));
      canvas.drawLine(x, y + frameHeight, right, y + frameHeight, paint);
    }
  }

  // Paint the vertical marker for the current frame.
  // We paint it over the current frame, not after it, because when we
  // paint this we don't yet have all the times for the current frame.
  paint.setStyle(SkPaint::Style::kFill_Style);
  if (UnitFrameInterval(lastLap().InMillisecondsF()) > 1.0) {
    // budget exceeded
    paint.setColor(SK_ColorRED);
  } else {
    // within budget
    paint.setColor(SK_ColorGREEN);
  }
  double sampleX = x + width * (static_cast<double>(_current_sample) / kMaxSamples)
                     - sampleMarginWidth;
  canvas.drawRectCoords(sampleX, y, sampleX + width * sampleUnitWidth + sampleMarginWidth * 2, bottom, paint);
}

Stopwatch::~Stopwatch() = default;

}  // namespace instrumentation
}  // namespace flow
