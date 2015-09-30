// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/instrumentation.h"
#include "third_party/skia/include/core/SkPath.h"

namespace sky {
namespace compositor {
namespace instrumentation {

static const size_t kMaxSamples = 120;

Stopwatch::Stopwatch()
    : _start(base::TimeTicks::Now()), _lastLap(), _current_sample(0) {
  const base::TimeDelta delta;
  _laps.resize(kMaxSamples, delta);
}

void Stopwatch::start() {
  _start = base::TimeTicks::Now();
  _current_sample = (_current_sample + 1) % kMaxSamples;
}

void Stopwatch::stop() {
  _lastLap = base::TimeTicks::Now() - _start;
  _laps[_current_sample] = _lastLap;
}

static inline constexpr double UnitFrameInterval(double frameTimeMS) {
  return frameTimeMS * 60.0 * 1e-3;
}

void Stopwatch::visualize(SkCanvas& canvas, const SkRect& rect) const {
  SkAutoCanvasRestore save(&canvas, false);

  SkPaint paint;

  // Paint the background
  paint.setColor(0xAAFFFFFF);
  canvas.drawRect(rect, paint);

  // Paint the graph
  SkPath path;
  auto width = rect.width();
  auto height = rect.height();

  auto unitHeight = (1.0 - UnitFrameInterval(_laps[0].InMillisecondsF()));

  path.moveTo(0, height);
  path.lineTo(0, height * unitHeight);

  for (size_t i = 0; i < kMaxSamples; i++) {
    double unitWidth = (static_cast<double>(i + 1) / kMaxSamples);
    unitHeight = (1.0 - UnitFrameInterval(_laps[i].InMillisecondsF()));
    path.lineTo(width * unitWidth, height * unitHeight);
  }

  path.lineTo(width, height);

  path.close();

  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  // Paint the marker
  paint.setColor(0xFF00FF00);
  paint.setStrokeWidth(3);
  paint.setStyle(SkPaint::Style::kStroke_Style);
  auto sampleX = width * (static_cast<double>(_current_sample) / kMaxSamples);
  canvas.drawLine(sampleX, 0, sampleX, height, paint);
}

Stopwatch::~Stopwatch() = default;

}  // namespace instrumentation
}  // namespace compositor
}  // namespace sky
