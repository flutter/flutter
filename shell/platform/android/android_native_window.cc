// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_native_window.h"

namespace shell {

AndroidNativeWindow::AndroidNativeWindow(Handle window) : window_(window) {}

AndroidNativeWindow::~AndroidNativeWindow() {
  if (window_ != nullptr) {
    ANativeWindow_release(window_);
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
  return window_ == nullptr ? SkISize::Make(0, 0)
                            : SkISize::Make(ANativeWindow_getWidth(window_),
                                            ANativeWindow_getHeight(window_));
}

}  // namespace shell
