// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_FILTER_ANIMATION_CURVE_IMPL_H_
#define SKY_VIEWER_CC_WEB_FILTER_ANIMATION_CURVE_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebFilterAnimationCurve.h"

namespace cc {
class AnimationCurve;
class KeyframedFilterAnimationCurve;
}

namespace blink {
class WebFilterKeyframe;
}

namespace sky_viewer_cc {

class WebFilterAnimationCurveImpl : public blink::WebFilterAnimationCurve {
 public:
  SKY_VIEWER_CC_EXPORT WebFilterAnimationCurveImpl();
  virtual ~WebFilterAnimationCurveImpl();

  // blink::WebCompositorAnimationCurve implementation.
  virtual AnimationCurveType type() const;

  // blink::WebFilterAnimationCurve implementation.
  virtual void add(const blink::WebFilterKeyframe& keyframe,
                   TimingFunctionType type);
  virtual void add(const blink::WebFilterKeyframe& keyframe,
                   double x1,
                   double y1,
                   double x2,
                   double y2);

  scoped_ptr<cc::AnimationCurve> CloneToAnimationCurve() const;

 private:
  scoped_ptr<cc::KeyframedFilterAnimationCurve> curve_;

  DISALLOW_COPY_AND_ASSIGN(WebFilterAnimationCurveImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_FILTER_ANIMATION_CURVE_IMPL_H_
