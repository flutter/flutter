// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"

#include "impeller/base/timing.h"
#include "impeller/base/validation.h"
#include "impeller/playground/playground_test.h"

namespace impeller {

PlaygroundTest::PlaygroundTest()
    : Playground(PlaygroundSwitches{flutter::testing::GetArgsForProcess()}) {}

PlaygroundTest::~PlaygroundTest() = default;

void PlaygroundTest::SetUp() {
  if (!Playground::SupportsBackend(GetParam())) {
    GTEST_SKIP_("Playground doesn't support this backend type.");
    return;
  }

  if (!Playground::ShouldOpenNewPlaygrounds()) {
    GTEST_SKIP_("Skipping due to user action.");
    return;
  }

  ImpellerValidationErrorsSetFatal(true);

  SetupContext(GetParam());
  SetupWindow();
}

PlaygroundBackend PlaygroundTest::GetBackend() const {
  return GetParam();
}

void PlaygroundTest::TearDown() {
  TeardownWindow();
}

// |Playground|
std::unique_ptr<fml::Mapping> PlaygroundTest::OpenAssetAsMapping(
    std::string asset_name) const {
  return flutter::testing::OpenFixtureAsMapping(asset_name);
}

RuntimeStage::Map PlaygroundTest::OpenAssetAsRuntimeStage(
    const char* asset_name) const {
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping(asset_name);
  if (!fixture || fixture->GetSize() == 0) {
    return {};
  }
  return RuntimeStage::DecodeRuntimeStages(fixture);
}

// |Playground|
std::string PlaygroundTest::GetWindowTitle() const {
  std::stringstream stream;
  stream << "Impeller Playground for '"
         << flutter::testing::GetCurrentTestName() << "' ";
  switch (GetBackend()) {
    case PlaygroundBackend::kMetal:
      break;
    case PlaygroundBackend::kOpenGLES:
      if (switches_.use_angle) {
        stream << " (Angle) ";
      }
      break;
    case PlaygroundBackend::kVulkan:
      if (switches_.use_swiftshader) {
        stream << " (SwiftShader) ";
      }
      break;
  }
  stream << " (Press ESC to quit)";
  return stream.str();
}

// |Playground|
bool PlaygroundTest::ShouldKeepRendering() const {
  if (!switches_.timeout.has_value()) {
    return true;
  }

  if (SecondsF{GetSecondsElapsed()} > switches_.timeout.value()) {
    return false;
  }

  return true;
}

}  // namespace impeller
