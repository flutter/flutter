// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"

namespace flutter {
namespace testing {

EmbedderTest::EmbedderTest() = default;

std::string EmbedderTest::GetFixturesDirectory() const {
  return GetFixturesPath();
}

EmbedderTestContext& EmbedderTest::GetEmbedderContext(ContextType type) {
  // Setup the embedder context lazily instead of in the constructor because we
  // don't to do all the work if the test won't end up using context.
  if (!embedder_contexts_[type]) {
    switch (type) {
      case ContextType::kSoftwareContext:
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextSoftware>(
                GetFixturesDirectory());
        break;
      case ContextType::kOpenGLContext:
        embedder_contexts_[type] =
            std::make_unique<EmbedderTestContextGL>(GetFixturesDirectory());
        break;
      default:
        FML_DCHECK(false) << "Invalid context type specified.";
        break;
    }
  }

  return *embedder_contexts_[type];
}

}  // namespace testing
}  // namespace flutter
