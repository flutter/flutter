// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/tests/embedder_context.h"
#include "flutter/testing/testing.h"

namespace shell {
namespace testing {

class EmbedderTest : public ::testing::Test {
 public:
  EmbedderTest();

  ~EmbedderTest() override;

  std::string GetFixturesDirectory() const;

  EmbedderContext& GetEmbedderContext();

 private:
  std::unique_ptr<EmbedderContext> embedder_context_;

  // |testing::Test|
  void SetUp() override;

  // |testing::Test|
  void TearDown() override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTest);
};

}  // namespace testing
}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_
