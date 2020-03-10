// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/ios_context_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_context_software.h"

#if FLUTTER_SHELL_ENABLE_METAL
#include "flutter/shell/platform/darwin/ios/ios_context_metal.h"
#endif  // FLUTTER_SHELL_ENABLE_METAL

namespace flutter {

IOSContext::IOSContext() = default;

IOSContext::~IOSContext() = default;

std::unique_ptr<IOSContext> IOSContext::Create(IOSRenderingAPI rendering_api) {
  switch (rendering_api) {
    case IOSRenderingAPI::kOpenGLES:
      return std::make_unique<IOSContextGL>();
    case IOSRenderingAPI::kSoftware:
      return std::make_unique<IOSContextSoftware>();
#if FLUTTER_SHELL_ENABLE_METAL
    case IOSRenderingAPI::kMetal:
      return std::make_unique<IOSContextMetal>();
#endif  // FLUTTER_SHELL_ENABLE_METAL
    default:
      break;
  }
  FML_CHECK(false);
  return nullptr;
}

}  // namespace flutter
