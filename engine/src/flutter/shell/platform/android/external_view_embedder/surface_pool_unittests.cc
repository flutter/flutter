// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/shell/platform/android/external_view_embedder/surface_pool.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/surface/android_surface_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::ByMove;
using ::testing::ElementsAre;
using ::testing::Return;

class TestSurface : public Surface {
 public:
  bool IsValid() override { return true; }
  std::unique_ptr<SurfaceFrame> AcquireFrame(const DlISize& size) override {
    return nullptr;
  }
  DlMatrix GetRootTransformation() const override { return DlMatrix(); }
  GrDirectContext* GetContext() override { return nullptr; }
};

class TestAndroidSurfaceFactory : public AndroidSurfaceFactory {
 public:
  using TestSurfaceProducer =
      std::function<std::unique_ptr<AndroidSurface>(void)>;
  explicit TestAndroidSurfaceFactory(TestSurfaceProducer&& surface_producer) {
    surface_producer_ = surface_producer;
  }

  ~TestAndroidSurfaceFactory() override = default;

  std::unique_ptr<AndroidSurface> CreateSurface() override {
    return surface_producer_();
  }

 private:
  TestSurfaceProducer surface_producer_;
};

TEST(SurfacePool, GetLayerAllocateOneLayer) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                              surface_factory);

  ASSERT_TRUE(pool->HasLayers());
  ASSERT_NE(nullptr, layer);
  ASSERT_EQ(reinterpret_cast<intptr_t>(gr_context.get()),
            layer->gr_context_key);
}

TEST(SurfacePool, GetUnusedLayers) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                              surface_factory);
  ASSERT_EQ(0UL, pool->GetUnusedLayers().size());

  pool->RecycleLayers();

  ASSERT_TRUE(pool->HasLayers());
  ASSERT_EQ(1UL, pool->GetUnusedLayers().size());
  ASSERT_EQ(layer, pool->GetUnusedLayers()[0]);
}

TEST(SurfacePool, GetLayerRecycle) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);

  auto gr_context_1 = GrDirectContext::MakeMock(nullptr);
  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto gr_context_2 = GrDirectContext::MakeMock(nullptr);
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context_1, gr_context_2, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        // Allocate two GPU surfaces for each gr context.
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_2.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        // Set the native window once.
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer_1 = pool->GetLayer(gr_context_1.get(), *android_context, jni_mock,
                                surface_factory);

  pool->RecycleLayers();

  auto layer_2 = pool->GetLayer(gr_context_2.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_TRUE(pool->HasLayers());
  ASSERT_NE(nullptr, layer_1);
  ASSERT_EQ(layer_1, layer_2);
  ASSERT_EQ(reinterpret_cast<intptr_t>(gr_context_2.get()),
            layer_1->gr_context_key);
  ASSERT_EQ(reinterpret_cast<intptr_t>(gr_context_2.get()),
            layer_2->gr_context_key);
}

TEST(SurfacePool, GetLayerAllocateTwoLayers) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto jni_mock = std::make_shared<JNIMock>();
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .Times(2)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              1, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer_1 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);
  auto layer_2 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_TRUE(pool->HasLayers());
  ASSERT_NE(nullptr, layer_1);
  ASSERT_NE(nullptr, layer_2);
  ASSERT_NE(layer_1, layer_2);
  ASSERT_EQ(0, layer_1->id);
  ASSERT_EQ(1, layer_2->id);
}

TEST(SurfacePool, DestroyLayersNew) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true);
  auto jni_mock = std::make_shared<JNIMock>();

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(0);
  pool->DestroyLayers(jni_mock);

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2());

  ASSERT_TRUE(pool->HasLayers());
  pool->DestroyLayers(jni_mock);

  ASSERT_FALSE(pool->HasLayers());
  ASSERT_TRUE(pool->GetUnusedLayers().empty());
}

TEST(SurfacePool, DestroyLayers) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  pool->DestroyLayers(jni_mock);

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces());

  ASSERT_TRUE(pool->HasLayers());
  pool->DestroyLayers(jni_mock);

  ASSERT_FALSE(pool->HasLayers());
  ASSERT_TRUE(pool->GetUnusedLayers().empty());
}

TEST(SurfacePool, TakeLayers) {
  constexpr int kFirstOverlayId = 0;
  constexpr int kSecondOverlayId = 1;
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  EXPECT_FALSE(pool->HasPendingDestroy());
  EXPECT_TRUE(pool->TakeLayers().empty());
  EXPECT_FALSE(pool->HasPendingDestroy());

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kFirstOverlayId, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                              surface_factory);

  // Taking the layers retires their IDs for asynchronous destruction on the
  // platform thread without calling JNI synchronously.
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  std::vector<std::shared_ptr<OverlayLayer>> layers = pool->TakeLayers();

  ASSERT_EQ(1UL, layers.size());
  EXPECT_EQ(layer, layers[0]);
  EXPECT_FALSE(pool->HasLayers());
  EXPECT_TRUE(pool->HasPendingDestroy());
  EXPECT_TRUE(pool->GetUnusedLayers().empty());

  // Destroying pending layers flushes by ID once and becomes a no-op
  // thereafter.
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(
                             std::vector<int32_t>{kFirstOverlayId}))
      .Times(1);
  pool->DestroyPendingLayers(jni_mock);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyPendingLayers(jni_mock);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // If GetLayer runs before DestroyPendingLayers, GetLayer never calls JNI
  // destroy inline; the caller drains TakeRetiredLayerIds() (X9).
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kFirstOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  ASSERT_TRUE(pool->HasPendingDestroy());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(0, 0))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kSecondOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  EXPECT_TRUE(pool->HasPendingDestroy());
  EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(kFirstOverlayId));
  EXPECT_FALSE(pool->HasPendingDestroy());
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // If DestroyLayers runs while layers_ is empty and retired_layer_ids_ is
  // non-empty (for example, during Teardown), it flushes once.
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  EXPECT_FALSE(pool->HasLayers());
  EXPECT_TRUE(pool->HasPendingDestroy());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  pool->DestroyLayers(jni_mock);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyLayers(jni_mock);
  pool->DestroyPendingLayers(jni_mock);
}

TEST(SurfacePool, GetLayerRetiresOldLayersOnResizeWithoutCallingJNIDestroy) {
  constexpr int kStaleOverlayId = 0;
  constexpr int kFirstNewOverlayId = 1;
  constexpr int kSecondNewOverlayId = 2;
  constexpr int kInitialSizePx = 100;
  constexpr int kResizedSizePx = 200;

  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });

  pool->SetFrameSize(DlISize(kInitialSizePx, kInitialSizePx));
  EXPECT_CALL(*jni_mock,
              FlutterViewCreateOverlaySurface(kInitialSizePx, kInitialSizePx))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kStaleOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  pool->SetFrameSize(DlISize(kResizedSizePx, kResizedSizePx));
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  ASSERT_TRUE(pool->HasPendingDestroy());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  EXPECT_CALL(*jni_mock,
              FlutterViewCreateOverlaySurface(kResizedSizePx, kResizedSizePx))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kFirstNewOverlayId, window))))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kSecondNewOverlayId, window))));
  auto layer_1 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);
  auto layer_2 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_NE(nullptr, layer_1);
  ASSERT_NE(nullptr, layer_2);
  EXPECT_NE(layer_1, layer_2);
  EXPECT_EQ(kFirstNewOverlayId, layer_1->id);
  EXPECT_EQ(kSecondNewOverlayId, layer_2->id);
  EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(kStaleOverlayId));
  EXPECT_FALSE(pool->HasPendingDestroy());
  EXPECT_TRUE(pool->HasLayers());
}

TEST(SurfacePool,
     TakeLayersPreservesPendingDestroyAcrossResizeBackToOriginalSize) {
  constexpr int kStaleOverlayId = 0;
  constexpr int kReplacementOverlayId = 1;
  constexpr int kOriginalSizePx = 100;
  constexpr int kIntermediateSizePx = 200;

  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });

  pool->SetFrameSize(DlISize(kOriginalSizePx, kOriginalSizePx));
  EXPECT_CALL(*jni_mock,
              FlutterViewCreateOverlaySurface(kOriginalSizePx, kOriginalSizePx))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kStaleOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  pool->SetFrameSize(DlISize(kIntermediateSizePx, kIntermediateSizePx));
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  EXPECT_TRUE(pool->HasPendingDestroy());

  pool->SetFrameSize(DlISize(kOriginalSizePx, kOriginalSizePx));
  EXPECT_TRUE(pool->TakeLayers().empty());
  EXPECT_TRUE(pool->HasPendingDestroy());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock,
              FlutterViewCreateOverlaySurface(kOriginalSizePx, kOriginalSizePx))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kReplacementOverlayId, window))));
  auto replacement = pool->GetLayer(gr_context.get(), *android_context,
                                    jni_mock, surface_factory);
  ASSERT_NE(nullptr, replacement);
  EXPECT_EQ(kReplacementOverlayId, replacement->id);
  EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(kStaleOverlayId));
  EXPECT_FALSE(pool->HasPendingDestroy());
}

TEST(SurfacePool, RetireLayersWhenFrameSizeChanged) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  pool->SetFrameSize(DlISize(10, 10));
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(10, 10))
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  ASSERT_FALSE(pool->HasLayers());

  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);

  ASSERT_TRUE(pool->HasLayers());

  pool->SetFrameSize(DlISize(20, 20));
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(20, 20))
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              1, window))));
  auto layer_2 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_NE(nullptr, layer_2);
  EXPECT_EQ(1, layer_2->id);
  EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(0));
  ASSERT_TRUE(pool->GetUnusedLayers().empty());
  ASSERT_TRUE(pool->HasLayers());
}

TEST(SurfacePool, DoesNotDestroyLayersFrameSizeChangedNew) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true);
  auto jni_mock = std::make_shared<JNIMock>();

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        EXPECT_CALL(*android_surface_mock,
                    OnScreenSurfaceResize(DlISize(20, 20)))
            .Times(1);
        return android_surface_mock;
      });
  pool->SetFrameSize(DlISize(10, 10));
  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(0);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  ASSERT_FALSE(pool->HasLayers());

  auto layer_1 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_TRUE(pool->HasLayers());
  ASSERT_NE(nullptr, layer_1);

  pool->RecycleLayers();
  pool->SetFrameSize(DlISize(20, 20));
  auto layer_2 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_TRUE(pool->GetUnusedLayers().empty());
  ASSERT_TRUE(pool->HasLayers());
  ASSERT_EQ(layer_1, layer_2);
}

TEST(SurfacePool, GetLayerReturnsNullOnAllocationOrSurfaceFailures) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context_1 = GrDirectContext::MakeMock(nullptr);
  auto gr_context_2 = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);

  pool->SetFrameSize(DlISize(50, 50));

  // Case 1: Invalid AndroidSurface returns nullptr without calling JNI.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(false));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(_, _)).Times(0);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
  }

  // Case 2: Null metadata returns nullptr without retiring an ID; null or
  // invalid native windows retire the allocated Java overlay ID without calling
  // SetNativeWindow.
  {
    auto invalid_window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(_, _)).Times(0);
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(50, 50))
        .WillOnce(Return(ByMove(nullptr)))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                5, nullptr))))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                6, invalid_window))));
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_TRUE(pool->TakeRetiredLayerIds().empty());
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(5, 6));
  }

  // Case 2b: SetNativeWindow failure retires the Java overlay ID without
  // creating a GPU surface or poisoning SurfacePool.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
          .WillOnce(Return(false));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(_)).Times(0);
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(50, 50))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                8, window))));
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(8));
  }

  // Case 3: Null GPU surface retires the newly created Java overlay ID.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([gr_context_1,
                                                                window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
          .WillOnce(Return(ByMove(nullptr)));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(50, 50))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                7, window))));
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(7));
  }

  // Case 4: GPU surface recreation failure during recycle removes & retires id.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([gr_context_1,
                                                                gr_context_2,
                                                                window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
          .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_2.get()))
          .WillOnce(Return(ByMove(nullptr)));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(50, 50))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                9, window))));
    ASSERT_NE(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    pool->RecycleLayers();
    EXPECT_EQ(
        pool->GetLayer(gr_context_2.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_THAT(pool->TakeRetiredLayerIds(), ElementsAre(9));
  }
}

}  // namespace testing
}  // namespace flutter
