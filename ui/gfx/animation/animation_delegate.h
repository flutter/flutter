// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANIMATION_ANIMATION_DELEGATE_H_
#define UI_GFX_ANIMATION_ANIMATION_DELEGATE_H_

#include "ui/gfx/gfx_export.h"

namespace gfx {

class Animation;

// AnimationDelegate
//
//  Implement this interface when you want to receive notifications about the
//  state of an animation.
class GFX_EXPORT AnimationDelegate {
 public:
  virtual ~AnimationDelegate() {}

  // Called when an animation has completed.
  virtual void AnimationEnded(const Animation* animation) {}

  // Called when an animation has progressed.
  virtual void AnimationProgressed(const Animation* animation) {}

  // Called when an animation has been canceled.
  virtual void AnimationCanceled(const Animation* animation) {}
};

}  // namespace gfx

#endif  // UI_GFX_ANIMATION_ANIMATION_DELEGATE_H_
