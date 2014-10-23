// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_layer_impl_fixed_bounds.h"

#include "cc/layers/layer.h"
#include "sky/engine/public/platform/WebFloatPoint.h"
#include "sky/engine/public/platform/WebSize.h"
#include "third_party/skia/include/utils/SkMatrix44.h"

using cc::Layer;

namespace sky_viewer_cc {

WebLayerImplFixedBounds::WebLayerImplFixedBounds() {
}

WebLayerImplFixedBounds::WebLayerImplFixedBounds(scoped_refptr<Layer> layer)
    : WebLayerImpl(layer) {
}

WebLayerImplFixedBounds::~WebLayerImplFixedBounds() {
}

void WebLayerImplFixedBounds::invalidateRect(const blink::WebFloatRect& rect) {
  // Partial invalidations seldom occur for such layers.
  // Simply invalidate the whole layer to avoid transformation of coordinates.
  invalidate();
}

void WebLayerImplFixedBounds::setTransformOrigin(
    const blink::WebFloatPoint3D& transform_origin) {
  if (transform_origin != this->transformOrigin()) {
    layer_->SetTransformOrigin(transform_origin);
    UpdateLayerBoundsAndTransform();
  }
}

void WebLayerImplFixedBounds::setBounds(const blink::WebSize& bounds) {
  if (original_bounds_ != gfx::Size(bounds)) {
    original_bounds_ = bounds;
    UpdateLayerBoundsAndTransform();
  }
}

blink::WebSize WebLayerImplFixedBounds::bounds() const {
  return original_bounds_;
}

void WebLayerImplFixedBounds::setTransform(const SkMatrix44& matrix) {
  gfx::Transform transform;
  transform.matrix() = matrix;
  SetTransformInternal(transform);
}

SkMatrix44 WebLayerImplFixedBounds::transform() const {
  return original_transform_.matrix();
}

void WebLayerImplFixedBounds::SetFixedBounds(gfx::Size fixed_bounds) {
  if (fixed_bounds_ != fixed_bounds) {
    fixed_bounds_ = fixed_bounds;
    UpdateLayerBoundsAndTransform();
  }
}

void WebLayerImplFixedBounds::SetTransformInternal(
    const gfx::Transform& transform) {
  if (original_transform_ != transform) {
    original_transform_ = transform;
    UpdateLayerBoundsAndTransform();
  }
}

void WebLayerImplFixedBounds::UpdateLayerBoundsAndTransform() {
  if (fixed_bounds_.IsEmpty() || original_bounds_.IsEmpty() ||
      fixed_bounds_ == original_bounds_ ||
      // For now fall back to non-fixed bounds for non-zero transform origin.
      // TODO(wangxianzhu): Support non-zero anchor point for fixed bounds.
      transformOrigin().x ||
      transformOrigin().y) {
    layer_->SetBounds(original_bounds_);
    layer_->SetTransform(original_transform_);
    return;
  }

  layer_->SetBounds(fixed_bounds_);

  // Apply bounds scale (bounds/fixed_bounds) over original transform.
  gfx::Transform transform_with_bounds_scale(original_transform_);
  float bounds_scale_x =
      static_cast<float>(original_bounds_.width()) / fixed_bounds_.width();
  float bounds_scale_y =
      static_cast<float>(original_bounds_.height()) / fixed_bounds_.height();
  transform_with_bounds_scale.Scale(bounds_scale_x, bounds_scale_y);
  layer_->SetTransform(transform_with_bounds_scale);
}

}  // namespace sky_viewer_cc
