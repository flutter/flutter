// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/display_list/display_list_builder.h"

namespace flutter {
namespace testing {

sk_sp<DisplayList> GetSampleDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  builder.setColor(SK_ColorRED);
  builder.drawRect(SkRect::MakeXYWH(10, 10, 80, 80));
  return builder.Build();
}

sk_sp<DisplayList> GetSampleNestedDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      builder.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      builder.drawRect(SkRect::MakeXYWH(x, y, 80, 80));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.drawDisplayList(builder.Build());
  return outer_builder.Build();
}

sk_sp<DisplayList> GetSampleDisplayList(int ops) {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int i = 0; i < ops; i++) {
    builder.drawColor(SK_ColorRED, DlBlendMode::kSrc);
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
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setAntiAlias(true); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.setAntiAlias(false); }},
       }},
      {"SetDither",
       {
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setDither(true); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.setDither(false); }},
       }},
      {"SetInvertColors",
       {
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setInvertColors(true); }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setInvertColors(false); }},
       }},
      {"SetStrokeCap",
       {
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setStrokeCap(DlStrokeCap::kRound); }},
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) {
              b.setStrokeCap(DlStrokeCap::kSquare);
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setStrokeCap(DlStrokeCap::kButt); }},
       }},
      {"SetStrokeJoin",
       {
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) {
              b.setStrokeJoin(DlStrokeJoin::kBevel);
            }},
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) {
              b.setStrokeJoin(DlStrokeJoin::kRound);
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) {
              b.setStrokeJoin(DlStrokeJoin::kMiter);
            }},
       }},
      {"SetStyle",
       {
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setStyle(DlDrawStyle::kStroke); }},
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) {
              b.setStyle(DlDrawStyle::kStrokeAndFill);
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setStyle(DlDrawStyle::kFill); }},
       }},
      {"SetStrokeWidth",
       {
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setStrokeWidth(1.0); }},
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setStrokeWidth(5.0); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.setStrokeWidth(0.0); }},
       }},
      {"SetStrokeMiter",
       {
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setStrokeMiter(0.0); }},
           {0, 8, 0, 0, [](DisplayListBuilder& b) { b.setStrokeMiter(5.0); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.setStrokeMiter(4.0); }},
       }},
      {"SetColor",
       {
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setColor(SK_ColorGREEN); }},
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setColor(SK_ColorBLUE); }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setColor(SK_ColorBLACK); }},
       }},
      {"SetBlendModeOrBlender",
       {
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setBlendMode(DlBlendMode::kSrcIn); }},
           {0, 8, 0, 0,
            [](DisplayListBuilder& b) { b.setBlendMode(DlBlendMode::kDstIn); }},
           {0, 16, 0, 0,
            [](DisplayListBuilder& b) { b.setBlender(kTestBlender1); }},
           {0, 16, 0, 0,
            [](DisplayListBuilder& b) { b.setBlender(kTestBlender2); }},
           {0, 16, 0, 0,
            [](DisplayListBuilder& b) { b.setBlender(kTestBlender3); }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) {
              b.setBlendMode(DlBlendMode::kSrcOver);
            }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.setBlender(nullptr); }},
       }},
      {"SetColorSource",
       {
           {0, 96, 0, 0,
            [](DisplayListBuilder& b) { b.setColorSource(&kTestSource1); }},
           // stop_count * (sizeof(float) + sizeof(uint32_t)) = 80
           {0, 80 + 6 * 4, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorSource(kTestSource2.get());
            }},
           {0, 80 + 6 * 4, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorSource(kTestSource3.get());
            }},
           {0, 88 + 6 * 4, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorSource(kTestSource4.get());
            }},
           {0, 80 + 6 * 4, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorSource(kTestSource5.get());
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setColorSource(nullptr); }},
       }},
      {"SetImageFilter",
       {
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestBlurImageFilter1);
            }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestBlurImageFilter2);
            }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestBlurImageFilter3);
            }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestBlurImageFilter4);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestDilateImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestDilateImageFilter2);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestDilateImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestErodeImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestErodeImageFilter2);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestErodeImageFilter3);
            }},
           {0, 64, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestMatrixImageFilter1);
            }},
           {0, 64, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestMatrixImageFilter2);
            }},
           {0, 64, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestMatrixImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestComposeImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestComposeImageFilter2);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestComposeImageFilter3);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestCFImageFilter1);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setImageFilter(&kTestCFImageFilter2);
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setImageFilter(nullptr); }},
       }},
      {"SetColorFilter",
       {
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(&kTestBlendColorFilter1);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(&kTestBlendColorFilter2);
            }},
           {0, 24, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(&kTestBlendColorFilter3);
            }},
           {0, 96, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(&kTestMatrixColorFilter1);
            }},
           {0, 96, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(&kTestMatrixColorFilter2);
            }},
           {0, 16, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(DlSrgbToLinearGammaColorFilter::instance.get());
            }},
           {0, 16, 0, 0,
            [](DisplayListBuilder& b) {
              b.setColorFilter(DlLinearToSrgbGammaColorFilter::instance.get());
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setColorFilter(nullptr); }},
       }},
      {"SetPathEffect",
       {
           // sizeof(DlDashPathEffect) + 2 * sizeof(SkScalar)
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setPathEffect(kTestPathEffect1.get());
            }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) {
              b.setPathEffect(kTestPathEffect2.get());
            }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setPathEffect(nullptr); }},
       }},
      {"SetMaskFilter",
       {
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(&kTestMaskFilter1); }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(&kTestMaskFilter2); }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(&kTestMaskFilter3); }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(&kTestMaskFilter4); }},
           {0, 32, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(&kTestMaskFilter5); }},
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) { b.setMaskFilter(nullptr); }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllSaveRestoreOps() {
  return {
      {"Save(Layer)+Restore",
       {
           {5, 112, 5, 112,
            [](DisplayListBuilder& b) {
              b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
                          &kTestCFImageFilter1);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           // There are many reasons that save and restore can elide content,
           // including whether or not there are any draw operations between
           // them, whether or not there are any state changes to restore, and
           // whether group rendering (opacity) optimizations can allow
           // attributes to be distributed to the children. To prevent those
           // cases we include at least one clip operation and 2 overlapping
           // rendering primitives between each save/restore pair.
           {5, 96, 5, 96,
            [](DisplayListBuilder& b) {
              b.save();
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 96, 5, 96,
            [](DisplayListBuilder& b) {
              b.saveLayer(nullptr, false);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 96, 5, 96,
            [](DisplayListBuilder& b) {
              b.saveLayer(nullptr, true);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 112, 5, 112,
            [](DisplayListBuilder& b) {
              b.saveLayer(&kTestBounds, false);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 112, 5, 112,
            [](DisplayListBuilder& b) {
              b.saveLayer(&kTestBounds, true);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           // backdrop variants - using the TestCFImageFilter because it can be
           // reconstituted in the DL->SkCanvas->DL stream
           // {5, 104, 5, 104, [](DisplayListBuilder& b) {
           //   b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes,
           //   &kTestCFImageFilter1); b.clipRect({0, 0, 25, 25},
           //   SkClipOp::kIntersect, true); b.drawRect({5, 5, 15, 15});
           //   b.drawRect({10, 10, 20, 20});
           //   b.restore();
           // }},
           {5, 112, 5, 112,
            [](DisplayListBuilder& b) {
              b.saveLayer(nullptr, SaveLayerOptions::kWithAttributes,
                          &kTestCFImageFilter1);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 128, 5, 128,
            [](DisplayListBuilder& b) {
              b.saveLayer(&kTestBounds, SaveLayerOptions::kNoAttributes,
                          &kTestCFImageFilter1);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
           {5, 128, 5, 128,
            [](DisplayListBuilder& b) {
              b.saveLayer(&kTestBounds, SaveLayerOptions::kWithAttributes,
                          &kTestCFImageFilter1);
              b.clipRect({0, 0, 25, 25}, DlCanvas::ClipOp::kIntersect, true);
              b.drawRect({5, 5, 15, 15});
              b.drawRect({10, 10, 20, 20});
              b.restore();
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllTransformOps() {
  return {
      {"Translate",
       {
           // cv.translate(0, 0) is ignored
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.translate(10, 10); }},
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.translate(10, 15); }},
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.translate(15, 10); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.translate(0, 0); }},
       }},
      {"Scale",
       {
           // cv.scale(1, 1) is ignored
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.scale(2, 2); }},
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.scale(2, 3); }},
           {1, 16, 1, 16, [](DisplayListBuilder& b) { b.scale(3, 2); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.scale(1, 1); }},
       }},
      {"Rotate",
       {
           // cv.rotate(0) is ignored, otherwise expressed as concat(rotmatrix)
           {1, 8, 1, 32, [](DisplayListBuilder& b) { b.rotate(30); }},
           {1, 8, 1, 32, [](DisplayListBuilder& b) { b.rotate(45); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.rotate(0); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.rotate(360); }},
       }},
      {"Skew",
       {
           // cv.skew(0, 0) is ignored, otherwise expressed as
           // concat(skewmatrix)
           {1, 16, 1, 32, [](DisplayListBuilder& b) { b.skew(0.1, 0.1); }},
           {1, 16, 1, 32, [](DisplayListBuilder& b) { b.skew(0.1, 0.2); }},
           {1, 16, 1, 32, [](DisplayListBuilder& b) { b.skew(0.2, 0.1); }},
           {0, 0, 0, 0, [](DisplayListBuilder& b) { b.skew(0, 0); }},
       }},
      {"Transform2DAffine",
       {
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.transform2DAffine(0, 1, 12, 1, 0, 33);
            }},
           // b.transform(identity) is ignored
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) {
              b.transform2DAffine(1, 0, 0, 0, 1, 0);
            }},
       }},
      {"TransformFullPerspective",
       {
           {1, 72, 1, 72,
            [](DisplayListBuilder& b) {
              b.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29,
                                         0, 0, 0, 12);
            }},
           // b.transform(2D affine) is reduced to 2x3
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.transformFullPerspective(2, 1, 0, 4, 1, 3, 0, 5, 0, 0, 1, 0, 0,
                                         0, 0, 1);
            }},
           // b.transform(identity) is ignored
           {0, 0, 0, 0,
            [](DisplayListBuilder& b) {
              b.transformFullPerspective(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0,
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
            [](DisplayListBuilder& b) {
              b.clipRect(kTestBounds, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipRect(kTestBounds.makeOffset(1, 1),
                         DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipRect(kTestBounds, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipRect(kTestBounds, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipRect(kTestBounds, DlCanvas::ClipOp::kDifference, false);
            }},
       }},
      {"ClipRRect",
       {
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipRRect(kTestRRect, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipRRect(kTestRRect.makeOffset(1, 1),
                          DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipRRect(kTestRRect, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipRRect(kTestRRect, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipRRect(kTestRRect, DlCanvas::ClipOp::kDifference, false);
            }},
       }},
      {"ClipPath",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath1, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath2, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath3, DlCanvas::ClipOp::kIntersect, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath1, DlCanvas::ClipOp::kIntersect, false);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath1, DlCanvas::ClipOp::kDifference, true);
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPath1, DlCanvas::ClipOp::kDifference, false);
            }},
           // clipPath(rect) becomes clipRect
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPathRect, DlCanvas::ClipOp::kIntersect, true);
            }},
           // clipPath(oval) becomes clipRRect
           {1, 64, 1, 64,
            [](DisplayListBuilder& b) {
              b.clipPath(kTestPathOval, DlCanvas::ClipOp::kIntersect, true);
            }},
       }},
  };
}

std::vector<DisplayListInvocationGroup> CreateAllRenderingOps() {
  return {
      {"DrawPaint",
       {
           {1, 8, 1, 8, [](DisplayListBuilder& b) { b.drawPaint(); }},
       }},
      {"DrawColor",
       {
           // cv.drawColor becomes cv.drawPaint(paint)
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawColor(SK_ColorBLUE, DlBlendMode::kSrcIn);
            }},
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawColor(SK_ColorBLUE, DlBlendMode::kDstIn);
            }},
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawColor(SK_ColorCYAN, DlBlendMode::kSrcIn);
            }},
       }},
      {"DrawLine",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawLine({0, 0}, {10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawLine({0, 1}, {10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawLine({0, 0}, {20, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawLine({0, 0}, {10, 20});
            }},
       }},
      {"DrawRect",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawRect({0, 0, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawRect({0, 1, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawRect({0, 0, 20, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawRect({0, 0, 10, 20});
            }},
       }},
      {"DrawOval",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawOval({0, 0, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawOval({0, 1, 10, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawOval({0, 0, 20, 10});
            }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawOval({0, 0, 10, 20});
            }},
       }},
      {"DrawCircle",
       {
           // cv.drawCircle becomes cv.drawOval
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawCircle({0, 0}, 10);
            }},
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawCircle({0, 5}, 10);
            }},
           {1, 16, 1, 24,
            [](DisplayListBuilder& b) {
              b.drawCircle({0, 0}, 20);
            }},
       }},
      {"DrawRRect",
       {
           {1, 56, 1, 56,
            [](DisplayListBuilder& b) { b.drawRRect(kTestRRect); }},
           {1, 56, 1, 56,
            [](DisplayListBuilder& b) {
              b.drawRRect(kTestRRect.makeOffset(5, 5));
            }},
       }},
      {"DrawDRRect",
       {
           {1, 112, 1, 112,
            [](DisplayListBuilder& b) {
              b.drawDRRect(kTestRRect, kTestInnerRRect);
            }},
           {1, 112, 1, 112,
            [](DisplayListBuilder& b) {
              b.drawDRRect(kTestRRect.makeOffset(5, 5),
                           kTestInnerRRect.makeOffset(4, 4));
            }},
       }},
      {"DrawPath",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawPath(kTestPath1); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawPath(kTestPath2); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawPath(kTestPath3); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawPath(kTestPathRect); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawPath(kTestPathOval); }},
       }},
      {"DrawArc",
       {
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.drawArc(kTestBounds, 45, 270, false);
            }},
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.drawArc(kTestBounds.makeOffset(1, 1), 45, 270, false);
            }},
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.drawArc(kTestBounds, 30, 270, false);
            }},
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.drawArc(kTestBounds, 45, 260, false);
            }},
           {1, 32, 1, 32,
            [](DisplayListBuilder& b) {
              b.drawArc(kTestBounds, 45, 270, true);
            }},
       }},
      {"DrawPoints",
       {
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DisplayListBuilder& b) {
              b.drawPoints(DlCanvas::PointMode::kPoints, TestPointCount,
                           TestPoints);
            }},
           {1, 8 + (TestPointCount - 1) * 8, 1, 8 + (TestPointCount - 1) * 8,
            [](DisplayListBuilder& b) {
              b.drawPoints(DlCanvas::PointMode::kPoints, TestPointCount - 1,
                           TestPoints);
            }},
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DisplayListBuilder& b) {
              b.drawPoints(DlCanvas::PointMode::kLines, TestPointCount,
                           TestPoints);
            }},
           {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
            [](DisplayListBuilder& b) {
              b.drawPoints(DlCanvas::PointMode::kPolygon, TestPointCount,
                           TestPoints);
            }},
       }},
      {"DrawVertices",
       {
           {1, 112, 1, 16,
            [](DisplayListBuilder& b) {
              b.drawVertices(TestVertices1, DlBlendMode::kSrcIn);
            }},
           {1, 112, 1, 16,
            [](DisplayListBuilder& b) {
              b.drawVertices(TestVertices1, DlBlendMode::kDstIn);
            }},
           {1, 112, 1, 16,
            [](DisplayListBuilder& b) {
              b.drawVertices(TestVertices2, DlBlendMode::kSrcIn);
            }},
       }},
      {"DrawImage",
       {
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage1, {10, 10}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage1, {10, 10}, kNearestSampling, true);
            }},
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage1, {20, 10}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage1, {10, 20}, kNearestSampling, false);
            }},
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage1, {10, 10}, kLinearSampling, false);
            }},
           {1, 24, -1, 48,
            [](DisplayListBuilder& b) {
              b.drawImage(TestImage2, {10, 10}, kNearestSampling, false);
            }},
       }},
      {"DrawImageRect",
       {
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kNearestSampling, false);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kNearestSampling, true);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(
                  TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                  kNearestSampling, false,
                  SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                              kNearestSampling, false);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                              kNearestSampling, false);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              kLinearSampling, false);
            }},
           {1, 56, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageRect(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                              kNearestSampling, false);
            }},
       }},
      {"DrawImageNine",
       {
           // SkVanvas::drawImageNine is immediately converted to
           // drawImageLattice
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, true);
            }},
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                              DlFilterMode::kNearest, false);
            }},
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                              DlFilterMode::kLinear, false);
            }},
           {1, 48, -1, 80,
            [](DisplayListBuilder& b) {
              b.drawImageNine(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                              DlFilterMode::kNearest, false);
            }},
       }},
      {"DrawImageLattice",
       {
           // Lattice:
           // const int*      fXDivs;     //!< x-axis values dividing bitmap
           // const int*      fYDivs;     //!< y-axis values dividing bitmap
           // const RectType* fRectTypes; //!< array of fill types
           // int             fXCount;    //!< number of x-coordinates
           // int             fYCount;    //!< number of y-coordinates
           // const SkIRect*  fBounds;    //!< source bounds to draw from
           // const SkColor*  fColors;    //!< array of colors
           // size = 64 + fXCount * 4 + fYCount * 4
           // if fColors and fRectTypes are not null, add (fXCount + 1) *
           // (fYCount + 1) * 5
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kNearest, false);
            }},
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 45}, DlFilterMode::kNearest, false);
            }},
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs2, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kNearest, false);
            }},
           // One less yDiv does not change the allocation due to 8-byte
           // alignment
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 2, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kNearest, false);
            }},
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kLinear, false);
            }},
           {1, 96, -1, 96,
            [](DisplayListBuilder& b) {
              b.setColor(SK_ColorMAGENTA);
              b.drawImageLattice(
                  TestImage1,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kNearest, true);
            }},
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(
                  TestImage2,
                  {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                  {10, 10, 40, 40}, DlFilterMode::kNearest, false);
            }},
           // Supplying fBounds does not change size because the Op record
           // always includes it
           {1, 88, -1, 88,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(TestImage1,
                                 {kTestDivs1, kTestDivs1, nullptr, 3, 3,
                                  &kTestLatticeSrcRect, nullptr},
                                 {10, 10, 40, 40}, DlFilterMode::kNearest,
                                 false);
            }},
           {1, 128, -1, 128,
            [](DisplayListBuilder& b) {
              b.drawImageLattice(TestImage1,
                                 {kTestDivs3, kTestDivs3, kTestRTypes, 2, 2,
                                  nullptr, kTestLatticeColors},
                                 {10, 10, 40, 40}, DlFilterMode::kNearest,
                                 false);
            }},
       }},
      {"DrawAtlas",
       {
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr, true);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{0, 1, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 25, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kLinearSampling, nullptr, false);
            }},
           {1, 48 + 32 + 8, -1, 48 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              b.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                          DlBlendMode::kDstIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 64 + 32 + 8, -1, 64 + 32 + 32,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static SkRect cull_rect = {0, 0, 200, 200};
              b.drawAtlas(TestImage2, xforms, texs, nullptr, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, &cull_rect,
                          false);
            }},
           {1, 48 + 32 + 8 + 8, -1, 48 + 32 + 32 + 8,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static DlColor colors[] = {DlColor::kBlue(), DlColor::kGreen()};
              b.drawAtlas(TestImage1, xforms, texs, colors, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, nullptr,
                          false);
            }},
           {1, 64 + 32 + 8 + 8, -1, 64 + 32 + 32 + 8,
            [](DisplayListBuilder& b) {
              static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
              static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
              static DlColor colors[] = {DlColor::kBlue(), DlColor::kGreen()};
              static SkRect cull_rect = {0, 0, 200, 200};
              b.drawAtlas(TestImage1, xforms, texs, colors, 2,
                          DlBlendMode::kSrcIn, kNearestSampling, &cull_rect,
                          false);
            }},
       }},
      {"DrawPicture",
       {
           // cv.drawPicture cannot be compared as SkCanvas may inline it
           {1, 16, -1, 16,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture1, nullptr, false);
            }},
           {1, 16, -1, 16,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture2, nullptr, false);
            }},
           {1, 16, -1, 16,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture1, nullptr, true);
            }},
           {1, 56, -1, 56,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture1, &kTestMatrix1, false);
            }},
           {1, 56, -1, 56,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture1, &kTestMatrix2, false);
            }},
           {1, 56, -1, 56,
            [](DisplayListBuilder& b) {
              b.drawPicture(TestPicture1, &kTestMatrix1, true);
            }},
       }},
      {"DrawDisplayList",
       {
           // cv.drawDL does not exist
           {1, 16, -1, 16,
            [](DisplayListBuilder& b) { b.drawDisplayList(TestDisplayList1); }},
           {1, 16, -1, 16,
            [](DisplayListBuilder& b) { b.drawDisplayList(TestDisplayList2); }},
       }},
      {"DrawTextBlob",
       {
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawTextBlob(TestBlob1, 10, 10); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawTextBlob(TestBlob1, 20, 10); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawTextBlob(TestBlob1, 10, 20); }},
           {1, 24, 1, 24,
            [](DisplayListBuilder& b) { b.drawTextBlob(TestBlob2, 10, 10); }},
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
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath2, SK_ColorGREEN, 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath1, SK_ColorBLUE, 1.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath1, SK_ColorGREEN, 2.0, false, 1.0);
            }},
           {1, 32, -1, 32,
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, true, 1.0);
            }},
           {1, 32, -1, 32,
            [](DisplayListBuilder& b) {
              b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, false, 2.5);
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
