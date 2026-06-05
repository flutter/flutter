// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"

#include "impeller/base/timing.h"
#include "impeller/base/validation.h"
#include "impeller/playground/playground_test.h"

namespace impeller {

PlaygroundTest::PlaygroundTest()
    : Playground(GetParam(),
                 PlaygroundSwitches{flutter::testing::GetArgsForProcess()}) {
  ImpellerValidationErrorsSetCallback(
      [](const char* message, const char* file, int line) -> bool {
        // GTEST_MESSAGE_AT_ can only be used in a function that returns void.
        // Hence the goofy lambda. The failure message and location will still
        // be correct however.
        //
        // https://google.github.io/googletest/advanced.html#assertion-placement
        [message, file, line]() -> void {
          GTEST_MESSAGE_AT_(file, line, "Impeller Validation Error",
                            ::testing::TestPartResult::kFatalFailure)
              << message;
        }();
        return true;
      });
}

PlaygroundTest::~PlaygroundTest() {
  ImpellerValidationErrorsSetCallback(nullptr);
}

void PlaygroundTest::SetUp() {
  if (!Playground::SupportsBackend(GetParam())) {
    GTEST_SKIP() << "Playground doesn't support this backend type.";
    return;
  }

  if (!Playground::ShouldOpenNewPlaygrounds()) {
    GTEST_SKIP() << "Skipping due to user action.";
    return;
  }
}

void PlaygroundTest::TearDown() {
  Playground::TearDownContextData();
}

bool PlaygroundTest::IsGoldenTestSuite() const {
  return false;
}

PlaygroundBackend PlaygroundTest::GetBackend() const {
  return GetParam();
}

// |Playground|
std::unique_ptr<fml::Mapping> PlaygroundTest::OpenAssetAsMapping(
    std::string asset_name) const {
  return flutter::testing::OpenFixtureAsMapping(asset_name);
}

absl::StatusOr<RuntimeStage::Map> PlaygroundTest::OpenAssetAsRuntimeStage(
    const char* asset_name) const {
  const std::shared_ptr<fml::Mapping> fixture =
      flutter::testing::OpenFixtureAsMapping(asset_name);
  if (!fixture || fixture->GetSize() == 0) {
    return absl::NotFoundError("Asset not found or empty.");
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
    case PlaygroundBackend::kMetalSDF:
      break;
    case PlaygroundBackend::kOpenGLES:
    case PlaygroundBackend::kOpenGLESSDF:
      if (GetSwitches().use_angle) {
        stream << " (Angle) ";
      }
      break;
    case PlaygroundBackend::kVulkan:
      if (GetSwitches().use_swiftshader) {
        stream << " (SwiftShader) ";
      }
      break;
  }
  stream << " (Press ESC to quit)";
  return stream.str();
}

// |Playground|
bool PlaygroundTest::ShouldKeepRendering() const {
  if (!GetSwitches().timeout.has_value()) {
    return true;
  }

  if (SecondsF{GetSecondsElapsed()} > GetSwitches().timeout.value()) {
    return false;
  }

  return true;
}

}  // namespace impeller
