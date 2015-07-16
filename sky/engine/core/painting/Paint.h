// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINT_H_
#define SKY_ENGINE_CORE_PAINTING_PAINT_H_

#include "sky/engine/core/painting/CanvasColor.h"
#include "sky/engine/core/painting/PaintingStyle.h"
#include "sky/engine/core/painting/TransferMode.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace blink {

class DrawLooper;
class ColorFilter;
class MaskFilter;
class Shader;

class Paint : public RefCounted<Paint>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~Paint() override;
  static PassRefPtr<Paint> create() { return adoptRef(new Paint); }

  bool isAntiAlias() const { return paint_.isAntiAlias(); }
  void setIsAntiAlias(bool value) { paint_.setAntiAlias(value); }

  SkColor color() const { return paint_.getColor(); }
  void setColor(SkColor color) { paint_.setColor(color); }

  SkScalar strokeWidth() const { return paint_.getStrokeWidth(); }
  void setStrokeWidth(SkScalar strokeWidth) {
    paint_.setStrokeWidth(strokeWidth);
  }

  void setDrawLooper(DrawLooper* looper);
  void setColorFilter(ColorFilter* filter);
  void setMaskFilter(MaskFilter* filter);
  void setShader(Shader* shader);
  void setStyle(SkPaint::Style style);
  void setTransferMode(SkXfermode::Mode transfer_mode);

  const SkPaint& paint() const { return paint_; }
  void setPaint(const SkPaint& paint) { paint_ = paint; }

  String toString() const;

 private:
  Paint();

  SkPaint paint_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINT_H_
