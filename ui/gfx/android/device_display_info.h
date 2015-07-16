// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANDROID_DEVICE_DISPLAY_INFO_H_
#define UI_GFX_ANDROID_DEVICE_DISPLAY_INFO_H_

#include <jni.h>
#include <string>

#include "base/basictypes.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// Facilitates access to device information typically only
// available using the Android SDK, including Display properties.
class GFX_EXPORT DeviceDisplayInfo {
 public:
  DeviceDisplayInfo();
  ~DeviceDisplayInfo();

  // Returns display height in physical pixels.
  int GetDisplayHeight();

  // Returns display width in physical pixels.
  int GetDisplayWidth();

  // Returns real display height in physical pixels.
  // This version does not subtract window decorations etc.
  // WARNING: This is only supported on JB-MR1 (sdk >= 17). Either
  //          check the SDK-level, or check for '0' being returned.
  int GetPhysicalDisplayHeight();

  // Returns real display width in physical pixels.
  // This version does not subtract window decorations etc.
  // WARNING: This is only supported on JB-MR1 (sdk >= 17). Either
  //          check the SDK-level, or check for '0' being returned.
  int GetPhysicalDisplayWidth();

  // Returns number of bits per pixel.
  int GetBitsPerPixel();

  // Returns number of bits per component.
  int GetBitsPerComponent();

  // Returns a scaling factor for Density Independent Pixel unit
  // (1.0 is 160dpi, 0.75 is 120dpi, 2.0 is 320dpi).
  double GetDIPScale();

  // Smallest possible screen size in density-independent pixels.
  int GetSmallestDIPWidth();

  // Returns the display rotation angle from its natural orientation. Expected
  // values are one of { 0, 90, 180, 270 }.
  // See DeviceDispayInfo.java for more information.
  int GetRotationDegrees();

 private:
  DISALLOW_COPY_AND_ASSIGN(DeviceDisplayInfo);
};

}  // namespace gfx

#endif  // UI_GFX_ANDROID_DEVICE_DISPLAY_INFO_H_
