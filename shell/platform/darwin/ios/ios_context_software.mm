// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context_software.h"

namespace flutter {

IOSContextSoftware::IOSContextSoftware() = default;

// |IOSContext|
IOSContextSoftware::~IOSContextSoftware() = default;

// |IOSContext|
sk_sp<GrContext> IOSContextSoftware::CreateResourceContext() {
  return nullptr;
}

// |IOSContext|
bool IOSContextSoftware::MakeCurrent() {
  return false;
}

// |IOSContext|
bool IOSContextSoftware::ResourceMakeCurrent() {
  return false;
}

// |IOSContext|
bool IOSContextSoftware::ClearCurrent() {
  return false;
}

// |IOSContext|
std::unique_ptr<Texture> IOSContextSoftware::CreateExternalTexture(
    int64_t texture_id,
    fml::scoped_nsobject<NSObject<FlutterTexture>> texture) {
  // Don't use FML for logging as it will contain engine specific details. This is a user facing
  // message.
  NSLog(@"Flutter: Attempted to composite external texture sources using the software backend. "
        @"This backend is only used on simulators. This feature is only available on actual "
        @"devices where OpenGL or Metal is used for rendering.");

  // Not supported in this backend.
  return nullptr;
}

}  // namespace flutter
