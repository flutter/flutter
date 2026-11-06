// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_platform_views_controller.h"

#include <atomic>
#include <chrono>
#include <cstddef>
#include <memory>
#include <thread>
#include <vector>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

/// Android API 33 (Tiramisu), before `Path.conicTo` was added in API 34.
constexpr int32_t kTestAndroidApiLevel33 = 33;

/// Android API 34 (UpsideDownCake), which introduced `Path.conicTo`.
constexpr int32_t kTestAndroidApiLevel34 = 34;

/// Primary view ID (0) and secondary view ID (1) for multi-view tests.
constexpr FlutterViewId kPrimaryViewId = 0;
constexpr FlutterViewId kSecondaryViewId = 1;

/// Standard full-HD test dimensions (1080x1920) for root onscreen backing
/// stores.
constexpr double kOnscreenWidth = 1080.0;
constexpr double kOnscreenHeight = 1920.0;

/// Overlay backing store dimensions (500x400).
constexpr double kOverlayWidth = 500.0;
constexpr double kOverlayHeight = 400.0;

/// Platform view test dimensions (300x200) and offsets (50, 60).
constexpr double kPlatformViewOffsetX = 50.0;
constexpr double kPlatformViewOffsetY = 60.0;
constexpr double kPlatformViewWidth = 300.0;
constexpr double kPlatformViewHeight = 200.0;

/// Unregistered Java-managed platform view IDs used to verify that
/// `OnDisplayPlatformView` does not require prior C-API registration.
constexpr int64_t kUnregisteredJavaPlatformViewId1 = 701;
constexpr int64_t kUnregisteredJavaPlatformViewId2 = 702;

/// Sample opacity mutation value (0.8 = 80% opaque).
constexpr double kSampleOpacity = 0.8;

/// Sample conic weight (0.70710678) for SoA `FlutterPath` mutation testing.
constexpr double kSampleConicWeight = 0.70710678;

}  // namespace

TEST(AndroidPlatformViewsControllerTest,
     ConfiguresFlutterCompositorForHybridCompositionAndSurfaceControl) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);

  FlutterCompositor hc_compositor = {};
  controller.ConfigureFlutterCompositor(&hc_compositor,
                                        /*enable_surface_control=*/false,
                                        kTestAndroidApiLevel33);
  EXPECT_EQ(hc_compositor.struct_size, sizeof(FlutterCompositor));
  EXPECT_EQ(hc_compositor.user_data, &controller);
  EXPECT_TRUE(hc_compositor.avoid_backing_store_cache);
  EXPECT_TRUE(hc_compositor.merge_raster_thread_on_platform_views);
  EXPECT_FALSE(hc_compositor.coalesce_overlay_layers);
  EXPECT_EQ(hc_compositor.present_layers_callback, nullptr);
  EXPECT_NE(hc_compositor.present_view_callback, nullptr);
  EXPECT_EQ(
      hc_compositor.platform_view_mutation_capabilities,
      static_cast<uint64_t>(kFlutterPlatformViewMutationCapabilityDefault));

  FlutterCompositor hcpp_compositor = {};
  controller.ConfigureFlutterCompositor(&hcpp_compositor,
                                        /*enable_surface_control=*/true,
                                        kTestAndroidApiLevel34);
  EXPECT_TRUE(hcpp_compositor.avoid_backing_store_cache);
  EXPECT_FALSE(hcpp_compositor.merge_raster_thread_on_platform_views);
  EXPECT_TRUE(hcpp_compositor.coalesce_overlay_layers);
  EXPECT_EQ(
      hcpp_compositor.platform_view_mutation_capabilities,
      static_cast<uint64_t>(kFlutterPlatformViewMutationCapabilityPathConics));
}

TEST(AndroidPlatformViewsControllerTest,
     CreateBackingStoreRoutesRootLayerVsOverlayLayer) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  const FlutterCompositor* compositor = controller.GetEmbedderCompositor();
  ASSERT_NE(compositor, nullptr);

  // 1. Root layer (is_root_layer = true): binds and resizes on-screen
  // swapchain.
  FlutterBackingStoreConfig root_config = {};
  root_config.struct_size = sizeof(FlutterBackingStoreConfig);
  root_config.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};
  root_config.view_id = kPrimaryViewId;
  root_config.is_root_layer = true;

  FlutterBackingStore root_store = {};
  ASSERT_TRUE(compositor->create_backing_store_callback(
      &root_config, &root_store, compositor->user_data));
  EXPECT_EQ(controller.GetOnscreenBindCount(kPrimaryViewId), 1u);
  EXPECT_EQ(controller.GetOverlayBindCount(kPrimaryViewId), 0u);
  EXPECT_EQ(provider->GetCreateOverlaySurfaceCount(), 0u);
  const FlutterSize bound_size =
      controller.GetBoundOnscreenSize(kPrimaryViewId);
  EXPECT_DOUBLE_EQ(bound_size.width, kOnscreenWidth);
  EXPECT_DOUBLE_EQ(bound_size.height, kOnscreenHeight);
  EXPECT_EQ(root_store.open_gl.framebuffer.name, kDefaultOnscreenFramebufferId);

  // 2. Non-root layer (is_root_layer = false): allocates and resizes off-screen
  // overlay surface.
  FlutterBackingStoreConfig overlay_config = {};
  overlay_config.struct_size = sizeof(FlutterBackingStoreConfig);
  overlay_config.size = FlutterSize{kOverlayWidth, kOverlayHeight};
  overlay_config.view_id = kPrimaryViewId;
  overlay_config.is_root_layer = false;

  FlutterBackingStore overlay_store = {};
  ASSERT_TRUE(compositor->create_backing_store_callback(
      &overlay_config, &overlay_store, compositor->user_data));
  EXPECT_EQ(controller.GetOnscreenBindCount(kPrimaryViewId), 1u);
  EXPECT_EQ(controller.GetOverlayBindCount(kPrimaryViewId), 1u);
  EXPECT_EQ(provider->GetCreateOverlaySurfaceCount(), 1u);
  EXPECT_GE(overlay_store.open_gl.framebuffer.name, kBaseOverlayFramebufferId);

  // 3. Legacy struct_size smaller than is_root_layer offset defaults to
  // non-root overlay layer via SAFE_ACCESS.
  FlutterBackingStoreConfig truncated_config = {};
  truncated_config.struct_size =
      offsetof(FlutterBackingStoreConfig, is_root_layer);
  truncated_config.size = FlutterSize{kOverlayWidth, kOverlayHeight};

  FlutterBackingStore truncated_store = {};
  ASSERT_TRUE(compositor->create_backing_store_callback(
      &truncated_config, &truncated_store, compositor->user_data));
  EXPECT_EQ(controller.GetOverlayBindCount(kPrimaryViewId), 2u);
  EXPECT_EQ(provider->GetCreateOverlaySurfaceCount(), 2u);

  EXPECT_TRUE(compositor->collect_backing_store_callback(
      &root_store, compositor->user_data));
  EXPECT_TRUE(compositor->collect_backing_store_callback(
      &overlay_store, compositor->user_data));
  EXPECT_TRUE(compositor->collect_backing_store_callback(
      &truncated_store, compositor->user_data));
}

TEST(AndroidPlatformViewsControllerTest,
     RouteCreateOverlaySurfaceReleasesMutexBeforeLatchWaitOnUnmergedThread) {
  fml::Thread platform_thread("test_platform_thread");
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider,
                                            platform_thread.GetTaskRunner());

  std::atomic<bool> reentrant_query_completed{false};
  // When CreateOverlaySurface runs on the platform thread while the raster
  // thread is waiting inside latch.Wait(), re-enter controller methods that
  // lock controller.mutex_. If mutex_ were held across latch.Wait(), this
  // would deadlock.
  provider->SetOnCreateOverlaySurfaceHook(
      [&controller, &reentrant_query_completed]() {
        (void)controller.GetActiveOverlaySurfacesCount();
        (void)controller.GetBoundOnscreenSize(kPrimaryViewId);
        reentrant_query_completed.store(true);
      });

  // Call EnsureOverlaySurfaceAllocated from the current (unmerged) test thread.
  const std::optional<int32_t> surface_id =
      controller.EnsureOverlaySurfaceAllocated(0);
  ASSERT_TRUE(surface_id.has_value());
  EXPECT_TRUE(reentrant_query_completed.load());
  EXPECT_EQ(controller.GetActiveOverlaySurfacesCount(), 1u);
}

TEST(
    AndroidPlatformViewsControllerTest,
    PresentViewCapturesPerViewLayersByValueAndDispatchesUnregisteredJavaViews) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  const FlutterCompositor* compositor = controller.GetEmbedderCompositor();

  // Allocate root backing store for primary view (view_id = 0) and overlay.
  FlutterBackingStoreConfig root_cfg = {};
  root_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  root_cfg.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};
  root_cfg.view_id = kPrimaryViewId;
  root_cfg.is_root_layer = true;
  FlutterBackingStore root_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&root_cfg, &root_store));

  FlutterBackingStoreConfig ov_cfg = {};
  ov_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  ov_cfg.size = FlutterSize{kOverlayWidth, kOverlayHeight};
  ov_cfg.view_id = kPrimaryViewId;
  ov_cfg.is_root_layer = false;
  FlutterBackingStore ov_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&ov_cfg, &ov_store));

  // Build a platform view layer with an SoA conic clip path and opacity
  // mutation. Note that kUnregisteredJavaPlatformViewId1 was NEVER registered
  // via controller.CreatePlatformView().
  const FlutterPathVerb verbs[] = {kFlutterPathVerbMove, kFlutterPathVerbConic,
                                   kFlutterPathVerbClose};
  const FlutterPoint points[] = {{0.0, 0.0}, {50.0, 0.0}, {50.0, 50.0}};
  const double weights[] = {kSampleConicWeight};
  constexpr size_t kVerbCount = 3;
  constexpr size_t kPointCount = 3;

  FlutterPlatformViewMutation m_path = {};
  m_path.type = kFlutterPlatformViewMutationTypeClipPath;
  m_path.clip_path.struct_size = sizeof(FlutterPath);
  m_path.clip_path.fill_type = kFlutterPathFillTypeEvenOdd;
  m_path.clip_path.verbs_count = kVerbCount;
  m_path.clip_path.verbs = verbs;
  m_path.clip_path.points_count = kPointCount;
  m_path.clip_path.points = points;
  m_path.clip_path.conic_weights_count = 1;
  m_path.clip_path.conic_weights = weights;
  m_path.clip_path.bounds = FlutterRect{0.0, 0.0, 50.0, 50.0};

  FlutterPlatformViewMutation m_opacity = {};
  m_opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  m_opacity.opacity = kSampleOpacity;

  constexpr size_t kMutationCount = 2;
  const FlutterPlatformViewMutation* mutations[kMutationCount] = {&m_path,
                                                                  &m_opacity};

  FlutterPlatformView pv1 = {};
  pv1.struct_size = sizeof(FlutterPlatformView);
  pv1.identifier = kUnregisteredJavaPlatformViewId1;
  pv1.mutations_count = kMutationCount;
  pv1.mutations = mutations;

  FlutterLayer l_root = {};
  l_root.struct_size = sizeof(FlutterLayer);
  l_root.type = kFlutterLayerContentTypeBackingStore;
  l_root.backing_store = &root_store;
  l_root.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv1;
  l_pv.offset = FlutterPoint{kPlatformViewOffsetX, kPlatformViewOffsetY};
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  FlutterLayer l_ov = {};
  l_ov.struct_size = sizeof(FlutterLayer);
  l_ov.type = kFlutterLayerContentTypeBackingStore;
  l_ov.backing_store = &ov_store;
  l_ov.size = FlutterSize{kOverlayWidth, kOverlayHeight};

  constexpr size_t kPrimaryLayerCount = 3;
  const FlutterLayer* primary_layers[kPrimaryLayerCount] = {&l_root, &l_pv,
                                                            &l_ov};

  FlutterPresentViewInfo present_primary = {};
  present_primary.struct_size = sizeof(FlutterPresentViewInfo);
  present_primary.view_id = kPrimaryViewId;
  present_primary.layers = primary_layers;
  present_primary.layers_count = kPrimaryLayerCount;
  present_primary.user_data = compositor->user_data;

  ASSERT_TRUE(compositor->present_view_callback(&present_primary));

  // Verify OnDisplayPlatformView was dispatched to Java/provider without prior
  // C-API registration!
  EXPECT_EQ(provider->GetDisplayPlatformViewCount(), 1u);
  const auto geom1 =
      provider->GetLastGeometry(kUnregisteredJavaPlatformViewId1);
  ASSERT_TRUE(geom1.has_value());
  EXPECT_EQ(geom1->x, static_cast<int32_t>(kPlatformViewOffsetX));
  EXPECT_EQ(geom1->y, static_cast<int32_t>(kPlatformViewOffsetY));
  EXPECT_EQ(geom1->width, static_cast<int32_t>(kPlatformViewWidth));
  EXPECT_EQ(geom1->height, static_cast<int32_t>(kPlatformViewHeight));
  EXPECT_EQ(geom1->mutators_stack.GetMutatorsCount(), kMutationCount);

  // Present a second FlutterViewId (view_id = 1) with a different platform view
  // and verify per-FlutterViewId snapshots do not overwrite each other.
  FlutterPlatformView pv2 = {};
  pv2.struct_size = sizeof(FlutterPlatformView);
  pv2.identifier = kUnregisteredJavaPlatformViewId2;
  pv2.mutations_count = 0;
  pv2.mutations = nullptr;

  FlutterLayer l_pv2 = {};
  l_pv2.struct_size = sizeof(FlutterLayer);
  l_pv2.type = kFlutterLayerContentTypePlatformView;
  l_pv2.platform_view = &pv2;
  l_pv2.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  const FlutterLayer* secondary_layers[1] = {&l_pv2};
  FlutterPresentViewInfo present_secondary = {};
  present_secondary.struct_size = sizeof(FlutterPresentViewInfo);
  present_secondary.view_id = kSecondaryViewId;
  present_secondary.layers = secondary_layers;
  present_secondary.layers_count = 1;
  present_secondary.user_data = compositor->user_data;

  ASSERT_TRUE(compositor->present_view_callback(&present_secondary));

  const auto snap0 = controller.GetLastCommittedFrameSnapshot(kPrimaryViewId);
  const auto snap1 = controller.GetLastCommittedFrameSnapshot(kSecondaryViewId);
  ASSERT_TRUE(snap0.has_value());
  ASSERT_TRUE(snap1.has_value());
  EXPECT_TRUE(snap0->root_layer.present);
  ASSERT_EQ(snap0->platform_views.size(), 1u);
  EXPECT_EQ(snap0->platform_views[0].platform_view_id,
            kUnregisteredJavaPlatformViewId1);
  EXPECT_EQ(snap0->overlay_layers.size(), 1u);

  EXPECT_FALSE(snap1->root_layer.present);
  ASSERT_EQ(snap1->platform_views.size(), 1u);
  EXPECT_EQ(snap1->platform_views[0].platform_view_id,
            kUnregisteredJavaPlatformViewId2);
  EXPECT_TRUE(snap1->overlay_layers.empty());

  EXPECT_TRUE(controller.CollectBackingStore(&root_store));
  EXPECT_TRUE(controller.CollectBackingStore(&ov_store));
}

TEST(AndroidPlatformViewsControllerTest,
     SurfaceControlHcppLifecycleSwapsTransactionsAndHidesRemovedViews) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  ASSERT_TRUE(controller.SetHcppEnabled(true));
  EXPECT_TRUE(controller.IsHcppEnabled());

  FlutterBackingStoreConfig ov_cfg = {};
  ov_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  ov_cfg.size = FlutterSize{kOverlayWidth, kOverlayHeight};
  ov_cfg.view_id = kPrimaryViewId;
  ov_cfg.is_root_layer = false;
  FlutterBackingStore ov_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&ov_cfg, &ov_store));

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  FlutterLayer l_ov = {};
  l_ov.struct_size = sizeof(FlutterLayer);
  l_ov.type = kFlutterLayerContentTypeBackingStore;
  l_ov.backing_store = &ov_store;
  l_ov.size = FlutterSize{kOverlayWidth, kOverlayHeight};

  constexpr size_t kFrame1LayerCount = 2;
  const FlutterLayer* frame1_layers[kFrame1LayerCount] = {&l_pv, &l_ov};
  FlutterPresentViewInfo frame1 = {};
  frame1.struct_size = sizeof(FlutterPresentViewInfo);
  frame1.view_id = kPrimaryViewId;
  frame1.layers = frame1_layers;
  frame1.layers_count = kFrame1LayerCount;
  frame1.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&frame1));
  EXPECT_TRUE(provider->IsOverlayVisible(0));
  EXPECT_EQ(provider->GetSealFrameTransactionsCount(), 1u);
  EXPECT_EQ(provider->GetSwapTransactionCount(), 1u);
  EXPECT_EQ(provider->GetEndFrameCount(), 1u);

  // Frame 2: platform view and overlay are removed -> HidePlatformView and
  // HideOverlaySurface(0) must be invoked.
  FlutterPresentViewInfo frame2 = {};
  frame2.struct_size = sizeof(FlutterPresentViewInfo);
  frame2.view_id = kPrimaryViewId;
  frame2.layers = nullptr;
  frame2.layers_count = 0;
  frame2.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&frame2));
  EXPECT_FALSE(provider->IsOverlayVisible(0));
  const auto hidden = provider->GetHiddenPlatformViews();
  ASSERT_EQ(hidden.size(), 1u);
  EXPECT_EQ(hidden[0], kUnregisteredJavaPlatformViewId1);
  EXPECT_EQ(provider->GetSealFrameTransactionsCount(), 2u);
  EXPECT_EQ(provider->GetSwapTransactionCount(), 2u);

  EXPECT_TRUE(controller.CollectBackingStore(&ov_store));
}

TEST(AndroidPlatformViewsControllerTest,
     SetMergeRasterThreadOnPlatformViewsOverridesCompositorFlag) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  EXPECT_TRUE(controller.GetMergeRasterThreadOnPlatformViews());
  EXPECT_TRUE(controller.GetEmbedderCompositor()
                  ->merge_raster_thread_on_platform_views);

  controller.SetMergeRasterThreadOnPlatformViews(false);
  EXPECT_FALSE(controller.GetMergeRasterThreadOnPlatformViews());
  EXPECT_FALSE(controller.GetEmbedderCompositor()
                   ->merge_raster_thread_on_platform_views);

  controller.SetMergeRasterThreadOnPlatformViews(true);
  EXPECT_TRUE(controller.GetMergeRasterThreadOnPlatformViews());
  EXPECT_TRUE(controller.GetEmbedderCompositor()
                  ->merge_raster_thread_on_platform_views);
}

TEST(AndroidPlatformViewsControllerTest,
     RawRenderDelegateAndPreservedPhysicalViewDimensions) {
  class FakeRenderDelegate
      : public AndroidPlatformViewsController::RenderDelegate {
   public:
    bool BindAndResizeOnscreenSurface(
        FlutterViewId /*view_id*/,
        ANativeWindow* /*onscreen_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      ++onscreen_binds;
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      return true;
    }

    bool BindAndResizeOverlaySurface(
        FlutterViewId /*view_id*/,
        int32_t /*overlay_surface_id*/,
        ANativeWindow* /*overlay_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      ++overlay_binds;
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      return true;
    }

    size_t onscreen_binds = 0;
    size_t overlay_binds = 0;
  };

  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  FakeRenderDelegate delegate;
  controller.SetRenderDelegate(&delegate);

  /// Device pixel ratio 2.5x for testing physical viewWidth/viewHeight
  /// preservation alongside a 2.0x scene scale transform.
  constexpr double kTestDpr = 2.5;
  constexpr double kSceneScale = 2.0;
  controller.SetDevicePixelRatio(kTestDpr);

  FlutterBackingStoreConfig root_cfg = {};
  root_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  root_cfg.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};
  root_cfg.view_id = kPrimaryViewId;
  root_cfg.is_root_layer = true;
  FlutterBackingStore root_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&root_cfg, &root_store));
  EXPECT_EQ(delegate.onscreen_binds, 1u);
  EXPECT_EQ(controller.GetAllocatedStoreCount(), 1u);

  FlutterPlatformViewMutation m_root_dpr = {};
  m_root_dpr.type = kFlutterPlatformViewMutationTypeTransformation;
  m_root_dpr.transformation = FlutterTransformation{
      .scaleX = kTestDpr,
      .skewX = 0.0,
      .transX = 0.0,
      .skewY = 0.0,
      .scaleY = kTestDpr,
      .transY = 0.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  FlutterPlatformViewMutation m_scene_scale = {};
  m_scene_scale.type = kFlutterPlatformViewMutationTypeTransformation;
  m_scene_scale.transformation = FlutterTransformation{
      .scaleX = kSceneScale,
      .skewX = 0.0,
      .transX = 0.0,
      .skewY = 0.0,
      .scaleY = kSceneScale,
      .transY = 0.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  constexpr size_t kTransformCount = 2;
  const FlutterPlatformViewMutation* mutations[kTransformCount] = {
      &m_root_dpr, &m_scene_scale};

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;
  pv.mutations_count = kTransformCount;
  pv.mutations = mutations;

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  const FlutterLayer* layers[1] = {&l_pv};
  FlutterPresentViewInfo present_info = {};
  present_info.struct_size = sizeof(FlutterPresentViewInfo);
  present_info.view_id = kPrimaryViewId;
  present_info.layers = layers;
  present_info.layers_count = 1;
  present_info.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&present_info));
  EXPECT_EQ(controller.GetPresentCount(), 1u);

  const auto geom = provider->GetLastGeometry(kUnregisteredJavaPlatformViewId1);
  ASSERT_TRUE(geom.has_value());
  EXPECT_EQ(geom->view_width, static_cast<int32_t>(kPlatformViewWidth));
  EXPECT_EQ(geom->view_height, static_cast<int32_t>(kPlatformViewHeight));
  EXPECT_EQ(geom->width,
            static_cast<int32_t>(kPlatformViewWidth * kSceneScale));
  EXPECT_EQ(geom->height,
            static_cast<int32_t>(kPlatformViewHeight * kSceneScale));

  EXPECT_TRUE(controller.CollectBackingStore(&root_store));
  EXPECT_EQ(controller.GetAllocatedStoreCount(), 0u);
}

TEST(AndroidPlatformViewsControllerTest,
     PresentViewRotated90DegreesSwapsComposedWidthAndHeight) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);

  /// 2x device pixel ratio applied as the root surface transformation.
  constexpr double kTestDpr = 2.0;
  controller.SetDevicePixelRatio(kTestDpr);

  FlutterPlatformViewMutation m_root_dpr = {};
  m_root_dpr.type = kFlutterPlatformViewMutationTypeTransformation;
  m_root_dpr.transformation = FlutterTransformation{
      .scaleX = kTestDpr,
      .skewX = 0.0,
      .transX = 0.0,
      .skewY = 0.0,
      .scaleY = kTestDpr,
      .transY = 0.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  // 90 degree rotation: x' = -y, y' = x.
  FlutterPlatformViewMutation m_rotate = {};
  m_rotate.type = kFlutterPlatformViewMutationTypeTransformation;
  m_rotate.transformation = FlutterTransformation{
      .scaleX = 0.0,
      .skewX = -1.0,
      .transX = 0.0,
      .skewY = 1.0,
      .scaleY = 0.0,
      .transY = 0.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  constexpr size_t kTransformCount = 2;
  const FlutterPlatformViewMutation* mutations[kTransformCount] = {&m_root_dpr,
                                                                   &m_rotate};

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;
  pv.mutations_count = kTransformCount;
  pv.mutations = mutations;

  // Layer size is the unrotated physical size (sizePoints * dpr).
  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth * kTestDpr,
                          kPlatformViewHeight * kTestDpr};

  const FlutterLayer* layers[1] = {&l_pv};
  FlutterPresentViewInfo present_info = {};
  present_info.struct_size = sizeof(FlutterPresentViewInfo);
  present_info.view_id = kPrimaryViewId;
  present_info.layers = layers;
  present_info.layers_count = 1;
  present_info.user_data = &controller;
  ASSERT_TRUE(controller.PresentView(&present_info));

  const auto geom = provider->GetLastGeometry(kUnregisteredJavaPlatformViewId1);
  ASSERT_TRUE(geom.has_value());
  // viewWidth/viewHeight stay the unrotated physical size.
  EXPECT_EQ(geom->view_width,
            static_cast<int32_t>(kPlatformViewWidth * kTestDpr));
  EXPECT_EQ(geom->view_height,
            static_cast<int32_t>(kPlatformViewHeight * kTestDpr));
  // The composed bounding box is rotated, so width and height swap.
  EXPECT_EQ(geom->width, static_cast<int32_t>(kPlatformViewHeight * kTestDpr));
  EXPECT_EQ(geom->height, static_cast<int32_t>(kPlatformViewWidth * kTestDpr));
}

TEST(AndroidPlatformViewsControllerTest,
     PresentViewWithNoFrameWorkDoesNotWaitOnPlatformThread) {
  // These events must outlive platform_thread: the blocking task below is
  // still returning from release_platform.Wait() when the test body ends, and
  // Bionic aborts if it locks a mutex that has already been destroyed.
  fml::AutoResetWaitableEvent platform_blocked;
  fml::AutoResetWaitableEvent release_platform;
  fml::AutoResetWaitableEvent platform_finished;
  fml::Thread platform_thread("test_platform_thread");
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider,
                                            platform_thread.GetTaskRunner());

  // Block the platform thread. If PresentView posted to it and waited, the
  // raster-side call below would not complete until the block is released.
  platform_thread.GetTaskRunner()->PostTask([&]() {
    platform_blocked.Signal();
    release_platform.Wait();
    platform_finished.Signal();
  });
  platform_blocked.Wait();

  FlutterPresentViewInfo empty_frame = {};
  empty_frame.struct_size = sizeof(FlutterPresentViewInfo);
  empty_frame.view_id = kPrimaryViewId;
  empty_frame.layers = nullptr;
  empty_frame.layers_count = 0;
  empty_frame.user_data = &controller;

  std::atomic<bool> present_returned{false};
  std::thread raster_thread([&]() {
    EXPECT_TRUE(controller.PresentView(&empty_frame));
    present_returned.store(true);
  });

  /// Upper bound on how long a no-op PresentView may take before we treat it
  /// as blocked on the platform thread.
  constexpr auto kNoWaitDeadline = std::chrono::seconds(5);
  /// Polling interval while waiting for PresentView to return.
  constexpr auto kPollInterval = std::chrono::milliseconds(1);
  const auto deadline = std::chrono::steady_clock::now() + kNoWaitDeadline;
  while (!present_returned.load() &&
         std::chrono::steady_clock::now() < deadline) {
    std::this_thread::sleep_for(kPollInterval);
  }
  const bool returned_while_platform_blocked = present_returned.load();

  release_platform.Signal();
  platform_finished.Wait();
  raster_thread.join();

  EXPECT_TRUE(returned_while_platform_blocked);
  EXPECT_EQ(provider->GetBeginFrameCount(), 0u);
  EXPECT_EQ(provider->GetEndFrameCount(), 0u);
}

TEST(AndroidPlatformViewsControllerTest,
     FramePresentedCallbackFiresForPlatformViewOnlyFrames) {
  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);

  std::vector<FlutterViewId> presented_views;
  controller.SetFramePresentedCallback(
      [&presented_views](FlutterViewId view_id) {
        presented_views.push_back(view_id);
      });

  // A frame with no work must not report presentation.
  FlutterPresentViewInfo empty_frame = {};
  empty_frame.struct_size = sizeof(FlutterPresentViewInfo);
  empty_frame.view_id = kPrimaryViewId;
  empty_frame.user_data = &controller;
  ASSERT_TRUE(controller.PresentView(&empty_frame));
  EXPECT_TRUE(presented_views.empty());

  // A frame containing only a platform view layer (no backing store) must
  // report presentation after OnEndFrame so the embedder can fire
  // FlutterJNI.onFirstFrame().
  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  const FlutterLayer* layers[1] = {&l_pv};
  FlutterPresentViewInfo pv_frame = {};
  pv_frame.struct_size = sizeof(FlutterPresentViewInfo);
  pv_frame.view_id = kSecondaryViewId;
  pv_frame.layers = layers;
  pv_frame.layers_count = 1;
  pv_frame.user_data = &controller;
  ASSERT_TRUE(controller.PresentView(&pv_frame));

  ASSERT_EQ(presented_views.size(), 1u);
  EXPECT_EQ(presented_views[0], kSecondaryViewId);
  EXPECT_EQ(provider->GetEndFrameCount(), 1u);
}

TEST(AndroidPlatformViewsControllerTest,
     PresentViewWithPlatformViewAndOverlayWithoutRootClearsOnscreenInOrder) {
  std::vector<std::string> call_order;

  class OrderedProvider final : public InMemoryPlatformViewsProvider {
   public:
    explicit OrderedProvider(std::vector<std::string>* order) : order_(order) {}

    bool OnBeginFrame() override {
      order_->push_back("OnBeginFrame");
      return InMemoryPlatformViewsProvider::OnBeginFrame();
    }

    bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override {
      order_->push_back("OnDisplayPlatformView");
      return InMemoryPlatformViewsProvider::OnDisplayPlatformView(geometry);
    }

    bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) override {
      order_->push_back("OnDisplayOverlaySurface");
      return InMemoryPlatformViewsProvider::OnDisplayOverlaySurface(overlay);
    }

    bool OnEndFrame() override {
      order_->push_back("OnEndFrame");
      return InMemoryPlatformViewsProvider::OnEndFrame();
    }

   private:
    std::vector<std::string>* order_;
  };

  class OrderedRenderDelegate final
      : public AndroidPlatformViewsController::RenderDelegate {
   public:
    explicit OrderedRenderDelegate(std::vector<std::string>* order)
        : order_(order) {}

    bool BindAndResizeOnscreenSurface(
        FlutterViewId /*view_id*/,
        ANativeWindow* /*onscreen_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      return true;
    }

    bool BindAndResizeOverlaySurface(
        FlutterViewId /*view_id*/,
        int32_t /*overlay_surface_id*/,
        ANativeWindow* /*overlay_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      return true;
    }

    bool PresentOnscreenSurface(
        FlutterViewId /*view_id*/,
        const FlutterBackingStore* /*backing_store*/) override {
      order_->push_back("PresentOnscreenSurface");
      return true;
    }

    bool ClearAndPresentOnscreenSurface(FlutterViewId /*view_id*/) override {
      order_->push_back("ClearAndPresentOnscreenSurface");
      return true;
    }

    bool PresentOverlaySurface(
        FlutterViewId /*view_id*/,
        int32_t /*overlay_surface_id*/,
        const FlutterBackingStore* /*backing_store*/) override {
      order_->push_back("PresentOverlaySurface");
      return true;
    }

   private:
    std::vector<std::string>* order_;
  };

  auto provider = std::make_shared<OrderedProvider>(&call_order);
  AndroidPlatformViewsController controller(provider);
  OrderedRenderDelegate delegate(&call_order);
  controller.SetRenderDelegate(&delegate);

  FlutterBackingStoreConfig overlay_cfg = {};
  overlay_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  overlay_cfg.size = FlutterSize{kOverlayWidth, kOverlayHeight};
  overlay_cfg.view_id = kPrimaryViewId;
  overlay_cfg.is_root_layer = false;
  FlutterBackingStore overlay_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&overlay_cfg, &overlay_store));

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  FlutterLayer l_overlay = {};
  l_overlay.struct_size = sizeof(FlutterLayer);
  l_overlay.type = kFlutterLayerContentTypeBackingStore;
  l_overlay.backing_store = &overlay_store;
  l_overlay.size = FlutterSize{kOverlayWidth, kOverlayHeight};

  // Layer count of 2: [PlatformView, OverlayBackingStore] with no root layer.
  constexpr size_t kLayerCount = 2;
  const FlutterLayer* layers[kLayerCount] = {&l_pv, &l_overlay};
  FlutterPresentViewInfo present_info = {};
  present_info.struct_size = sizeof(FlutterPresentViewInfo);
  present_info.view_id = kPrimaryViewId;
  present_info.layers = layers;
  present_info.layers_count = kLayerCount;
  present_info.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&present_info));

  const std::vector<std::string> expected_order = {
      "OnBeginFrame",
      "OnDisplayPlatformView",
      "ClearAndPresentOnscreenSurface",
      "PresentOverlaySurface",
      "OnDisplayOverlaySurface",
      "OnEndFrame",
  };
  EXPECT_EQ(call_order, expected_order);
  EXPECT_TRUE(controller.CollectBackingStore(&overlay_store));
}

TEST(AndroidPlatformViewsControllerTest,
     PresentViewClearsOnscreenWhenOnDisplayPlatformViewSwitchesWindow) {
  // Synthetic non-null ANativeWindow pointers representing FlutterSurfaceView
  // before OnDisplayPlatformView and FlutterImageView after convertToImageView.
  constexpr uintptr_t kSurfaceViewWindowAddr = 0x5001;
  constexpr uintptr_t kImageViewWindowAddr = 0x5002;
  auto* surface_view_window =
      reinterpret_cast<ANativeWindow*>(kSurfaceViewWindowAddr);
  auto* image_view_window =
      reinterpret_cast<ANativeWindow*>(kImageViewWindowAddr);

  class WindowSwitchingProvider final : public InMemoryPlatformViewsProvider {
   public:
    WindowSwitchingProvider(AndroidPlatformViewsController** controller_Slot,
                            ANativeWindow* switched_window)
        : controller_slot_(controller_Slot),
          switched_window_(switched_window) {}

    bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override {
      if (*controller_slot_ != nullptr) {
        (*controller_slot_)
            ->SetOnscreenWindow(kPrimaryViewId, switched_window_,
                                static_cast<size_t>(kOnscreenWidth),
                                static_cast<size_t>(kOnscreenHeight));
      }
      return InMemoryPlatformViewsProvider::OnDisplayPlatformView(geometry);
    }

   private:
    AndroidPlatformViewsController** controller_slot_;
    ANativeWindow* switched_window_;
  };

  class RecordingRenderDelegate final
      : public AndroidPlatformViewsController::RenderDelegate {
   public:
    bool BindAndResizeOnscreenSurface(
        FlutterViewId /*view_id*/,
        ANativeWindow* /*onscreen_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      return true;
    }

    bool BindAndResizeOverlaySurface(
        FlutterViewId /*view_id*/,
        int32_t /*overlay_surface_id*/,
        ANativeWindow* /*overlay_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      return true;
    }

    bool PresentOnscreenSurface(
        FlutterViewId /*view_id*/,
        const FlutterBackingStore* /*backing_store*/) override {
      ++present_onscreen_count;
      return true;
    }

    bool ClearAndPresentOnscreenSurface(FlutterViewId /*view_id*/) override {
      ++clear_and_present_count;
      return true;
    }

    size_t present_onscreen_count = 0;
    size_t clear_and_present_count = 0;
  };

  AndroidPlatformViewsController* controller_ptr = nullptr;
  auto provider = std::make_shared<WindowSwitchingProvider>(&controller_ptr,
                                                            image_view_window);
  AndroidPlatformViewsController controller(provider);
  controller_ptr = &controller;
  controller.SetOnscreenWindow(kPrimaryViewId, surface_view_window,
                               static_cast<size_t>(kOnscreenWidth),
                               static_cast<size_t>(kOnscreenHeight));

  RecordingRenderDelegate delegate;
  controller.SetRenderDelegate(&delegate);

  FlutterBackingStoreConfig root_cfg = {};
  root_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  root_cfg.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};
  root_cfg.view_id = kPrimaryViewId;
  root_cfg.is_root_layer = true;
  FlutterBackingStore root_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&root_cfg, &root_store));

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = kUnregisteredJavaPlatformViewId1;

  FlutterLayer l_root = {};
  l_root.struct_size = sizeof(FlutterLayer);
  l_root.type = kFlutterLayerContentTypeBackingStore;
  l_root.backing_store = &root_store;
  l_root.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};

  FlutterLayer l_pv = {};
  l_pv.struct_size = sizeof(FlutterLayer);
  l_pv.type = kFlutterLayerContentTypePlatformView;
  l_pv.platform_view = &pv;
  l_pv.size = FlutterSize{kPlatformViewWidth, kPlatformViewHeight};

  // Layer count of 2: [RootBackingStore, PlatformView].
  constexpr size_t kLayerCount = 2;
  const FlutterLayer* layers[kLayerCount] = {&l_root, &l_pv};
  FlutterPresentViewInfo present_info = {};
  present_info.struct_size = sizeof(FlutterPresentViewInfo);
  present_info.view_id = kPrimaryViewId;
  present_info.layers = layers;
  present_info.layers_count = kLayerCount;
  present_info.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&present_info));
  EXPECT_EQ(delegate.present_onscreen_count, 0u);
  EXPECT_EQ(delegate.clear_and_present_count, 1u);
  EXPECT_TRUE(controller.CollectBackingStore(&root_store));
}

TEST(AndroidPlatformViewsControllerTest,
     PresentViewWithoutPlatformViewsPresentsRootLayerWithoutJavaFrameHooks) {
  class RootOnlyRenderDelegate final
      : public AndroidPlatformViewsController::RenderDelegate {
   public:
    bool BindAndResizeOnscreenSurface(
        FlutterViewId /*view_id*/,
        ANativeWindow* /*onscreen_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      return true;
    }

    bool BindAndResizeOverlaySurface(
        FlutterViewId /*view_id*/,
        int32_t /*overlay_surface_id*/,
        ANativeWindow* /*overlay_window*/,
        size_t /*width*/,
        size_t /*height*/,
        FlutterBackingStore* backing_store_out) override {
      *backing_store_out = {};
      backing_store_out->struct_size = sizeof(FlutterBackingStore);
      return true;
    }

    bool PresentOnscreenSurface(
        FlutterViewId /*view_id*/,
        const FlutterBackingStore* /*backing_store*/) override {
      ++present_onscreen_count;
      return true;
    }

    size_t present_onscreen_count = 0;
  };

  auto provider = std::make_shared<InMemoryPlatformViewsProvider>();
  AndroidPlatformViewsController controller(provider);
  RootOnlyRenderDelegate delegate;
  controller.SetRenderDelegate(&delegate);

  FlutterBackingStoreConfig root_cfg = {};
  root_cfg.struct_size = sizeof(FlutterBackingStoreConfig);
  root_cfg.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};
  root_cfg.view_id = kPrimaryViewId;
  root_cfg.is_root_layer = true;
  FlutterBackingStore root_store = {};
  ASSERT_TRUE(controller.CreateBackingStore(&root_cfg, &root_store));

  FlutterLayer l_root = {};
  l_root.struct_size = sizeof(FlutterLayer);
  l_root.type = kFlutterLayerContentTypeBackingStore;
  l_root.backing_store = &root_store;
  l_root.size = FlutterSize{kOnscreenWidth, kOnscreenHeight};

  // Single root backing-store layer with no platform views or overlays.
  constexpr size_t kSingleLayerCount = 1;
  const FlutterLayer* layers[kSingleLayerCount] = {&l_root};
  FlutterPresentViewInfo present_info = {};
  present_info.struct_size = sizeof(FlutterPresentViewInfo);
  present_info.view_id = kPrimaryViewId;
  present_info.layers = layers;
  present_info.layers_count = kSingleLayerCount;
  present_info.user_data = &controller;

  ASSERT_TRUE(controller.PresentView(&present_info));
  EXPECT_EQ(delegate.present_onscreen_count, 1u);
  EXPECT_EQ(provider->GetBeginFrameCount(), 0u);
  EXPECT_EQ(provider->GetEndFrameCount(), 0u);
  EXPECT_TRUE(controller.CollectBackingStore(&root_store));
}

}  // namespace testing
}  // namespace flutter
