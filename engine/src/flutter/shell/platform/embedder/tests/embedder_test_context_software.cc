// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context_software.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/paths.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_software.h"
#include "flutter/testing/testing.h"
#include "third_party/dart/runtime/bin/elf_loader.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

EmbedderTestContextSoftware::EmbedderTestContextSoftware(
    std::string assets_path)
    : EmbedderTestContext(assets_path) {}

EmbedderTestContextSoftware::~EmbedderTestContextSoftware() = default;

bool EmbedderTestContextSoftware::Present(sk_sp<SkImage> image) {
  software_surface_present_count_++;

  FireRootSurfacePresentCallbackIfPresent([image] { return image; });

  return true;
}

size_t EmbedderTestContextSoftware::GetSurfacePresentCount() const {
  return software_surface_present_count_;
}

void EmbedderTestContextSoftware::SetupOpenGLSurface(SkISize surface_size) {
  FML_CHECK(!gl_surface_);
  gl_surface_ = std::make_unique<TestGLSurface>(surface_size);
}

void EmbedderTestContextSoftware::SetupCompositor() {
  FML_CHECK(!compositor_) << "Already ssetup a compositor in this context.";
  FML_CHECK(gl_surface_)
      << "Setup the GL surface before setting up a compositor.";
  compositor_ = std::make_unique<EmbedderTestCompositorSoftware>(
      gl_surface_->GetSurfaceSize(), gl_surface_->GetGrContext());
}

}  // namespace testing
}  // namespace flutter
