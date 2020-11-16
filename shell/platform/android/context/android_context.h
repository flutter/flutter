// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_H_

#include "flutter/fml/macros.h"

namespace flutter {

enum class AndroidRenderingAPI {
  kSoftware,
  kOpenGLES,
  kVulkan,
};

//------------------------------------------------------------------------------
/// @brief      Holds state that is shared across Android surfaces.
///
class AndroidContext {
 public:
  explicit AndroidContext(AndroidRenderingAPI rendering_api);

  virtual ~AndroidContext();

  AndroidRenderingAPI RenderingApi() const;

  bool IsValid() const;

 private:
  const AndroidRenderingAPI rendering_api_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContext);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_H_
