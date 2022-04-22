// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/transform_layer.h"

#include <optional>

namespace flutter {

TransformLayer::TransformLayer(const SkMatrix& transform)
    : transform_(transform) {
  // Checks (in some degree) that SkMatrix transform_ is valid and initialized.
  //
  // If transform_ is uninitialized, this assert may look flaky as it doesn't
  // fail all the time, and some rerun may make it pass. But don't ignore it and
  // just rerun the test if this is triggered, since even a flaky failure here
  // may signify a potentially big problem in the code.
  //
  // We have to write this flaky test because there is no reliable way to test
  // whether a variable is initialized or not in C++.
  FML_DCHECK(transform_.isFinite());
  if (!transform_.isFinite()) {
    FML_LOG(ERROR) << "TransformLayer is constructed with an invalid matrix.";
    transform_.setIdentity();
  }
}

void TransformLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const TransformLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (transform_ != prev->transform_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }
  context->PushTransform(transform_);
  DiffChildren(context, prev);
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void TransformLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "TransformLayer::Preroll");

  SkMatrix child_matrix;
  child_matrix.setConcat(matrix, transform_);
  context->mutators_stack.PushTransform(transform_);
  SkRect previous_cull_rect = context->cull_rect;
  SkMatrix inverse_transform_;
  // Perspective projections don't produce rectangles that are useful for
  // culling for some reason.
  if (!transform_.hasPerspective() && transform_.invert(&inverse_transform_)) {
    inverse_transform_.mapRect(&context->cull_rect);
  } else {
    context->cull_rect = kGiantRect;
  }

  // Collect inheritance information on our children in Preroll so that
  // we can pass it along by default.
  context->subtree_can_inherit_opacity = true;

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, child_matrix, &child_paint_bounds);

  transform_.mapRect(&child_paint_bounds);
  set_paint_bounds(child_paint_bounds);

  context->cull_rect = previous_cull_rect;
  context->mutators_stack.Pop();
}

void TransformLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "TransformLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->concat(transform_);

  PaintChildren(context);
}

}  // namespace flutter
