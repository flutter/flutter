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

namespace flutter {

static const size_t kMaxSamples = 120;
static const size_t kMaxFrameMarkers = 8;

void DlStopwatchVisualizer::Visualize(DlCanvas* canvas,
                                      const DlRect& rect) const {
  DlVertexPainter painter(vertices_storage_, color_storage_);
  DlPaint paint;

  // Establish the graph position.
  const DlScalar x = rect.GetX();
  const DlScalar y = rect.GetY();
  const DlScalar width = rect.GetWidth();
  const DlScalar height = rect.GetHeight();
  const DlScalar bottom = rect.GetBottom();

  // Scale the graph to show time frames up to those that are 3x the frame time.
  const DlScalar one_frame_ms = GetFrameBudget().count();
  const DlScalar max_interval = one_frame_ms * 3.0;
  const DlScalar max_unit_interval = UnitFrameInterval(max_interval);
  const DlScalar sample_unit_width = width / kMaxSamples;

  // resize backing storage to match expected lap count.
  size_t required_storage =
      (stopwatch_.GetLapsCount() + 2 + kMaxFrameMarkers) * 6;
  if (vertices_storage_.size() < required_storage) {
    vertices_storage_.resize(required_storage);
    color_storage_.resize(required_storage);
  }

  // Provide a semi-transparent background for the graph.
  painter.DrawRect(rect, DlColor(0x99FFFFFF));

  // Prepare a path for the data; we start at the height of the last point so
  // it looks like we wrap around.
  {
    DlScalar bar_left = x;
    for (size_t i = 0u; i < stopwatch_.GetLapsCount(); i++) {
      const double time_ms = stopwatch_.GetLap(i).ToMillisecondsF();
      const DlScalar sample_unit_height = static_cast<DlScalar>(
          height * UnitHeight(time_ms, max_unit_interval));

      const DlScalar bar_top = bottom - sample_unit_height;
      const DlScalar bar_right = x + (i + 1) * sample_unit_width;

      painter.DrawRect(DlRect::MakeLTRB(/*left=*/bar_left,
                                        /*top=*/bar_top,
                                        /*right=*/bar_right,
                                        /*bottom=*/bottom),
                       DlColor(0xAA0000FF));
      bar_left = bar_right;
    }
  }

  // Draw horizontal frame markers.
  {
    if (max_interval > one_frame_ms) {
      // Paint the horizontal markers.
      size_t count = static_cast<size_t>(max_interval / one_frame_ms);

      // Limit the number of markers to a reasonable amount.
      if (count > kMaxFrameMarkers) {
        count = 1;
      }

      for (uint32_t i = 0u; i < count; i++) {
        const DlScalar frame_height =
            height * (1.0 - (UnitFrameInterval(i + 1) * one_frame_ms) /
                                max_unit_interval);

        // Draw a skinny rectangle (i.e. a line).
        painter.DrawRect(DlRect::MakeLTRB(/*left=*/x,
                                          /*top=*/y + frame_height,
                                          /*right=*/x + width,
                                          /*bottom=*/y + frame_height + 1),
                         DlColor(0xCC000000));
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
    size_t sample =
        (stopwatch_.GetCurrentSample() + 1) % stopwatch_.GetLapsCount();
    const DlScalar l = x + sample * sample_unit_width;
    const DlScalar t = y;
    const DlScalar r = l + sample_unit_width;
    const DlScalar b = rect.GetBottom();
    painter.DrawRect(DlRect::MakeLTRB(l, t, r, b), color);
  }

  // Actually draw.
  // Use kSrcOver blend mode so that elements under the performance overlay are
  // partially visible.
  paint.setBlendMode(DlBlendMode::kSrcOver);
  // The second blend mode does nothing since the paint has no additional color
  // sources like a tiled image or gradient.
  canvas->DrawVertices(painter.IntoVertices(rect), DlBlendMode::kSrcOver,
                       paint);
}

DlVertexPainter::DlVertexPainter(std::vector<DlPoint>& vertices_storage,
                                 std::vector<DlColor>& color_storage)
    : vertices_(vertices_storage), colors_(color_storage) {}

void DlVertexPainter::DrawRect(const DlRect& rect, const DlColor& color) {
  const DlScalar left = rect.GetLeft();
  const DlScalar top = rect.GetTop();
  const DlScalar right = rect.GetRight();
  const DlScalar bottom = rect.GetBottom();

  FML_DCHECK(6 + colors_offset_ <= vertices_.size());
  FML_DCHECK(6 + colors_offset_ <= colors_.size());

  // Draw 6 vertices representing 2 triangles.
  vertices_[vertices_offset_++] = DlPoint(left, top);      // tl tr
  vertices_[vertices_offset_++] = DlPoint(right, top);     //    br
  vertices_[vertices_offset_++] = DlPoint(right, bottom);  //
  vertices_[vertices_offset_++] = DlPoint(right, bottom);  // tl
  vertices_[vertices_offset_++] = DlPoint(left, bottom);   // bl br
  vertices_[vertices_offset_++] = DlPoint(left, top);      //
  for (size_t i = 0u; i < 6u; i++) {
    colors_[colors_offset_++] = color;
  }
}

std::shared_ptr<DlVertices> DlVertexPainter::IntoVertices(
    const DlRect& bounds_rect) {
  return DlVertices::Make(
      /*mode=*/DlVertexMode::kTriangles,
      /*vertex_count=*/vertices_.size(),
      /*vertices=*/vertices_.data(),
      /*texture_coordinates=*/nullptr,
      /*colors=*/colors_.data(),
      /*index_count=*/0,
      /*indices=*/nullptr,
      /*bounds=*/&bounds_rect);
}

}  // namespace flutter
