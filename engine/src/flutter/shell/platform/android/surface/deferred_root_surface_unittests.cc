// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/deferred_root_surface.h"

#include <cstring>
#include <memory>
#include <optional>
#include <utility>
#include <vector>

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/surface.h"
#include "flutter/flow/surface_frame.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPixmap.h"
#include "third_party/skia/include/core/SkSurface.h"

#if !SLIMPELLER
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#endif  // !SLIMPELLER

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/display_list/aiks_context.h"
#include "impeller/renderer/testing/mocks.h"
#endif  // IMPELLER_SUPPORTS_RENDERING

namespace flutter {
namespace testing {

namespace {

using ::testing::ByMove;
using ::testing::NiceMock;
using ::testing::Return;

// Standard non-empty test viewport dimensions in physical pixels.
constexpr int kTestWidthPx = 64;
constexpr int kTestHeightPx = 48;
// Sample non-zero damage rect coordinates in physical pixels.
constexpr int kDamageOriginPx = 4;
constexpr int kDamageExtentPx = 16;
// Sample root transformation scale factor used to verify delegation.
constexpr DlScalar kRootScaleFactor = 2.0f;
// Sample ARGB pixel colors and test coordinate inside the viewport.
constexpr uint32_t kSolidGreenPremul = 0xFF00FF00u;
constexpr int kSamplePixelCoord = 8;
// Sample monotonic nanosecond timestamp for SubmitInfo propagation checks.
constexpr int64_t kPresentationTimestampNs = 123456789;
// Sample negative extent in physical pixels used to verify non-positive frame
// dimension rejection.
constexpr int kNegativeExtentPx = -10;
#if SLIMPELLER
// Non-null sentinel address for opaque GrDirectContext* delegation checks when
// Ganesh is compiled out under SLIMPELLER (never dereferenced).
constexpr uintptr_t kSlimpellerSentinelGrContextAddr = 0x1234u;
#endif  // SLIMPELLER

class MockInnerSurface : public Surface {
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
  MOCK_METHOD(bool, ClearRenderContext, (), (override));
  MOCK_METHOD(bool, AllowsDrawingWhenGpuDisabled, (), (const, override));
  MOCK_METHOD(bool, EnableRasterCache, (), (const, override));
  MOCK_METHOD(std::shared_ptr<impeller::AiksContext>,
              GetAiksContext,
              (),
              (const, override));
  MOCK_METHOD(SurfaceData, GetSurfaceData, (), (const, override));
};

class TrackingSwitchableGLContext final : public SwitchableGLContext {
 public:
  TrackingSwitchableGLContext(bool* is_current,
                              std::vector<std::string>* events,
                              bool set_current_succeeds = true)
      : is_current_(is_current),
        events_(events),
        set_current_succeeds_(set_current_succeeds) {}

  bool SetCurrent() override {
    events_->push_back("SetCurrent");
    if (!set_current_succeeds_) {
      return false;
    }
    *is_current_ = true;
    return true;
  }

  bool RemoveCurrent() override {
    events_->push_back("RemoveCurrent");
    *is_current_ = false;
    return true;
  }

 private:
  bool* is_current_;
  std::vector<std::string>* events_;
  bool set_current_succeeds_;
};

#if IMPELLER_SUPPORTS_RENDERING
class DisposableMockImpellerContext
    : public impeller::testing::MockImpellerContext {
 public:
  MOCK_METHOD(void, DisposeThreadLocalCachedResources, (), (override));
};
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace

TEST(DeferredRootSurfaceTest, DelegatesAllTenSurfaceVirtualsAndHandlesNull) {
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();

  const DlMatrix kExpectedMatrix =
      DlMatrix::MakeScale({kRootScaleFactor, kRootScaleFactor, 1.0f});
  const char kSamplePayload[] = "rgba";
  sk_sp<SkData> sample_data =
      SkData::MakeWithCopy(kSamplePayload, sizeof(kSamplePayload));
#if !SLIMPELLER
  sk_sp<GrDirectContext> mock_gr_context = GrDirectContext::MakeMock(nullptr);
  GrDirectContext* expected_gr_context = mock_gr_context.get();
#else
  GrDirectContext* expected_gr_context =
      reinterpret_cast<GrDirectContext*>(kSlimpellerSentinelGrContextAddr);
#endif

#if IMPELLER_SUPPORTS_RENDERING
  auto mock_impeller_ctx =
      std::make_shared<NiceMock<DisposableMockImpellerContext>>();
  ON_CALL(*mock_impeller_ctx, IsValid()).WillByDefault(Return(false));
  auto expected_aiks =
      std::make_shared<impeller::AiksContext>(mock_impeller_ctx, nullptr);
#else
  std::shared_ptr<impeller::AiksContext> expected_aiks = nullptr;
#endif

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, GetRootTransformation())
      .WillOnce(Return(kExpectedMatrix));
  EXPECT_CALL(*raw_inner, GetContext()).WillOnce(Return(expected_gr_context));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillOnce([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });
  EXPECT_CALL(*raw_inner, ClearRenderContext()).WillOnce(Return(true));
  EXPECT_CALL(*raw_inner, AllowsDrawingWhenGpuDisabled())
      .WillOnce(Return(false));
  EXPECT_CALL(*raw_inner, EnableRasterCache()).WillOnce(Return(false));
  EXPECT_CALL(*raw_inner, GetAiksContext()).WillOnce(Return(expected_aiks));
  EXPECT_CALL(*raw_inner, GetSurfaceData()).WillOnce([sample_data] {
    return Surface::SurfaceData{.pixel_format = "RGBA_8888",
                                .data = sample_data};
  });
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce([](const DlISize& size) {
        return std::make_unique<SurfaceFrame>(
            nullptr, SurfaceFrame::FramebufferInfo{},
            [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, size, nullptr,
            /*display_list_fallback=*/true);
      });

  DeferredRootSurface deferred(std::move(inner), [] { return false; });
  EXPECT_TRUE(deferred.IsValid());
  EXPECT_EQ(deferred.GetRootTransformation(), kExpectedMatrix);
  EXPECT_EQ(deferred.GetContext(), expected_gr_context);
  std::unique_ptr<GLContextResult> ctx_res =
      deferred.MakeRenderContextCurrent();
  ASSERT_NE(ctx_res, nullptr);
  EXPECT_TRUE(ctx_res->GetResult());
  EXPECT_TRUE(deferred.ClearRenderContext());
  EXPECT_FALSE(deferred.AllowsDrawingWhenGpuDisabled());
  EXPECT_FALSE(deferred.EnableRasterCache());
  EXPECT_EQ(deferred.GetAiksContext(), expected_aiks);
  Surface::SurfaceData data = deferred.GetSurfaceData();
  EXPECT_EQ(data.pixel_format, "RGBA_8888");
  EXPECT_EQ(data.data, sample_data);
  EXPECT_NE(deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)),
            nullptr);

  // Null inner surface returns safe defaults on all 10 virtuals without crash.
  DeferredRootSurface null_deferred(nullptr, [] { return true; });
  EXPECT_FALSE(null_deferred.IsValid());
  EXPECT_EQ(null_deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)),
            nullptr);
  EXPECT_EQ(
      null_deferred.AcquireInnerFrame(DlISize(kTestWidthPx, kTestHeightPx)),
      nullptr);
  EXPECT_EQ(null_deferred.GetRootTransformation(), DlMatrix());
  EXPECT_EQ(null_deferred.GetContext(), nullptr);
  std::unique_ptr<GLContextResult> null_ctx =
      null_deferred.MakeRenderContextCurrent();
  ASSERT_NE(null_ctx, nullptr);
  EXPECT_FALSE(null_ctx->GetResult());
  EXPECT_FALSE(null_deferred.ClearRenderContext());
  EXPECT_FALSE(null_deferred.AllowsDrawingWhenGpuDisabled());
  EXPECT_TRUE(null_deferred.EnableRasterCache());
  EXPECT_EQ(null_deferred.GetAiksContext(), nullptr);
  EXPECT_EQ(null_deferred.GetSurfaceData().data, nullptr);
}

TEST(DeferredRootSurfaceTest, RejectsZeroNegativeOrInvalidSurfaceFrames) {
  bool defer = false;
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, AcquireFrame(::testing::_)).Times(0);

  DeferredRootSurface deferred(std::move(inner), [&defer] { return defer; });

  const std::vector<DlISize> kInvalidSizes = {
      DlISize(0, 0),
      DlISize(0, kTestHeightPx),
      DlISize(kTestWidthPx, 0),
      DlISize(kNegativeExtentPx, kTestHeightPx),
      DlISize(kTestWidthPx, kNegativeExtentPx),
  };

  for (bool should_defer : {false, true}) {
    defer = should_defer;
    for (const DlISize& bad_size : kInvalidSizes) {
      EXPECT_EQ(deferred.AcquireFrame(bad_size), nullptr);
      EXPECT_EQ(deferred.AcquireInnerFrame(bad_size), nullptr);
    }
  }

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(false));
  EXPECT_EQ(deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)),
            nullptr);
  EXPECT_EQ(deferred.AcquireInnerFrame(DlISize(kTestWidthPx, kTestHeightPx)),
            nullptr);
}

TEST(DeferredRootSurfaceTest,
     UnencodedDeferredFrameNeverAcquiresInnerAndDisposesImpellerThreadCache) {
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });
  EXPECT_CALL(*raw_inner, AcquireFrame(::testing::_)).Times(0);

#if IMPELLER_SUPPORTS_RENDERING
  auto mock_impeller_ctx =
      std::make_shared<NiceMock<DisposableMockImpellerContext>>();
  ON_CALL(*mock_impeller_ctx, IsValid()).WillByDefault(Return(false));
  auto aiks_ctx =
      std::make_shared<impeller::AiksContext>(mock_impeller_ctx, nullptr);
  EXPECT_CALL(*raw_inner, GetAiksContext()).WillRepeatedly(Return(aiks_ctx));
  EXPECT_CALL(*mock_impeller_ctx, DisposeThreadLocalCachedResources()).Times(1);
#endif  // IMPELLER_SUPPORTS_RENDERING

  DeferredRootSurface deferred(std::move(inner), [] { return true; });
  std::unique_ptr<SurfaceFrame> frame =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame, nullptr);
  EXPECT_TRUE(frame->framebuffer_info().supports_readback);
  EXPECT_FALSE(frame->framebuffer_info().supports_partial_repaint);

  DlPaint paint;
  paint.setColor(DlColor::kGreen());
  frame->Canvas()->DrawRect(DlRect::MakeWH(kTestWidthPx, kTestHeightPx), paint);

  sk_sp<DisplayList> dl = deferred.GetOrBuildDisplayList(*frame);
  ASSERT_NE(dl, nullptr);
  EXPECT_GT(dl->op_count(), 0u);

  // Dropping the deferred frame without Submit() (steady-state HC frame) never
  // touches inner_->AcquireFrame.
  frame.reset();
}

TEST(DeferredRootSurfaceTest,
     DualConsumesCachedDisplayListAndLazilySubmitsToInnerSurface) {
#if SLIMPELLER
  // Exercise DisplayList-backed Impeller inner SurfaceFrame when SkSurface
  // rasterization is compiled out.
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();
  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });

  uint32_t inner_op_count = 0;
  SurfaceFrame::SubmitInfo observed_submit_info;
  bool inner_submitted = false;
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce([&](const DlISize& size) {
        return std::make_unique<SurfaceFrame>(
            nullptr, SurfaceFrame::FramebufferInfo{.supports_readback = true},
            [&](SurfaceFrame& inner_frame, DlCanvas*) {
              sk_sp<DisplayList> inner_dl = inner_frame.BuildDisplayList();
              inner_op_count = inner_dl ? inner_dl->op_count() : 0u;
              return inner_dl != nullptr;
            },
            [&](SurfaceFrame& inner_frame) {
              observed_submit_info = inner_frame.submit_info();
              inner_submitted = true;
              return true;
            },
            size, nullptr, /*display_list_fallback=*/true);
      });

  DeferredRootSurface deferred(std::move(inner), [] { return true; });
  std::unique_ptr<SurfaceFrame> frame =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame, nullptr);
  frame->Canvas()->Clear(DlColor::kGreen());

  sk_sp<DisplayList> dl1 = deferred.GetOrBuildDisplayList(*frame);
  sk_sp<DisplayList> dl2 = deferred.GetOrBuildDisplayList(*frame);
  ASSERT_NE(dl1, nullptr);
  EXPECT_EQ(dl1.get(), dl2.get());
  EXPECT_GT(dl1->op_count(), 0u);

  SurfaceFrame::SubmitInfo expected_info;
  expected_info.presentation_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(kPresentationTimestampNs));
  expected_info.frame_boundary = false;
  frame->set_submit_info(expected_info);

  EXPECT_FALSE(inner_submitted);
  EXPECT_TRUE(frame->Submit());
  EXPECT_TRUE(inner_submitted);
  EXPECT_EQ(inner_op_count, dl1->op_count());
  EXPECT_EQ(observed_submit_info.presentation_time,
            expected_info.presentation_time);
  EXPECT_FALSE(observed_submit_info.frame_boundary);
#else
  // Verify pixel-exact dual rendering across both an external target (standing
  // in for HybridImageReader) and a raster SkSurface-backed inner frame
  // (standing in for Skia GL / Software root surfaces), plus DisplayList-backed
  // Impeller inner frames.
  const SkImageInfo image_info =
      SkImageInfo::MakeN32Premul(kTestWidthPx, kTestHeightPx);
  sk_sp<SkSurface> bg_target = SkSurfaces::Raster(image_info);
  sk_sp<SkSurface> root_target = SkSurfaces::Raster(image_info);
  ASSERT_NE(bg_target, nullptr);
  ASSERT_NE(root_target, nullptr);

  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();
  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });

  bool inner_encoded = false;
  bool inner_submitted = false;
  SurfaceFrame::SubmitInfo observed_submit_info;
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce([&](const DlISize& size) {
        SurfaceFrame::FramebufferInfo info;
        info.supports_partial_repaint = true;
        info.existing_damage = DlIRect::MakeXYWH(
            kDamageOriginPx, kDamageOriginPx, kDamageExtentPx, kDamageExtentPx);
        return std::make_unique<SurfaceFrame>(
            root_target, info,
            [&](SurfaceFrame& inner_frame, DlCanvas*) {
              EXPECT_FALSE(
                  inner_frame.framebuffer_info().existing_damage.has_value());
              inner_encoded = true;
              return true;
            },
            [&](SurfaceFrame& inner_frame) {
              observed_submit_info = inner_frame.submit_info();
              inner_submitted = true;
              return true;
            },
            size);
      });

  DeferredRootSurface deferred(std::move(inner), [] { return true; });
  std::unique_ptr<SurfaceFrame> frame =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame, nullptr);

  frame->Canvas()->Clear(DlColor::kGreen());

  // 1st consumption (e.g. HC exit frame background ImageLayer):
  sk_sp<DisplayList> dl1 = deferred.GetOrBuildDisplayList(*frame);
  sk_sp<DisplayList> dl2 = deferred.GetOrBuildDisplayList(*frame);
  ASSERT_NE(dl1, nullptr);
  EXPECT_EQ(dl1.get(), dl2.get());
  EXPECT_GT(dl1->op_count(), 0u);

  DlSkCanvasAdapter bg_canvas(bg_target->getCanvas());
  bg_canvas.DrawDisplayList(dl1);

  // Inner surface still has not been acquired before Submit().
  EXPECT_FALSE(inner_encoded);
  EXPECT_FALSE(inner_submitted);

  SurfaceFrame::SubmitInfo expected_info;
  expected_info.presentation_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(kPresentationTimestampNs));
  expected_info.frame_boundary = false;
  frame->set_submit_info(expected_info);

  // 2nd consumption via deferred_frame->Submit(): lazily acquires inner_,
  // replays the cached DisplayList without destructive loss, and submits.
  EXPECT_TRUE(frame->Submit());
  EXPECT_TRUE(inner_encoded);
  EXPECT_TRUE(inner_submitted);
  EXPECT_EQ(observed_submit_info.presentation_time,
            expected_info.presentation_time);
  EXPECT_FALSE(observed_submit_info.frame_boundary);

  SkPixmap bg_pixmap;
  SkPixmap root_pixmap;
  ASSERT_TRUE(bg_target->peekPixels(&bg_pixmap));
  ASSERT_TRUE(root_target->peekPixels(&root_pixmap));
  EXPECT_EQ(*bg_pixmap.addr32(kSamplePixelCoord, kSamplePixelCoord),
            kSolidGreenPremul);
  EXPECT_EQ(*root_pixmap.addr32(kSamplePixelCoord, kSamplePixelCoord),
            kSolidGreenPremul);
#endif  // SLIMPELLER
}

TEST(DeferredRootSurfaceTest,
     HoldsGLContextSwitchCurrentAcrossDeferredFrameLifetimeAndChecksFailure) {
  bool is_gl_current = false;
  std::vector<std::string> events;
  bool set_current_succeeds = true;

  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();
  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([&] {
    return std::make_unique<GLContextSwitch>(
        std::make_unique<TrackingSwitchableGLContext>(&is_gl_current, &events,
                                                      set_current_succeeds));
  });
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce([&](const DlISize& size) {
        // GL context must still be current when lazy Encode acquires inner_.
        EXPECT_TRUE(is_gl_current);
        return std::make_unique<SurfaceFrame>(
            nullptr, SurfaceFrame::FramebufferInfo{.supports_readback = true},
            [&](SurfaceFrame& inner_frame, DlCanvas*) {
              EXPECT_TRUE(is_gl_current);
              return inner_frame.BuildDisplayList() != nullptr;
            },
            [&](const SurfaceFrame&) {
              EXPECT_TRUE(is_gl_current);
              return true;
            },
            size, raw_inner->MakeRenderContextCurrent(),
            /*display_list_fallback=*/true);
      });

  DeferredRootSurface deferred(std::move(inner), [] { return true; });
  std::unique_ptr<SurfaceFrame> frame =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame, nullptr);
  EXPECT_TRUE(is_gl_current);
  EXPECT_EQ(events, std::vector<std::string>({"SetCurrent"}));

  frame->Canvas()->Clear(DlColor::kBlue());
  EXPECT_TRUE(frame->Submit());
  // Both nested GLContextSwitches remain alive until the outer deferred
  // SurfaceFrame itself is destroyed.
  EXPECT_TRUE(is_gl_current);
  EXPECT_EQ(events, (std::vector<std::string>{"SetCurrent", "SetCurrent"}));
  frame.reset();
  EXPECT_FALSE(is_gl_current);
  EXPECT_EQ(events,
            (std::vector<std::string>{"SetCurrent", "SetCurrent",
                                      "RemoveCurrent", "RemoveCurrent"}));

  // Failed MakeRenderContextCurrent returns nullptr without acquiring a frame.
  set_current_succeeds = false;
  EXPECT_EQ(deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)),
            nullptr);
}

TEST(DeferredRootSurfaceTest,
     ClearsExistingDamageOnFirstDirectFrameAfterDeferral) {
  bool should_defer = false;
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });

  const DlIRect kSampleDamage = DlIRect::MakeXYWH(
      kDamageOriginPx, kDamageOriginPx, kDamageExtentPx, kDamageExtentPx);
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillRepeatedly([kSampleDamage](const DlISize& size) {
        SurfaceFrame::FramebufferInfo info;
        info.supports_partial_repaint = true;
        info.existing_damage = kSampleDamage;
        return std::make_unique<SurfaceFrame>(
            nullptr, info, [](const SurfaceFrame&, DlCanvas*) { return true; },
            [](const SurfaceFrame&) { return true; }, size, nullptr,
            /*display_list_fallback=*/true);
      });

  DeferredRootSurface deferred(std::move(inner),
                               [&should_defer] { return should_defer; });

  // 1. Direct frame before any deferral preserves existing_damage.
  auto direct_before =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(direct_before, nullptr);
  EXPECT_EQ(direct_before->framebuffer_info().existing_damage, kSampleDamage);

  // 2. Deferred session frame + AcquireInnerFrame (transparent entry clear):
  // AcquireInnerFrame clears existing_damage on its returned frame while
  // keeping post-deferral tracking armed for the first direct exit frame.
  should_defer = true;
  auto deferred_frame =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(deferred_frame, nullptr);
  auto inner_clear_frame =
      deferred.AcquireInnerFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(inner_clear_frame, nullptr);
  EXPECT_FALSE(
      inner_clear_frame->framebuffer_info().existing_damage.has_value());
  deferred_frame.reset();

  // 3. First direct frame after deferral clears existing_damage to force full
  // repaint.
  should_defer = false;
  auto first_direct_after =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(first_direct_after, nullptr);
  EXPECT_FALSE(
      first_direct_after->framebuffer_info().existing_damage.has_value());

  // 4. Subsequent direct frames preserve existing_damage for partial repaint.
  auto second_direct_after =
      deferred.AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(second_direct_after, nullptr);
  EXPECT_EQ(second_direct_after->framebuffer_info().existing_damage,
            kSampleDamage);
}

TEST(DeferredRootSurfaceTest,
     PropagatesInnerFailuresAndInvalidatesWeakPtrOnDestruction) {
  auto inner = std::make_unique<NiceMock<MockInnerSurface>>();
  MockInnerSurface* raw_inner = inner.get();

  EXPECT_CALL(*raw_inner, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });

  // Subcase 1: Lazy inner AcquireFrame returning nullptr fails Submit()
  // cleanly.
  EXPECT_CALL(*raw_inner, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce(Return(ByMove(nullptr)));

  auto deferred = std::make_unique<DeferredRootSurface>(std::move(inner),
                                                        [] { return true; });
  fml::WeakPtr<DeferredRootSurface> weak_surface = deferred->GetWeakPtr();
  EXPECT_TRUE(static_cast<bool>(weak_surface));

  auto frame1 = deferred->AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame1, nullptr);
  frame1->Canvas()->Clear(DlColor::kRed());
  EXPECT_FALSE(frame1->Submit());

  // Subcase 2: Destroying DeferredRootSurface before Encode() invalidates
  // weak_surface and causes Submit() to return false without UAF.
  auto frame2 = deferred->AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame2, nullptr);
  frame2->Canvas()->Clear(DlColor::kRed());
  deferred.reset();
  EXPECT_FALSE(static_cast<bool>(weak_surface));
  EXPECT_FALSE(frame2->Submit());

  // Subcase 3: Destroying DeferredRootSurface after Encode() succeeds and
  // before Submit() destroys state->inner_frame while inner_ is still alive and
  // causes Submit() to return false without invoking inner SubmitCallback.
  struct LifetimeTrackingInnerSurface : public MockInnerSurface {
    explicit LifetimeTrackingInnerSurface(bool* alive) : alive_(alive) {}
    ~LifetimeTrackingInnerSurface() override { *alive_ = false; }
    bool* alive_;
  };
  struct InnerFrameDestructorGuard final : public GLContextDefaultResult {
    InnerFrameDestructorGuard(const bool* inner_alive, bool* destroyed)
        : GLContextDefaultResult(true),
          inner_alive_(inner_alive),
          destroyed_(destroyed) {}
    ~InnerFrameDestructorGuard() override {
      EXPECT_TRUE(*inner_alive_);
      *destroyed_ = true;
    }
    const bool* inner_alive_;
    bool* destroyed_;
  };

  bool inner_alive = true;
  bool inner_frame_destroyed = false;
  bool inner_submit_called = false;
  auto inner2 =
      std::make_unique<NiceMock<LifetimeTrackingInnerSurface>>(&inner_alive);
  LifetimeTrackingInnerSurface* raw_inner2 = inner2.get();
  EXPECT_CALL(*raw_inner2, IsValid()).WillRepeatedly(Return(true));
  EXPECT_CALL(*raw_inner2, MakeRenderContextCurrent()).WillRepeatedly([] {
    return std::make_unique<GLContextDefaultResult>(true);
  });
  EXPECT_CALL(*raw_inner2, AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx)))
      .WillOnce([&](const DlISize& size) {
        return std::make_unique<SurfaceFrame>(
            nullptr, SurfaceFrame::FramebufferInfo{.supports_readback = true},
            [](SurfaceFrame& inner_frame, DlCanvas*) {
              return inner_frame.BuildDisplayList() != nullptr;
            },
            [&](const SurfaceFrame&) {
              inner_submit_called = true;
              return true;
            },
            size,
            std::make_unique<InnerFrameDestructorGuard>(&inner_alive,
                                                        &inner_frame_destroyed),
            /*display_list_fallback=*/true);
      });

  auto deferred2 = std::make_unique<DeferredRootSurface>(std::move(inner2),
                                                         [] { return true; });
  auto frame3 = deferred2->AcquireFrame(DlISize(kTestWidthPx, kTestHeightPx));
  ASSERT_NE(frame3, nullptr);
  frame3->Canvas()->Clear(DlColor::kRed());
  ASSERT_TRUE(frame3->Encode());
  EXPECT_FALSE(inner_frame_destroyed);

  deferred2.reset();
  EXPECT_FALSE(inner_alive);
  EXPECT_TRUE(inner_frame_destroyed);
  EXPECT_FALSE(frame3->Submit());
  EXPECT_FALSE(inner_submit_called);
}

}  // namespace testing
}  // namespace flutter
