// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/transform_layer.h"

#include <optional>

namespace flutter {

TransformLayer::TransformLayer(const SkM44& transform) : transform_(transform) {
  // Checks (in some degree) that SkM44 transform_ is valid and initialized.
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

void TransformLayer::Preroll(PrerollContext* context) {
  auto mutator = context->state_stack.save();
  mutator.transform(transform_);

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, &child_paint_bounds);

  // We convert to a 3x3 matrix here primarily because the SkM44 object
  // does not support a mapRect operation.
  // https://bugs.chromium.org/p/skia/issues/detail?id=11720&q=mapRect&can=2
  //
  // All geometry is X,Y only which means the 3rd row of the 4x4 matrix
  // is ignored and the output of the 3rd column is also ignored.
  // So we can transform the rectangle using just the 3x3 SkMatrix
  // equivalent without any loss of information.
  //
  // Performance consideration:
  // Skia has an internal mapRect for their SkM44 object that is faster
  // than what SkMatrix does when it has perspective elements. But SkMatrix
  // is otherwise optimal for non-perspective matrices. If SkM44 ever exposes
  // a mapRect operation, or if SkMatrix ever optimizes its handling of
  // the perspective elements, this issue will become moot.
  transform_.asM33().mapRect(&child_paint_bounds);
  set_paint_bounds(child_paint_bounds);
}

void TransformLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting(context));

  auto mutator = context.state_stack.save();
  mutator.transform(transform_);

  PaintChildren(context);
}

}  // namespace flutter
