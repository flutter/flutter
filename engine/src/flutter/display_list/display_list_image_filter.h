// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_IMAGE_FILTER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_IMAGE_FILTER_H_

#include "flutter/display_list/display_list_attributes.h"
#include "flutter/display_list/display_list_color_filter.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_tile_mode.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {

// The DisplayList ImageFilter class. This class implements all of the
// facilities and adheres to the design goals of the |DlAttribute| base
// class.
//
// The objects here define operations that can take a location and one or
// more input pixels and produce a color for that output pixel

// An enumerated type for the recognized ImageFilter operations.
// If a custom ImageFilter outside of the recognized types is needed
// then a |kUnknown| type that simply defers to an SkImageFilter is
// provided as a fallback.
enum class DlImageFilterType {
  kBlur,
  kMatrix,
  kComposeFilter,
  kColorFilter,
  kUnknown
};

class DlBlurImageFilter;
class DlMatrixImageFilter;
class DlComposeImageFilter;
class DlColorFilterImageFilter;

class DlImageFilter
    : public DlAttribute<DlImageFilter, SkImageFilter, DlImageFilterType> {
 public:
  // Return a shared_ptr holding a DlImageFilter representing the indicated
  // Skia SkImageFilter pointer.
  //
  // This method can only detect the ColorFilter type of ImageFilter from an
  // analogous SkImageFilter as there are no "asA..." methods for the other
  // types on SkImageFilter.
  static std::shared_ptr<DlImageFilter> From(SkImageFilter* sk_filter);

  // Return a shared_ptr holding a DlImageFilter representing the indicated
  // Skia SkImageFilter pointer.
  //
  // This method can only detect the ColorFilter type of ImageFilter from an
  // analogous SkImageFilter as there are no "asA..." methods for the other
  // types on SkImageFilter.
  static std::shared_ptr<DlImageFilter> From(sk_sp<SkImageFilter> sk_filter) {
    return From(sk_filter.get());
  }

  // Return a DlBlurImageFilter pointer to this object iff it is a Blur
  // type of ImageFilter, otherwise return nullptr.
  virtual const DlBlurImageFilter* asBlur() const { return nullptr; }

  // Return a DlMatrixImageFilter pointer to this object iff it is a Matrix
  // type of ImageFilter, otherwise return nullptr.
  virtual const DlMatrixImageFilter* asMatrix() const { return nullptr; }

  // Return a DlComposeImageFilter pointer to this object iff it is a Compose
  // type of ImageFilter, otherwise return nullptr.
  virtual const DlComposeImageFilter* asCompose() const { return nullptr; }

  // Return a DlColorFilterImageFilter pointer to this object iff it is a
  // ColorFilter type of ImageFilter, otherwise return nullptr.
  virtual const DlColorFilterImageFilter* asColorFilter() const {
    return nullptr;
  }

  // Return a boolean indicating whether the image filtering operation will
  // modify transparent black. This is typically used to determine if applying
  // the ImageFilter to a temporary saveLayer buffer will turn the surrounding
  // pixels non-transparent and therefore expand the bounds.
  virtual bool modifies_transparent_black() const = 0;

  // Return the bounds of the output for this image filtering operation
  // based on the supplied input bounds where both are measured in the local
  // (untransformed) coordinate space.
  //
  // The output bounds parameter must be supplied and the method will either
  // return a pointer to it with the result filled in, or it will return a
  // nullptr if it cannot determine the results.
  virtual SkRect* map_local_bounds(const SkRect& input_bounds,
                                   SkRect& output_bounds) const = 0;

  // Return the device bounds of the output for this image filtering operation
  // based on the supplied input device bounds where both are measured in the
  // pixel coordinate space and relative to the given rendering ctm. The
  // transform matrix is used to adjust the filter parameters for when it
  // is used in a rendering operation (for example, the blur radius of a
  // Blur filter will expand based on the ctm).
  //
  // The output bounds parameter must be supplied and the method will either
  // return a pointer to it with the result filled in, or it will return a
  // nullptr if it cannot determine the results.
  virtual SkIRect* map_device_bounds(const SkIRect& input_bounds,
                                     const SkMatrix& ctm,
                                     SkIRect& output_bounds) const = 0;
};

class DlBlurImageFilter final : public DlImageFilter {
 public:
  DlBlurImageFilter(SkScalar sigma_x, SkScalar sigma_y, DlTileMode tile_mode)
      : sigma_x_(sigma_x), sigma_y_(sigma_y), tile_mode_(tile_mode) {}
  explicit DlBlurImageFilter(const DlBlurImageFilter* filter)
      : DlBlurImageFilter(filter->sigma_x_,
                          filter->sigma_y_,
                          filter->tile_mode_) {}
  explicit DlBlurImageFilter(const DlBlurImageFilter& filter)
      : DlBlurImageFilter(&filter) {}

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlBlurImageFilter>(this);
  }

  DlImageFilterType type() const override { return DlImageFilterType::kBlur; }
  size_t size() const override { return sizeof(*this); }

  const DlBlurImageFilter* asBlur() const override { return this; }

  bool modifies_transparent_black() const override { return false; }

  SkRect* map_local_bounds(const SkRect& input_bounds,
                           SkRect& output_bounds) const override {
    output_bounds = input_bounds.makeOutset(sigma_x_ * 3, sigma_y_ * 3);
    return &output_bounds;
  }

  SkIRect* map_device_bounds(const SkIRect& input_bounds,
                             const SkMatrix& ctm,
                             SkIRect& output_bounds) const override {
    SkVector device_sigma = ctm.mapVector(sigma_x_, sigma_y_);
    if (!SkScalarIsFinite(device_sigma.fX)) {
      device_sigma.fX = 0;
    }
    if (!SkScalarIsFinite(device_sigma.fY)) {
      device_sigma.fY = 0;
    }
    output_bounds = input_bounds.makeOutset(ceil(abs(device_sigma.fX)),
                                            ceil(abs(device_sigma.fY)));
    return &output_bounds;
  }

  SkScalar sigma_x() const { return sigma_x_; }
  SkScalar sigma_y() const { return sigma_y_; }
  DlTileMode tile_mode() const { return tile_mode_; }

  sk_sp<SkImageFilter> skia_object() const override {
    return SkImageFilters::Blur(sigma_x_, sigma_y_, ToSk(tile_mode_), nullptr);
  }

 protected:
  bool equals_(const DlImageFilter& other) const override {
    FML_DCHECK(other.type() == DlImageFilterType::kBlur);
    auto that = static_cast<const DlBlurImageFilter*>(&other);
    return (sigma_x_ == that->sigma_x_ && sigma_y_ == that->sigma_y_ &&
            tile_mode_ == that->tile_mode_);
  }

 private:
  SkScalar sigma_x_;
  SkScalar sigma_y_;
  DlTileMode tile_mode_;
};

class DlMatrixImageFilter final : public DlImageFilter {
 public:
  DlMatrixImageFilter(const SkMatrix& matrix, const SkSamplingOptions& sampling)
      : matrix_(matrix), sampling_(sampling) {}
  explicit DlMatrixImageFilter(const DlMatrixImageFilter* filter)
      : DlMatrixImageFilter(filter->matrix_, filter->sampling_) {}
  explicit DlMatrixImageFilter(const DlMatrixImageFilter& filter)
      : DlMatrixImageFilter(&filter) {}

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlMatrixImageFilter>(this);
  }

  DlImageFilterType type() const override { return DlImageFilterType::kMatrix; }
  size_t size() const override { return sizeof(*this); }

  const SkMatrix& matrix() const { return matrix_; }
  const SkSamplingOptions& sampling() const { return sampling_; }

  const DlMatrixImageFilter* asMatrix() const override { return this; }

  bool modifies_transparent_black() const override { return false; }

  SkRect* map_local_bounds(const SkRect& input_bounds,
                           SkRect& output_bounds) const override {
    output_bounds = matrix_.mapRect(input_bounds);
    return &output_bounds;
  }

  SkIRect* map_device_bounds(const SkIRect& input_bounds,
                             const SkMatrix& ctm,
                             SkIRect& output_bounds) const override {
    SkMatrix matrix;
    if (!ctm.invert(&matrix)) {
      output_bounds = input_bounds;
      return nullptr;
    }
    matrix.postConcat(matrix_);
    matrix.postConcat(ctm);
    SkRect device_rect;
    matrix.mapRect(&device_rect, SkRect::Make(input_bounds));
    output_bounds = device_rect.roundOut();
    return &output_bounds;
  }

  sk_sp<SkImageFilter> skia_object() const override {
    return SkImageFilters::MatrixTransform(matrix_, sampling_, nullptr);
  }

 protected:
  bool equals_(const DlImageFilter& other) const override {
    FML_DCHECK(other.type() == DlImageFilterType::kMatrix);
    auto that = static_cast<const DlMatrixImageFilter*>(&other);
    return (matrix_ == that->matrix_ && sampling_ == that->sampling_);
  }

 private:
  SkMatrix matrix_;
  SkSamplingOptions sampling_;
};

class DlComposeImageFilter final : public DlImageFilter {
 public:
  DlComposeImageFilter(std::shared_ptr<DlImageFilter> outer,
                       std::shared_ptr<DlImageFilter> inner)
      : outer_(std::move(outer)), inner_(std::move(inner)) {}
  DlComposeImageFilter(const DlImageFilter* outer, const DlImageFilter* inner)
      : outer_(outer->shared()), inner_(inner->shared()) {}
  DlComposeImageFilter(const DlImageFilter& outer, const DlImageFilter& inner)
      : DlComposeImageFilter(&outer, &inner) {}
  explicit DlComposeImageFilter(const DlComposeImageFilter* filter)
      : DlComposeImageFilter(filter->outer_, filter->inner_) {}
  explicit DlComposeImageFilter(const DlComposeImageFilter& filter)
      : DlComposeImageFilter(&filter) {}

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlComposeImageFilter>(this);
  }

  DlImageFilterType type() const override {
    return DlImageFilterType::kComposeFilter;
  }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlImageFilter> outer() const { return outer_; }
  std::shared_ptr<DlImageFilter> inner() const { return inner_; }

  const DlComposeImageFilter* asCompose() const override { return this; }

  bool modifies_transparent_black() const override {
    if (inner_ && inner_->modifies_transparent_black()) {
      return true;
    }
    if (outer_ && outer_->modifies_transparent_black()) {
      return true;
    }
    return false;
  }

  SkRect* map_local_bounds(const SkRect& input_bounds,
                           SkRect& output_bounds) const override {
    SkRect* ret = &output_bounds;
    if (inner_) {
      if (!inner_->map_local_bounds(input_bounds, output_bounds)) {
        ret = nullptr;
      }
    }
    if (ret && outer_) {
      if (!outer_->map_local_bounds(input_bounds, output_bounds)) {
        ret = nullptr;
      }
    }
    if (!ret) {
      output_bounds = input_bounds;
    }
    return ret;
  }

  SkIRect* map_device_bounds(const SkIRect& input_bounds,
                             const SkMatrix& ctm,
                             SkIRect& output_bounds) const override {
    SkIRect* ret = &output_bounds;
    if (inner_) {
      if (!inner_->map_device_bounds(input_bounds, ctm, output_bounds)) {
        ret = nullptr;
      }
    }
    if (ret && outer_) {
      if (!outer_->map_device_bounds(input_bounds, ctm, output_bounds)) {
        ret = nullptr;
      }
    }
    if (!ret) {
      output_bounds = input_bounds;
    }
    return ret;
  }

  sk_sp<SkImageFilter> skia_object() const override {
    return SkImageFilters::Compose(outer_->skia_object(),
                                   inner_->skia_object());
  }

 protected:
  bool equals_(const DlImageFilter& other) const override {
    FML_DCHECK(other.type() == DlImageFilterType::kComposeFilter);
    auto that = static_cast<const DlComposeImageFilter*>(&other);
    return (Equals(outer_, that->outer_) && Equals(inner_, that->inner_));
  }

 private:
  std::shared_ptr<DlImageFilter> outer_;
  std::shared_ptr<DlImageFilter> inner_;
};

class DlColorFilterImageFilter final : public DlImageFilter {
 public:
  explicit DlColorFilterImageFilter(std::shared_ptr<DlColorFilter> filter)
      : color_filter_(std::move(filter)) {}
  explicit DlColorFilterImageFilter(const DlColorFilter* filter)
      : color_filter_(filter->shared()) {}
  explicit DlColorFilterImageFilter(const DlColorFilter& filter)
      : color_filter_(filter.shared()) {}
  explicit DlColorFilterImageFilter(const DlColorFilterImageFilter* filter)
      : DlColorFilterImageFilter(filter->color_filter_) {}
  explicit DlColorFilterImageFilter(const DlColorFilterImageFilter& filter)
      : DlColorFilterImageFilter(&filter) {}

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlColorFilterImageFilter>(color_filter_);
  }

  DlImageFilterType type() const override {
    return DlImageFilterType::kColorFilter;
  }
  size_t size() const override { return sizeof(*this); }

  const std::shared_ptr<DlColorFilter> color_filter() const {
    return color_filter_;
  }

  const DlColorFilterImageFilter* asColorFilter() const override {
    return this;
  }

  bool modifies_transparent_black() const override {
    if (color_filter_) {
      return color_filter_->modifies_transparent_black();
    }
    return false;
  }

  SkRect* map_local_bounds(const SkRect& input_bounds,
                           SkRect& output_bounds) const override {
    output_bounds = input_bounds;
    return modifies_transparent_black() ? nullptr : &output_bounds;
  }

  SkIRect* map_device_bounds(const SkIRect& input_bounds,
                             const SkMatrix& ctm,
                             SkIRect& output_bounds) const override {
    output_bounds = input_bounds;
    return modifies_transparent_black() ? nullptr : &output_bounds;
  }

  sk_sp<SkImageFilter> skia_object() const override {
    return SkImageFilters::ColorFilter(color_filter_->skia_object(), nullptr);
  }

 protected:
  bool equals_(const DlImageFilter& other) const override {
    FML_DCHECK(other.type() == DlImageFilterType::kColorFilter);
    auto that = static_cast<const DlColorFilterImageFilter*>(&other);
    return Equals(color_filter_, that->color_filter_);
  }

 private:
  std::shared_ptr<DlColorFilter> color_filter_;
};

// A wrapper class for a Skia ImageFilter of unknown type. The above 4 types
// are the only types that can be constructed by Flutter using the
// ui.ImageFilter class so this class should be rarely used. The main use
// would come from the |DisplayListCanvasRecorder| recording Skia rendering
// calls that originated outside of the Flutter dart code. This would
// primarily happen in the Paragraph code that renders the text using the
// SkCanvas interface which we capture into DisplayList data structures.
class DlUnknownImageFilter final : public DlImageFilter {
 public:
  explicit DlUnknownImageFilter(sk_sp<SkImageFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  explicit DlUnknownImageFilter(const SkImageFilter* sk_filter)
      : sk_filter_(sk_ref_sp(sk_filter)) {}
  explicit DlUnknownImageFilter(const DlUnknownImageFilter* filter)
      : DlUnknownImageFilter(filter->sk_filter_) {}
  explicit DlUnknownImageFilter(const DlUnknownImageFilter& filter)
      : DlUnknownImageFilter(&filter) {}

  DlImageFilterType type() const override {
    return DlImageFilterType::kUnknown;
  }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlUnknownImageFilter>(this);
  }

  bool modifies_transparent_black() const override {
    if (!sk_filter_) {
      return false;
    }
    return !sk_filter_->canComputeFastBounds();
  }

  SkRect* map_local_bounds(const SkRect& input_bounds,
                           SkRect& output_bounds) const override {
    output_bounds = input_bounds;
    if (modifies_transparent_black()) {
      return nullptr;
    }
    output_bounds = sk_filter_->computeFastBounds(input_bounds);
    return &output_bounds;
  }

  SkIRect* map_device_bounds(const SkIRect& input_bounds,
                             const SkMatrix& ctm,
                             SkIRect& output_bounds) const override {
    output_bounds = input_bounds;
    if (modifies_transparent_black()) {
      return nullptr;
    }
    output_bounds = sk_filter_->filterBounds(
        input_bounds, ctm, SkImageFilter::kForward_MapDirection);
    return &output_bounds;
  }

  sk_sp<SkImageFilter> skia_object() const override { return sk_filter_; }

  virtual ~DlUnknownImageFilter() = default;

 protected:
  bool equals_(const DlImageFilter& other) const override {
    FML_DCHECK(other.type() == DlImageFilterType::kUnknown);
    auto that = static_cast<DlUnknownImageFilter const*>(&other);
    return sk_filter_ == that->sk_filter_;
  }

 private:
  sk_sp<SkImageFilter> sk_filter_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_IMAGE_FILTER_H_
