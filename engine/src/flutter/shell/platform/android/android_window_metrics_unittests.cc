// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <future>
#include <thread>
#include <vector>

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;
using ::testing::StrictMock;

class MockJvmInvokerForMetrics : public JvmInvoker {
 public:
  MockJvmInvokerForMetrics() {
    ON_CALL(*this, InvokeVoidMethod(::testing::_, ::testing::_, ::testing::_))
        .WillByDefault(::testing::Return(true));
    ON_CALL(*this,
            InvokeBooleanMethod(::testing::_, ::testing::_, ::testing::_))
        .WillByDefault(::testing::Return(true));
  }

  MOCK_METHOD(bool, EnsureAttachedToThread, (), (override));
  MOCK_METHOD(void, DetachFromThread, (), (override));
  MOCK_METHOD(bool, HasPendingException, (), (const, override));
  MOCK_METHOD(void, ClearPendingException, (), (override));

  MOCK_METHOD(bool,
              InvokeVoidMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool,
              InvokeBooleanMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(int64_t,
              InvokeIntMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(double,
              InvokeDoubleMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::string,
              InvokeStringMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::vector<uint8_t>,
              InvokeBytesMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

class MockLegacyJniDelegateForMetrics : public LegacyJniDelegate {
 public:
  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const std::vector<uint8_t>& message,
               int32_t response_id),
              (override));
  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const std::vector<uint8_t>& data),
              (override));
  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings),
              (override));
  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));
  MOCK_METHOD(bool,
              UpdateCustomAccessibilityActions,
              (const std::vector<uint8_t>& actions_buffer,
               const std::vector<std::string>& action_strings),
              (override));
  MOCK_METHOD(bool,
              UpdateSemantics,
              (const FlutterSemanticsUpdate2& update),
              (override));
  MOCK_METHOD(bool, SetSemanticsEnabled, (bool enabled), (override));
  MOCK_METHOD(bool,
              DispatchSemanticsAction,
              (int32_t node_id,
               FlutterSemanticsAction action,
               const std::vector<uint8_t>& data,
               int64_t view_id),
              (override));
  MOCK_METHOD(bool, SetAccessibilityFeatures, (int32_t flags), (override));
  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));
  MOCK_METHOD(bool, OnFirstFrame, (), (override));
  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));
  MOCK_METHOD(bool,
              OnVsync,
              (int64_t frame_time_nanos, int64_t frame_target_time_nanos),
              (override));
  MOCK_METHOD(bool,
              SetViewportMetrics,
              (const AndroidViewportMetrics& metrics),
              (override));
  MOCK_METHOD(bool,
              UpdateDisplayMetrics,
              (const AndroidDisplayMetrics& metrics),
              (override));
  MOCK_METHOD(bool,
              UpdateDisplayMetrics,
              (uint64_t display_id,
               double refresh_rate,
               double width,
               double height,
               double device_pixel_ratio),
              (override));
  MOCK_METHOD(
      bool,
      DispatchViewportMetrics,
      (int64_t view_id, double width, double height, double pixel_ratio),
      (override));
  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int64_t loading_unit_id),
              (override));
  MOCK_METHOD(bool, OnAssetManagerChanged, (), (override));
  MOCK_METHOD(std::optional<DartCallbackInfo>,
              LookupCallbackInformation,
              (int64_t handle),
              (override));
  MOCK_METHOD(bool,
              DecodeImage,
              (const uint8_t* data, size_t size, int64_t generator_handle),
              (override));
  MOCK_METHOD(void,
              OnNativeImageHeader,
              (int64_t generator_handle, int32_t width, int32_t height),
              (override));
  MOCK_METHOD(std::optional<ImageHeaderInfo>,
              GetImageHeader,
              (int64_t generator_handle),
              (override));
  MOCK_METHOD(int64_t,
              CreatePlatformView,
              (const PlatformViewCreationParams& params,
               PlatformViewCompositionType composition_type),
              (override));
  MOCK_METHOD(bool, DisposePlatformView, (int64_t view_id), (override));
  MOCK_METHOD(bool,
              ResizePlatformView,
              (const PlatformViewResizeRequest& request),
              (override));
  MOCK_METHOD(bool,
              OffsetPlatformView,
              (int64_t view_id, double top, double left),
              (override));
  MOCK_METHOD(bool,
              SetPlatformViewDirection,
              (int64_t view_id, int32_t direction),
              (override));
  MOCK_METHOD(bool, ClearPlatformViewFocus, (int64_t view_id), (override));
  MOCK_METHOD(bool,
              DispatchPlatformViewTouch,
              (const PlatformViewTouch& touch),
              (override));
  MOCK_METHOD(bool,
              OnDisplayPlatformView,
              (const PlatformViewGeometry& geometry),
              (override));
  MOCK_METHOD(bool,
              OnDisplayPlatformView,
              (const FlutterPlatformView& platform_view,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height),
              (override));
  MOCK_METHOD(bool, HidePlatformView, (int64_t view_id), (override));
  MOCK_METHOD(bool,
              SynchronizeToNativeViewHierarchy,
              (bool synchronize),
              (override));
  MOCK_METHOD(bool, OnBeginFrame, (), (override));
  MOCK_METHOD(bool, OnEndFrame, (), (override));
  MOCK_METHOD(std::optional<int32_t>, CreateOverlaySurface, (), (override));
  MOCK_METHOD(bool, DestroyOverlaySurfaces, (), (override));
  MOCK_METHOD(bool,
              OnDisplayOverlaySurface,
              (const PlatformViewOverlay& overlay),
              (override));
  MOCK_METHOD(bool, ShowOverlaySurface, (int32_t surface_id), (override));
  MOCK_METHOD(bool, HideOverlaySurface, (int32_t surface_id), (override));
  MOCK_METHOD(bool, SetHcppEnabled, (bool enabled), (override));
  MOCK_METHOD(bool, CreatePlatformViewTransaction, (), (override));
  MOCK_METHOD(bool, SwapPlatformViewTransactions, (), (override));
  MOCK_METHOD(bool, ApplyPlatformViewTransactions, (), (override));
  MOCK_METHOD(bool, IsHcppEnabled, (), (const, override));
  MOCK_METHOD(bool,
              CreateSurfaceControl,
              (int64_t surface_id, const std::string& debug_name),
              (override));
  MOCK_METHOD(bool, DestroySurfaceControl, (int64_t surface_id), (override));
  MOCK_METHOD(bool,
              ReparentSurfaceControl,
              (int64_t surface_id, int64_t new_parent_id),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlGeometry,
              (int64_t surface_id,
               const AndroidSurfaceControlRect& source,
               const AndroidSurfaceControlRect& destination,
               int32_t transform),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlVisibility,
              (int64_t surface_id, bool visible),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlZOrder,
              (int64_t surface_id, int32_t z_order),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlDamageRegion,
              (int64_t surface_id,
               const std::vector<AndroidSurfaceControlRect>& rects),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlBuffer,
              (int64_t surface_id, void* buffer, int fence_fd),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlBufferAlpha,
              (int64_t surface_id, float alpha),
              (override));
  MOCK_METHOD(bool,
              SetSurfaceControlColor,
              (int64_t surface_id, float r, float g, float b, float alpha),
              (override));
  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (int64_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               const AndroidMutatorsStack& mutators_stack),
              (override));
  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (const FlutterPlatformView& platform_view,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height),
              (override));
  MOCK_METHOD(bool, InitVM, (const AndroidVMArgs& args), (override));
  MOCK_METHOD(bool, PrefetchDefaultFontManager, (), (override));
  MOCK_METHOD(bool, SetVmServiceUri, (const std::string& uri), (override));
  MOCK_METHOD(bool,
              RegisterHardwareBufferTexture,
              (int64_t texture_id),
              (override));
  MOCK_METHOD(bool,
              UnregisterHardwareBufferTexture,
              (int64_t texture_id),
              (override));
  MOCK_METHOD(bool,
              SetHardwareBufferFrame,
              (int64_t texture_id,
               const std::shared_ptr<AndroidHardwareBuffer>& buffer),
              (override));
  MOCK_METHOD(bool,
              SetHardwareBufferFrame,
              (int64_t texture_id,
               const FlutterHardwareBufferExternalTexture& texture),
              (override));
  MOCK_METHOD(bool,
              GetHardwareBufferTextureFrame,
              (int64_t texture_id,
               size_t width,
               size_t height,
               FlutterHardwareBufferExternalTexture* texture_out),
              (override));
  MOCK_METHOD(bool,
              OnHardwareBufferFrameAvailable,
              (int64_t texture_id),
              (override));
  MOCK_METHOD(bool, RegisterVulkanTexture, (int64_t texture_id), (override));
  MOCK_METHOD(bool, UnregisterVulkanTexture, (int64_t texture_id), (override));
  MOCK_METHOD(bool,
              SetVulkanTextureFrame,
              (int64_t texture_id,
               const std::shared_ptr<AndroidVulkanExternalTexture>& texture),
              (override));
  MOCK_METHOD(bool,
              SetVulkanTextureFrame,
              (int64_t texture_id, const FlutterVulkanExternalTexture& texture),
              (override));
  MOCK_METHOD(bool,
              GetVulkanTextureFrame,
              (int64_t texture_id,
               size_t width,
               size_t height,
               FlutterVulkanExternalTexture* texture_out),
              (override));
  MOCK_METHOD(bool,
              OnVulkanTextureFrameAvailable,
              (int64_t texture_id),
              (override));
};

// ---------------------------------------------------------------------------
// 1. AndroidWindowMetricsMapper Tests
// ---------------------------------------------------------------------------

TEST(AndroidWindowMetricsMapperTest, BasicViewportMetricsTranslation) {
  AndroidViewportMetrics metrics;
  metrics.view_id = 42;
  metrics.display_id = 1;
  metrics.device_pixel_ratio = 3.0;
  metrics.physical_width = 1080.0;
  metrics.physical_height = 2400.0;
  metrics.physical_padding_top = 72.0;
  metrics.physical_padding_bottom = 48.0;
  metrics.physical_view_inset_top = 0.0;
  metrics.physical_view_inset_bottom = 200.0;
  metrics.physical_view_inset_left = 0.0;
  metrics.physical_view_inset_right = 0.0;

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);

  EXPECT_EQ(event.struct_size, sizeof(FlutterWindowMetricsEvent));
  EXPECT_EQ(event.view_id, 42);
  EXPECT_EQ(event.display_id, 1u);
  EXPECT_DOUBLE_EQ(event.pixel_ratio, 3.0);
  EXPECT_EQ(event.width, 1080u);
  EXPECT_EQ(event.height, 2400u);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_top, 0.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_bottom, 200.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_left, 0.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_right, 0.0);
  EXPECT_FALSE(event.has_constraints);
  EXPECT_EQ(event.min_width_constraint, 1080u);
  EXPECT_EQ(event.max_width_constraint, 1080u);
  EXPECT_EQ(event.min_height_constraint, 2400u);
  EXPECT_EQ(event.max_height_constraint, 2400u);
}

TEST(AndroidWindowMetricsMapperTest, ConstrainedViewportMetricsTranslation) {
  AndroidViewportMetrics metrics;
  metrics.view_id = 0;
  metrics.display_id = 0;
  metrics.device_pixel_ratio = 2.0;
  metrics.physical_width = 800.0;
  metrics.physical_height = 1200.0;
  metrics.physical_min_width = 600.0;
  metrics.physical_max_width = 1000.0;
  metrics.physical_min_height = 900.0;
  metrics.physical_max_height = 1500.0;

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);

  EXPECT_TRUE(event.has_constraints);
  EXPECT_EQ(event.min_width_constraint, 600u);
  EXPECT_EQ(event.max_width_constraint, 1000u);
  EXPECT_EQ(event.min_height_constraint, 900u);
  EXPECT_EQ(event.max_height_constraint, 1500u);
  EXPECT_EQ(event.width, 800u);
  EXPECT_EQ(event.height, 1200u);
}

TEST(AndroidWindowMetricsMapperTest, InsetBoundaryClamping) {
  AndroidViewportMetrics metrics;
  metrics.physical_width = 500.0;
  metrics.physical_height = 800.0;
  metrics.physical_view_inset_top = -50.0;  // negative -> clamp to 0
  metrics.physical_view_inset_bottom =
      1200.0;  // exceeds height -> clamp to 800
  metrics.physical_view_inset_left = -10.0;
  metrics.physical_view_inset_right = 900.0;  // exceeds width -> clamp to 500

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);

  EXPECT_DOUBLE_EQ(event.physical_view_inset_top, 0.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_bottom, 800.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_left, 0.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_right, 500.0);
}

TEST(AndroidWindowMetricsMapperTest, BasicDisplayMetricsTranslation) {
  AndroidDisplayMetrics display;
  display.display_id = 5;
  display.single_display = false;
  display.refresh_rate = 120.0;
  display.width = 1440.0;
  display.height = 3120.0;
  display.device_pixel_ratio = 3.5;

  FlutterEngineDisplay engine_display =
      AndroidWindowMetricsMapper::ToFlutterEngineDisplay(display);

  EXPECT_EQ(engine_display.struct_size, sizeof(FlutterEngineDisplay));
  EXPECT_EQ(engine_display.display_id, 5u);
  EXPECT_FALSE(engine_display.single_display);
  EXPECT_DOUBLE_EQ(engine_display.refresh_rate, 120.0);
  EXPECT_EQ(engine_display.width, 1440u);
  EXPECT_EQ(engine_display.height, 3120u);
  EXPECT_DOUBLE_EQ(engine_display.device_pixel_ratio, 3.5);
}

TEST(AndroidWindowMetricsMapperTest,
     DisplayFeaturesParsingAndCutoutExtraction) {
  std::vector<double> bounds = {450.0, 0.0,    630.0,  80.0,
                                0.0,   1000.0, 1080.0, 1050.0};
  std::vector<int32_t> types = {3, 1};
  std::vector<int32_t> states = {0, 2};

  std::vector<AndroidDisplayFeature> features =
      AndroidWindowMetricsMapper::ParseDisplayFeatures(bounds, types, states);

  ASSERT_EQ(features.size(), 2u);
  EXPECT_DOUBLE_EQ(features[0].left, 450.0);
  EXPECT_DOUBLE_EQ(features[0].top, 0.0);
  EXPECT_DOUBLE_EQ(features[0].right, 630.0);
  EXPECT_DOUBLE_EQ(features[0].bottom, 80.0);
  EXPECT_EQ(features[0].type, AndroidDisplayFeatureType::kCutout);
  EXPECT_EQ(features[0].state, AndroidDisplayFeatureState::kUnknown);

  EXPECT_DOUBLE_EQ(features[1].left, 0.0);
  EXPECT_DOUBLE_EQ(features[1].top, 1000.0);
  EXPECT_DOUBLE_EQ(features[1].right, 1080.0);
  EXPECT_DOUBLE_EQ(features[1].bottom, 1050.0);
  EXPECT_EQ(features[1].type, AndroidDisplayFeatureType::kFold);
  EXPECT_EQ(features[1].state, AndroidDisplayFeatureState::kPostureHalfOpened);

  AndroidCutoutInsets cutout = AndroidWindowMetricsMapper::ExtractCutoutInsets(
      bounds, types, 1080.0, 2400.0);
  EXPECT_DOUBLE_EQ(cutout.top, 80.0);
  EXPECT_DOUBLE_EQ(cutout.bottom, 0.0);
  EXPECT_DOUBLE_EQ(cutout.left, 0.0);
  EXPECT_DOUBLE_EQ(cutout.right, 0.0);
}

TEST(AndroidWindowMetricsMapperTest, EffectiveInsetsComputation) {
  AndroidViewportMetrics metrics;
  metrics.physical_width = 1080.0;
  metrics.physical_height = 2400.0;
  metrics.physical_padding_top = 60.0;
  metrics.physical_view_inset_bottom = 300.0;
  metrics.display_features_bounds = {480.0, 0.0, 600.0, 90.0};
  metrics.display_features_type = {3};
  metrics.display_features_state = {0};

  AndroidCutoutInsets effective =
      AndroidWindowMetricsMapper::ComputeEffectiveInsets(metrics);

  EXPECT_DOUBLE_EQ(effective.top, 90.0);
  EXPECT_DOUBLE_EQ(effective.bottom, 300.0);
  EXPECT_DOUBLE_EQ(effective.left, 0.0);
  EXPECT_DOUBLE_EQ(effective.right, 0.0);
}

// ---------------------------------------------------------------------------
// 2. InMemoryWindowMetricsProvider Tests
// ---------------------------------------------------------------------------

TEST(InMemoryWindowMetricsProviderTest, SetAndRetrieveMetrics) {
  InMemoryWindowMetricsProvider provider;

  AndroidViewportMetrics viewport;
  viewport.view_id = 100;
  viewport.physical_width = 1200.0;
  viewport.physical_height = 1600.0;
  viewport.device_pixel_ratio = 2.0;

  AndroidDisplayMetrics display;
  display.display_id = 1;
  display.refresh_rate = 90.0;
  display.width = 1200.0;
  display.height = 1600.0;

  EXPECT_TRUE(provider.SendViewportMetrics(viewport));
  EXPECT_TRUE(provider.UpdateDisplayMetrics(display));

  EXPECT_EQ(provider.GetSendCount(), 1u);
  EXPECT_EQ(provider.GetUpdateCount(), 1u);

  auto retrieved_vp = provider.GetViewportMetrics(100);
  ASSERT_TRUE(retrieved_vp.has_value());
  if (retrieved_vp.has_value()) {
    EXPECT_EQ(retrieved_vp.value(), viewport);
  }

  auto retrieved_disp = provider.GetDisplayMetrics(1);
  ASSERT_TRUE(retrieved_disp.has_value());
  if (retrieved_disp.has_value()) {
    EXPECT_EQ(retrieved_disp.value(), display);
  }

  provider.Clear();
  EXPECT_EQ(provider.GetSendCount(), 0u);
  EXPECT_EQ(provider.GetUpdateCount(), 0u);
  EXPECT_FALSE(provider.GetViewportMetrics(100).has_value());
  EXPECT_FALSE(provider.GetDisplayMetrics(1).has_value());
}

TEST(InMemoryWindowMetricsProviderTest, ResultOverrides) {
  InMemoryWindowMetricsProvider provider;
  provider.SetSendResult(false);
  provider.SetUpdateResult(false);

  AndroidViewportMetrics viewport;
  AndroidDisplayMetrics display;

  EXPECT_FALSE(provider.SendViewportMetrics(viewport));
  EXPECT_FALSE(provider.UpdateDisplayMetrics(display));
}

// ---------------------------------------------------------------------------
// 3. DefaultWindowMetricsProvider Tests
// ---------------------------------------------------------------------------

TEST(DefaultWindowMetricsProviderTest, InvokesJvmMethods) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  DefaultWindowMetricsProvider provider(mock_invoker);

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onViewportMetrics", "(IDDD)V", _))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onDisplayMetrics", "(JDDDF)V", _))
      .WillOnce(Return(true));

  AndroidViewportMetrics viewport;
  viewport.view_id = 0;
  viewport.physical_width = 1080.0;
  viewport.physical_height = 1920.0;
  viewport.device_pixel_ratio = 2.5;

  AndroidDisplayMetrics display;
  display.display_id = 0;
  display.refresh_rate = 60.0;
  display.width = 1080.0;
  display.height = 1920.0;
  display.device_pixel_ratio = 2.5;

  EXPECT_TRUE(provider.SendViewportMetrics(viewport));
  EXPECT_TRUE(provider.UpdateDisplayMetrics(display));

  auto cached_vp = provider.GetViewportMetrics(0);
  ASSERT_TRUE(cached_vp.has_value());
  if (cached_vp.has_value()) {
    EXPECT_EQ(cached_vp.value(), viewport);
  }

  auto cached_disp = provider.GetDisplayMetrics(0);
  ASSERT_TRUE(cached_disp.has_value());
  if (cached_disp.has_value()) {
    EXPECT_EQ(cached_disp.value(), display);
  }
}

// ---------------------------------------------------------------------------
// 4. JniDelegate Window Metrics Tests
// ---------------------------------------------------------------------------

TEST(JniDelegateWindowMetricsTest, RoutesThroughWindowMetricsProvider) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();
  auto delegate = std::make_shared<JniDelegate>(mock_invoker, nullptr, nullptr,
                                                nullptr, in_memory_provider);

  AndroidViewportMetrics vp;
  vp.view_id = 10;
  vp.physical_width = 720.0;
  vp.physical_height = 1280.0;
  vp.device_pixel_ratio = 2.0;

  AndroidDisplayMetrics disp;
  disp.display_id = 2;
  disp.refresh_rate = 144.0;
  disp.width = 720.0;
  disp.height = 1280.0;
  disp.device_pixel_ratio = 2.0;

  EXPECT_TRUE(delegate->SetViewportMetrics(vp));
  EXPECT_TRUE(delegate->UpdateDisplayMetrics(disp));

  EXPECT_EQ(in_memory_provider->GetSendCount(), 1u);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 1u);

  EXPECT_EQ(delegate->GetViewportMetrics(10), vp);
  EXPECT_EQ(delegate->GetDisplayMetrics(2), disp);

  EXPECT_TRUE(delegate->UpdateDisplayMetrics(3, 90.0, 800.0, 1200.0, 1.5));
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 2u);

  EXPECT_TRUE(delegate->DispatchViewportMetrics(0, 1080.0, 1920.0, 3.0));
  EXPECT_EQ(in_memory_provider->GetSendCount(), 2u);
}

// ---------------------------------------------------------------------------
// 5. JniRouter Routing Flip Tests
// ---------------------------------------------------------------------------

TEST(JniRouterWindowMetricsTest, RoutingFlipLegacyAndEmbedder) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();
  auto embedder_delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, in_memory_provider);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegateForMetrics>();

  JniRouter router(embedder_delegate, legacy_delegate);

  AndroidViewportMetrics vp;
  vp.view_id = 1;
  vp.physical_width = 1080.0;
  vp.physical_height = 2400.0;
  vp.device_pixel_ratio = 2.75;

  AndroidDisplayMetrics disp;
  disp.display_id = 1;
  disp.refresh_rate = 120.0;
  disp.width = 1080.0;
  disp.height = 2400.0;
  disp.device_pixel_ratio = 2.75;

  // 1. Rollout flag disabled -> legacy path
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, SetViewportMetrics(vp)).WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate, UpdateDisplayMetrics(disp))
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate,
              UpdateDisplayMetrics(1, 120.0, 1080.0, 2400.0, 2.75))
      .WillOnce(Return(true));
  EXPECT_CALL(*legacy_delegate,
              DispatchViewportMetrics(1, 1080.0, 2400.0, 2.75))
      .WillOnce(Return(true));

  EXPECT_TRUE(router.RouteSetViewportMetrics(vp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(disp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(1, 120.0, 1080.0, 2400.0, 2.75));
  EXPECT_TRUE(router.RouteViewportMetrics(1, 1080.0, 2400.0, 2.75));

  // 2. Rollout flag enabled -> embedder path
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_EQ(router.GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  EXPECT_TRUE(router.RouteSetViewportMetrics(vp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(disp));
  EXPECT_TRUE(router.RouteUpdateDisplayMetrics(1, 120.0, 1080.0, 2400.0, 2.75));
  EXPECT_TRUE(router.RouteViewportMetrics(1, 1080.0, 2400.0, 2.75));

  EXPECT_EQ(in_memory_provider->GetSendCount(), 2u);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 2u);

  JniRouter::SetEmbedderEnabled(false);
}

// ---------------------------------------------------------------------------
// 6. FlutterEmbedderNative Window Metrics Translation & Integration Tests
// ---------------------------------------------------------------------------

TEST(FlutterEmbedderNativeWindowMetricsTest, FullSubsystemIntegration) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();

  FlutterEmbedderNative native(mock_invoker, nullptr, nullptr, nullptr, nullptr,
                               nullptr, nullptr, nullptr, in_memory_provider);

  AndroidViewportMetrics vp;
  vp.view_id = 5;
  vp.physical_width = 1200.0;
  vp.physical_height = 2000.0;
  vp.device_pixel_ratio = 2.0;

  AndroidDisplayMetrics disp;
  disp.display_id = 0;
  disp.refresh_rate = 60.0;
  disp.width = 1200.0;
  disp.height = 2000.0;
  disp.device_pixel_ratio = 2.0;

  FlutterWindowMetricsEvent c_event = native.TranslateViewportMetrics(vp);
  EXPECT_EQ(c_event.width, 1200u);
  EXPECT_EQ(c_event.height, 2000u);
  EXPECT_DOUBLE_EQ(c_event.pixel_ratio, 2.0);
  EXPECT_EQ(c_event.view_id, 5);

  FlutterEngineDisplay c_disp = native.TranslateDisplayMetrics(disp);
  EXPECT_EQ(c_disp.width, 1200u);
  EXPECT_EQ(c_disp.height, 2000u);
  EXPECT_DOUBLE_EQ(c_disp.refresh_rate, 60.0);

  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_TRUE(native.SetViewportMetrics(vp));
  EXPECT_TRUE(native.UpdateDisplayMetrics(disp));
  EXPECT_TRUE(native.UpdateDisplayMetrics(0, 90.0, 1200.0, 2000.0, 2.0));

  EXPECT_EQ(in_memory_provider->GetSendCount(), 1u);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(), 2u);

  EXPECT_EQ(native.SendWindowMetricsEvent(nullptr, &c_event),
            kInvalidArguments);
  EXPECT_EQ(native.SendWindowMetricsEvent(nullptr, vp), kInvalidArguments);
  EXPECT_EQ(native.NotifyDisplayUpdate(
                nullptr, kFlutterEngineDisplaysUpdateTypeStartup, &c_disp, 1),
            kInvalidArguments);
  EXPECT_EQ(native.NotifyDisplayUpdate(nullptr, disp), kInvalidArguments);

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

// ---------------------------------------------------------------------------
// 7. Multithreaded Concurrency Tests
// ---------------------------------------------------------------------------

TEST(FlutterEmbedderNativeWindowMetricsTest, MultithreadedConcurrentMetrics) {
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();
  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterationsPerThread = 50;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);
  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&, t]() {
      for (size_t i = 0; i < kIterationsPerThread; ++i) {
        AndroidViewportMetrics vp;
        vp.view_id = static_cast<int64_t>(t);
        vp.physical_width = 1000.0 + i;
        vp.physical_height = 2000.0 + i;
        vp.device_pixel_ratio = 2.0;
        in_memory_provider->SendViewportMetrics(vp);

        AndroidDisplayMetrics disp;
        disp.display_id = t;
        disp.refresh_rate = 60.0 + (i % 60);
        disp.width = 1000.0 + i;
        disp.height = 2000.0 + i;
        disp.device_pixel_ratio = 2.0;
        in_memory_provider->UpdateDisplayMetrics(disp);

        auto check_vp = in_memory_provider->GetViewportMetrics(t);
        EXPECT_TRUE(check_vp.has_value());
        auto check_disp = in_memory_provider->GetDisplayMetrics(t);
        EXPECT_TRUE(check_disp.has_value());
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(in_memory_provider->GetSendCount(),
            kThreadCount * kIterationsPerThread);
  EXPECT_EQ(in_memory_provider->GetUpdateCount(),
            kThreadCount * kIterationsPerThread);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
