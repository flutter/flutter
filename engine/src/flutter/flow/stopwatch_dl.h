// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_STOPWATCH_DL_H_
#define FLUTTER_FLOW_STOPWATCH_DL_H_

#include "flow/stopwatch.h"

namespace flutter {

//------------------------------------------------------------------------------
/// A stopwatch visualizer that uses DisplayList (|DlCanvas|) to draw.
///
/// @note This is the newer non-backend specific version, that works in both
///       Skia and Impeller. The older Skia-specific version is
///       |SkStopwatchVisualizer|, which still should be used for Skia-specific
///       optimizations.
class DlStopwatchVisualizer : public StopwatchVisualizer {
 public:
  explicit DlStopwatchVisualizer(const Stopwatch& stopwatch)
      : StopwatchVisualizer(stopwatch) {}

  void Visualize(DlCanvas* canvas, const SkRect& rect) const override;
};

/// @brief Provides canvas-like painting methods that actually build vertices.
///
/// The goal is minimally invasive rendering for the performance monitor.
///
/// The methods in this class are intended to be used by |DlStopwatchVisualizer|
/// only. The rationale is the creating lines, rectangles, and paths (while OK
/// for general apps) would cause non-trivial work for the performance monitor
/// due to tessellation per-frame.
///
/// @note A goal of this class was to make updating the performance monitor
/// (and keeping it in sync with the |SkStopwatchVisualizer|) as easy as
/// possible (i.e. not having to do triangle-math).
class DlVertexPainter final {
 public:
  /// Draws a rectangle with the given color to a buffer.
  void DrawRect(const SkRect& rect, const DlColor& color);

  /// Converts the buffered vertices into a |DlVertices| object.
  ///
  /// @note This method clears the buffer.
  std::shared_ptr<DlVertices> IntoVertices();

 private:
  std::vector<SkPoint> vertices_;
  std::vector<DlColor> colors_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_STOPWATCH_DL_H_
