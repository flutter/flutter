// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_op_receiver.h"

namespace flutter {
namespace testing {

sk_sp<DisplayList> GetSampleDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  builder.DrawRect(SkRect::MakeXYWH(10, 10, 80, 80), DlPaint(DlColor::kRed()));
  return builder.Build();
}

sk_sp<DisplayList> GetSampleNestedDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  DlPaint paint;
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      paint.setColor(((x + y) % 20) == 10 ? DlColor(SK_ColorRED)
                                          : DlColor(SK_ColorBLUE));
      builder.DrawRect(SkRect::MakeXYWH(x, y, 80, 80), paint);
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.DrawDisplayList(builder.Build());
  return outer_builder.Build();
}

sk_sp<DisplayList> GetSampleDisplayList(int ops) {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int i = 0; i < ops; i++) {
    builder.DrawColor(DlColor::kRed(), DlBlendMode::kSrc);
  }
  return builder.Build();
}

// ---------------
// Test Suite data
// ---------------

std::vector<DisplayListInvocationGroup> CreateAllAttributesOps() {
  return {
      {"SetAntiAlias",
       {
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setAntiAlias(true); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setAntiAlias(false); }},
       }},
      {"SetInvertColors",
       {
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setInvertColors(true); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setInvertColors(false); }},
       }},
      {"SetStrokeCap",
       {
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeCap(DlStrokeCap::kRound); }},
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeCap(DlStrokeCap::kSquare); }},
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeCap(DlStrokeCap::kButt); }},
       }},
      {"SetStrokeJoin",
       {
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeJoin(DlStrokeJoin::kBevel); }},
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeJoin(DlStrokeJoin::kRound); }},
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.setStrokeJoin(DlStrokeJoin::kMiter); }},
       }},
      {"SetStyle",
       {
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setDrawStyle(DlDrawStyle::kStroke); }},
           {0, 8, 0, 0,
            [](DlOpReceiver& r) {
              r.setDrawStyle(DlDrawStyle::kStrokeAndFill);
            }},
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.setDrawStyle(DlDrawStyle::kFill); }},
       }},
      {"SetStrokeWidth",
       {
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setStrokeWidth(1.0); }},
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setStrokeWidth(5.0); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setStrokeWidth(0.0); }},
       }},
      {"SetStrokeMiter",
       {
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setStrokeMiter(0.0); }},
           {0, 8, 0, 0, [](DlOpReceiver& r) { r.setStrokeMiter(5.0); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setStrokeMiter(4.0); }},
       }},
      {"SetColor",
       {
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setColor(DlColor(SK_ColorGREEN)); }},
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setColor(DlColor(SK_ColorBLUE)); }},
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.setColor(DlColor(SK_ColorBLACK)); }},
       }},
      {"SetBlendMode",
       {
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setBlendMode(DlBlendMode::kSrcIn); }},
           {0, 8, 0, 0,
            [](DlOpReceiver& r) { r.setBlendMode(DlBlendMode::kDstIn); }},
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.setBlendMode(DlBlendMode::kSrcOver); }},
       }},
      {"SetColorSource",
       {
           {0, 96, 0, 0,
            [](DlOpReceiver& r) { r.setColorSource(&kTestSource1); }},
           // stop_count * (sizeof(float) + sizeof(uint32_t)) = 80
           {0, 80 + 6 * 4, 0, 0,
            [](DlOpReceiver& r) { r.setColorSource(kTestSource2.get()); }},
           {0, 80 + 6 * 4, 0, 0,
            [](DlOpReceiver& r) { r.setColorSource(kTestSource3.get()); }},
           {0, 88 + 6 * 4, 0, 0,
            [](DlOpReceiver& r) { r.setColorSource(kTestSource4.get()); }},
           {0, 80 + 6 * 4, 0, 0,
            [](DlOpReceiver& r) { r.setColorSource(kTestSource5.get()); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setColorSource(nullptr); }},
       }},
      {"SetImageFilter",
       {
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestBlurImageFilter1); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestBlurImageFilter2); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestBlurImageFilter3); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestBlurImageFilter4); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestDilateImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestDilateImageFilter2);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestDilateImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestErodeImageFilter1); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestErodeImageFilter2); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestErodeImageFilter3); }},
           {0, 64, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestMatrixImageFilter1);
            }},
           {0, 64, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestMatrixImageFilter2);
            }},
           {0, 64, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestMatrixImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestComposeImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestComposeImageFilter2);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(&kTestComposeImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestCFImageFilter1); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setImageFilter(&kTestCFImageFilter2); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setImageFilter(nullptr); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) {
              r.setImageFilter(
                  kTestBlurImageFilter1
                      .makeWithLocalMatrix(SkMatrix::Translate(2, 2))
                      .get());
            }},
       }},
      {"SetColorFilter",
       {
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setColorFilter(&kTestBlendColorFilter1); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setColorFilter(&kTestBlendColorFilter2); }},
           {0, 24, 0, 0,
            [](DlOpReceiver& r) { r.setColorFilter(&kTestBlendColorFilter3); }},
           {0, 96, 0, 0,
            [](DlOpReceiver& r) {
              r.setColorFilter(&kTestMatrixColorFilter1);
            }},
           {0, 96, 0, 0,
            [](DlOpReceiver& r) {
              r.setColorFilter(&kTestMatrixColorFilter2);
            }},
           {0, 16, 0, 0,
            [](DlOpReceiver& r) {
              r.setColorFilter(DlSrgbToLinearGammaColorFilter::kInstance.get());
            }},
           {0, 16, 0, 0,
            [](DlOpReceiver& r) {
              r.setColorFilter(DlLinearToSrgbGammaColorFilter::kInstance.get());
            }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setColorFilter(nullptr); }},
       }},
      {"SetPathEffect",
       {
           // sizeof(DlDashPathEffect) + 2 * sizeof(SkScalar)
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setPathEffect(kTestPathEffect1.get()); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setPathEffect(kTestPathEffect2.get()); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setPathEffect(nullptr); }},
       }},
      {"SetMaskFilter",
       {
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setMaskFilter(&kTestMaskFilter1); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setMaskFilter(&kTestMaskFilter2); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setMaskFilter(&kTestMaskFilter3); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setMaskFilter(&kTestMaskFilter4); }},
           {0, 32, 0, 0,
            [](DlOpReceiver& r) { r.setMaskFilter(&kTestMaskFilter5); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.setMaskFilter(nullptr); }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllSaveRestoreOps() {
  return {
      {"Save(Layer)+Restore",
       {
           {5, 112, 5, 112,
            [](DlOpReceiver& r) {
              r.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
                          &kTestCFImageFilter1);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           // There are many reasons that save and restore can elide content,
           // including whether or not there are any draw operations between
           // them, whether or not there are any state changes to restore, and
           // whether group rendering (opacity) optimizations can allow
           // attributes to be distributed to the children. To prevent those
           // cases we include at least one clip operation and 2 overlapping
           // rendering primitives between each save/restore pair.
           {5, 96, 5, 96,
            [](DlOpReceiver& r) {
              r.save();
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 96, 5, 96,
            [](DlOpReceiver& r) {
              r.saveLayer(nullptr, SaveLayerOptions::kNoAttributes);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 96, 5, 96,
            [](DlOpReceiver& r) {
              r.saveLayer(nullptr, SaveLayerOptions::kWithAttributes);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 112, 5, 112,
            [](DlOpReceiver& r) {
              r.saveLayer(&kTestBounds, SaveLayerOptions::kNoAttributes);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 112, 5, 112,
            [](DlOpReceiver& r) {
              r.saveLayer(&kTestBounds, SaveLayerOptions::kWithAttributes);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           // backdrop variants - using the TestCFImageFilter because it can be
           // reconstituted in the DL->SkCanvas->DL stream
           // {5, 104, 5, 104, [](DlOpReceiver& r) {
           //   r.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
           //   &kTestCFImageFilter1); r.clipRect({0, 0, 25, 25},
           //   SkClipOp::kIntersect, true); r.drawRect({5, 5, 15, 15});
           //   r.drawRect({10, 10, 20, 20});
           //   r.restore();
           // }},
           {5, 112, 5, 112,
            [](DlOpReceiver& r) {
              r.saveLayer(nullptr, SaveLayerOptions::kWithAttributes,
                          &kTestCFImageFilter1);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 128, 5, 128,
            [](DlOpReceiver& r) {
              r.saveLayer(&kTestBounds, SaveLayerOptions::kNoAttributes,
                          &kTestCFImageFilter1);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
           {5, 128, 5, 128,
            [](DlOpReceiver& r) {
              r.saveLayer(&kTestBounds, SaveLayerOptions::kWithAttributes,
                          &kTestCFImageFilter1);
              r.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              r.drawRect({5, 5, 15, 15});
              r.drawRect({10, 10, 20, 20});
              r.restore();
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllTransformOps() {
  return {
      {"Translate",
       {
           // cv.translate(0, 0) is ignored
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.translate(10, 10); }},
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.translate(10, 15); }},
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.translate(15, 10); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.translate(0, 0); }},
       }},
      {"Scale",
       {
           // cv.scale(1, 1) is ignored
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.scale(2, 2); }},
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.scale(2, 3); }},
           {1, 16, 1, 16, [](DlOpReceiver& r) { r.scale(3, 2); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.scale(1, 1); }},
       }},
      {"Rotate",
       {
           // cv.rotate(0) is ignored, otherwise expressed as concat(rotmatrix)
           {1, 8, 1, 32, [](DlOpReceiver& r) { r.rotate(30); }},
           {1, 8, 1, 32, [](DlOpReceiver& r) { r.rotate(45); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.rotate(0); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.rotate(360); }},
       }},
      {"Skew",
       {
           // cv.skew(0, 0) is ignored, otherwise expressed as
           // concat(skewmatrix)
           {1, 16, 1, 32, [](DlOpReceiver& r) { r.skew(0.1, 0.1); }},
           {1, 16, 1, 32, [](DlOpReceiver& r) { r.skew(0.1, 0.2); }},
           {1, 16, 1, 32, [](DlOpReceiver& r) { r.skew(0.2, 0.1); }},
           {0, 0, 0, 0, [](DlOpReceiver& r) { r.skew(0, 0); }},
       }},
      {"Transform2DAffine",
       {
           {1, 32, 1, 32,
            [](DlOpReceiver& r) { r.transform2DAffine(0, 1, 12, 1, 0, 33); }},
           // r.transform(identity) is ignored
           {0, 0, 0, 0,
            [](DlOpReceiver& r) { r.transform2DAffine(1, 0, 0, 0, 1, 0); }},
       }},
      {"TransformFullPerspective",
       {
           {1, 72, 1, 72,
            [](DlOpReceiver& r) {
              r.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29,
                                         0, 0, 0, 12);
            }},
           // r.transform(2D affine) is reduced to 2x3
           {1, 32, 1, 32,
            [](DlOpReceiver& r) {
              r.transformFullPerspective(2, 1, 0, 4, 1, 3, 0, 5, 0, 0, 1, 0, 0,
                                         0, 0, 1);
            }},
           // r.transform(identity) is ignored
           {0, 0, 0, 0,
            [](DlOpReceiver& r) {
              r.transformFullPerspective(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0,
                                         0, 0, 1);
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllClipOps() {
  return {
      {"ClipRect",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipRect(kTestBounds, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipRect(kTestBounds.makeOffset(1, 1),
                         DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipRect(kTestBounds, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipRect(kTestBounds, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipRect(kTestBounds, DlCanvas::ClipOp::kDifference, false);
            }},
       }},
      {"ClipRRect",
       {
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipRRect(kTestRRect, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipRRect(kTestRRect.makeOffset(1, 1),
                          DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipRRect(kTestRRect, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipRRect(kTestRRect, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipRRect(kTestRRect, DlCanvas::ClipOp::kDifference, false);
            }},
       }},
      {"ClipPath",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath1, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath2, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath3, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath1, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath1, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPath1, DlCanvas::ClipOp::kDifference, false);
            }},
           // clipPath(rect) becomes clipRect
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPathRect, DlCanvas::ClipOp::kIntersect, true);
            }},
           // clipPath(oval) becomes clipRRect
           {1, 64, 1, 64,
            [](DlOpReceiver& r) {
              r.clipPath(kTestPathOval, DlCanvas::ClipOp::kIntersect, true);
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllRenderingOps() {
  return {
      {"DrawPaint",
       {
           {1, 8, 1, 8, [](DlOpReceiver& r) { r.drawPaint(); }},
       }},
      {"DrawColor",
       {
           // cv.drawColor becomes cv.drawPaint(paint)
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawColor(DlColor(SK_ColorBLUE), DlBlendMode::kSrcIn);
            }},
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawColor(DlColor(SK_ColorBLUE), DlBlendMode::kDstOut);
            }},
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawColor(DlColor(SK_ColorCYAN), DlBlendMode::kSrcIn);
            }},
       }},
      {"DrawLine",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawLine({0, 0}, {10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawLine({0, 1}, {10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawLine({0, 0}, {20, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawLine({0, 0}, {10, 20});
            }},
       }},
      {"DrawRect",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawRect({0, 0, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawRect({0, 1, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawRect({0, 0, 20, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawRect({0, 0, 10, 20});
            }},
       }},
      {"DrawOval",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawOval({0, 0, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawOval({0, 1, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawOval({0, 0, 20, 10});
            }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) {
              r.drawOval({0, 0, 10, 20});
            }},
       }},
      {"DrawCircle",
       {
           // cv.drawCircle becomes cv.drawOval
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawCircle({0, 0}, 10);
            }},
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawCircle({0, 5}, 10);
            }},
           {1, 16, 1, 24,
            [](DlOpReceiver& r) {
              r.drawCircle({0, 0}, 20);
            }},
       }},
      {"DrawRRect",
       {
           {1, 56, 1, 56, [](DlOpReceiver& r) { r.drawRRect(kTestRRect); }},
           {1, 56, 1, 56,
            [](DlOpReceiver& r) { r.drawRRect(kTestRRect.makeOffset(5, 5)); }},
       }},
      {"DrawDRRect",
       {
           {1, 112, 1, 112,
            [](DlOpReceiver& r) { r.drawDRRect(kTestRRect, kTestInnerRRect); }},
           {1, 112, 1, 112,
            [](DlOpReceiver& r) {
              r.drawDRRect(kTestRRect.makeOffset(5, 5),
                           kTestInnerRRect.makeOffset(4, 4));
            }},
       }},
      {"DrawPath",
       {
           {1, 24, 1, 24, [](DlOpReceiver& r) { r.drawPath(kTestPath1); }},
           {1, 24, 1, 24, [](DlOpReceiver& r) { r.drawPath(kTestPath2); }},
           {1, 24, 1, 24, [](DlOpReceiver& r) { r.drawPath(kTestPath3); }},
           {1, 24, 1, 24, [](DlOpReceiver& r) { r.drawPath(kTestPathRect); }},
           {1, 24, 1, 24, [](DlOpReceiver& r) { r.drawPath(kTestPathOval); }},
       }},
      {"DrawArc",
       {
           {1, 32, 1, 32,
            [](DlOpReceiver& r) { r.drawArc(kTestBounds, 45, 270, false); }},
           {1, 32, 1, 32,
            [](DlOpReceiver& r) {
              r.drawArc(kTestBounds.makeOffset(1, 1), 45, 270, false);
            }},
           {1, 32, 1, 32,
            [](DlOpReceiver& r) { r.drawArc(kTestBounds, 30, 270, false); }},
           {1, 32, 1, 32,
            [](DlOpReceiver& r) { r.drawArc(kTestBounds, 45, 260, false); }},
           {1, 32, 1, 32,
            [](DlOpReceiver& r) { r.drawArc(kTestBounds, 45, 270, true); }},
       }},
      {"DrawPoints",
       {
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DlOpReceiver& r) {
              r.drawPoints(DlCanvas::PointMode::kPoints, TestPointCount,
                           TestPoints);
            }},
           {1, 8 + (TestPointCount - 1) * 8, 1, 8 + (TestPointCount - 1) * 8,
            [](DlOpReceiver& r) {
              r.drawPoints(DlCanvas::PointMode::kPoints, TestPointCount - 1,
                           TestPoints);
            }},
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DlOpReceiver& r) {
              r.drawPoints(DlCanvas::PointMode::kLines, TestPointCount,
                           TestPoints);
            }},
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DlOpReceiver& r) {
              r.drawPoints(DlCanvas::PointMode::kPolygon, TestPointCount,
                           TestPoints);
            }},
       }},
      {"DrawVertices",
       {
           {1, 112, 1, 16,
            [](DlOpReceiver& r) {
              r.drawVertices(TestVertices1.get(), DlBlendMode::kSrcIn);
            }},
           {1, 112, 1, 16,
            [](DlOpReceiver& r) {
              r.drawVertices(TestVertices1.get(), DlBlendMode::kDstIn);
            }},
           {1, 112, 1, 16,
            [](DlOpReceiver& r) {
              r.drawVertices(TestVertices2.get(), DlBlendMode::kSrcIn);
            }},
       }},
      {"DrawImage",
       {
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage1, {10, 10}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage1, {10, 10}, kNearestSampling, true);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage1, {20, 10}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage1, {10, 20}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage1, {10, 10}, kLinearSampling, false);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              r.drawImage(TestImage2, {10, 10}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DlOpReceiver& r) {
              auto dl_image = DlImage::Make(TestSkImage);
              r.drawImage(dl_image, {10, 10}, kNearestSampling, false);
            }},
       }},
      {"DrawImageRect",
       {
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kNearestSampling, true,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kStrict);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kLinearSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageRect(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
           {1, 56, -1, 80,
            [](DlOpReceiver& r) {
              auto dl_image = DlImage::Make(TestSkImage);
              r.drawImageRect(dl_image, {10, 10, 15, 15}, {10, 10, 80, 80},
                              kNearestSampling, false,
                              DlCanvas::SrcRectConstraint::kFast);
            }},
       }},
      {"DrawImageNine",
       {
           // SkCanvas::drawImageNine is immediately converted to
           // drawImageLattice
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, true);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kLinear, false);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              r.drawImageNine(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DlOpReceiver& r) {
              auto dl_image = DlImage::Make(TestSkImage);
              r.drawImageNine(dl_image, {10, 10, 15, 15}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
       }},
      {"DrawAtlas",
       {
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr, true);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{0, 1, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 25, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kLinearSampling, nullptr, false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kDstIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 64 + 32 + 8, -1, 64 + 32 + 32,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static SkRect cull_rect = {0, 0, 200, 200};
              r.drawAtlas(TestImage2, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, &cull_rect,
                          false);
            }},
           {1, 48 + 32 + 8 + 8, -1, 48 + 32 + 32 + 8,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static DlColor colors[] = {DlColor::kBlue(), DlColor::kGreen()};
              r.drawAtlas(TestImage1, xforms, texs, colors, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 64 + 32 + 8 + 8, -1, 64 + 32 + 32 + 8,
            [](DlOpReceiver& r) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static DlColor colors[] = {DlColor::kBlue(), DlColor::kGreen()};
              static SkRect cull_rect = {0, 0, 200, 200};
              r.drawAtlas(TestImage1, xforms, texs, colors, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, &cull_rect,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DlOpReceiver& r) {
              auto dl_image = DlImage::Make(TestSkImage);
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              r.drawAtlas(dl_image, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
       }},
      {"DrawDisplayList",
       {
           // cv.drawDL does not exist
           {1, 16, -1, 16,
            [](DlOpReceiver& r) { r.drawDisplayList(TestDisplayList1, 1.0); }},
           {1, 16, -1, 16,
            [](DlOpReceiver& r) { r.drawDisplayList(TestDisplayList1, 0.5); }},
           {1, 16, -1, 16,
            [](DlOpReceiver& r) { r.drawDisplayList(TestDisplayList2, 1.0); }},
           {1, 16, -1, 16,
            [](DlOpReceiver& r) {
              r.drawDisplayList(MakeTestDisplayList(10, 10, SK_ColorRED), 1.0);
            }},
       }},
      {"DrawTextBlob",
       {
           {1, 24, 1, 24,
            [](DlOpReceiver& r) { r.drawTextBlob(TestBlob1, 10, 10); }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) { r.drawTextBlob(TestBlob1, 20, 10); }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) { r.drawTextBlob(TestBlob1, 10, 20); }},
           {1, 24, 1, 24,
            [](DlOpReceiver& r) { r.drawTextBlob(TestBlob2, 10, 10); }},
       }},
      // The -1 op counts below are to indicate to the framework not to test
      // SkCanvas conversion of these ops as it converts the operation into a
      // format that is not exposed publicly and so we cannot recapture the
      // operation.
      // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
      {"DrawShadow",
       {
           // cv shadows are turned into an opaque ShadowRec which is not
           // exposed
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath1, DlColor(SK_ColorGREEN), 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath2, DlColor(SK_ColorGREEN), 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath1, DlColor(SK_ColorBLUE), 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath1, DlColor(SK_ColorGREEN), 2.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath1, DlColor(SK_ColorGREEN), 1.0, true, 1.0);
            }},
           {1, 32, -1, 32,
            [](DlOpReceiver& r) {
              r.drawShadow(kTestPath1, DlColor(SK_ColorGREEN), 1.0, false, 2.5);
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllGroups() {
  std::vector<DisplayListInvocationGroup> result;
  auto all_attribute_ops = CreateAllAttributesOps();
  std::move(all_attribute_ops.begin(), all_attribute_ops.end(),
            std::back_inserter(result));
  auto all_save_restore_ops = CreateAllSaveRestoreOps();
  std::move(all_save_restore_ops.begin(), all_save_restore_ops.end(),
            std::back_inserter(result));
  auto all_transform_ops = CreateAllTransformOps();
  std::move(all_transform_ops.begin(), all_transform_ops.end(),
            std::back_inserter(result));
  auto all_clip_ops = CreateAllClipOps();
  std::move(all_clip_ops.begin(), all_clip_ops.end(),
            std::back_inserter(result));
  auto all_rendering_ops = CreateAllRenderingOps();
  std::move(all_rendering_ops.begin(), all_rendering_ops.end(),
            std::back_inserter(result));
  return result;
}

}  // namespace testing
}  // namespace flutter
