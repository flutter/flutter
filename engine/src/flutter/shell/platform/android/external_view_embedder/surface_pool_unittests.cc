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
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto surface_factory =
      std::make_shared<TestAndroidSurfaceFactory>([gr_context, window]() {
        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_2.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        // Set the native window once.
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
            .WillOnce(Return(true));
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

namespace {

class OrderTrackingAndroidSurface final : public AndroidSurface {
 public:
  explicit OrderTrackingAndroidSurface(std::vector<std::string>* events)
      : events_(events) {}

  bool IsValid() const override { return true; }
  void TeardownOnScreenContext() override {}
  std::unique_ptr<Surface> CreateGPUSurface(GrDirectContext*) override {
    events_->push_back("CreateGPUSurface");
    return std::make_unique<TestSurface>();
  }
  bool OnScreenSurfaceResize(const DlISize&) override { return true; }
  bool ResourceContextMakeCurrent() override { return true; }
  bool ResourceContextClearCurrent() override { return true; }
  void SetupImpellerSurface() override {
    events_->push_back("SetupImpellerSurface");
  }
  bool SetNativeWindow(
      fml::RefPtr<AndroidNativeWindow>,
      const std::shared_ptr<PlatformViewAndroidJNI>&) override {
    events_->push_back("SetNativeWindow");
    return true;
  }

 private:
  std::vector<std::string>* events_;
};

}  // namespace

TEST(SurfacePool, GetLayerCallsSetupImpellerSurfaceBeforeSetNativeWindow) {
  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  std::vector<std::string> events;
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto factory = std::make_shared<TestAndroidSurfaceFactory>([&events]() {
    return std::make_unique<OrderTrackingAndroidSurface>(&events);
  });

  auto layer =
      pool->GetLayer(gr_context.get(), *android_context, jni_mock, factory);
  ASSERT_NE(layer, nullptr);
  EXPECT_THAT(events, ElementsAre("SetupImpellerSurface", "SetNativeWindow",
                                  "CreateGPUSurface"));
}

TEST(SurfacePool, GetLayerReturnsNullOnAllocationOrSurfaceFailures) {
  // Distinct overlay surface IDs used across failure sub-cases.
  constexpr int kNullWindowOverlayId = 5;
  constexpr int kSetNativeWindowFailOverlayId = 6;
  constexpr int kNullGpuSurfaceOverlayId = 7;
  constexpr int kMultiOverlayFirstId = 8;
  constexpr int kRecycleFailOverlayId = 9;
  constexpr int kHcppFailOverlayId = 10;
  constexpr int kFrameExtentPx = 50;

  auto pool = std::make_unique<SurfacePool>(/*use_new_surface_methods=*/false);
  auto jni_mock = std::make_shared<JNIMock>();
  auto gr_context_1 = GrDirectContext::MakeMock(nullptr);
  auto gr_context_2 = GrDirectContext::MakeMock(nullptr);
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  pool->SetFrameSize(DlISize(kFrameExtentPx, kFrameExtentPx));

  // Case 1: Invalid AndroidSurface returns nullptr without calling JNI.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(false));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface()).Times(0);
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 2a: Null metadata (Java threw before returning an overlay) returns
  // nullptr without invoking FlutterViewDestroyOverlaySurfaces.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(ByMove(nullptr)));
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 2b: Non-null metadata with null window destroys the orphaned Java
  // overlay immediately when no earlier layers are active.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kNullWindowOverlayId, nullptr))));
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 3: SetNativeWindow failure returns nullptr without calling
  // CreateGPUSurface and destroys the orphaned Java overlay immediately.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
          .WillOnce(Return(false));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(_)).Times(0);
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kSetNativeWindowFailOverlayId, window))));
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 4: Null GPU surface returns nullptr and destroys the orphaned Java
  // overlay immediately.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([gr_context_1,
                                                                window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
          .WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
          .WillOnce(Return(ByMove(nullptr)));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kNullGpuSurfaceOverlayId, window))));
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 5: GPU surface recreation failure during recycle erases the broken
  // layer and marks pending Java cleanup for DestroyLayers.
  {
    auto factory = std::make_shared<TestAndroidSurfaceFactory>([gr_context_1,
                                                                gr_context_2,
                                                                window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
          .WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_1.get()))
          .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
      EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context_2.get()))
          .WillOnce(Return(ByMove(nullptr)));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kRecycleFailOverlayId, window))));
    ASSERT_NE(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    pool->RecycleLayers();
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
    EXPECT_EQ(
        pool->GetLayer(gr_context_2.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_TRUE(pool->HasPendingDestroy());

    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    pool->DestroyLayers(jni_mock);
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 6: Second overlay failing post-JNI in the same frame preserves active
  // overlay #0 during the frame and destroys Java overlays on DestroyLayers.
  {
    int allocation_call = 0;
    auto factory = std::make_shared<TestAndroidSurfaceFactory>(
        [&allocation_call, gr_context_1, window]() {
          auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
          EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
          if (allocation_call++ == 0) {
            EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
                .WillOnce(Return(true));
            EXPECT_CALL(*android_surface_mock,
                        CreateGPUSurface(gr_context_1.get()))
                .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
          } else {
            EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
                .WillOnce(Return(false));
          }
          return android_surface_mock;
        });
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kMultiOverlayFirstId, window))))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kSetNativeWindowFailOverlayId, window))));
    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
    ASSERT_NE(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_EQ(
        pool->GetLayer(gr_context_1.get(), *android_context, jni_mock, factory),
        nullptr);
    EXPECT_TRUE(pool->HasLayers());

    EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    pool->DestroyLayers(jni_mock);
    EXPECT_FALSE(pool->HasLayers());
    EXPECT_FALSE(pool->HasPendingDestroy());
  }

  // Case 7: HCPP (use_new_surface_methods=true) invokes destroyOverlaySurface2
  // immediately when initial post-JNI setup fails, and via DestroyLayers when
  // raster-thread recycle fails.
  {
    auto hcpp_pool =
        std::make_unique<SurfacePool>(/*use_new_surface_methods=*/true);
    auto fail_factory = std::make_shared<TestAndroidSurfaceFactory>([window]() {
      auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
      EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
          .WillOnce(Return(false));
      return android_surface_mock;
    });
    EXPECT_CALL(*jni_mock, createOverlaySurface2())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kHcppFailOverlayId, window))));
    EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
    EXPECT_EQ(hcpp_pool->GetLayer(gr_context_1.get(), *android_context,
                                  jni_mock, fail_factory),
              nullptr);
    EXPECT_FALSE(hcpp_pool->HasLayers());
    EXPECT_FALSE(hcpp_pool->HasPendingDestroy());

    auto recycle_factory = std::make_shared<TestAndroidSurfaceFactory>(
        [gr_context_1, gr_context_2, window]() {
          auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
          EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
          EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _))
              .WillOnce(Return(true));
          EXPECT_CALL(*android_surface_mock,
                      CreateGPUSurface(gr_context_1.get()))
              .WillOnce(Return(ByMove(std::make_unique<TestSurface>())));
          EXPECT_CALL(*android_surface_mock,
                      CreateGPUSurface(gr_context_2.get()))
              .WillOnce(Return(ByMove(nullptr)));
          return android_surface_mock;
        });
    EXPECT_CALL(*jni_mock, createOverlaySurface2())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                kHcppFailOverlayId, window))));
    ASSERT_NE(hcpp_pool->GetLayer(gr_context_1.get(), *android_context,
                                  jni_mock, recycle_factory),
              nullptr);
    hcpp_pool->ResetLayers();
    EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(0);
    EXPECT_EQ(hcpp_pool->GetLayer(gr_context_2.get(), *android_context,
                                  jni_mock, recycle_factory),
              nullptr);
    EXPECT_FALSE(hcpp_pool->HasLayers());
    EXPECT_TRUE(hcpp_pool->HasPendingDestroy());

    EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
    hcpp_pool->DestroyLayers(jni_mock);
    EXPECT_FALSE(hcpp_pool->HasPendingDestroy());
  }
}

}  // namespace testing
}  // namespace flutter
