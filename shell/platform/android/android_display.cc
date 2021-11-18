// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_display.h"
#include "android_display.h"

namespace flutter {

AndroidDisplay::AndroidDisplay(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : Display(jni_facade->GetDisplayRefreshRate()),
      jni_facade_(std::move(jni_facade)) {}

double AndroidDisplay::GetRefreshRate() const {
  return jni_facade_->GetDisplayRefreshRate();
}

}  // namespace flutter
