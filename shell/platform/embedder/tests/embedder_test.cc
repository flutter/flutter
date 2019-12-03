// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"

namespace flutter {
namespace testing {

EmbedderTest::EmbedderTest() = default;

EmbedderTest::~EmbedderTest() = default;

std::string EmbedderTest::GetFixturesDirectory() const {
  return GetFixturesPath();
}

EmbedderTestContext& EmbedderTest::GetEmbedderContext() {
  // Setup the embedder context lazily instead of in the SetUp method because we
  // don't to do all the work if the test won't end up using context.
  if (!embedder_context_) {
    embedder_context_ =
        std::make_unique<EmbedderTestContext>(GetFixturesDirectory());
  }
  return *embedder_context_;
}

// |testing::Test|
void EmbedderTest::SetUp() {
  ThreadTest::SetUp();
}

// |testing::Test|
void EmbedderTest::TearDown() {
  embedder_context_.reset();
  ThreadTest::TearDown();
}

}  // namespace testing
}  // namespace flutter
