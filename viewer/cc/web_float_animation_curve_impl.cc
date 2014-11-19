// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_float_animation_curve_impl.h"

#include "cc/animation/animation_curve.h"
#include "cc/animation/keyframed_animation_curve.h"
#include "cc/animation/timing_function.h"
#include "sky/viewer/cc/web_animation_curve_common.h"

using blink::WebFloatKeyframe;

namespace sky_viewer_cc {

WebFloatAnimationCurveImpl::WebFloatAnimationCurveImpl()
    : curve_(cc::KeyframedFloatAnimationCurve::Create()) {
}

WebFloatAnimationCurveImpl::~WebFloatAnimationCurveImpl() {
}

blink::WebCompositorAnimationCurve::AnimationCurveType
WebFloatAnimationCurveImpl::type() const {
  return blink::WebCompositorAnimationCurve::AnimationCurveTypeFloat;
}

void WebFloatAnimationCurveImpl::add(const WebFloatKeyframe& keyframe) {
  add(keyframe, TimingFunctionTypeEase);
}

void WebFloatAnimationCurveImpl::add(const WebFloatKeyframe& keyframe,
                                     TimingFunctionType type) {
  curve_->AddKeyframe(
      cc::FloatKeyframe::Create(base::TimeDelta::FromSecondsD(keyframe.time),
                                keyframe.value, CreateTimingFunction(type)));
}

void WebFloatAnimationCurveImpl::add(const WebFloatKeyframe& keyframe,
                                     double x1,
                                     double y1,
                                     double x2,
                                     double y2) {
  curve_->AddKeyframe(cc::FloatKeyframe::Create(
      base::TimeDelta::FromSecondsD(keyframe.time), keyframe.value,
      cc::CubicBezierTimingFunction::Create(x1, y1, x2, y2).Pass()));
}

float WebFloatAnimationCurveImpl::getValue(double time) const {
  return curve_->GetValue(base::TimeDelta::FromSecondsD(time));
}

scoped_ptr<cc::AnimationCurve>
WebFloatAnimationCurveImpl::CloneToAnimationCurve() const {
  return curve_->Clone();
}

}  // namespace sky_viewer_cc
