// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_software.h"

namespace flutter::testing {

EmbedderTest::EmbedderTest() = default;

std::string EmbedderTest::GetFixturesDirectory() const {
  return GetFixturesPath();
}

EmbedderTestContext& EmbedderTest::GetEmbedderContext(
    EmbedderTestContextType type) {
  // Setup the embedder context lazily instead of in the constructor because we
  // don't to do all the work if the test won't end up using context.
  if (!embedder_contexts_[type]) {
    switch (type) {
      case EmbedderTestContextType::kSoftwareContext:
        embedder_contexts_[type] = CreateSoftwareContext();
        break;
      case EmbedderTestContextType::kOpenGLContext:
        embedder_contexts_[type] = CreateGLContext();
        break;
      case EmbedderTestContextType::kVulkanContext:
        embedder_contexts_[type] = CreateVulkanContext();
        break;
      case EmbedderTestContextType::kMetalContext:
        embedder_contexts_[type] = CreateMetalContext();
        break;
      default:
        FML_DCHECK(false) << "Invalid context type specified.";
        break;
    }
  }

  return *embedder_contexts_[type];
}

std::unique_ptr<EmbedderTestContext> EmbedderTest::CreateSoftwareContext() {
  return std::make_unique<EmbedderTestContextSoftware>(GetFixturesDirectory());
}

#ifndef SHELL_ENABLE_GL
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_gl.cc.
std::unique_ptr<EmbedderTestContext> EmbedderTest::CreateGLContext() {
  FML_LOG(FATAL) << "OpenGL is not supported in this build";
  return nullptr;
}
#endif

#ifndef SHELL_ENABLE_METAL
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_metal.mm.
std::unique_ptr<EmbedderTestContext> EmbedderTest::CreateMetalContext() {
  FML_LOG(FATAL) << "Metal is not supported in this build";
  return nullptr;
}
#endif

#ifndef SHELL_ENABLE_VULKAN
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_vulkan.cc.
std::unique_ptr<EmbedderTestContext> EmbedderTest::CreateVulkanContext() {
  FML_LOG(FATAL) << "Vulkan is not supported in this build";
  return nullptr;
}
#endif

}  // namespace flutter::testing
