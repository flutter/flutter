// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <atomic>
#include <memory>

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/android_surface_mock.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::ByMove;
using ::testing::InSequence;
using ::testing::Return;

constexpr int64_t kImplicitViewId = 0;

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
              (const DlISize& size),
              (override));

  MOCK_METHOD(DlMatrix, GetRootTransformation, (), (const, override));

  MOCK_METHOD(GrDirectContext*, GetContext, (), (override));

  MOCK_METHOD(std::unique_ptr<GLContextResult>,
              MakeRenderContextCurrent,
              (),
              (override));
};

fml::RefPtr<fml::RasterThreadMerger> GetThreadMergerFromPlatformThread(
    fml::Thread* rasterizer_thread = nullptr) {
  // Assume the current thread is the platform thread.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto platform_queue_id = fml::MessageLoop::GetCurrentTaskQueueId();

  if (!rasterizer_thread) {
    return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                        platform_queue_id);
  }
  auto rasterizer_queue_id =
      rasterizer_thread->GetTaskRunner()->GetTaskQueueId();
  return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                      rasterizer_queue_id);
}

fml::RefPtr<fml::RasterThreadMerger> GetThreadMergerFromRasterThread(
    fml::Thread* platform_thread) {
  auto platform_queue_id = platform_thread->GetTaskRunner()->GetTaskQueueId();

  // Assume the current thread is the raster thread.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto rasterizer_queue_id = fml::MessageLoop::GetCurrentTaskQueueId();

  return fml::MakeRefCounted<fml::RasterThreadMerger>(platform_queue_id,
                                                      rasterizer_queue_id);
}

TaskRunners GetTaskRunnersForFixture() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto& loop = fml::MessageLoop::GetCurrent();
  return {
      "test",
      loop.GetTaskRunner(),  // platform
      loop.GetTaskRunner(),  // raster
      loop.GetTaskRunner(),  // ui
      loop.GetTaskRunner()   // io
  };
}

TEST(AndroidExternalViewEmbedder, CompositeEmbeddedView) {
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, nullptr, nullptr, GetTaskRunnersForFixture());

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
      android_context, nullptr, nullptr, GetTaskRunnersForFixture());

  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  embedder->CancelFrame();

  ASSERT_EQ(embedder->CompositeEmbeddedView(0), nullptr);
}

TEST(AndroidExternalViewEmbedder, RasterizerRunsOnPlatformThread) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(10, 20), 1.0);

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
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);
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
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());
  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(100, 100), 1.5);

  MutatorsStack stack;
  DlMatrix matrix;
  // The framework always push a scale matrix based on the screen ratio.
  matrix = matrix * DlMatrix::MakeScale({1.5, 1.5, 1});
  matrix = matrix * DlMatrix::MakeTranslation({10, 20});
  auto view_params =
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(30, 40), stack);

  auto view_id = 0;
  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params));
  ASSERT_EQ(DlRect::MakeXYWH(15, 30, 45, 60), embedder->GetViewRect(view_id));
}

TEST(AndroidExternalViewEmbedder, PlatformViewRectChangedParams) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());
  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(100, 100), 1.5);

  auto view_id = 0;

  MutatorsStack stack1;
  DlMatrix matrix1;
  // The framework always push a scale matrix based on the screen ratio.
  matrix1 =
      DlMatrix::MakeScale({1.5, 1.5, 1}) * DlMatrix::MakeTranslation({10, 20});
  auto view_params_1 =
      std::make_unique<EmbeddedViewParams>(matrix1, DlSize(30, 40), stack1);

  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params_1));

  MutatorsStack stack2;
  DlMatrix matrix2;
  // The framework always push a scale matrix based on the screen ratio.
  matrix2 = matrix2 * DlMatrix::MakeScale({1.5, 1.5, 1});
  matrix2 = matrix2 * DlMatrix::MakeTranslation({50, 60});
  auto view_params_2 =
      std::make_unique<EmbeddedViewParams>(matrix2, DlSize(70, 80), stack2);

  embedder->PrerollCompositeEmbeddedView(view_id, std::move(view_params_2));

  ASSERT_EQ(DlRect::MakeXYWH(75, 90, 105, 120), embedder->GetViewRect(view_id));
}

// Regression test for https://github.com/flutter/flutter/issues/189834.
//
// A platform view that exactly covers the screen must be laid out at the full
// physical size of the screen. The logical size the framework computes is
// `physical / dpr` narrowed to a float, so multiplying it back out lands a hair
// *under* the physical size. Truncating that (rather than rounding) shaves a
// pixel off of the right and bottom edges, and the Flutter content behind the
// platform view shows through as a thin line.
TEST(AndroidExternalViewEmbedder, PlatformViewSizeIsRoundedNotTruncated) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  // A 1080x2400 screen at the device pixel ratio of, say, a Pixel 6.
  constexpr double kDevicePixelRatio = 2.625;
  const auto frame_size = DlISize(1080, 2400);

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(frame_size, kDevicePixelRatio);

  // The framework sizes the view in logical pixels, which is narrowed to a
  // float on the way in: 411.42856f * 2.625 == 1079.9999656677246, and
  // 914.28571f * 2.625 == 2399.9999771118164.
  const auto size_points =
      DlSize(static_cast<DlScalar>(frame_size.width / kDevicePixelRatio),
             static_cast<DlScalar>(frame_size.height / kDevicePixelRatio));
  MutatorsStack stack;
  const DlMatrix scale =
      DlMatrix::MakeScale({kDevicePixelRatio, kDevicePixelRatio, 1});
  stack.PushTransform(scale);
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>(scale, size_points, stack));

  // Both the bounding rect and the size of the view itself cover the whole
  // screen; neither is 1079x2399.
  EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 1080, 2400,
                                                          1080, 2400, stack));

  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1080, 2400), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size);
  embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                              std::move(surface_frame));

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, SubmitFlutterView) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));
        auto surface_frame_2 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .Times(2 /* frames */)
            .WillOnce(Return(ByMove(std::move(surface_frame_1))))
            .WillOnce(Return(ByMove(std::move(surface_frame_2))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));

        return android_surface_mock;
      });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  // ------------------ First frame ------------------ //
  {
    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            DlCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/DlISize(800, 600));

    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
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
    embedder->BeginFrame(nullptr, raster_thread_merger);
    embedder->PrepareFlutterView(frame_size, 1.5);

    // Add an Android view.
    MutatorsStack stack1;
    DlMatrix scale = DlMatrix::MakeScale({1.5, 1.5, 1});
    DlMatrix trans = DlMatrix::MakeTranslation({100, 100});
    DlMatrix matrix1 = scale * trans;
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 =
        std::make_unique<EmbeddedViewParams>(matrix1, DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    // This is the recording canvas flow writes to.
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    DlPaint rect_paint;
    rect_paint.setColor(DlColor::kCyan());
    rect_paint.setDrawStyle(DlDrawStyle::kFill);

    // This simulates Flutter UI that doesn't intersect with the Android view.
    canvas_1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    // This simulates Flutter UI that intersects with the Android view.
    canvas_1->DrawRect(DlRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(150, 150, 100, 100), rect_paint);

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
                FlutterViewDisplayOverlaySurface(0, 150, 150, 100, 100));

    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            DlCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/DlISize(800, 600));

    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
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
    embedder->BeginFrame(nullptr, raster_thread_merger);
    embedder->PrepareFlutterView(frame_size, 1.5);

    // Add an Android view.
    MutatorsStack stack1;
    DlMatrix scale = DlMatrix::MakeScale({1.5, 1.5, 1});
    DlMatrix trans = DlMatrix::MakeTranslation({100, 100});
    DlMatrix matrix1 = scale * trans;
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 =
        std::make_unique<EmbeddedViewParams>(matrix1, DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    // This is the recording canvas flow writes to.
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    DlPaint rect_paint;
    rect_paint.setColor(DlColor::kCyan());
    rect_paint.setDrawStyle(DlDrawStyle::kFill);

    // This simulates Flutter UI that doesn't intersect with the Android view.
    canvas_1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    // This simulates Flutter UI that intersects with the Android view.
    canvas_1->DrawRect(DlRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    // Don't create a new overlay surface since it's recycled from the first
    // frame.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface()).Times(0);
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                               0, 150, 150, 300, 300, 300, 300, stack1));
    // The JNI call to display the overlay surface.
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 150, 150, 100, 100));

    auto did_submit_frame = false;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [&did_submit_frame](const SurfaceFrame& surface_frame,
                            DlCanvas* canvas) mutable {
          if (canvas != nullptr) {
            did_submit_frame = true;
          }
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    // Submits frame if there are Android views in the previous frame.
    EXPECT_TRUE(did_submit_frame);
    // Doesn't resubmit frame.
    auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
    ASSERT_EQ(PostPrerollResult::kSuccess, postpreroll_result);

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }
}

TEST(AndroidExternalViewEmbedder, OverlayCoverTwoPlatformViews) {
  // In this test we will simulate two Android views appearing on the screen
  // with a rect intersecting both of them

  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .Times(1 /* frames */)
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        return android_surface_mock;
      });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(frame_size, 1.5);

  {
    // Add first Android view.
    DlMatrix matrix = DlMatrix::MakeTranslation({100, 100});
    MutatorsStack stack;
    embedder->PrerollCompositeEmbeddedView(
        0,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100), stack));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                               0, 100, 100, 100, 100, 150, 150, stack));
  }

  {
    // Add second Android view.
    DlMatrix matrix = DlMatrix::MakeTranslation({300, 100});
    MutatorsStack stack;
    embedder->PrerollCompositeEmbeddedView(
        1,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100), stack));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                               1, 300, 100, 100, 100, 150, 150, stack));
  }
  auto rect_paint = DlPaint();
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  // This simulates Flutter UI that intersects with the two Android views.
  // Since we will compute the intersection for each android view in turn, and
  // finally merge The final size of the overlay will be smaller than the
  // width and height of the rect.
  embedder->CompositeEmbeddedView(1)->DrawRect(
      DlRect::MakeXYWH(150, 50, 200, 200), rect_paint);

  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillRepeatedly([&]() {
        return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
            1, window);
      });

  // The JNI call to display the overlay surface.
  EXPECT_CALL(*jni_mock,
              FlutterViewDisplayOverlaySurface(1, 150, 100, 200, 100))
      .Times(1);

  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1000, 1000), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) mutable {
        return true;
      },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/DlISize(800, 600));

  embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                              std::move(surface_frame));

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, SubmitFrameOverlayComposition) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .Times(1 /* frames */)
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        return android_surface_mock;
      });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(frame_size, 1.5);

  {
    // Add first Android view.
    DlMatrix matrix;
    MutatorsStack stack;
    stack.PushTransform(DlMatrix::MakeTranslation({0, 0}));

    embedder->PrerollCompositeEmbeddedView(
        0,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(200, 200), stack));
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack));
  }

  auto rect_paint = DlPaint();
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  // This simulates Flutter UI that intersects with the first Android view.
  embedder->CompositeEmbeddedView(0)->DrawRect(
      DlRect::MakeXYWH(25, 25, 80, 150), rect_paint);

  {
    // Add second Android view.
    DlMatrix matrix;
    MutatorsStack stack;
    stack.PushTransform(DlMatrix::MakeTranslation({0, 100}));

    embedder->PrerollCompositeEmbeddedView(
        1,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100), stack));
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(1, 0, 0, 100, 100,
                                                            150, 150, stack));
  }
  // This simulates Flutter UI that intersects with the first and second Android
  // views.
  embedder->CompositeEmbeddedView(1)->DrawRect(DlRect::MakeXYWH(25, 25, 80, 50),
                                               rect_paint);

  embedder->CompositeEmbeddedView(1)->DrawRect(
      DlRect::MakeXYWH(75, 75, 30, 100), rect_paint);

  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillRepeatedly([&]() {
        return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
            1, window);
      });

  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(1, 25, 25, 80, 150))
      .Times(2);

  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1000, 1000), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) mutable {
        return true;
      },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/DlISize(800, 600));

  embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                              std::move(surface_frame));

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, SubmitFramePlatformViewWithoutAnyOverlay) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .Times(1 /* frames */)
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));
        return android_surface_mock;
      });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  auto raster_thread_merger = GetThreadMergerFromPlatformThread();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(frame_size, 1.5);

  {
    // Add Android view.
    DlMatrix matrix;
    MutatorsStack stack;
    stack.PushTransform(DlMatrix::MakeTranslation({0, 0}));

    embedder->PrerollCompositeEmbeddedView(
        0,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(200, 200), stack));
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack));
  }

  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface()).Times(0);

  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1000, 1000), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) mutable {
        return true;
      },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/DlISize(800, 600));

  embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                              std::move(surface_frame));

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, DoesNotCallJNIPlatformThreadOnlyMethods) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  // While on the raster thread, don't make JNI calls as these methods can only
  // run on the platform thread.
  fml::Thread platform_thread("platform");
  auto raster_thread_merger = GetThreadMergerFromRasterThread(&platform_thread);

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(10, 20), 1.0);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
}

TEST(AndroidExternalViewEmbedder, DestroyOverlayLayersOnSizeChange) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));

        return android_surface_mock;
      });

  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());
  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);

  // ------------------ First frame ------------------ //
  {
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(nullptr, raster_thread_merger);
    embedder->PrepareFlutterView(frame_size, 1.5);

    // Add an Android view.
    MutatorsStack stack1;
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        DlMatrix(), DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));

    // This simulates Flutter UI that intersects with the Android view.
    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(50, 50, 200, 200), DlPaint());

    // Create a new overlay surface.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack1));
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 150, 150));

    SurfaceFrame::FramebufferInfo framebuffer_info;
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  // Change the frame size.
  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(30, 40), 1.0);
  // `PrepareFlutterView` posts `MaybeResizeSurfaceView` to the platform runner,
  // keeping `jni_mock` alive past the end of the test, so verify here.
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
}

TEST(AndroidExternalViewEmbedder, DoesNotDestroyOverlayLayersOnSizeChange) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size, framebuffer_info]() {
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));

        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        EXPECT_CALL(*android_surface_mock, SetNativeWindow(window, _));

        return android_surface_mock;
      });

  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  // ------------------ First frame ------------------ //
  {
    fml::Thread rasterizer_thread("rasterizer");
    auto raster_thread_merger =
        GetThreadMergerFromPlatformThread(&rasterizer_thread);
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    embedder->BeginFrame(nullptr, raster_thread_merger);
    embedder->PrepareFlutterView(frame_size, 1.5);

    // Add an Android view.
    MutatorsStack stack1;
    // TODO(egarciad): Investigate why Flow applies the device pixel ratio to
    // the offsetPixels, but not the sizePoints.
    auto view_params_1 = std::make_unique<EmbeddedViewParams>(
        DlMatrix(), DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));

    // This simulates Flutter UI that intersects with the Android view.
    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(50, 50, 200, 200), DlPaint());

    // Create a new overlay surface.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    // The JNI call to display the Android view.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack1));
    EXPECT_CALL(*jni_mock,
                FlutterViewDisplayOverlaySurface(0, 50, 50, 150, 150));

    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
          return true;
        },
        [](const SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));

    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);
  }

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);

  fml::Thread platform_thread("platform");
  embedder->BeginFrame(nullptr,
                       GetThreadMergerFromRasterThread(&platform_thread));
  embedder->PrepareFlutterView(DlISize(30, 40), 1.0);
  // `PrepareFlutterView` posts `MaybeResizeSurfaceView` to the platform runner,
  // keeping `jni_mock` alive past the end of the test, so verify here.
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
}

TEST(AndroidExternalViewEmbedder, SupportsDynamicThreadMerging) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());
  ASSERT_TRUE(embedder->SupportsDynamicThreadMerging());
}

TEST(AndroidExternalViewEmbedder, DisableThreadMerger) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  fml::Thread platform_thread("platform");
  auto raster_thread_merger = GetThreadMergerFromRasterThread(&platform_thread);
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  // The shell may disable the thread merger during `OnPlatformViewDestroyed`.
  raster_thread_merger->Disable();

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);

  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(DlISize(10, 20), 1.0);
  // Push a platform view.
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());

  auto postpreroll_result = embedder->PostPrerollAction(raster_thread_merger);
  ASSERT_EQ(PostPrerollResult::kSkipAndRetryFrame, postpreroll_result);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  embedder->EndFrame(/*should_resubmit_frame=*/true, raster_thread_merger);

  ASSERT_FALSE(raster_thread_merger->IsMerged());
}

TEST(AndroidExternalViewEmbedder, Teardown) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [gr_context, window, frame_size]() {
        SurfaceFrame::FramebufferInfo framebuffer_info;
        auto surface_frame_1 = std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(1000, 1000), framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            /*frame_size=*/DlISize(800, 600));

        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillOnce(Return(ByMove(std::move(surface_frame_1))));

        auto android_surface_mock = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface_mock, IsValid()).WillOnce(Return(true));
        EXPECT_CALL(*android_surface_mock, CreateGPUSurface(gr_context.get()))
            .WillOnce(Return(ByMove(std::move(surface_mock))));

        return android_surface_mock;
      });

  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());
  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);

  embedder->BeginFrame(nullptr, raster_thread_merger);
  embedder->PrepareFlutterView(frame_size, 1.5);

  // Add an Android view.
  MutatorsStack stack;
  auto view_params =
      std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(200, 200), stack);

  embedder->PrerollCompositeEmbeddedView(0, std::move(view_params));

  // This simulates Flutter UI that intersects with the Android view.
  embedder->CompositeEmbeddedView(0)->DrawRect(
      DlRect::MakeXYWH(50, 50, 200, 200), DlPaint());

  // Create a new overlay surface.
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1000, 1000), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/DlISize(800, 600));
  embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                              std::move(surface_frame));

  embedder->EndFrame(/*should_resubmit_frame=*/false, raster_thread_merger);

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces());
  // Teardown.
  embedder->Teardown();
}

TEST(AndroidExternalViewEmbedder, MaybeResizeSurfaceView) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.raster_thread->GetTaskRunner(),    // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, task_runners);

  fml::Thread rasterizer_thread("rasterizer");
  auto raster_thread_merger =
      GetThreadMergerFromPlatformThread(&rasterizer_thread);
  ASSERT_FALSE(raster_thread_merger->IsMerged());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
  embedder->BeginFrame(nullptr, raster_thread_merger);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(100, 200));
  embedder->PrepareFlutterView(DlISize(100, 200), 1.0);

  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(task_runners.GetPlatformTaskRunner(),
                                    [&latch]() { latch.Signal(); });
  latch.Wait();
}

TEST(AndroidExternalViewEmbedder, TeardownDoesNotCallJNIMethod) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  embedder->Teardown();
}

namespace {

// Shared multi-thread harness for Hybrid Composition (HC) resize tests.
struct HcResizeTestFixture {
  // Initial and post-resize viewport dimensions in physical pixels.
  static constexpr int kInitialViewportPx = 1000;
  static constexpr int kResizedViewportPx = 800;
  // Logical platform view size and intersecting Flutter overlay rect.
  static constexpr DlScalar kPlatformViewLogicalSize = 200;
  static constexpr DlScalar kOverlayOriginLogical = 50;
  static constexpr DlScalar kOverlaySizeLogical = 200;
  // Physical view size (200 * 1.5 dpr) and clipped overlay size (200 - 50).
  static constexpr int kPhysicalViewSizePx = 300;
  static constexpr int kClippedOverlaySizePx = 150;
  static constexpr double kDevicePixelRatio = 1.5;
  static constexpr int64_t kTestPlatformViewId = 0;
  static constexpr int kFirstOverlayId = 0;
  static constexpr int kSecondOverlayId = 1;
  // Timeout used when checking that PrepareFlutterView does not block 1.raster.
  static constexpr int64_t kDeadlockTimeoutSeconds = 10;
  // 1-frame merge lease used to enter merged mode on the initial HC frame.
  static constexpr size_t kInitialMergeLease = 1;

  const DlISize frame_size1{kInitialViewportPx, kInitialViewportPx};
  const DlISize frame_size2{kResizedViewportPx, kResizedViewportPx};
  SurfaceFrame::FramebufferInfo framebuffer_info;
  std::shared_ptr<JNIMock> jni_mock = std::make_shared<JNIMock>();
  std::shared_ptr<AndroidContext> android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host{"io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster};
  TaskRunners task_runners{"test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner()};
  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  MutatorsStack stack;
  std::shared_ptr<TestAndroidSurfaceFactory> surface_factory;
  std::unique_ptr<AndroidExternalViewEmbedder> embedder;

  HcResizeTestFixture() {
    auto info = framebuffer_info;
    surface_factory = std::make_shared<TestAndroidSurfaceFactory>([info]() {
      auto surface_mock = std::make_unique<SurfaceMock>();
      EXPECT_CALL(*surface_mock, AcquireFrame(_))
          .WillRepeatedly([info](const DlISize& size) {
            return std::make_unique<SurfaceFrame>(
                SkSurfaces::Null(size.width, size.height), info,
                [](const SurfaceFrame&, DlCanvas*) { return true; },
                [](const SurfaceFrame&) { return true; }, size);
          });
      auto android_surface = std::make_unique<AndroidSurfaceMock>();
      EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
      EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
          .WillRepeatedly(Return(true));
      EXPECT_CALL(*android_surface, CreateGPUSurface(_))
          .WillRepeatedly(Return(ByMove(std::move(surface_mock))));
      return android_surface;
    });
    embedder = std::make_unique<AndroidExternalViewEmbedder>(
        *android_context, jni_mock, surface_factory, task_runners);
  }

  void DrawMergedOverlayFrame(const DlISize& size) {
    PostTaskSync(task_runners.GetPlatformTaskRunner(), [&]() {
      embedder->PrepareFlutterView(size, kDevicePixelRatio);
      embedder->PrerollCompositeEmbeddedView(
          kTestPlatformViewId,
          std::make_unique<EmbeddedViewParams>(
              DlMatrix(),
              DlSize(kPlatformViewLogicalSize, kPlatformViewLogicalSize),
              stack));
      embedder->CompositeEmbeddedView(kTestPlatformViewId)
          ->DrawRect(
              DlRect::MakeXYWH(kOverlayOriginLogical, kOverlayOriginLogical,
                               kOverlaySizeLogical, kOverlaySizeLogical),
              DlPaint());
      embedder->SubmitFlutterView(
          kImplicitViewId, nullptr, nullptr,
          std::make_unique<SurfaceFrame>(
              SkSurfaces::Null(size.width, size.height), framebuffer_info,
              [](const SurfaceFrame&, DlCanvas*) { return true; },
              [](const SurfaceFrame&) { return true; }, size));
    });
    PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  }
};

}  // namespace

// Regression test for a raster/platform thread deadlock with Hybrid
// Composition (HC).
//
// HC only merges the raster thread into the platform thread while platform
// views are in the scene. After the last platform view leaves and the merge
// lease expires, frames are rasterized on the raster thread again, but the
// surface pool still holds the overlay layers. When the frame size then changes
// (for example, on rotation), `PrepareFlutterView` runs on the raster thread
// and must release those layers without blocking on the platform thread, which
// may itself be waiting on the raster thread (e.g. `NotifyChanged`).
TEST(AndroidExternalViewEmbedder, ResizeDoesNotBlockRasterOnPlatformThread) {
  HcResizeTestFixture h;

  // The first frame allocates overlay 0.
  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(
                  HcResizeTestFixture::kTestPlatformViewId, 0, 0,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPhysicalViewSizePx,
                  HcResizeTestFixture::kPhysicalViewSizePx, h.stack));
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(
                               HcResizeTestFixture::kFirstOverlayId,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kClippedOverlaySizePx,
                               HcResizeTestFixture::kClippedOverlaySizePx));
  h.DrawMergedOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Occupy the platform thread, standing in for a platform thread that is
  // waiting for the raster thread.
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  // Without platform views, the next frame is rasterized on the raster thread.
  // Its frame-size change must not wait for the platform thread.
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  fml::AutoResetWaitableEvent resize_done;
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    h.embedder->PrepareFlutterView(h.frame_size2,
                                   HcResizeTestFixture::kDevicePixelRatio);
    resize_done.Signal();
  });
  const bool timed_out =
      resize_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(
          HcResizeTestFixture::kDeadlockTimeoutSeconds));
  if (timed_out) {
    release_platform.Signal();
    resize_done.Wait();
    PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
    ADD_FAILURE() << "PrepareFlutterView blocked the raster thread on the "
                     "platform thread";
  } else {
    ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

    // The overlay views of the old size are destroyed on the platform thread
    // once it is free.
    EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
        .Times(::testing::AnyNumber());
    EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);

    release_platform.Signal();
    PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  }
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // The next frame with an overlay allocates a new overlay for the new size
  // without destroying again.
  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(
                  HcResizeTestFixture::kTestPlatformViewId, 0, 0,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPhysicalViewSizePx,
                  HcResizeTestFixture::kPhysicalViewSizePx, h.stack));
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kSecondOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(
                               HcResizeTestFixture::kSecondOverlayId,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kClippedOverlaySizePx,
                               HcResizeTestFixture::kClippedOverlaySizePx));
  h.DrawMergedOverlayFrame(h.frame_size2);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Teardown on the platform thread destroys the new overlay.
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     MergedTaskAheadOfPostedResizeDestroyDestroysOldBeforeCreatingNew) {
  HcResizeTestFixture h;
  auto raster_thread_merger = fml::MakeRefCounted<fml::RasterThreadMerger>(
      h.task_runners.GetPlatformTaskRunner()->GetTaskQueueId(),
      h.task_runners.GetRasterTaskRunner()->GetTaskQueueId());

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame())
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(::testing::AnyNumber());

  auto run_hc_frame = [&](const DlISize& size) -> PostPrerollResult {
    h.embedder->BeginFrame(nullptr, raster_thread_merger);
    h.embedder->PrepareFlutterView(size,
                                   HcResizeTestFixture::kDevicePixelRatio);
    h.embedder->PrerollCompositeEmbeddedView(
        HcResizeTestFixture::kTestPlatformViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(HcResizeTestFixture::kPlatformViewLogicalSize,
                   HcResizeTestFixture::kPlatformViewLogicalSize),
            h.stack));
    h.embedder->CompositeEmbeddedView(HcResizeTestFixture::kTestPlatformViewId)
        ->DrawRect(DlRect::MakeXYWH(HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical),
                   DlPaint());
    PostPrerollResult preroll =
        h.embedder->PostPrerollAction(raster_thread_merger);
    if (preroll != PostPrerollResult::kSkipAndRetryFrame) {
      h.embedder->SubmitFlutterView(
          kImplicitViewId, nullptr, nullptr,
          std::make_unique<SurfaceFrame>(
              SkSurfaces::Null(size.width, size.height), h.framebuffer_info,
              [](const SurfaceFrame&, DlCanvas*) { return true; },
              [](const SurfaceFrame&) { return true; }, size));
    }
    h.embedder->EndFrame(preroll != PostPrerollResult::kSuccess,
                         raster_thread_merger);
    return preroll;
  };

  // Allocate overlay 0 at frame_size1, then expire the merge lease so threads
  // unmerge while overlay 0 remains cached in SurfacePool.
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock,
              FlutterViewDisplayOverlaySurface(
                  HcResizeTestFixture::kFirstOverlayId, _, _, _, _))
      .Times(::testing::AtLeast(1));
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), [&]() {
    raster_thread_merger->MergeWithLease(
        HcResizeTestFixture::kInitialMergeLease);
    run_hc_frame(h.frame_size1);
    run_hc_frame(h.frame_size1);
    h.embedder->BeginFrame(nullptr, raster_thread_merger);
    h.embedder->PrepareFlutterView(h.frame_size1,
                                   HcResizeTestFixture::kDevicePixelRatio);
    h.embedder->EndFrame(false, raster_thread_merger);
    while (raster_thread_merger->IsMerged()) {
      raster_thread_merger->DecrementLease();
    }
  });
  // Drain the MaybeResizeSurfaceView task queued by PrepareFlutterView before
  // clearing and updating JNIMock expectations on the test thread.
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  ASSERT_FALSE(raster_thread_merger->IsMerged());
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame())
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(::testing::AnyNumber());
  {
    // Even though Draw 2 runs on the merged platform queue ahead of the
    // platform task posted by Draw 1's ReleaseOverlayLayers(), SurfacePool
    // flushes the pending destroy before creating overlay 1 and turns the
    // delayed platform task into a no-op.
    InSequence sequence;
    EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
    EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface())
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                HcResizeTestFixture::kSecondOverlayId, h.window))));
    EXPECT_CALL(*h.jni_mock,
                FlutterViewDisplayOverlaySurface(
                    HcResizeTestFixture::kSecondOverlayId, _, _, _, _))
        .Times(::testing::AtLeast(1));
  }

  fml::AutoResetWaitableEvent platform_held;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_held.Signal();
    release_platform.Wait();
  });
  platform_held.Wait();

  fml::AutoResetWaitableEvent draw1_entered;
  fml::AutoResetWaitableEvent draw2_queued;
  fml::AutoResetWaitableEvent draw1_finished;
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    draw1_entered.Signal();
    draw2_queued.Wait();
    EXPECT_EQ(PostPrerollResult::kSkipAndRetryFrame,
              run_hc_frame(h.frame_size2));
    h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
      if (raster_thread_merger->IsOnRasterizingThread()) {
        run_hc_frame(h.frame_size2);
      }
    });
    draw1_finished.Signal();
  });

  draw1_entered.Wait();
  // Queued before Draw 1 posts ReleaseOverlayLayers() to platform_queue, giving
  // this raster task an earlier MessageLoopTaskQueues order_ stamp.
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    if (!raster_thread_merger->IsOnRasterizingThread()) {
      return;
    }
    if (run_hc_frame(h.frame_size2) == PostPrerollResult::kResubmitFrame) {
      h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
        if (raster_thread_merger->IsOnRasterizingThread()) {
          run_hc_frame(h.frame_size2);
        }
      });
    }
  });
  draw2_queued.Signal();
  draw1_finished.Wait();

  release_platform.Signal();
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), [&]() {
    h.embedder->Teardown();
    while (raster_thread_merger->IsMerged()) {
      raster_thread_merger->DecrementLease();
    }
  });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder, TeardownDrainsPendingAsyncOverlayDestroy) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);
  h.DrawMergedOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  std::atomic<int> destroy_calls{0};
  ON_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces())
      .WillByDefault([&]() { destroy_calls.fetch_add(1); });
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);

  int destroy_calls_upon_teardown_return = -1;
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), [&]() {
    // While the platform thread is in this Looper turn, 1.raster finishes
    // PrepareFlutterView(frame_size2) and queues its async destroy behind us.
    PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
      h.embedder->PrepareFlutterView(h.frame_size2,
                                     HcResizeTestFixture::kDevicePixelRatio);
    });
    h.embedder->Teardown();
    destroy_calls_upon_teardown_return = destroy_calls.load();
  });

  // Drain the queued platform task and verify no JNI call runs after Teardown.
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  EXPECT_EQ(1, destroy_calls_upon_teardown_return);
  EXPECT_EQ(1, destroy_calls.load());
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     NullOverlaySurfaceFrameSkipsDisplayAndSubmit) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  const DlISize frame_size(HcResizeTestFixture::kInitialViewportPx,
                           HcResizeTestFixture::kInitialViewportPx);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  MutatorsStack stack;

  auto surface_mock = std::make_unique<SurfaceMock>();
  // Frame 1 succeeds so Frame 2 enters SubmitFlutterView with
  // previous_frame_view_count_ > 0 (should_submit_current_frame == true);
  // Frame 2 returns nullptr from AcquireFrame.
  EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
      .WillOnce([framebuffer_info, frame_size](const DlISize&) {
        return std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(frame_size.width, frame_size.height),
            framebuffer_info,
            [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, frame_size);
      })
      .WillOnce(Return(ByMove(std::unique_ptr<SurfaceFrame>())));

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      fml::MakeCopyable([surface_mock = std::move(surface_mock)]() mutable {
        auto android_surface = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
            .WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, CreateGPUSurface(_))
            .WillOnce(Return(ByMove(std::move(surface_mock))));
        return android_surface;
      }));

  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  auto raster_thread_merger = fml::MakeRefCounted<fml::RasterThreadMerger>(
      task_runners.GetPlatformTaskRunner()->GetTaskQueueId(),
      task_runners.GetRasterTaskRunner()->GetTaskQueueId());
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, task_runners);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, window))));
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);

  PostTaskSync(task_runners.GetPlatformTaskRunner(), [&]() {
    embedder->PrepareFlutterView(frame_size,
                                 HcResizeTestFixture::kDevicePixelRatio);
    embedder->PrerollCompositeEmbeddedView(
        HcResizeTestFixture::kTestPlatformViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(HcResizeTestFixture::kPlatformViewLogicalSize,
                   HcResizeTestFixture::kPlatformViewLogicalSize),
            stack));
    embedder->CompositeEmbeddedView(HcResizeTestFixture::kTestPlatformViewId)
        ->DrawRect(DlRect::MakeXYWH(HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical),
                   DlPaint());
    embedder->SubmitFlutterView(
        kImplicitViewId, nullptr, nullptr,
        std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(frame_size.width, frame_size.height),
            framebuffer_info,
            [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, frame_size));
    embedder->EndFrame(false, raster_thread_merger);
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // Frame 2 has previous_frame_view_count_ == 1, so root_submitted becomes
  // true while the null overlay SurfaceFrame skips both
  // FlutterViewDisplayOverlaySurface and overlay Submit().
  bool root_submitted = false;
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(1);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(0);

  PostTaskSync(task_runners.GetPlatformTaskRunner(), [&]() {
    embedder->PrepareFlutterView(frame_size,
                                 HcResizeTestFixture::kDevicePixelRatio);
    embedder->PrerollCompositeEmbeddedView(
        HcResizeTestFixture::kTestPlatformViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(HcResizeTestFixture::kPlatformViewLogicalSize,
                   HcResizeTestFixture::kPlatformViewLogicalSize),
            stack));
    embedder->CompositeEmbeddedView(HcResizeTestFixture::kTestPlatformViewId)
        ->DrawRect(DlRect::MakeXYWH(HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlayOriginLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical,
                                    HcResizeTestFixture::kOverlaySizeLogical),
                   DlPaint());
    embedder->SubmitFlutterView(
        kImplicitViewId, nullptr, nullptr,
        std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(frame_size.width, frame_size.height),
            framebuffer_info,
            [&](const SurfaceFrame&, DlCanvas*) {
              root_submitted = true;
              return true;
            },
            [](const SurfaceFrame&) { return true; }, frame_size));
    embedder->EndFrame(false, raster_thread_merger);
  });
  EXPECT_TRUE(root_submitted);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { embedder->Teardown(); });
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder2,
     SwapsTransactionsAfterDisplayingPlatformViews) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.raster_thread->GetTaskRunner(),    // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
    EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
        .WillRepeatedly(Return(true));
    EXPECT_CALL(*android_surface, CreateGPUSurface(_))
        .WillRepeatedly(Return(ByMove(std::make_unique<SurfaceMock>())));
    return android_surface;
  });

  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .WillRepeatedly(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      *android_context, jni_mock, surface_factory, task_runners);

  const DlISize frame_size(100, 100);
  const int64_t view_id = 42;
  MutatorsStack mutators;
  DlMatrix matrix = DlMatrix::MakeTranslation({0, 0});

  embedder->PrepareFlutterView(frame_size, 1.0);
  embedder->PrerollCompositeEmbeddedView(
      view_id,
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(50, 50), mutators));
  embedder->CompositeEmbeddedView(view_id);

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(*jni_mock, sealFrameTransactions());
    EXPECT_CALL(*jni_mock, onDisplayPlatformView2(view_id, 0, 0, 50, 50, 50, 50,
                                                  mutators));
    EXPECT_CALL(*jni_mock, swapTransaction());
    EXPECT_CALL(*jni_mock, onEndFrame2());
  }

  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(100, 100), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size);

  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(surface_frame));
    fml::TaskRunner::RunNowOrPostTask(task_runners.GetPlatformTaskRunner(),
                                      [&latch]() { latch.Signal(); });
  });
  latch.Wait();

  embedder->Teardown();
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder2, FrameSizeChangeDoesNotDestroySurfaces) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.raster_thread->GetTaskRunner(),    // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  const DlISize frame_size1(100, 100);
  const DlISize frame_size2(200, 200);
  SurfaceFrame::FramebufferInfo framebuffer_info;

  auto surface_mock = std::make_unique<SurfaceMock>();
  EXPECT_CALL(*surface_mock, AcquireFrame(frame_size1))
      .WillOnce(Return(ByMove(std::make_unique<SurfaceFrame>(
          SkSurfaces::Null(100, 100), framebuffer_info,
          [](const SurfaceFrame&, DlCanvas*) { return true; },
          [](const SurfaceFrame&) { return true; }, frame_size1))));
  EXPECT_CALL(*surface_mock, AcquireFrame(frame_size2))
      .WillOnce(Return(ByMove(std::make_unique<SurfaceFrame>(
          SkSurfaces::Null(200, 200), framebuffer_info,
          [](const SurfaceFrame&, DlCanvas*) { return true; },
          [](const SurfaceFrame&) { return true; }, frame_size2))));

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      fml::MakeCopyable([frame_size2,
                         surface_mock = std::move(surface_mock)]() mutable {
        auto android_surface = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
            .WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, CreateGPUSurface(_))
            .WillOnce(Return(ByMove(std::move(surface_mock))));
        EXPECT_CALL(*android_surface, OnScreenSurfaceResize(frame_size2))
            .Times(1);
        return android_surface;
      }));

  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));
  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(0);

  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      *android_context, jni_mock, surface_factory, task_runners);

  const int64_t view_id = 42;
  MutatorsStack mutators;
  DlMatrix matrix = DlMatrix::MakeTranslation({0, 0});
  DlPaint rect_paint;
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  // First frame with size 100x100
  embedder->PrepareFlutterView(frame_size1, 1.0);
  embedder->PrerollCompositeEmbeddedView(
      view_id,
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(50, 50), mutators));
  auto canvas1 = embedder->CompositeEmbeddedView(view_id);
  canvas1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);

  EXPECT_CALL(*jni_mock, sealFrameTransactions());
  EXPECT_CALL(*jni_mock,
              onDisplayPlatformView2(view_id, 0, 0, 50, 50, 50, 50, mutators));
  EXPECT_CALL(*jni_mock, swapTransaction());
  EXPECT_CALL(*jni_mock, onEndFrame2());

  auto surface_frame1 = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(100, 100), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size1);

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(surface_frame1));
  });
  // Drain the work that SubmitFlutterView posted to the platform thread.
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  // Second frame with size 200x200 (simulating rotation/resize).
  // PrepareFlutterView should NOT destroy overlay surfaces.
  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(200, 200));
  embedder->PrepareFlutterView(frame_size2, 1.0);
  embedder->PrerollCompositeEmbeddedView(
      view_id,
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100), mutators));
  auto canvas2 = embedder->CompositeEmbeddedView(view_id);
  canvas2->DrawRect(DlRect::MakeXYWH(0, 0, 100, 100), rect_paint);

  EXPECT_CALL(*jni_mock, sealFrameTransactions());
  EXPECT_CALL(*jni_mock, onDisplayPlatformView2(view_id, 0, 0, 100, 100, 100,
                                                100, mutators));
  EXPECT_CALL(*jni_mock, swapTransaction());
  EXPECT_CALL(*jni_mock, onEndFrame2());

  auto surface_frame2 = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(200, 200), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size2);

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(surface_frame2));
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
  embedder->Teardown();
  embedder.reset();
}

// Regression test for the HCPP rotation ANR.
//
// The platform thread is unavailable while it is inside
// ViewRootImpl.performTraversals dispatching surfaceChanged, so a frame resize
// on the raster thread must not block waiting on it. Rather than reproduce both
// halves of the deadlock, this occupies the platform thread directly and
// asserts the raster thread still makes progress.
TEST(AndroidExternalViewEmbedder2, ResizeDoesNotBlockRasterOnPlatformThread) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.raster_thread->GetTaskRunner(),    // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  const DlISize frame_size1(100, 100);
  const DlISize frame_size2(200, 200);
  SurfaceFrame::FramebufferInfo framebuffer_info;

  auto surface_mock = std::make_unique<SurfaceMock>();
  EXPECT_CALL(*surface_mock, AcquireFrame(frame_size1))
      .WillOnce(Return(ByMove(std::make_unique<SurfaceFrame>(
          SkSurfaces::Null(100, 100), framebuffer_info,
          [](const SurfaceFrame&, DlCanvas*) { return true; },
          [](const SurfaceFrame&) { return true; }, frame_size1))));

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      fml::MakeCopyable([surface_mock = std::move(surface_mock)]() mutable {
        auto android_surface = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
            .WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, CreateGPUSurface(_))
            .WillOnce(Return(ByMove(std::move(surface_mock))));
        return android_surface;
      }));

  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .Times(1)
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      *android_context, jni_mock, surface_factory, task_runners);

  const int64_t view_id = 42;
  MutatorsStack mutators;
  DlMatrix matrix = DlMatrix::MakeTranslation({0, 0});
  DlPaint rect_paint;
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  // Run one frame so the overlay layer exists. Without a layer, DestroySurfaces
  // early-returns and there is nothing to deadlock on.
  embedder->PrepareFlutterView(frame_size1, 1.0);
  embedder->PrerollCompositeEmbeddedView(
      view_id,
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(50, 50), mutators));
  auto canvas = embedder->CompositeEmbeddedView(view_id);
  canvas->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);

  EXPECT_CALL(*jni_mock, sealFrameTransactions());
  EXPECT_CALL(*jni_mock,
              onDisplayPlatformView2(view_id, 0, 0, 50, 50, 50, 50, mutators));
  EXPECT_CALL(*jni_mock, swapTransaction());
  EXPECT_CALL(*jni_mock, onEndFrame2());

  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(100, 100), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size1);

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(surface_frame));
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  // Occupy the platform thread, standing in for a layout traversal.
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(200, 200));

  // The resize must complete without the platform thread running anything.
  fml::AutoResetWaitableEvent resize_done;
  task_runners.GetRasterTaskRunner()->PostTask([&]() {
    embedder->PrepareFlutterView(frame_size2, 1.0);
    resize_done.Signal();
  });
  const bool timed_out =
      resize_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(10));

  // Release the platform thread before asserting so that a regression fails
  // this test instead of hanging the suite.
  release_platform.Signal();
  if (timed_out) {
    resize_done.Wait();
  }
  EXPECT_FALSE(timed_out)
      << "PrepareFlutterView blocked the raster thread on the platform thread";

  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
  embedder->Teardown();
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder2,
     SealsFrameTransactionsOnRasterThreadBeforePlatformTaskRuns) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi | ThreadHost::Type::kRaster);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.raster_thread->GetTaskRunner(),    // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  const DlISize frame_size(100, 100);
  SurfaceFrame::FramebufferInfo framebuffer_info;

  std::vector<std::string> events;
  auto surface_mock = std::make_unique<SurfaceMock>();
  EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
      .WillOnce(Return(ByMove(std::make_unique<SurfaceFrame>(
          SkSurfaces::Null(100, 100), framebuffer_info,
          [&](const SurfaceFrame&, DlCanvas*) {
            events.push_back("submit_overlay_1");
            return true;
          },
          [](const SurfaceFrame&) { return true; }, frame_size))));

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      fml::MakeCopyable([surface_mock = std::move(surface_mock)]() mutable {
        auto android_surface = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
            .WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, CreateGPUSurface(_))
            .WillOnce(Return(ByMove(std::move(surface_mock))));
        return android_surface;
      }));

  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);
  EXPECT_CALL(*jni_mock, createOverlaySurface2())
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      *android_context, jni_mock, surface_factory, task_runners);

  const int64_t view_id = 42;
  MutatorsStack mutators;
  DlMatrix matrix = DlMatrix::MakeTranslation({0, 0});
  DlPaint rect_paint;
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  // Create the overlay surface on a warm-up frame before occupying the platform
  // thread, since first-time overlay creation blocks on the platform thread.
  embedder->PrepareFlutterView(frame_size, 1.0);
  embedder->PrerollCompositeEmbeddedView(
      view_id,
      std::make_unique<EmbeddedViewParams>(matrix, DlSize(50, 50), mutators));
  embedder->CompositeEmbeddedView(view_id);
  EXPECT_CALL(*jni_mock, sealFrameTransactions());
  EXPECT_CALL(*jni_mock,
              onDisplayPlatformView2(view_id, 0, 0, 50, 50, 50, 50, mutators));
  EXPECT_CALL(*jni_mock, swapTransaction());
  EXPECT_CALL(*jni_mock, onEndFrame2());
  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    auto warmup_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(100, 100), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, frame_size);
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(warmup_frame));
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  // Hold the platform thread so two raster frames complete before either
  // posted platform task can run.
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  EXPECT_CALL(*jni_mock, sealFrameTransactions())
      .Times(2)
      .WillRepeatedly([&]() { events.push_back("seal"); });
  EXPECT_CALL(*jni_mock,
              onDisplayPlatformView2(view_id, 0, 0, 50, 50, 50, 50, mutators))
      .WillOnce([&](int32_t, int32_t, int32_t, int32_t, int32_t, int32_t,
                    int32_t,
                    const MutatorsStack&) { events.push_back("display_1"); });
  EXPECT_CALL(*jni_mock, hidePlatformView2(view_id)).WillOnce([&](int32_t) {
    events.push_back("hide_2");
  });
  EXPECT_CALL(*jni_mock, swapTransaction()).Times(2).WillRepeatedly([&]() {
    events.push_back("swap");
  });
  EXPECT_CALL(*jni_mock, onEndFrame2()).Times(2).WillRepeatedly([&]() {
    events.push_back("end");
  });

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    // Frame 1: platform view + overlay layer.
    embedder->PrepareFlutterView(frame_size, 1.0);
    embedder->PrerollCompositeEmbeddedView(
        view_id,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(50, 50), mutators));
    auto canvas1 = embedder->CompositeEmbeddedView(view_id);
    canvas1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    auto frame1 = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(100, 100), framebuffer_info,
        [&](const SurfaceFrame&, DlCanvas*) {
          events.push_back("submit_main_1");
          return true;
        },
        [](const SurfaceFrame&) { return true; }, frame_size);
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(frame1));

    // Frame 2: no platform views.
    embedder->PrepareFlutterView(frame_size, 1.0);
    auto frame2 = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(100, 100), framebuffer_info,
        [&](const SurfaceFrame&, DlCanvas*) {
          events.push_back("submit_main_2");
          return true;
        },
        [](const SurfaceFrame&) { return true; }, frame_size);
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(frame2));
  });

  release_platform.Signal();
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});

  EXPECT_EQ(events, (std::vector<std::string>{
                        "submit_overlay_1",
                        "submit_main_1",
                        "seal",
                        "submit_main_2",
                        "seal",
                        "display_1",
                        "swap",
                        "end",
                        "hide_2",
                        "swap",
                        "end",
                    }));

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
  embedder->Teardown();
  embedder.reset();
}

}  // namespace testing
}  // namespace flutter
