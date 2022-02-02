// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_software.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"
#endif

#ifdef SHELL_ENABLE_METAL
#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"
#endif

namespace flutter {
namespace testing {

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
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextSoftware>(
                GetFixturesDirectory());
        break;
#ifdef SHELL_ENABLE_VULKAN
      case EmbedderTestContextType::kVulkanContext:
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextVulkan>(GetFixturesDirectory());
        break;
#endif
#ifdef SHELL_ENABLE_GL
      case EmbedderTestContextType::kOpenGLContext:
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextGL>(GetFixturesDirectory());
        break;
#endif
#ifdef SHELL_ENABLE_METAL
      case EmbedderTestContextType::kMetalContext:
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextMetal>(GetFixturesDirectory());
        break;
#endif
      default:
        FML_DCHECK(false) << "Invalid context type specified.";
        break;
    }
  }

  return *embedder_contexts_[type];
}

}  // namespace testing
}  // namespace flutter
