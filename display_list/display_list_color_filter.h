// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_

#include "flutter/display_list/display_list_attributes.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_color.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

namespace flutter {

class DlBlendColorFilter;
class DlMatrixColorFilter;

// The DisplayList ColorFilter class. This class implements all of the
// facilities and adheres to the design goals of the |DlAttribute| base
// class.

// An enumerated type for the recognized ColorFilter operations.
// If a custom ColorFilter outside of the recognized types is needed
// then a |kUnknown| type that simply defers to an SkColorFilter is
// provided as a fallback.
enum class DlColorFilterType {
  kBlend,
  kMatrix,
  kSrgbToLinearGamma,
  kLinearToSrgbGamma,
  kUnknown
};

class DlColorFilter
    : public DlAttribute<DlColorFilter, SkColorFilter, DlColorFilterType> {
 public:
  // Return a shared_ptr holding a DlColorFilter representing the indicated
  // Skia SkColorFilter pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkColorFilter.
  static std::shared_ptr<DlColorFilter> From(SkColorFilter* sk_filter);

  // Return a shared_ptr holding a DlColorFilter representing the indicated
  // Skia SkColorFilter pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkColorFilter.
  static std::shared_ptr<DlColorFilter> From(sk_sp<SkColorFilter> sk_filter) {
    return From(sk_filter.get());
  }

  // Return a boolean indicating whether the color filtering operation will
  // modify transparent black. This is typically used to determine if applying
  // the ColorFilter to a temporary saveLayer buffer will turn the surrounding
  // pixels non-transparent and therefore expand the bounds.
  virtual bool modifies_transparent_black() const = 0;

  // Return a boolean indicating whether the color filtering operation can
  // be applied either before or after modulating the pixels with an opacity
  // value without changing the operation.
  virtual bool can_commute_with_opacity() const { return false; }

  // Return a DlBlendColorFilter pointer to this object iff it is a Blend
  // type of ColorFilter, otherwise return nullptr.
  virtual const DlBlendColorFilter* asBlend() const { return nullptr; }

  // Return a DlMatrixColorFilter pointer to this object iff it is a Matrix
  // type of ColorFilter, otherwise return nullptr.
  virtual const DlMatrixColorFilter* asMatrix() const { return nullptr; }

  // asSrgb<->Linear and asUnknown are not needed because they
  // have no properties to query. Their type fully specifies their
  // operation or can be accessed via the common skia_object() method.
};

// The Blend type of ColorFilter which specifies modifying the
// colors as if the color specified in the Blend filter is the
// source color and the color drawn by the rendering operation
// is the destination color. The mode parameter of the Blend
// filter is then used to combine those colors.
class DlBlendColorFilter final : public DlColorFilter {
 public:
  DlBlendColorFilter(DlColor color, DlBlendMode mode)
      : color_(color), mode_(mode) {}
  DlBlendColorFilter(const DlBlendColorFilter& filter)
      : DlBlendColorFilter(filter.color_, filter.mode_) {}
  DlBlendColorFilter(const DlBlendColorFilter* filter)
      : DlBlendColorFilter(filter->color_, filter->mode_) {}

  DlColorFilterType type() const override { return DlColorFilterType::kBlend; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    // Look at blend and color to make a faster determination?
    sk_sp<SkColorFilter> sk_filter = skia_object();
    return sk_filter &&
           sk_filter->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlBlendColorFilter>(this);
  }

  sk_sp<SkColorFilter> skia_object() const override {
    return SkColorFilters::Blend(color_, ToSk(mode_));
  }

  const DlBlendColorFilter* asBlend() const override { return this; }

  DlColor color() const { return color_; }
  DlBlendMode mode() const { return mode_; }

 protected:
  bool equals_(DlColorFilter const& other) const override {
    FML_DCHECK(other.type() == DlColorFilterType::kBlend);
    auto that = static_cast<DlBlendColorFilter const*>(&other);
    return color_ == that->color_ && mode_ == that->mode_;
  }

 private:
  DlColor color_;
  DlBlendMode mode_;
};

// The Matrix type of ColorFilter which runs every pixel drawn by
// the rendering operation [iR,iG,iB,iA] through a vector/matrix
// multiplication, as in:
//
//  [ oR ]   [ m[ 0] m[ 1] m[ 2] m[ 3] m[ 4] ]   [ iR ]
//  [ oG ]   [ m[ 5] m[ 6] m[ 7] m[ 8] m[ 9] ]   [ iG ]
//  [ oB ] = [ m[10] m[11] m[12] m[13] m[14] ] x [ iB ]
//  [ oA ]   [ m[15] m[16] m[17] m[18] m[19] ]   [ iA ]
//                                               [  1 ]
//
// The resulting color [oR,oG,oB,oA] is then clamped to the range of
// valid pixel components before storing in the output.
class DlMatrixColorFilter final : public DlColorFilter {
 public:
  DlMatrixColorFilter(const float matrix[20]) {
    memcpy(matrix_, matrix, sizeof(matrix_));
  }
  DlMatrixColorFilter(const DlMatrixColorFilter& filter)
      : DlMatrixColorFilter(filter.matrix_) {}
  DlMatrixColorFilter(const DlMatrixColorFilter* filter)
      : DlMatrixColorFilter(filter->matrix_) {}

  DlColorFilterType type() const override { return DlColorFilterType::kMatrix; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    // Look at the matrix to make a faster determination?
    // Basically, are the translation components all 0?
    sk_sp<SkColorFilter> sk_filter = skia_object();
    return sk_filter &&
           sk_filter->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  bool can_commute_with_opacity() const override {
    return matrix_[3] == 0 && matrix_[8] == 0 && matrix_[13] == 0 &&
           matrix_[15] == 0 && matrix_[16] == 0 && matrix_[17] == 0 &&
           (matrix_[18] >= 0.0 && matrix_[18] <= 1.0) && matrix_[19] == 0;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlMatrixColorFilter>(this);
  }

  sk_sp<SkColorFilter> skia_object() const override {
    return SkColorFilters::Matrix(matrix_);
  }

  const DlMatrixColorFilter* asMatrix() const override { return this; }

  const float& operator[](int index) const { return matrix_[index]; }
  void get_matrix(float matrix[20]) const {
    memcpy(matrix, matrix_, sizeof(matrix_));
  }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == DlColorFilterType::kMatrix);
    auto that = static_cast<DlMatrixColorFilter const*>(&other);
    return memcmp(matrix_, that->matrix_, sizeof(matrix_)) == 0;
  }

 private:
  float matrix_[20];
};

// The SrgbToLinear type of ColorFilter that applies the inverse of the sRGB
// gamma curve to the rendered pixels.
class DlSrgbToLinearGammaColorFilter final : public DlColorFilter {
 public:
  static const std::shared_ptr<DlSrgbToLinearGammaColorFilter> instance;

  DlSrgbToLinearGammaColorFilter() {}
  DlSrgbToLinearGammaColorFilter(const DlSrgbToLinearGammaColorFilter& filter)
      : DlSrgbToLinearGammaColorFilter() {}
  DlSrgbToLinearGammaColorFilter(const DlSrgbToLinearGammaColorFilter* filter)
      : DlSrgbToLinearGammaColorFilter() {}

  DlColorFilterType type() const override {
    return DlColorFilterType::kSrgbToLinearGamma;
  }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override { return false; }
  bool can_commute_with_opacity() const override { return true; }

  std::shared_ptr<DlColorFilter> shared() const override { return instance; }
  sk_sp<SkColorFilter> skia_object() const override { return sk_filter_; }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == DlColorFilterType::kSrgbToLinearGamma);
    return true;
  }

 private:
  static const sk_sp<SkColorFilter> sk_filter_;
  friend class DlColorFilter;
};

// The LinearToSrgb type of ColorFilter that applies the sRGB gamma curve
// to the rendered pixels.
class DlLinearToSrgbGammaColorFilter final : public DlColorFilter {
 public:
  static const std::shared_ptr<DlLinearToSrgbGammaColorFilter> instance;

  DlLinearToSrgbGammaColorFilter() {}
  DlLinearToSrgbGammaColorFilter(const DlLinearToSrgbGammaColorFilter& filter)
      : DlLinearToSrgbGammaColorFilter() {}
  DlLinearToSrgbGammaColorFilter(const DlLinearToSrgbGammaColorFilter* filter)
      : DlLinearToSrgbGammaColorFilter() {}

  DlColorFilterType type() const override {
    return DlColorFilterType::kLinearToSrgbGamma;
  }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override { return false; }
  bool can_commute_with_opacity() const override { return true; }

  std::shared_ptr<DlColorFilter> shared() const override { return instance; }
  sk_sp<SkColorFilter> skia_object() const override { return sk_filter_; }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == DlColorFilterType::kLinearToSrgbGamma);
    return true;
  }

 private:
  static const sk_sp<SkColorFilter> sk_filter_;
  friend class DlColorFilter;
};

// A wrapper class for a Skia ColorFilter of unknown type. The above 4 types
// are the only types that can be constructed by Flutter using the
// ui.ColorFilter class so this class should be rarely used.
// In fact, now that the DisplayListCanvasRecorder is deleted and the
// Paragraph code talks directly to a DisplayListBuilder, there may be
// no more reasons to maintain this sub-class.
// See: https://github.com/flutter/flutter/issues/121389
class DlUnknownColorFilter final : public DlColorFilter {
 public:
  DlUnknownColorFilter(sk_sp<SkColorFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  DlUnknownColorFilter(const DlUnknownColorFilter& filter)
      : DlUnknownColorFilter(filter.sk_filter_) {}
  DlUnknownColorFilter(const DlUnknownColorFilter* filter)
      : DlUnknownColorFilter(filter->sk_filter_) {}

  DlColorFilterType type() const override {
    return DlColorFilterType::kUnknown;
  }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    return sk_filter_->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlUnknownColorFilter>(this);
  }

  sk_sp<SkColorFilter> skia_object() const override { return sk_filter_; }

  virtual ~DlUnknownColorFilter() = default;

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == DlColorFilterType::kUnknown);
    auto that = static_cast<DlUnknownColorFilter const*>(&other);
    return sk_filter_ == that->sk_filter_;
  }

 private:
  sk_sp<SkColorFilter> sk_filter_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_
