// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_PAINT_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_PAINT_H_

#include <memory>
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_color.h"
#include "flutter/display_list/display_list_color_filter.h"
#include "flutter/display_list/display_list_color_source.h"
#include "flutter/display_list/display_list_image_filter.h"
#include "flutter/display_list/display_list_mask_filter.h"
#include "flutter/display_list/display_list_path_effect.h"

namespace flutter {

enum class DlDrawStyle {
  kFill,           //!< fills interior of shapes
  kStroke,         //!< strokes boundary of shapes
  kStrokeAndFill,  //!< both strokes and fills shapes

  kLastStyle = kStrokeAndFill,
  kDefaultStyle = kFill,
};

inline DlDrawStyle ToDl(SkPaint::Style style) {
  return static_cast<DlDrawStyle>(style);
}

inline SkPaint::Style ToSk(DlDrawStyle style) {
  return static_cast<SkPaint::Style>(style);
}

enum class DlStrokeCap {
  kButt,    //!< no stroke extension
  kRound,   //!< adds circle
  kSquare,  //!< adds square

  kLastCap = kSquare,
  kDefaultCap = kButt,
};

inline DlStrokeCap ToDl(SkPaint::Cap cap) {
  return static_cast<DlStrokeCap>(cap);
}

inline SkPaint::Cap ToSk(DlStrokeCap cap) {
  return static_cast<SkPaint::Cap>(cap);
}

enum class DlStrokeJoin {
  kMiter,  //!< extends to miter limit
  kRound,  //!< adds circle
  kBevel,  //!< connects outside edges

  kLastJoin = kBevel,
  kDefaultJoin = kMiter,
};

inline DlStrokeJoin ToDl(SkPaint::Join join) {
  return static_cast<DlStrokeJoin>(join);
}

inline SkPaint::Join ToSk(DlStrokeJoin join) {
  return static_cast<SkPaint::Join>(join);
}

class DlPaint {
 public:
  static constexpr DlColor kDefaultColor = DlColor::kBlack();
  static constexpr float kDefaultWidth = 0.0;
  static constexpr float kDefaultMiter = 4.0;

  DlPaint();

  bool isAntiAlias() const { return isAntiAlias_; }
  DlPaint& setAntiAlias(bool isAntiAlias) {
    isAntiAlias_ = isAntiAlias;
    return *this;
  }

  bool isDither() const { return isDither_; }
  DlPaint& setDither(bool isDither) {
    isDither_ = isDither;
    return *this;
  }

  bool isInvertColors() const { return isInvertColors_; }
  DlPaint& setInvertColors(bool isInvertColors) {
    isInvertColors_ = isInvertColors;
    return *this;
  }

  DlColor getColor() const { return color_; }
  DlPaint& setColor(DlColor color) {
    color_ = color;
    return *this;
  }

  uint8_t getAlpha() const { return color_.argb >> 24; }
  DlPaint& setAlpha(uint8_t alpha) {
    color_.argb = alpha << 24 | (color_.argb & 0x00FFFFFF);
    return *this;
  }

  DlBlendMode getBlendMode() const {
    return static_cast<DlBlendMode>(blendMode_);
  }
  DlPaint& setBlendMode(DlBlendMode mode) {
    blendMode_ = static_cast<unsigned>(mode);
    return *this;
  }

  DlDrawStyle getDrawStyle() const {
    return static_cast<DlDrawStyle>(drawStyle_);
  }
  DlPaint& setDrawStyle(DlDrawStyle style) {
    drawStyle_ = static_cast<unsigned>(style);
    return *this;
  }

  DlStrokeCap getStrokeCap() const {
    return static_cast<DlStrokeCap>(strokeCap_);
  }
  DlPaint& setStrokeCap(DlStrokeCap cap) {
    strokeCap_ = static_cast<unsigned>(cap);
    return *this;
  }

  DlStrokeJoin getStrokeJoin() const {
    return static_cast<DlStrokeJoin>(strokeJoin_);
  }
  DlPaint& setStrokeJoin(DlStrokeJoin join) {
    strokeJoin_ = static_cast<unsigned>(join);
    return *this;
  }

  float getStrokeWidth() const { return strokeWidth_; }
  DlPaint& setStrokeWidth(float width) {
    strokeWidth_ = width;
    return *this;
  }

  float getStrokeMiter() const { return strokeMiter_; }
  DlPaint& setStrokeMiter(float miter) {
    strokeMiter_ = miter;
    return *this;
  }

  std::shared_ptr<const DlColorSource> getColorSource() const {
    return colorSource_;
  }
  const DlColorSource* getColorSourcePtr() const { return colorSource_.get(); }
  DlPaint& setColorSource(std::shared_ptr<const DlColorSource> source) {
    colorSource_ = source;
    return *this;
  }
  DlPaint& setColorSource(const DlColorSource* source) {
    colorSource_ = source ? source->shared() : nullptr;
    return *this;
  }

  std::shared_ptr<const DlColorFilter> getColorFilter() const {
    return colorFilter_;
  }
  const DlColorFilter* getColorFilterPtr() const { return colorFilter_.get(); }
  DlPaint& setColorFilter(std::shared_ptr<DlColorFilter> filter) {
    colorFilter_ = filter ? filter->shared() : nullptr;
    return *this;
  }
  DlPaint& setColorFilter(const DlColorFilter* filter) {
    colorFilter_ = filter ? filter->shared() : nullptr;
    return *this;
  }

  std::shared_ptr<const DlImageFilter> getImageFilter() const {
    return imageFilter_;
  }
  const DlImageFilter* getImageFilterPtr() const { return imageFilter_.get(); }
  DlPaint& setImageFilter(std::shared_ptr<DlImageFilter> filter) {
    imageFilter_ = filter;
    return *this;
  }
  DlPaint& setImageFilter(const DlImageFilter* filter) {
    imageFilter_ = filter ? filter->shared() : nullptr;
    return *this;
  }

  std::shared_ptr<const DlMaskFilter> getMaskFilter() const {
    return maskFilter_;
  }
  const DlMaskFilter* getMaskFilterPtr() const { return maskFilter_.get(); }
  DlPaint& setMaskFilter(std::shared_ptr<DlMaskFilter> filter) {
    maskFilter_ = filter;
    return *this;
  }
  DlPaint& setMaskFilter(const DlMaskFilter* filter) {
    maskFilter_ = filter ? filter->shared() : nullptr;
    return *this;
  }

  std::shared_ptr<const DlPathEffect> getPathEffect() const {
    return pathEffect_;
  }
  const DlPathEffect* getPathEffectPtr() const { return pathEffect_.get(); }
  DlPaint& setPathEffect(std::shared_ptr<DlPathEffect> pathEffect) {
    pathEffect_ = pathEffect;
    return *this;
  }

  bool operator==(DlPaint const& other) const;
  bool operator!=(DlPaint const& other) const { return !(*this == other); }

 private:
#define ASSERT_ENUM_FITS(last_enum, num_bits)                    \
  static_assert(static_cast<int>(last_enum) < (1 << num_bits) && \
                static_cast<int>(last_enum) * 2 >= (1 << num_bits))

  static constexpr int kBlendModeBits = 5;
  static constexpr int kDrawStyleBits = 2;
  static constexpr int kStrokeCapBits = 2;
  static constexpr int kStrokeJoinBits = 2;
  ASSERT_ENUM_FITS(DlBlendMode::kLastMode, kBlendModeBits);
  ASSERT_ENUM_FITS(DlDrawStyle::kLastStyle, kDrawStyleBits);
  ASSERT_ENUM_FITS(DlStrokeCap::kLastCap, kStrokeCapBits);
  ASSERT_ENUM_FITS(DlStrokeJoin::kLastJoin, kStrokeJoinBits);

  union {
    struct {
      unsigned blendMode_ : kBlendModeBits;
      unsigned drawStyle_ : kDrawStyleBits;
      unsigned strokeCap_ : kStrokeCapBits;
      unsigned strokeJoin_ : kStrokeJoinBits;
      unsigned isAntiAlias_ : 1;
      unsigned isDither_ : 1;
      unsigned isInvertColors_ : 1;
    };
  };

  DlColor color_;
  float strokeWidth_;
  float strokeMiter_;

  std::shared_ptr<const DlColorSource> colorSource_;
  std::shared_ptr<const DlColorFilter> colorFilter_;
  std::shared_ptr<const DlImageFilter> imageFilter_;
  std::shared_ptr<const DlMaskFilter> maskFilter_;
  std::shared_ptr<const DlPathEffect> pathEffect_;
  // missing (as compared to SkPaint):
  // DlBlender - not planning on using that object in a pure DisplayList world
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_PAINT_H_
