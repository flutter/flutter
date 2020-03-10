// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_RENDERING_API_SELECTION_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_RENDERING_API_SELECTION_H_

#include <objc/runtime.h>

#include "flutter/fml/macros.h"

namespace flutter {

enum class IOSRenderingAPI {
  kSoftware,
  kOpenGLES,
  kMetal,
};

IOSRenderingAPI GetRenderingAPIForProcess();

Class GetCoreAnimationLayerClassForRenderingAPI(
    IOSRenderingAPI rendering_api = GetRenderingAPIForProcess());

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_RENDERING_API_SELECTION_H_
