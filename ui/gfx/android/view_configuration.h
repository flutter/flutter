// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANDROID_VIEW_CONFIGURATION_H_
#define UI_GFX_ANDROID_VIEW_CONFIGURATION_H_

#include <jni.h>

#include "ui/gfx/gfx_export.h"

namespace gfx {

// Provides access to Android's ViewConfiguration for gesture-related constants.
// Note: All methods may be safely called from any thread.
class GFX_EXPORT ViewConfiguration {
 public:
  static int GetDoubleTapTimeoutInMs();
  static int GetLongPressTimeoutInMs();
  static int GetTapTimeoutInMs();

  // Dimensionless coefficient of friction.
  static float GetScrollFriction();

  static int GetMaximumFlingVelocityInPixelsPerSecond();
  static int GetMinimumFlingVelocityInPixelsPerSecond();

  static int GetTouchSlopInPixels();
  static int GetDoubleTapSlopInPixels();

  static int GetMinScalingSpanInPixels();
  static int GetMinScalingTouchMajorInPixels();

  // Registers methods with JNI and returns true if succeeded.
  static bool RegisterViewConfiguration(JNIEnv* env);
};

}  // namespace gfx

#endif  // UI_GFX_ANDROID_VIEW_CONFIGURATION_H_
