// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_animation_impl.h"

#include "cc/animation/animation.h"
#include "cc/animation/animation_curve.h"
#include "cc/animation/animation_id_provider.h"
#include "sky/viewer/cc/web_filter_animation_curve_impl.h"
#include "sky/viewer/cc/web_float_animation_curve_impl.h"
#include "sky/viewer/cc/web_scroll_offset_animation_curve_impl.h"
#include "sky/viewer/cc/web_transform_animation_curve_impl.h"
#include "sky/engine/public/platform/WebCompositorAnimationCurve.h"

using cc::Animation;
using cc::AnimationIdProvider;

using blink::WebCompositorAnimation;
using blink::WebCompositorAnimationCurve;

namespace sky_viewer_cc {

WebCompositorAnimationImpl::WebCompositorAnimationImpl(
    const WebCompositorAnimationCurve& web_curve,
    TargetProperty target_property,
    int animation_id,
    int group_id) {
  if (!animation_id)
    animation_id = AnimationIdProvider::NextAnimationId();
  if (!group_id)
    group_id = AnimationIdProvider::NextGroupId();

  WebCompositorAnimationCurve::AnimationCurveType curve_type = web_curve.type();
  scoped_ptr<cc::AnimationCurve> curve;
  switch (curve_type) {
    case WebCompositorAnimationCurve::AnimationCurveTypeFloat: {
      const WebFloatAnimationCurveImpl* float_curve_impl =
          static_cast<const WebFloatAnimationCurveImpl*>(&web_curve);
      curve = float_curve_impl->CloneToAnimationCurve();
      break;
    }
    case WebCompositorAnimationCurve::AnimationCurveTypeTransform: {
      const WebTransformAnimationCurveImpl* transform_curve_impl =
          static_cast<const WebTransformAnimationCurveImpl*>(&web_curve);
      curve = transform_curve_impl->CloneToAnimationCurve();
      break;
    }
    case WebCompositorAnimationCurve::AnimationCurveTypeFilter: {
      const WebFilterAnimationCurveImpl* filter_curve_impl =
          static_cast<const WebFilterAnimationCurveImpl*>(&web_curve);
      curve = filter_curve_impl->CloneToAnimationCurve();
      break;
    }
    case WebCompositorAnimationCurve::AnimationCurveTypeScrollOffset: {
      const WebScrollOffsetAnimationCurveImpl* scroll_curve_impl =
          static_cast<const WebScrollOffsetAnimationCurveImpl*>(&web_curve);
      curve = scroll_curve_impl->CloneToAnimationCurve();
      break;
    }
  }
  animation_ = Animation::Create(
      curve.Pass(),
      animation_id,
      group_id,
      static_cast<cc::Animation::TargetProperty>(target_property));
}

WebCompositorAnimationImpl::~WebCompositorAnimationImpl() {
}

int WebCompositorAnimationImpl::id() {
  return animation_->id();
}

blink::WebCompositorAnimation::TargetProperty
WebCompositorAnimationImpl::targetProperty() const {
  return static_cast<WebCompositorAnimationImpl::TargetProperty>(
      animation_->target_property());
}

#if WEB_ANIMATION_SUPPORTS_FRACTIONAL_ITERATIONS
double WebCompositorAnimationImpl::iterations() const {
  return animation_->iterations();
}

void WebCompositorAnimationImpl::setIterations(double n) {
  animation_->set_iterations(n);
}
#else
int WebCompositorAnimationImpl::iterations() const {
  return animation_->iterations();
}

void WebCompositorAnimationImpl::setIterations(int n) {
  animation_->set_iterations(n);
}
#endif

double WebCompositorAnimationImpl::startTime() const {
  return (animation_->start_time() - base::TimeTicks()).InSecondsF();
}

void WebCompositorAnimationImpl::setStartTime(double monotonic_time) {
  animation_->set_start_time(base::TimeTicks::FromInternalValue(
      monotonic_time * base::Time::kMicrosecondsPerSecond));
}

double WebCompositorAnimationImpl::timeOffset() const {
  return animation_->time_offset().InSecondsF();
}

void WebCompositorAnimationImpl::setTimeOffset(double monotonic_time) {
  animation_->set_time_offset(base::TimeDelta::FromSecondsD(monotonic_time));
}

#if WEB_ANIMATION_SUPPORTS_FULL_DIRECTION
blink::WebCompositorAnimation::Direction WebCompositorAnimationImpl::direction()
    const {
  switch (animation_->direction()) {
    case cc::Animation::Normal:
      return DirectionNormal;
    case cc::Animation::Reverse:
      return DirectionReverse;
    case cc::Animation::Alternate:
      return DirectionAlternate;
    case cc::Animation::AlternateReverse:
      return DirectionAlternateReverse;
    default:
      NOTREACHED();
  }
  return DirectionNormal;
}

void WebCompositorAnimationImpl::setDirection(Direction direction) {
  switch (direction) {
    case DirectionNormal:
      animation_->set_direction(cc::Animation::Normal);
      break;
    case DirectionReverse:
      animation_->set_direction(cc::Animation::Reverse);
      break;
    case DirectionAlternate:
      animation_->set_direction(cc::Animation::Alternate);
      break;
    case DirectionAlternateReverse:
      animation_->set_direction(cc::Animation::AlternateReverse);
      break;
  }
}
#else
bool WebCompositorAnimationImpl::alternatesDirection() const {
  return animation_->direction() == cc::Animation::Alternate;
}

void WebCompositorAnimationImpl::setAlternatesDirection(bool alternates) {
  if (alternates)
    animation_->set_direction(cc::Animation::Alternate);
  else
    animation_->set_direction(cc::Animation::Normal);
}
#endif

double WebCompositorAnimationImpl::playbackRate() const {
  return animation_->playback_rate();
}

void WebCompositorAnimationImpl::setPlaybackRate(double playback_rate) {
  animation_->set_playback_rate(playback_rate);
}

scoped_ptr<cc::Animation> WebCompositorAnimationImpl::PassAnimation() {
  animation_->set_needs_synchronized_start_time(true);
  return animation_.Pass();
}

}  // namespace sky_viewer_cc
