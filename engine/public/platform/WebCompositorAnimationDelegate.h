// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONDELEGATE_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONDELEGATE_H_

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebCompositorAnimation.h"

#define WEB_ANIMATION_DELEGATE_TAKES_MONOTONIC_TIME 1

namespace blink {

class BLINK_PLATFORM_EXPORT WebCompositorAnimationDelegate {
public:
    virtual ~WebCompositorAnimationDelegate() { }

    virtual void notifyAnimationStarted(double monotonicTime, WebCompositorAnimation::TargetProperty) = 0;
    virtual void notifyAnimationFinished(double monotonicTime, WebCompositorAnimation::TargetProperty) = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBCOMPOSITORANIMATIONDELEGATE_H_
