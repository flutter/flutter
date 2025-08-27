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

/// @brief An Impeller Android context that dynamically creates either an
/// [AndroidContextGLImpeller] or an [AndroidContextVKImpeller].
///
/// The construction of these objects is deferred until [GetImpellerContext] is
/// invoked. Up to this point, the reported backend will be kImpellerAutoselect.
class AndroidContextDynamicImpeller : public AndroidContext {
 public:
  explicit AndroidContextDynamicImpeller(
      const AndroidContext::ContextSettings& settings);

  ~AndroidContextDynamicImpeller();

  // |AndroidContext|
  bool IsValid() const override { return true; }

  // |AndroidContext|
  bool IsDynamicSelection() const override { return true; }

  // |AndroidContext|
  AndroidRenderingAPI RenderingApi() const override;

  /// @brief Retrieve the GL Context if it was created, or nullptr.
  std::shared_ptr<AndroidContextGLImpeller> GetGLContext() const;

  /// @brief Retrieve the VK context if it was created, or nullptr.
  std::shared_ptr<AndroidContextVKImpeller> GetVKContext() const;

  // |AndroidContext|
  void SetupImpellerContext() override;

  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

 private:
  const AndroidContext::ContextSettings settings_;
  std::shared_ptr<AndroidContextGLImpeller> gl_context_;
  std::shared_ptr<AndroidContextVKImpeller> vk_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextDynamicImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_
