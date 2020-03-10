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

}  // namespace flutter
