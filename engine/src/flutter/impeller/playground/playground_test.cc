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

std::shared_ptr<RuntimeStage> PlaygroundTest::OpenAssetAsRuntimeStage(
    const char* asset_name) const {
  auto fixture = flutter::testing::OpenFixtureAsMapping(asset_name);
  if (!fixture || fixture->GetSize() == 0) {
    return nullptr;
  }
  auto stage = std::make_unique<RuntimeStage>(std::move(fixture));
  if (!stage->IsValid()) {
    return nullptr;
  }
  return stage;
}

static std::string FormatWindowTitle(const std::string& test_name) {
  std::stringstream stream;
  stream << "Impeller Playground for '" << test_name << "' (Press ESC to quit)";
  return stream.str();
}

// |Playground|
std::string PlaygroundTest::GetWindowTitle() const {
  return FormatWindowTitle(flutter::testing::GetCurrentTestName());
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
