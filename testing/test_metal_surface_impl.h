// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_METAL_SURFACE_IMPL_H_
#define FLUTTER_TESTING_TEST_METAL_SURFACE_IMPL_H_

#include "flutter/fml/macros.h"
#include "flutter/testing/test_metal_surface.h"

namespace flutter {

class TestMetalSurfaceImpl : public TestMetalSurface {
 public:
  TestMetalSurfaceImpl(SkISize surface_size);

  // |TestMetalSurface|
  ~TestMetalSurfaceImpl() override;

 private:
  bool is_valid_ = false;
  sk_sp<GrContext> context_;
  sk_sp<SkSurface> surface_;

  // |TestMetalSurface|
  bool IsValid() const override;

  // |TestMetalSurface|
  sk_sp<GrContext> GetGrContext() const override;

  // |TestMetalSurface|
  sk_sp<SkSurface> GetSurface() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(TestMetalSurfaceImpl);
};

}  // namespace flutter

#endif  // FLUTTER_TESTING_TEST_METAL_SURFACE_IMPL_H_
