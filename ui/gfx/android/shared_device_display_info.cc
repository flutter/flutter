// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/android/shared_device_display_info.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/logging.h"
#include "jni/DeviceDisplayInfo_jni.h"

namespace gfx {

// static JNI call
static void UpdateSharedDeviceDisplayInfo(JNIEnv* env,
                                          jobject obj,
                                          jint display_height,
                                          jint display_width,
                                          jint physical_display_height,
                                          jint physical_display_width,
                                          jint bits_per_pixel,
                                          jint bits_per_component,
                                          jdouble dip_scale,
                                          jint smallest_dip_width,
                                          jint rotation_degrees) {
  SharedDeviceDisplayInfo::GetInstance()->InvokeUpdate(env, obj,
      display_height, display_width,
      physical_display_height, physical_display_width,
      bits_per_pixel, bits_per_component,
      dip_scale, smallest_dip_width, rotation_degrees);
}

// static
SharedDeviceDisplayInfo* SharedDeviceDisplayInfo::GetInstance() {
  return Singleton<SharedDeviceDisplayInfo>::get();
}

int SharedDeviceDisplayInfo::GetDisplayHeight() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, display_height_);
  return display_height_;
}

int SharedDeviceDisplayInfo::GetDisplayWidth() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, display_width_);
  return display_width_;
}

int SharedDeviceDisplayInfo::GetPhysicalDisplayHeight() {
  base::AutoLock autolock(lock_);
  return physical_display_height_;
}

int SharedDeviceDisplayInfo::GetPhysicalDisplayWidth() {
  base::AutoLock autolock(lock_);
  return physical_display_width_;
}

int SharedDeviceDisplayInfo::GetBitsPerPixel() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, bits_per_pixel_);
  return bits_per_pixel_;
}

int SharedDeviceDisplayInfo::GetBitsPerComponent() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, bits_per_component_);
  return bits_per_component_;
}

double SharedDeviceDisplayInfo::GetDIPScale() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, dip_scale_);
  return dip_scale_;
}

int SharedDeviceDisplayInfo::GetSmallestDIPWidth() {
  base::AutoLock autolock(lock_);
  DCHECK_NE(0, smallest_dip_width_);
  return smallest_dip_width_;
}

int SharedDeviceDisplayInfo::GetRotationDegrees() {
  base::AutoLock autolock(lock_);
  return rotation_degrees_;
}

// static
bool SharedDeviceDisplayInfo::RegisterSharedDeviceDisplayInfo(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

void SharedDeviceDisplayInfo::InvokeUpdate(JNIEnv* env,
                                           jobject obj,
                                           jint display_height,
                                           jint display_width,
                                           jint physical_display_height,
                                           jint physical_display_width,
                                           jint bits_per_pixel,
                                           jint bits_per_component,
                                           jdouble dip_scale,
                                           jint smallest_dip_width,
                                           jint rotation_degrees) {
  base::AutoLock autolock(lock_);

  UpdateDisplayInfo(env, obj,
      display_height, display_width,
      physical_display_height, physical_display_width,
      bits_per_pixel, bits_per_component, dip_scale,
      smallest_dip_width, rotation_degrees);
}

SharedDeviceDisplayInfo::SharedDeviceDisplayInfo()
    : display_height_(0),
      display_width_(0),
      bits_per_pixel_(0),
      bits_per_component_(0),
      dip_scale_(0),
      smallest_dip_width_(0) {
  JNIEnv* env = base::android::AttachCurrentThread();
  j_device_info_.Reset(
      Java_DeviceDisplayInfo_create(
          env, base::android::GetApplicationContext()));
  UpdateDisplayInfo(env, j_device_info_.obj(),
      Java_DeviceDisplayInfo_getDisplayHeight(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getDisplayWidth(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getPhysicalDisplayHeight(env,
                                                      j_device_info_.obj()),
      Java_DeviceDisplayInfo_getPhysicalDisplayWidth(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getBitsPerPixel(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getBitsPerComponent(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getDIPScale(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getSmallestDIPWidth(env, j_device_info_.obj()),
      Java_DeviceDisplayInfo_getRotationDegrees(env, j_device_info_.obj()));
}

SharedDeviceDisplayInfo::~SharedDeviceDisplayInfo() {
}

void SharedDeviceDisplayInfo::UpdateDisplayInfo(JNIEnv* env,
                                                jobject jobj,
                                                jint display_height,
                                                jint display_width,
                                                jint physical_display_height,
                                                jint physical_display_width,
                                                jint bits_per_pixel,
                                                jint bits_per_component,
                                                jdouble dip_scale,
                                                jint smallest_dip_width,
                                                jint rotation_degrees) {
  display_height_ = static_cast<int>(display_height);
  display_width_ = static_cast<int>(display_width);
  physical_display_height_ = static_cast<int>(physical_display_height);
  physical_display_width_ = static_cast<int>(physical_display_width);
  bits_per_pixel_ = static_cast<int>(bits_per_pixel);
  bits_per_component_ = static_cast<int>(bits_per_component);
  dip_scale_ = static_cast<double>(dip_scale);
  smallest_dip_width_ = static_cast<int>(smallest_dip_width);
  rotation_degrees_ = static_cast<int>(rotation_degrees);
}

}  // namespace gfx
