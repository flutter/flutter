// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_ANIMATION_CURVE_COMMON_H_
#define SKY_VIEWER_CC_WEB_ANIMATION_CURVE_COMMON_H_

#include "base/memory/scoped_ptr.h"
#include "sky/engine/public/platform/WebCompositorAnimationCurve.h"

namespace cc {
class TimingFunction;
}

namespace sky_viewer_cc {
scoped_ptr<cc::TimingFunction> CreateTimingFunction(
    blink::WebCompositorAnimationCurve::TimingFunctionType);
}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_ANIMATION_CURVE_COMMON_H_
