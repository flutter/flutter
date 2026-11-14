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
using ::testing::Return;

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
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
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
        EXPECT_CALL(*android_surface_mock,
                    CreateGPUSurface(gr_context_1.get()));
        EXPECT_CALL(*android_surface_mock,
                    CreateGPUSurface(gr_context_2.get()));
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
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kFirstOverlayId, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .Times(1);
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  auto layer = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                              surface_factory);

  // Taking the layers leaves destroying the Java overlay surfaces pending for
  // the platform thread.
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  std::vector<std::shared_ptr<OverlayLayer>> layers = pool->TakeLayers();

  ASSERT_EQ(1UL, layers.size());
  EXPECT_EQ(layer, layers[0]);
  EXPECT_FALSE(pool->HasLayers());
  EXPECT_TRUE(pool->HasPendingDestroy());
  EXPECT_TRUE(pool->GetUnusedLayers().empty());

  // Destroying pending layers flushes once and becomes a no-op thereafter.
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  pool->DestroyPendingLayers(jni_mock);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyPendingLayers(jni_mock);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // If GetLayer runs before DestroyPendingLayers, GetLayer flushes the pending
  // destroy before allocating a new overlay surface.
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kFirstOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  ASSERT_TRUE(pool->HasPendingDestroy());

  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kSecondOverlayId, window))));
  }
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyPendingLayers(jni_mock);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // If DestroyLayers runs while layers_ is empty and pending_java_destroy_ is
  // true (for example, during Teardown), it flushes the pending destroy once.
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  EXPECT_FALSE(pool->HasLayers());
  EXPECT_TRUE(pool->HasPendingDestroy());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  pool->DestroyLayers(jni_mock);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyLayers(jni_mock);
  pool->DestroyPendingLayers(jni_mock);
}

TEST(SurfacePool,
     GetLayerFlushesPendingDestroyOnceAcrossMultipleOverlaysInFrame) {
  // Overlay IDs assigned sequentially across initial and post-resize frames.
  constexpr int kStaleOverlayId = 0;
  constexpr int kFirstNewOverlayId = 1;
  constexpr int kSecondNewOverlayId = 2;
  // Distinct pre-resize and post-resize viewport dimensions in physical pixels.
  constexpr int kInitialSizePx = 100;
  constexpr int kResizedSizePx = 200;

  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .Times(1);
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });

  pool->SetFrameSize(DlISize(kInitialSizePx, kInitialSizePx));
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kStaleOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  pool->SetFrameSize(DlISize(kResizedSizePx, kResizedSizePx));
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  ASSERT_TRUE(pool->HasPendingDestroy());

  // Acquiring two overlays in the same frame must flush the stale Java overlay
  // once before the first allocation and leave the first new overlay intact
  // when allocating the second.
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kFirstNewOverlayId, window))));
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kSecondNewOverlayId, window))));
  }
  auto layer_1 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);
  auto layer_2 = pool->GetLayer(gr_context.get(), *android_context, jni_mock,
                                surface_factory);

  ASSERT_NE(nullptr, layer_1);
  ASSERT_NE(nullptr, layer_2);
  EXPECT_NE(layer_1, layer_2);
  EXPECT_EQ(kFirstNewOverlayId, layer_1->id);
  EXPECT_EQ(kSecondNewOverlayId, layer_2->id);
  EXPECT_FALSE(pool->HasPendingDestroy());
  EXPECT_TRUE(pool->HasLayers());
}

TEST(SurfacePool,
     TakeLayersPreservesPendingDestroyAcrossResizeBackToOriginalSize) {
  // Overlay IDs before and after an unmerged size1 -> size2 -> size1 resize.
  constexpr int kStaleOverlayId = 0;
  constexpr int kReplacementOverlayId = 1;
  // Original and intermediate viewport dimensions in physical pixels.
  constexpr int kOriginalSizePx = 100;
  constexpr int kIntermediateSizePx = 200;

  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .Times(1);
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _)).Times(1);
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });

  pool->SetFrameSize(DlISize(kOriginalSizePx, kOriginalSizePx));
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              kStaleOverlayId, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // First unmerged resize empties layers_ and marks pending_java_destroy_.
  pool->SetFrameSize(DlISize(kIntermediateSizePx, kIntermediateSizePx));
  ASSERT_EQ(1UL, pool->TakeLayers().size());
  EXPECT_TRUE(pool->HasPendingDestroy());

  // Second unmerged resize back to kOriginalSizePx finds layers_ already empty;
  // pending_java_destroy_ must remain set even though requested_frame_size_ now
  // equals current_frame_size_.
  pool->SetFrameSize(DlISize(kOriginalSizePx, kOriginalSizePx));
  EXPECT_TRUE(pool->TakeLayers().empty());
  EXPECT_TRUE(pool->HasPendingDestroy());

  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kReplacementOverlayId, window))));
  }
  auto replacement = pool->GetLayer(gr_context.get(), *android_context,
                                    jni_mock, surface_factory);
  ASSERT_NE(nullptr, replacement);
  EXPECT_EQ(kReplacementOverlayId, replacement->id);
  EXPECT_FALSE(pool->HasPendingDestroy());
  pool->DestroyPendingLayers(jni_mock);
}

TEST(SurfacePool, DestroyLayersFrameSizeChanged) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        return android_surface_mock;
      });
  pool->SetFrameSize(DlISize(10, 10));
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  ASSERT_FALSE(pool->HasLayers());

  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);

  ASSERT_TRUE(pool->HasLayers());

  pool->SetFrameSize(DlISize(20, 20));
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              1, window))));
  pool->GetLayer(gr_context.get(), *android_context, jni_mock, surface_factory);

  ASSERT_TRUE(pool->GetUnusedLayers().empty());
  ASSERT_TRUE(pool->HasLayers());
}

TEST(SurfacePool, DoesNotDestroyLayersFrameSizeChangedNew) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true);
  auto jni_mock = std::make_shared<JNIMock>();

  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()));
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

}  // namespace testing
}  // namespace flutter
