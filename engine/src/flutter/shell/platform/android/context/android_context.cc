// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/context/android_context.h"

namespace flutter {

AndroidContext::AndroidContext(AndroidRenderingAPI rendering_api)
    : rendering_api_(rendering_api) {}

AndroidContext::~AndroidContext() = default;

AndroidRenderingAPI AndroidContext::RenderingApi() const {
  return rendering_api_;
}

bool AndroidContext::IsValid() const {
  return true;
}

}  // namespace flutter
