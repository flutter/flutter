// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_SCROLL_OFFSET_ANIMATION_CURVE_IMPL_H_
#define SKY_VIEWER_CC_WEB_SCROLL_OFFSET_ANIMATION_CURVE_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebScrollOffsetAnimationCurve.h"

namespace cc {
class AnimationCurve;
class ScrollOffsetAnimationCurve;
}

namespace sky_viewer_cc {

class WebScrollOffsetAnimationCurveImpl
    : public blink::WebScrollOffsetAnimationCurve {
 public:
  SKY_VIEWER_CC_EXPORT WebScrollOffsetAnimationCurveImpl(
      blink::WebFloatPoint target_value,
      TimingFunctionType timing_function);
  virtual ~WebScrollOffsetAnimationCurveImpl();

  // blink::WebCompositorAnimationCurve implementation.
  virtual AnimationCurveType type() const;

  // blink::WebScrollOffsetAnimationCurve implementation.
  virtual void setInitialValue(blink::WebFloatPoint initial_value);
  virtual blink::WebFloatPoint getValue(double time) const;
  virtual double duration() const;

  scoped_ptr<cc::AnimationCurve> CloneToAnimationCurve() const;

 private:
  scoped_ptr<cc::ScrollOffsetAnimationCurve> curve_;

  DISALLOW_COPY_AND_ASSIGN(WebScrollOffsetAnimationCurveImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_SCROLL_OFFSET_ANIMATION_CURVE_IMPL_H_
