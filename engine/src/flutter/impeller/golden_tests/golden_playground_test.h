// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/impeller/aiks/aiks_context.h"
#include "flutter/impeller/playground/playground.h"
#include "flutter/impeller/renderer/render_target.h"
#include "flutter/testing/testing.h"
#include "impeller/typographer/typographer_context.h"

#if FML_OS_MACOSX
#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#endif

namespace impeller {

class GoldenPlaygroundTest
    : public ::testing::TestWithParam<PlaygroundBackend> {
 public:
  using AiksPlaygroundCallback =
      std::function<std::optional<Picture>(AiksContext& renderer)>;

  GoldenPlaygroundTest();

  ~GoldenPlaygroundTest() override;

  void SetUp();

  void TearDown();

  PlaygroundBackend GetBackend() const;

  void SetTypographerContext(
      std::shared_ptr<TypographerContext> typographer_context);

  bool OpenPlaygroundHere(Picture picture);

  bool OpenPlaygroundHere(AiksPlaygroundCallback callback);

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name,
      bool enable_mipmapping = false) const;

  std::shared_ptr<RuntimeStage> OpenAssetAsRuntimeStage(
      const char* asset_name) const;

  std::shared_ptr<Context> GetContext() const;

  Point GetContentScale() const;

  Scalar GetSecondsElapsed() const;

  ISize GetWindowSize() const;

 private:
#if FML_OS_MACOSX
  // This must be placed first so that the autorelease pool is not destroyed
  // until the GoldenPlaygroundTestImpl has been destructed.
  fml::ScopedNSAutoreleasePool autorelease_pool_;
#endif

  std::shared_ptr<TypographerContext> typographer_context_;

  struct GoldenPlaygroundTestImpl;
  // This is only a shared_ptr so it can work with a forward declared type.
  std::shared_ptr<GoldenPlaygroundTestImpl> pimpl_;

  FML_DISALLOW_COPY_AND_ASSIGN(GoldenPlaygroundTest);
};

}  // namespace impeller
