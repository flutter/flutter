// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/instrumentation.h"

#include <algorithm>

#include "third_party/skia/include/core/SkPath.h"

namespace sky {
namespace compositor {
namespace instrumentation {

static const size_t kMaxSamples = 120;
static const double kOneFrameMS = 1e3 / 60.0;

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

  // Paint the background
  paint.setColor(0xAAFFFFFF);
  canvas.drawRect(rect, paint);

  // Paint the graph
  SkPath path;
  const SkScalar width = rect.width();
  const SkScalar height = rect.height();

  // Find the max delta. We use this to scale the graph

  double maxInterval = maxDelta().InMillisecondsF();

  if (maxInterval < kOneFrameMS) {
    maxInterval = kOneFrameMS;
  }

  const double maxUnitInterval = UnitFrameInterval(maxInterval);

  // Draw the path
  double unitHeight =
      UnitFrameInterval(_laps[0].InMillisecondsF()) / maxUnitInterval;

  path.moveTo(0, height);
  path.lineTo(0, height * (1.0 - unitHeight));

  for (size_t i = 0; i < kMaxSamples; i++) {
    double unitWidth = (static_cast<double>(i + 1) / kMaxSamples);
    unitHeight =
        UnitFrameInterval(_laps[i].InMillisecondsF()) / maxUnitInterval;
    path.lineTo(width * unitWidth, height * (1.0 - unitHeight));
  }

  path.lineTo(width, height);

  path.close();

  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  paint.setStrokeWidth(1);
  paint.setStyle(SkPaint::Style::kStroke_Style);
  paint.setColor(0xAAFFFFFF);

  if (maxInterval > kOneFrameMS) {
    // Paint the horizontal markers
    for (size_t frameIndex = 1; (frameIndex * kOneFrameMS) < maxInterval;
         frameIndex++) {
      const double frameHeight =
          height * (1.0 - (UnitFrameInterval(frameIndex * kOneFrameMS) /
                           maxUnitInterval));
      canvas.drawLine(0, frameHeight, width, frameHeight, paint);
    }
  }

  // Paint the vertical marker
  if (UnitFrameInterval(lastLap().InMillisecondsF()) > 1.0) {
    // budget exceeded
    paint.setColor(SK_ColorRED);
  } else {
    // within budget
    paint.setColor(SK_ColorGREEN);
  }

  double sampleX = width * (static_cast<double>(_current_sample) / kMaxSamples);
  paint.setStrokeWidth(3);
  canvas.drawLine(sampleX, 0, sampleX, height, paint);
}

Stopwatch::~Stopwatch() = default;

}  // namespace instrumentation
}  // namespace compositor
}  // namespace sky
