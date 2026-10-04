// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/android/surface_control_impl.h"

#include "impeller/base/validation.h"
#include "impeller/toolkit/android/surface_transaction.h"

namespace impeller::android {

SurfaceControlImpl::SurfaceControlImpl(ANativeWindow* window,
                                       const char* debug_name) {
  if (window == nullptr) {
    VALIDATION_LOG << "Parent window of surface was null.";
    return;
  }
  if (debug_name == nullptr) {
    debug_name = "Impeller Layer";
  }
  control_.reset(
      GetProcTable().ASurfaceControl_createFromWindow(window, debug_name));
}

SurfaceControlImpl::~SurfaceControlImpl() {
  if (IsValid() && !RemoveFromParent()) {
    VALIDATION_LOG << "Surface control could not be removed from its parent. "
                      "Expect a leak.";
  }
}

bool SurfaceControlImpl::IsValid() const {
  return control_.is_valid();
}

ASurfaceControl* SurfaceControlImpl::GetHandle() const {
  return control_.get();
}

bool SurfaceControlImpl::RemoveFromParent() const {
  if (!IsValid()) {
    return false;
  }
  SurfaceTransaction transaction;
  if (!transaction.SetParent(*this, nullptr)) {
    return false;
  }
  return transaction.Apply();
}

}  // namespace impeller::android
