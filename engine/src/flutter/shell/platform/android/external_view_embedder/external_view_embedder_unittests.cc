// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"

namespace flutter {
namespace testing {

TEST(AndroidExternalViewEmbedder, GetCurrentCanvases) {
  auto embedder = new AndroidExternalViewEmbedder();

  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(2UL, canvases.size());
  ASSERT_EQ(SkISize::Make(10, 20), canvases[0]->getBaseLayerSize());
  ASSERT_EQ(SkISize::Make(10, 20), canvases[1]->getBaseLayerSize());
}

TEST(AndroidExternalViewEmbedder, CompositeEmbeddedView) {
  auto embedder = new AndroidExternalViewEmbedder();

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  ASSERT_TRUE(embedder->CompositeEmbeddedView(0) != nullptr);

  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());
  ASSERT_TRUE(embedder->CompositeEmbeddedView(1) != nullptr);
}

TEST(AndroidExternalViewEmbedder, FinishFrame) {
  auto embedder = new AndroidExternalViewEmbedder();

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->FinishFrame();

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(0UL, canvases.size());
}

TEST(AndroidExternalViewEmbedder, CancelFrame) {
  auto embedder = new AndroidExternalViewEmbedder();

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->CancelFrame();

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(0UL, canvases.size());
}

}  // namespace testing
}  // namespace flutter
