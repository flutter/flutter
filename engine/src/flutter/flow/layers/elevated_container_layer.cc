// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/elevated_container_layer.h"

namespace flutter {
namespace {

float ClampElevation(float elevation,
                     float parent_elevation,
                     float max_elevation) {
  // TODO(mklim): Deal with bounds overflow more elegantly. We'd like to be
  // able to have developers specify the behavior here to alternatives besides
  // clamping, like normalization on some arbitrary curve.
  float clamped_elevation = elevation;
  if (max_elevation > -1 && (parent_elevation + elevation) > max_elevation) {
    // Clamp the local z coordinate at our max bound. Take into account the
    // parent z position here to fix clamping in cases where the child is
    // overflowing because of its parents.
    clamped_elevation = max_elevation - parent_elevation;
  }

  return clamped_elevation;
}

}  // namespace

ElevatedContainerLayer::ElevatedContainerLayer(float elevation)
    : elevation_(elevation), clamped_elevation_(elevation) {}

void ElevatedContainerLayer::Preroll(PrerollContext* context,
                                     const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ElevatedContainerLayer::Preroll");

  // Track total elevation as we walk the tree, in order to deal with bounds
  // overflow in z.
  parent_elevation_ = context->total_elevation;
  clamped_elevation_ = ClampElevation(elevation_, parent_elevation_,
                                      context->frame_physical_depth);
  context->total_elevation += clamped_elevation_;

  ContainerLayer::Preroll(context, matrix);

  // Restore the elevation for our parent.
  context->total_elevation = parent_elevation_;
}

}  // namespace flutter
