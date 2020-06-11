// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidExternalViewEmbedder, GetCurrentCanvases) {
  auto embedder = new AndroidExternalViewEmbedder(nullptr);

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
  auto embedder = new AndroidExternalViewEmbedder(nullptr);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  ASSERT_TRUE(embedder->CompositeEmbeddedView(0) != nullptr);

  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());
  ASSERT_TRUE(embedder->CompositeEmbeddedView(1) != nullptr);
}

TEST(AndroidExternalViewEmbedder, CancelFrame) {
  auto embedder = new AndroidExternalViewEmbedder(nullptr);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->CancelFrame();

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(0UL, canvases.size());
}

TEST(AndroidExternalViewEmbedder, RasterizerRunsOnPlatformThread) {
  auto embedder = new AndroidExternalViewEmbedder(nullptr);
  auto platform_thread = new fml::Thread("platform");
  auto rasterizer_thread = new fml::Thread("rasterizer");
  auto platform_queue_id = platform_thread->GetTaskRunner()->GetTaskQueueId();
  auto rasterizer_queue_id =
      rasterizer_thread->GetTaskRunner()->GetTaskQueueId();

  auto raster_thread_merger = fml::MakeRefCounted<fml::RasterThreadMerger>(
      platform_queue_id, rasterizer_queue_id);
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0);
  // Push a platform view.
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());

  auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kResubmitFrame, postpreroll_result);
  ASSERT_TRUE(embedder->SubmitFrame(nullptr, nullptr));

  embedder->EndFrame(raster_thread_merger);
  ASSERT_TRUE(raster_thread_merger->IsMerged());

  int pending_frames = 0;
  while (raster_thread_merger->IsMerged()) {
    raster_thread_merger->DecrementLease();
    pending_frames++;
  }
  ASSERT_EQ(10, pending_frames);  // kDefaultMergedLeaseDuration
}

TEST(AndroidExternalViewEmbedder, RasterizerRunsOnRasterizerThread) {
  auto embedder = new AndroidExternalViewEmbedder(nullptr);
  auto platform_thread = new fml::Thread("platform");
  auto rasterizer_thread = new fml::Thread("rasterizer");
  auto platform_queue_id = platform_thread->GetTaskRunner()->GetTaskQueueId();
  auto rasterizer_queue_id =
      rasterizer_thread->GetTaskRunner()->GetTaskQueueId();

  auto raster_thread_merger = fml::MakeRefCounted<fml::RasterThreadMerger>(
      platform_queue_id, rasterizer_queue_id);
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  PostPrerollResult result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kSuccess, result);

  embedder->EndFrame(raster_thread_merger);
  ASSERT_FALSE(raster_thread_merger->IsMerged());
}

}  // namespace testing
}  // namespace flutter
