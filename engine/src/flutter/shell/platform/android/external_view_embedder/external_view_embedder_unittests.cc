// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <atomic>
#include <memory>

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/make_copyable.h"
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

TEST(AndroidExternalViewEmbedder, PlatformViewRect) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(100, 100)).Times(1);
  embedder->BeginFrame(nullptr);
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
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
}

TEST(AndroidExternalViewEmbedder, PlatformViewRectChangedParams) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(100, 100)).Times(1);
  embedder->BeginFrame(nullptr);
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
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
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

  // A 1080x2400 screen at the device pixel ratio of, say, a Pixel 6.
  constexpr double kDevicePixelRatio = 2.625;
  const auto frame_size = DlISize(1080, 2400);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1080, 2400)).Times(1);
  embedder->BeginFrame(nullptr);
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

  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    // Both the bounding rect and the size of the view itself cover the whole
    // screen; neither is 1079x2399.
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 1080, 2400,
                                                            1080, 2400, stack));
    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
  }

  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      SkSurfaces::Null(1080, 2400), framebuffer_info,
      [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
      [](const SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/frame_size);
  embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                              std::move(surface_frame));
  embedder->EndFrame();

  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
}

TEST(AndroidExternalViewEmbedder, SubmitFlutterView) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
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

  // ------------------ First frame (no platform views) ------------------ //
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
    embedder->EndFrame();
  }

  // ------------------ Second frame (Frame 0 with PV: root composite)
  // ------------------ //
  {
    EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    MutatorsStack stack1;
    DlMatrix scale = DlMatrix::MakeScale({1.5, 1.5, 1});
    DlMatrix trans = DlMatrix::MakeTranslation({100, 100});
    DlMatrix matrix1 = scale * trans;
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    auto view_params_1 =
        std::make_unique<EmbeddedViewParams>(matrix1, DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    DlPaint rect_paint;
    rect_paint.setColor(DlColor::kCyan());
    rect_paint.setDrawStyle(DlDrawStyle::kFill);
    canvas_1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    // Frame 0 composites onto root surface without creating overlays.
    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(_, _)).Times(0);
    EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
        .Times(0);
    {
      ::testing::InSequence sequence;
      EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
      EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                                 0, 150, 150, 300, 300, 300, 300, stack1));
      EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    }

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
    EXPECT_TRUE(did_submit_frame);
    embedder->EndFrame();

    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  }

  // ------------------ Third frame (Frame 1: creates overlay)
  // ------------------ //
  {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    MutatorsStack stack1;
    DlMatrix scale = DlMatrix::MakeScale({1.5, 1.5, 1});
    DlMatrix trans = DlMatrix::MakeTranslation({100, 100});
    DlMatrix matrix1 = scale * trans;
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    auto view_params_1 =
        std::make_unique<EmbeddedViewParams>(matrix1, DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    DlPaint rect_paint;
    rect_paint.setColor(DlColor::kCyan());
    rect_paint.setDrawStyle(DlDrawStyle::kFill);
    canvas_1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(1000, 1000))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                0, window))));
    {
      ::testing::InSequence sequence;
      EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
      EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                                 0, 150, 150, 300, 300, 300, 300, stack1));
      EXPECT_CALL(*jni_mock,
                  FlutterViewDisplayOverlaySurface(0, 150, 150, 100, 100));
      EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    }

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
    EXPECT_TRUE(did_submit_frame);
    embedder->EndFrame();

    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  }

  // ------------------ Fourth frame (recycles overlay) ------------------ //
  {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    MutatorsStack stack1;
    DlMatrix scale = DlMatrix::MakeScale({1.5, 1.5, 1});
    DlMatrix trans = DlMatrix::MakeTranslation({100, 100});
    DlMatrix matrix1 = scale * trans;
    stack1.PushTransform(scale);
    stack1.PushTransform(trans);
    auto view_params_1 =
        std::make_unique<EmbeddedViewParams>(matrix1, DlSize(200, 200), stack1);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params_1));
    auto canvas_1 = embedder->CompositeEmbeddedView(0);

    DlPaint rect_paint;
    rect_paint.setColor(DlColor::kCyan());
    rect_paint.setDrawStyle(DlDrawStyle::kFill);
    canvas_1->DrawRect(DlRect::MakeXYWH(0, 0, 50, 50), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(50, 50, 200, 200), rect_paint);
    canvas_1->DrawRect(DlRect::MakeXYWH(150, 150, 100, 100), rect_paint);

    EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(_, _)).Times(0);
    {
      ::testing::InSequence sequence;
      EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
      EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(
                                 0, 150, 150, 300, 300, 300, 300, stack1));
      EXPECT_CALL(*jni_mock,
                  FlutterViewDisplayOverlaySurface(0, 150, 150, 100, 100));
      EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    }

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
    EXPECT_TRUE(did_submit_frame);
    embedder->EndFrame();

    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  }

  // ------------------ Fifth frame (transition out of PVs) ------------------
  // //
  {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    EXPECT_CALL(*jni_mock,
                FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
        .Times(0);
    EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
        .Times(0);
    {
      ::testing::InSequence sequence;
      EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
      EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    }

    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    embedder->EndFrame();

    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  }
}

TEST(AndroidExternalViewEmbedder, OverlayCoverTwoPlatformViews) {
  // In this test we will simulate two Android views appearing on the screen
  // with a rect intersecting both of them

  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
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

  auto rect_paint = DlPaint();
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);

  auto submit_two_pv_scene = [&](bool expect_overlay) {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);
    {
      DlMatrix matrix = DlMatrix::MakeTranslation({100, 100});
      MutatorsStack stack;
      embedder->PrerollCompositeEmbeddedView(
          0, std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100),
                                                  stack));
    }
    {
      DlMatrix matrix = DlMatrix::MakeTranslation({300, 100});
      MutatorsStack stack;
      embedder->PrerollCompositeEmbeddedView(
          1, std::make_unique<EmbeddedViewParams>(matrix, DlSize(100, 100),
                                                  stack));
    }
    embedder->CompositeEmbeddedView(1)->DrawRect(
        DlRect::MakeXYWH(150, 50, 200, 200), rect_paint);

    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    EXPECT_CALL(*jni_mock,
                FlutterViewOnDisplayPlatformView(0, 100, 100, 100, 100, 150,
                                                 150, MutatorsStack()));
    EXPECT_CALL(*jni_mock,
                FlutterViewOnDisplayPlatformView(1, 300, 100, 100, 100, 150,
                                                 150, MutatorsStack()));
    if (expect_overlay) {
      EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(1000, 1000))
          .WillRepeatedly([&]() {
            return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                1, window);
          });
      EXPECT_CALL(*jni_mock,
                  FlutterViewDisplayOverlaySurface(1, 150, 100, 200, 100))
          .Times(1);
    }
    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());

    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    embedder->EndFrame();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  };

  // Frame 0 transitions into Hybrid Composition; Frame 1 creates overlay.
  submit_two_pv_scene(/*expect_overlay=*/false);
  submit_two_pv_scene(/*expect_overlay=*/true);
}

TEST(AndroidExternalViewEmbedder, SubmitFrameOverlayComposition) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
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

  auto rect_paint = DlPaint();
  rect_paint.setColor(DlColor::kCyan());
  rect_paint.setDrawStyle(DlDrawStyle::kFill);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);

  auto submit_scene = [&](bool expect_overlay) {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);
    MutatorsStack stack0;
    stack0.PushTransform(DlMatrix::MakeTranslation({0, 0}));
    embedder->PrerollCompositeEmbeddedView(
        0, std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(200, 200),
                                                stack0));
    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(25, 25, 80, 150), rect_paint);

    MutatorsStack stack1;
    stack1.PushTransform(DlMatrix::MakeTranslation({0, 100}));
    embedder->PrerollCompositeEmbeddedView(
        1, std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(100, 100),
                                                stack1));
    embedder->CompositeEmbeddedView(1)->DrawRect(
        DlRect::MakeXYWH(25, 25, 80, 50), rect_paint);
    embedder->CompositeEmbeddedView(1)->DrawRect(
        DlRect::MakeXYWH(75, 75, 30, 100), rect_paint);

    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack0));
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(1, 0, 0, 100, 100,
                                                            150, 150, stack1));
    if (expect_overlay) {
      EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(1000, 1000))
          .WillRepeatedly([&]() {
            return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                1, window);
          });
      EXPECT_CALL(*jni_mock,
                  FlutterViewDisplayOverlaySurface(1, 25, 25, 80, 150))
          .Times(2);
    }
    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());

    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    embedder->EndFrame();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  };

  submit_scene(/*expect_overlay=*/false);
  submit_scene(/*expect_overlay=*/true);
}

TEST(AndroidExternalViewEmbedder, SubmitFramePlatformViewWithoutAnyOverlay) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  auto gr_context = GrDirectContext::MakeMock(nullptr);
  auto frame_size = DlISize(1000, 1000);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      []() { return std::make_unique<AndroidSurfaceMock>(); });
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, GetTaskRunnersForFixture());

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(_, _)).Times(0);

  for (int i = 0; i < 2; ++i) {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    DlMatrix matrix;
    MutatorsStack stack;
    stack.PushTransform(DlMatrix::MakeTranslation({0, 0}));
    embedder->PrerollCompositeEmbeddedView(
        0,
        std::make_unique<EmbeddedViewParams>(matrix, DlSize(200, 200), stack));

    {
      ::testing::InSequence sequence;
      EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
      EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                              300, 300, stack));
      EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    }

    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, DlISize(800, 600));

    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    embedder->EndFrame();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  }
}

TEST(AndroidExternalViewEmbedder, DoesNotCallJNIPlatformThreadOnlyMethods) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  embedder->BeginFrame(nullptr);
  embedder->PrepareFlutterView(DlISize(10, 20), 1.0);

  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  embedder->EndFrame();
}

TEST(AndroidExternalViewEmbedder, RetireOverlayLayersByIdOnSizeChange) {
  auto jni_mock = std::make_shared<JNIMock>();

  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
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

  auto submit_frame = [&](bool expect_overlay) {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);
    MutatorsStack stack1;
    embedder->PrerollCompositeEmbeddedView(
        0, std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(200, 200),
                                                stack1));
    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(50, 50, 200, 200), DlPaint());
    if (expect_overlay) {
      EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(1000, 1000))
          .WillOnce(Return(
              ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                  0, window))));
      EXPECT_CALL(*jni_mock,
                  FlutterViewDisplayOverlaySurface(0, 50, 50, 150, 150));
    }
    EXPECT_CALL(*jni_mock, FlutterViewBeginFrame());
    EXPECT_CALL(*jni_mock, FlutterViewOnDisplayPlatformView(0, 0, 0, 200, 200,
                                                            300, 300, stack1));
    EXPECT_CALL(*jni_mock, FlutterViewEndFrame());
    auto surface_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(1000, 1000), framebuffer_info,
        [](const SurfaceFrame&, DlCanvas*) { return true; },
        [](const SurfaceFrame&) { return true; }, DlISize(800, 600));
    embedder->SubmitFlutterView(kImplicitViewId, gr_context.get(), nullptr,
                                std::move(surface_frame));
    embedder->EndFrame();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
  };

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);
  submit_frame(/*expect_overlay=*/false);
  submit_frame(/*expect_overlay=*/true);

  // Changing the frame size must not destroy overlay surfaces inline inside
  // PrepareFlutterView; instead EndFrame flushes retired overlay ID {0} via
  // FlutterViewDestroyOverlaySurfacesByIds on the platform task runner (X6/X9).
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  embedder->PrepareFlutterView(DlISize(30, 40), 1.0);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(30, 40)).Times(1);
  EXPECT_CALL(*jni_mock,
              FlutterViewDestroyOverlaySurfacesByIds(std::vector<int32_t>{0}))
      .Times(1);
  embedder->EndFrame();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());
}

TEST(AndroidExternalViewEmbedder, Teardown) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
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

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(1000, 1000)).Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(1000, 1000))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              0, window))));

  for (int i = 0; i < 2; ++i) {
    embedder->BeginFrame(nullptr);
    embedder->PrepareFlutterView(frame_size, 1.5);

    MutatorsStack stack;
    auto view_params = std::make_unique<EmbeddedViewParams>(
        DlMatrix(), DlSize(200, 200), stack);

    embedder->PrerollCompositeEmbeddedView(0, std::move(view_params));

    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(50, 50, 200, 200), DlPaint());

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

    embedder->EndFrame();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
    fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  }

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

  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  embedder->BeginFrame(nullptr);

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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
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

  void DrawOverlayFrame(const DlISize& size, bool expect_overlay = true) {
    PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
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
      embedder->EndFrame();
    });
    (void)expect_overlay;
    PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
    PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});
  }
};

}  // namespace

// Regression test for a raster/platform thread deadlock with Hybrid
// Composition (HC).
//
// In unmerged HC, frame resizes on the raster thread retire old overlay layers
// without waiting for the platform thread (which may be blocked waiting for the
// raster thread during NotifyChanged / teardown).
TEST(AndroidExternalViewEmbedder, ResizeDoesNotBlockRasterOnPlatformThread) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(
                  HcResizeTestFixture::kTestPlatformViewId, 0, 0,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPhysicalViewSizePx,
                  HcResizeTestFixture::kPhysicalViewSizePx, h.stack))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(
                               HcResizeTestFixture::kFirstOverlayId,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kClippedOverlaySizePx,
                               HcResizeTestFixture::kClippedOverlaySizePx))
      .Times(1);
  // Frame 0 transitions to HC; Frame 1 creates overlay 0.
  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Occupy the platform thread, standing in for a platform thread waiting for
  // the raster thread.
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  // Resizing on the raster thread must not wait on the platform thread.
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  fml::AutoResetWaitableEvent resize_done;
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    h.embedder->PrepareFlutterView(h.frame_size2,
                                   HcResizeTestFixture::kDevicePixelRatio);
    h.embedder->EndFrame();
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

    EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
        .Times(::testing::AnyNumber());
    EXPECT_CALL(*h.jni_mock,
                FlutterViewDestroyOverlaySurfacesByIds(
                    std::vector<int32_t>{HcResizeTestFixture::kFirstOverlayId}))
        .Times(1);

    release_platform.Signal();
    PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  }
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // The next frame with an overlay allocates a new overlay on the raster
  // thread without destroying again.
  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(1);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(1);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(
                  HcResizeTestFixture::kTestPlatformViewId, 0, 0,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPlatformViewLogicalSize,
                  HcResizeTestFixture::kPhysicalViewSizePx,
                  HcResizeTestFixture::kPhysicalViewSizePx, h.stack));
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size2.width, h.frame_size2.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kSecondOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(
                               HcResizeTestFixture::kSecondOverlayId,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kClippedOverlaySizePx,
                               HcResizeTestFixture::kClippedOverlaySizePx));
  h.DrawOverlayFrame(h.frame_size2);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Teardown on the platform thread destroys overlays inline (X8).
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     ResizeCreatesNewOverlayOnRasterAndDestroysOldByIdBeforePresent) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock,
              FlutterViewDisplayOverlaySurface(
                  HcResizeTestFixture::kFirstOverlayId, _, _, _, _))
      .Times(1);
  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Hold the platform thread while raster prepares frame_size2 and submits a
  // resized frame without going through EndFrame in between (simulating X9).
  fml::AutoResetWaitableEvent platform_held;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_held.Signal();
    release_platform.Wait();
  });
  platform_held.Wait();

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  {
    InSequence sequence;
    // Raster thread allocates new overlay first (X1/V6), while platform is
    // held.
    EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                                 h.frame_size2.width, h.frame_size2.height))
        .WillOnce(Return(
            ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
                HcResizeTestFixture::kSecondOverlayId, h.window))));
    // Once platform runs Present, BeginFrame/ops/EndFrame present overlay 1,
    // followed by destroying retired overlay 0 by ID.
    EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(1);
    EXPECT_CALL(*h.jni_mock,
                FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
        .Times(1);
    EXPECT_CALL(*h.jni_mock,
                FlutterViewDisplayOverlaySurface(
                    HcResizeTestFixture::kSecondOverlayId, _, _, _, _))
        .Times(1);
    EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(1);
    EXPECT_CALL(*h.jni_mock,
                FlutterViewDestroyOverlaySurfacesByIds(
                    std::vector<int32_t>{HcResizeTestFixture::kFirstOverlayId}))
        .Times(1);
  }

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->PrepareFlutterView(h.frame_size2,
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
    h.embedder->SubmitFlutterView(
        kImplicitViewId, nullptr, nullptr,
        std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(h.frame_size2.width, h.frame_size2.height),
            h.framebuffer_info,
            [](const SurfaceFrame& surface_frame, DlCanvas* canvas) {
              return true;
            },
            [](const SurfaceFrame& surface_frame) { return true; },
            h.frame_size2));
    h.embedder->EndFrame();
  });

  release_platform.Signal();
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), []() {});
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder, TeardownDrainsPendingAsyncOverlayDestroy) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);
  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfacesByIds(_)).Times(0);
  std::atomic<int> destroy_calls{0};
  ON_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces())
      .WillByDefault([&]() { destroy_calls.fetch_add(1); });
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);

  int destroy_calls_upon_teardown_return = -1;
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), [&]() {
    // While the platform thread is in this Looper turn, 1.raster resizes and
    // queues its async retired-ID cleanup behind Teardown.
    PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
      h.embedder->PrepareFlutterView(h.frame_size2,
                                     HcResizeTestFixture::kDevicePixelRatio);
      h.embedder->EndFrame();
    });
    h.embedder->Teardown();
    destroy_calls_upon_teardown_return = destroy_calls.load();
  });

  // Drain the queued platform task and verify stale task became a no-op.
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  EXPECT_EQ(1, destroy_calls_upon_teardown_return);
  EXPECT_EQ(1, destroy_calls.load());
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder, NullOverlaySurfaceFrameAbortsPartialPresent) {
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
  // Frame 1 acquires and submits overlay 0 cleanly; Frame 2 returns nullptr
  // from AcquireFrame so partial Present must be aborted (X3).
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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, task_runners);

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(frame_size.width,
                                                         frame_size.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, window))));
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);

  auto submit_frame = [&](const std::function<bool(const SurfaceFrame&,
                                                   DlCanvas*)>& on_submit) {
    PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
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
          ->DrawRect(
              DlRect::MakeXYWH(HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlayOriginLogical,
                               HcResizeTestFixture::kOverlaySizeLogical,
                               HcResizeTestFixture::kOverlaySizeLogical),
              DlPaint());
      embedder->SubmitFlutterView(
          kImplicitViewId, nullptr, nullptr,
          std::make_unique<SurfaceFrame>(
              SkSurfaces::Null(frame_size.width, frame_size.height),
              framebuffer_info, on_submit,
              [](const SurfaceFrame&) { return true; }, frame_size));
      embedder->EndFrame();
    });
    PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
    PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});
  };

  submit_frame([](const SurfaceFrame&, DlCanvas*) { return true; });
  submit_frame([](const SurfaceFrame&, DlCanvas*) { return true; });
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // Frame 2 fails AcquireFrame -> root submits, partial Present is aborted
  // (no BeginFrame / DisplayPlatformView / DisplayOverlaySurface / EndFrame),
  // and the platform thread drains the aborted root ImageReader buffer.
  bool root_submitted = false;
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDrainAbortedFrame(std::vector<int32_t>{}))
      .Times(1);

  submit_frame([&](const SurfaceFrame&, DlCanvas*) {
    root_submitted = true;
    return true;
  });
  EXPECT_TRUE(root_submitted);
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { embedder->Teardown(); });
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder, ReadyForNextFrameBackpressureAndResume) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(1);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(1);

  fml::AutoResetWaitableEvent platform_held;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_held.Signal();
    release_platform.Wait();
  });
  platform_held.Wait();

  fml::AutoResetWaitableEvent resumed;
  bool deferred_while_in_flight = false;
  bool ready_before_present = false;
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    ready_before_present = h.embedder->ReadyForNextFrame([]() {});
    h.embedder->PrepareFlutterView(h.frame_size1,
                                   HcResizeTestFixture::kDevicePixelRatio);
    h.embedder->PrerollCompositeEmbeddedView(
        HcResizeTestFixture::kTestPlatformViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(HcResizeTestFixture::kPlatformViewLogicalSize,
                   HcResizeTestFixture::kPlatformViewLogicalSize),
            h.stack));
    h.embedder->SubmitFlutterView(
        kImplicitViewId, nullptr, nullptr,
        std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(h.frame_size1.width, h.frame_size1.height),
            h.framebuffer_info,
            [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, h.frame_size1));
    h.embedder->EndFrame();
    deferred_while_in_flight =
        !h.embedder->ReadyForNextFrame([&]() { resumed.Signal(); });
  });

  EXPECT_TRUE(ready_before_present);
  EXPECT_TRUE(deferred_while_in_flight);

  release_platform.Signal();
  resumed.Wait();

  bool ready_after_present_done = false;
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    ready_after_present_done = h.embedder->ReadyForNextFrame([]() {});
  });
  EXPECT_TRUE(ready_after_present_done);

  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     CancelFrameAfterResizeFlushesRetiredOverlayIds) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);

  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(0);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewDestroyOverlaySurfacesByIds(
                  std::vector<int32_t>{HcResizeTestFixture::kFirstOverlayId}))
      .Times(1);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->PrepareFlutterView(h.frame_size2,
                                   HcResizeTestFixture::kDevicePixelRatio);
    h.embedder->CancelFrame();
  });
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(), []() {});
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder, ReuseAfterTeardownOnForegroundResume) {
  HcResizeTestFixture h;

  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kFirstOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(1);
  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Simulate surfaceDestroyed -> Teardown().
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  // Simulate surfaceCreated -> foreground resume reusing the same embedder:
  // Frame 0 re-enters HC and Frame 1 allocates a fresh overlay normally.
  EXPECT_CALL(*h.jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(2);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface(
                               h.frame_size1.width, h.frame_size1.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              HcResizeTestFixture::kSecondOverlayId, h.window))));
  EXPECT_CALL(*h.jni_mock,
              FlutterViewDisplayOverlaySurface(
                  HcResizeTestFixture::kSecondOverlayId, _, _, _, _))
      .Times(1);
  h.DrawOverlayFrame(h.frame_size1);
  h.DrawOverlayFrame(h.frame_size1);
  ::testing::Mock::VerifyAndClearExpectations(h.jni_mock.get());

  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  h.embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     MultiOverlayAbortDrainsRootAndEarlierSubmittedOverlays) {
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
  const DlISize frame_size(200, 200);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  MutatorsStack stack;

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>(
      [frame_size, framebuffer_info]() {
        auto surface_mock = std::make_unique<SurfaceMock>();
        EXPECT_CALL(*surface_mock, AcquireFrame(frame_size))
            .WillRepeatedly([framebuffer_info, frame_size](const DlISize&) {
              return std::make_unique<SurfaceFrame>(
                  SkSurfaces::Null(frame_size.width, frame_size.height),
                  framebuffer_info,
                  [](const SurfaceFrame&, DlCanvas*) { return true; },
                  [](const SurfaceFrame&) { return true; }, frame_size);
            });
        auto android_surface = std::make_unique<AndroidSurfaceMock>();
        EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, SetNativeWindow(_, _))
            .WillRepeatedly(Return(true));
        EXPECT_CALL(*android_surface, CreateGPUSurface(_))
            .Times(::testing::AtMost(1))
            .WillOnce(Return(ByMove(std::move(surface_mock))));
        return android_surface;
      });

  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, task_runners);

  auto submit_two_pv_frame = [&]() {
    PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
      embedder->PrepareFlutterView(frame_size, 1.0);
      embedder->PrerollCompositeEmbeddedView(
          0, std::make_unique<EmbeddedViewParams>(
                 DlMatrix::MakeTranslation({0, 0}), DlSize(50, 50), stack));
      embedder->CompositeEmbeddedView(0)->DrawRect(
          DlRect::MakeXYWH(10, 10, 20, 20), DlPaint());
      embedder->PrerollCompositeEmbeddedView(
          1, std::make_unique<EmbeddedViewParams>(
                 DlMatrix::MakeTranslation({100, 0}), DlSize(50, 50), stack));
      embedder->CompositeEmbeddedView(1)->DrawRect(
          DlRect::MakeXYWH(110, 10, 20, 20), DlPaint());
      embedder->SubmitFlutterView(
          kImplicitViewId, nullptr, nullptr,
          std::make_unique<SurfaceFrame>(
              SkSurfaces::Null(frame_size.width, frame_size.height),
              framebuffer_info,
              [](const SurfaceFrame&, DlCanvas*) { return true; },
              [](const SurfaceFrame&) { return true; }, frame_size));
      embedder->EndFrame();
    });
  };

  // Frame 0 enters HC mode.
  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(1);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(2);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(1);
  submit_two_pv_frame();
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // Hold platform thread so we can verify in_flight backpressure during drain.
  fml::AutoResetWaitableEvent platform_held;
  fml::AutoResetWaitableEvent release_platform;
  task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_held.Signal();
    release_platform.Wait();
  });
  platform_held.Wait();

  // Frame 1: overlay 0 succeeds and submits; overlay 1 fails allocation ->
  // must drain root + overlay 0 without BeginFrame/EndFrame and hold in_flight
  // until drain finishes.
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(frame_size.width,
                                                         frame_size.height))
      .WillOnce(Return(
          ByMove(std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
              10, window))))
      .WillOnce(Return(ByMove(nullptr)));
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewDrainAbortedFrame(std::vector<int32_t>{10}))
      .Times(1);

  submit_two_pv_frame();
  fml::AutoResetWaitableEvent resumed;
  bool deferred_during_drain = false;
  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    deferred_during_drain =
        !embedder->ReadyForNextFrame([&]() { resumed.Signal(); });
  });
  EXPECT_TRUE(deferred_during_drain);

  release_platform.Signal();
  EXPECT_FALSE(resumed.WaitWithTimeout(fml::TimeDelta::FromSeconds(5)));
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(1);
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { embedder->Teardown(); });
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     Frame0SchedulesFollowUpFrameOnPlatformThread) {
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
  const DlISize frame_size(100, 100);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  MutatorsStack stack;

  std::atomic<int> schedule_frame_calls{0};
  std::atomic<bool> schedule_frame_on_platform_thread{false};
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, nullptr, task_runners, [&]() {
        schedule_frame_on_platform_thread.store(
            task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        schedule_frame_calls.fetch_add(1);
      });

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(1);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(1);

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->PrepareFlutterView(frame_size, 1.0);
    embedder->PrerollCompositeEmbeddedView(
        0, std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(50, 50),
                                                stack));
    embedder->CompositeEmbeddedView(0)->DrawRect(
        DlRect::MakeXYWH(10, 10, 20, 20), DlPaint());
    embedder->SubmitFlutterView(
        kImplicitViewId, nullptr, nullptr,
        std::make_unique<SurfaceFrame>(
            SkSurfaces::Null(frame_size.width, frame_size.height),
            framebuffer_info,
            [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, frame_size));
    embedder->EndFrame();
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});

  EXPECT_EQ(schedule_frame_calls.load(), 1);
  EXPECT_TRUE(schedule_frame_on_platform_thread.load());

  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { embedder->Teardown(); });
  embedder.reset();
}

TEST(AndroidExternalViewEmbedder,
     TeardownSkipsDestroyWhenOverlayCreationReturnedNull) {
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
  const DlISize frame_size(100, 100);
  SurfaceFrame::FramebufferInfo framebuffer_info;
  MutatorsStack stack;

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(true));
    return android_surface;
  });

  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      *android_context, jni_mock, surface_factory, task_runners);

  auto draw_frame = [&]() {
    PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
      embedder->PrepareFlutterView(frame_size, 1.0);
      embedder->PrerollCompositeEmbeddedView(
          0, std::make_unique<EmbeddedViewParams>(DlMatrix(), DlSize(50, 50),
                                                  stack));
      embedder->CompositeEmbeddedView(0)->DrawRect(
          DlRect::MakeXYWH(10, 10, 20, 20), DlPaint());
      embedder->SubmitFlutterView(
          kImplicitViewId, nullptr, nullptr,
          std::make_unique<SurfaceFrame>(
              SkSurfaces::Null(frame_size.width, frame_size.height),
              framebuffer_info,
              [](const SurfaceFrame&, DlCanvas*) { return true; },
              [](const SurfaceFrame&) { return true; }, frame_size));
      embedder->EndFrame();
    });
    PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
    PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});
  };

  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(_, _))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(*jni_mock, FlutterViewBeginFrame()).Times(1);
  EXPECT_CALL(*jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, FlutterViewEndFrame()).Times(1);
  draw_frame();
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // Frame 1: overlay creation returns nullptr (e.g. detached controller).
  EXPECT_CALL(*jni_mock, FlutterViewCreateOverlaySurface(100, 100))
      .WillOnce(Return(ByMove(nullptr)));
  EXPECT_CALL(*jni_mock, FlutterViewDrainAbortedFrame(std::vector<int32_t>{}))
      .Times(1);
  draw_frame();
  ::testing::Mock::VerifyAndClearExpectations(jni_mock.get());

  // Since no Java overlay was ever created, Teardown() must not call
  // FlutterViewDestroyOverlaySurfaces().
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { embedder->Teardown(); });
  embedder.reset();
}

TEST(AndroidExternalViewEmbedderWrapper,
     TeardownBeforeInitIsNoOpAndConcurrentReadyForNextFrameIsSafe) {
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

  auto wrapper = std::make_unique<AndroidExternalViewEmbedderWrapper>(
      /*meets_hcpp_criteria=*/false, *android_context, jni_mock, nullptr,
      task_runners);

  // Teardown before any frame must not lazily allocate an embedder or call JNI.
  EXPECT_CALL(*jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { wrapper->Teardown(); });

  // Concurrent ReadyForNextFrame (raster) vs Teardown (platform) must not race.
  fml::AutoResetWaitableEvent raster_done;
  task_runners.GetRasterTaskRunner()->PostTask([&]() {
    EXPECT_TRUE(wrapper->ReadyForNextFrame([]() {}));
    raster_done.Signal();
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(),
               [&]() { wrapper->Teardown(); });
  raster_done.Wait();
  wrapper.reset();
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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
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
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr,
                                               /*is_fake_window=*/true);
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
