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
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
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

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));
  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));
  MOCK_METHOD(bool, OnFirstFrame, (), (override));
  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));
  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));

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

  MOCK_METHOD(bool,
              DecodeImage,
              (const uint8_t* data, size_t size, int64_t generator_handle),
              (override));

  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (int64_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height,
               const std::vector<uint8_t>& payload),
              (override));
};

class MockLegacyJniDelegateForMetrics : public LegacyJniDelegate {
 public:
  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
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

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));
  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

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
              (int loading_unit_id),
              (override));
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
              (int64_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height,
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
  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (const FlutterPlatformView& platform_view,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height),
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

  MOCK_METHOD(int64_t,
              SpawnEngine,
              (int64_t parent_engine_id, const AndroidEngineSpawnArgs& args),
              (override));

  MOCK_METHOD(bool, ShutdownSpawnedEngine, (int64_t engine_id), (override));

  MOCK_METHOD(size_t, GetActiveEngineCount, (), (const, override));

  MOCK_METHOD(bool, OnEngineGarbageCollected, (int64_t engine_id), (override));
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

TEST(AndroidWindowMetricsMapperTest, CutoutInsetsCornerAndMalformedBounds) {
  // Corner top-left cutout (height 80 > width 40 -> insets.top selected)
  std::vector<double> corner_tl = {0.0, 0.0, 40.0, 80.0};
  std::vector<int32_t> types = {3};
  AndroidCutoutInsets cutout = AndroidWindowMetricsMapper::ExtractCutoutInsets(
      corner_tl, types, 1080.0, 2400.0);
  EXPECT_DOUBLE_EQ(cutout.top, 80.0);
  EXPECT_DOUBLE_EQ(cutout.left, 0.0);

  // Inverted bounds (left > right or top > bottom) -> rejected
  std::vector<double> malformed = {100.0, 0.0, 50.0, 80.0};
  AndroidCutoutInsets malformed_cutout =
      AndroidWindowMetricsMapper::ExtractCutoutInsets(malformed, types, 1080.0,
                                                      2400.0);
  EXPECT_DOUBLE_EQ(malformed_cutout.top, 0.0);
  EXPECT_DOUBLE_EQ(malformed_cutout.left, 0.0);

  // Non-cutout display feature (fold = type 1) -> ignored for cutout insets
  std::vector<int32_t> fold_type = {1};
  AndroidCutoutInsets fold_cutout =
      AndroidWindowMetricsMapper::ExtractCutoutInsets(corner_tl, fold_type,
                                                      1080.0, 2400.0);
  EXPECT_DOUBLE_EQ(fold_cutout.top, 0.0);
  EXPECT_DOUBLE_EQ(fold_cutout.left, 0.0);
}

TEST(AndroidWindowMetricsMapperTest, SafeDimensionLargeValueClamping) {
  AndroidViewportMetrics metrics;
  metrics.physical_width = 1e300;
  metrics.physical_height = 1e20;
  metrics.physical_min_width = 1e300;
  metrics.physical_max_width = 1e300;
  metrics.physical_min_height = 1e300;
  metrics.physical_max_height = 1e300;

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);
  EXPECT_EQ(event.width, 65536u);
  EXPECT_EQ(event.height, 65536u);
  EXPECT_EQ(event.min_width_constraint, 65536u);
  EXPECT_EQ(event.max_width_constraint, 65536u);
  EXPECT_EQ(event.min_height_constraint, 65536u);
  EXPECT_EQ(event.max_height_constraint, 65536u);
}

TEST(AndroidWindowMetricsMapperTest, UnconstrainedMinConstraintPreserved) {
  AndroidViewportMetrics metrics;
  metrics.physical_width = 800.0;
  metrics.physical_height = 600.0;
  metrics.physical_min_width = 0.0;
  metrics.physical_max_width = 1200.0;
  metrics.physical_min_height = 0.0;
  metrics.physical_max_height = 900.0;

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);
  EXPECT_TRUE(event.has_constraints);
  EXPECT_EQ(event.width, 800u);
  EXPECT_EQ(event.height, 600u);
  EXPECT_EQ(event.min_width_constraint, 0u);
  EXPECT_EQ(event.max_width_constraint, 1200u);
  EXPECT_EQ(event.min_height_constraint, 0u);
  EXPECT_EQ(event.max_height_constraint, 900u);
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

  PackedViewportMetrics expected_vp_payload = {
      viewport.view_id,
      viewport.physical_width,
      viewport.physical_height,
      viewport.device_pixel_ratio,
  };
  std::vector<uint8_t> expected_vp_bytes(sizeof(PackedViewportMetrics));
  std::memcpy(expected_vp_bytes.data(), &expected_vp_payload,
              sizeof(PackedViewportMetrics));

  PackedDisplayMetrics expected_disp_payload = {
      static_cast<int64_t>(display.display_id),
      display.refresh_rate,
      display.width,
      display.height,
      display.device_pixel_ratio,
  };
  std::vector<uint8_t> expected_disp_bytes(sizeof(PackedDisplayMetrics));
  std::memcpy(expected_disp_bytes.data(), &expected_disp_payload,
              sizeof(PackedDisplayMetrics));

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onViewportMetrics", "(JDDD)V",
                                              expected_vp_bytes))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onDisplayMetrics", "(JDDDD)V",
                                              expected_disp_bytes))
      .WillOnce(Return(true));

  bool vp_callback_called = false;
  provider.SetMetricsCallback([&](const AndroidViewportMetrics& m) {
    vp_callback_called = true;
    EXPECT_EQ(m.view_id, 0);
    return true;
  });

  bool disp_callback_called = false;
  provider.SetDisplayUpdateCallback([&](const AndroidDisplayMetrics& d) {
    disp_callback_called = true;
    EXPECT_EQ(d.display_id, 0u);
    return true;
  });

  EXPECT_TRUE(provider.SendViewportMetrics(viewport));
  EXPECT_TRUE(provider.UpdateDisplayMetrics(display));

  EXPECT_TRUE(vp_callback_called);
  EXPECT_TRUE(disp_callback_called);

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

TEST(JniDelegateWindowMetricsTest, ConcurrentProviderReplacement) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  auto delegate = std::make_shared<JniDelegate>(mock_invoker, nullptr, nullptr,
                                                nullptr, nullptr, nullptr);

  std::atomic<bool> running{true};
  std::vector<std::thread> threads;

  // Thread 1 & 2: Sending metrics
  for (int i = 0; i < 2; ++i) {
    threads.emplace_back([&]() {
      AndroidViewportMetrics vp;
      vp.view_id = 42;
      vp.physical_width = 1080.0;
      vp.physical_height = 1920.0;
      vp.device_pixel_ratio = 2.0;

      AndroidDisplayMetrics disp;
      disp.display_id = 0;
      disp.width = 1080.0;
      disp.height = 1920.0;

      while (running.load()) {
        delegate->SetViewportMetrics(vp);
        delegate->UpdateDisplayMetrics(disp);
        delegate->GetViewportMetrics(42);
        delegate->GetDisplayMetrics(0);
      }
    });
  }

  // Thread 3: Swapping providers
  threads.emplace_back([&]() {
    for (int i = 0; i < 200; ++i) {
      if (i % 2 == 0) {
        delegate->SetWindowMetricsProvider(
            std::make_shared<InMemoryWindowMetricsProvider>());
      } else {
        delegate->SetWindowMetricsProvider(
            std::make_shared<DefaultWindowMetricsProvider>(mock_invoker));
      }
      std::this_thread::yield();
    }
    running.store(false);
  });

  for (auto& t : threads) {
    t.join();
  }
}

// ---------------------------------------------------------------------------
// 4. JniDelegate Window Metrics Tests
// ---------------------------------------------------------------------------

TEST(JniDelegateWindowMetricsTest, RoutesThroughWindowMetricsProvider) {
  auto mock_invoker = std::make_shared<MockJvmInvokerForMetrics>();
  auto in_memory_provider = std::make_shared<InMemoryWindowMetricsProvider>();
  auto delegate = std::make_shared<JniDelegate>(
      mock_invoker, nullptr, nullptr, nullptr, nullptr, in_memory_provider);

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
      mock_invoker, nullptr, nullptr, nullptr, nullptr, in_memory_provider);
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

TEST(AndroidWindowMetricsMapperTest, NaNAndInfiniteValuesHandledSafely) {
  AndroidViewportMetrics vp;
  vp.physical_width = std::numeric_limits<double>::quiet_NaN();
  vp.physical_height = std::numeric_limits<double>::infinity();
  vp.device_pixel_ratio = -2.0;
  vp.physical_view_inset_top = std::numeric_limits<double>::quiet_NaN();
  vp.physical_min_width = std::numeric_limits<double>::quiet_NaN();

  FlutterWindowMetricsEvent event =
      AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(vp);
  EXPECT_EQ(event.width, 0u);
  EXPECT_EQ(event.height, 0u);
  EXPECT_DOUBLE_EQ(event.pixel_ratio, 1.0);
  EXPECT_DOUBLE_EQ(event.physical_view_inset_top, 0.0);
  EXPECT_FALSE(event.has_constraints);

  AndroidDisplayMetrics disp;
  disp.refresh_rate = std::numeric_limits<double>::quiet_NaN();
  disp.width = std::numeric_limits<double>::quiet_NaN();
  disp.height = -100.0;
  disp.device_pixel_ratio = std::numeric_limits<double>::infinity();

  FlutterEngineDisplay engine_disp =
      AndroidWindowMetricsMapper::ToFlutterEngineDisplay(disp);
  EXPECT_DOUBLE_EQ(engine_disp.refresh_rate, 60.0);
  EXPECT_EQ(engine_disp.width, 0u);
  EXPECT_EQ(engine_disp.height, 0u);
  EXPECT_DOUBLE_EQ(engine_disp.device_pixel_ratio, 1.0);
}

TEST(AndroidWindowMetricsMapperTest, OperatorEqualsWithNaN) {
  AndroidViewportMetrics vp1;
  vp1.physical_width = std::numeric_limits<double>::quiet_NaN();
  AndroidViewportMetrics vp2;
  vp2.physical_width = std::numeric_limits<double>::quiet_NaN();

  EXPECT_TRUE(vp1 == vp2);
  EXPECT_TRUE(vp1 == vp1);

  vp2.physical_width = 100.0;
  EXPECT_FALSE(vp1 == vp2);
}

TEST(AndroidWindowMetricsMapperTest, ParseDisplayFeaturesCeiling) {
  std::vector<double> bounds(2000, 10.0);  // 500 features > 256 ceiling
  std::vector<int32_t> types(500, 1);
  std::vector<int32_t> states(500, 1);

  auto features =
      AndroidWindowMetricsMapper::ParseDisplayFeatures(bounds, types, states);
  EXPECT_EQ(features.size(), 256u);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
