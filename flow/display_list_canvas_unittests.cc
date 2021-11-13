// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/display_list_canvas.h"
#include "flutter/flow/layers/physical_shape_layer.h"

#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/core/SkVertices.h"
#include "third_party/skia/include/effects/SkBlenders.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkDiscretePathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

#include <cmath>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

constexpr int TestWidth = 200;
constexpr int TestHeight = 200;
constexpr int RenderWidth = 100;
constexpr int RenderHeight = 100;
constexpr int RenderHalfWidth = 50;
constexpr int RenderHalfHeight = 50;
constexpr int RenderLeft = (TestWidth - RenderWidth) / 2;
constexpr int RenderTop = (TestHeight - RenderHeight) / 2;
constexpr int RenderRight = RenderLeft + RenderWidth;
constexpr int RenderBottom = RenderTop + RenderHeight;
constexpr int RenderCenterX = (RenderLeft + RenderRight) / 2;
constexpr int RenderCenterY = (RenderTop + RenderBottom) / 2;
constexpr SkScalar RenderRadius = std::min(RenderWidth, RenderHeight) / 2.0;
constexpr SkScalar RenderCornerRadius = RenderRadius / 5.0;

constexpr SkPoint TestCenter = SkPoint::Make(TestWidth / 2, TestHeight / 2);
constexpr SkRect TestBounds = SkRect::MakeWH(TestWidth, TestHeight);
constexpr SkRect RenderBounds =
    SkRect::MakeLTRB(RenderLeft, RenderTop, RenderRight, RenderBottom);

// The tests try 3 miter limit values, 0.0, 4.0 (the default), and 10.0
// These values will allow us to construct a diamond that spans the
// width or height of the render box and still show the miter for 4.0
// and 10.0.
// These values were discovered by drawing a diamond path in Skia fiddle
// and then playing with the cross-axis size until the miter was about
// as large as it could get before it got cut off.

// The X offsets which will be used for tall vertical diamonds are
// expressed in terms of the rendering height to obtain the proper angle
constexpr SkScalar MiterExtremeDiamondOffsetX = RenderHeight * 0.04;
constexpr SkScalar Miter10DiamondOffsetX = RenderHeight * 0.051;
constexpr SkScalar Miter4DiamondOffsetX = RenderHeight * 0.14;

// The Y offsets which will be used for long horizontal diamonds are
// expressed in terms of the rendering width to obtain the proper angle
constexpr SkScalar MiterExtremeDiamondOffsetY = RenderWidth * 0.04;
constexpr SkScalar Miter10DiamondOffsetY = RenderWidth * 0.051;
constexpr SkScalar Miter4DiamondOffsetY = RenderWidth * 0.14;

// Render 3 vertical and horizontal diamonds each
// designed to break at the tested miter limits
// 0.0, 4.0 and 10.0
constexpr SkScalar x_off_0 = RenderCenterX;
constexpr SkScalar x_off_l1 = RenderCenterX - Miter4DiamondOffsetX;
constexpr SkScalar x_off_l2 = x_off_l1 - Miter10DiamondOffsetX;
constexpr SkScalar x_off_l3 = x_off_l2 - Miter10DiamondOffsetX;
constexpr SkScalar x_off_r1 = RenderCenterX + Miter4DiamondOffsetX;
constexpr SkScalar x_off_r2 = x_off_r1 + MiterExtremeDiamondOffsetX;
constexpr SkScalar x_off_r3 = x_off_r2 + MiterExtremeDiamondOffsetX;
constexpr SkPoint VerticalMiterDiamondPoints[] = {
    // Vertical diamonds:
    //  M10   M4  Mextreme
    //   /\   /|\   /\       top of RenderBounds
    //  /  \ / | \ /  \              to
    // <----X--+--X---->         RenderCenter
    //  \  / \ | / \  /              to
    //   \/   \|/   \/      bottom of RenderBounds
    // clang-format off
    SkPoint::Make(x_off_l3, RenderCenterY),
    SkPoint::Make(x_off_l2, RenderTop),
    SkPoint::Make(x_off_l1, RenderCenterY),
    SkPoint::Make(x_off_0,  RenderTop),
    SkPoint::Make(x_off_r1, RenderCenterY),
    SkPoint::Make(x_off_r2, RenderTop),
    SkPoint::Make(x_off_r3, RenderCenterY),
    SkPoint::Make(x_off_r2, RenderBottom),
    SkPoint::Make(x_off_r1, RenderCenterY),
    SkPoint::Make(x_off_0,  RenderBottom),
    SkPoint::Make(x_off_l1, RenderCenterY),
    SkPoint::Make(x_off_l2, RenderBottom),
    SkPoint::Make(x_off_l3, RenderCenterY),
    // clang-format on
};
const int VerticalMiterDiamondPointCount =
    sizeof(VerticalMiterDiamondPoints) / sizeof(VerticalMiterDiamondPoints[0]);

constexpr SkScalar y_off_0 = RenderCenterY;
constexpr SkScalar y_off_u1 = RenderCenterY - Miter4DiamondOffsetY;
constexpr SkScalar y_off_u2 = y_off_u1 - Miter10DiamondOffsetY;
constexpr SkScalar y_off_u3 = y_off_u2 - Miter10DiamondOffsetY;
constexpr SkScalar y_off_d1 = RenderCenterY + Miter4DiamondOffsetY;
constexpr SkScalar y_off_d2 = y_off_d1 + MiterExtremeDiamondOffsetY;
constexpr SkScalar y_off_d3 = y_off_d2 + MiterExtremeDiamondOffsetY;
const SkPoint HorizontalMiterDiamondPoints[] = {
    // Horizontal diamonds
    // Same configuration as Vertical diamonds above but
    // rotated 90 degrees
    // clang-format off
    SkPoint::Make(RenderCenterX, y_off_u3),
    SkPoint::Make(RenderLeft,    y_off_u2),
    SkPoint::Make(RenderCenterX, y_off_u1),
    SkPoint::Make(RenderLeft,    y_off_0),
    SkPoint::Make(RenderCenterX, y_off_d1),
    SkPoint::Make(RenderLeft,    y_off_d2),
    SkPoint::Make(RenderCenterX, y_off_d3),
    SkPoint::Make(RenderRight,   y_off_d2),
    SkPoint::Make(RenderCenterX, y_off_d1),
    SkPoint::Make(RenderRight,   y_off_0),
    SkPoint::Make(RenderCenterX, y_off_u1),
    SkPoint::Make(RenderRight,   y_off_u2),
    SkPoint::Make(RenderCenterX, y_off_u3),
    // clang-format on
};
const int HorizontalMiterDiamondPointCount =
    (sizeof(HorizontalMiterDiamondPoints) /
     sizeof(HorizontalMiterDiamondPoints[0]));

// A class to specify how much tolerance to allow in bounds estimates.
// For some attributes, the machinery must make some conservative
// assumptions as to the extent of the bounds, but some of our test
// parameters do not produce bounds that expand by the full conservative
// estimates. This class provides a number of tweaks to apply to the
// pixel bounds to account for the conservative factors.
//
// An instance is passed along through the methods and if any test adds
// a paint attribute or other modifier that will cause a more conservative
// estimate for bounds, it can modify the factors here to account for it.
// Ideally, all tests will be executed with geometry that will trigger
// the conservative cases anyway and all attributes will be combined with
// other attributes that make their output more predictable, but in those
// cases where a given test sequence cannot really provide attributes to
// demonstrate the worst case scenario, they can modify these factors to
// avoid false bounds overflow notifications.
class BoundsTolerance {
 public:
  BoundsTolerance() : BoundsTolerance(0, 0, 1, 1, 0, 0, 0) {}
  BoundsTolerance(SkScalar bounds_pad_x,
                  SkScalar bounds_pad_y,
                  SkScalar scale_x,
                  SkScalar scale_y,
                  SkScalar absolute_pad_x,
                  SkScalar absolute_pad_y,
                  SkScalar discrete_offset)
      : bounds_pad_x_(bounds_pad_x),
        bounds_pad_y_(bounds_pad_y),
        scale_x_(scale_x),
        scale_y_(scale_y),
        absolute_pad_x_(absolute_pad_x),
        absolute_pad_y_(absolute_pad_y),
        discrete_offset_(discrete_offset) {}

  BoundsTolerance addBoundsPadding(SkScalar bounds_pad_x,
                                   SkScalar bounds_pad_y) const {
    return {bounds_pad_x_ + bounds_pad_x,
            bounds_pad_y_ + bounds_pad_y,
            scale_x_,
            scale_y_,
            absolute_pad_x_,
            absolute_pad_y_,
            discrete_offset_};
  }

  BoundsTolerance addScale(SkScalar scale_x, SkScalar scale_y) const {
    return {bounds_pad_x_,       //
            bounds_pad_y_,       //
            scale_x_ * scale_x,  //
            scale_y_ * scale_y,  //
            absolute_pad_x_,     //
            absolute_pad_y_,     //
            discrete_offset_};
  }

  BoundsTolerance addAbsolutePadding(SkScalar absolute_pad_x,
                                     SkScalar absolute_pad_y) const {
    return {bounds_pad_x_,
            bounds_pad_y_,
            scale_x_,
            scale_y_,
            absolute_pad_x_ + absolute_pad_x,
            absolute_pad_y_ + absolute_pad_y,
            discrete_offset_};
  }

  BoundsTolerance addDiscreteOffset(SkScalar discrete_offset) const {
    return {bounds_pad_x_,
            bounds_pad_y_,
            scale_x_,
            scale_y_,
            absolute_pad_x_,
            absolute_pad_y_,
            discrete_offset_ + discrete_offset};
  }

  bool overflows(SkISize pix_size,
                 int worst_bounds_pad_x,
                 int worst_bounds_pad_y) const {
    int scaled_bounds_pad_x =
        std::ceil((pix_size.width() + bounds_pad_x_) * scale_x_);
    int allowed_width = scaled_bounds_pad_x + absolute_pad_x_;
    int scaled_bounds_pad_y =
        std::ceil((pix_size.height() + bounds_pad_y_) * scale_y_);
    int allowed_height = scaled_bounds_pad_y + absolute_pad_y_;
    int allowed_pad_x = allowed_width - pix_size.width();
    int allowed_pad_y = allowed_height - pix_size.height();
    if (worst_bounds_pad_x > allowed_pad_x ||
        worst_bounds_pad_y > allowed_pad_y) {
      FML_LOG(ERROR) << "allowed pad: "  //
                     << allowed_pad_x << ", " << allowed_pad_y;
    }
    return (worst_bounds_pad_x > allowed_pad_x ||
            worst_bounds_pad_y > allowed_pad_y);
  }

  SkScalar discrete_offset() const { return discrete_offset_; }

 private:
  SkScalar bounds_pad_x_;
  SkScalar bounds_pad_y_;
  SkScalar scale_x_;
  SkScalar scale_y_;
  SkScalar absolute_pad_x_;
  SkScalar absolute_pad_y_;

  SkScalar discrete_offset_;
};

class CanvasCompareTester {
 private:
  // If a test is using any shadow operations then we cannot currently
  // record those in an SkCanvas and play it back into a DisplayList
  // because internally the operation gets encapsulated in a Skia
  // ShadowRec which is not exposed by their headers. For operations
  // that use shadows, we can perform a lot of tests, but not the tests
  // that require SkCanvas->DisplayList transfers.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  static bool TestingDrawShadows;
  // The CPU renders nothing for drawVertices with a Blender.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12200
  static bool TestingDrawVertices;
  // The CPU renders nothing for drawAtlas with a Blender.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12199
  static bool TestingDrawAtlas;

 public:
  typedef const std::function<void(SkCanvas*, SkPaint&)> CvRenderer;
  typedef const std::function<void(DisplayListBuilder&)> DlRenderer;
  typedef const std::function<const BoundsTolerance(const BoundsTolerance&,
                                                    const SkPaint&,
                                                    const SkMatrix&)>
      ToleranceAdjuster;

  static BoundsTolerance DefaultTolerance;
  static const BoundsTolerance DefaultAdjuster(const BoundsTolerance& tolerance,
                                               const SkPaint& paint,
                                               const SkMatrix& matrix) {
    return tolerance;
  }

  // All of the tests should eventually use this method except for the
  // tests that call |RenderNoAttributes| because they do not use the
  // SkPaint object.
  // But there are a couple of conditions beyond our control which require
  // the use of one of the variant methods below (|RenderShadows|,
  // |RenderVertices|, |RenderAtlas|).
  static void RenderAll(CvRenderer& cv_renderer,
                        DlRenderer& dl_renderer,
                        ToleranceAdjuster& adjuster = DefaultAdjuster,
                        const BoundsTolerance& tolerance = DefaultTolerance) {
    RenderNoAttributes(cv_renderer, dl_renderer, adjuster, tolerance);
    RenderWithAttributes(cv_renderer, dl_renderer, adjuster, tolerance);
  }

  // Used by the tests that render shadows to deal with a condition where
  // we cannot recapture the shadow information from an SkCanvas stream
  // due to the DrawShadowRec used by Skia is not properly exported.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  static void RenderShadows(
      CvRenderer& cv_renderer,
      DlRenderer& dl_renderer,
      ToleranceAdjuster& adjuster = DefaultAdjuster,
      const BoundsTolerance& tolerance = DefaultTolerance) {
    TestingDrawShadows = true;
    RenderNoAttributes(cv_renderer, dl_renderer, adjuster, tolerance);
    TestingDrawShadows = false;
  }

  // Used by the tests that call drawVertices to avoid using an SkBlender
  // during testing because the CPU renderer appears not to render anything.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12200
  static void RenderVertices(CvRenderer& cv_renderer, DlRenderer& dl_renderer) {
    TestingDrawVertices = true;
    RenderAll(cv_renderer, dl_renderer);
    TestingDrawVertices = false;
  }

  // Used by the tests that call drawAtlas to avoid using an SkBlender
  // during testing because the CPU renderer appears not to render anything.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12199
  static void RenderAtlas(CvRenderer& cv_renderer, DlRenderer& dl_renderer) {
    TestingDrawAtlas = true;
    RenderAll(cv_renderer, dl_renderer);
    TestingDrawAtlas = false;
  }

  // Used by the tests that call a draw method that does not take a paint
  // call. Those tests could use |RenderAll| but there would be a lot of
  // wasted test runs that prepare an SkPaint that is never used.
  static void RenderNoAttributes(
      CvRenderer& cv_renderer,
      DlRenderer& dl_renderer,
      ToleranceAdjuster& adjuster = DefaultAdjuster,
      const BoundsTolerance& tolerance = DefaultTolerance) {
    RenderWith([=](SkCanvas*, SkPaint& p) {},  //
               [=](DisplayListBuilder& d) {},  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Base Test");
    RenderWithTransforms(cv_renderer, dl_renderer, adjuster, tolerance);
    RenderWithClips(cv_renderer, dl_renderer, adjuster, tolerance);
    RenderWithSaveRestore(cv_renderer, dl_renderer, adjuster, tolerance);
  }

  static void RenderWithSaveRestore(CvRenderer& cv_renderer,
                                    DlRenderer& dl_renderer,
                                    ToleranceAdjuster& adjuster,
                                    const BoundsTolerance& tolerance) {
    SkRect clip = SkRect::MakeLTRB(0, 0, 10, 10);
    SkRect rect = SkRect::MakeLTRB(5, 5, 15, 15);
    SkColor alpha_layer_color = SkColorSetARGB(0x7f, 0x00, 0xff, 0xff);
    SkColor default_color = SkPaint().getColor();
    CvRenderer cv_restored = [=](SkCanvas* cv, SkPaint& p) {
      // Draw more than one primitive to disable peephole optimizations
      cv->drawRect(RenderBounds.makeOutset(5, 5), p);
      cv_renderer(cv, p);
      cv->restore();
    };
    DlRenderer dl_restored = [=](DisplayListBuilder& b) {
      // Draw more than one primitive to disable peephole optimizations
      b.drawRect(RenderBounds.makeOutset(5, 5));
      dl_renderer(b);
      b.restore();
    };
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {
          cv->save();
          cv->clipRect(clip, SkClipOp::kIntersect, false);
          cv->drawRect(rect, p);
          cv->restore();
        },
        [=](DisplayListBuilder& b) {
          b.save();
          b.clipRect(clip, SkClipOp::kIntersect, false);
          b.drawRect(rect);
          b.restore();
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "With prior save/clip/restore");
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {  //
          cv->saveLayer(nullptr, nullptr);
        },
        [=](DisplayListBuilder& b) {  //
          b.saveLayer(nullptr, false);
        },
        cv_restored, dl_restored, adjuster, tolerance,
        "saveLayer no paint, no bounds");
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {  //
          cv->saveLayer(RenderBounds, nullptr);
        },
        [=](DisplayListBuilder& b) {  //
          b.saveLayer(&RenderBounds, false);
        },
        cv_restored, dl_restored, adjuster, tolerance,
        "saveLayer no paint, with bounds");
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {
          SkPaint save_p;
          save_p.setColor(alpha_layer_color);
          cv->saveLayer(nullptr, &save_p);
        },
        [=](DisplayListBuilder& b) {
          b.setColor(alpha_layer_color);
          b.saveLayer(nullptr, true);
          b.setColor(default_color);
        },
        cv_restored, dl_restored, adjuster, tolerance,
        "saveLayer with alpha, no bounds");
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {
          SkPaint save_p;
          save_p.setColor(alpha_layer_color);
          cv->saveLayer(RenderBounds, &save_p);
        },
        [=](DisplayListBuilder& b) {
          b.setColor(alpha_layer_color);
          b.saveLayer(&RenderBounds, true);
          b.setColor(default_color);
        },
        cv_restored, dl_restored, adjuster, tolerance,
        "saveLayer with alpha and bounds");

    {
      sk_sp<SkImageFilter> filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kDecal, nullptr, nullptr);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(
            [=](SkCanvas* cv, SkPaint& p) {
              SkPaint save_p;
              save_p.setImageFilter(filter);
              cv->saveLayer(nullptr, &save_p);
              p.setStrokeWidth(5.0);
            },
            [=](DisplayListBuilder& b) {
              b.setImageFilter(filter);
              b.saveLayer(nullptr, true);
              b.setImageFilter(nullptr);
              b.setStrokeWidth(5.0);
            },
            cv_restored, dl_restored, adjuster, blur5Tolerance,
            "saveLayer ImageFilter, no bounds");
      }
      ASSERT_TRUE(filter->unique())
          << "saveLayer ImageFilter, no bounds Cleanup";
      {
        RenderWith(
            [=](SkCanvas* cv, SkPaint& p) {
              SkPaint save_p;
              save_p.setImageFilter(filter);
              cv->saveLayer(RenderBounds, &save_p);
              p.setStrokeWidth(5.0);
            },
            [=](DisplayListBuilder& b) {
              b.setImageFilter(filter);
              b.saveLayer(&RenderBounds, true);
              b.setImageFilter(nullptr);
              b.setStrokeWidth(5.0);
            },
            cv_restored, dl_restored, adjuster, blur5Tolerance,
            "saveLayer ImageFilter and bounds");
      }
      ASSERT_TRUE(filter->unique())
          << "saveLayer ImageFilter and bounds Cleanup";
    }
  }

  static void RenderWithAttributes(CvRenderer& cv_renderer,
                                   DlRenderer& dl_renderer,
                                   ToleranceAdjuster& adjuster,
                                   const BoundsTolerance& tolerance) {
    RenderWith([=](SkCanvas*, SkPaint& p) {},  //
               [=](DisplayListBuilder& d) {},  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Base Test");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setAntiAlias(true); },  //
               [=](DisplayListBuilder& b) { b.setAntiAlias(true); },  //
               cv_renderer, dl_renderer, adjuster, tolerance,
               "AntiAlias == True");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setAntiAlias(false); },  //
               [=](DisplayListBuilder& b) { b.setAntiAlias(false); },  //
               cv_renderer, dl_renderer, adjuster, tolerance,
               "AntiAlias == False");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setDither(true); },  //
               [=](DisplayListBuilder& b) { b.setDither(true); },  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Dither == True");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setDither(false); },  //
               [=](DisplayListBuilder& b) { b.setDither(false); },  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Dither = False");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorBLUE); },  //
               [=](DisplayListBuilder& b) { b.setColor(SK_ColorBLUE); },  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Color == Blue");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorGREEN); },  //
               [=](DisplayListBuilder& b) { b.setColor(SK_ColorGREEN); },  //
               cv_renderer, dl_renderer, adjuster, tolerance, "Color == Green");

    RenderWithStrokes(cv_renderer, dl_renderer, adjuster, tolerance);

    {
      // half opaque cyan
      SkColor blendableColor = SkColorSetARGB(0x7f, 0x00, 0xff, 0xff);
      SkColor bg = SK_ColorWHITE;

      RenderWith(
          [=](SkCanvas*, SkPaint& p) {
            p.setBlendMode(SkBlendMode::kSrcIn);
            p.setColor(blendableColor);
          },
          [=](DisplayListBuilder& b) {
            b.setBlendMode(SkBlendMode::kSrcIn);
            b.setColor(blendableColor);
          },
          cv_renderer, dl_renderer, adjuster, tolerance, "Blend == SrcIn", &bg);
      RenderWith(
          [=](SkCanvas*, SkPaint& p) {
            p.setBlendMode(SkBlendMode::kDstIn);
            p.setColor(blendableColor);
          },
          [=](DisplayListBuilder& b) {
            b.setBlendMode(SkBlendMode::kDstIn);
            b.setColor(blendableColor);
          },
          cv_renderer, dl_renderer, adjuster, tolerance, "Blend == DstIn", &bg);
    }

    if (!(TestingDrawAtlas || TestingDrawVertices)) {
      sk_sp<SkBlender> blender =
          SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, false);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setBlender(blender); },
                   [=](DisplayListBuilder& b) { b.setBlender(blender); },
                   cv_renderer, dl_renderer, adjuster, tolerance,
                   "ImageFilter == Blender Arithmetic 0.25-false");
      }
      ASSERT_TRUE(blender->unique()) << "Blender Cleanup";
      blender = SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, true);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setBlender(blender); },
                   [=](DisplayListBuilder& b) { b.setBlender(blender); },
                   cv_renderer, dl_renderer, adjuster, tolerance,
                   "ImageFilter == Blender Arithmetic 0.25-true");
      }
      ASSERT_TRUE(blender->unique()) << "Blender Cleanup";
    }

    {
      sk_sp<SkImageFilter> filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kDecal, nullptr, nullptr);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Provide some non-trivial stroke size to get blurred
              p.setStrokeWidth(5.0);
              p.setImageFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              // Provide some non-trivial stroke size to get blurred
              b.setStrokeWidth(5.0);
              b.setImageFilter(filter);
            },
            cv_renderer, dl_renderer, adjuster, blur5Tolerance,
            "ImageFilter == Decal Blur 5");
      }
      ASSERT_TRUE(filter->unique()) << "ImageFilter Cleanup";
      filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kClamp, nullptr, nullptr);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Provide some non-trivial stroke size to get blurred
              p.setStrokeWidth(5.0);
              p.setImageFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              // Provide some non-trivial stroke size to get blurred
              b.setStrokeWidth(5.0);
              b.setImageFilter(filter);
            },
            cv_renderer, dl_renderer, adjuster, blur5Tolerance,
            "ImageFilter == Clamp Blur 5");
      }
      ASSERT_TRUE(filter->unique()) << "ImageFilter Cleanup";
    }

    {
      // clang-format off
      constexpr float rotate_color_matrix[20] = {
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
      };
      constexpr float invert_color_matrix[20] = {
        -1.0,    0,    0, 1.0,   0,
           0, -1.0,    0, 1.0,   0,
           0,    0, -1.0, 1.0,   0,
         1.0,  1.0,  1.0, 1.0,   0,
      };
      // clang-format on
      sk_sp<SkColorFilter> filter = SkColorFilters::Matrix(rotate_color_matrix);
      {
        SkColor bg = SK_ColorWHITE;
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setColor(SK_ColorYELLOW);
              p.setColorFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              b.setColor(SK_ColorYELLOW);
              b.setColorFilter(filter);
            },
            cv_renderer, dl_renderer, adjuster, tolerance,
            "ColorFilter == RotateRGB", &bg);
      }
      ASSERT_TRUE(filter->unique()) << "ColorFilter == RotateRGB Cleanup";
      filter = SkColorFilters::Matrix(invert_color_matrix);
      {
        SkColor bg = SK_ColorWHITE;
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setColor(SK_ColorYELLOW);
              p.setColorFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              b.setColor(SK_ColorYELLOW);
              b.setInvertColors(true);
            },
            cv_renderer, dl_renderer, adjuster, tolerance,
            "ColorFilter == Invert", &bg);
      }
      ASSERT_TRUE(filter->unique()) << "ColorFilter == Invert Cleanup";
    }

    {
      sk_sp<SkPathEffect> effect = SkDiscretePathEffect::Make(3, 5);
      {
        // Discrete path effects need a stroke width for drawPointsAsPoints
        // to do something realistic
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStrokeWidth(5.0);
              // A Discrete(3, 5) effect produces miters that are near
              // maximal for a miter limit of 3.0.
              p.setStrokeMiter(3.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setStrokeWidth(5.0);
              // A Discrete(3, 5) effect produces miters that are near
              // maximal for a miter limit of 3.0.
              b.setStrokeMiter(3.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, adjuster,
            tolerance
                // register the discrete offset so adjusters can compensate
                .addDiscreteOffset(5)
                // the miters in the 3-5 discrete effect don't always fill
                // their conservative bounds, so tolerate a couple of pixels
                .addBoundsPadding(2, 2),
            "PathEffect == Discrete-3-5");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect == Discrete-3-5 Cleanup";
      effect = SkDiscretePathEffect::Make(2, 3);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStrokeWidth(5.0);
              // A Discrete(2, 3) effect produces miters that are near
              // maximal for a miter limit of 2.5.
              p.setStrokeMiter(2.5);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setStrokeWidth(5.0);
              // A Discrete(2, 3) effect produces miters that are near
              // maximal for a miter limit of 2.5.
              b.setStrokeMiter(2.5);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, adjuster,
            tolerance
                // register the discrete offset so adjusters can compensate
                .addDiscreteOffset(3)
                // the miters in the 3-5 discrete effect don't always fill
                // their conservative bounds, so tolerate a couple of pixels
                .addBoundsPadding(2, 2),
            "PathEffect == Discrete-2-3");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect == Discrete-2-3 Cleanup";
    }

    {
      sk_sp<SkMaskFilter> filter =
          SkMaskFilter::MakeBlur(kNormal_SkBlurStyle, 5.0);
      BoundsTolerance blur5Tolerance = tolerance.addBoundsPadding(4, 4);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Provide some non-trivial stroke size to get blurred
              p.setStrokeWidth(5.0);
              p.setMaskFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              // Provide some non-trivial stroke size to get blurred
              b.setStrokeWidth(5.0);
              b.setMaskFilter(filter);
            },
            cv_renderer, dl_renderer, adjuster, blur5Tolerance,
            "MaskFilter == Blur 5");
      }
      ASSERT_TRUE(filter->unique()) << "MaskFilter == Blur 5 Cleanup";
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Provide some non-trivial stroke size to get blurred
              p.setStrokeWidth(5.0);
              p.setMaskFilter(filter);
            },
            [=](DisplayListBuilder& b) {
              // Provide some non-trivial stroke size to get blurred
              b.setStrokeWidth(5.0);
              b.setMaskBlurFilter(kNormal_SkBlurStyle, 5.0);
            },
            cv_renderer, dl_renderer, adjuster, blur5Tolerance,
            "MaskFilter == Blur(Normal, 5.0)");
      }
      ASSERT_TRUE(filter->unique())
          << "MaskFilter == Blur(Normal, 5.0) Cleanup";
    }

    {
      SkPoint end_points[] = {
          SkPoint::Make(RenderBounds.fLeft, RenderBounds.fTop),
          SkPoint::Make(RenderBounds.fRight, RenderBounds.fBottom),
      };
      SkColor colors[] = {
          SK_ColorGREEN,
          SK_ColorYELLOW,
          SK_ColorBLUE,
      };
      float stops[] = {
          0.0,
          0.5,
          1.0,
      };
      sk_sp<SkShader> shader = SkGradientShader::MakeLinear(
          end_points, colors, stops, 3, SkTileMode::kMirror, 0, nullptr);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setShader(shader); },
                   [=](DisplayListBuilder& b) { b.setShader(shader); },
                   cv_renderer, dl_renderer, adjuster, tolerance,
                   "LinearGradient GYB");
      }
      ASSERT_TRUE(shader->unique()) << "LinearGradient GYB Cleanup";
    }
  }

  static void RenderWithStrokes(CvRenderer& cv_renderer,
                                DlRenderer& dl_renderer,
                                ToleranceAdjuster& adjuster,
                                const BoundsTolerance& tolerance_in) {
    // The test cases were generated with geometry that will try to fill
    // out the various miter limits used for testing, but they can be off
    // by a couple of pixels so we will relax bounds testing for strokes by
    // a couple of pixels.
    BoundsTolerance tolerance = tolerance_in.addBoundsPadding(2, 2);
    RenderWith(  //
        [=](SkCanvas*, SkPaint& p) { p.setStyle(SkPaint::kFill_Style); },
        [=](DisplayListBuilder& b) { b.setStyle(SkPaint::kFill_Style); },
        cv_renderer, dl_renderer, adjuster, tolerance, "Fill");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) { p.setStyle(SkPaint::kStroke_Style); },
        [=](DisplayListBuilder& b) { b.setStyle(SkPaint::kStroke_Style); },
        cv_renderer, dl_renderer, adjuster, tolerance, "Stroke + defaults");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kFill_Style);
          p.setStrokeWidth(10.0);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kFill_Style);
          b.setStrokeWidth(10.0);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Fill + unnecessary StrokeWidth 10");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(10.0);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(10.0);
        },
        cv_renderer, dl_renderer, adjuster, tolerance, "Stroke Width 10");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
        },
        cv_renderer, dl_renderer, adjuster, tolerance, "Stroke Width 5");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeCap(SkPaint::kButt_Cap);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeCap(SkPaint::kButt_Cap);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Butt Cap");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeCap(SkPaint::kRound_Cap);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeCap(SkPaint::kRound_Cap);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Round Cap");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeJoin(SkPaint::kBevel_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeJoin(SkPaint::kBevel_Join);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Bevel Join");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeJoin(SkPaint::kRound_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeJoin(SkPaint::kRound_Join);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Round Join");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeMiter(10.0);
          p.setStrokeJoin(SkPaint::kMiter_Join);
          // AA helps fill in the peaks of the really thin miters better
          // for bounds accuracy testing
          p.setAntiAlias(true);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeMiter(10.0);
          b.setStrokeJoin(SkPaint::kMiter_Join);
          // AA helps fill in the peaks of the really thin miters better
          // for bounds accuracy testing
          b.setAntiAlias(true);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Miter 10");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeMiter(0.0);
          p.setStrokeJoin(SkPaint::kMiter_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setStrokeMiter(0.0);
          b.setStrokeJoin(SkPaint::kMiter_Join);
        },
        cv_renderer, dl_renderer, adjuster, tolerance,
        "Stroke Width 5, Miter 0");

    {
      const SkScalar TestDashes1[] = {29.0, 2.0};
      const SkScalar TestDashes2[] = {17.0, 1.5};
      sk_sp<SkPathEffect> effect = SkDashPathEffect::Make(TestDashes1, 2, 0.0f);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Need stroke style to see dashing properly
              p.setStyle(SkPaint::kStroke_Style);
              // Provide some non-trivial stroke size to get dashed
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              // Need stroke style to see dashing properly
              b.setStyle(SkPaint::kStroke_Style);
              // Provide some non-trivial stroke size to get dashed
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, adjuster, tolerance,
            "PathEffect == Dash-29-2");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect == Dash-29-2 Cleanup";
      effect = SkDashPathEffect::Make(TestDashes2, 2, 0.0f);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              // Need stroke style to see dashing properly
              p.setStyle(SkPaint::kStroke_Style);
              // Provide some non-trivial stroke size to get dashed
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              // Need stroke style to see dashing properly
              b.setStyle(SkPaint::kStroke_Style);
              // Provide some non-trivial stroke size to get dashed
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, adjuster, tolerance,
            "PathEffect == Dash-17-1.5");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect == Dash-17-1.5 Cleanup";
    }
  }

  static void RenderWithTransforms(CvRenderer& cv_renderer,
                                   DlRenderer& dl_renderer,
                                   ToleranceAdjuster& adjuster,
                                   const BoundsTolerance& tolerance) {
    // If there is bounds padding for some conservative bounds overestimate
    // then that padding will be even more pronounced in rotated or skewed
    // coordinate systems so we scale the padding by about 5% to compensate.
    BoundsTolerance skewed_tolerance = tolerance.addScale(1.05, 1.05);
    RenderWith([=](SkCanvas* c, SkPaint&) { c->translate(5, 10); },  //
               [=](DisplayListBuilder& b) { b.translate(5, 10); },   //
               cv_renderer, dl_renderer, adjuster, tolerance,
               "Translate 5, 10");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->scale(1.05, 1.05); },  //
               [=](DisplayListBuilder& b) { b.scale(1.05, 1.05); },   //
               cv_renderer, dl_renderer, adjuster, tolerance,         //
               "Scale +5%");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->rotate(5); },  //
               [=](DisplayListBuilder& b) { b.rotate(5); },   //
               cv_renderer, dl_renderer, adjuster, skewed_tolerance,
               "Rotate 5 degrees");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->skew(0.05, 0.05); },   //
               [=](DisplayListBuilder& b) { b.skew(0.05, 0.05); },    //
               cv_renderer, dl_renderer, adjuster, skewed_tolerance,  //
               "Skew 5%");
    {
      SkMatrix tx = SkMatrix::MakeAll(1.10, 0.10, 5,   //
                                      0.05, 1.05, 10,  //
                                      0, 0, 1);
      RenderWith([=](SkCanvas* c, SkPaint&) { c->concat(tx); },  //
                 [=](DisplayListBuilder& b) {
                   b.transform2DAffine(tx[0], tx[1], tx[2],  //
                                       tx[3], tx[4], tx[5]);
                 },  //
                 cv_renderer, dl_renderer, adjuster, skewed_tolerance,
                 "Transform 2D Affine");
    }
    {
      SkM44 m44 = SkM44(1, 0, 0, RenderCenterX,  //
                        0, 1, 0, RenderCenterY,  //
                        0, 0, 1, 0,              //
                        0, 0, .001, 1);
      m44.preConcat(SkM44::Rotate({1, 0, 0}, M_PI / 60));  // 3 degrees around X
      m44.preConcat(SkM44::Rotate({0, 1, 0}, M_PI / 45));  // 4 degrees around Y
      m44.preTranslate(-RenderCenterX, -RenderCenterY);
      RenderWith([=](SkCanvas* c, SkPaint&) { c->concat(m44); },  //
                 [=](DisplayListBuilder& b) {
                   b.transformFullPerspective(
                       m44.rc(0, 0), m44.rc(0, 1), m44.rc(0, 2), m44.rc(0, 3),
                       m44.rc(1, 0), m44.rc(1, 1), m44.rc(1, 2), m44.rc(1, 3),
                       m44.rc(2, 0), m44.rc(2, 1), m44.rc(2, 2), m44.rc(2, 3),
                       m44.rc(3, 0), m44.rc(3, 1), m44.rc(3, 2), m44.rc(3, 3));
                 },  //
                 cv_renderer, dl_renderer, adjuster, skewed_tolerance,
                 "Transform Full Perspective");
    }
  }

  static void RenderWithClips(CvRenderer& cv_renderer,
                              DlRenderer& dl_renderer,
                              ToleranceAdjuster& diff_adjuster,
                              const BoundsTolerance& diff_tolerance) {
    SkRect r_clip = RenderBounds.makeInset(15.5, 15.5);
    // For kIntersect clips we can be really strict on tolerance
    ToleranceAdjuster& intersect_adjuster = DefaultAdjuster;
    BoundsTolerance& intersect_tolerance = DefaultTolerance;
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, SkClipOp::kIntersect, false);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "Hard ClipRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, SkClipOp::kIntersect, true);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "AntiAlias ClipRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, SkClipOp::kDifference, false);
        },
        cv_renderer, dl_renderer, diff_adjuster, diff_tolerance,
        "Hard ClipRect Diff, inset by 15.5");
    SkRRect rr_clip = SkRRect::MakeRectXY(r_clip, 1.8, 2.7);
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, SkClipOp::kIntersect, false);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "Hard ClipRRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, SkClipOp::kIntersect, true);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "AntiAlias ClipRRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, SkClipOp::kDifference, false);
        },
        cv_renderer, dl_renderer, diff_adjuster, diff_tolerance,
        "Hard ClipRRect Diff, inset by 15.5");
    SkPath path_clip = SkPath();
    path_clip.setFillType(SkPathFillType::kEvenOdd);
    path_clip.addRect(r_clip);
    path_clip.addCircle(RenderCenterX, RenderCenterY, 1.0);
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, SkClipOp::kIntersect, false);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "Hard ClipPath inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, SkClipOp::kIntersect, true);
        },
        cv_renderer, dl_renderer, intersect_adjuster, intersect_tolerance,
        "AntiAlias ClipPath inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, SkClipOp::kDifference, false);
        },
        cv_renderer, dl_renderer, diff_adjuster, diff_tolerance,
        "Hard ClipPath Diff, inset by 15.5");
  }

  static sk_sp<SkPicture> getSkPicture(CvRenderer& cv_setup,
                                       CvRenderer& cv_render) {
    SkPictureRecorder recorder;
    SkRTreeFactory rtree_factory;
    SkCanvas* cv = recorder.beginRecording(TestBounds, &rtree_factory);
    SkPaint p;
    cv_setup(cv, p);
    cv_render(cv, p);
    return recorder.finishRecordingAsPicture();
  }

  static void RenderWith(CvRenderer& cv_setup,
                         DlRenderer& dl_setup,
                         CvRenderer& cv_render,
                         DlRenderer& dl_render,
                         ToleranceAdjuster& adjuster,
                         const BoundsTolerance& tolerance_in,
                         const std::string info,
                         const SkColor* bg = nullptr) {
    // surface1 is direct rendering via SkCanvas to SkSurface
    // DisplayList mechanisms are not involved in this operation
    sk_sp<SkSurface> ref_surface = makeSurface(bg);
    SkPaint paint1;
    cv_setup(ref_surface->getCanvas(), paint1);
    const BoundsTolerance tolerance = adjuster(
        tolerance_in, paint1, ref_surface->getCanvas()->getTotalMatrix());
    cv_render(ref_surface->getCanvas(), paint1);
    sk_sp<SkPicture> ref_picture = getSkPicture(cv_setup, cv_render);
    SkRect ref_bounds = ref_picture->cullRect();
    SkPixmap ref_pixels;
    ASSERT_TRUE(ref_surface->peekPixels(&ref_pixels)) << info;
    ASSERT_EQ(ref_pixels.width(), TestWidth) << info;
    ASSERT_EQ(ref_pixels.height(), TestHeight) << info;
    ASSERT_EQ(ref_pixels.info().bytesPerPixel(), 4) << info;
    checkPixels(&ref_pixels, ref_bounds, info + " (Skia reference)", bg);

    {
      // This sequence plays the provided equivalently constructed
      // DisplayList onto the SkCanvas of the surface
      // DisplayList => direct rendering
      sk_sp<SkSurface> test_surface = makeSurface(bg);
      DisplayListBuilder builder(TestBounds);
      dl_setup(builder);
      dl_render(builder);
      sk_sp<DisplayList> display_list = builder.Build();
      SkRect dl_bounds = display_list->bounds();
      if (!ref_bounds.roundOut().contains(dl_bounds)) {
        FML_LOG(ERROR) << "For " << info;
        FML_LOG(ERROR) << "ref: "  //
                       << ref_bounds.fLeft << ", " << ref_bounds.fTop << " => "
                       << ref_bounds.fRight << ", " << ref_bounds.fBottom;
        FML_LOG(ERROR) << "dl: "  //
                       << dl_bounds.fLeft << ", " << dl_bounds.fTop << " => "
                       << dl_bounds.fRight << ", " << dl_bounds.fBottom;
        if (!dl_bounds.contains(ref_bounds)) {
          FML_LOG(ERROR) << "DisplayList bounds are too small!";
        }
        if (!ref_bounds.roundOut().contains(dl_bounds.roundOut())) {
          FML_LOG(ERROR) << "###### DisplayList bounds larger than reference!";
        }
      }

      // This sometimes triggers, but when it triggers and I examine
      // the ref_bounds, they are always unnecessarily large and
      // since the pixel OOB tests in the compare method do not
      // trigger, we will trust the DL bounds.
      // EXPECT_TRUE(dl_bounds.contains(ref_bounds)) << info;

      EXPECT_EQ(display_list->op_count(), ref_picture->approximateOpCount())
          << info;

      display_list->RenderTo(test_surface->getCanvas());
      compareToReference(test_surface.get(), &ref_pixels,
                         info + " (DisplayList built directly -> surface)",
                         &dl_bounds, &tolerance, bg);
    }

    // This test cannot work if the rendering is using shadows until
    // we can access the Skia ShadowRec via public headers.
    if (!TestingDrawShadows) {
      // This sequence renders SkCanvas calls to a DisplayList and then
      // plays them back on SkCanvas to SkSurface
      // SkCanvas calls => DisplayList => rendering
      sk_sp<SkSurface> test_surface = makeSurface(bg);
      DisplayListCanvasRecorder dl_recorder(TestBounds);
      SkPaint test_paint;
      cv_setup(&dl_recorder, test_paint);
      cv_render(&dl_recorder, test_paint);
      dl_recorder.builder()->Build()->RenderTo(test_surface->getCanvas());
      compareToReference(test_surface.get(), &ref_pixels,
                         info + " (Skia calls -> DisplayList -> surface)",
                         nullptr, nullptr, nullptr);
    }

    {
      // This sequence renders the SkCanvas calls to an SkPictureRecorder and
      // renders the DisplayList calls to a DisplayListBuilder and then
      // renders both back under a transform (scale(2x)) to see if their
      // rendering is affected differently by a change of matrix between
      // recording time and rendering time.
      const int TestWidth2 = TestWidth * 2;
      const int TestHeight2 = TestHeight * 2;
      const SkScalar TestScale = 2.0;

      SkPictureRecorder sk_recorder;
      SkCanvas* ref_canvas = sk_recorder.beginRecording(TestBounds);
      SkPaint ref_paint;
      cv_setup(ref_canvas, ref_paint);
      cv_render(ref_canvas, ref_paint);
      sk_sp<SkPicture> ref_picture = sk_recorder.finishRecordingAsPicture();
      sk_sp<SkSurface> ref_surface2 = makeSurface(bg, TestWidth2, TestHeight2);
      SkCanvas* ref_canvas2 = ref_surface2->getCanvas();
      ref_canvas2->scale(TestScale, TestScale);
      ref_picture->playback(ref_canvas2);
      SkPixmap ref_pixels2;
      ASSERT_TRUE(ref_surface2->peekPixels(&ref_pixels2)) << info;
      ASSERT_EQ(ref_pixels2.width(), TestWidth2) << info;
      ASSERT_EQ(ref_pixels2.height(), TestHeight2) << info;
      ASSERT_EQ(ref_pixels2.info().bytesPerPixel(), 4) << info;

      DisplayListBuilder builder(TestBounds);
      dl_setup(builder);
      dl_render(builder);
      sk_sp<DisplayList> display_list = builder.Build();
      sk_sp<SkSurface> test_surface = makeSurface(bg, TestWidth2, TestHeight2);
      SkCanvas* test_canvas = test_surface->getCanvas();
      test_canvas->scale(TestScale, TestScale);
      display_list->RenderTo(test_canvas);
      compareToReference(test_surface.get(), &ref_pixels2,
                         info + " (Both rendered scaled 2x)", nullptr, nullptr,
                         nullptr, TestWidth2, TestHeight2, false);
    }
  }

  static void checkPixels(SkPixmap* ref_pixels,
                          SkRect ref_bounds,
                          const std::string info,
                          const SkColor* bg) {
    SkPMColor untouched = (bg) ? SkPreMultiplyColor(*bg) : 0;
    int pixels_touched = 0;
    int pixels_oob = 0;
    SkIRect i_bounds = ref_bounds.roundOut();
    for (int y = 0; y < TestHeight; y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
      for (int x = 0; x < TestWidth; x++) {
        if (ref_row[x] != untouched) {
          pixels_touched++;
          if (!i_bounds.contains(x, y)) {
            pixels_oob++;
          }
        }
      }
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_GT(pixels_touched, 0) << info;
  }

  static void compareToReference(SkSurface* test_surface,
                                 SkPixmap* reference,
                                 const std::string info,
                                 SkRect* bounds,
                                 const BoundsTolerance* tolerance,
                                 const SkColor* bg,
                                 int width = TestWidth,
                                 int height = TestHeight,
                                 bool printMismatches = false) {
    SkPMColor untouched = (bg) ? SkPreMultiplyColor(*bg) : 0;
    SkPixmap test_pixels;
    ASSERT_TRUE(test_surface->peekPixels(&test_pixels)) << info;
    ASSERT_EQ(test_pixels.width(), width) << info;
    ASSERT_EQ(test_pixels.height(), height) << info;
    ASSERT_EQ(test_pixels.info().bytesPerPixel(), 4) << info;
    SkIRect i_bounds =
        bounds ? bounds->roundOut() : SkIRect::MakeWH(width, height);

    int pixels_different = 0;
    int pixels_oob = 0;
    int minX = width;
    int minY = height;
    int maxX = 0;
    int maxY = 0;
    for (int y = 0; y < height; y++) {
      const uint32_t* ref_row = reference->addr32(0, y);
      const uint32_t* test_row = test_pixels.addr32(0, y);
      for (int x = 0; x < width; x++) {
        if (bounds && test_row[x] != untouched) {
          if (minX > x) {
            minX = x;
          }
          if (minY > y) {
            minY = y;
          }
          if (maxX <= x) {
            maxX = x + 1;
          }
          if (maxY <= y) {
            maxY = y + 1;
          }
          if (!i_bounds.contains(x, y)) {
            pixels_oob++;
          }
        }
        if (test_row[x] != ref_row[x]) {
          if (printMismatches) {
            FML_LOG(ERROR) << "pix[" << x << ", " << y
                           << "] mismatch: " << std::hex << test_row[x]
                           << "(test) != (ref)" << ref_row[x] << std::dec;
          }
          pixels_different++;
        }
      }
    }
    if (pixels_oob > 0) {
      FML_LOG(ERROR) << "pix bounds["  //
                     << minX << ", " << minY << " => " << maxX << ", " << maxY
                     << "]";
      FML_LOG(ERROR) << "dl_bounds["                               //
                     << bounds->fLeft << ", " << bounds->fTop      //
                     << " => "                                     //
                     << bounds->fRight << ", " << bounds->fBottom  //
                     << "]";
    } else if (bounds) {
      showBoundsOverflow(info, i_bounds, tolerance, minX, minY, maxX, maxY);
    }
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_EQ(pixels_different, 0) << info;
  }

  static void showBoundsOverflow(std::string info,
                                 SkIRect& bounds,
                                 const BoundsTolerance* tolerance,
                                 int pixLeft,
                                 int pixTop,
                                 int pixRight,
                                 int pixBottom) {
    int pad_left = std::max(0, pixLeft - bounds.fLeft);
    int pad_top = std::max(0, pixTop - bounds.fTop);
    int pad_right = std::max(0, bounds.fRight - pixRight);
    int pad_bottom = std::max(0, bounds.fBottom - pixBottom);
    int pixWidth = pixRight - pixLeft;
    int pixHeight = pixBottom - pixTop;
    SkISize pixSize = SkISize::Make(pixWidth, pixHeight);
    int worst_pad_x = std::max(pad_left, pad_right);
    int worst_pad_y = std::max(pad_top, pad_bottom);
    if (tolerance->overflows(pixSize, worst_pad_x, worst_pad_y)) {
      FML_LOG(ERROR) << "Overflow for " << info;
      FML_LOG(ERROR) << "pix bounds["                        //
                     << pixLeft << ", " << pixTop << " => "  //
                     << pixRight << ", " << pixBottom        //
                     << "]";
      FML_LOG(ERROR) << "dl_bounds["                             //
                     << bounds.fLeft << ", " << bounds.fTop      //
                     << " => "                                   //
                     << bounds.fRight << ", " << bounds.fBottom  //
                     << "]";
      FML_LOG(ERROR) << "Bounds overflowed by up to "             //
                     << worst_pad_x << ", " << worst_pad_y        //
                     << " (" << (worst_pad_x * 100.0 / pixWidth)  //
                     << "%, " << (worst_pad_y * 100.0 / pixHeight) << "%)";
      int pix_area = pixSize.area();
      int dl_area = bounds.width() * bounds.height();
      FML_LOG(ERROR) << "Total overflow area: " << (dl_area - pix_area)  //
                     << " (+" << (dl_area * 100.0 / pix_area - 100.0) << "%)";
      FML_LOG(ERROR);
    }
  }

  static sk_sp<SkSurface> makeSurface(const SkColor* bg,
                                      int width = TestWidth,
                                      int height = TestHeight) {
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(width, height);
    if (bg) {
      surface->getCanvas()->drawColor(*bg);
    }
    return surface;
  }

  static const sk_sp<SkImage> testImage;
  static const sk_sp<SkImage> makeTestImage() {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRasterN32Premul(RenderWidth, RenderHeight);
    SkCanvas* canvas = surface->getCanvas();
    SkPaint p0, p1;
    p0.setStyle(SkPaint::kFill_Style);
    p0.setColor(SK_ColorGREEN);
    p1.setStyle(SkPaint::kFill_Style);
    p1.setColor(SK_ColorBLUE);
    // Some pixels need some transparency for DstIn testing
    p1.setAlpha(128);
    int cbdim = 5;
    for (int y = 0; y < RenderHeight; y += cbdim) {
      for (int x = 0; x < RenderWidth; x += cbdim) {
        SkPaint& cellp = ((x + y) & 1) == 0 ? p0 : p1;
        canvas->drawRect(SkRect::MakeXYWH(x, y, cbdim, cbdim), cellp);
      }
    }
    return surface->makeImageSnapshot();
  }

  static sk_sp<SkTextBlob> MakeTextBlob(std::string string,
                                        SkScalar font_height) {
    SkFont font(SkTypeface::MakeFromName("ahem", SkFontStyle::Normal()),
                font_height);
    return SkTextBlob::MakeFromText(string.c_str(), string.size(), font,
                                    SkTextEncoding::kUTF8);
  }
};

bool CanvasCompareTester::TestingDrawShadows = false;
bool CanvasCompareTester::TestingDrawVertices = false;
bool CanvasCompareTester::TestingDrawAtlas = false;
BoundsTolerance CanvasCompareTester::DefaultTolerance =
    BoundsTolerance().addAbsolutePadding(1, 1);

const sk_sp<SkImage> CanvasCompareTester::testImage =
    CanvasCompareTester::makeTestImage();

TEST(DisplayListCanvas, DrawPaint) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPaint(paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPaint();
      });
}

TEST(DisplayListCanvas, DrawColor) {
  CanvasCompareTester::RenderNoAttributes(     //
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawColor(SK_ColorMAGENTA);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawColor(SK_ColorMAGENTA, SkBlendMode::kSrcOver);
      });
}

BoundsTolerance lineTolerance(const BoundsTolerance& tolerance,
                              const SkPaint& paint,
                              const SkMatrix& matrix,
                              bool is_horizontal,
                              bool is_vertical,
                              bool ignores_butt_cap) {
  SkScalar adjust = 0.0;
  SkScalar half_width = paint.getStrokeWidth() * 0.5f;
  if (tolerance.discrete_offset() > 0) {
    // When a discrete path effect is added, the bounds calculations must allow
    // for miters in any direction, but a horizontal line will not have
    // miters in the horizontal direction, similarly for vertical
    // lines, and diagonal lines will have miters off at a "45 degree" angle
    // that don't expand the bounds much at all.
    // Also, the discrete offset will not move any points parallel with
    // the line, so provide tolerance for both miters and offset.
    adjust = half_width * paint.getStrokeMiter() + tolerance.discrete_offset();
  }
  if (paint.getStrokeCap() == SkPaint::kButt_Cap && !ignores_butt_cap) {
    adjust = std::max(adjust, half_width);
  }
  if (adjust == 0) {
    return CanvasCompareTester::DefaultAdjuster(tolerance, paint, matrix);
  }
  SkScalar hTolerance;
  SkScalar vTolerance;
  if (is_horizontal) {
    FML_DCHECK(!is_vertical);
    hTolerance = adjust;
    vTolerance = 0;
  } else if (is_vertical) {
    hTolerance = 0;
    vTolerance = adjust;
  } else {
    // The perpendicular miters just do not impact the bounds of
    // diagonal lines at all as they are aimed in the wrong direction
    // to matter. So allow tolerance in both axes.
    hTolerance = vTolerance = adjust;
  }
  BoundsTolerance new_tolerance =
      tolerance.addBoundsPadding(hTolerance, vTolerance);
  return CanvasCompareTester::DefaultAdjuster(new_tolerance, paint, matrix);
}

// For drawing horizontal lines
BoundsTolerance hLineTolerance(const BoundsTolerance& tolerance,
                               const SkPaint& paint,
                               const SkMatrix& matrix) {
  return lineTolerance(tolerance, paint, matrix, true, false, false);
}

// For drawing vertical lines
BoundsTolerance vLineTolerance(const BoundsTolerance& tolerance,
                               const SkPaint& paint,
                               const SkMatrix& matrix) {
  return lineTolerance(tolerance, paint, matrix, false, true, false);
}

// For drawing diagonal lines
BoundsTolerance dLineTolerance(const BoundsTolerance& tolerance,
                               const SkPaint& paint,
                               const SkMatrix& matrix) {
  return lineTolerance(tolerance, paint, matrix, false, false, false);
}

// For drawing individual points (drawPoints(Point_Mode))
BoundsTolerance pointsTolerance(const BoundsTolerance& tolerance,
                                const SkPaint& paint,
                                const SkMatrix& matrix) {
  return lineTolerance(tolerance, paint, matrix, false, false, true);
}

TEST(DisplayListCanvas, DrawDiagonalLines) {
  SkPoint p1 = SkPoint::Make(RenderLeft, RenderTop);
  SkPoint p2 = SkPoint::Make(RenderRight, RenderBottom);
  SkPoint p3 = SkPoint::Make(RenderLeft, RenderBottom);
  SkPoint p4 = SkPoint::Make(RenderRight, RenderTop);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawLine(p1, p2, p);
        canvas->drawLine(p3, p4, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawLine(p1, p2);
        builder.drawLine(p3, p4);
      },
      dLineTolerance);
}

TEST(DisplayListCanvas, DrawHorizontalLine) {
  SkPoint p1 = SkPoint::Make(RenderLeft, RenderCenterY);
  SkPoint p2 = SkPoint::Make(RenderRight, RenderCenterY);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawLine(p1, p2, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawLine(p1, p2);
      },
      hLineTolerance);
}

TEST(DisplayListCanvas, DrawVerticalLine) {
  SkPoint p1 = SkPoint::Make(RenderCenterX, RenderTop);
  SkPoint p2 = SkPoint::Make(RenderCenterY, RenderBottom);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawLine(p1, p2, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawLine(p1, p2);
      },
      vLineTolerance);
}

TEST(DisplayListCanvas, DrawRect) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawRect(RenderBounds, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawRect(RenderBounds);
      });
}

TEST(DisplayListCanvas, DrawOval) {
  SkRect rect = RenderBounds.makeInset(0, 10);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawOval(rect, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawOval(rect);
      });
}

TEST(DisplayListCanvas, DrawCircle) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawCircle(TestCenter, RenderRadius, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawCircle(TestCenter, RenderRadius);
      });
}

TEST(DisplayListCanvas, DrawRRect) {
  SkRRect rrect =
      SkRRect::MakeRectXY(RenderBounds, RenderCornerRadius, RenderCornerRadius);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawRRect(rrect, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawRRect(rrect);
      });
}

TEST(DisplayListCanvas, DrawDRRect) {
  SkRRect outer =
      SkRRect::MakeRectXY(RenderBounds, RenderCornerRadius, RenderCornerRadius);
  SkRect innerBounds = RenderBounds.makeInset(30.0, 30.0);
  SkRRect inner =
      SkRRect::MakeRectXY(innerBounds, RenderCornerRadius, RenderCornerRadius);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawDRRect(outer, inner, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawDRRect(outer, inner);
      });
}

TEST(DisplayListCanvas, DrawPath) {
  SkPath path;
  path.addRect(RenderBounds);
  path.moveTo(VerticalMiterDiamondPoints[0]);
  for (int i = 1; i < VerticalMiterDiamondPointCount; i++) {
    path.lineTo(VerticalMiterDiamondPoints[i]);
  }
  path.close();
  path.moveTo(HorizontalMiterDiamondPoints[0]);
  for (int i = 1; i < HorizontalMiterDiamondPointCount; i++) {
    path.lineTo(HorizontalMiterDiamondPoints[i]);
  }
  path.close();
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPath(path, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPath(path);
      });
}

TEST(DisplayListCanvas, DrawArc) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawArc(RenderBounds, 60, 330, false, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawArc(RenderBounds, 60, 330, false);
      });
}

TEST(DisplayListCanvas, DrawArcCenter) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawArc(RenderBounds, 60, 330, true, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawArc(RenderBounds, 60, 330, true);
      });
}

TEST(DisplayListCanvas, DrawPointsAsPoints) {
  // The +/- 16 points are designed to fall just inside the clips
  // that are tested against so we avoid lots of undrawn pixels
  // in the accumulated bounds.
  const SkScalar x0 = RenderLeft;
  const SkScalar x1 = RenderLeft + 16;
  const SkScalar x2 = (RenderLeft + RenderCenterX) * 0.5;
  const SkScalar x3 = RenderCenterX;
  const SkScalar x4 = (RenderRight + RenderCenterX) * 0.5;
  const SkScalar x5 = RenderRight - 16;
  const SkScalar x6 = RenderRight;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = RenderTop + 16;
  const SkScalar y2 = (RenderTop + RenderCenterY) * 0.5;
  const SkScalar y3 = RenderCenterY;
  const SkScalar y4 = (RenderBottom + RenderCenterY) * 0.5;
  const SkScalar y5 = RenderBottom - 16;
  const SkScalar y6 = RenderBottom;

  // clang-format off
  const SkPoint points[] = {
      {x0, y0}, {x1, y0}, {x2, y0}, {x3, y0}, {x4, y0}, {x5, y0}, {x6, y0},
      {x0, y1}, {x1, y1}, {x2, y1}, {x3, y1}, {x4, y1}, {x5, y1}, {x6, y1},
      {x0, y2}, {x1, y2}, {x2, y2}, {x3, y2}, {x4, y2}, {x5, y2}, {x6, y2},
      {x0, y3}, {x1, y3}, {x2, y3}, {x3, y3}, {x4, y3}, {x5, y3}, {x6, y3},
      {x0, y4}, {x1, y4}, {x2, y4}, {x3, y4}, {x4, y4}, {x5, y4}, {x6, y4},
      {x0, y5}, {x1, y5}, {x2, y5}, {x3, y5}, {x4, y5}, {x5, y5}, {x6, y5},
      {x0, y6}, {x1, y6}, {x2, y6}, {x3, y6}, {x4, y6}, {x5, y6}, {x6, y6},
  };
  // clang-format on
  const int count = sizeof(points) / sizeof(points[0]);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kPoints_PointMode, count, points, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kPoints_PointMode, count, points);
      },
      pointsTolerance);
}

TEST(DisplayListCanvas, DrawPointsAsLines) {
  const SkScalar x0 = RenderLeft + 1;
  const SkScalar x1 = RenderLeft + 16;
  const SkScalar x2 = RenderRight - 16;
  const SkScalar x3 = RenderRight - 1;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = RenderTop + 16;
  const SkScalar y2 = RenderBottom - 16;
  const SkScalar y3 = RenderBottom;

  // clang-format off
  const SkPoint points[] = {
      // Outer box
      {x0, y0}, {x3, y0},
      {x3, y0}, {x3, y3},
      {x3, y3}, {x0, y3},
      {x0, y3}, {x0, y0},

      // Diagonals
      {x0, y0}, {x3, y3}, {x3, y0}, {x0, y3},

      // Inner box
      {x1, y1}, {x2, y1},
      {x2, y1}, {x2, y2},
      {x2, y2}, {x1, y2},
      {x1, y2}, {x1, y1},
  };
  // clang-format on

  const int count = sizeof(points) / sizeof(points[0]);
  ASSERT_TRUE((count & 1) == 0);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kLines_PointMode, count, points, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kLines_PointMode, count, points);
      });
}

TEST(DisplayListCanvas, DrawPointsAsPolygon) {
  const SkPoint points1[] = {
      // RenderBounds box with a diagonal
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderBottom),
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const int count1 = sizeof(points1) / sizeof(points1[0]);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        // Skia requires kStroke style on horizontal and vertical
        // lines to get the bounds correct.
        // See https://bugs.chromium.org/p/skia/issues/detail?id=12446
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kPolygon_PointMode, count1, points1, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kPolygon_PointMode, count1, points1);
      });
}

TEST(DisplayListCanvas, DrawVerticesWithColors) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const SkPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderCenterY),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkColor colors[6] = {
      SK_ColorRED,  SK_ColorBLUE,   SK_ColorGREEN,
      SK_ColorCYAN, SK_ColorYELLOW, SK_ColorMAGENTA,
  };
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 6, pts, nullptr, colors);
  CanvasCompareTester::RenderVertices(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawVertices(vertices.get(), SkBlendMode::kSrcOver, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawVertices(vertices, SkBlendMode::kSrcOver);
      });
  ASSERT_TRUE(vertices->unique());
}

TEST(DisplayListCanvas, DrawVerticesWithImage) {
  // Cover as many sides of the box with only 6 vertices:
  // +----------+
  // |xxxxxxxxxx|
  // |    xxxxxx|
  // |       xxx|
  // |xxx       |
  // |xxxxxx    |
  // |xxxxxxxxxx|
  // +----------|
  const SkPoint pts[6] = {
      // Upper-Right corner, full top, half right coverage
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderRight, RenderCenterY),
      // Lower-Left corner, full bottom, half left coverage
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderCenterY),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkPoint tex[6] = {
      SkPoint::Make(RenderWidth / 2.0, 0),
      SkPoint::Make(0, RenderHeight),
      SkPoint::Make(RenderWidth, RenderHeight),
      SkPoint::Make(RenderWidth / 2, RenderHeight),
      SkPoint::Make(0, 0),
      SkPoint::Make(RenderWidth, 0),
  };
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 6, pts, tex, nullptr);
  const sk_sp<SkShader> shader = CanvasCompareTester::testImage->makeShader(
      SkTileMode::kRepeat, SkTileMode::kRepeat, SkSamplingOptions());
  CanvasCompareTester::RenderVertices(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        paint.setShader(shader);
        canvas->drawVertices(vertices.get(), SkBlendMode::kSrcOver, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.setShader(shader);
        builder.drawVertices(vertices, SkBlendMode::kSrcOver);
      });
  ASSERT_TRUE(vertices->unique());
  ASSERT_TRUE(shader->unique());
}

TEST(DisplayListCanvas, DrawImageNearest) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImage(CanvasCompareTester::testImage, RenderLeft, RenderTop,
                          DisplayList::NearestSampling, &paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImage(CanvasCompareTester::testImage,
                          SkPoint::Make(RenderLeft, RenderTop),
                          DisplayList::NearestSampling, true);
      });
}

TEST(DisplayListCanvas, DrawImageNearestNoPaint) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImage(CanvasCompareTester::testImage, RenderLeft, RenderTop,
                          DisplayList::NearestSampling, nullptr);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImage(CanvasCompareTester::testImage,
                          SkPoint::Make(RenderLeft, RenderTop),
                          DisplayList::NearestSampling, false);
      });
}

TEST(DisplayListCanvas, DrawImageLinear) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImage(CanvasCompareTester::testImage, RenderLeft, RenderTop,
                          DisplayList::LinearSampling, &paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImage(CanvasCompareTester::testImage,
                          SkPoint::Make(RenderLeft, RenderTop),
                          DisplayList::LinearSampling, true);
      });
}

TEST(DisplayListCanvas, DrawImageRectNearest) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::NearestSampling, &paint,
                              SkCanvas::kFast_SrcRectConstraint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::NearestSampling, true);
      });
}

TEST(DisplayListCanvas, DrawImageRectNearestNoPaint) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::NearestSampling, nullptr,
                              SkCanvas::kFast_SrcRectConstraint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::NearestSampling, false);
      });
}

TEST(DisplayListCanvas, DrawImageRectLinear) {
  SkRect src = SkRect::MakeIWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::LinearSampling, &paint,
                              SkCanvas::kFast_SrcRectConstraint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageRect(CanvasCompareTester::testImage, src, dst,
                              DisplayList::LinearSampling, true);
      });
}

TEST(DisplayListCanvas, DrawImageNineNearest) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageNine(CanvasCompareTester::testImage.get(), src, dst,
                              SkFilterMode::kNearest, &paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageNine(CanvasCompareTester::testImage, src, dst,
                              SkFilterMode::kNearest, true);
      });
}

TEST(DisplayListCanvas, DrawImageNineNearestNoPaint) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageNine(CanvasCompareTester::testImage.get(), src, dst,
                              SkFilterMode::kNearest, nullptr);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageNine(CanvasCompareTester::testImage, src, dst,
                              SkFilterMode::kNearest, false);
      });
}

TEST(DisplayListCanvas, DrawImageNineLinear) {
  SkIRect src = SkIRect::MakeWH(RenderWidth, RenderHeight).makeInset(5, 5);
  SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageNine(CanvasCompareTester::testImage.get(), src, dst,
                              SkFilterMode::kLinear, &paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawImageNine(CanvasCompareTester::testImage, src, dst,
                              SkFilterMode::kLinear, true);
      });
}

TEST(DisplayListCanvas, DrawImageLatticeNearest) {
  const SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  const int divX[] = {
      (RenderLeft + RenderCenterX) / 2,
      RenderCenterX,
      (RenderRight + RenderCenterX) / 2,
  };
  const int divY[] = {
      (RenderTop + RenderCenterY) / 2,
      RenderCenterY,
      (RenderBottom + RenderCenterY) / 2,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageLattice(CanvasCompareTester::testImage.get(), lattice,
                                 dst, SkFilterMode::kNearest, &paint);
      },
      [=](DisplayListBuilder& builder) {                                   //
        builder.drawImageLattice(CanvasCompareTester::testImage, lattice,  //
                                 dst, SkFilterMode::kNearest, true);
      });
}

TEST(DisplayListCanvas, DrawImageLatticeNearestNoPaint) {
  const SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  const int divX[] = {
      (RenderLeft + RenderCenterX) / 2,
      RenderCenterX,
      (RenderRight + RenderCenterX) / 2,
  };
  const int divY[] = {
      (RenderTop + RenderCenterY) / 2,
      RenderCenterY,
      (RenderBottom + RenderCenterY) / 2,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageLattice(CanvasCompareTester::testImage.get(), lattice,
                                 dst, SkFilterMode::kNearest, nullptr);
      },
      [=](DisplayListBuilder& builder) {                                   //
        builder.drawImageLattice(CanvasCompareTester::testImage, lattice,  //
                                 dst, SkFilterMode::kNearest, false);
      });
}

TEST(DisplayListCanvas, DrawImageLatticeLinear) {
  const SkRect dst = RenderBounds.makeInset(15.5, 10.5);
  const int divX[] = {
      (RenderLeft + RenderCenterX) / 2,
      RenderCenterX,
      (RenderRight + RenderCenterX) / 2,
  };
  const int divY[] = {
      (RenderTop + RenderCenterY) / 2,
      RenderCenterY,
      (RenderBottom + RenderCenterY) / 2,
  };
  SkCanvas::Lattice lattice = {
      divX, divY, nullptr, 3, 3, nullptr, nullptr,
  };
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawImageLattice(CanvasCompareTester::testImage.get(), lattice,
                                 dst, SkFilterMode::kLinear, &paint);
      },
      [=](DisplayListBuilder& builder) {                                   //
        builder.drawImageLattice(CanvasCompareTester::testImage, lattice,  //
                                 dst, SkFilterMode::kLinear, true);
      });
}

TEST(DisplayListCanvas, DrawAtlasNearest) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAtlas(
      [=](SkCanvas* canvas, SkPaint& paint) {
        canvas->drawAtlas(image.get(), xform, tex, colors, 4,
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr, &paint);
      },
      [=](DisplayListBuilder& builder) {
        builder.drawAtlas(image, xform, tex, colors, 4,  //
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr, true);
      });
}

TEST(DisplayListCanvas, DrawAtlasNearestNoPaint) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAtlas(
      [=](SkCanvas* canvas, SkPaint& paint) {
        canvas->drawAtlas(image.get(), xform, tex, colors, 4,
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr, nullptr);
      },
      [=](DisplayListBuilder& builder) {
        builder.drawAtlas(image, xform, tex, colors, 4,  //
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr, false);
      });
}

TEST(DisplayListCanvas, DrawAtlasLinear) {
  const SkRSXform xform[] = {
      // clang-format off
      { 1.2f,  0.0f, RenderLeft,  RenderTop},
      { 0.0f,  1.2f, RenderRight, RenderTop},
      {-1.2f,  0.0f, RenderRight, RenderBottom},
      { 0.0f, -1.2f, RenderLeft,  RenderBottom},
      // clang-format on
  };
  const SkRect tex[] = {
      // clang-format off
      {0,               0,                RenderHalfWidth, RenderHalfHeight},
      {RenderHalfWidth, 0,                RenderWidth,     RenderHalfHeight},
      {RenderHalfWidth, RenderHalfHeight, RenderWidth,     RenderHeight},
      {0,               RenderHalfHeight, RenderHalfWidth, RenderHeight},
      // clang-format on
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
      SK_ColorYELLOW,
      SK_ColorMAGENTA,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAtlas(
      [=](SkCanvas* canvas, SkPaint& paint) {
        canvas->drawAtlas(image.get(), xform, tex, colors, 2,  //
                          SkBlendMode::kSrcOver, DisplayList::LinearSampling,
                          nullptr, &paint);
      },
      [=](DisplayListBuilder& builder) {
        builder.drawAtlas(image, xform, tex, colors, 2,  //
                          SkBlendMode::kSrcOver, DisplayList::LinearSampling,
                          nullptr, true);
      });
}

sk_sp<SkPicture> makeTestPicture() {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(RenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  SkScalar x_coords[] = {
      RenderLeft,
      RenderCenterX,
      RenderRight,
  };
  SkScalar y_coords[] = {
      RenderTop,
      RenderCenterY,
      RenderBottom,
  };
  SkColor colors[][2] = {
      {
          SK_ColorRED,
          SK_ColorBLUE,
      },
      {
          SK_ColorGREEN,
          SK_ColorYELLOW,
      },
  };
  for (int j = 0; j < 2; j++) {
    for (int i = 0; i < 2; i++) {
      SkRect rect = {
          x_coords[i],
          y_coords[j],
          x_coords[i + 1],
          y_coords[j + 1],
      };
      p.setColor(colors[i][j]);
      cv->drawOval(rect, p);
    }
  }
  return recorder.finishRecordingAsPicture();
}

TEST(DisplayListCanvas, DrawPicture) {
  sk_sp<SkPicture> picture = makeTestPicture();
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPicture(picture, nullptr, nullptr);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPicture(picture, nullptr, false);
      });
}

TEST(DisplayListCanvas, DrawPictureWithMatrix) {
  sk_sp<SkPicture> picture = makeTestPicture();
  SkMatrix matrix = SkMatrix::Scale(0.95, 0.95);
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPicture(picture, &matrix, nullptr);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPicture(picture, &matrix, false);
      });
}

TEST(DisplayListCanvas, DrawPictureWithPaint) {
  sk_sp<SkPicture> picture = makeTestPicture();
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPicture(picture, nullptr, &paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPicture(picture, nullptr, true);
      });
}

TEST(DisplayListCanvas, DrawDisplayList) {
  DisplayListBuilder builder;
  builder.setStyle(SkPaint::kFill_Style);
  builder.setColor(SK_ColorBLUE);
  builder.drawOval(RenderBounds);
  sk_sp<DisplayList> display_list = builder.Build();
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        display_list->RenderTo(canvas);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawDisplayList(display_list);
      });
}

TEST(DisplayListCanvas, DrawTextBlob) {
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // performance overlay can use Fuchsia's font manager instead of the empty
  // default.
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Rendering comparisons require a valid default font manager";
#endif  // OS_FUCHSIA
  sk_sp<SkTextBlob> blob =
      CanvasCompareTester::MakeTextBlob("Testing", RenderHeight * 0.33f);
  SkScalar RenderY1_3 = RenderTop + RenderHeight * 0.33;
  SkScalar RenderY2_3 = RenderTop + RenderHeight * 0.66;
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawTextBlob(blob, RenderLeft, RenderY1_3, paint);
        canvas->drawTextBlob(blob, RenderLeft, RenderY2_3, paint);
        canvas->drawTextBlob(blob, RenderLeft, RenderBottom, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawTextBlob(blob, RenderLeft, RenderY1_3);
        builder.drawTextBlob(blob, RenderLeft, RenderY2_3);
        builder.drawTextBlob(blob, RenderLeft, RenderBottom);
      },
      CanvasCompareTester::DefaultAdjuster,
      // From examining the bounds differential for the "Default" case, the
      // SkTextBlob adds a padding of ~31 on the left, ~30 on the right,
      // ~12 on top and ~8 on the bottom, so we add 32h & 13v allowed
      // padding to the tolerance
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(32, 13));
}

const BoundsTolerance shadowTolerance(const BoundsTolerance& tolerance,
                                      const SkPaint& paint,
                                      const SkMatrix& matrix) {
  // Shadow primitives could use just a little more horizontal bounds
  // tolerance when drawn with a perspective transform.
  return CanvasCompareTester::DefaultAdjuster(
      matrix.hasPerspective() ? tolerance.addScale(1.04, 1.0) : tolerance,
      paint, matrix);
}

TEST(DisplayListCanvas, DrawShadow) {
  SkPath path;
  path.addRoundRect(
      {
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderShadows(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, false,
                                       1.0);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, false, 1.0);
      },
      shadowTolerance,
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST(DisplayListCanvas, DrawShadowTransparentOccluder) {
  SkPath path;
  path.addRoundRect(
      {
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderShadows(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, true,
                                       1.0);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, true, 1.0);
      },
      shadowTolerance,
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

TEST(DisplayListCanvas, DrawShadowDpr) {
  SkPath path;
  path.addRoundRect(
      {
          RenderLeft + 10,
          RenderTop,
          RenderRight - 10,
          RenderBottom - 20,
      },
      RenderCornerRadius, RenderCornerRadius);
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 5;

  CanvasCompareTester::RenderShadows(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, false,
                                       1.5);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, false, 1.5);
      },
      shadowTolerance,
      CanvasCompareTester::DefaultTolerance.addBoundsPadding(3, 3));
}

}  // namespace testing
}  // namespace flutter
