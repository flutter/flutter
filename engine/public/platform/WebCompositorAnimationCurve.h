// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONCURVE_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONCURVE_H_

#define WEB_SCROLL_OFFSET_ANIMATION_CURVE_IS_DEFINED 1

namespace blink {

class WebCompositorAnimationCurve {
public:
    virtual ~WebCompositorAnimationCurve() { }

    enum TimingFunctionType {
        TimingFunctionTypeEase,
        TimingFunctionTypeEaseIn,
        TimingFunctionTypeEaseOut,
        TimingFunctionTypeEaseInOut,
        TimingFunctionTypeLinear
    };

    enum AnimationCurveType {
        AnimationCurveTypeFilter,
        AnimationCurveTypeFloat,
        AnimationCurveTypeTransform,
    };

    virtual AnimationCurveType type() const = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONCURVE_H_
