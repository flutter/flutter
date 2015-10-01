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

static inline constexpr double UnitFrameInterval(double frameTimeMS) {
  return frameTimeMS * 60.0 * 1e-3;
}

void Stopwatch::visualize(SkCanvas& canvas, const SkRect& rect) const {
  SkPaint paint;

  // Paint the background
  paint.setColor(0xAAFFFFFF);
  canvas.drawRect(rect, paint);

  // Paint the graph
  SkPath path;
  auto width = rect.width();
  auto height = rect.height();

  auto unitHeight =
      std::min(1.0, UnitFrameInterval(_laps[0].InMillisecondsF()));

  path.moveTo(0, height);
  path.lineTo(0, height * (1.0 - unitHeight));

  for (size_t i = 0; i < kMaxSamples; i++) {
    double unitWidth = (static_cast<double>(i + 1) / kMaxSamples);
    unitHeight = std::min(1.0, UnitFrameInterval(_laps[i].InMillisecondsF()));
    path.lineTo(width * unitWidth, height * (1.0 - unitHeight));
  }

  path.lineTo(width, height);

  path.close();

  paint.setColor(0xAA0000FF);
  canvas.drawPath(path, paint);

  // Paint the marker
  if (UnitFrameInterval(_laps[_current_sample].InMillisecondsF()) > 1.0) {
    // budget exceeded
    paint.setColor(SK_ColorRED);
  } else {
    // within budget
    paint.setColor(SK_ColorGREEN);
  }

  paint.setStrokeWidth(3);
  paint.setStyle(SkPaint::Style::kStroke_Style);
  auto sampleX = width * (static_cast<double>(_current_sample) / kMaxSamples);
  canvas.drawLine(sampleX, 0, sampleX, height, paint);
}

Stopwatch::~Stopwatch() = default;

}  // namespace instrumentation
}  // namespace compositor
}  // namespace sky
