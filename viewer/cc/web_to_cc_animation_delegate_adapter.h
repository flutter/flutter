// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_TO_CC_ANIMATION_DELEGATE_ADAPTER_H_
#define SKY_VIEWER_CC_WEB_TO_CC_ANIMATION_DELEGATE_ADAPTER_H_

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "cc/animation/animation_delegate.h"

namespace blink {
class WebCompositorAnimationDelegate;
}

namespace sky_viewer_cc {

class WebToCCAnimationDelegateAdapter : public cc::AnimationDelegate {
 public:
  explicit WebToCCAnimationDelegateAdapter(
      blink::WebCompositorAnimationDelegate* delegate);

 private:
  virtual void NotifyAnimationStarted(
      base::TimeTicks monotonic_time,
      cc::Animation::TargetProperty target_property,
      int group) override;
  virtual void NotifyAnimationFinished(
      base::TimeTicks monotonic_time,
      cc::Animation::TargetProperty target_property,
      int group) override;

  blink::WebCompositorAnimationDelegate* delegate_;

  DISALLOW_COPY_AND_ASSIGN(WebToCCAnimationDelegateAdapter);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_TO_CC_ANIMATION_DELEGATE_ADAPTER_H_
