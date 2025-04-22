// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_

#include <mutex>
#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"
#include "flutter/shell/platform/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/android/context/android_context.h"

namespace flutter {

class AndroidContextDynamicImpeller : public AndroidContext {
 public:
  explicit AndroidContextDynamicImpeller(
      const AndroidContext::ContextSettings& settings);

  ~AndroidContextDynamicImpeller();

  // |AndroidContext|
  bool IsValid() const override { return true; }

  // |AndroidContext|
  AndroidRenderingAPI RenderingApi() const override;

  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

  std::shared_ptr<AndroidContextGLImpeller> GetGLContext() const {
    return gl_context_;
  }

  std::shared_ptr<AndroidContextVKImpeller> GetVKContext() const {
    return vk_context_;
  }

 private:
  const AndroidContext::ContextSettings settings_;
  // The impeller context may be accessed simultaneously on UI/Raster/IO
  // threads.
  mutable std::mutex mutex_;
  mutable std::shared_ptr<AndroidContextGLImpeller> gl_context_;
  mutable std::shared_ptr<AndroidContextVKImpeller> vk_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextDynamicImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_
