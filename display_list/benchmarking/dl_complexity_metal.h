// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKING_DL_COMPLEXITY_METAL_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKING_DL_COMPLEXITY_METAL_H_

#include "flutter/display_list/benchmarking/dl_complexity_helper.h"

namespace flutter {

class DisplayListMetalComplexityCalculator
    : public DisplayListComplexityCalculator {
 public:
  static DisplayListMetalComplexityCalculator* GetInstance();

  unsigned int Compute(const DisplayList* display_list) override {
    MetalHelper helper(ceiling_);
    display_list->Dispatch(helper);
    return helper.ComplexityScore();
  }

  bool ShouldBeCached(unsigned int complexity_score) override {
    // Set cache threshold at 1ms
    return complexity_score > 200000u;
  }

  void SetComplexityCeiling(unsigned int ceiling) override {
    ceiling_ = ceiling;
  }

 private:
  class MetalHelper : public ComplexityCalculatorHelper {
   public:
    MetalHelper(unsigned int ceiling)
        : ComplexityCalculatorHelper(ceiling),
          save_layer_count_(0),
          draw_text_blob_count_(0) {}

    void saveLayer(const SkRect* bounds,
                   const SaveLayerOptions options,
                   const DlImageFilter* backdrop) override;

    void drawLine(const SkPoint& p0, const SkPoint& p1) override;
    void drawRect(const SkRect& rect) override;
    void drawOval(const SkRect& bounds) override;
    void drawCircle(const SkPoint& center, SkScalar radius) override;
    void drawRRect(const SkRRect& rrect) override;
    void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
    void drawPath(const SkPath& path) override;
    void drawArc(const SkRect& oval_bounds,
                 SkScalar start_degrees,
                 SkScalar sweep_degrees,
                 bool use_center) override;
    void drawPoints(DlCanvas::PointMode mode,
                    uint32_t count,
                    const SkPoint points[]) override;
    void drawVertices(const DlVertices* vertices, DlBlendMode mode) override;
    void drawImage(const sk_sp<DlImage> image,
                   const SkPoint point,
                   DlImageSampling sampling,
                   bool render_with_attributes) override;
    void drawImageNine(const sk_sp<DlImage> image,
                       const SkIRect& center,
                       const SkRect& dst,
                       DlFilterMode filter,
                       bool render_with_attributes) override;
    void drawDisplayList(const sk_sp<DisplayList> display_list,
                         SkScalar opacity) override;
    void drawTextBlob(const sk_sp<SkTextBlob> blob,
                      SkScalar x,
                      SkScalar y) override;
    void drawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                       SkScalar x,
                       SkScalar y) override;
    void drawShadow(const SkPath& path,
                    const DlColor color,
                    const SkScalar elevation,
                    bool transparent_occluder,
                    SkScalar dpr) override;

   protected:
    void ImageRect(const SkISize& size,
                   bool texture_backed,
                   bool render_with_attributes,
                   bool enforce_src_edges) override;

    unsigned int BatchedComplexity() override;

   private:
    unsigned int save_layer_count_;
    unsigned int draw_text_blob_count_;
  };

  DisplayListMetalComplexityCalculator()
      : ceiling_(std::numeric_limits<unsigned int>::max()) {}
  static DisplayListMetalComplexityCalculator* instance_;

  unsigned int ceiling_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKING_DL_COMPLEXITY_METAL_H_
