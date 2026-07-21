// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/compute_playground_test.h"

#include "flutter/fml/time/time_point.h"
#include "flutter/testing/test_args.h"
#include "impeller/playground/playground_test.h"

namespace impeller {

ComputePlaygroundTest::ComputePlaygroundTest()
    : Playground(GetParam(), PlaygroundTest::kCommandLineSwitches) {}

ComputePlaygroundTest::~ComputePlaygroundTest() = default;

void ComputePlaygroundTest::SetUp() {
  if (!Playground::SupportsBackend(GetParam())) {
    GTEST_SKIP() << "Playground doesn't support this backend type.";
    return;
  }
  if (!IsBackendEnabled(GetParam())) {
    GTEST_SKIP() << "This backend is disabled by the command line";
    return;
  }

  if (!Playground::ShouldOpenNewPlaygrounds()) {
    GTEST_SKIP() << "Skipping due to user action.";
    return;
  }

  start_time_ = fml::TimePoint::Now().ToEpochDelta();
}

void ComputePlaygroundTest::TearDown() {
  Playground::TearDownContextData();
}

// |Playground|
std::unique_ptr<fml::Mapping> ComputePlaygroundTest::OpenAssetAsMapping(
    std::string asset_name) const {
  return flutter::testing::OpenFixtureAsMapping(asset_name);
}

static std::string FormatWindowTitle(const std::string& test_name) {
  std::stringstream stream;
  stream << "Impeller Playground for '" << test_name << "' (Press ESC to quit)";
  return stream.str();
}

// |Playground|
std::string ComputePlaygroundTest::GetWindowTitle() const {
  return FormatWindowTitle(flutter::testing::GetCurrentTestName());
}

}  // namespace impeller
