// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"

#include "impeller/base/timing.h"
#include "impeller/base/validation.h"
#include "impeller/playground/playground_test.h"

#if IMPELLER_ENABLE_METAL
#include "impeller/playground/backend/metal/playground_impl_mtl.h"
#endif  // IMPELLER_ENABLE_METAL

namespace impeller {

PlaygroundTest::PlaygroundTest()
    : Playground(PlaygroundSwitches{flutter::testing::GetArgsForProcess()}) {
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

namespace {
bool DoesSupportWideGamutTests() {
#ifdef __arm64__
  return true;
#else
  return false;
#endif
}
}  // namespace

void PlaygroundTest::SetUp() {
  if (!Playground::SupportsBackend(GetParam())) {
    GTEST_SKIP() << "Playground doesn't support this backend type.";
    return;
  }

  if (!Playground::ShouldOpenNewPlaygrounds()) {
    GTEST_SKIP() << "Skipping due to user action.";
    return;
  }

  // Test names that contain "WideGamut/" will render with 10-bit wide gamut.
  // Test names that contain "WideGamutF16/" will render with 16-bit float wide
  // gamut.
  std::string test_name = flutter::testing::GetCurrentTestName();
  PlaygroundSwitches switches = switches_;
  switches.enable_wide_gamut_f16 =
      test_name.find("WideGamutF16/") != std::string::npos;
  switches.enable_wide_gamut =
      switches.enable_wide_gamut_f16 ||
      test_name.find("WideGamut/") != std::string::npos;

  if (switches.enable_wide_gamut && (GetParam() != PlaygroundBackend::kMetal ||
                                     !DoesSupportWideGamutTests())) {
    GTEST_SKIP() << "This backend doesn't yet support wide gamut.";
    return;
  }

  // 10-bit pixel formats (e.g., BGRA10_XR) require Apple3+ GPU.
  // Mac2 family only supports F16 wide gamut, not 10-bit formats.
  // Skip non-F16 wide gamut tests on devices that don't support 10-bit.
  //
  // Note: 10-bit wide gamut tests (WideGamut/) are only relevant for iOS,
  // because macOS engine always uses F16 for wide gamut. Whether these tests
  // can run depends on the testing environment (Apple Silicon with Apple3+).
  // See: https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
#if IMPELLER_ENABLE_METAL
  if (switches.enable_wide_gamut && !switches.enable_wide_gamut_f16 &&
      !PlaygroundImplMTL::DeviceSupports10BitFormats()) {
    GTEST_SKIP() << "Device doesn't support 10-bit formats. Use WideGamutF16 tests.";
    return;
  }
#endif  // IMPELLER_ENABLE_METAL

  switches.flags.antialiased_lines =
      test_name.find("ExperimentAntialiasLines/") != std::string::npos;

  SetupContext(GetParam(), switches);
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
