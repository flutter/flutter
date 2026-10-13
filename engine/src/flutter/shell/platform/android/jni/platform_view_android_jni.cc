// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {

void PlatformMessagePayloadDeleter::operator()(
    FlutterPlatformMessagePayload* payload) const {
  if (payload->destruction_callback != nullptr) {
    payload->destruction_callback(payload->user_data);
  }
  delete payload;
}

PlatformViewAndroidJNI::~PlatformViewAndroidJNI() = default;

}  // namespace flutter
