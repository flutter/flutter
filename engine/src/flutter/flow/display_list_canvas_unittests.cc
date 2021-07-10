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

class CanvasCompareTester {
 public:
  // If a test is using any shadow operations then we cannot currently
  // record those in an SkCanvas and play it back into a DisplayList
  // because internally the operation gets encapsulated in a Skia
  // ShadowRec which is not exposed by their headers. For operations
  // that use shadows, we can perform a lot of tests, but not the tests
  // that require SkCanvas->DisplayList transfers.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  static bool UsingShadows;

  typedef const std::function<void(SkCanvas*, SkPaint&)> CvRenderer;
  typedef const std::function<void(DisplayListBuilder&)> DlRenderer;

  static void RenderAll(CvRenderer& cv_renderer, DlRenderer& dl_renderer) {
    RenderWithAttributes(cv_renderer, dl_renderer);
    RenderWithTransforms(cv_renderer, dl_renderer);
    RenderWithClips(cv_renderer, dl_renderer);
  }

  static void RenderNoAttributes(CvRenderer& cv_renderer,
                                 DlRenderer& dl_renderer) {
    RenderWith([=](SkCanvas*, SkPaint& p) {},  //
               [=](DisplayListBuilder& d) {},  //
               cv_renderer, dl_renderer, "Base Test");
    RenderWithTransforms(cv_renderer, dl_renderer);
    RenderWithClips(cv_renderer, dl_renderer);
  }

  static void RenderWithSaveRestore(CvRenderer& cv_renderer,
                                    DlRenderer& dl_renderer) {
    SkRect clip = SkRect::MakeLTRB(0, 0, 10, 10);
    SkRect rect = SkRect::MakeLTRB(5, 5, 15, 15);
    SkColor save_layer_color = SkColorSetARGB(0x7f, 0x00, 0xff, 0xff);
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {
          cv->save();
          cv->clipRect(clip, SkClipOp::kIntersect, false);
          cv->drawRect(rect, p);
          cv->restore();
        },
        [=](DisplayListBuilder& b) {
          b.save();
          b.clipRect(clip, false, SkClipOp::kIntersect);
          b.drawRect(rect);
          b.restore();
        },
        cv_renderer, dl_renderer, "With prior save/clip/restore");
    RenderWith(
        [=](SkCanvas* cv, SkPaint& p) {
          SkPaint save_p;
          save_p.setColor(save_layer_color);
          cv->saveLayer(RenderBounds, &save_p);
          cv->drawRect(rect, p);
        },
        [=](DisplayListBuilder& b) {
          b.setColor(save_layer_color);
          b.saveLayer(&RenderBounds, true);
          b.setColor(SkPaint().getColor());
          b.drawRect(rect);
        },
        cv_renderer, dl_renderer, "With saveLayer");
  }

  static void RenderWithAttributes(CvRenderer& cv_renderer,
                                   DlRenderer& dl_renderer) {
    RenderWith([=](SkCanvas*, SkPaint& p) {},  //
               [=](DisplayListBuilder& d) {},  //
               cv_renderer, dl_renderer, "Base Test");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setAntiAlias(true); },  //
               [=](DisplayListBuilder& b) { b.setAA(true); },         //
               cv_renderer, dl_renderer, "AA == True");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setAntiAlias(false); },  //
               [=](DisplayListBuilder& b) { b.setAA(false); },         //
               cv_renderer, dl_renderer, "AA == False");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setDither(true); },  //
               [=](DisplayListBuilder& b) { b.setDither(true); },  //
               cv_renderer, dl_renderer, "Dither == True");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setDither(false); },  //
               [=](DisplayListBuilder& b) { b.setDither(false); },  //
               cv_renderer, dl_renderer, "Dither = False");

    RenderWith([=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorBLUE); },  //
               [=](DisplayListBuilder& b) { b.setColor(SK_ColorBLUE); },  //
               cv_renderer, dl_renderer, "Color == Blue");
    RenderWith([=](SkCanvas*, SkPaint& p) { p.setColor(SK_ColorGREEN); },  //
               [=](DisplayListBuilder& b) { b.setColor(SK_ColorGREEN); },  //
               cv_renderer, dl_renderer, "Color == Green");

    RenderWithStrokes(cv_renderer, dl_renderer);

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
          cv_renderer, dl_renderer, "Blend == SrcIn", &bg);
      RenderWith(
          [=](SkCanvas*, SkPaint& p) {
            p.setBlendMode(SkBlendMode::kDstIn);
            p.setColor(blendableColor);
          },
          [=](DisplayListBuilder& b) {
            b.setBlendMode(SkBlendMode::kDstIn);
            b.setColor(blendableColor);
          },
          cv_renderer, dl_renderer, "Blend == DstIn", &bg);
    }

    {
      sk_sp<SkImageFilter> filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kDecal, nullptr, nullptr);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setImageFilter(filter); },
                   [=](DisplayListBuilder& b) { b.setImageFilter(filter); },
                   cv_renderer, dl_renderer, "ImageFilter == Decal Blur 5");
      }
      ASSERT_TRUE(filter->unique()) << "ImageFilter Cleanup";
      filter =
          SkImageFilters::Blur(5.0, 5.0, SkTileMode::kClamp, nullptr, nullptr);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setImageFilter(filter); },
                   [=](DisplayListBuilder& b) { b.setImageFilter(filter); },
                   cv_renderer, dl_renderer, "ImageFilter == Clamp Blur 5");
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
            cv_renderer, dl_renderer, "ColorFilter == RotateRGB", &bg);
      }
      ASSERT_TRUE(filter->unique()) << "ColorFilter Cleanup";
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
            cv_renderer, dl_renderer, "ColorFilter == Invert", &bg);
      }
      ASSERT_TRUE(filter->unique()) << "ColorFilter Cleanup";
    }

    {
      // Discrete path effects need a stroke width for drawPointsAsPoints
      // to do something realistic
      sk_sp<SkPathEffect> effect = SkDiscretePathEffect::Make(3, 5);
      {
        // Discrete path effects need a stroke width for drawPointsAsPoints
        // to do something realistic
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, "PathEffect == Discrete-3-5");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect Cleanup";
      effect = SkDiscretePathEffect::Make(2, 3);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, "PathEffect == Discrete-2-3");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect Cleanup";
    }

    {
      sk_sp<SkMaskFilter> filter =
          SkMaskFilter::MakeBlur(kNormal_SkBlurStyle, 5.0);
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setMaskFilter(filter); },
                   [=](DisplayListBuilder& b) { b.setMaskFilter(filter); },
                   cv_renderer, dl_renderer, "MaskFilter == Blur 5");
      }
      ASSERT_TRUE(filter->unique()) << "MaskFilter Cleanup";
      {
        RenderWith([=](SkCanvas*, SkPaint& p) { p.setMaskFilter(filter); },
                   [=](DisplayListBuilder& b) {
                     b.setMaskBlurFilter(kNormal_SkBlurStyle, 5.0);
                   },
                   cv_renderer, dl_renderer, "MaskFilter == Blur(Normal, 5.0)");
      }
      ASSERT_TRUE(filter->unique()) << "MaskFilter Cleanup";
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
                   cv_renderer, dl_renderer, "LinearGradient GYB");
      }
      ASSERT_TRUE(shader->unique()) << "Shader Cleanup";
    }
  }

  static void RenderWithStrokes(CvRenderer& cv_renderer,
                                DlRenderer& dl_renderer) {
    RenderWith(
        [=](SkCanvas*, SkPaint& p) { p.setStyle(SkPaint::kFill_Style); },
        [=](DisplayListBuilder& b) { b.setDrawStyle(SkPaint::kFill_Style); },
        cv_renderer, dl_renderer, "Fill");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) { p.setStyle(SkPaint::kStroke_Style); },
        [=](DisplayListBuilder& b) { b.setDrawStyle(SkPaint::kStroke_Style); },
        cv_renderer, dl_renderer, "Stroke + defaults");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kFill_Style);
          p.setStrokeWidth(10.0);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kFill_Style);
          b.setStrokeWidth(10.0);
        },
        cv_renderer, dl_renderer, "Fill + unnecessary StrokeWidth 10");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(10.0);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(10.0);
        },
        cv_renderer, dl_renderer, "Stroke Width 10");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
        },
        cv_renderer, dl_renderer, "Stroke Width 5");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeCap(SkPaint::kButt_Cap);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setCaps(SkPaint::kButt_Cap);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Butt Cap");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeCap(SkPaint::kRound_Cap);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setCaps(SkPaint::kRound_Cap);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Round Cap");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeJoin(SkPaint::kBevel_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setJoins(SkPaint::kBevel_Join);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Bevel Join");
    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeJoin(SkPaint::kRound_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setJoins(SkPaint::kRound_Join);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Round Join");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeMiter(100.0);
          p.setStrokeJoin(SkPaint::kMiter_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setMiterLimit(100.0);
          b.setJoins(SkPaint::kMiter_Join);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Miter 100");

    RenderWith(
        [=](SkCanvas*, SkPaint& p) {
          p.setStyle(SkPaint::kStroke_Style);
          p.setStrokeWidth(5.0);
          p.setStrokeMiter(0.0);
          p.setStrokeJoin(SkPaint::kMiter_Join);
        },
        [=](DisplayListBuilder& b) {
          b.setDrawStyle(SkPaint::kStroke_Style);
          b.setStrokeWidth(5.0);
          b.setMiterLimit(0.0);
          b.setJoins(SkPaint::kMiter_Join);
        },
        cv_renderer, dl_renderer, "Stroke Width 5, Miter 0");

    {
      const SkScalar TestDashes1[] = {4.0, 2.0};
      const SkScalar TestDashes2[] = {1.0, 1.5};
      sk_sp<SkPathEffect> effect = SkDashPathEffect::Make(TestDashes1, 2, 0.0f);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStyle(SkPaint::kStroke_Style);
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setDrawStyle(SkPaint::kStroke_Style);
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, "PathEffect == Dash-4-2");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect Cleanup";
      effect = SkDashPathEffect::Make(TestDashes2, 2, 0.0f);
      {
        RenderWith(
            [=](SkCanvas*, SkPaint& p) {
              p.setStyle(SkPaint::kStroke_Style);
              p.setStrokeWidth(5.0);
              p.setPathEffect(effect);
            },
            [=](DisplayListBuilder& b) {
              b.setDrawStyle(SkPaint::kStroke_Style);
              b.setStrokeWidth(5.0);
              b.setPathEffect(effect);
            },
            cv_renderer, dl_renderer, "PathEffect == Dash-1-1.5");
      }
      ASSERT_TRUE(effect->unique()) << "PathEffect Cleanup";
    }
  }

  static void RenderWithTransforms(CvRenderer& cv_renderer,
                                   DlRenderer& dl_renderer) {
    RenderWith([=](SkCanvas* c, SkPaint&) { c->translate(5, 10); },  //
               [=](DisplayListBuilder& b) { b.translate(5, 10); },   //
               cv_renderer, dl_renderer, "Translate 5, 10");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->scale(0.95, 0.95); },  //
               [=](DisplayListBuilder& b) { b.scale(0.95, 0.95); },   //
               cv_renderer, dl_renderer, "Scale 95%");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->rotate(5); },  //
               [=](DisplayListBuilder& b) { b.rotate(5); },   //
               cv_renderer, dl_renderer, "Rotate 5 degrees");
    RenderWith([=](SkCanvas* c, SkPaint&) { c->skew(0.05, 0.05); },  //
               [=](DisplayListBuilder& b) { b.skew(0.05, 0.05); },   //
               cv_renderer, dl_renderer, "Skew 5%");
    {
      SkMatrix tx = SkMatrix::MakeAll(1.1, 0.1, 1.05, 0.05, 1, 1, 0, 0, 1);
      RenderWith([=](SkCanvas* c, SkPaint&) { c->concat(tx); },  //
                 [=](DisplayListBuilder& b) {
                   b.transform2x3(tx[0], tx[1], tx[2],  //
                                  tx[3], tx[4], tx[5]);
                 },  //
                 cv_renderer, dl_renderer, "Transform 2x3");
    }
    {
      SkMatrix tx = SkMatrix::MakeAll(1.1, 0.1, 1.05, 0.05, 1, 1, 0, 0, 1.01);
      RenderWith([=](SkCanvas* c, SkPaint&) { c->concat(tx); },  //
                 [=](DisplayListBuilder& b) {
                   b.transform3x3(tx[0], tx[1], tx[2],  //
                                  tx[3], tx[4], tx[5],  //
                                  tx[6], tx[7], tx[8]);
                 },  //
                 cv_renderer, dl_renderer, "Transform 3x3");
    }
  }

  static void RenderWithClips(CvRenderer& cv_renderer,
                              DlRenderer& dl_renderer) {
    SkRect r_clip = RenderBounds.makeInset(15.5, 15.5);
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, false, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "Hard ClipRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, true, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "AA ClipRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRect(r_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRect(r_clip, false, SkClipOp::kDifference);
        },
        cv_renderer, dl_renderer, "Hard ClipRect Diff, inset by 15.5");
    SkRRect rr_clip = SkRRect::MakeRectXY(r_clip, 1.8, 2.7);
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, false, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "Hard ClipRRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, true, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "AA ClipRRect inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipRRect(rr_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipRRect(rr_clip, false, SkClipOp::kDifference);
        },
        cv_renderer, dl_renderer, "Hard ClipRRect Diff, inset by 15.5");
    SkPath path_clip = SkPath();
    path_clip.setFillType(SkPathFillType::kEvenOdd);
    path_clip.addRect(r_clip);
    path_clip.addCircle(RenderCenterX, RenderCenterY, 1.0);
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kIntersect, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, false, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "Hard ClipPath inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kIntersect, true);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, true, SkClipOp::kIntersect);
        },
        cv_renderer, dl_renderer, "AA ClipPath inset by 15.5");
    RenderWith(
        [=](SkCanvas* c, SkPaint&) {
          c->clipPath(path_clip, SkClipOp::kDifference, false);
        },
        [=](DisplayListBuilder& b) {
          b.clipPath(path_clip, false, SkClipOp::kDifference);
        },
        cv_renderer, dl_renderer, "Hard ClipPath Diff, inset by 15.5");
  }

  static SkRect getSkBounds(CvRenderer& cv_setup, CvRenderer& cv_render) {
    SkPictureRecorder recorder;
    SkRTreeFactory rtree_factory;
    SkCanvas* cv = recorder.beginRecording(TestBounds, &rtree_factory);
    SkPaint p;
    cv_setup(cv, p);
    cv_render(cv, p);
    return recorder.finishRecordingAsPicture()->cullRect();
  }

  static void RenderWith(CvRenderer& cv_setup,
                         DlRenderer& dl_setup,
                         CvRenderer& cv_render,
                         DlRenderer& dl_render,
                         const std::string info,
                         const SkColor* bg = nullptr) {
    // surface1 is direct rendering via SkCanvas to SkSurface
    // DisplayList mechanisms are not involved in this operation
    sk_sp<SkSurface> ref_surface = makeSurface(bg);
    SkPaint paint1;
    cv_setup(ref_surface->getCanvas(), paint1);
    cv_render(ref_surface->getCanvas(), paint1);
    SkRect ref_bounds = getSkBounds(cv_setup, cv_render);
    SkPixmap ref_pixels;
    ASSERT_TRUE(ref_surface->peekPixels(&ref_pixels)) << info;
    ASSERT_EQ(ref_pixels.width(), TestWidth) << info;
    ASSERT_EQ(ref_pixels.height(), TestHeight) << info;
    ASSERT_EQ(ref_pixels.info().bytesPerPixel(), 4) << info;
    checkPixels(&ref_pixels, ref_bounds, info, bg);

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
#ifdef DISPLAY_LIST_BOUNDS_ACCURACY_CHECKING
      if (dl_bounds != ref_bounds) {
        FML_LOG(ERROR) << "For " << info;
        FML_LOG(ERROR) << "ref: " << ref_bounds.fLeft << ", " << ref_bounds.fTop
                       << " => " << ref_bounds.fRight << ", "
                       << ref_bounds.fBottom;
        FML_LOG(ERROR) << "dl: " << dl_bounds.fLeft << ", " << dl_bounds.fTop
                       << " => " << dl_bounds.fRight << ", "
                       << dl_bounds.fBottom;
        if (!dl_bounds.contains(ref_bounds)) {
          FML_LOG(ERROR) << "DisplayList bounds are too small!";
        }
      }
#endif  // DISPLAY_LIST_BOUNDS_ACCURACY_CHECKING
      // This sometimes triggers, but when it triggers and I examine
      // the ref_bounds, they are always unnecessarily large and
      // since the pixel OOB tests in the compare method do not
      // trigger, we will trust the DL bounds.
      // EXPECT_TRUE(dl_bounds.contains(ref_bounds)) << info;
      display_list->RenderTo(test_surface->getCanvas());
      compareToReference(test_surface.get(), &ref_pixels, info + " (DL render)",
                         &dl_bounds, bg);
    }

    // This test cannot work if the rendering is using shadows until
    // we can access the Skia ShadowRec via public headers.
    if (!UsingShadows) {
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
                         info + " (Sk->DL render)", nullptr, nullptr);
    }
  }

  static void checkPixels(SkPixmap* ref_pixels,
                          SkRect ref_bounds,
                          const std::string info,
                          const SkColor* bg) {
    SkPMColor untouched = (bg) ? SkPreMultiplyColor(*bg) : 0;
    int pixels_touched = 0;
    int pixels_oob = 0;
    for (int y = 0; y < TestHeight; y++) {
      const uint32_t* ref_row = ref_pixels->addr32(0, y);
      for (int x = 0; x < TestWidth; x++) {
        if (ref_row[x] != untouched) {
          pixels_touched++;
          if (!ref_bounds.intersects(SkRect::MakeXYWH(x, y, 1, 1))) {
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
                                 const SkColor* bg) {
    SkPMColor untouched = (bg) ? SkPreMultiplyColor(*bg) : 0;
    SkPixmap test_pixels;
    ASSERT_TRUE(test_surface->peekPixels(&test_pixels)) << info;
    ASSERT_EQ(test_pixels.width(), TestWidth) << info;
    ASSERT_EQ(test_pixels.height(), TestHeight) << info;
    ASSERT_EQ(test_pixels.info().bytesPerPixel(), 4) << info;

    int pixels_different = 0;
    int pixels_oob = 0;
    int minX = TestWidth;
    int minY = TestWidth;
    int maxX = 0;
    int maxY = 0;
    for (int y = 0; y < TestHeight; y++) {
      const uint32_t* ref_row = reference->addr32(0, y);
      const uint32_t* test_row = test_pixels.addr32(0, y);
      for (int x = 0; x < TestWidth; x++) {
        if (bounds && test_row[x] != untouched) {
          if (minX > x)
            minX = x;
          if (minY > y)
            minY = y;
          if (maxX < x)
            maxX = x;
          if (maxY < y)
            maxY = y;
          if (!bounds->intersects(SkRect::MakeXYWH(x, y, 1, 1))) {
            pixels_oob++;
          }
        }
        if (test_row[x] != ref_row[x]) {
          pixels_different++;
        }
      }
    }
#ifdef DISPLAY_LIST_BOUNDS_ACCURACY_CHECKING
    if (bounds && *bounds != SkRect::MakeLTRB(minX, minY, maxX + 1, maxY + 1)) {
      FML_LOG(ERROR) << "inaccurate bounds for " << info;
      FML_LOG(ERROR) << "dl: " << bounds->fLeft << ", " << bounds->fTop
                     << " => " << bounds->fRight << ", " << bounds->fBottom;
      FML_LOG(ERROR) << "pixels: " << minX << ", " << minY << " => "
                     << (maxX + 1) << ", " << (maxY + 1);
    }
#endif  // DISPLAY_LIST_BOUNDS_ACCURACY_CHECKING
    ASSERT_EQ(pixels_oob, 0) << info;
    ASSERT_EQ(pixels_different, 0) << info;
  }

  static sk_sp<SkSurface> makeSurface(const SkColor* bg) {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRasterN32Premul(TestWidth, TestHeight);
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
                                        SkScalar height = RenderHeight) {
    SkFont font(SkTypeface::MakeDefault(), height);
    return SkTextBlob::MakeFromText(string.c_str(), string.size(), font,
                                    SkTextEncoding::kUTF8);
  }
};

bool CanvasCompareTester::UsingShadows = false;
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

TEST(DisplayListCanvas, DrawLine) {
  SkRect rect = RenderBounds;
  SkPoint p1 = SkPoint::Make(rect.fLeft, rect.fTop);
  SkPoint p2 = SkPoint::Make(rect.fRight, rect.fBottom);

  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawLine(p1, p2, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawLine(p1, p2);
      });
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
  path.moveTo(RenderCenterX, RenderTop);
  path.lineTo(RenderRight, RenderBottom);
  path.lineTo(RenderLeft, RenderCenterY);
  path.lineTo(RenderRight, RenderCenterY);
  path.lineTo(RenderLeft, RenderBottom);
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
        canvas->drawArc(RenderBounds, 30, 270, false, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawArc(RenderBounds, 30, 270, false);
      });
}

TEST(DisplayListCanvas, DrawArcCenter) {
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawArc(RenderBounds, 30, 270, true, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawArc(RenderBounds, 30, 270, true);
      });
}

TEST(DisplayListCanvas, DrawPointsAsPoints) {
  const SkScalar x0 = RenderLeft;
  const SkScalar x1 = (RenderLeft + RenderCenterX) * 0.5;
  const SkScalar x2 = RenderCenterX;
  const SkScalar x3 = (RenderRight + RenderCenterX) * 0.5;
  const SkScalar x4 = RenderRight;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = (RenderTop + RenderCenterY) * 0.5;
  const SkScalar y2 = RenderCenterY;
  const SkScalar y3 = (RenderBottom + RenderCenterY) * 0.5;
  const SkScalar y4 = RenderBottom;

  // clang-format off
  const SkPoint points[] = {
      {x0, y0}, {x1, y0}, {x2, y0}, {x3, y0}, {x4, y0},
      {x0, y1}, {x1, y1}, {x2, y1}, {x3, y1}, {x4, y1},
      {x0, y2}, {x1, y2}, {x2, y2}, {x3, y2}, {x4, y2},
      {x0, y3}, {x1, y3}, {x2, y3}, {x3, y3}, {x4, y3},
      {x0, y4}, {x1, y4}, {x2, y4}, {x3, y4}, {x4, y4},
  };
  // clang-format on

  const int count = sizeof(points) / sizeof(points[0]);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kPoints_PointMode, count, points, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kPoints_PointMode, count, points);
      });
}

TEST(DisplayListCanvas, DrawPointsAsLines) {
  const SkScalar x0 = RenderLeft;
  const SkScalar x1 = (RenderLeft + RenderCenterX) * 0.5;
  const SkScalar x2 = RenderCenterX;
  const SkScalar x3 = (RenderRight + RenderCenterX) * 0.5;
  const SkScalar x4 = RenderRight;

  const SkScalar y0 = RenderTop;
  const SkScalar y1 = (RenderTop + RenderCenterY) * 0.5;
  const SkScalar y2 = RenderCenterY;
  const SkScalar y3 = (RenderBottom + RenderCenterY) * 0.5;
  const SkScalar y4 = RenderBottom;

  // clang-format off
  const SkPoint points[] = {
      // Diagonals
      {x0, y0}, {x4, y4}, {x4, y0}, {x0, y4},
      // Inner box
      {x1, y1}, {x3, y1},
      {x3, y1}, {x3, y3},
      {x3, y3}, {x1, y3},
      {x1, y3}, {x1, y1},
      // Middle crosshair
      {x2, y1}, {x2, y3},
      {x1, y2}, {x3, y3},
  };
  // clang-format on

  const int count = sizeof(points) / sizeof(points[0]);
  ASSERT_TRUE((count & 1) == 0);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kLines_PointMode, count, points, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kLines_PointMode, count, points);
      });
}

TEST(DisplayListCanvas, DrawPointsAsPolygon) {
  const SkPoint points[] = {
      SkPoint::Make(RenderLeft, RenderTop),
      SkPoint::Make(RenderRight, RenderBottom),
      SkPoint::Make(RenderRight, RenderTop),
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderLeft, RenderTop),
  };
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        SkPaint p = paint;
        p.setStyle(SkPaint::kStroke_Style);
        canvas->drawPoints(SkCanvas::kPolygon_PointMode, 4, points, p);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPoints(SkCanvas::kPolygon_PointMode, 4, points);
      });
}

TEST(DisplayListCanvas, DrawVerticesWithColors) {
  const SkPoint pts[3] = {
      SkPoint::Make(RenderCenterX, RenderTop),
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkColor colors[3] = {SK_ColorRED, SK_ColorBLUE, SK_ColorGREEN};
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 3, pts, nullptr, colors);
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawVertices(vertices.get(), SkBlendMode::kSrcOver, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawVertices(vertices, SkBlendMode::kSrcOver);
      });
  ASSERT_TRUE(vertices->unique());
}

TEST(DisplayListCanvas, DrawVerticesWithImage) {
  const SkPoint pts[3] = {
      SkPoint::Make(RenderCenterX, RenderTop),
      SkPoint::Make(RenderLeft, RenderBottom),
      SkPoint::Make(RenderRight, RenderBottom),
  };
  const SkPoint tex[3] = {
      SkPoint::Make(RenderWidth / 2.0, 0),
      SkPoint::Make(0, RenderHeight),
      SkPoint::Make(RenderWidth, RenderHeight),
  };
  const sk_sp<SkVertices> vertices = SkVertices::MakeCopy(
      SkVertices::kTriangles_VertexMode, 3, pts, tex, nullptr);
  const sk_sp<SkShader> shader = CanvasCompareTester::testImage->makeShader(
      SkTileMode::kRepeat, SkTileMode::kRepeat, SkSamplingOptions());
  CanvasCompareTester::RenderAll(
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
                          DisplayList::NearestSampling);
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
                          DisplayList::LinearSampling);
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
                              DisplayList::NearestSampling);
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
                              DisplayList::LinearSampling);
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
                              SkFilterMode::kNearest);
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
                              SkFilterMode::kLinear);
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
      {0.5, 0, RenderLeft, RenderRight},
      {0, 0.5, RenderCenterX, RenderCenterY},
  };
  const SkRect tex[] = {
      {0, 0, RenderWidth * 0.5, RenderHeight * 0.5},
      {RenderWidth * 0.5, RenderHeight * 0.5, RenderWidth, RenderHeight},
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {
        canvas->drawAtlas(image.get(), xform, tex, colors, 2,
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr, &paint);
      },
      [=](DisplayListBuilder& builder) {
        builder.drawAtlas(image, xform, tex, colors, 2,  //
                          SkBlendMode::kSrcOver, DisplayList::NearestSampling,
                          nullptr);
      });
}

TEST(DisplayListCanvas, DrawAtlasLinear) {
  const SkRSXform xform[] = {
      {0.5, 0, RenderLeft, RenderRight},
      {0, 0.5, RenderCenterX, RenderCenterY},
  };
  const SkRect tex[] = {
      {0, 0, RenderWidth * 0.5, RenderHeight * 0.5},
      {RenderWidth * 0.5, RenderHeight * 0.5, RenderWidth, RenderHeight},
  };
  const SkColor colors[] = {
      SK_ColorBLUE,
      SK_ColorGREEN,
  };
  const sk_sp<SkImage> image = CanvasCompareTester::testImage;
  CanvasCompareTester::RenderAll(
      [=](SkCanvas* canvas, SkPaint& paint) {
        canvas->drawAtlas(image.get(), xform, tex, colors, 2,  //
                          SkBlendMode::kSrcOver, DisplayList::LinearSampling,
                          nullptr, &paint);
      },
      [=](DisplayListBuilder& builder) {
        builder.drawAtlas(image, xform, tex, colors, 2,  //
                          SkBlendMode::kSrcOver, DisplayList::LinearSampling,
                          nullptr);
      });
}

TEST(DisplayListCanvas, DrawPicture) {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(RenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  p.setColor(SK_ColorBLUE);
  cv->drawOval(RenderBounds, p);
  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawPicture(picture, nullptr, nullptr);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawPicture(picture, nullptr, false);
      });
}

TEST(DisplayListCanvas, DrawPictureWithMatrix) {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(RenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  p.setColor(SK_ColorBLUE);
  cv->drawOval(RenderBounds, p);
  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
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
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(RenderBounds);
  SkPaint p;
  p.setStyle(SkPaint::kFill_Style);
  p.setColor(SK_ColorBLUE);
  cv->drawOval(RenderBounds, p);
  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
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
  builder.setDrawStyle(SkPaint::kFill_Style);
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
  sk_sp<SkTextBlob> blob = CanvasCompareTester::MakeTextBlob("Test Blob");
  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        canvas->drawTextBlob(blob, RenderLeft, RenderBottom, paint);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawTextBlob(blob, RenderLeft, RenderBottom);
      });
}

TEST(DisplayListCanvas, DrawShadow) {
  CanvasCompareTester::UsingShadows = true;
  SkPath path;
  path.moveTo(RenderCenterX, RenderTop);
  path.lineTo(RenderRight, RenderBottom);
  path.lineTo(RenderLeft, RenderCenterY);
  path.lineTo(RenderRight, RenderCenterY);
  path.lineTo(RenderLeft, RenderBottom);
  path.close();
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 10;

  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, false,
                                       1.0);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, false, 1.0);
      });
  CanvasCompareTester::UsingShadows = false;
}

TEST(DisplayListCanvas, DrawOccludingShadow) {
  CanvasCompareTester::UsingShadows = true;
  SkPath path;
  path.moveTo(RenderCenterX, RenderTop);
  path.lineTo(RenderRight, RenderBottom);
  path.lineTo(RenderLeft, RenderCenterY);
  path.lineTo(RenderRight, RenderCenterY);
  path.lineTo(RenderLeft, RenderBottom);
  path.close();
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 10;

  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, true,
                                       1.0);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, true, 1.0);
      });
  CanvasCompareTester::UsingShadows = false;
}

TEST(DisplayListCanvas, DrawShadowDpr) {
  CanvasCompareTester::UsingShadows = true;
  SkPath path;
  path.moveTo(RenderCenterX, RenderTop);
  path.lineTo(RenderRight, RenderBottom);
  path.lineTo(RenderLeft, RenderCenterY);
  path.lineTo(RenderRight, RenderCenterY);
  path.lineTo(RenderLeft, RenderBottom);
  path.close();
  const SkColor color = SK_ColorDKGRAY;
  const SkScalar elevation = 10;

  CanvasCompareTester::RenderNoAttributes(
      [=](SkCanvas* canvas, SkPaint& paint) {  //
        PhysicalShapeLayer::DrawShadow(canvas, path, color, elevation, false,
                                       2.5);
      },
      [=](DisplayListBuilder& builder) {  //
        builder.drawShadow(path, color, elevation, false, 2.5);
      });
  CanvasCompareTester::UsingShadows = false;
}

}  // namespace testing
}  // namespace flutter
