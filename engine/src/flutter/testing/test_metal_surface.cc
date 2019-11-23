// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_metal_surface.h"

#if TESTING_ENABLE_METAL
#include "flutter/testing/test_metal_surface_impl.h"
#endif  // TESTING_ENABLE_METAL

namespace flutter {

bool TestMetalSurface::PlatformSupportsMetal() {
#if TESTING_ENABLE_METAL
  return true;
#else   // TESTING_ENABLE_METAL
  return false;
#endif  // TESTING_ENABLE_METAL
}

std::unique_ptr<TestMetalSurface> TestMetalSurface::Create(
    SkISize surface_size) {
#if TESTING_ENABLE_METAL
  return std::make_unique<TestMetalSurfaceImpl>(surface_size);
#else   // TESTING_ENABLE_METAL
  return nullptr;
#endif  // TESTING_ENABLE_METAL
}

TestMetalSurface::TestMetalSurface() = default;

TestMetalSurface::~TestMetalSurface() = default;

bool TestMetalSurface::IsValid() const {
  return impl_ ? impl_->IsValid() : false;
}

sk_sp<GrContext> TestMetalSurface::GetGrContext() const {
  return impl_ ? impl_->GetGrContext() : nullptr;
}

sk_sp<SkSurface> TestMetalSurface::GetSurface() const {
  return impl_ ? impl_->GetSurface() : nullptr;
}

}  // namespace flutter
