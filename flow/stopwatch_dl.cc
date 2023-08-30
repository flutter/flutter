// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/stopwatch_dl.h"
#include <memory>
#include <vector>
#include "display_list/dl_blend_mode.h"
#include "display_list/dl_canvas.h"
#include "display_list/dl_color.h"
#include "display_list/dl_paint.h"
#include "display_list/dl_vertices.h"
#include "include/core/SkRect.h"

namespace flutter {

static const size_t kMaxSamples = 120;
static const size_t kMaxFrameMarkers = 8;

void DlStopwatchVisualizer::Visualize(DlCanvas* canvas,
                                      const SkRect& rect) const {
  auto painter = DlVertexPainter();
  DlPaint paint;

  // Establish the graph position.
  auto const x = rect.x();
  auto const y = rect.y();
  auto const width = rect.width();
  auto const height = rect.height();
  auto const bottom = rect.bottom();

  // Scale the graph to show time frames up to those that are 3x the frame time.
  auto const one_frame_ms = stopwatch_.GetFrameBudget().count();
  auto const max_interval = one_frame_ms * 3.0;
  auto const max_unit_interval = UnitFrameInterval(max_interval);
  auto const sample_unit_width = (1.0 / kMaxSamples);

  // Provide a semi-transparent background for the graph.
  painter.DrawRect(rect, 0x99FFFFFF);

  // Prepare a path for the data; we start at the height of the last point so
  // it looks like we wrap around.
  {
    for (auto i = size_t(0); i < stopwatch_.GetLapsCount(); i++) {
      auto const sample_unit_height =
          (1.0 - UnitHeight(stopwatch_.GetLap(i).ToMillisecondsF(),
                            max_unit_interval));

      auto const bar_width = width * sample_unit_width;
      auto const bar_height = height * sample_unit_height;
      auto const bar_left = x + width * sample_unit_width * i;

      painter.DrawRect(SkRect::MakeLTRB(/*left=*/bar_left,
                                        /*top=*/y + bar_height,
                                        /*right=*/bar_left + bar_width,
                                        /*bottom=*/bottom),
                       0xAA0000FF);
    }
  }

  // Draw horizontal frame markers.
  {
    if (max_interval > one_frame_ms) {
      // Paint the horizontal markers.
      auto count = static_cast<size_t>(max_interval / one_frame_ms);

      // Limit the number of markers to a reasonable amount.
      if (count > kMaxFrameMarkers) {
        count = 1;
      }

      for (auto i = size_t(0); i < count; i++) {
        auto const frame_height =
            height * (1.0 - (UnitFrameInterval(i + 1) * one_frame_ms) /
                                max_unit_interval);

        // Draw a skinny rectangle (i.e. a line).
        painter.DrawRect(SkRect::MakeLTRB(/*left=*/x,
                                          /*top=*/y + frame_height,
                                          /*right=*/width,
                                          /*bottom=*/y + frame_height + 1),
                         0xCC000000);
      }
    }
  }

  // Paint the vertical marker for the current frame.
  {
    DlColor color = DlColor::kGreen();
    if (UnitFrameInterval(stopwatch_.LastLap().ToMillisecondsF()) > 1.0) {
      // budget exceeded.
      color = DlColor::kRed();
    }
    auto const l =
        x + width * (static_cast<double>(stopwatch_.GetCurrentSample()) /
                     kMaxSamples);
    auto const t = y;
    auto const r = l + width * sample_unit_width;
    auto const b = rect.bottom();
    painter.DrawRect(SkRect::MakeLTRB(l, t, r, b), color);
  }

  // Actually draw.
  // Note we use kSrcOver, because some of the colors above have opacity < 1.0.
  canvas->DrawVertices(painter.IntoVertices(), DlBlendMode::kSrcOver, paint);
}

void DlVertexPainter::DrawRect(const SkRect& rect, const DlColor& color) {
  // Draw 6 vertices representing 2 triangles.
  auto const left = rect.x();
  auto const top = rect.y();
  auto const right = rect.right();
  auto const bottom = rect.bottom();

  auto const vertices = std::array<SkPoint, 6>{
      SkPoint::Make(left, top),      // tl tr
      SkPoint::Make(right, top),     //    br
      SkPoint::Make(right, bottom),  //
      SkPoint::Make(right, bottom),  // tl
      SkPoint::Make(left, bottom),   // bl br
      SkPoint::Make(left, top)       //
  };

  auto const colors = std::array<DlColor, 6>{
      color,  // tl tr
      color,  //    br
      color,  //
      color,  // tl
      color,  // bl br
      color   //
  };

  vertices_.insert(vertices_.end(), vertices.begin(), vertices.end());
  colors_.insert(colors_.end(), colors.begin(), colors.end());
}

std::shared_ptr<DlVertices> DlVertexPainter::IntoVertices() {
  auto const result = DlVertices::Make(
      /*mode=*/DlVertexMode::kTriangles,
      /*vertex_count=*/vertices_.size(),
      /*vertices=*/vertices_.data(),
      /*texture_coordinates=*/nullptr,
      /*colors=*/colors_.data());
  vertices_.clear();
  colors_.clear();
  return result;
}

}  // namespace flutter
