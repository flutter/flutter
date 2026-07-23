// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/android/surface_control.h"

#include "impeller/base/validation.h"
#include "impeller/toolkit/android/surface_control_impl.h"
#include "impeller/toolkit/android/surface_transaction.h"

namespace impeller::android {

std::unique_ptr<SurfaceControl> SurfaceControl::Create(ANativeWindow* window,
                                                       const char* debug_name) {
  return std::unique_ptr<SurfaceControl>(
      new SurfaceControlImpl(window, debug_name));
}

bool SurfaceControl::IsAvailableOnPlatform() {
  auto api_level = android_get_device_api_level();

  // Technically SurfaceControl is supported on API 29 but I've observed
  // enough reported bugs that I'm bumping the constraint to 30. If
  // we had more time to test all of these older devices maybe we could
  // figure out what the problem is.
  // https://github.com/flutter/flutter/issues/155877
  return api_level >= 29 && GetProcTable().IsValid() &&
         GetProcTable().ASurfaceControl_createFromWindow.IsAvailable();
}

}  // namespace impeller::android
