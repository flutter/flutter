// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/performance_overlay_layer.h"

#include <iomanip>
#include <iostream>
#include <memory>
#include <string>

#include "flow/stopwatch.h"
#include "flow/stopwatch_dl.h"
#include "flow/stopwatch_sk.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#ifdef IMPELLER_SUPPORTS_RENDERING
#include "impeller/typographer/backends/skia/text_frame_skia.h"  // nogncheck
#endif  // IMPELLER_SUPPORTS_RENDERING

namespace flutter {
namespace {

void VisualizeStopWatch(DlCanvas* canvas,
                        const bool impeller_enabled,
                        const Stopwatch& stopwatch,
                        SkScalar x,
                        SkScalar y,
                        SkScalar width,
                        SkScalar height,
                        bool show_graph,
                        bool show_labels,
                        const std::string& label_prefix,
                        const std::string& font_path) {
  const int label_x = 8;    // distance from x
  const int label_y = -10;  // distance from y+height

  if (show_graph) {
    SkRect visualization_rect = SkRect::MakeXYWH(x, y, width, height);
    std::unique_ptr<StopwatchVisualizer> visualizer;

    if (impeller_enabled) {
      visualizer = std::make_unique<DlStopwatchVisualizer>(stopwatch);
    } else {
      visualizer = std::make_unique<SkStopwatchVisualizer>(stopwatch);
    }

    visualizer->Visualize(canvas, visualization_rect);
  }

  if (show_labels) {
    auto text = PerformanceOverlayLayer::MakeStatisticsText(
        stopwatch, label_prefix, font_path);
    // Historically SK_ColorGRAY (== 0xFF888888) was used here
    DlPaint paint(DlColor(0xFF888888));
#ifdef IMPELLER_SUPPORTS_RENDERING
    if (impeller_enabled) {
      canvas->DrawTextFrame(impeller::MakeTextFrameFromTextBlobSkia(text),
                            x + label_x, y + height + label_y, paint);
      return;
    }
#endif  // IMPELLER_SUPPORTS_RENDERING
    canvas->DrawTextBlob(text, x + label_x, y + height + label_y, paint);
  }
}

}  // namespace

sk_sp<SkTextBlob> PerformanceOverlayLayer::MakeStatisticsText(
    const Stopwatch& stopwatch,
    const std::string& label_prefix,
    const std::string& font_path) {
  SkFont font;
  if (font_path != "") {
    font = SkFont(SkTypeface::MakeFromFile(font_path.c_str()));
  }
  font.setSize(15);

  double max_ms_per_frame = stopwatch.MaxDelta().ToMillisecondsF();
  double average_ms_per_frame = stopwatch.AverageDelta().ToMillisecondsF();
  std::stringstream stream;
  stream.setf(std::ios::fixed | std::ios::showpoint);
  stream << std::setprecision(1);
  stream << label_prefix << "  "
         << "max " << max_ms_per_frame << " ms/frame, "
         << "avg " << average_ms_per_frame << " ms/frame";
  auto text = stream.str();
  return SkTextBlob::MakeFromText(text.c_str(), text.size(), font,
                                  SkTextEncoding::kUTF8);
}

PerformanceOverlayLayer::PerformanceOverlayLayer(uint64_t options,
                                                 const char* font_path)
    : options_(options) {
  if (font_path != nullptr) {
    font_path_ = font_path;
  }
}

void PerformanceOverlayLayer::Diff(DiffContext* context,
                                   const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(old_layer);
    auto prev = old_layer->as_performance_overlay_layer();
    context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(prev));
  }
  context->AddLayerBounds(paint_bounds());
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void PerformanceOverlayLayer::Paint(PaintContext& context) const {
  const int padding = 8;

  if (!options_) {
    return;
  }

  SkScalar x = paint_bounds().x() + padding;
  SkScalar y = paint_bounds().y() + padding;
  SkScalar width = paint_bounds().width() - (padding * 2);
  SkScalar height = paint_bounds().height() / 2;
  auto mutator = context.state_stack.save();

  VisualizeStopWatch(
      context.canvas, context.impeller_enabled, context.raster_time, x, y,
      width, height - padding, options_ & kVisualizeRasterizerStatistics,
      options_ & kDisplayRasterizerStatistics, "Raster", font_path_);

  VisualizeStopWatch(context.canvas, context.impeller_enabled, context.ui_time,
                     x, y + height, width, height - padding,
                     options_ & kVisualizeEngineStatistics,
                     options_ & kDisplayEngineStatistics, "UI", font_path_);
}

}  // namespace flutter
