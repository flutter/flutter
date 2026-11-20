// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"

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
#include "flutter/shell/platform/android/surface/deferred_root_surface.h"
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
using ::testing::NiceMock;
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
  SurfaceMock() {
    ON_CALL(*this, IsValid()).WillByDefault(Return(true));
    ON_CALL(*this, MakeRenderContextCurrent()).WillByDefault([] {
      return std::make_unique<GLContextDefaultResult>(true);
    });
  }

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

namespace {

constexpr intptr_t kTestReaderTokenStart = 0x10000;
constexpr intptr_t kTestImageTokenStart = 0x20000;
constexpr int kDefaultFrameExtentPx = 1000;
constexpr double kDefaultDevicePixelRatio = 1.5;
constexpr double kUnitDevicePixelRatio = 1.0;
constexpr int64_t kDeadlockTimeoutSeconds = 5;
constexpr int64_t kPrimaryViewId = 0;
constexpr int64_t kSecondaryViewId = 1;
// Overlay and platform-view bounds used across the Frame-Packet state-table and
// z-order unit tests (in logical/physical pixel coordinates).
constexpr DlScalar kSmallViewExtentLogical = 50.0f;
constexpr DlScalar kMediumViewExtentLogical = 100.0f;
constexpr DlScalar kSecondaryViewOriginLogical = 300.0f;
constexpr DlScalar kOverlayInsetLogical = 20.0f;
constexpr DlScalar kOverlayExtentLogical = 60.0f;
constexpr DlScalar kSecondaryOverlayOriginLogical = 320.0f;
constexpr DlScalar kRootPaintExtentLogical = 10.0f;
constexpr int kSmallDamageExtentPx = 50;
constexpr int kMediumOverlayExtentPx = 100;
constexpr int kOverlayInsetPx = 20;
constexpr int kOverlayExtentPx = 60;
constexpr int kScaledMediumExtentPx = 150;
constexpr int kSecondaryViewOriginPx = 300;
constexpr int kSecondaryOverlayOriginPx = 320;
constexpr int kMidTestOverlayRectOffsetLogical = 10;
constexpr int kMidTestOverlayRectExtentLogical = 30;
constexpr int kCase3OverlayExtentLogical = 40;
constexpr int kCase5RootRectExtentLogical = 20;
constexpr int kCase7OverlayOffsetLogical = 5;
constexpr int kCase7OverlayExtentLogical = 25;
constexpr int kAbortSecondaryOriginLogical = 200;
constexpr int kAbortSecondaryOverlayOriginLogical = 210;
constexpr int kResizedViewportWidthPx = 800;
constexpr int kResizedViewportHeightPx = 600;
constexpr int kTinyViewportWidthPx = 100;
constexpr int kTinyViewportHeightPx = 100;
constexpr DlScalar kTinyRectExtentLogical = 10.0f;
constexpr DlScalar kChangedRectOriginXLogical = 10.0f;
constexpr DlScalar kChangedRectOriginYLogical = 20.0f;
constexpr DlScalar kChangedRectWidthLogical = 30.0f;
constexpr DlScalar kChangedRectHeightLogical = 40.0f;
constexpr DlScalar kAltRectOriginXLogical = 50.0f;
constexpr DlScalar kAltRectOriginYLogical = 60.0f;
constexpr DlScalar kAltRectWidthLogical = 70.0f;
constexpr DlScalar kAltRectHeightLogical = 80.0f;
constexpr DlScalar kExpectedScaledX1 = 15.0f;
constexpr DlScalar kExpectedScaledY1 = 30.0f;
constexpr DlScalar kExpectedScaledW1 = 45.0f;
constexpr DlScalar kExpectedScaledH1 = 60.0f;
constexpr DlScalar kExpectedScaledX2 = 75.0f;
constexpr DlScalar kExpectedScaledY2 = 90.0f;
constexpr DlScalar kExpectedScaledW2 = 105.0f;
constexpr DlScalar kExpectedScaledH2 = 120.0f;
// Origin coordinate when a test view or overlay starts at (0, 0).
constexpr int kOriginPx = 0;
// Logical origin coordinate when a test view or drawing starts at (0, 0).
constexpr DlScalar kOriginLogical = 0.0f;
// Ordinal (1-based) of the AcquireLatestHybridImage call forced to fail in
// cold-start failure tests (1 = background succeeds, 2 = overlay 0 returns
// null).
constexpr int kFailedOverlayAcquireOrdinal = 2;
// Total AcquireLatestHybridImage calls made across 1 background layer and 2
// overlays when overlay 0 fails on call 2 and overlay 1 is drained on call 3.
constexpr int kExpectedAcquireCallsAfterOverlay0Failure = 3;
// Non-null acquired images released after overlay 0 returns null (the
// background image plus the drained overlay 1 image).
constexpr int kExpectedReleasedImagesAfterOverlay0Failure = 2;
// Layer and image count for an HC frame containing a background layer and one
// overlay slice.
constexpr int kSingleOverlayFrameLayerCount = 2;
// Image count for a background-only HC frame with zero overlay slices.
constexpr int kBackgroundOnlyPacketImageCount = 1;
// Expected FlutterViewBeginHybridFrame calls during teardown entry+exit reuse.
constexpr int kTeardownReuseFrameCount = 2;

std::unique_ptr<SurfaceFrame> MakeRecordingSurfaceFrame(
    const DlISize& size,
    std::function<bool()> on_submit = {}) {
  SurfaceFrame::FramebufferInfo info;
  info.supports_readback = true;
  return std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, info,
      /*encode_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*submit_callback=*/
      [on_submit = std::move(on_submit)](const SurfaceFrame&) {
        return on_submit ? on_submit() : true;
      },
      size, /*context_result=*/nullptr, /*display_list_fallback=*/true);
}

// Multi-thread harness with separate Platform (`main`) and Raster (`1.raster`)
// threads, wired `HybridCompositionState`, and `DeferredRootSurfaceSlot`.
struct FramePacketTestHarness {
  std::shared_ptr<JNIMock> jni_mock = std::make_shared<JNIMock>();
  std::shared_ptr<AndroidContext> android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  ThreadHost thread_host{"io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform |
                             ThreadHost::Type::kRaster | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi};
  TaskRunners task_runners{"test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner()};
  std::shared_ptr<HybridCompositionState> hc_state =
      std::make_shared<HybridCompositionState>();
  std::shared_ptr<DeferredRootSurfaceSlot> deferred_slot =
      std::make_shared<DeferredRootSurfaceSlot>();
  fml::RefPtr<AndroidNativeWindow> window =
      fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  std::atomic<intptr_t> next_reader_token{kTestReaderTokenStart};
  std::atomic<intptr_t> next_image_token{kTestImageTokenStart};
  std::atomic<int> created_readers{0};
  std::atomic<int> retired_readers{0};
  std::atomic<int> acquired_images{0};
  std::atomic<int> released_images{0};
  std::atomic<int> root_inner_submits{0};
  std::atomic<int> root_make_current_calls{0};
  std::atomic<int> schedule_frame_calls_on_platform{0};

  std::shared_ptr<TestAndroidSurfaceFactory> surface_factory;
  std::unique_ptr<DeferredRootSurface> deferred_root;
  std::unique_ptr<AndroidExternalViewEmbedder> embedder;

  FramePacketTestHarness() {
    hc_state->hc_views_alive.store(true, std::memory_order_release);

    ON_CALL(*jni_mock, CreateHybridImageReader(_, _))
        .WillByDefault([this](int32_t width, int32_t height) {
          EXPECT_TRUE(
              task_runners.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
          EXPECT_GT(width, 0);
          EXPECT_GT(height, 0);
          created_readers.fetch_add(1);
          return std::make_unique<
              PlatformViewAndroidJNI::HybridImageReaderMetadata>(
              HybridJavaGlobalRef::ForTest(next_reader_token.fetch_add(1)),
              window);
        });

    ON_CALL(*jni_mock, AcquireLatestHybridImage(_))
        .WillByDefault([this](const HybridJavaGlobalRef& reader) {
          EXPECT_TRUE(
              task_runners.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
          EXPECT_FALSE(reader.is_null());
          acquired_images.fetch_add(1);
          return HybridJavaGlobalRef::ForTest(next_image_token.fetch_add(1));
        });

    ON_CALL(*jni_mock, ReleaseHybridImage(_, _))
        .WillByDefault(
            [this](const HybridJavaGlobalRef&, HybridJavaGlobalRef image) {
              if (image) {
                released_images.fetch_add(1);
              }
            });

    ON_CALL(*jni_mock, RetireHybridImageReader(_))
        .WillByDefault([this](HybridJavaGlobalRef reader) {
          if (reader) {
            retired_readers.fetch_add(1);
          }
        });

    surface_factory = std::make_shared<TestAndroidSurfaceFactory>([this]() {
      EXPECT_TRUE(
          task_runners.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
      auto gpu_surface = std::make_unique<NiceMock<SurfaceMock>>();
      ON_CALL(*gpu_surface, AcquireFrame(_))
          .WillByDefault([](const DlISize& size) {
            return MakeRecordingSurfaceFrame(size);
          });
      auto android_surface = std::make_unique<AndroidSurfaceMock>();
      ON_CALL(*android_surface, IsValid()).WillByDefault(Return(true));
      ON_CALL(*android_surface, SetNativeWindow(_, _))
          .WillByDefault(Return(true));
      EXPECT_CALL(*android_surface, CreateGPUSurface(_))
          .WillRepeatedly([gpu = gpu_surface.release()]() mutable {
            if (gpu != nullptr) {
              auto owned = std::unique_ptr<Surface>(gpu);
              gpu = nullptr;
              return owned;
            }
            auto replacement = std::make_unique<NiceMock<SurfaceMock>>();
            ON_CALL(*replacement, AcquireFrame(_))
                .WillByDefault([](const DlISize& s) {
                  return MakeRecordingSurfaceFrame(s);
                });
            return std::unique_ptr<Surface>(std::move(replacement));
          });
      return android_surface;
    });

    PostTaskSync(task_runners.GetRasterTaskRunner(), [this]() {
      InstallNewDeferredRootSurface();
      embedder = std::make_unique<AndroidExternalViewEmbedder>(
          *android_context, jni_mock, surface_factory, task_runners, hc_state,
          deferred_slot, [this]() {
            EXPECT_TRUE(task_runners.GetPlatformTaskRunner()
                            ->RunsTasksOnCurrentThread());
            schedule_frame_calls_on_platform.fetch_add(1);
          });
    });
  }

  ~FramePacketTestHarness() {
    FlushPlatform();
    PostTaskSync(task_runners.GetRasterTaskRunner(), [this]() {
      embedder.reset();
      deferred_root.reset();
      deferred_slot->reset();
    });
    FlushPlatform();
  }

  void InstallNewDeferredRootSurface() {
    auto inner = std::make_unique<NiceMock<SurfaceMock>>();
    ON_CALL(*inner, MakeRenderContextCurrent()).WillByDefault([this]() {
      root_make_current_calls.fetch_add(1);
      return std::make_unique<GLContextDefaultResult>(true);
    });
    ON_CALL(*inner, AcquireFrame(_)).WillByDefault([this](const DlISize& size) {
      return MakeRecordingSurfaceFrame(size, [this]() {
        root_inner_submits.fetch_add(1);
        return true;
      });
    });
    deferred_root = std::make_unique<DeferredRootSurface>(
        std::move(inner),
        [state = hc_state]() { return state->ShouldDeferRootSurface(); });
    *deferred_slot = deferred_root->GetWeakPtr();
  }

  void FlushRaster() {
    PostTaskSync(task_runners.GetRasterTaskRunner(), []() {});
  }

  void FlushPlatform() {
    PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  }
};

}  // namespace

TEST(AndroidExternalViewEmbedder, CompositeEmbeddedViewAndCancelFrame) {
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, nullptr, nullptr, GetTaskRunnersForFixture());

  ASSERT_EQ(nullptr, embedder->CompositeEmbeddedView(0));
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  ASSERT_NE(nullptr, embedder->CompositeEmbeddedView(0));

  embedder->CancelFrame();
  ASSERT_EQ(nullptr, embedder->CompositeEmbeddedView(0));
}

TEST(AndroidExternalViewEmbedder,
     SupportsDynamicThreadMergingIsFalseAndPostPrerollAlwaysSucceeds) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  EXPECT_FALSE(embedder->SupportsDynamicThreadMerging());
  embedder->PrepareFlutterView(
      DlISize(kDefaultFrameExtentPx, kDefaultFrameExtentPx),
      kDefaultDevicePixelRatio);
  embedder->PrerollCompositeEmbeddedView(
      0, std::make_unique<EmbeddedViewParams>());
  EXPECT_EQ(embedder->PostPrerollAction(nullptr), PostPrerollResult::kSuccess);
}

TEST(AndroidExternalViewEmbedder, PlatformViewRectAndChangedParams) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context = AndroidContext(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder>(
      android_context, jni_mock, nullptr, GetTaskRunnersForFixture());

  embedder->BeginFrame(nullptr, nullptr);
  embedder->PrepareFlutterView(
      DlISize(kTinyViewportWidthPx, kTinyViewportHeightPx),
      kDefaultDevicePixelRatio);

  MutatorsStack stack1;
  DlMatrix matrix1 = DlMatrix::MakeScale({kDefaultDevicePixelRatio,
                                          kDefaultDevicePixelRatio, 1}) *
                     DlMatrix::MakeTranslation({kChangedRectOriginXLogical,
                                                kChangedRectOriginYLogical});
  embedder->PrerollCompositeEmbeddedView(
      kPrimaryViewId,
      std::make_unique<EmbeddedViewParams>(
          matrix1, DlSize(kChangedRectWidthLogical, kChangedRectHeightLogical),
          stack1));
  EXPECT_EQ(DlRect::MakeXYWH(kExpectedScaledX1, kExpectedScaledY1,
                             kExpectedScaledW1, kExpectedScaledH1),
            embedder->GetViewRect(kPrimaryViewId));

  MutatorsStack stack2;
  DlMatrix matrix2 = DlMatrix::MakeScale({kDefaultDevicePixelRatio,
                                          kDefaultDevicePixelRatio, 1}) *
                     DlMatrix::MakeTranslation(
                         {kAltRectOriginXLogical, kAltRectOriginYLogical});
  embedder->PrerollCompositeEmbeddedView(
      kPrimaryViewId,
      std::make_unique<EmbeddedViewParams>(
          matrix2, DlSize(kAltRectWidthLogical, kAltRectHeightLogical),
          stack2));
  EXPECT_EQ(DlRect::MakeXYWH(kExpectedScaledX2, kExpectedScaledY2,
                             kExpectedScaledW2, kExpectedScaledH2),
            embedder->GetViewRect(kPrimaryViewId));
}

// Regression test for https://github.com/flutter/flutter/issues/189834.
TEST(AndroidExternalViewEmbedder, PlatformViewSizeIsRoundedNotTruncated) {
  FramePacketTestHarness h;

  constexpr double kPixel6Dpr = 2.625;
  constexpr int kScreenWidthPx = 1080;
  constexpr int kScreenHeightPx = 2400;
  const DlISize frame_size(kScreenWidthPx, kScreenHeightPx);
  const DlSize size_points(
      static_cast<DlScalar>(frame_size.width / kPixel6Dpr),
      static_cast<DlScalar>(frame_size.height / kPixel6Dpr));
  MutatorsStack stack;
  const DlMatrix scale = DlMatrix::MakeScale({kPixel6Dpr, kPixel6Dpr, 1});
  stack.PushTransform(scale);

  EXPECT_CALL(*h.jni_mock, FlutterViewOnDisplayHybridPlatformView(
                               0, 0, 0, kScreenWidthPx, kScreenHeightPx,
                               kScreenWidthPx, kScreenHeightPx, stack))
      .Times(1);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kPixel6Dpr);
    std::unique_ptr<SurfaceFrame> root_frame =
        h.deferred_root->AcquireFrame(frame_size);
    h.embedder->PrerollCompositeEmbeddedView(
        0, std::make_unique<EmbeddedViewParams>(scale, size_points, stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
}

TEST(AndroidExternalViewEmbedder,
     StrictThreadSeparationSequentialSubmitsAndInterleavedZOrder) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);

  // Never invoke legacy merged-HC JNI methods.
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginFrame()).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndFrame()).Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewCreateOverlaySurface()).Times(0);
  EXPECT_CALL(*h.jni_mock,
              FlutterViewOnDisplayPlatformView(_, _, _, _, _, _, _, _))
      .Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayOverlaySurface(_, _, _, _, _))
      .Times(0);
  EXPECT_CALL(*h.jni_mock, FlutterViewDestroyOverlaySurfaces()).Times(0);

  std::vector<std::string> raster_order;
  int layer_index = 0;
  h.surface_factory = std::make_shared<TestAndroidSurfaceFactory>([&]() {
    const int idx = layer_index++;
    auto gpu_surface = std::make_unique<NiceMock<SurfaceMock>>();
    EXPECT_CALL(*gpu_surface, AcquireFrame(frame_size))
        .WillOnce([&, idx](const DlISize& size) {
          EXPECT_TRUE(
              h.task_runners.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
          raster_order.push_back("acquire_" + std::to_string(idx));
          return MakeRecordingSurfaceFrame(size, [&, idx]() {
            EXPECT_TRUE(h.task_runners.GetRasterTaskRunner()
                            ->RunsTasksOnCurrentThread());
            raster_order.push_back("submit_" + std::to_string(idx));
            return true;
          });
        });
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    ON_CALL(*android_surface, IsValid()).WillByDefault(Return(true));
    ON_CALL(*android_surface, SetNativeWindow(_, _))
        .WillByDefault(Return(true));
    EXPECT_CALL(*android_surface, CreateGPUSurface(_))
        .WillOnce(Return(ByMove(std::move(gpu_surface))));
    return android_surface;
  });

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder = std::make_unique<AndroidExternalViewEmbedder>(
        *h.android_context, h.jni_mock, h.surface_factory, h.task_runners,
        h.hc_state, h.deferred_slot);
  });

  ON_CALL(*h.jni_mock, AcquireLatestHybridImage(_))
      .WillByDefault([&](const HybridJavaGlobalRef& reader) {
        EXPECT_TRUE(
            h.task_runners.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
        raster_order.push_back("acquire_image");
        return HybridJavaGlobalRef::ForTest(h.next_image_token.fetch_add(1));
      });

  std::vector<std::string> ui_order;
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _))
      .WillOnce([&](HybridJavaGlobalRef bg_img,
                    const HybridJavaGlobalRef& bg_reader) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        EXPECT_FALSE(bg_img.is_null());
        EXPECT_FALSE(bg_reader.is_null());
        ui_order.push_back("begin_bg");
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewOnDisplayHybridPlatformView(
                               kPrimaryViewId, kOriginPx, kOriginPx,
                               kMediumOverlayExtentPx, kMediumOverlayExtentPx,
                               kScaledMediumExtentPx, kScaledMediumExtentPx, _))
      .WillOnce([&](int, int, int, int, int, int, int, const MutatorsStack&) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        ui_order.push_back("pv_0");
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayHybridOverlaySurface(
                               kPrimaryViewId, kOverlayInsetPx, kOverlayInsetPx,
                               kOverlayExtentPx, kOverlayExtentPx, _, _))
      .WillOnce([&](int, int, int, int, int, HybridJavaGlobalRef img,
                    const HybridJavaGlobalRef& reader) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        EXPECT_FALSE(img.is_null());
        EXPECT_FALSE(reader.is_null());
        ui_order.push_back("ov_0");
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewOnDisplayHybridPlatformView(
                               kSecondaryViewId, kSecondaryViewOriginPx,
                               kSecondaryViewOriginPx, kMediumOverlayExtentPx,
                               kMediumOverlayExtentPx, kScaledMediumExtentPx,
                               kScaledMediumExtentPx, _))
      .WillOnce([&](int, int, int, int, int, int, int, const MutatorsStack&) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        ui_order.push_back("pv_1");
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewDisplayHybridOverlaySurface(
                               kSecondaryViewId, kSecondaryOverlayOriginPx,
                               kSecondaryOverlayOriginPx, kOverlayExtentPx,
                               kOverlayExtentPx, _, _))
      .WillOnce([&](int, int, int, int, int, HybridJavaGlobalRef img,
                    const HybridJavaGlobalRef& reader) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        EXPECT_FALSE(img.is_null());
        EXPECT_FALSE(reader.is_null());
        ui_order.push_back("ov_1");
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false))
      .WillOnce([&](bool, bool) {
        EXPECT_TRUE(
            h.task_runners.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
        ui_order.push_back("end");
      });

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kDefaultDevicePixelRatio);
    std::unique_ptr<SurfaceFrame> root_frame =
        h.deferred_root->AcquireFrame(frame_size);
    root_frame->Canvas()->DrawRect(
        DlRect::MakeXYWH(kOriginLogical, kOriginLogical,
                         kRootPaintExtentLogical, kRootPaintExtentLogical),
        DlPaint());

    MutatorsStack s0;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), s0));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(
            DlRect::MakeXYWH(kOverlayInsetLogical, kOverlayInsetLogical,
                             kOverlayExtentLogical, kOverlayExtentLogical),
            DlPaint());

    MutatorsStack s1;
    DlMatrix m1 = DlMatrix::MakeTranslation(
        {kSecondaryViewOriginLogical, kSecondaryViewOriginLogical});
    h.embedder->PrerollCompositeEmbeddedView(
        kSecondaryViewId,
        std::make_unique<EmbeddedViewParams>(
            m1, DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical),
            s1));
    h.embedder->CompositeEmbeddedView(kSecondaryViewId)
        ->DrawRect(
            DlRect::MakeXYWH(kSecondaryOverlayOriginLogical,
                             kSecondaryOverlayOriginLogical,
                             kOverlayExtentLogical, kOverlayExtentLogical),
            DlPaint());

    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();

  // Sequential AcquireFrame -> Submit per layer (preserving GL FBO 0), followed
  // by batched AcquireLatestHybridImage across all submitted layers.
  EXPECT_EQ(raster_order, (std::vector<std::string>{
                              "acquire_0", "submit_0", "acquire_1", "submit_1",
                              "acquire_2", "submit_2", "acquire_image",
                              "acquire_image", "acquire_image"}));
  // Interleaved Z-order on main: bg -> PV_0 -> Ov_0 -> PV_1 -> Ov_1 -> end.
  EXPECT_EQ(ui_order, (std::vector<std::string>{"begin_bg", "pv_0", "ov_0",
                                                "pv_1", "ov_1", "end"}));
  EXPECT_EQ(h.root_inner_submits.load(), 0);
}

TEST(AndroidExternalViewEmbedder,
     AllEightStateTableTransitionsTransparentEntryAndOverlayTrimming) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false))
      .Times(::testing::AnyNumber());
  int expected_root_submits = 0;

  // Case 1: (alive=0, active=0, has_pv=0) -> direct inner submit, partial
  // repaint enabled, zero readers created.
  h.hc_state->hc_views_alive.store(false, std::memory_order_release);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    EXPECT_TRUE(h.embedder->SupportsPartialRepaint());
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  EXPECT_EQ(h.root_inner_submits.load(), ++expected_root_submits);
  EXPECT_EQ(h.created_readers.load(), 0);

  // Case 8: (alive=0, active=0, has_pv=1) -> PV created & disposed before first
  // HC frame; slices flattened onto root canvas, submitted directly to inner_.
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    SurfaceFrame::SubmitInfo info;
    info.buffer_damage = DlIRect::MakeXYWH(
        kOriginPx, kOriginPx, kSmallDamageExtentPx, kSmallDamageExtentPx);
    root_frame->set_submit_info(info);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kSmallViewExtentLogical, kSmallViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(DlRect::MakeXYWH(
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kCase5RootRectExtentLogical),
                       static_cast<DlScalar>(kCase5RootRectExtentLogical)),
                   DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  EXPECT_EQ(h.root_inner_submits.load(), ++expected_root_submits);
  EXPECT_EQ(h.created_readers.load(), 0);

  // Case 2: (alive=1, active=0, has_pv=0) -> deferred DisplayList replayed onto
  // inner_ inside frame->Submit(); SupportsPartialRepaint() == false.
  h.hc_state->hc_views_alive.store(true, std::memory_order_release);
  h.hc_state->root_surface_transparent.store(true, std::memory_order_release);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    EXPECT_FALSE(h.embedder->SupportsPartialRepaint());
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    root_frame->Canvas()->DrawRect(
        DlRect::MakeXYWH(kOriginLogical, kOriginLogical,
                         kRootPaintExtentLogical, kRootPaintExtentLogical),
        DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  EXPECT_EQ(h.root_inner_submits.load(), ++expected_root_submits);
  EXPECT_FALSE(h.hc_state->hc_session_active.load());

  // Case 3: (alive=1, active=0, has_pv=1) with root_surface_transparent=true ->
  // clears inner_ once via AcquireInnerFrame, allocates bg + 1 overlay reader,
  // sets hc_session_active = true.
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(DlRect::MakeXYWH(
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kCase3OverlayExtentLogical),
                       static_cast<DlScalar>(kCase3OverlayExtentLogical)),
                   DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.root_inner_submits.load(), ++expected_root_submits);
  EXPECT_EQ(h.created_readers.load(), kSingleOverlayFrameLayerCount);
  EXPECT_TRUE(h.hc_state->hc_session_active.load());

  // Case 4: (alive=1, active=1, has_pv=1) with 0 overlays -> reuses bg_layer,
  // trims unused overlay_0 immediately, does NOT touch inner_ again.
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.root_inner_submits.load(), expected_root_submits);
  EXPECT_EQ(h.retired_readers.load(), kBackgroundOnlyPacketImageCount);

  // Case 5: (alive=1, active=1, has_pv=0) -> dual-renders cached DisplayList to
  // bg_layer and inner_, publishes exit frame, retires bg_layer once drained,
  // sets active=false.
  bool saw_exit_frame = false;
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(true, false))
      .WillOnce([&](bool, bool) { saw_exit_frame = true; });
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    root_frame->Canvas()->DrawRect(
        DlRect::MakeXYWH(kOriginLogical, kOriginLogical,
                         static_cast<DlScalar>(kCase5RootRectExtentLogical),
                         static_cast<DlScalar>(kCase5RootRectExtentLogical)),
        DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_TRUE(saw_exit_frame);
  EXPECT_EQ(h.root_inner_submits.load(), ++expected_root_submits);
  EXPECT_EQ(h.retired_readers.load(), kSingleOverlayFrameLayerCount);
  EXPECT_FALSE(h.hc_state->hc_session_active.load());

  // Re-enter HC and test Case 7: (alive=0, active=1, has_pv=1) -> frame built
  // before dispose(), rasterized after dispose().
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  ASSERT_TRUE(h.hc_state->hc_session_active.load());

  // Simulate Java dispose() setting hc_views_alive = false while a frame with
  // PlatformViewLayer is rasterizing on 1.raster (Case 7).
  h.hc_state->hc_views_alive.store(false, std::memory_order_release);
  bool saw_case7_exit = false;
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(true, false))
      .WillOnce([&](bool, bool) { saw_case7_exit = true; });
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(
            DlRect::MakeXYWH(static_cast<DlScalar>(kCase7OverlayOffsetLogical),
                             static_cast<DlScalar>(kCase7OverlayOffsetLogical),
                             static_cast<DlScalar>(kCase7OverlayExtentLogical),
                             static_cast<DlScalar>(kCase7OverlayExtentLogical)),
            DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_TRUE(saw_case7_exit);
  EXPECT_FALSE(h.hc_state->hc_session_active.load());

  // Re-enter with synchronize_to_native_view_hierarchy = false and test Case 6:
  // (alive=0, active=1, has_pv=0) when bg_synced == false -> submits to inner_
  // without allocating a background HybridImageReader.
  const int readers_before_unsynced = h.created_readers.load();
  h.hc_state->hc_views_alive.store(true, std::memory_order_release);
  h.hc_state->synchronize_to_native_view_hierarchy.store(
      false, std::memory_order_release);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.created_readers.load(), readers_before_unsynced);
  ASSERT_TRUE(h.hc_state->hc_session_active.load());

  h.hc_state->hc_views_alive.store(false, std::memory_order_release);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(true, false)).Times(1);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.created_readers.load(), readers_before_unsynced);
  EXPECT_FALSE(h.hc_state->hc_session_active.load());
}

TEST(AndroidExternalViewEmbedder,
     MidSessionSynchronizeToggleRemovesBackgroundAfterTraversal) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false)).Times(1);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  ASSERT_EQ(h.retired_readers.load(), 0);

  // Toggle synchronize_to_native_view_hierarchy -> false mid-session.
  h.hc_state->synchronize_to_native_view_hierarchy.store(
      false, std::memory_order_release);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, true)).Times(1);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.retired_readers.load(), kBackgroundOnlyPacketImageCount);
  EXPECT_EQ(h.root_inner_submits.load(), 1);
}

TEST(AndroidExternalViewEmbedder,
     MidSessionSynchronizeTrueClearsTransparentRootSurface) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);
  h.hc_state->root_surface_transparent.store(true, std::memory_order_release);
  h.hc_state->synchronize_to_native_view_hierarchy.store(
      false, std::memory_order_release);

  // Enter HC with background synchronization disabled: hc_session_active
  // becomes true, hc_background_synchronized_ stays false, and inner_ receives
  // the root frame directly without allocating a background HybridImageReader.
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  ASSERT_TRUE(h.hc_state->hc_session_active.load());
  ASSERT_EQ(h.created_readers.load(), 0);
  ASSERT_EQ(h.root_inner_submits.load(), 1);

  // Enable synchronize_to_native_view_hierarchy mid-session while
  // root_surface_transparent is true: the transition
  // (!hc_background_synchronized_
  // && root_transparent) must clear inner_ once (root_inner_submits: 1 -> 2),
  // allocate bg_layer, and present a non-null background image.
  h.hc_state->synchronize_to_native_view_hierarchy.store(
      true, std::memory_order_release);
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _))
      .WillOnce([](HybridJavaGlobalRef bg_img, const HybridJavaGlobalRef&) {
        EXPECT_FALSE(bg_img.is_null());
      })
      .WillOnce([](HybridJavaGlobalRef bg_img, const HybridJavaGlobalRef&) {
        EXPECT_FALSE(bg_img.is_null());
      });
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false)).Times(2);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.created_readers.load(), kBackgroundOnlyPacketImageCount);
  EXPECT_EQ(h.root_inner_submits.load(), 2);

  // Subsequent frame with background already synchronized must NOT touch
  // inner_.
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_EQ(h.root_inner_submits.load(), 2);
}

TEST(
    AndroidExternalViewEmbedder,
    ColdStartAcquireFailureReleasesPartialImagesDrainsLayersAndSchedulesRetry) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);

  // Background image succeeds, overlay 0 image returns null, overlay 1 was
  // already submitted and must be drained and released.
  int acquire_call = 0;
  ON_CALL(*h.jni_mock, AcquireLatestHybridImage(_))
      .WillByDefault([&](const HybridJavaGlobalRef&) {
        ++acquire_call;
        if (acquire_call == kFailedOverlayAcquireOrdinal) {
          return HybridJavaGlobalRef();
        }
        return HybridJavaGlobalRef::ForTest(h.next_image_token.fetch_add(1));
      });

  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _)).Times(0);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);

    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(DlRect::MakeXYWH(
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical)),
                   DlPaint());
    h.embedder->PrerollCompositeEmbeddedView(
        kSecondaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix::MakeTranslation(
                {static_cast<DlScalar>(kAbortSecondaryOriginLogical),
                 static_cast<DlScalar>(kAbortSecondaryOriginLogical)}),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kSecondaryViewId)
        ->DrawRect(
            DlRect::MakeXYWH(
                static_cast<DlScalar>(kAbortSecondaryOverlayOriginLogical),
                static_cast<DlScalar>(kAbortSecondaryOverlayOriginLogical),
                static_cast<DlScalar>(kMidTestOverlayRectExtentLogical),
                static_cast<DlScalar>(kMidTestOverlayRectExtentLogical)),
            DlPaint());

    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    EXPECT_FALSE(h.embedder->DidLastSubmitSucceed());
    EXPECT_FALSE(h.hc_state->hc_session_active.load());
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();

  // Both bg image (call 1) and drained overlay 1 image (call 3) were released;
  // retry ScheduleFrame ran on main.
  EXPECT_EQ(acquire_call, kExpectedAcquireCallsAfterOverlay0Failure);
  EXPECT_EQ(h.released_images.load(),
            kExpectedReleasedImagesAfterOverlay0Failure);
  EXPECT_EQ(h.schedule_frame_calls_on_platform.load(), 1);
}

TEST(AndroidExternalViewEmbedder,
     ResizeAndSupersedeDoNotBlockRasterWhenPlatformThreadIsOccupied) {
  FramePacketTestHarness h;
  const DlISize size1(kDefaultFrameExtentPx, kDefaultFrameExtentPx);
  const DlISize size2(kResizedViewportWidthPx, kResizedViewportHeightPx);

  // Occupy platform thread while 1.raster renders at size1, resizes to size2,
  // and renders at size2 (superseding packet 1 in the mailbox).
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  fml::AutoResetWaitableEvent raster_done;
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    for (const DlISize& s : {size1, size2}) {
      h.embedder->BeginFrame(nullptr, nullptr);
      h.embedder->PrepareFlutterView(s, kUnitDevicePixelRatio);
      auto root_frame = h.deferred_root->AcquireFrame(s);
      MutatorsStack stack;
      h.embedder->PrerollCompositeEmbeddedView(
          kPrimaryViewId,
          std::make_unique<EmbeddedViewParams>(
              DlMatrix(),
              DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical),
              stack));
      h.embedder->CompositeEmbeddedView(kPrimaryViewId)
          ->DrawRect(
              DlRect::MakeXYWH(
                  static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                  static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                  static_cast<DlScalar>(kMidTestOverlayRectExtentLogical),
                  static_cast<DlScalar>(kMidTestOverlayRectExtentLogical)),
              DlPaint());
      h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                    std::move(root_frame));
      h.embedder->EndFrame(false, nullptr);
    }
    raster_done.Signal();
  });

  const bool timed_out = raster_done.WaitWithTimeout(
      fml::TimeDelta::FromSeconds(kDeadlockTimeoutSeconds));
  release_platform.Signal();
  if (timed_out) {
    raster_done.Wait();
  }
  EXPECT_FALSE(timed_out);

  // Packet 1's images were superseded and released; only Packet 2 drains on
  // main.
  int drained_frames = 0;
  ON_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _))
      .WillByDefault([&](HybridJavaGlobalRef, const HybridJavaGlobalRef&) {
        ++drained_frames;
      });
  h.FlushPlatform();
  EXPECT_EQ(drained_frames, 1);
  EXPECT_EQ(h.released_images.load(), kSingleOverlayFrameLayerCount);
  EXPECT_EQ(h.retired_readers.load(), kSingleOverlayFrameLayerCount);
}

TEST(
    AndroidExternalViewEmbedder,
    EpochBumpDiscardsInFlightPacketAndTeardownAllowsReuseAcrossNewRootSurface) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);

  // Hold platform thread so packet stays queued in mailbox while hc_epoch
  // advances (simulating OnPreEngineRestart or NotifyDestroyed).
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });

  // Bump epoch before main drains -> packet must be discarded and its image
  // released without calling FlutterViewBeginHybridFrame.
  h.hc_state->hc_epoch.fetch_add(1, std::memory_order_acq_rel);
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _)).Times(0);
  release_platform.Signal();
  h.FlushPlatform();
  EXPECT_EQ(h.released_images.load(), kBackgroundOnlyPacketImageCount);

  // Run Teardown() on main, destroy DeferredRootSurface #1, install
  // DeferredRootSurface #2, and verify a fresh HC entry + exit session works.
  EXPECT_CALL(*h.jni_mock, FlutterViewTeardownHybridComposition()).Times(1);
  PostTaskSync(h.task_runners.GetPlatformTaskRunner(),
               [&]() { h.embedder->Teardown(); });
  EXPECT_FALSE(h.hc_state->hc_session_active.load());

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.deferred_root.reset();
    h.InstallNewDeferredRootSurface();
  });

  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _))
      .Times(kTeardownReuseFrameCount);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false)).Times(1);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(true, false)).Times(1);

  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    // Entry on DeferredRootSurface #2.
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto entry_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(entry_frame));
    h.embedder->EndFrame(false, nullptr);

    // Exit on DeferredRootSurface #2.
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto exit_frame = h.deferred_root->AcquireFrame(frame_size);
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(exit_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  EXPECT_FALSE(h.hc_state->hc_session_active.load());
}

TEST(
    AndroidExternalViewEmbedder,
    DestructorClosesMailboxAndRetiresLayersWithoutBlockingOnBlockedPlatformThread) {
  FramePacketTestHarness h;
  const DlISize frame_size(kDefaultFrameExtentPx, kDefaultFrameExtentPx);

  // Establish an active HC session with both bg_layer and one overlay layer.
  EXPECT_CALL(*h.jni_mock, FlutterViewBeginHybridFrame(_, _)).Times(1);
  EXPECT_CALL(*h.jni_mock, FlutterViewEndHybridFrame(false, false)).Times(1);
  PostTaskSync(h.task_runners.GetRasterTaskRunner(), [&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(DlRect::MakeXYWH(
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical)),
                   DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);
  });
  h.FlushPlatform();
  ASSERT_TRUE(h.hc_state->hc_session_active.load());
  ASSERT_EQ(h.created_readers.load(), kSingleOverlayFrameLayerCount);
  const int released_before_block = h.released_images.load();

  // Occupy PlatformTaskRunner while submitting a new packet and then destroying
  // the embedder on 1.raster.
  fml::AutoResetWaitableEvent platform_occupied;
  fml::AutoResetWaitableEvent release_platform;
  h.task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    platform_occupied.Signal();
    release_platform.Wait();
  });
  platform_occupied.Wait();

  fml::AutoResetWaitableEvent destroy_done;
  h.task_runners.GetRasterTaskRunner()->PostTask([&]() {
    h.embedder->BeginFrame(nullptr, nullptr);
    h.embedder->PrepareFlutterView(frame_size, kUnitDevicePixelRatio);
    auto root_frame = h.deferred_root->AcquireFrame(frame_size);
    MutatorsStack stack;
    h.embedder->PrerollCompositeEmbeddedView(
        kPrimaryViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(),
            DlSize(kMediumViewExtentLogical, kMediumViewExtentLogical), stack));
    h.embedder->CompositeEmbeddedView(kPrimaryViewId)
        ->DrawRect(DlRect::MakeXYWH(
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectOffsetLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical),
                       static_cast<DlScalar>(kMidTestOverlayRectExtentLogical)),
                   DlPaint());
    h.embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                  std::move(root_frame));
    h.embedder->EndFrame(false, nullptr);

    h.embedder.reset();
    destroy_done.Signal();
  });

  const bool timed_out = destroy_done.WaitWithTimeout(
      fml::TimeDelta::FromSeconds(kDeadlockTimeoutSeconds));
  if (!timed_out) {
    EXPECT_FALSE(h.hc_state->hc_session_active.load());
    EXPECT_EQ(h.released_images.load(),
              released_before_block + kSingleOverlayFrameLayerCount);
    EXPECT_EQ(h.retired_readers.load(), kSingleOverlayFrameLayerCount);
  }
  release_platform.Signal();
  if (timed_out) {
    destroy_done.Wait();
  }
  EXPECT_FALSE(timed_out);
  h.FlushPlatform();
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

TEST(AndroidExternalViewEmbedder2,
     SkipsOverlayFrameCleanlyWhenAcquireFrameReturnsNull) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::kPlatform |
                             ThreadHost::Type::kRaster | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kImpellerVulkan);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(nullptr);

  // Frame and platform view geometry in physical/logical pixels.
  constexpr int kFrameExtentPx = 100;
  constexpr DlScalar kViewExtentLogical = 50.0f;
  constexpr int64_t kTestViewId = 0;

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
    auto surface_mock = std::make_unique<SurfaceMock>();
    EXPECT_CALL(*surface_mock,
                AcquireFrame(DlISize(kFrameExtentPx, kFrameExtentPx)))
        .WillOnce(Return(ByMove(nullptr)));
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    EXPECT_CALL(*android_surface, IsValid()).WillOnce(Return(true));
    EXPECT_CALL(*android_surface, SetNativeWindow(_, _)).WillOnce(Return(true));
    EXPECT_CALL(*android_surface, CreateGPUSurface(_))
        .WillOnce(Return(ByMove(std::move(surface_mock))));
    return android_surface;
  });

  EXPECT_CALL(*jni_mock, createOverlaySurface2()).WillOnce([window]() {
    return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(0, window);
  });
  EXPECT_CALL(*jni_mock, MaybeResizeSurfaceView(kFrameExtentPx, kFrameExtentPx))
      .Times(1);
  EXPECT_CALL(*jni_mock, sealFrameTransactions()).Times(1);
  EXPECT_CALL(*jni_mock,
              onDisplayPlatformView2(kTestViewId, 0, 0, 50, 50, 50, 50, _))
      .Times(1);
  EXPECT_CALL(*jni_mock, showOverlaySurface2()).Times(0);
  EXPECT_CALL(*jni_mock, swapTransaction()).Times(1);
  EXPECT_CALL(*jni_mock, onEndFrame2()).Times(1);

  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      *android_context, jni_mock, surface_factory, task_runners);

  bool root_submitted = false;
  SurfaceFrame::FramebufferInfo framebuffer_info;
  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    embedder->PrepareFlutterView(DlISize(kFrameExtentPx, kFrameExtentPx), 1.0);
    MutatorsStack stack;
    embedder->PrerollCompositeEmbeddedView(
        kTestViewId,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(), DlSize(kViewExtentLogical, kViewExtentLogical), stack));
    embedder->CompositeEmbeddedView(kTestViewId)
        ->DrawRect(
            DlRect::MakeXYWH(0, 0, kViewExtentLogical, kViewExtentLogical),
            DlPaint());

    auto root_frame = std::make_unique<SurfaceFrame>(
        SkSurfaces::Null(kFrameExtentPx, kFrameExtentPx), framebuffer_info,
        [&](const SurfaceFrame&, DlCanvas*) {
          root_submitted = true;
          return true;
        },
        [](const SurfaceFrame&) { return true; },
        DlISize(kFrameExtentPx, kFrameExtentPx));
    embedder->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                                std::move(root_frame));
  });
  PostTaskSync(task_runners.GetPlatformTaskRunner(), []() {});
  EXPECT_TRUE(root_submitted);

  EXPECT_CALL(*jni_mock, destroyOverlaySurface2()).Times(1);
  embedder->Teardown();
}

TEST(AndroidExternalViewEmbedderWrapperTest,
     ForwardsPartialRepaintSubmitStatusAndUnlocksInitMutexAcrossTeardown) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::kPlatform |
                             ThreadHost::Type::kRaster | ThreadHost::Type::kIo |
                             ThreadHost::Type::kUi);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  auto jni_mock = std::make_shared<JNIMock>();
  auto android_context =
      std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
  auto hc_state = std::make_shared<HybridCompositionState>();
  auto deferred_slot = std::make_shared<DeferredRootSurfaceSlot>();

  auto surface_factory = std::make_shared<TestAndroidSurfaceFactory>([]() {
    auto android_surface = std::make_unique<AndroidSurfaceMock>();
    EXPECT_CALL(*android_surface, IsValid()).WillRepeatedly(Return(false));
    return android_surface;
  });

  auto wrapper = std::make_unique<AndroidExternalViewEmbedderWrapper>(
      /*meets_hcpp_criteria=*/false, *android_context, jni_mock,
      surface_factory, task_runners, hc_state, deferred_slot);

  // Uninitialized Teardown() and TeardownClassicHybridComposition() are no-ops
  // and SupportsPartialRepaint() reflects hc_state before initialization.
  EXPECT_CALL(*jni_mock, FlutterViewTeardownHybridComposition()).Times(0);
  wrapper->Teardown();
  wrapper->TeardownClassicHybridComposition();
  EXPECT_TRUE(wrapper->SupportsPartialRepaint());
  EXPECT_TRUE(wrapper->DidLastSubmitSucceed());

  hc_state->hc_views_alive.store(true, std::memory_order_release);
  EXPECT_FALSE(wrapper->SupportsPartialRepaint());

  // Initialize inner Classic HC embedder and trigger a failed HC layer submit.
  constexpr int kFrameExtentPx = 100;
  constexpr DlScalar kViewExtentLogical = 50.0f;
  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() {
    EXPECT_FALSE(wrapper->SupportsDynamicThreadMerging());
    wrapper->BeginFrame(nullptr, nullptr);
    wrapper->PrepareFlutterView(DlISize(kFrameExtentPx, kFrameExtentPx), 1.0);
    MutatorsStack stack;
    wrapper->PrerollCompositeEmbeddedView(
        0,
        std::make_unique<EmbeddedViewParams>(
            DlMatrix(), DlSize(kViewExtentLogical, kViewExtentLogical), stack));
    auto root_frame =
        MakeRecordingSurfaceFrame(DlISize(kFrameExtentPx, kFrameExtentPx));
    wrapper->SubmitFlutterView(kImplicitViewId, nullptr, nullptr,
                               std::move(root_frame));
    EXPECT_FALSE(wrapper->DidLastSubmitSucceed());
    wrapper->EndFrame(false, nullptr);
  });

  // Occupy RasterTaskRunner, start TeardownClassicHybridComposition() on
  // PlatformTaskRunner, and verify RasterTaskRunner can query
  // SupportsPartialRepaint() (which locks init_mutex_) without deadlocking.
  fml::AutoResetWaitableEvent raster_occupied;
  fml::AutoResetWaitableEvent check_init_mutex;
  fml::AutoResetWaitableEvent teardown_started;
  fml::AutoResetWaitableEvent teardown_done;
  bool queried_partial_repaint = true;

  EXPECT_CALL(*jni_mock, FlutterViewTeardownHybridComposition()).Times(1);

  task_runners.GetRasterTaskRunner()->PostTask([&]() {
    raster_occupied.Signal();
    check_init_mutex.Wait();
    queried_partial_repaint = wrapper->SupportsPartialRepaint();
  });
  raster_occupied.Wait();

  task_runners.GetPlatformTaskRunner()->PostTask([&]() {
    teardown_started.Signal();
    wrapper->TeardownClassicHybridComposition();
    teardown_done.Signal();
  });
  teardown_started.Wait();
  check_init_mutex.Signal();

  EXPECT_FALSE(teardown_done.WaitWithTimeout(
      fml::TimeDelta::FromSeconds(kDeadlockTimeoutSeconds)));
  EXPECT_FALSE(queried_partial_repaint);

  PostTaskSync(task_runners.GetRasterTaskRunner(), [&]() { wrapper.reset(); });
}

}  // namespace testing
}  // namespace flutter
