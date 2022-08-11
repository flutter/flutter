// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_image_filter.h"

namespace flutter {

std::shared_ptr<DlImageFilter> DlImageFilter::From(
    const SkImageFilter* sk_filter) {
  if (sk_filter == nullptr) {
    return nullptr;
  }
  {
    SkColorFilter* color_filter;
    if (sk_filter->isColorFilterNode(&color_filter)) {
      FML_DCHECK(color_filter != nullptr);
      // If |isColorFilterNode| succeeds, the pointer it sets into color_filter
      // will be ref'd already so we do not use sk_ref_sp() here as that would
      // double-ref the color filter object. Instead we use a bare sk_sp
      // constructor to adopt this reference into an sk_sp<SkCF> without
      // reffing it and let the compiler manage the refs.
      return std::make_shared<DlColorFilterImageFilter>(
          DlColorFilter::From(sk_sp<SkColorFilter>(color_filter)));
    }
  }
  return std::make_shared<DlUnknownImageFilter>(sk_ref_sp(sk_filter));
}

std::shared_ptr<DlImageFilter> DlImageFilter::makeWithLocalMatrix(
    const SkMatrix& matrix) {
  if (matrix.isIdentity()) {
    return shared();
  }
  // Matrix
  switch (this->matrix_capability()) {
    case MatrixCapability::kTranslate: {
      if (!matrix.isTranslate()) {
        // Nothing we can do at this point
        return nullptr;
      }
      break;
    }
    case MatrixCapability::kScaleTranslate: {
      if (!matrix.isScaleTranslate()) {
        // Nothing we can do at this point
        return nullptr;
      }
      break;
    }
    default:
      break;
  }
  return std::make_shared<DlLocalMatrixImageFilter>(matrix, shared());
}

SkRect* DlComposeImageFilter::map_local_bounds(const SkRect& input_bounds,
                                               SkRect& output_bounds) const {
  SkRect cur_bounds = input_bounds;
  SkRect* ret = &output_bounds;
  // We set this result in case neither filter is present.
  output_bounds = input_bounds;
  if (inner_) {
    if (!inner_->map_local_bounds(cur_bounds, output_bounds)) {
      ret = nullptr;
    }
    cur_bounds = output_bounds;
  }
  if (outer_) {
    if (!outer_->map_local_bounds(cur_bounds, output_bounds)) {
      ret = nullptr;
    }
  }
  return ret;
}

SkIRect* DlComposeImageFilter::map_device_bounds(const SkIRect& input_bounds,
                                                 const SkMatrix& ctm,
                                                 SkIRect& output_bounds) const {
  SkIRect cur_bounds = input_bounds;
  SkIRect* ret = &output_bounds;
  // We set this result in case neither filter is present.
  output_bounds = input_bounds;
  if (inner_) {
    if (!inner_->map_device_bounds(cur_bounds, ctm, output_bounds)) {
      ret = nullptr;
    }
    cur_bounds = output_bounds;
  }
  if (outer_) {
    if (!outer_->map_device_bounds(cur_bounds, ctm, output_bounds)) {
      ret = nullptr;
    }
  }
  return ret;
}

SkIRect* DlComposeImageFilter::get_input_device_bounds(
    const SkIRect& output_bounds,
    const SkMatrix& ctm,
    SkIRect& input_bounds) const {
  SkIRect cur_bounds = output_bounds;
  SkIRect* ret = &input_bounds;
  // We set this result in case neither filter is present.
  input_bounds = output_bounds;
  if (outer_) {
    if (!outer_->get_input_device_bounds(cur_bounds, ctm, input_bounds)) {
      ret = nullptr;
    }
    cur_bounds = input_bounds;
  }
  if (inner_) {
    if (!inner_->get_input_device_bounds(cur_bounds, ctm, input_bounds)) {
      ret = nullptr;
    }
  }
  return ret;
}

}  // namespace flutter
