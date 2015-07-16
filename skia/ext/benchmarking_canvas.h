// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_BENCHMARKING_CANVAS_H_
#define SKIA_EXT_BENCHMARKING_CANVAS_H_

#include "base/values.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

class SkXfermode;

namespace skia {

class SK_API BenchmarkingCanvas : public SkNWayCanvas {
public:
  BenchmarkingCanvas(SkCanvas* canvas, unsigned flags = 0);
  ~BenchmarkingCanvas() override;

  enum Flags {
      kOverdrawVisualization_Flag = 0x01,
  };

  // Returns the number of draw commands executed on this canvas.
  size_t CommandCount() const;

  // Returns the list of executed draw commands.
  const base::ListValue& Commands() const;

  // Return the recorded render time (milliseconds) for a draw command index.
  double GetTime(size_t index);

protected:
  // SkCanvas overrides
  void willSave() override;
  SaveLayerStrategy willSaveLayer(const SkRect*,
                                  const SkPaint*,
                                  SaveFlags) override;
  void willRestore() override;

  void didConcat(const SkMatrix&) override;
  void didSetMatrix(const SkMatrix&) override;

  void onClipRect(const SkRect&, SkRegion::Op, ClipEdgeStyle) override;
  void onClipRRect(const SkRRect&, SkRegion::Op, ClipEdgeStyle) override;
  void onClipPath(const SkPath&, SkRegion::Op, ClipEdgeStyle) override;
  void onClipRegion(const SkRegion&, SkRegion::Op) override;

  void onDrawPaint(const SkPaint&) override;
  void onDrawPoints(PointMode, size_t count, const SkPoint pts[],
                    const SkPaint&) override;
  void onDrawRect(const SkRect&, const SkPaint&) override;
  void onDrawOval(const SkRect&, const SkPaint&) override;
  void onDrawRRect(const SkRRect&, const SkPaint&) override;
  void onDrawDRRect(const SkRRect&, const SkRRect&, const SkPaint&) override;
  void onDrawPath(const SkPath&, const SkPaint&) override;

  void onDrawPicture(const SkPicture*, const SkMatrix*, const SkPaint*) override;

  void onDrawBitmap(const SkBitmap&, SkScalar left, SkScalar top, const SkPaint*) override;
  void onDrawBitmapRect(const SkBitmap&, const SkRect* src, const SkRect& dst,
                        const SkPaint*, DrawBitmapRectFlags flags) override;
  void onDrawImage(const SkImage*, SkScalar left, SkScalar top, const SkPaint*) override;
  void onDrawImageRect(const SkImage*, const SkRect* src, const SkRect& dst,
                       const SkPaint*) override;
  void onDrawBitmapNine(const SkBitmap&, const SkIRect& center, const SkRect& dst,
                        const SkPaint*) override;
  void onDrawSprite(const SkBitmap&, int left, int top, const SkPaint*) override;

  void onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y,
                  const SkPaint&) override;
  void onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[],
                     const SkPaint&) override;
  void onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[],
                      SkScalar constY, const SkPaint&) override;
  void onDrawTextOnPath(const void* text, size_t byteLength, const SkPath& path,
                        const SkMatrix* matrix, const SkPaint&) override;
  void onDrawTextBlob(const SkTextBlob* blob, SkScalar x, SkScalar y,
                      const SkPaint& paint) override;

private:
  typedef SkNWayCanvas INHERITED;

  class AutoOp;

  base::ListValue op_records_;
  unsigned flags_;
  RefPtr<SkXfermode> overdraw_xfermode_;
};

}
#endif // SKIA_EXT_BENCHMARKING_CANVAS_H
