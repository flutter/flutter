// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_SKIA_DL_SK_PAINT_DISPATCHER_H_
#define FLUTTER_DISPLAY_LIST_SKIA_DL_SK_PAINT_DISPATCHER_H_

#include "flutter/display_list/dl_op_receiver.h"

namespace flutter {

// A utility class that will monitor the DlOpReceiver methods relating
// to the rendering attributes and accumulate them into an SkPaint
// which can be accessed at any time via paint().
class DlSkPaintDispatchHelper : public virtual DlOpReceiver {
 public:
  DlSkPaintDispatchHelper(SkScalar opacity = SK_Scalar1)
      : current_color_(SK_ColorBLACK), opacity_(opacity) {
    if (opacity < SK_Scalar1) {
      paint_.setAlphaf(opacity);
    }
  }

  void setAntiAlias(bool aa) override;
  void setDither(bool dither) override;
  void setDrawStyle(DlDrawStyle style) override;
  void setColor(DlColor color) override;
  void setStrokeWidth(SkScalar width) override;
  void setStrokeMiter(SkScalar limit) override;
  void setStrokeCap(DlStrokeCap cap) override;
  void setStrokeJoin(DlStrokeJoin join) override;
  void setColorSource(const DlColorSource* source) override;
  void setColorFilter(const DlColorFilter* filter) override;
  void setInvertColors(bool invert) override;
  void setBlendMode(DlBlendMode mode) override;
  void setPathEffect(const DlPathEffect* effect) override;
  void setMaskFilter(const DlMaskFilter* filter) override;
  void setImageFilter(const DlImageFilter* filter) override;

  const SkPaint& paint() {
    // On the Impeller backend, we will only support dithering of *gradients*,
    // and it will be enabled by default (without the option to disable it).
    // Until Skia support is completely removed, we only want to respect the
    // dither flag for gradients (otherwise it will also apply to, for
    // example, images, which is not supported in Impeller).
    //
    // See https://github.com/flutter/flutter/issues/112498.
    paint_.setDither(color_source_gradient_ && dither_);
    return paint_;
  }

  /// Returns the current opacity attribute which is used to reduce
  /// the alpha of all setColor calls encountered in the streeam
  SkScalar opacity() { return opacity_; }
  /// Returns the combined opacity that includes both the current
  /// opacity attribute and the alpha of the most recent color.
  /// The most recently set color will have combined the two and
  /// stored the combined value in the alpha of the paint.
  SkScalar combined_opacity() { return paint_.getAlphaf(); }
  /// Returns true iff the current opacity attribute is not opaque,
  /// irrespective of the alpha of the current color
  bool has_opacity() { return opacity_ < SK_Scalar1; }

 protected:
  void save_opacity(SkScalar opacity_for_children);
  void restore_opacity();

 private:
  SkPaint paint_;
  bool color_source_gradient_ = false;
  bool dither_ = false;
  bool invert_colors_ = false;
  sk_sp<SkColorFilter> sk_color_filter_;

  sk_sp<SkColorFilter> makeColorFilter() const;

  struct SaveInfo {
    SaveInfo(SkScalar opacity) : opacity(opacity) {}

    SkScalar opacity;
  };
  std::vector<SaveInfo> save_stack_;

  void set_opacity(SkScalar opacity) {
    if (opacity_ != opacity) {
      opacity_ = opacity;
      setColor(current_color_);
    }
  }

  SkColor current_color_;
  SkScalar opacity_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_SKIA_DL_SK_PAINT_DISPATCHER_H_
