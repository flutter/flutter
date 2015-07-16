// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANDROID_SHARED_DEVICE_DISPLAY_INFO_H_
#define UI_GFX_ANDROID_SHARED_DEVICE_DISPLAY_INFO_H_

#include "base/android/scoped_java_ref.h"
#include "base/basictypes.h"
#include "base/memory/singleton.h"
#include "base/synchronization/lock.h"

namespace gfx {

// Facilitates access to device information typically only
// available using the Android SDK, including Display properties.
class SharedDeviceDisplayInfo {
 public:
  static SharedDeviceDisplayInfo* GetInstance();

  // See documentation in DeviceDisplayInfo.java
  int GetDisplayHeight();
  int GetDisplayWidth();
  int GetPhysicalDisplayHeight();
  int GetPhysicalDisplayWidth();
  int GetBitsPerPixel();
  int GetBitsPerComponent();
  double GetDIPScale();
  int GetSmallestDIPWidth();
  int GetRotationDegrees();

  // Registers methods with JNI and returns true if succeeded.
  static bool RegisterSharedDeviceDisplayInfo(JNIEnv* env);

  void InvokeUpdate(JNIEnv* env,
                    jobject jobj,
                    jint display_height,
                    jint display_width,
                    jint physical_display_height,
                    jint physical_display_width,
                    jint bits_per_pixel,
                    jint bits_per_component,
                    jdouble dip_scale,
                    jint smallest_dip_width,
                    jint rotation_degrees);
 private:
  friend struct DefaultSingletonTraits<SharedDeviceDisplayInfo>;

  SharedDeviceDisplayInfo();
  ~SharedDeviceDisplayInfo();
  void UpdateDisplayInfo(JNIEnv* env,
                         jobject jobj,
                         jint display_height,
                         jint display_width,
                         jint physical_display_height,
                         jint physical_display_width,
                         jint bits_per_pixel,
                         jint bits_per_component,
                         jdouble dip_scale,
                         jint smallest_dip_width,
                         jint rotation_degrees);

  base::Lock lock_;
  base::android::ScopedJavaGlobalRef<jobject> j_device_info_;

  int display_height_;
  int display_width_;
  int physical_display_height_;
  int physical_display_width_;
  int bits_per_pixel_;
  int bits_per_component_;
  double dip_scale_;
  int smallest_dip_width_;
  int rotation_degrees_;

  DISALLOW_COPY_AND_ASSIGN(SharedDeviceDisplayInfo);
};

}  // namespace gfx

#endif // UI_GFX_ANDROID_SHARED_DEVICE_DISPLAY_INFO_H_
