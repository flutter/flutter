// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_scroll_offset_animation_curve_impl.h"

#include "cc/animation/scroll_offset_animation_curve.h"
#include "cc/animation/timing_function.h"
#include "sky/viewer/cc/web_animation_curve_common.h"

using blink::WebFloatPoint;

namespace sky_viewer_cc {

WebScrollOffsetAnimationCurveImpl::WebScrollOffsetAnimationCurveImpl(
    WebFloatPoint target_value,
    TimingFunctionType timing_function)
    : curve_(cc::ScrollOffsetAnimationCurve::Create(
          gfx::ScrollOffset(target_value.x, target_value.y),
          CreateTimingFunction(timing_function))) {
}

WebScrollOffsetAnimationCurveImpl::~WebScrollOffsetAnimationCurveImpl() {
}

blink::WebCompositorAnimationCurve::AnimationCurveType
WebScrollOffsetAnimationCurveImpl::type() const {
  return WebCompositorAnimationCurve::AnimationCurveTypeScrollOffset;
}

void WebScrollOffsetAnimationCurveImpl::setInitialValue(
    WebFloatPoint initial_value) {
  curve_->SetInitialValue(gfx::ScrollOffset(initial_value.x, initial_value.y));
}

WebFloatPoint WebScrollOffsetAnimationCurveImpl::getValue(double time) const {
  gfx::ScrollOffset value = curve_->GetValue(time);
  return WebFloatPoint(value.x(), value.y());
}

double WebScrollOffsetAnimationCurveImpl::duration() const {
  return curve_->Duration();
}

scoped_ptr<cc::AnimationCurve>
WebScrollOffsetAnimationCurveImpl::CloneToAnimationCurve() const {
  return curve_->Clone();
}

}  // namespace sky_viewer_cc
