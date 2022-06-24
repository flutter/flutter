// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_CANVAS_H_
#define FLUTTER_LIB_UI_PAINTING_CANVAS_H_

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/picture_recorder.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/vertices.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {
class CanvasImage;

class Canvas : public RefCountedDartWrappable<Canvas>, DisplayListOpFlags {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Canvas);

 public:
  static fml::RefPtr<Canvas> Create(PictureRecorder* recorder,
                                    double left,
                                    double top,
                                    double right,
                                    double bottom);

  ~Canvas() override;

  void save();
  void saveLayerWithoutBounds(const Paint& paint, const PaintData& paint_data);
  void saveLayer(double left,
                 double top,
                 double right,
                 double bottom,
                 const Paint& paint,
                 const PaintData& paint_data);
  void restore();
  int getSaveCount();

  void translate(double dx, double dy);
  void scale(double sx, double sy);
  void rotate(double radians);
  void skew(double sx, double sy);
  void transform(const tonic::Float64List& matrix4);
  void getTransform(tonic::Float64List& matrix4);

  void clipRect(double left,
                double top,
                double right,
                double bottom,
                SkClipOp clipOp,
                bool doAntiAlias = true);
  void clipRRect(const RRect& rrect, bool doAntiAlias = true);
  void clipPath(const CanvasPath* path, bool doAntiAlias = true);
  void getDestinationClipBounds(tonic::Float64List& rect);
  void getLocalClipBounds(tonic::Float64List& rect);

  void drawColor(SkColor color, DlBlendMode blend_mode);
  void drawLine(double x1,
                double y1,
                double x2,
                double y2,
                const Paint& paint,
                const PaintData& paint_data);
  void drawPaint(const Paint& paint, const PaintData& paint_data);
  void drawRect(double left,
                double top,
                double right,
                double bottom,
                const Paint& paint,
                const PaintData& paint_data);
  void drawRRect(const RRect& rrect,
                 const Paint& paint,
                 const PaintData& paint_data);
  void drawDRRect(const RRect& outer,
                  const RRect& inner,
                  const Paint& paint,
                  const PaintData& paint_data);
  void drawOval(double left,
                double top,
                double right,
                double bottom,
                const Paint& paint,
                const PaintData& paint_data);
  void drawCircle(double x,
                  double y,
                  double radius,
                  const Paint& paint,
                  const PaintData& paint_data);
  void drawArc(double left,
               double top,
               double right,
               double bottom,
               double startAngle,
               double sweepAngle,
               bool useCenter,
               const Paint& paint,
               const PaintData& paint_data);
  void drawPath(const CanvasPath* path,
                const Paint& paint,
                const PaintData& paint_data);
  Dart_Handle drawImage(const CanvasImage* image,
                        double x,
                        double y,
                        const Paint& paint,
                        const PaintData& paint_data,
                        int filterQualityIndex);
  Dart_Handle drawImageRect(const CanvasImage* image,
                            double src_left,
                            double src_top,
                            double src_right,
                            double src_bottom,
                            double dst_left,
                            double dst_top,
                            double dst_right,
                            double dst_bottom,
                            const Paint& paint,
                            const PaintData& paint_data,
                            int filterQualityIndex);
  Dart_Handle drawImageNine(const CanvasImage* image,
                            double center_left,
                            double center_top,
                            double center_right,
                            double center_bottom,
                            double dst_left,
                            double dst_top,
                            double dst_right,
                            double dst_bottom,
                            const Paint& paint,
                            const PaintData& paint_data,
                            int bitmapSamplingIndex);
  void drawPicture(Picture* picture);

  // The paint argument is first for the following functions because Paint
  // unwraps a number of C++ objects. Once we create a view unto a
  // Float32List, we cannot re-enter the VM to unwrap objects. That means we
  // either need to process the paint argument first.

  void drawPoints(const Paint& paint,
                  const PaintData& paint_data,
                  SkCanvas::PointMode point_mode,
                  const tonic::Float32List& points);

  void drawVertices(const Vertices* vertices,
                    DlBlendMode blend_mode,
                    const Paint& paint,
                    const PaintData& paint_data);

  Dart_Handle drawAtlas(const Paint& paint,
                        const PaintData& paint_data,
                        int filterQualityIndex,
                        CanvasImage* atlas,
                        tonic::Float32List& transforms,
                        tonic::Float32List& rects,
                        tonic::Int32List& colors,
                        DlBlendMode blend_mode,
                        tonic::Float32List& cull_rect);

  void drawShadow(const CanvasPath* path,
                  SkColor color,
                  double elevation,
                  bool transparentOccluder);

  SkCanvas* canvas() const { return canvas_; }
  void Invalidate();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit Canvas(SkCanvas* canvas);

  // The SkCanvas is supplied by a call to SkPictureRecorder::beginRecording,
  // which does not transfer ownership.  For this reason, we hold a raw
  // pointer and manually set to null in Clear.
  SkCanvas* canvas_;

  // A copy of the recorder used by the SkCanvas->DisplayList adapter for cases
  // where we cannot record the SkCanvas method call through the various OnOp()
  // virtual methods or where we can be more efficient by talking directly in
  // the DisplayList operation lexicon. The recorder has a method for recording
  // paint attributes from an SkPaint and an operation type as well as access
  // to the raw DisplayListBuilder for emitting custom rendering operations.
  sk_sp<DisplayListCanvasRecorder> display_list_recorder_;
  DisplayListBuilder* builder() {
    return display_list_recorder_->builder().get();
  }
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_CANVAS_H_
