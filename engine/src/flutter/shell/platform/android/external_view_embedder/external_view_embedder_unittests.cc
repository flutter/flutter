// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/android_surface_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {
namespace testing {

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

class SurfaceMock : public Surface {
 public:
  MOCK_METHOD(bool, IsValid, (), (override));

  MOCK_METHOD(std::unique_ptr<SurfaceFrame>,
              AcquireFrame,
              (const SkISize& size),
              (override));

  MOCK_METHOD(SkMatrix, GetRootTransformation, (), (const, override));

  MOCK_METHOD(GrDirectContext*, GetContext, (), (override));

  MOCK_METHOD(std::unique_ptr<GLContextResult>,
              MakeRenderContextCurrent,
              (),
              (override));
};

fml::RefPtr<fml::RasterThreadMerger> GetThreadMergerFromPlatformThread(
    bool merged = false) {
  // Assume the current thread is the platform thread.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto platform_queue_id = fml::MessageLoop::GetCurrentTaskQueueId();

  if (merged) {
    return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                        platform_queue_id);
  }
  auto rasterizer_thread = new fml::Thread("rasterizer");
  auto rasterizer_queue_id =
      rasterizer_thread->GetTaskRunner()->GetTaskQueueId();
  return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                      rasterizer_queue_id);
}

fml::RefPtr<fml::RasterThreadMerger> GetThreadMergerFromRasterThread() {
  auto platform_thread = new fml::Thread("rasterizer");
  auto platform_queue_id = platform_thread->GetTaskRunner()->GetTaskQueueId();

  // Assume the current thread is the raster thread.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto rasterizer_queue_id = fml::MessageLoop::GetCurrentTaskQueueId();

  return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                      rasterizer_queue_id);
}

TEST(AndroidExternalViewEmbedder, GetCurrentCanvases) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);
  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0,
                       raster_thread_merger);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(2UL, canvases.size());
  ASSERT_EQ(SkISize::Make(10, 20), canvases[0]->getBaseLayerSize());
  ASSERT_EQ(SkISize::Make(10, 20), canvases[1]->getBaseLayerSize());
}

TEST(AndroidExternalViewEmbedder, GetCurrentCanvases__CompositeOrder) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);
  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0,
                       raster_thread_merger);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(2UL, canvases.size());
  ASSERT_EQ(embedder->CompositeEmbeddedView(0), canvases[0]);
  ASSERT_EQ(embedder->CompositeEmbeddedView(1), canvases[1]);
}

TEST(AndroidExternalViewEmbedder, CompositeEmbeddedView) {
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, nullptr, nullptr);

  ASSERT_EQ(nullptr, embedder->CompositeEmbeddedView(0));
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  ASSERT_NE(nullptr, embedder->CompositeEmbeddedView(0));

  ASSERT_EQ(nullptr, embedder->CompositeEmbeddedView(1));
  embedder->PrerollCompositeEmbeddedView(
      1, std::make_unique<EmbeddedViewParams>());
  ASSERT_NE(nullptr, embedder->CompositeEmbeddedView(1));
}

TEST(AndroidExternalViewEmbedder, CancelFrame) {
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, nullptr, nullptr);

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->CancelFrame();

  auto canvases = embedder->GetCurrentCanvases();
  ASSERT_EQ(0UL, canvases.size());
}

TEST(AndroidExternalViewEmbedder, RasterizerRunsOnPlatformThread) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0,
                       raster_thread_merger);
  // Push a platform view.
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());

  auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kSkipAndRetryFrame, postpreroll_result);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/true, raster_thread_merger);

  ASSERT_TRUE(raster_thread_merger->IsMerged());

  int pending_frames = 0;
  while (raster_thread_merger->IsMerged()) {
    raster_thread_merger->DecrementLease();
    pending_frames++;
  }
  ASSERT_EQ(10, pending_frames);  // kDefaultMergedLeaseDuration
}

TEST(AndroidExternalViewEmbedder, RasterizerRunsOnRasterizerThread) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  PostPrerollResult result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kSuccess, result);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/true, raster_thread_merger);

  ASSERT_FALSE(raster_thread_merger->IsMerged());
}

TEST(AndroidExternalViewEmbedder, PlatformViewRect) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);
  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(SkISize::Make(100, 100), nullptr, 1.5,
                       raster_thread_merger);

  MutatorsStack stack;
  SkMatrix matrix;
  matrix.setIdentity();
  // The framework always push a scale matrix based on the screen ratio.
  matrix.setConcat(matrix, SkMatrix::MakeScale(1.5, 1.5));
  matrix.setConcat(matrix, SkMatrix::MakeTrans(10, 20));
  auto view_params =
      std::make_unique<EmbeddedViewParams>(matrix, SkSize::Make(30, 40), stack);

  auto view_id = 0;
  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params));
  ASSERT_EQ(SkRect::MakeXYWH(15, 30, 45, 60), embedder->GetViewRect(view_id));
}

TEST(AndroidExternalViewEmbedder, PlatformViewRect__ChangedParams) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);
  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(SkISize::Make(100, 100), nullptr, 1.5,
                       raster_thread_merger);

  auto view_id = 0;

  MutatorsStack stack1;
  SkMatrix matrix1;
  matrix1.setIdentity();
  // The framework always push a scale matrix based on the screen ratio.
  matrix1.setConcat(SkMatrix::MakeScale(1.5, 1.5), SkMatrix::MakeTrans(10, 20));
  auto view_params_1 = std::make_unique<EmbeddedViewParams>(
      matrix1, SkSize::Make(30, 40), stack1);

  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params_1));

  MutatorsStack stack2;
  SkMatrix matrix2;
  matrix2.setIdentity();
  // The framework always push a scale matrix based on the screen ratio.
  matrix2.setConcat(matrix2, SkMatrix::MakeScale(1.5, 1.5));
  matrix2.setConcat(matrix2, SkMatrix::MakeTrans(50, 60));
  auto view_params_2 = std::make_unique<EmbeddedViewParams>(
      matrix2, SkSize::Make(70, 80), stack2);

  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params_2));

  ASSERT_EQ(SkRect::MakeXYWH(75, 90, 105, 120), embedder->GetViewRect(view_id));
}

TEST(AndroidExternalViewEmbedder, SubmitFrame) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = SkISize::Make(1000, 1000);
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurface::MakeNull(1000, 1000), false,
            [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
              return true;
            });
        auto surface_frame_2 = std::make_unique<SurfaceFrame>(
            SkSurface::MakeNull(1000, 1000), false,
            [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
              return true;
            });

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .Times(2 /* frames */)
            .WillOnce(Return(ByMove(std::move(surface_frame_1))))
            .WillOnce(Return(ByMove(std::move(surface_frame_2))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window));

        return android_surface_mock;
      });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, surface_factory);

  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(/*merged=*/true);

  // ------------------ First frame ------------------ //
  {
    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurface::MakeNull(1000, 1000), false,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            SkCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        });

    embedder->SubmitFrame(gr_context.get(), std::move(surface_frame), nullptr);
    // Submits frame if no Android view in the current frame.
    EXPECT_TRUE(did_submit_frame);
    // Doesn't resubmit frame.
    auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
    ASSERT_EQ(PostPrerollResult::kSuccess, postpreroll_result);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  // ------------------ Second frame ------------------ //
  {
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(frame_size, nullptr, 1.5, raster_thread_merger);

    // Add an Android view.
    MutatorsStack stack1;
    SkMatrix matrix1;
    matrix1.setIdentity();
    SkMatrix scale = SkMatrix::MakeScale(1.5, 1.5);
    SkMatrix trans = SkMatrix::MakeTrans(100, 100);
    matrix1.setConcat(scale, trans);
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        matrix1, SkSize::Make(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    // This is the recording canvas flow writes to.
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    auto rect_paint = SkPaint();
    rect_paint.setColor(SkColors::kCyan);
    rect_paint.setStyle(SkPaint::Style::kFill_Style);

    // This simulates Flutter UI that doesn't intersect with the Android view.
    canvas_1->drawRect(SkRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    // This simulates Flutter UI that intersects with the Android view.
    canvas_1->drawRect(SkRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->drawRect(SkRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    // Create a new overlay surface.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                               0, 150, 150, 300, 300, 300, 300, stack1));
    // The JNI call to display the overlay surface.
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 200, 200));

    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurface::MakeNull(1000, 1000), false,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            SkCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        });

    embedder->SubmitFrame(gr_context.get(), std::move(surface_frame), nullptr);
    // Doesn't submit frame if there aren't Android views in the previous frame.
    EXPECT_FALSE(did_submit_frame);
    // Resubmits frame.
    auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
    ASSERT_EQ(PostPrerollResult::kResubmitFrame, postpreroll_result);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  // ------------------ Third frame ------------------ //
  {
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(frame_size, nullptr, 1.5, raster_thread_merger);

    // Add an Android view.
    MutatorsStack stack1;
    SkMatrix matrix1;
    matrix1.setIdentity();
    SkMatrix scale = SkMatrix::MakeScale(1.5, 1.5);
    SkMatrix trans = SkMatrix::MakeTrans(100, 100);
    matrix1.setConcat(scale, trans);
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        matrix1, SkSize::Make(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    // This is the recording canvas flow writes to.
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    auto rect_paint = SkPaint();
    rect_paint.setColor(SkColors::kCyan);
    rect_paint.setStyle(SkPaint::Style::kFill_Style);

    // This simulates Flutter UI that doesn't intersect with the Android view.
    canvas_1->drawRect(SkRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    // This simulates Flutter UI that intersects with the Android view.
    canvas_1->drawRect(SkRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->drawRect(SkRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    // Don't create a new overlay surface since it's recycled from the first
    // frame.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface()).Times(0);
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                               0, 150, 150, 300, 300, 300, 300, stack1));
    // The JNI call to display the overlay surface.
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 200, 200));

    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurface::MakeNull(1000, 1000), false,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            SkCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        });
    embedder->SubmitFrame(gr_context.get(), std::move(surface_frame), nullptr);
    // Submits frame if there are Android views in the previous frame.
    EXPECT_TRUE(did_submit_frame);
    // Doesn't resubmit frame.
    auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
    ASSERT_EQ(PostPrerollResult::kSuccess, postpreroll_result);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }
}

TEST(AndroidExternalViewEmbedder, DoesNotCallJNIPlatformThreadOnlyMethods) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);

  // While on the raster thread, don't make JNI calls as these methods can only
  // run on the platform thread.
  auto raster_thread_merger = GetThreadMergerFromRasterThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0,
                       raster_thread_merger);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, DestroyOverlayLayersOnSizeChange) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = SkISize::Make(1000, 1000);
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurface::MakeNull(1000, 1000), false,
            [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
              return true;
            });

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window));

        return android_surface_mock;
      });

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, surface_factory);
  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  // ------------------ First frame ------------------ //
  {
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(frame_size, nullptr, 1.5, raster_thread_merger);

    // Add an Android view.
    MutatorsStack stack1;
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        SkMatrix(), SkSize::Make(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));

    // This simulates Flutter UI that intersects with the Android view.
    embedder->CompositeEmbeddedView(0)->drawRect(
        SkRect::MakeXYWH(50, 50, 200, 200), SkPaint());

    // Create a new overlay surface.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack1));
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 200, 200));

    auto surface_frame =
        std::make_unique<SurfaceFrame>(SkSurface::MakeNull(1000, 1000), false,
                                       [](const SurfaceFrame& surface_frame,
                                          SkCanvas* canvas) { return true; });
    embedder->SubmitFrame(gr_context.get(), std::move(surface_frame), nullptr);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  // Change the frame size.
  embedder->BeginFrame(SkISize::Make(30, 40), nullptr, 1.0,
                       raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, DoesNotDestroyOverlayLayersOnSizeChange) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = SkISize::Make(1000, 1000);
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurface::MakeNull(1000, 1000), false,
            [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
              return true;
            });

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window));

        return android_surface_mock;
      });

  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, surface_factory);

  // ------------------ First frame ------------------ //
  {
    auto raster_thread_merger = GetThreadMergerFromPlatformThread();
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(frame_size, nullptr, 1.5, raster_thread_merger);

    // Add an Android view.
    MutatorsStack stack1;
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        SkMatrix(), SkSize::Make(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));

    // This simulates Flutter UI that intersects with the Android view.
    embedder->CompositeEmbeddedView(0)->drawRect(
        SkRect::MakeXYWH(50, 50, 200, 200), SkPaint());

    // Create a new overlay surface.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack1));
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 200, 200));

    auto surface_frame =
        std::make_unique<SurfaceFrame>(SkSurface::MakeNull(1000, 1000), false,
                                       [](const SurfaceFrame& surface_frame,
                                          SkCanvas* canvas) { return true; });
    embedder->SubmitFrame(gr_context.get(), std::move(surface_frame), nullptr);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  // Changing the frame size from the raster thread does not make JNI calls.

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);

  embedder->BeginFrame(SkISize::Make(30, 40), nullptr, 1.0,
                       GetThreadMergerFromRasterThread());
}

TEST(AndroidExternalViewEmbedder, SupportsDynamicThreadMerging) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);
  ASSERT_TRUE(embedder->SupportsDynamicThreadMerging());
}

TEST(AndroidExternalViewEmbedder, DisableThreadMerger) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr);

  auto raster_thread_merger = GetThreadMergerFromRasterThread();
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  // The shell may disable the thread merger during `OnPlatformViewDestroyed`.
  raster_thread_merger->Disable();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);

  embedder->BeginFrame(SkISize::Make(10, 20), nullptr, 1.0,
                       raster_thread_merger);
  // Push a platform view.
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());

  auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kSkipAndRetryFrame, postpreroll_result);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  embedder->EndFrame(/*should_resubmit_frame=*/true, raster_thread_merger);

  ASSERT_FALSE(raster_thread_merger->IsMerged());
}

}  // namespace testing
}  // namespace flutter
