// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_transform_operations_impl.h"

#include <algorithm>

#include "ui/gfx/transform.h"

namespace sky_viewer_cc {

WebTransformOperationsImpl::WebTransformOperationsImpl() {
}

const cc::TransformOperations&
WebTransformOperationsImpl::AsTransformOperations() const {
  return transform_operations_;
}

bool WebTransformOperationsImpl::canBlendWith(
    const blink::WebTransformOperations& other) const {
  const WebTransformOperationsImpl& other_impl =
      static_cast<const WebTransformOperationsImpl&>(other);
  return transform_operations_.CanBlendWith(other_impl.transform_operations_);
}

void WebTransformOperationsImpl::appendTranslate(double x, double y, double z) {
  transform_operations_.AppendTranslate(x, y, z);
}

void WebTransformOperationsImpl::appendRotate(double x,
                                              double y,
                                              double z,
                                              double degrees) {
  transform_operations_.AppendRotate(x, y, z, degrees);
}

void WebTransformOperationsImpl::appendScale(double x, double y, double z) {
  transform_operations_.AppendScale(x, y, z);
}

void WebTransformOperationsImpl::appendSkew(double x, double y) {
  transform_operations_.AppendSkew(x, y);
}

void WebTransformOperationsImpl::appendPerspective(double depth) {
  transform_operations_.AppendPerspective(depth);
}

void WebTransformOperationsImpl::appendMatrix(const SkMatrix44& matrix) {
  gfx::Transform transform(gfx::Transform::kSkipInitialization);
  transform.matrix() = matrix;
  transform_operations_.AppendMatrix(transform);
}

void WebTransformOperationsImpl::appendIdentity() {
  transform_operations_.AppendIdentity();
}

bool WebTransformOperationsImpl::isIdentity() const {
  return transform_operations_.IsIdentity();
}

WebTransformOperationsImpl::~WebTransformOperationsImpl() {
}

}  // namespace sky_viewer_cc
