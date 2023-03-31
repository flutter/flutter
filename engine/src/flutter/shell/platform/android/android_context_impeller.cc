// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_impeller.h"

namespace flutter {

AndroidContextImpeller::AndroidContextImpeller()
    : AndroidContext(AndroidRenderingAPI::kGPU) {}

AndroidContextImpeller::~AndroidContextImpeller() = default;

bool AndroidContextImpeller::IsValid() const {
  return true;
}

}  // namespace flutter
