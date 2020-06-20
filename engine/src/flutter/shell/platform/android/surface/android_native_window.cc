// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/android_native_window.h"

namespace flutter {

AndroidNativeWindow::AndroidNativeWindow(Handle window) : window_(window) {}

AndroidNativeWindow::~AndroidNativeWindow() {
  if (window_ != nullptr) {
#if OS_ANDROID
    ANativeWindow_release(window_);
#endif  // OS_ANDROID
    window_ = nullptr;
  }
}

bool AndroidNativeWindow::IsValid() const {
  return window_ != nullptr;
}

AndroidNativeWindow::Handle AndroidNativeWindow::handle() const {
  return window_;
}

SkISize AndroidNativeWindow::GetSize() const {
#if OS_ANDROID
  return window_ == nullptr ? SkISize::Make(0, 0)
                            : SkISize::Make(ANativeWindow_getWidth(window_),
                                            ANativeWindow_getHeight(window_));
#else   // OS_ANDROID
  return SkISize::Make(0, 0);
#endif  // OS_ANDROID
}

}  // namespace flutter
