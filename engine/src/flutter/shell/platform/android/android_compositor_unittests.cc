// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_compositor.h"

#include <atomic>
#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

class MockPlatformViewDelegate : public AndroidCompositorPlatformViewDelegate {
 public:
  struct PresentedView {
    int64_t view_id = -1;
    FlutterPoint offset = {0, 0};
    FlutterSize size = {0, 0};
    size_t mutations_count = 0;
  };

  struct PresentedOverlay {
    size_t overlay_index = 0;
    FlutterPoint offset = {0, 0};
    FlutterSize size = {0, 0};
  };

  void OnPlatformViewPresented(
      int64_t view_id,
      const FlutterPoint& offset,
      const FlutterSize& size,
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations) override {
    presented_views_.push_back(
        PresentedView{view_id, offset, size, mutations_count});
  }

  void OnOverlayPresented(size_t overlay_index,
                          const FlutterPoint& offset,
                          const FlutterSize& size) override {
    presented_overlays_.push_back(
        PresentedOverlay{overlay_index, offset, size});
  }

  ANativeWindow* GetOverlayWindow(size_t overlay_index) override {
    get_overlay_window_calls_++;
    return fake_overlay_window_;
  }

  void SetFakeOverlayWindow(ANativeWindow* window) {
    fake_overlay_window_ = window;
  }

  size_t GetOverlayWindowCalls() const { return get_overlay_window_calls_; }

  void OnFramePresented() override { frame_presented_count_++; }

  const std::vector<PresentedView>& GetPresentedViews() const {
    return presented_views_;
  }

  const std::vector<PresentedOverlay>& GetPresentedOverlays() const {
    return presented_overlays_;
  }

  size_t GetFramePresentedCount() const { return frame_presented_count_; }

  void Reset() {
    presented_views_.clear();
    presented_overlays_.clear();
    frame_presented_count_ = 0;
  }

 private:
  std::vector<PresentedView> presented_views_;
  std::vector<PresentedOverlay> presented_overlays_;
  size_t frame_presented_count_ = 0;
  ANativeWindow* fake_overlay_window_ = nullptr;
  size_t get_overlay_window_calls_ = 0;
};

}  // namespace

TEST(AndroidCompositorTest, LifecycleAndInitialState) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(surface_manager, nullptr);

  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);
  ASSERT_NE(compositor, nullptr);
  EXPECT_EQ(compositor->GetSurfaceManager(), surface_manager);
  EXPECT_EQ(compositor->GetPresentedFrameCount(), 0u);
  EXPECT_EQ(compositor->GetLastPresentedLayersCount(), 0u);
  EXPECT_EQ(compositor->GetLastPresentedPlatformViewsCount(), 0u);
}

TEST(AndroidCompositorTest, CreateAndCollectSoftwareBackingStore) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(surface_manager, nullptr);
  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);

  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{100.0, 200.0};
  config.view_id = 0;

  FlutterBackingStore backing_store = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &backing_store));
  EXPECT_EQ(backing_store.struct_size, sizeof(FlutterBackingStore));
  EXPECT_EQ(backing_store.type, kFlutterBackingStoreTypeSoftware);
  ASSERT_NE(backing_store.software.allocation, nullptr);
  EXPECT_EQ(backing_store.software.row_bytes, 100u * 4);
  EXPECT_EQ(backing_store.software.height, 200u);
  EXPECT_EQ(backing_store.software.destruction_callback, nullptr);

  // Invalid config checks
  FlutterBackingStore bad_backing_store = {};
  EXPECT_FALSE(compositor->CreateBackingStore(nullptr, &bad_backing_store));
  EXPECT_FALSE(compositor->CreateBackingStore(&config, nullptr));

  FlutterBackingStoreConfig small_config = config;
  small_config.struct_size = sizeof(size_t) - 1;
  EXPECT_FALSE(
      compositor->CreateBackingStore(&small_config, &bad_backing_store));

  EXPECT_TRUE(compositor->CollectBackingStore(&backing_store));
  EXPECT_FALSE(compositor->CollectBackingStore(nullptr));
}

TEST(AndroidCompositorTest, CreateAndCollectGLBackingStore) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);

  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{800.0, 600.0};
  config.view_id = 0;

  FlutterBackingStore backing_store = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &backing_store));
  EXPECT_EQ(backing_store.struct_size, sizeof(FlutterBackingStore));
  EXPECT_TRUE(backing_store.did_update);
  EXPECT_EQ(backing_store.type, kFlutterBackingStoreTypeOpenGL);
  EXPECT_EQ(backing_store.open_gl.type, kFlutterOpenGLTargetTypeFramebuffer);
  EXPECT_EQ(backing_store.open_gl.framebuffer.target, 0x8058u);  // GL_RGBA8
  EXPECT_EQ(backing_store.open_gl.framebuffer.name, 0u);

  // Invalid dimensions
  FlutterBackingStoreConfig zero_config = config;
  zero_config.size = FlutterSize{0.0, 100.0};
  FlutterBackingStore zero_store = {};
  EXPECT_FALSE(compositor->CreateBackingStore(&zero_config, &zero_store));

  EXPECT_TRUE(compositor->CollectBackingStore(&backing_store));
}

TEST(AndroidCompositorTest, PresentLayersWithBackingStoreAndPlatformViews) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(surface_manager, nullptr);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto mock_delegate = std::make_shared<MockPlatformViewDelegate>();
  auto compositor =
      std::make_unique<AndroidCompositor>(surface_manager, mock_delegate);

  // Backing store
  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{100.0, 100.0};
  config.view_id = 0;

  FlutterBackingStore backing_store = {};
  ASSERT_TRUE(compositor->CreateBackingStore(&config, &backing_store));

  FlutterLayer backing_store_layer = {};
  backing_store_layer.struct_size = sizeof(FlutterLayer);
  backing_store_layer.type = kFlutterLayerContentTypeBackingStore;
  backing_store_layer.backing_store = &backing_store;
  backing_store_layer.offset = FlutterPoint{0.0, 0.0};
  backing_store_layer.size = FlutterSize{100.0, 100.0};

  // Platform view 1
  FlutterPlatformViewMutation mutation1 = {};
  mutation1.type = kFlutterPlatformViewMutationTypeOpacity;
  mutation1.opacity = 0.8;
  const FlutterPlatformViewMutation* mutations_array1[] = {&mutation1};

  FlutterPlatformView pv1 = {};
  pv1.struct_size = sizeof(FlutterPlatformView);
  pv1.identifier = 42;
  pv1.mutations_count = 1;
  pv1.mutations = mutations_array1;

  FlutterLayer pv_layer1 = {};
  pv_layer1.struct_size = sizeof(FlutterLayer);
  pv_layer1.type = kFlutterLayerContentTypePlatformView;
  pv_layer1.platform_view = &pv1;
  pv_layer1.offset = FlutterPoint{10.0, 20.0};
  pv_layer1.size = FlutterSize{200.0, 300.0};

  // Platform view 2
  FlutterPlatformView pv2 = {};
  pv2.struct_size = sizeof(FlutterPlatformView);
  pv2.identifier = 84;
  pv2.mutations_count = 0;
  pv2.mutations = nullptr;

  FlutterLayer pv_layer2 = {};
  pv_layer2.struct_size = sizeof(FlutterLayer);
  pv_layer2.type = kFlutterLayerContentTypePlatformView;
  pv_layer2.platform_view = &pv2;
  pv_layer2.offset = FlutterPoint{50.0, 60.0};
  pv_layer2.size = FlutterSize{150.0, 250.0};

  const FlutterLayer* layers[] = {&backing_store_layer, &pv_layer1, &pv_layer2};

  EXPECT_TRUE(compositor->PresentLayers(layers, 3));
  EXPECT_EQ(compositor->GetPresentedFrameCount(), 1u);
  EXPECT_EQ(compositor->GetLastPresentedLayersCount(), 3u);
  EXPECT_EQ(compositor->GetLastPresentedPlatformViewsCount(), 2u);

  EXPECT_EQ(mock_delegate->GetFramePresentedCount(), 1u);
  ASSERT_EQ(mock_delegate->GetPresentedViews().size(), 2u);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].view_id, 42);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].offset.x, 10.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].offset.y, 20.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].size.width, 200.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].size.height, 300.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[0].mutations_count, 1u);

  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].view_id, 84);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].offset.x, 50.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].offset.y, 60.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].size.width, 150.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].size.height, 250.0);
  EXPECT_EQ(mock_delegate->GetPresentedViews()[1].mutations_count, 0u);

  compositor->CollectBackingStore(&backing_store);
}

TEST(AndroidCompositorTest, PresentViewCallback) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);

  FlutterBackingStore backing_store = {};
  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{100.0, 100.0};
  config.view_id = 0;
  ASSERT_TRUE(compositor->CreateBackingStore(&config, &backing_store));

  FlutterLayer layer = {};
  layer.struct_size = sizeof(FlutterLayer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.offset = FlutterPoint{0.0, 0.0};
  layer.size = FlutterSize{100.0, 100.0};

  const FlutterLayer* layers[] = {&layer};

  FlutterPresentViewInfo info = {};
  info.struct_size = sizeof(FlutterPresentViewInfo);
  info.view_id = 0;
  info.layers = layers;
  info.layers_count = 1;
  info.user_data = compositor.get();

  EXPECT_TRUE(compositor->PresentView(&info));
  EXPECT_EQ(compositor->GetPresentedFrameCount(), 1u);

  // Null safety & invalid struct_size
  EXPECT_FALSE(compositor->PresentView(nullptr));

  FlutterPresentViewInfo small_info = info;
  small_info.struct_size = sizeof(size_t) - 1;
  EXPECT_FALSE(compositor->PresentView(&small_info));

  compositor->CollectBackingStore(&backing_store);
}

TEST(AndroidCompositorTest, ANRSafeConcurrentSurfaceDetachment) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);

  FlutterBackingStore backing_store = {};
  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{100.0, 100.0};
  config.view_id = 0;
  ASSERT_TRUE(compositor->CreateBackingStore(&config, &backing_store));

  FlutterLayer layer = {};
  layer.struct_size = sizeof(FlutterLayer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.offset = FlutterPoint{0.0, 0.0};
  layer.size = FlutterSize{100.0, 100.0};
  const FlutterLayer* layers[] = {&layer};

  constexpr size_t kIterations = 200;
  std::atomic<bool> start{false};
  std::atomic<bool> running{true};

  // Platform thread attaching and detaching surface
  std::thread platform_thread([&]() {
    while (!start.load()) {
      std::this_thread::yield();
    }
    for (size_t i = 0; i < kIterations; ++i) {
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true);
      std::this_thread::yield();
      surface_manager->ClearNativeWindow();
    }
    running.store(false);
  });

  // Raster thread presenting layers concurrently
  std::thread raster_thread([&]() {
    while (!start.load()) {
      std::this_thread::yield();
    }
    while (running.load()) {
      compositor->PresentLayers(layers, 1);
      std::this_thread::yield();
    }
    // Present at least one final time to guarantee presentation count > 0
    compositor->PresentLayers(layers, 1);
  });

  start.store(true);
  platform_thread.join();
  raster_thread.join();

  EXPECT_GT(compositor->GetPresentedFrameCount(), 0u);
  compositor->CollectBackingStore(&backing_store);
}

TEST(AndroidCompositorTest, PopulateCompositorConfig) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);

  FlutterCompositor comp_config = {};
  compositor->PopulateCompositorConfig(&comp_config);

  EXPECT_EQ(comp_config.struct_size, sizeof(FlutterCompositor));
  EXPECT_EQ(comp_config.user_data, compositor.get());
  ASSERT_NE(comp_config.create_backing_store_callback, nullptr);
  ASSERT_NE(comp_config.collect_backing_store_callback, nullptr);
  ASSERT_NE(comp_config.present_view_callback, nullptr);
  EXPECT_TRUE(comp_config.avoid_backing_store_cache);

  // Test callbacks through C-API trampolines
  FlutterBackingStoreConfig bs_config = {};
  bs_config.struct_size = sizeof(FlutterBackingStoreConfig);
  bs_config.size = FlutterSize{200.0, 300.0};
  bs_config.view_id = 0;

  FlutterBackingStore bs = {};
  EXPECT_TRUE(comp_config.create_backing_store_callback(&bs_config, &bs,
                                                        comp_config.user_data));

  FlutterLayer layer = {};
  layer.struct_size = sizeof(FlutterLayer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &bs;
  const FlutterLayer* layers[] = {&layer};

  FlutterPresentViewInfo info = {};
  info.struct_size = sizeof(FlutterPresentViewInfo);
  info.view_id = 0;
  info.layers = layers;
  info.layers_count = 1;
  info.user_data = comp_config.user_data;

  EXPECT_TRUE(comp_config.present_view_callback(&info));
  EXPECT_EQ(compositor->GetPresentedFrameCount(), 1u);

  EXPECT_TRUE(
      comp_config.collect_backing_store_callback(&bs, comp_config.user_data));

  // Null safety
  compositor->PopulateCompositorConfig(nullptr);
}

TEST(AndroidCompositorTest, BackingStoreRoundTrip) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto compositor = std::make_unique<AndroidCompositor>(surface_manager);
  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{100.0, 100.0};
  config.view_id = 0;

  FlutterBackingStore bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &bs));

  FlutterLayer layer = {};
  layer.struct_size = sizeof(FlutterLayer);
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &bs;
  const FlutterLayer* layers[] = {&layer};

  EXPECT_TRUE(compositor->PresentLayers(layers, 1));
  EXPECT_TRUE(compositor->CollectBackingStore(&bs));
}

TEST(AndroidCompositorTest, MultiLayerPlatformViewWithOverlayDispatch) {
  std::shared_ptr<AndroidSurfaceManager> surface_manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(surface_manager, nullptr);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto delegate = std::make_shared<MockPlatformViewDelegate>();
  auto compositor =
      std::make_unique<AndroidCompositor>(surface_manager, delegate);

  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  // 150.0x150.0 dimensions matching smoke test golden size.
  config.size = FlutterSize{150.0, 150.0};
  config.view_id = 0;

  FlutterBackingStore root_bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &root_bs));

  FlutterBackingStore overlay_bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &overlay_bs));

  // Layer 0: Root backing store below the platform view
  FlutterLayer root_layer = {};
  root_layer.struct_size = sizeof(FlutterLayer);
  root_layer.type = kFlutterLayerContentTypeBackingStore;
  root_layer.backing_store = &root_bs;
  root_layer.offset = FlutterPoint{0.0, 0.0};
  root_layer.size = FlutterSize{150.0, 150.0};

  // Layer 1: Platform view in the middle
  FlutterPlatformView platform_view = {};
  platform_view.struct_size = sizeof(FlutterPlatformView);
  // View ID 42 representing native view.
  platform_view.identifier = 42;
  platform_view.mutations_count = 0;
  platform_view.mutations = nullptr;

  FlutterLayer pv_layer = {};
  pv_layer.struct_size = sizeof(FlutterLayer);
  pv_layer.type = kFlutterLayerContentTypePlatformView;
  pv_layer.platform_view = &platform_view;
  pv_layer.offset = FlutterPoint{10.0, 10.0};
  pv_layer.size = FlutterSize{100.0, 100.0};

  // Layer 2: Overlay backing store above the platform view (the Flutter circle)
  FlutterLayer overlay_layer = {};
  overlay_layer.struct_size = sizeof(FlutterLayer);
  overlay_layer.type = kFlutterLayerContentTypeBackingStore;
  overlay_layer.backing_store = &overlay_bs;
  overlay_layer.offset = FlutterPoint{15.0, 15.0};
  overlay_layer.size = FlutterSize{120.0, 90.0};

  const FlutterLayer* layers[] = {&root_layer, &pv_layer, &overlay_layer};
  // 3 composited layers in total.
  constexpr size_t kLayerCount = 3;

  EXPECT_TRUE(compositor->PresentLayers(layers, kLayerCount));

  EXPECT_EQ(compositor->GetPresentedFrameCount(), 1u);
  EXPECT_EQ(compositor->GetLastPresentedLayersCount(), kLayerCount);
  EXPECT_EQ(compositor->GetLastPresentedPlatformViewsCount(), 1u);
  EXPECT_EQ(compositor->GetLastPresentedOverlaysCount(), 1u);

  EXPECT_EQ(delegate->GetFramePresentedCount(), 1u);
  ASSERT_EQ(delegate->GetPresentedViews().size(), 1u);
  EXPECT_EQ(delegate->GetPresentedViews()[0].view_id, 42);

  ASSERT_EQ(delegate->GetPresentedOverlays().size(), 1u);
  EXPECT_EQ(delegate->GetPresentedOverlays()[0].overlay_index, 0u);
  EXPECT_DOUBLE_EQ(delegate->GetPresentedOverlays()[0].offset.x, 15.0);
  EXPECT_DOUBLE_EQ(delegate->GetPresentedOverlays()[0].offset.y, 15.0);
  EXPECT_DOUBLE_EQ(delegate->GetPresentedOverlays()[0].size.width, 120.0);
  EXPECT_DOUBLE_EQ(delegate->GetPresentedOverlays()[0].size.height, 90.0);
  EXPECT_EQ(delegate->GetOverlayWindowCalls(), 1u);

  EXPECT_TRUE(compositor->CollectBackingStore(&root_bs));
  EXPECT_TRUE(compositor->CollectBackingStore(&overlay_bs));
}

namespace {

class OrderRecordingSurfaceManager : public AndroidSurfaceManager {
 public:
  OrderRecordingSurfaceManager(AndroidRenderingAPI api,
                               std::shared_ptr<std::vector<std::string>> events)
      : AndroidSurfaceManager(api), events_(std::move(events)) {}

  bool Present() override {
    if (events_) {
      events_->push_back("Present");
    }
    return AndroidSurfaceManager::Present();
  }

  bool BlitAndPresentOnscreenSurface(uint32_t offscreen_fbo,
                                     size_t width,
                                     size_t height) override {
    if (events_) {
      events_->push_back("BlitAndPresentOnscreenSurface");
    }
    return AndroidSurfaceManager::Present();
  }

  bool ClearAndPresentOnscreenSurface() override {
    if (events_) {
      events_->push_back("ClearAndPresentOnscreenSurface");
    }
    return AndroidSurfaceManager::Present();
  }

 private:
  std::shared_ptr<std::vector<std::string>> events_;
};

class OrderRecordingPlatformViewDelegate
    : public AndroidCompositorPlatformViewDelegate {
 public:
  explicit OrderRecordingPlatformViewDelegate(
      std::shared_ptr<std::vector<std::string>> events)
      : events_(std::move(events)) {}

  void OnBeginFrame() override {
    if (events_) {
      events_->push_back("OnBeginFrame");
    }
  }

  void OnPlatformViewPresented(
      int64_t view_id,
      const FlutterPoint& offset,
      const FlutterSize& size,
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations) override {
    (void)offset;
    (void)size;
    (void)mutations_count;
    (void)mutations;
    if (events_) {
      events_->push_back("OnPlatformViewPresented:" + std::to_string(view_id));
    }
  }

  void OnOverlayPresented(size_t overlay_index,
                          const FlutterPoint& offset,
                          const FlutterSize& size) override {
    (void)offset;
    (void)size;
    if (events_) {
      events_->push_back("OnOverlayPresented:" + std::to_string(overlay_index));
    }
  }

  ANativeWindow* GetOverlayWindow(size_t overlay_index) override {
    if (events_) {
      events_->push_back("GetOverlayWindow:" + std::to_string(overlay_index));
    }
    return nullptr;
  }

  void OnFramePresented() override {
    if (events_) {
      events_->push_back("OnFramePresented");
    }
  }

 private:
  std::shared_ptr<std::vector<std::string>> events_;
};

}  // namespace

TEST(AndroidCompositorTest,
     PlatformViewAndOverlayWithoutBackgroundBackingStoreClearsAndPresents) {
  auto events = std::make_shared<std::vector<std::string>>();
  auto surface_manager = std::make_shared<OrderRecordingSurfaceManager>(
      AndroidRenderingAPI::kSkiaOpenGLES, events);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto delegate = std::make_shared<OrderRecordingPlatformViewDelegate>(events);
  auto compositor =
      std::make_unique<AndroidCompositor>(surface_manager, delegate);

  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  // 150.0x150.0 dimensions matching smoke test golden size.
  config.size = FlutterSize{150.0, 150.0};
  config.view_id = 0;

  FlutterBackingStore overlay_bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &overlay_bs));

  // Layer 0: Platform view with no Flutter background layer below it
  FlutterPlatformView platform_view = {};
  platform_view.struct_size = sizeof(FlutterPlatformView);
  // View ID 1 matching HybridAndroidViewTest.
  platform_view.identifier = 1;
  platform_view.mutations_count = 0;
  platform_view.mutations = nullptr;

  FlutterLayer pv_layer = {};
  pv_layer.struct_size = sizeof(FlutterLayer);
  pv_layer.type = kFlutterLayerContentTypePlatformView;
  pv_layer.platform_view = &platform_view;
  pv_layer.offset = FlutterPoint{0.0, 0.0};
  pv_layer.size = FlutterSize{150.0, 150.0};

  // Layer 1: Overlay backing store above the platform view
  FlutterLayer overlay_layer = {};
  overlay_layer.struct_size = sizeof(FlutterLayer);
  overlay_layer.type = kFlutterLayerContentTypeBackingStore;
  overlay_layer.backing_store = &overlay_bs;
  overlay_layer.offset = FlutterPoint{0.0, 0.0};
  overlay_layer.size = FlutterSize{75.0, 75.0};

  const FlutterLayer* layers[] = {&pv_layer, &overlay_layer};
  // 2 composited layers (PlatformView + Overlay).
  constexpr size_t kLayerCount = 2;

  EXPECT_TRUE(compositor->PresentLayers(layers, kLayerCount));

  const std::vector<std::string> expected_events = {
      "OnBeginFrame",
      "OnPlatformViewPresented:1",
      "GetOverlayWindow:0",
      "OnOverlayPresented:0",
      "ClearAndPresentOnscreenSurface",
      "OnFramePresented",
  };
  EXPECT_EQ(*events, expected_events);

  EXPECT_TRUE(compositor->CollectBackingStore(&overlay_bs));
}

TEST(AndroidCompositorTest,
     RootBackingStorePresentedAfterPlatformViewAndOverlay) {
  auto events = std::make_shared<std::vector<std::string>>();
  auto surface_manager = std::make_shared<OrderRecordingSurfaceManager>(
      AndroidRenderingAPI::kSkiaOpenGLES, events);
  EXPECT_TRUE(
      surface_manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  auto delegate = std::make_shared<OrderRecordingPlatformViewDelegate>(events);
  auto compositor =
      std::make_unique<AndroidCompositor>(surface_manager, delegate);

  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = FlutterSize{150.0, 150.0};
  config.view_id = 0;

  FlutterBackingStore root_bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &root_bs));

  FlutterBackingStore overlay_bs = {};
  EXPECT_TRUE(compositor->CreateBackingStore(&config, &overlay_bs));

  FlutterLayer root_layer = {};
  root_layer.struct_size = sizeof(FlutterLayer);
  root_layer.type = kFlutterLayerContentTypeBackingStore;
  root_layer.backing_store = &root_bs;
  root_layer.offset = FlutterPoint{0.0, 0.0};
  root_layer.size = FlutterSize{150.0, 150.0};

  FlutterPlatformView platform_view = {};
  platform_view.struct_size = sizeof(FlutterPlatformView);
  platform_view.identifier = 42;
  platform_view.mutations_count = 0;
  platform_view.mutations = nullptr;

  FlutterLayer pv_layer = {};
  pv_layer.struct_size = sizeof(FlutterLayer);
  pv_layer.type = kFlutterLayerContentTypePlatformView;
  pv_layer.platform_view = &platform_view;
  pv_layer.offset = FlutterPoint{10.0, 10.0};
  pv_layer.size = FlutterSize{100.0, 100.0};

  FlutterLayer overlay_layer = {};
  overlay_layer.struct_size = sizeof(FlutterLayer);
  overlay_layer.type = kFlutterLayerContentTypeBackingStore;
  overlay_layer.backing_store = &overlay_bs;
  overlay_layer.offset = FlutterPoint{15.0, 15.0};
  overlay_layer.size = FlutterSize{120.0, 90.0};

  const FlutterLayer* layers[] = {&root_layer, &pv_layer, &overlay_layer};
  constexpr size_t kLayerCount = 3;

  EXPECT_TRUE(compositor->PresentLayers(layers, kLayerCount));

  const std::vector<std::string> expected_events = {
      "OnBeginFrame",
      "OnPlatformViewPresented:42",
      "GetOverlayWindow:0",
      "OnOverlayPresented:0",
      "Present",
      "OnFramePresented",
  };
  EXPECT_EQ(*events, expected_events);

  EXPECT_TRUE(compositor->CollectBackingStore(&root_bs));
  EXPECT_TRUE(compositor->CollectBackingStore(&overlay_bs));
}

}  // namespace testing
}  // namespace flutter
