// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_animation_curve_common.h"

#include "cc/animation/timing_function.h"

namespace sky_viewer_cc {

scoped_ptr<cc::TimingFunction> CreateTimingFunction(
    blink::WebCompositorAnimationCurve::TimingFunctionType type) {
  switch (type) {
    case blink::WebCompositorAnimationCurve::TimingFunctionTypeEase:
      return cc::EaseTimingFunction::Create();
    case blink::WebCompositorAnimationCurve::TimingFunctionTypeEaseIn:
      return cc::EaseInTimingFunction::Create();
    case blink::WebCompositorAnimationCurve::TimingFunctionTypeEaseOut:
      return cc::EaseOutTimingFunction::Create();
    case blink::WebCompositorAnimationCurve::TimingFunctionTypeEaseInOut:
      return cc::EaseInOutTimingFunction::Create();
    case blink::WebCompositorAnimationCurve::TimingFunctionTypeLinear:
      return scoped_ptr<cc::TimingFunction>();
  }
  return scoped_ptr<cc::TimingFunction>();
}

}  // namespace sky_viewer_cc
