// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/external_view_embedder/image_layer_pool.h"

#include <cstdint>
#include <functional>
#include <memory>
#include <utility>
#include <vector>

#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/surface/android_surface_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

using ::testing::_;
using ::testing::ByMove;
using ::testing::Return;

constexpr int32_t kInitialWidthPx = 400;
constexpr int32_t kInitialHeightPx = 800;
constexpr int32_t kResizedWidthPx = 800;
constexpr int32_t kResizedHeightPx = 400;
constexpr intptr_t kReaderTokenBase = 0x1000;
constexpr intptr_t kImageTokenBase = 0x2000;
constexpr intptr_t kFakeGrContextKeyA = 0x3000;
constexpr intptr_t kFakeGrContextKeyB = 0x4000;

class MockGpuSurface : public Surface {
 public:
  MOCK_METHOD(bool, IsValid, (), (override));
  MOCK_METHOD(std::unique_ptr<SurfaceFrame>,
              AcquireFrame,
              (const DlISize& size),
              (override));
  MOCK_METHOD(DlMatrix, GetRootTransformation, (), (const, override));
  MOCK_METHOD(GrDirectContext*, GetContext, (), (override));
  MOCK_METHOD(std::unique_ptr<GLContextResult>,
              MakeRenderContextCurrent,
              (),
              (override));
};

class CallbackAndroidSurfaceFactory final : public AndroidSurfaceFactory {
 public:
  explicit CallbackAndroidSurfaceFactory(
      std::function<std::unique_ptr<AndroidSurface>()> factory_fn)
      : factory_fn_(std::move(factory_fn)) {}

  std::unique_ptr<AndroidSurface> CreateSurface() override {
    return factory_fn_();
  }

 private:
  std::function<std::unique_ptr<AndroidSurface>()> factory_fn_;
};

std::unique_ptr<AndroidSurfaceMock> MakeValidAndroidSurfaceMock(
    int expected_gpu_surfaces = 1) {
  auto android_surface = std::make_unique<AndroidSurfaceMock>();
  EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*android_surface, SetNativeWindow(_, _)).WillOnce(Return(true));
  EXPECT_CALL(*android_surface, CreateGPUSurface(_))
      .Times(expected_gpu_surfaces)
      .WillRepeatedly([] {
        auto gpu_surface = std::make_unique<MockGpuSurface>();
        EXPECT_CALL(*gpu_surface, IsValid()).WillRepeatedly(Return(true));
        return gpu_surface;
      });
  return android_surface;
}

}  // namespace

TEST(ImageLayerPoolTest, RejectsNonPositiveDimensionsWithoutAllocating) {
  auto jni_mock = std::make_shared<JNIMock>();
  bool surface_created = false;
  auto surface_factory = std::make_shared<CallbackAndroidSurfaceFactory>([&] {
    surface_created = true;
    return MakeValidAndroidSurfaceMock();
  });

  EXPECT_CALL(*jni_mock, CreateHybridImageReader(_, _)).Times(0);

  ImageLayerPool pool;
  EXPECT_EQ(pool.GetOrCreateBackgroundLayer(DlISize(0, kInitialHeightPx),
                                            nullptr, jni_mock, surface_factory),
            nullptr);
  EXPECT_EQ(pool.GetOrCreateBackgroundLayer(DlISize(-1, kInitialHeightPx),
                                            nullptr, jni_mock, surface_factory),
            nullptr);
  EXPECT_EQ(pool.GetOrCreateOverlayLayer(0, DlISize(kInitialWidthPx, 0),
                                         nullptr, jni_mock, surface_factory),
            nullptr);
  EXPECT_FALSE(surface_created);
  EXPECT_FALSE(pool.HasLayers());
}

TEST(ImageLayerPoolTest,
     ReusesMatchingLayersAndRetiresUnusedOverlaysAndDestructorLayers) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto surface_factory = std::make_shared<CallbackAndroidSurfaceFactory>(
      [] { return MakeValidAndroidSurfaceMock(); });

  intptr_t next_reader_token = kReaderTokenBase;
  EXPECT_CALL(*jni_mock,
              CreateHybridImageReader(kInitialWidthPx, kInitialHeightPx))
      .Times(3)
      .WillRepeatedly([&](int32_t, int32_t) {
        return std::make_unique<
            PlatformViewAndroidJNI::HybridImageReaderMetadata>(
            HybridJavaGlobalRef::ForTest(next_reader_token++), window);
      });

  std::vector<intptr_t> retired_tokens;
  EXPECT_CALL(*jni_mock, RetireHybridImageReader(_))
      .WillRepeatedly([&](HybridJavaGlobalRef reader) {
        retired_tokens.push_back(reader.token());
      });

  const DlISize size(kInitialWidthPx, kInitialHeightPx);
  {
    ImageLayerPool pool;
    bool destroyed = false;
    ImageLayer* bg1 = pool.GetOrCreateBackgroundLayer(
        size, nullptr, jni_mock, surface_factory, &destroyed);
    ASSERT_NE(bg1, nullptr);
    EXPECT_FALSE(destroyed);
    EXPECT_EQ(bg1->id, ImageLayer::kBackgroundLayerId);

    // Second request at the same size reuses the exact same ImageLayer.
    ImageLayer* bg2 = pool.GetOrCreateBackgroundLayer(
        size, nullptr, jni_mock, surface_factory, &destroyed);
    EXPECT_EQ(bg1, bg2);
    EXPECT_FALSE(destroyed);

    ImageLayer* ov0 = pool.GetOrCreateOverlayLayer(0, size, nullptr, jni_mock,
                                                   surface_factory, &destroyed);
    ImageLayer* ov1 = pool.GetOrCreateOverlayLayer(1, size, nullptr, jni_mock,
                                                   surface_factory, &destroyed);
    ASSERT_NE(ov0, nullptr);
    ASSERT_NE(ov1, nullptr);
    EXPECT_EQ(ov0->id, 0);
    EXPECT_EQ(ov1->id, 1);
    EXPECT_EQ(pool.OverlayLayerCount(), 2u);

    // Trimming down to 1 active overlay immediately retires overlay 1's reader.
    EXPECT_TRUE(pool.RecycleAndTrimUnusedOverlays(/*used_overlay_count=*/1));
    EXPECT_EQ(pool.OverlayLayerCount(), 1u);
    ASSERT_EQ(retired_tokens.size(), 1u);
    EXPECT_EQ(retired_tokens[0], kReaderTokenBase + 2);
  }

  // ~ImageLayerPool() retires both the background reader and overlay 0 reader.
  ASSERT_EQ(retired_tokens.size(), 3u);
}

TEST(ImageLayerPoolTest,
     ResizeAndGrContextChangeRecreateLayersAndDeferRetireWhileHandleShared) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  int surface_allocations = 0;
  auto surface_factory = std::make_shared<CallbackAndroidSurfaceFactory>([&] {
    ++surface_allocations;
    // First AndroidSurface creates 2 GPU surfaces (initial + GrContext swap);
    // resized AndroidSurface creates 1 GPU surface.
    return MakeValidAndroidSurfaceMock(surface_allocations == 1 ? 2 : 1);
  });

  intptr_t next_reader_token = kReaderTokenBase;
  EXPECT_CALL(*jni_mock, CreateHybridImageReader(_, _))
      .Times(2)
      .WillRepeatedly([&](int32_t, int32_t) {
        return std::make_unique<
            PlatformViewAndroidJNI::HybridImageReaderMetadata>(
            HybridJavaGlobalRef::ForTest(next_reader_token++), window);
      });

  std::vector<intptr_t> events;
  EXPECT_CALL(*jni_mock, ReleaseHybridImage(_, _))
      .WillOnce(
          [&](const HybridJavaGlobalRef& reader, HybridJavaGlobalRef image) {
            EXPECT_EQ(reader.token(), kReaderTokenBase);
            events.push_back(image.token());
          });
  EXPECT_CALL(*jni_mock, RetireHybridImageReader(_))
      .WillRepeatedly([&](HybridJavaGlobalRef reader) {
        events.push_back(reader.token());
      });

  ImageLayerPool pool;
  const DlISize initial_size(kInitialWidthPx, kInitialHeightPx);
  const DlISize resized_size(kResizedWidthPx, kResizedHeightPx);

  auto* gr_a = reinterpret_cast<GrDirectContext*>(kFakeGrContextKeyA);
  auto* gr_b = reinterpret_cast<GrDirectContext*>(kFakeGrContextKeyB);

  bool destroyed = false;
  ImageLayer* layer_a = pool.GetOrCreateBackgroundLayer(
      initial_size, gr_a, jni_mock, surface_factory, &destroyed);
  ASSERT_NE(layer_a, nullptr);
  EXPECT_FALSE(destroyed);

  // Changing GrContext recreates the GPU surface in-place without retiring the
  // HybridImageReader.
  ImageLayer* layer_b = pool.GetOrCreateBackgroundLayer(
      initial_size, gr_b, jni_mock, surface_factory, &destroyed);
  ASSERT_EQ(layer_a, layer_b);
  EXPECT_TRUE(destroyed);
  EXPECT_TRUE(events.empty());

  // Simulate an in-flight packet holding `reader_handle` across a pool resize.
  std::shared_ptr<HybridReaderHandle> in_flight_handle = layer_b->reader_handle;
  ImageLayer* resized_layer = pool.GetOrCreateBackgroundLayer(
      resized_size, gr_b, jni_mock, surface_factory, &destroyed);
  ASSERT_NE(resized_layer, nullptr);
  EXPECT_TRUE(destroyed);
  // First reader is NOT retired yet because `in_flight_handle` is still live.
  EXPECT_TRUE(events.empty());

  // Releasing the image and dropping `in_flight_handle` releases the image
  // BEFORE retiring the first reader.
  in_flight_handle->ReleaseImage(HybridJavaGlobalRef::ForTest(kImageTokenBase));
  in_flight_handle.reset();
  ASSERT_EQ(events.size(), 2u);
  EXPECT_EQ(events[0], kImageTokenBase);
  EXPECT_EQ(events[1], kReaderTokenBase);
}

TEST(ImageLayerPoolTest, RetiresReaderImmediatelyWhenSetNativeWindowFails) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto surface_factory = std::make_shared<CallbackAndroidSurfaceFactory>([] {
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    EXPECT_CALL(*android_surface, IsValid()).WillOnce(Return(true));
    EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
        .WillOnce(Return(false));
    return android_surface;
  });

  EXPECT_CALL(*jni_mock,
              CreateHybridImageReader(kInitialWidthPx, kInitialHeightPx))
      .WillOnce([&](int32_t, int32_t) {
        return std::make_unique<
            PlatformViewAndroidJNI::HybridImageReaderMetadata>(
            HybridJavaGlobalRef::ForTest(kReaderTokenBase), window);
      });
  EXPECT_CALL(*jni_mock, RetireHybridImageReader(_))
      .WillOnce([](HybridJavaGlobalRef reader) {
        EXPECT_EQ(reader.token(), kReaderTokenBase);
      });

  ImageLayerPool pool;
  EXPECT_EQ(pool.GetOrCreateBackgroundLayer(
                DlISize(kInitialWidthPx, kInitialHeightPx), nullptr, jni_mock,
                surface_factory),
            nullptr);
  EXPECT_FALSE(pool.HasLayers());
}

}  // namespace testing
}  // namespace flutter
