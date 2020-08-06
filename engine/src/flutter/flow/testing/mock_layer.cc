// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_layer.h"

namespace flutter {
namespace testing {

MockLayer::MockLayer(SkPath path,
                     SkPaint paint,
                     bool fake_has_platform_view,
                     bool fake_needs_system_composite,
                     bool fake_reads_surface)
    : fake_paint_path_(path),
      fake_paint_(paint),
      fake_has_platform_view_(fake_has_platform_view),
      fake_needs_system_composite_(fake_needs_system_composite),
      fake_reads_surface_(fake_reads_surface) {}

void MockLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  parent_mutators_ = context->mutators_stack;
  parent_matrix_ = matrix;
  parent_cull_rect_ = context->cull_rect;
  parent_elevation_ = context->total_elevation;
  parent_has_platform_view_ = context->has_platform_view;

  context->has_platform_view = fake_has_platform_view_;
  set_paint_bounds(fake_paint_path_.getBounds());
  set_needs_system_composite(fake_needs_system_composite_);
  if (fake_reads_surface_) {
    context->surface_needs_readback = true;
  }
}

void MockLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting());

  context.leaf_nodes_canvas->drawPath(fake_paint_path_, fake_paint_);
}

}  // namespace testing
}  // namespace flutter
