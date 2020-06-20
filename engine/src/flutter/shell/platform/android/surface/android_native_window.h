// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_

#include "flutter/fml/build_config.h"

#if OS_ANDROID
#include <android/native_window.h>
#endif  // OS_ANDROID

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class AndroidNativeWindow
    : public fml::RefCountedThreadSafe<AndroidNativeWindow> {
 public:
#if OS_ANDROID
  using Handle = ANativeWindow*;
#else   // OS_ANDROID
  using Handle = std::nullptr_t;
#endif  // OS_ANDROID

  bool IsValid() const;

  Handle handle() const;

  SkISize GetSize() const;

 private:
  Handle window_;

  /// Creates a native window with the given handle. Handle ownership is assumed
  /// by this instance of the native window.
  explicit AndroidNativeWindow(Handle window);

  ~AndroidNativeWindow();

  FML_FRIEND_MAKE_REF_COUNTED(AndroidNativeWindow);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(AndroidNativeWindow);
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidNativeWindow);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_NATIVE_WINDOW_H_
