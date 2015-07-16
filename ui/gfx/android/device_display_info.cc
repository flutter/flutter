// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/android/device_display_info.h"

#include "base/logging.h"
#include "ui/gfx/android/shared_device_display_info.h"

namespace gfx {

DeviceDisplayInfo::DeviceDisplayInfo() {
}

DeviceDisplayInfo::~DeviceDisplayInfo() {
}

int DeviceDisplayInfo::GetDisplayHeight() {
  return SharedDeviceDisplayInfo::GetInstance()->GetDisplayHeight();
}

int DeviceDisplayInfo::GetDisplayWidth() {
  return SharedDeviceDisplayInfo::GetInstance()->GetDisplayWidth();
}

int DeviceDisplayInfo::GetPhysicalDisplayHeight() {
  return SharedDeviceDisplayInfo::GetInstance()->GetPhysicalDisplayHeight();
}

int DeviceDisplayInfo::GetPhysicalDisplayWidth() {
  return SharedDeviceDisplayInfo::GetInstance()->GetPhysicalDisplayWidth();
}

int DeviceDisplayInfo::GetBitsPerPixel() {
  return SharedDeviceDisplayInfo::GetInstance()->GetBitsPerPixel();
}

int DeviceDisplayInfo::GetBitsPerComponent() {
  return SharedDeviceDisplayInfo::GetInstance()->GetBitsPerComponent();
}

double DeviceDisplayInfo::GetDIPScale() {
  return SharedDeviceDisplayInfo::GetInstance()->GetDIPScale();
}

int DeviceDisplayInfo::GetSmallestDIPWidth() {
  return SharedDeviceDisplayInfo::GetInstance()->GetSmallestDIPWidth();
}

int DeviceDisplayInfo::GetRotationDegrees() {
  return SharedDeviceDisplayInfo::GetInstance()->GetRotationDegrees();
}

}  // namespace gfx
