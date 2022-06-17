// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_SOURCE_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_SOURCE_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_attributes.h"
#include "flutter/display_list/display_list_color.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/display_list_tile_mode.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/effects/SkGradientShader.h"

namespace flutter {

class DlColorColorSource;
class DlImageColorSource;
class DlLinearGradientColorSource;
class DlRadialGradientColorSource;
class DlConicalGradientColorSource;
class DlSweepGradientColorSource;
class DlUnknownColorSource;

// The DisplayList ColorSource class. This class implements all of the
// facilities and adheres to the design goals of the |DlAttribute| base
// class.
//
// The role of the DlColorSource is to provide color information for
// the pixels of a rendering operation. The object is essentially the
// origin of all color being rendered, though its output may be
// modified or transformed by geometric coverage data, the filter
// attributes, and the final blend with the pixels in the destination.

enum class DlColorSourceType {
  kColor,
  kImage,
  kLinearGradient,
  kRadialGradient,
  kConicalGradient,
  kSweepGradient,
  kUnknown
};

class DlColorSource
    : public DlAttribute<DlColorSource, SkShader, DlColorSourceType> {
 public:
  // Return a shared_ptr holding a DlColorSource representing the indicated
  // Skia SkShader pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkShader.
  static std::shared_ptr<DlColorSource> From(SkShader* sk_filter);

  // Return a shared_ptr holding a DlColorFilter representing the indicated
  // Skia SkShader pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkShader.
  static std::shared_ptr<DlColorSource> From(sk_sp<SkShader> sk_filter) {
    return From(sk_filter.get());
  }

  static std::shared_ptr<DlColorSource> MakeLinear(
      const SkPoint start_point,
      const SkPoint end_point,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlColorSource> MakeRadial(
      SkPoint center,
      SkScalar radius,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlColorSource> MakeConical(
      SkPoint start_center,
      SkScalar start_radius,
      SkPoint end_center,
      SkScalar end_radius,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlColorSource> MakeSweep(
      SkPoint center,
      SkScalar start,
      SkScalar end,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  virtual bool is_opaque() const = 0;

  virtual std::shared_ptr<DlColorSource> with_sampling(
      DlImageSampling options) const {
    return shared();
  }

  // Return a DlColorColorSource pointer to this object iff it is an Color
  // type of ColorSource, otherwise return nullptr.
  virtual const DlColorColorSource* asColor() const { return nullptr; }

  // Return a DlImageColorSource pointer to this object iff it is an Image
  // type of ColorSource, otherwise return nullptr.
  virtual const DlImageColorSource* asImage() const { return nullptr; }

  // Return a DlLinearGradientColorSource pointer to this object iff it is a
  // Linear Gradient type of ColorSource, otherwise return nullptr.
  virtual const DlLinearGradientColorSource* asLinearGradient() const {
    return nullptr;
  }

  // Return a DlRadialGradientColorSource pointer to this object iff it is a
  // Radial Gradient type of ColorSource, otherwise return nullptr.
  virtual const DlRadialGradientColorSource* asRadialGradient() const {
    return nullptr;
  }

  // Return a DlConicalGradientColorSource pointer to this object iff it is a
  // Conical Gradient type of ColorSource, otherwise return nullptr.
  virtual const DlConicalGradientColorSource* asConicalGradient() const {
    return nullptr;
  }

  // Return a DlSweepGradientColorSource pointer to this object iff it is a
  // Sweep Gradient type of ColorSource, otherwise return nullptr.
  virtual const DlSweepGradientColorSource* asSweepGradient() const {
    return nullptr;
  }

 protected:
  DlColorSource() = default;

 private:
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlColorSource);
};

class DlColorColorSource final : public DlColorSource {
 public:
  DlColorColorSource(DlColor color) : color_(color) {}

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlColorColorSource>(color_);
  }

  const DlColorColorSource* asColor() const override { return this; }

  DlColorSourceType type() const override { return DlColorSourceType::kColor; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return (color_ >> 24) == 255; }

  DlColor color() const { return color_; }

  sk_sp<SkShader> skia_object() const override {
    return SkShaders::Color(color_);
  }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kColor);
    auto that = static_cast<DlColorColorSource const*>(&other);
    return color_ == that->color_;
  }

 private:
  DlColor color_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlColorColorSource);
};

class DlMatrixColorSourceBase : public DlColorSource {
 public:
  const SkMatrix& matrix() const { return matrix_; }
  const SkMatrix* matrix_ptr() const {
    return matrix_.isIdentity() ? nullptr : &matrix_;
  }

 protected:
  DlMatrixColorSourceBase(const SkMatrix* matrix)
      : matrix_(matrix ? *matrix : SkMatrix::I()) {}

 private:
  const SkMatrix matrix_;
};

class DlImageColorSource final : public SkRefCnt,
                                 public DlMatrixColorSourceBase {
 public:
  // TODO(100984): Color sources must be DlImages instead of SkImages.
  DlImageColorSource(sk_sp<const SkImage> image,
                     DlTileMode horizontal_tile_mode,
                     DlTileMode vertical_tile_mode,
                     DlImageSampling sampling = DlImageSampling::kLinear,
                     const SkMatrix* matrix = nullptr)
      : DlMatrixColorSourceBase(matrix),
        sk_image_(image),
        horizontal_tile_mode_(horizontal_tile_mode),
        vertical_tile_mode_(vertical_tile_mode),
        sampling_(sampling) {}

  const DlImageColorSource* asImage() const override { return this; }

  std::shared_ptr<DlColorSource> shared() const override {
    return with_sampling(sampling_);
  }

  std::shared_ptr<DlColorSource> with_sampling(
      DlImageSampling sampling) const override {
    return std::make_shared<DlImageColorSource>(
        sk_image_, horizontal_tile_mode_, vertical_tile_mode_, sampling,
        matrix_ptr());
  }

  DlColorSourceType type() const override { return DlColorSourceType::kImage; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return sk_image_->isOpaque(); }

  sk_sp<const SkImage> image() const { return sk_image_; }
  DlTileMode horizontal_tile_mode() const { return horizontal_tile_mode_; }
  DlTileMode vertical_tile_mode() const { return vertical_tile_mode_; }
  DlImageSampling sampling() const { return sampling_; }

  virtual sk_sp<SkShader> skia_object() const override {
    return sk_image_->makeShader(ToSk(horizontal_tile_mode_),
                                 ToSk(vertical_tile_mode_), ToSk(sampling_),
                                 matrix_ptr());
  }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kImage);
    auto that = static_cast<DlImageColorSource const*>(&other);
    return (sk_image_ == that->sk_image_ && matrix() == that->matrix() &&
            horizontal_tile_mode_ == that->horizontal_tile_mode_ &&
            vertical_tile_mode_ == that->vertical_tile_mode_ &&
            sampling_ == that->sampling_);
  }

 private:
  sk_sp<const SkImage> sk_image_;
  DlTileMode horizontal_tile_mode_;
  DlTileMode vertical_tile_mode_;
  DlImageSampling sampling_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlImageColorSource);
};

class DlGradientColorSourceBase : public DlMatrixColorSourceBase {
 public:
  bool is_opaque() const override {
    if (mode_ == DlTileMode::kDecal) {
      return false;
    }
    const DlColor* my_colors = colors();
    for (uint32_t i = 0; i < stop_count_; i++) {
      if ((my_colors[i] >> 24) < 255) {
        return false;
      }
    }
    return true;
  }

  DlTileMode tile_mode() const { return mode_; }
  int stop_count() const { return stop_count_; }
  const DlColor* colors() const {
    return reinterpret_cast<const DlColor*>(pod());
  }
  const float* stops() const {
    return reinterpret_cast<const float*>(colors() + stop_count());
  }

 protected:
  DlGradientColorSourceBase(uint32_t stop_count,
                            DlTileMode tile_mode,
                            const SkMatrix* matrix = nullptr)
      : DlMatrixColorSourceBase(matrix),
        mode_(tile_mode),
        stop_count_(stop_count) {}

  size_t vector_sizes() const {
    return stop_count_ * (sizeof(DlColor) + sizeof(float));
  }

  virtual const void* pod() const = 0;

  bool base_equals_(DlGradientColorSourceBase const* other_base) const {
    if (mode_ != other_base->mode_ || matrix() != other_base->matrix() ||
        stop_count_ != other_base->stop_count_) {
      return false;
    }
    static_assert(sizeof(colors()[0]) == 4);
    static_assert(sizeof(stops()[0]) == 4);
    int num_bytes = stop_count_ * 4;
    return (memcmp(colors(), other_base->colors(), num_bytes) == 0 &&
            memcmp(stops(), other_base->stops(), num_bytes) == 0);
  }

  void store_color_stops(void* pod,
                         const DlColor* color_data,
                         const float* stop_data) {
    DlColor* color_storage = reinterpret_cast<DlColor*>(pod);
    memcpy(color_storage, color_data, stop_count_ * sizeof(*color_data));
    float* stop_storage = reinterpret_cast<float*>(color_storage + stop_count_);
    if (stop_data) {
      memcpy(stop_storage, stop_data, stop_count_ * sizeof(*stop_data));
    } else {
      float div = stop_count_ - 1;
      if (div <= 0) {
        div = 1;
      }
      for (uint32_t i = 0; i < stop_count_; i++) {
        stop_storage[i] = i / div;
      }
    }
  }

 private:
  DlTileMode mode_;
  uint32_t stop_count_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlGradientColorSourceBase);
};

class DlLinearGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlLinearGradientColorSource* asLinearGradient() const override {
    return this;
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kLinearGradient;
  }
  size_t size() const override { return sizeof(*this) + vector_sizes(); }

  std::shared_ptr<DlColorSource> shared() const override {
    return MakeLinear(start_point_, end_point_, stop_count(), colors(), stops(),
                      tile_mode(), matrix_ptr());
  }

  const SkPoint& start_point() const { return start_point_; }
  const SkPoint& end_point() const { return end_point_; }

  sk_sp<SkShader> skia_object() const override {
    SkPoint pts[] = {start_point_, end_point_};
    const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors());
    return SkGradientShader::MakeLinear(pts, sk_colors, stops(), stop_count(),
                                        ToSk(tile_mode()), 0, matrix_ptr());
  }

 protected:
  virtual const void* pod() const override { return this + 1; }

  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kLinearGradient);
    auto that = static_cast<DlLinearGradientColorSource const*>(&other);
    return (start_point_ == that->start_point_ &&
            end_point_ == that->end_point_ && base_equals_(that));
  }

 private:
  DlLinearGradientColorSource(const SkPoint start_point,
                              const SkPoint end_point,
                              uint32_t stop_count,
                              const DlColor* colors,
                              const float* stops,
                              DlTileMode tile_mode,
                              const SkMatrix* matrix = nullptr)
      : DlGradientColorSourceBase(stop_count, tile_mode, matrix),
        start_point_(start_point),
        end_point_(end_point) {
    store_color_stops(this + 1, colors, stops);
  }

  DlLinearGradientColorSource(const DlLinearGradientColorSource* source)
      : DlGradientColorSourceBase(source->stop_count(),
                                  source->tile_mode(),
                                  source->matrix_ptr()),
        start_point_(source->start_point()),
        end_point_(source->end_point()) {
    store_color_stops(this + 1, source->colors(), source->stops());
  }

  SkPoint start_point_;
  SkPoint end_point_;

  friend class DlColorSource;
  friend class DisplayListBuilder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlLinearGradientColorSource);
};

class DlRadialGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlRadialGradientColorSource* asRadialGradient() const override {
    return this;
  }

  std::shared_ptr<DlColorSource> shared() const override {
    return MakeRadial(center_, radius_, stop_count(), colors(), stops(),
                      tile_mode(), matrix_ptr());
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kRadialGradient;
  }
  size_t size() const override { return sizeof(*this) + vector_sizes(); }

  SkPoint center() const { return center_; }
  SkScalar radius() const { return radius_; }

  sk_sp<SkShader> skia_object() const override {
    const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors());
    return SkGradientShader::MakeRadial(center_, radius_, sk_colors, stops(),
                                        stop_count(), ToSk(tile_mode()), 0,
                                        matrix_ptr());
  }

 protected:
  virtual const void* pod() const override { return this + 1; }

  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kRadialGradient);
    auto that = static_cast<DlRadialGradientColorSource const*>(&other);
    return (center_ == that->center_ && radius_ == that->radius_ &&
            base_equals_(that));
  }

 private:
  DlRadialGradientColorSource(SkPoint center,
                              SkScalar radius,
                              uint32_t stop_count,
                              const DlColor* colors,
                              const float* stops,
                              DlTileMode tile_mode,
                              const SkMatrix* matrix = nullptr)
      : DlGradientColorSourceBase(stop_count, tile_mode, matrix),
        center_(center),
        radius_(radius) {
    store_color_stops(this + 1, colors, stops);
  }

  DlRadialGradientColorSource(const DlRadialGradientColorSource* source)
      : DlGradientColorSourceBase(source->stop_count(),
                                  source->tile_mode(),
                                  source->matrix_ptr()),
        center_(source->center()),
        radius_(source->radius()) {
    store_color_stops(this + 1, source->colors(), source->stops());
  }

  SkPoint center_;
  SkScalar radius_;

  friend class DlColorSource;
  friend class DisplayListBuilder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlRadialGradientColorSource);
};

class DlConicalGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlConicalGradientColorSource* asConicalGradient() const override {
    return this;
  }

  std::shared_ptr<DlColorSource> shared() const override {
    return MakeConical(start_center_, start_radius_, end_center_, end_radius_,
                       stop_count(), colors(), stops(), tile_mode(),
                       matrix_ptr());
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kConicalGradient;
  }
  size_t size() const override { return sizeof(*this) + vector_sizes(); }

  SkPoint start_center() const { return start_center_; }
  SkScalar start_radius() const { return start_radius_; }
  SkPoint end_center() const { return end_center_; }
  SkScalar end_radius() const { return end_radius_; }

  sk_sp<SkShader> skia_object() const override {
    const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors());
    return SkGradientShader::MakeTwoPointConical(
        start_center_, start_radius_, end_center_, end_radius_, sk_colors,
        stops(), stop_count(), ToSk(tile_mode()), 0, matrix_ptr());
  }

 protected:
  virtual const void* pod() const override { return this + 1; }

  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kConicalGradient);
    auto that = static_cast<DlConicalGradientColorSource const*>(&other);
    return (start_center_ == that->start_center_ &&
            start_radius_ == that->start_radius_ &&
            end_center_ == that->end_center_ &&
            end_radius_ == that->end_radius_ && base_equals_(that));
  }

 private:
  DlConicalGradientColorSource(SkPoint start_center,
                               SkScalar start_radius,
                               SkPoint end_center,
                               SkScalar end_radius,
                               uint32_t stop_count,
                               const DlColor* colors,
                               const float* stops,
                               DlTileMode tile_mode,
                               const SkMatrix* matrix = nullptr)
      : DlGradientColorSourceBase(stop_count, tile_mode, matrix),
        start_center_(start_center),
        start_radius_(start_radius),
        end_center_(end_center),
        end_radius_(end_radius) {
    store_color_stops(this + 1, colors, stops);
  }

  DlConicalGradientColorSource(const DlConicalGradientColorSource* source)
      : DlGradientColorSourceBase(source->stop_count(),
                                  source->tile_mode(),
                                  source->matrix_ptr()),
        start_center_(source->start_center()),
        start_radius_(source->start_radius()),
        end_center_(source->end_center()),
        end_radius_(source->end_radius()) {
    store_color_stops(this + 1, source->colors(), source->stops());
  }

  SkPoint start_center_;
  SkScalar start_radius_;
  SkPoint end_center_;
  SkScalar end_radius_;

  friend class DlColorSource;
  friend class DisplayListBuilder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlConicalGradientColorSource);
};

class DlSweepGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlSweepGradientColorSource* asSweepGradient() const override {
    return this;
  }

  std::shared_ptr<DlColorSource> shared() const override {
    return MakeSweep(center_, start_, end_, stop_count(), colors(), stops(),
                     tile_mode(), matrix_ptr());
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kSweepGradient;
  }
  size_t size() const override { return sizeof(*this) + vector_sizes(); }

  SkPoint center() const { return center_; }
  SkScalar start() const { return start_; }
  SkScalar end() const { return end_; }

  sk_sp<SkShader> skia_object() const override {
    const SkColor* sk_colors = reinterpret_cast<const SkColor*>(colors());
    return SkGradientShader::MakeSweep(center_.x(), center_.y(), sk_colors,
                                       stops(), stop_count(), ToSk(tile_mode()),
                                       start_, end_, 0, matrix_ptr());
  }

 protected:
  virtual const void* pod() const override { return this + 1; }

  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kSweepGradient);
    auto that = static_cast<DlSweepGradientColorSource const*>(&other);
    return (center_ == that->center_ && start_ == that->start_ &&
            end_ == that->end_ && base_equals_(that));
  }

 private:
  DlSweepGradientColorSource(SkPoint center,
                             SkScalar start,
                             SkScalar end,
                             uint32_t stop_count,
                             const DlColor* colors,
                             const float* stops,
                             DlTileMode tile_mode,
                             const SkMatrix* matrix = nullptr)
      : DlGradientColorSourceBase(stop_count, tile_mode, matrix),
        center_(center),
        start_(start),
        end_(end) {
    store_color_stops(this + 1, colors, stops);
  }

  DlSweepGradientColorSource(const DlSweepGradientColorSource* source)
      : DlGradientColorSourceBase(source->stop_count(),
                                  source->tile_mode(),
                                  source->matrix_ptr()),
        center_(source->center()),
        start_(source->start()),
        end_(source->end()) {
    store_color_stops(this + 1, source->colors(), source->stops());
  }

  SkPoint center_;
  SkScalar start_;
  SkScalar end_;

  friend class DlColorSource;
  friend class DisplayListBuilder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlSweepGradientColorSource);
};

class DlUnknownColorSource final : public DlColorSource {
 public:
  DlUnknownColorSource(sk_sp<SkShader> shader) : sk_shader_(shader) {}

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlUnknownColorSource>(sk_shader_);
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kUnknown;
  }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return sk_shader_->isOpaque(); }

  sk_sp<SkShader> skia_object() const override { return sk_shader_; }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kUnknown);
    auto that = static_cast<DlUnknownColorSource const*>(&other);
    return (sk_shader_ == that->sk_shader_);
  }

 private:
  sk_sp<SkShader> sk_shader_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlUnknownColorSource);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_SOURCE_H_
