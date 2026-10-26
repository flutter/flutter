// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>

#include "flutter/common/task_runners.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_view_embedder.h"
#include "flutter/shell/platform/embedder/embedder_layers.h"
#include "flutter/shell/platform/embedder/embedder_render_target_skia.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPixmap.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

namespace {

// Standard test frame dimensions in physical pixels.
constexpr int32_t kTestFrameWidth = 100;
constexpr int32_t kTestFrameHeight = 100;
constexpr double kTestDevicePixelRatio = 1.0;
constexpr int64_t kImplicitFlutterViewId = 0;
constexpr int64_t kFirstPlatformViewId = 1;
constexpr int64_t kSecondPlatformViewId = 2;
constexpr uint64_t kZeroPresentationTime = 0;

std::unique_ptr<EmbedderRenderTarget> CreateSoftwareRenderTarget(
    const FlutterBackingStoreConfig& config,
    sk_sp<SkSurface>* out_surface = nullptr) {
  const SkImageInfo image_info =
      SkImageInfo::MakeN32Premul(static_cast<int>(config.size.width),
                                 static_cast<int>(config.size.height));
  sk_sp<SkSurface> surface = SkSurfaces::Raster(image_info);
  if (out_surface != nullptr) {
    *out_surface = surface;
  }

  FlutterBackingStore backing_store = {};
  backing_store.struct_size = sizeof(FlutterBackingStore);
  backing_store.type = kFlutterBackingStoreTypeSoftware;

  return std::make_unique<EmbedderRenderTargetSkia>(
      backing_store, std::move(surface), []() {}, nullptr, nullptr);
}

}  // namespace

TEST(EmbedderCompositorUnitTest, IsRootLayerIsStrictlyTopological) {
  std::vector<FlutterBackingStoreConfig> recorded_configs;
  auto create_target = [&](GrDirectContext* context,
                           const std::shared_ptr<impeller::AiksContext>& aiks,
                           const FlutterBackingStoreConfig& config) {
    recorded_configs.push_back(config);
    return CreateSoftwareRenderTarget(config);
  };

  auto present = [](FlutterViewId view_id,
                    const std::vector<const FlutterLayer*>& layers) {
    return true;
  };

  // Test with avoid_backing_store_cache = false to verify topological
  // is_root_layer is independent of avoid_backing_store_cache.
  EmbedderExternalViewEmbedder embedder(/*avoid_backing_store_cache=*/false,
                                        create_target, present);

  const DlISize frame_size(kTestFrameWidth, kTestFrameHeight);

  // Case 1: Root layer + Platform view + Overlay layer.
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);
  DlCanvas* root_canvas = embedder.GetRootCanvas();
  ASSERT_NE(root_canvas, nullptr);
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  root_canvas->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight), paint);

  auto pv_params = std::make_unique<EmbeddedViewParams>(
      DlMatrix(), DlSize(50.0f, 50.0f), MutatorsStack());
  embedder.PrerollCompositeEmbeddedView(kFirstPlatformViewId,
                                        std::move(pv_params));
  DlCanvas* overlay_canvas =
      embedder.CompositeEmbeddedView(kFirstPlatformViewId);
  ASSERT_NE(overlay_canvas, nullptr);
  overlay_canvas->DrawRect(DlRect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f), paint);

  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);

  constexpr size_t kExpectedRootAndOverlayCount = 2;
  ASSERT_EQ(recorded_configs.size(), kExpectedRootAndOverlayCount);
  EXPECT_TRUE(recorded_configs[0].is_root_layer);
  EXPECT_FALSE(recorded_configs[1].is_root_layer);

  // Case 2: Platform view at the bottom (empty root slice) + Overlay above it.
  // Because a platform view lies beneath the only rendered Flutter slice, that
  // slice is an overlay (is_root_layer == false).
  recorded_configs.clear();
  embedder.CollectView(kImplicitFlutterViewId);
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);

  auto bottom_pv_params = std::make_unique<EmbeddedViewParams>(
      DlMatrix(), DlSize(50.0f, 50.0f), MutatorsStack());
  embedder.PrerollCompositeEmbeddedView(kFirstPlatformViewId,
                                        std::move(bottom_pv_params));
  DlCanvas* top_canvas = embedder.CompositeEmbeddedView(kFirstPlatformViewId);
  ASSERT_NE(top_canvas, nullptr);
  top_canvas->DrawRect(DlRect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f), paint);

  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);

  constexpr size_t kExpectedOverlayOnlyCount = 1;
  ASSERT_EQ(recorded_configs.size(), kExpectedOverlayOnlyCount);
  EXPECT_FALSE(recorded_configs[0].is_root_layer);
}

TEST(EmbedderCompositorUnitTest,
     DynamicThreadMergingThreeStepTransitionSequence) {
  size_t backing_store_creations = 0;
  std::vector<std::vector<FlutterLayerContentType>> presented_layer_types;

  auto create_target = [&](GrDirectContext* context,
                           const std::shared_ptr<impeller::AiksContext>& aiks,
                           const FlutterBackingStoreConfig& config) {
    ++backing_store_creations;
    return CreateSoftwareRenderTarget(config);
  };

  auto present = [&](FlutterViewId view_id,
                     const std::vector<const FlutterLayer*>& layers) {
    std::vector<FlutterLayerContentType> types;
    types.reserve(layers.size());
    for (const FlutterLayer* layer : layers) {
      types.push_back(layer->type);
    }
    presented_layer_types.push_back(std::move(types));
    return true;
  };

  EmbedderExternalViewEmbedder embedder(
      /*avoid_backing_store_cache=*/true, create_target, present,
      /*merge_raster_thread_on_platform_views=*/true);
  EXPECT_TRUE(embedder.SupportsDynamicThreadMerging());

  fml::Thread platform_thread("test_platform_thread");
  fml::Thread raster_thread("test_raster_thread");
  fml::TaskQueueId platform_queue_id =
      platform_thread.GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId raster_queue_id =
      raster_thread.GetTaskRunner()->GetTaskQueueId();

  auto merger = fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                             raster_queue_id);
  EXPECT_FALSE(merger->IsMerged());

  const DlISize frame_size(kTestFrameWidth, kTestFrameHeight);
  DlPaint paint;
  paint.setColor(DlColor::kRed());

  // Frame 0: No platform views -> PostPrerollAction returns kSuccess and leaves
  // threads unmerged.
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);
  embedder.GetRootCanvas()->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight), paint);
  EXPECT_EQ(embedder.PostPrerollAction(merger), PostPrerollResult::kSuccess);
  EXPECT_FALSE(merger->IsMerged());
  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);
  ASSERT_EQ(presented_layer_types.size(), 1u);
  EXPECT_EQ(backing_store_creations, 1u);

  // Frame 1, Pass 1 (unmerged, 0 -> 1 platform view):
  // PostPrerollAction cancels the frame, merges threads with a lease, and
  // returns kSkipAndRetryFrame.
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);
  embedder.GetRootCanvas()->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight), paint);
  embedder.PrerollCompositeEmbeddedView(
      kFirstPlatformViewId,
      std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(50.0f, 50.0f),
                                           MutatorsStack()));
  EXPECT_EQ(embedder.PostPrerollAction(merger),
            PostPrerollResult::kSkipAndRetryFrame);
  EXPECT_TRUE(merger->IsMerged());

  // Frame 1, Pass 2 (first merged pass on 0 -> 1 platform-view transition):
  // PostPrerollAction returns kResubmitFrame, and SubmitFlutterView presents
  // ONLY the platform-view layer without allocating backing stores.
  backing_store_creations = 0;
  presented_layer_types.clear();
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);
  embedder.GetRootCanvas()->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight), paint);
  embedder.PrerollCompositeEmbeddedView(
      kFirstPlatformViewId,
      std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(50.0f, 50.0f),
                                           MutatorsStack()));
  embedder.CompositeEmbeddedView(kFirstPlatformViewId)
      ->DrawRect(DlRect::MakeXYWH(10.0f, 10.0f, 20.0f, 20.0f), paint);

  EXPECT_EQ(embedder.PostPrerollAction(merger),
            PostPrerollResult::kResubmitFrame);
  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);

  EXPECT_EQ(backing_store_creations, 0u);
  ASSERT_EQ(presented_layer_types.size(), 1u);
  ASSERT_EQ(presented_layer_types[0].size(), 1u);
  EXPECT_EQ(presented_layer_types[0][0], kFlutterLayerContentTypePlatformView);

  // Frame 1, Pass 3 (resubmitted merged pass):
  // PostPrerollAction returns kSuccess, and SubmitFlutterView allocates backing
  // stores and presents all layers (Root BackingStore, PlatformView, Overlay
  // BackingStore).
  presented_layer_types.clear();
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);
  embedder.GetRootCanvas()->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight), paint);
  embedder.PrerollCompositeEmbeddedView(
      kFirstPlatformViewId,
      std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(50.0f, 50.0f),
                                           MutatorsStack()));
  embedder.CompositeEmbeddedView(kFirstPlatformViewId)
      ->DrawRect(DlRect::MakeXYWH(10.0f, 10.0f, 20.0f, 20.0f), paint);

  EXPECT_EQ(embedder.PostPrerollAction(merger), PostPrerollResult::kSuccess);
  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);

  constexpr size_t kExpectedRootAndOverlayStores = 2;
  EXPECT_EQ(backing_store_creations, kExpectedRootAndOverlayStores);
  ASSERT_EQ(presented_layer_types.size(), 1u);
  constexpr size_t kExpectedTotalLayers = 3;
  ASSERT_EQ(presented_layer_types[0].size(), kExpectedTotalLayers);
  EXPECT_EQ(presented_layer_types[0][0], kFlutterLayerContentTypeBackingStore);
  EXPECT_EQ(presented_layer_types[0][1], kFlutterLayerContentTypePlatformView);
  EXPECT_EQ(presented_layer_types[0][2], kFlutterLayerContentTypeBackingStore);

  // Expire the 10-frame merge lease before fml::Thread destructors run so that
  // each thread's termination task executes on its own message loop.
  constexpr size_t kExpectedLeaseFrames = 10;
  for (size_t i = 0; i < kExpectedLeaseFrames; ++i) {
    EXPECT_TRUE(merger->IsMerged());
    merger->DecrementLease();
  }
  EXPECT_FALSE(merger->IsMerged());
}

TEST(EmbedderCompositorUnitTest,
     CoalesceOverlayLayersAppliesDifferenceClipsForHigherZPlatformViews) {
  std::vector<FlutterBackingStoreConfig> configs;
  std::vector<sk_sp<SkSurface>> surfaces;
  std::vector<FlutterLayerContentType> layer_types;

  auto create_target = [&](GrDirectContext* context,
                           const std::shared_ptr<impeller::AiksContext>& aiks,
                           const FlutterBackingStoreConfig& config) {
    configs.push_back(config);
    sk_sp<SkSurface> surface;
    auto target = CreateSoftwareRenderTarget(config, &surface);
    surfaces.push_back(std::move(surface));
    return target;
  };

  auto present = [&](FlutterViewId view_id,
                     const std::vector<const FlutterLayer*>& layers) {
    for (const FlutterLayer* layer : layers) {
      layer_types.push_back(layer->type);
    }
    return true;
  };

  EmbedderExternalViewEmbedder embedder(
      /*avoid_backing_store_cache=*/true, create_target, present,
      /*merge_raster_thread_on_platform_views=*/false,
      /*coalesce_overlay_layers=*/true);

  const DlISize frame_size(kTestFrameWidth, kTestFrameHeight);
  embedder.PrepareFlutterView(frame_size, kTestDevicePixelRatio);

  // Root slice: fill entire frame with red.
  DlPaint red_paint;
  red_paint.setColor(DlColor::kRed());
  embedder.GetRootCanvas()->DrawRect(
      DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight),
      red_paint);

  // Platform view 1 at [10, 10, 40, 40] (size 30x30).
  MutatorsStack stack1;
  stack1.PushTransform(DlMatrix::MakeTranslation({10.0f, 10.0f}));
  auto pv1_params = std::make_unique<EmbeddedViewParams>(
      DlMatrix::MakeTranslation({10.0f, 10.0f}), DlSize(30.0f, 30.0f), stack1);
  embedder.PrerollCompositeEmbeddedView(kFirstPlatformViewId,
                                        std::move(pv1_params));

  // Overlay slice 1 (above PV 1, below PV 2): draw blue across the entire
  // 100x100 frame. When coalesced into the top-most overlay layer, PV 2's
  // bounds [50, 50, 80, 80] must be clipped out with DlClipOp::kDifference.
  DlPaint blue_paint;
  blue_paint.setColor(DlColor::kBlue());
  embedder.CompositeEmbeddedView(kFirstPlatformViewId)
      ->DrawRect(
          DlRect::MakeXYWH(0.0f, 0.0f, kTestFrameWidth, kTestFrameHeight),
          blue_paint);

  // Platform view 2 at [50, 50, 80, 80] (size 30x30).
  MutatorsStack stack2;
  stack2.PushTransform(DlMatrix::MakeTranslation({50.0f, 50.0f}));
  auto pv2_params = std::make_unique<EmbeddedViewParams>(
      DlMatrix::MakeTranslation({50.0f, 50.0f}), DlSize(30.0f, 30.0f), stack2);
  embedder.PrerollCompositeEmbeddedView(kSecondPlatformViewId,
                                        std::move(pv2_params));

  // Overlay slice 2 (above PV 2): draw green at [60, 60, 90, 90] (size 30x30).
  // Because this slice is above PV 2 in Z-order, it must NOT be clipped by
  // PV 2.
  DlPaint green_paint;
  green_paint.setColor(DlColor::kGreen());
  embedder.CompositeEmbeddedView(kSecondPlatformViewId)
      ->DrawRect(DlRect::MakeXYWH(60.0f, 60.0f, 30.0f, 30.0f), green_paint);

  embedder.SubmitFlutterView(kImplicitFlutterViewId, nullptr, nullptr, nullptr);

  // Only 2 backing stores should be created: 1 root + 1 coalesced overlay.
  constexpr size_t kExpectedCoalescedBackingStoreCount = 2;
  ASSERT_EQ(configs.size(), kExpectedCoalescedBackingStoreCount);
  EXPECT_TRUE(configs[0].is_root_layer);
  EXPECT_FALSE(configs[1].is_root_layer);

  // Presented layers: [Root BackingStore, PV 1, PV 2, Coalesced Overlay].
  constexpr size_t kExpectedPresentedLayers = 4;
  ASSERT_EQ(layer_types.size(), kExpectedPresentedLayers);
  EXPECT_EQ(layer_types[0], kFlutterLayerContentTypeBackingStore);
  EXPECT_EQ(layer_types[1], kFlutterLayerContentTypePlatformView);
  EXPECT_EQ(layer_types[2], kFlutterLayerContentTypePlatformView);
  EXPECT_EQ(layer_types[3], kFlutterLayerContentTypeBackingStore);

  // Inspect pixels of the coalesced overlay surface (surfaces[1]).
  ASSERT_EQ(surfaces.size(), kExpectedCoalescedBackingStoreCount);
  SkPixmap overlay_pixmap;
  ASSERT_TRUE(surfaces[1]->peekPixels(&overlay_pixmap));

  // Sample (20, 20) inside PV 1 [10..40, 10..40]: Overlay 1 is above PV 1, so
  // it remains blue.
  constexpr int kSampleInsidePv1X = 20;
  constexpr int kSampleInsidePv1Y = 20;
  EXPECT_EQ(overlay_pixmap.getColor(kSampleInsidePv1X, kSampleInsidePv1Y),
            SK_ColorBLUE);

  // Sample (55, 55) inside PV 2 [50..80, 50..80] but outside Overlay 2
  // [60..90, 60..90]: Overlay 1 had PV 2's rect clipped out with
  // DlClipOp::kDifference, so this pixel must be transparent.
  constexpr int kSampleInsidePv2HoleX = 55;
  constexpr int kSampleInsidePv2HoleY = 55;
  EXPECT_EQ(
      overlay_pixmap.getColor(kSampleInsidePv2HoleX, kSampleInsidePv2HoleY),
      SK_ColorTRANSPARENT);

  // Sample (70, 70) inside both PV 2 [50..80, 50..80] and Overlay 2
  // [60..90, 60..90]: Overlay 2 is above PV 2, so it paints green over PV 2.
  constexpr int kSampleInsideOverlay2X = 70;
  constexpr int kSampleInsideOverlay2Y = 70;
  EXPECT_EQ(
      overlay_pixmap.getColor(kSampleInsideOverlay2X, kSampleInsideOverlay2Y),
      SK_ColorGREEN);
}

TEST(EmbedderCompositorUnitTest,
     SerializeFlutterPathMutatorWithAndWithoutConicsCapability) {
  const DlISize frame_size(kTestFrameWidth, kTestFrameHeight);

  // Build a path containing MoveTo, LineTo, ConicTo, CubicTo, and Close with
  // EvenOdd fill type.
  DlPathBuilder path_builder;
  path_builder.SetFillType(DlPathFillType::kOdd);
  path_builder.MoveTo(DlPoint(10.0f, 10.0f));
  path_builder.LineTo(DlPoint(50.0f, 10.0f));
  constexpr DlScalar kTestConicWeight = 0.70710678f;
  path_builder.ConicCurveTo(DlPoint(50.0f, 50.0f), DlPoint(10.0f, 50.0f),
                            kTestConicWeight);
  path_builder.CubicCurveTo(DlPoint(5.0f, 40.0f), DlPoint(5.0f, 20.0f),
                            DlPoint(10.0f, 10.0f));
  path_builder.Close();
  const DlPath test_path = path_builder.TakePath();

  MutatorsStack stack;
  stack.PushClipPath(test_path);
  EmbeddedViewParams params(DlMatrix(), DlSize(50.0f, 50.0f), stack);

  // 1. Without kFlutterPlatformViewMutationCapabilityPathConics (capabilities =
  // 0): Conics must be approximated with quadratic curves (no
  // kFlutterPathVerbConic).
  {
    EmbedderLayers layers(frame_size, kTestDevicePixelRatio, DlMatrix(),
                          kZeroPresentationTime,
                          /*platform_view_mutation_capabilities=*/0);
    layers.PushPlatformViewLayer(kFirstPlatformViewId, params);

    bool callback_invoked = false;
    layers.InvokePresentCallback(
        kImplicitFlutterViewId,
        [&](FlutterViewId view_id,
            const std::vector<const FlutterLayer*>& presented) {
          callback_invoked = true;
          EXPECT_EQ(view_id, kImplicitFlutterViewId);
          if (presented.size() != 1u) {
            ADD_FAILURE() << "Expected 1 layer";
            return false;
          }
          const FlutterPlatformView* pv = presented[0]->platform_view;
          if (pv == nullptr || pv->mutations_count != 1u) {
            ADD_FAILURE() << "Expected 1 platform view mutation";
            return false;
          }
          const FlutterPlatformViewMutation* mutation = pv->mutations[0];
          EXPECT_EQ(mutation->type, kFlutterPlatformViewMutationTypeClipPath);
          const FlutterPath& clip_path = mutation->clip_path;
          EXPECT_EQ(clip_path.struct_size, sizeof(FlutterPath));
          EXPECT_EQ(clip_path.fill_type, kFlutterPathFillTypeEvenOdd);
          EXPECT_EQ(clip_path.conic_weights_count, 0u);
          EXPECT_EQ(clip_path.conic_weights, nullptr);
          EXPECT_GT(clip_path.verbs_count, 0u);
          EXPECT_NE(clip_path.verbs, nullptr);
          EXPECT_GT(clip_path.points_count, 0u);
          EXPECT_NE(clip_path.points, nullptr);

          bool has_conic_verb = false;
          bool has_quad_verb = false;
          for (size_t i = 0; i < clip_path.verbs_count; ++i) {
            if (clip_path.verbs[i] == kFlutterPathVerbConic) {
              has_conic_verb = true;
            }
            if (clip_path.verbs[i] == kFlutterPathVerbQuad) {
              has_quad_verb = true;
            }
          }
          EXPECT_FALSE(has_conic_verb);
          EXPECT_TRUE(has_quad_verb);
          return true;
        });
    EXPECT_TRUE(callback_invoked);
  }

  // 2. With kFlutterPlatformViewMutationCapabilityPathConics:
  // Conics must be preserved as kFlutterPathVerbConic with conic_weights
  // populated.
  {
    EmbedderLayers layers(frame_size, kTestDevicePixelRatio, DlMatrix(),
                          kZeroPresentationTime,
                          kFlutterPlatformViewMutationCapabilityPathConics);
    layers.PushPlatformViewLayer(kFirstPlatformViewId, params);

    bool callback_invoked = false;
    layers.InvokePresentCallback(
        kImplicitFlutterViewId,
        [&](FlutterViewId view_id,
            const std::vector<const FlutterLayer*>& presented) {
          callback_invoked = true;
          if (presented.size() != 1u) {
            ADD_FAILURE() << "Expected 1 layer";
            return false;
          }
          const FlutterPlatformView* pv = presented[0]->platform_view;
          if (pv == nullptr || pv->mutations_count != 1u) {
            ADD_FAILURE() << "Expected 1 platform view mutation";
            return false;
          }
          const FlutterPlatformViewMutation* mutation = pv->mutations[0];
          EXPECT_EQ(mutation->type, kFlutterPlatformViewMutationTypeClipPath);
          const FlutterPath& clip_path = mutation->clip_path;
          EXPECT_EQ(clip_path.struct_size, sizeof(FlutterPath));
          EXPECT_EQ(clip_path.fill_type, kFlutterPathFillTypeEvenOdd);

          // Expected verbs: Move, Line, Conic, Cubic, Close (5 verbs).
          constexpr size_t kExpectedVerbCountWithConic = 5;
          EXPECT_EQ(clip_path.verbs_count, kExpectedVerbCountWithConic);
          if (clip_path.verbs_count != kExpectedVerbCountWithConic) {
            return false;
          }
          EXPECT_EQ(clip_path.verbs[0], kFlutterPathVerbMove);
          EXPECT_EQ(clip_path.verbs[1], kFlutterPathVerbLine);
          EXPECT_EQ(clip_path.verbs[2], kFlutterPathVerbConic);
          EXPECT_EQ(clip_path.verbs[3], kFlutterPathVerbCubic);
          EXPECT_EQ(clip_path.verbs[4], kFlutterPathVerbClose);

          // Expected points: Move(1) + Line(1) + Conic(2) + Cubic(3) = 7.
          constexpr size_t kExpectedPointCountWithConic = 7;
          EXPECT_EQ(clip_path.points_count, kExpectedPointCountWithConic);
          EXPECT_EQ(clip_path.conic_weights_count, 1u);
          EXPECT_NE(clip_path.conic_weights, nullptr);
          if (clip_path.conic_weights_count != 1u ||
              clip_path.conic_weights == nullptr) {
            return false;
          }
          EXPECT_NEAR(clip_path.conic_weights[0],
                      static_cast<double>(kTestConicWeight), 1e-5);
          return true;
        });
    EXPECT_TRUE(callback_invoked);
  }
}

}  // namespace testing
}  // namespace flutter
