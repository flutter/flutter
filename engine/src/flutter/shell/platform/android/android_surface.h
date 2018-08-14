// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/surface.h"
#include "flutter/shell/platform/android/android_native_window.h"
#include "third_party/skia/include/core/SkSize.h"

namespace shell {

class AndroidSurface {
 public:
  static std::unique_ptr<AndroidSurface> Create(bool use_software_rendering);

  virtual ~AndroidSurface();

  virtual bool IsValid() const = 0;

  virtual void TeardownOnScreenContext() = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface() = 0;

  virtual bool OnScreenSurfaceResize(const SkISize& size) const = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual bool ResourceContextClearCurrent() = 0;

  virtual bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) = 0;
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_H_
