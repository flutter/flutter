// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"

#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"

namespace flutter::testing {

std::unique_ptr<EmbedderTestContext> EmbedderTest::CreateGLContext() {
  return std::make_unique<EmbedderTestContextGL>(GetFixturesDirectory());
}

}  // namespace flutter::testing
