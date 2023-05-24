// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/testing/test_args.h"
#include "flutter/testing/testing.h"
#include "impeller/geometry/scalar.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/switches.h"

#if FML_OS_MACOSX
#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#endif

namespace impeller {

class PlaygroundTest : public Playground,
                       public ::testing::TestWithParam<PlaygroundBackend> {
 public:
  PlaygroundTest();

  virtual ~PlaygroundTest();

  void SetUp() override;

  void TearDown() override;

  PlaygroundBackend GetBackend() const;

  // |Playground|
  std::unique_ptr<fml::Mapping> OpenAssetAsMapping(
      std::string asset_name) const override;

  std::shared_ptr<RuntimeStage> OpenAssetAsRuntimeStage(
      const char* asset_name) const;

  // |Playground|
  std::string GetWindowTitle() const override;

 private:
  // |Playground|
  bool ShouldKeepRendering() const;

#if FML_OS_MACOSX
  fml::ScopedNSAutoreleasePool autorelease_pool_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(PlaygroundTest);
};

#define INSTANTIATE_PLAYGROUND_SUITE(playground)                            \
  INSTANTIATE_TEST_SUITE_P(                                                 \
      Play, playground,                                                     \
      ::testing::Values(PlaygroundBackend::kMetal,                          \
                        PlaygroundBackend::kOpenGLES,                       \
                        PlaygroundBackend::kVulkan),                        \
      [](const ::testing::TestParamInfo<PlaygroundTest::ParamType>& info) { \
        return PlaygroundBackendToString(info.param);                       \
      });

}  // namespace impeller
