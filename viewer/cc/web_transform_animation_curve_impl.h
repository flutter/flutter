// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_TRANSFORM_ANIMATION_CURVE_IMPL_H_
#define SKY_VIEWER_CC_WEB_TRANSFORM_ANIMATION_CURVE_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebTransformAnimationCurve.h"

namespace cc {
class AnimationCurve;
class KeyframedTransformAnimationCurve;
}

namespace blink {
class WebTransformKeyframe;
}

namespace sky_viewer_cc {

class WebTransformAnimationCurveImpl
    : public blink::WebTransformAnimationCurve {
 public:
  SKY_VIEWER_CC_EXPORT WebTransformAnimationCurveImpl();
  virtual ~WebTransformAnimationCurveImpl();

  // blink::WebCompositorAnimationCurve implementation.
  virtual AnimationCurveType type() const;

  // blink::WebTransformAnimationCurve implementation.
  virtual void add(const blink::WebTransformKeyframe& keyframe);
  virtual void add(const blink::WebTransformKeyframe& keyframe,
                   TimingFunctionType type);
  virtual void add(const blink::WebTransformKeyframe& keyframe,
                   double x1,
                   double y1,
                   double x2,
                   double y2);

  scoped_ptr<cc::AnimationCurve> CloneToAnimationCurve() const;

 private:
  scoped_ptr<cc::KeyframedTransformAnimationCurve> curve_;

  DISALLOW_COPY_AND_ASSIGN(WebTransformAnimationCurveImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_TRANSFORM_ANIMATION_CURVE_IMPL_H_
