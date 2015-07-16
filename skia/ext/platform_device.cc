// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "skia/ext/platform_device.h"

#include "third_party/skia/include/core/SkMetaData.h"

namespace skia {

namespace {

const char* kDevicePlatformBehaviour = "CrDevicePlatformBehaviour";
const char* kDraftModeKey = "CrDraftMode";

#if defined(OS_MACOSX) || defined(OS_WIN)
const char* kIsPreviewMetafileKey = "CrIsPreviewMetafile";
#endif

void SetBoolMetaData(const SkCanvas& canvas, const char* key,  bool value) {
  SkMetaData& meta = skia::getMetaData(canvas);
  meta.setBool(key, value);
}

bool GetBoolMetaData(const SkCanvas& canvas, const char* key) {
  bool value;
  SkMetaData& meta = skia::getMetaData(canvas);
  if (!meta.findBool(key, &value))
    value = false;
  return value;
}

}  // namespace

void SetPlatformDevice(SkBaseDevice* device, PlatformDevice* platform_behaviour) {
  SkMetaData& meta_data = device->getMetaData();
  meta_data.setPtr(kDevicePlatformBehaviour, platform_behaviour);
}

PlatformDevice* GetPlatformDevice(SkBaseDevice* device) {
  if (device) {
    SkMetaData& meta_data = device->getMetaData();
    PlatformDevice* device_behaviour = NULL;
    if (meta_data.findPtr(kDevicePlatformBehaviour,
                          reinterpret_cast<void**>(&device_behaviour)))
      return device_behaviour;
  }
  return NULL;
}

SkMetaData& getMetaData(const SkCanvas& canvas) {
  SkBaseDevice* device = canvas.getDevice();
  DCHECK(device != NULL);
  return device->getMetaData();
}

void SetIsDraftMode(const SkCanvas& canvas, bool draft_mode) {
  SetBoolMetaData(canvas, kDraftModeKey, draft_mode);
}

bool IsDraftMode(const SkCanvas& canvas) {
  return GetBoolMetaData(canvas, kDraftModeKey);
}

#if defined(OS_MACOSX) || defined(OS_WIN)
void SetIsPreviewMetafile(const SkCanvas& canvas, bool is_preview) {
  SetBoolMetaData(canvas, kIsPreviewMetafileKey, is_preview);
}

bool IsPreviewMetafile(const SkCanvas& canvas) {
  return GetBoolMetaData(canvas, kIsPreviewMetafileKey);
}
#endif

bool PlatformDevice::SupportsPlatformPaint() {
  return true;
}

}  // namespace skia
