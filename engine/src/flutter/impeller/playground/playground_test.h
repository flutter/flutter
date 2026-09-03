// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_TEST_H_
#define FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_TEST_H_

#include <memory>

#include "flutter/testing/test_args.h"
#include "flutter/testing/testing.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/switches.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

#if FML_OS_MACOSX
#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#endif

namespace impeller {

class PlaygroundTest : public Playground,
                       public ::testing::TestWithParam<PlaygroundBackend> {
 public:
  PlaygroundTest();

  virtual ~PlaygroundTest();

  static void SetupTestEnvironment();

  void SetUp() override;

  void TearDown() override;

  PlaygroundBackend GetBackend() const;

  // |Playground|
  std::unique_ptr<fml::Mapping> OpenAssetAsMapping(
      std::string asset_name) const override;

  absl::StatusOr<RuntimeStage::Map> OpenAssetAsRuntimeStage(
      const char* asset_name) const;

  // |Playground|
  std::string GetWindowTitle() const override;

  testing::GoldenDigestManager* GetGoldenDigestManager() const override;

 protected:
  /// @brief This method is overridden on a test suite basis and establishes
  ///        whether a given set of tests is intended to generate goldens.
  ///
  /// The return value of this method is used to set the default value of
  /// |Playground::ShouldWriteGoldenImage|, but an individual test is still
  /// allowed to enable a golden image by calling |SetEnableWriteGolden|.
  ///
  /// @return false by default unless overridden in a subclass
  virtual bool IsGoldenTestSuite() const;

 private:
  // |Playground|
  bool ShouldKeepRendering() const override;

#if FML_OS_MACOSX
  fml::ScopedNSAutoreleasePool autorelease_pool_;
#endif

  PlaygroundTest(const PlaygroundTest&) = delete;

  PlaygroundTest& operator=(const PlaygroundTest&) = delete;
};

class PlaygroundTestWithGoldens : public PlaygroundTest {
 protected:
  bool IsGoldenTestSuite() const override { return true; }
};

#define INSTANTIATE_PLAYGROUND_SUITE(playground)                             \
  [[maybe_unused]] const char* kYouInstantiated##playground##MultipleTimes = \
      "";                                                                    \
  INSTANTIATE_TEST_SUITE_P(                                                  \
      Play, playground,                                                      \
      ::testing::Values(                                                     \
          PlaygroundBackend::kMetal, PlaygroundBackend::kMetalSDF,           \
          PlaygroundBackend::kOpenGLES, PlaygroundBackend::kOpenGLESSDF,     \
          PlaygroundBackend::kVulkan),                                       \
      [](const ::testing::TestParamInfo<PlaygroundTest::ParamType>& info) {  \
        return PlaygroundBackendToString(info.param);                        \
      });

#define INSTANTIATE_METAL_PLAYGROUND_SUITE(playground)                       \
  [[maybe_unused]] const char* kYouInstantiated##playground##MultipleTimes = \
      "";                                                                    \
  INSTANTIATE_TEST_SUITE_P(                                                  \
      Play, playground, ::testing::Values(PlaygroundBackend::kMetal),        \
      [](const ::testing::TestParamInfo<PlaygroundTest::ParamType>& info) {  \
        return PlaygroundBackendToString(info.param);                        \
      });

#define INSTANTIATE_VULKAN_PLAYGROUND_SUITE(playground)                      \
  [[maybe_unused]] const char* kYouInstantiated##playground##MultipleTimes = \
      "";                                                                    \
  INSTANTIATE_TEST_SUITE_P(                                                  \
      Play, playground, ::testing::Values(PlaygroundBackend::kVulkan),       \
      [](const ::testing::TestParamInfo<PlaygroundTest::ParamType>& info) {  \
        return PlaygroundBackendToString(info.param);                        \
      });

#define INSTANTIATE_OPENGLES_PLAYGROUND_SUITE(playground)                    \
  [[maybe_unused]] const char* kYouInstantiated##playground##MultipleTimes = \
      "";                                                                    \
  INSTANTIATE_TEST_SUITE_P(                                                  \
      Play, playground, ::testing::Values(PlaygroundBackend::kOpenGLES),     \
      [](const ::testing::TestParamInfo<PlaygroundTest::ParamType>& info) {  \
        return PlaygroundBackendToString(info.param);                        \
      });

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_TEST_H_
