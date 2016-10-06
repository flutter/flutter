// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_

#include <android/native_window.h>
#include "lib/ftl/macros.h"

namespace shell {

class AndroidNativeWindow {
 public:
  using Handle = ANativeWindow*;

  AndroidNativeWindow(Handle window);

  AndroidNativeWindow(AndroidNativeWindow&& other);

  ~AndroidNativeWindow();

  bool IsValid() const;

  Handle handle() const;

 private:
  Handle window_;

  FTL_DISALLOW_COPY_AND_ASSIGN(AndroidNativeWindow);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_
