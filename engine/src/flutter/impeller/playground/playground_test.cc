// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_test.h"

#ifndef FML_OS_WIN
#include <wordexp.h>
#endif

#include "flutter/fml/file.h"
#include "flutter/fml/time/time_point.h"
#include "impeller/base/timing.h"
#include "impeller/base/validation.h"
#include "impeller/playground/playground_impl.h"
#include "impeller/testing/golden_digest_manager.h"

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

  SetEnableWriteGolden(IsGoldenTestSuite());
}

void PlaygroundTest::TearDown() {
  Playground::TearDownContextData();
}

namespace {

class PlaygroundTestEnvironment : public ::testing::Environment {
 public:
  static std::optional<std::string> ValidateGoldenDirectory(
      const std::string& dir) {
#ifdef FML_OS_WIN
    return dir;
#else   // FML_OS_WIN
    wordexp_t wordexp_result;
    int code = wordexp(dir.c_str(), &wordexp_result, 0);
    FML_CHECK(code == 0) << "Could not parse golden output directory: " << dir;
    FML_CHECK(wordexp_result.we_wordc == 1u)
        << "Exactly one directory must be specified for Golden image output: "
        << dir;
    std::optional<std::string> working_dir = wordexp_result.we_wordv[0];
    wordfree(&wordexp_result);

    FML_CHECK(working_dir) << "Unrecognized golden output directory: " << dir;
    fml::UniqueFD directory = fml::OpenDirectory(
        working_dir->c_str(), false, fml::FilePermission::kReadWrite);
    FML_CHECK(fml::IsDirectory(directory))
        << "Golden output directory must be a directory with read/write"
        << " permissions: " << dir;
    return working_dir;
#endif  // FML_OS_WIN
  }

  void SetUp() override {
    const fml::CommandLine& args = ::flutter::testing::GetArgsForProcess();
    std::string golden_output_dir;
    if (args.GetOptionValue("golden_output_dir", &golden_output_dir)) {
      const std::optional<std::string> validated_dir =
          ValidateGoldenDirectory(golden_output_dir);
      if (validated_dir) {
        golden_manager_.emplace(*validated_dir);
      } else {
        FML_CHECK(validated_dir)
            << "Did not recognize golden output directory: "
            << golden_output_dir;
      }
    }
  }

  void TearDown() override {
    if (golden_manager_) {
      if (::testing::UnitTest::GetInstance()->Passed()) {
        golden_manager_->Write();
      } else {
        FML_LOG(ERROR)
            << ::testing::UnitTest::GetInstance()->failed_test_count()
            << " tests failed, golden digest will not be written";
        golden_manager_->ClearDigestData();
      }
      golden_manager_.reset();
    }
    PlaygroundImpl::OnTearDownTestEnvironment();
    Playground::OnTearDownTestEnvironment();
  }

  static testing::GoldenDigestManager* GetGoldenDigestManager() {
    return golden_manager_ ? &golden_manager_.value() : nullptr;
  }

 private:
  static std::optional<testing::GoldenDigestManager> golden_manager_;
};

std::optional<testing::GoldenDigestManager>
    PlaygroundTestEnvironment::golden_manager_;

}  // namespace

// Change these declarations to #defines to enable swiftshader or metal
// validation.
#undef APPLY_METAL_VALIDATION
#undef ENABLE_VK_SWIFTSHADER

void PlaygroundTest::SetupTestEnvironment() {
#ifdef ENABLE_VK_SWIFTSHADER
  // Make sure environment is set up for VK swiftshader
  std::filesystem::path testing_assets_path =
      flutter::testing::GetTestingAssetsPath();
  std::filesystem::path target_path = testing_assets_path.parent_path()
                                          .parent_path()
                                          .parent_path()
                                          .parent_path();
  std::filesystem::path icd_path = target_path / "vk_swiftshader_icd.json";
  setenv("VK_ICD_FILENAMES", icd_path.c_str(), 1);
#endif

#ifdef APPLY_METAL_VALIDATION
  // https://developer.apple.com/documentation/metal/diagnosing_metal_programming_issues_early?language=objc
  // Enables all shader validation tests.
  setenv("MTL_SHADER_VALIDATION", "1", true);
  // Validates accesses to device and constant memory.
  setenv("MTL_SHADER_VALIDATION_GLOBAL_MEMORY", "1", true);
  // Validates accesses to threadgroup memory.
  setenv("MTL_SHADER_VALIDATION_THREADGROUP_MEMORY", "1", true);
  // Validates that texture references are not nil.
  setenv("MTL_SHADER_VALIDATION_TEXTURE_USAGE", "1", true);
  // Enables metal validation.
  setenv("METAL_DEBUG_ERROR_MODE", "0", true);
  // Enables metal validation.
  setenv("METAL_DEVICE_WRAPPER_TYPE", "1", true);
#endif

  ::testing::AddGlobalTestEnvironment(new PlaygroundTestEnvironment());
}

impeller::testing::GoldenDigestManager* PlaygroundTest::GetGoldenDigestManager()
    const {
  return PlaygroundTestEnvironment::GetGoldenDigestManager();
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
