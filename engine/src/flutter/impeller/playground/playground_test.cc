// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_test.h"

namespace impeller {

PlaygroundTest::PlaygroundTest() = default;

PlaygroundTest::~PlaygroundTest() = default;

void PlaygroundTest::SetUp() {
  if (!Playground::SupportsBackend(GetParam())) {
    GTEST_SKIP_("Playground doesn't support this backend type.");
    return;
  }

  SetupWindow(GetParam());
}

void PlaygroundTest::TearDown() {
  TeardownWindow();
}

// |Playground|
std::unique_ptr<fml::Mapping> PlaygroundTest::OpenAssetAsMapping(
    std::string asset_name) const {
  return flutter::testing::OpenFixtureAsMapping(asset_name);
}

static std::string FormatWindowTitle(const std::string& test_name) {
  std::stringstream stream;
  stream << "Impeller Playground for '" << test_name
         << "' (Press ESC or 'q' to quit)";
  return stream.str();
}

// |Playground|
std::string PlaygroundTest::GetWindowTitle() const {
  return FormatWindowTitle(flutter::testing::GetCurrentTestName());
}

}  // namespace impeller
