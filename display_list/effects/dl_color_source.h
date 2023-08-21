// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_DL_COLOR_SOURCE_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_DL_COLOR_SOURCE_H_

#include <memory>
#include <utility>
#include <vector>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_attributes.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_runtime_effect.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/fml/logging.h"

#include "third_party/skia/include/core/SkShader.h"

#ifdef IMPELLER_ENABLE_3D
#include "impeller/geometry/matrix.h"  // nogncheck
#include "impeller/scene/node.h"       // nogncheck
namespace flutter {
class DlSceneColorSource;
}
#endif  // IMPELLER_ENABLE_3D

namespace flutter {

class DlColorColorSource;
class DlImageColorSource;
class DlLinearGradientColorSource;
class DlRadialGradientColorSource;
class DlConicalGradientColorSource;
class DlSweepGradientColorSource;
class DlRuntimeEffectColorSource;

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
  kRuntimeEffect,
#ifdef IMPELLER_ENABLE_3D
  kScene,
#endif  // IMPELLER_ENABLE_3D
};

class DlColorSource : public DlAttribute<DlColorSource, DlColorSourceType> {
 public:
  static std::shared_ptr<DlLinearGradientColorSource> MakeLinear(
      const SkPoint start_point,
      const SkPoint end_point,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlRadialGradientColorSource> MakeRadial(
      SkPoint center,
      SkScalar radius,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlConicalGradientColorSource> MakeConical(
      SkPoint start_center,
      SkScalar start_radius,
      SkPoint end_center,
      SkScalar end_radius,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlSweepGradientColorSource> MakeSweep(
      SkPoint center,
      SkScalar start,
      SkScalar end,
      uint32_t stop_count,
      const DlColor* colors,
      const float* stops,
      DlTileMode tile_mode,
      const SkMatrix* matrix = nullptr);

  static std::shared_ptr<DlRuntimeEffectColorSource> MakeRuntimeEffect(
      sk_sp<DlRuntimeEffect> runtime_effect,
      std::vector<std::shared_ptr<DlColorSource>> samplers,
      std::shared_ptr<std::vector<uint8_t>> uniform_data);

  virtual bool is_opaque() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      If the underlying platform data held by this object is
  ///             held in a way that it can be stored and potentially
  ///             released from the UI thread, this method returns true.
  ///
  /// @return     True if the class has no GPU related resources or if any
  ///             that it holds are held in a thread-safe manner.
  ///
  virtual bool isUIThreadSafe() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      If the underlying platform data represents a gradient.
  ///
  ///             TODO(matanl): Remove this flag when the Skia backend is
  ///             removed, https://github.com/flutter/flutter/issues/112498.
  ///
  /// @return     True if the class represents the output of a gradient.
  ///
  virtual bool isGradient() const { return false; }

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

  virtual const DlRuntimeEffectColorSource* asRuntimeEffect() const {
    return nullptr;
  }

#ifdef IMPELLER_ENABLE_3D
  virtual const DlSceneColorSource* asScene() const { return nullptr; }
#endif  // IMPELLER_ENABLE_3D

 protected:
  DlColorSource() = default;

 private:
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlColorSource);
};

class DlColorColorSource final : public DlColorSource {
 public:
  DlColorColorSource(DlColor color) : color_(color) {}

  bool isUIThreadSafe() const override { return true; }

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlColorColorSource>(color_);
  }

  const DlColorColorSource* asColor() const override { return this; }

  DlColorSourceType type() const override { return DlColorSourceType::kColor; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return (color_ >> 24) == 255; }

  DlColor color() const { return color_; }

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
  DlImageColorSource(sk_sp<const DlImage> image,
                     DlTileMode horizontal_tile_mode,
                     DlTileMode vertical_tile_mode,
                     DlImageSampling sampling = DlImageSampling::kLinear,
                     const SkMatrix* matrix = nullptr)
      : DlMatrixColorSourceBase(matrix),
        image_(image),
        horizontal_tile_mode_(horizontal_tile_mode),
        vertical_tile_mode_(vertical_tile_mode),
        sampling_(sampling) {}

  bool isUIThreadSafe() const override {
    return image_ ? image_->isUIThreadSafe() : true;
  }

  const DlImageColorSource* asImage() const override { return this; }

  std::shared_ptr<DlColorSource> shared() const override {
    return with_sampling(sampling_);
  }

  std::shared_ptr<DlColorSource> with_sampling(DlImageSampling sampling) const {
    return std::make_shared<DlImageColorSource>(image_, horizontal_tile_mode_,
                                                vertical_tile_mode_, sampling,
                                                matrix_ptr());
  }

  DlColorSourceType type() const override { return DlColorSourceType::kImage; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return image_->isOpaque(); }

  sk_sp<const DlImage> image() const { return image_; }
  DlTileMode horizontal_tile_mode() const { return horizontal_tile_mode_; }
  DlTileMode vertical_tile_mode() const { return vertical_tile_mode_; }
  DlImageSampling sampling() const { return sampling_; }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kImage);
    auto that = static_cast<DlImageColorSource const*>(&other);
    return (image_->Equals(that->image_) && matrix() == that->matrix() &&
            horizontal_tile_mode_ == that->horizontal_tile_mode_ &&
            vertical_tile_mode_ == that->vertical_tile_mode_ &&
            sampling_ == that->sampling_);
  }

 private:
  sk_sp<const DlImage> image_;
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

  bool isGradient() const override { return true; }

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

  bool isUIThreadSafe() const override { return true; }

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
  friend class DlOpRecorder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlLinearGradientColorSource);
};

class DlRadialGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlRadialGradientColorSource* asRadialGradient() const override {
    return this;
  }

  bool isUIThreadSafe() const override { return true; }

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
  friend class DlOpRecorder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlRadialGradientColorSource);
};

class DlConicalGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlConicalGradientColorSource* asConicalGradient() const override {
    return this;
  }

  bool isUIThreadSafe() const override { return true; }

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
  friend class DlOpRecorder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlConicalGradientColorSource);
};

class DlSweepGradientColorSource final : public DlGradientColorSourceBase {
 public:
  const DlSweepGradientColorSource* asSweepGradient() const override {
    return this;
  }

  bool isUIThreadSafe() const override { return true; }

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
  friend class DlOpRecorder;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlSweepGradientColorSource);
};

class DlRuntimeEffectColorSource final : public DlColorSource {
 public:
  DlRuntimeEffectColorSource(
      sk_sp<DlRuntimeEffect> runtime_effect,
      std::vector<std::shared_ptr<DlColorSource>> samplers,
      std::shared_ptr<std::vector<uint8_t>> uniform_data)
      : runtime_effect_(std::move(runtime_effect)),
        samplers_(std::move(samplers)),
        uniform_data_(std::move(uniform_data)) {}

  bool isUIThreadSafe() const override {
    for (auto sampler : samplers_) {
      if (!sampler->isUIThreadSafe()) {
        return false;
      }
    }
    return true;
  }

  const DlRuntimeEffectColorSource* asRuntimeEffect() const override {
    return this;
  }

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlRuntimeEffectColorSource>(
        runtime_effect_, samplers_, uniform_data_);
  }

  DlColorSourceType type() const override {
    return DlColorSourceType::kRuntimeEffect;
  }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return false; }

  const sk_sp<DlRuntimeEffect> runtime_effect() const {
    return runtime_effect_;
  }
  const std::vector<std::shared_ptr<DlColorSource>> samplers() const {
    return samplers_;
  }
  const std::shared_ptr<std::vector<uint8_t>> uniform_data() const {
    return uniform_data_;
  }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kRuntimeEffect);
    auto that = static_cast<DlRuntimeEffectColorSource const*>(&other);
    if (runtime_effect_ != that->runtime_effect_) {
      return false;
    }
    if (uniform_data_ != that->uniform_data_) {
      return false;
    }
    if (samplers_.size() != that->samplers_.size()) {
      return false;
    }
    for (size_t i = 0; i < samplers_.size(); i++) {
      if (samplers_[i] != that->samplers_[i]) {
        return false;
      }
    }
    return true;
  }

 private:
  sk_sp<DlRuntimeEffect> runtime_effect_;
  std::vector<std::shared_ptr<DlColorSource>> samplers_;
  std::shared_ptr<std::vector<uint8_t>> uniform_data_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlRuntimeEffectColorSource);
};

#ifdef IMPELLER_ENABLE_3D
class DlSceneColorSource final : public DlColorSource {
 public:
  DlSceneColorSource(std::shared_ptr<impeller::scene::Node> node,
                     impeller::Matrix camera_matrix)
      : node_(std::move(node)), camera_matrix_(camera_matrix) {}

  bool isUIThreadSafe() const override { return true; }

  const DlSceneColorSource* asScene() const override { return this; }

  std::shared_ptr<DlColorSource> shared() const override {
    return std::make_shared<DlSceneColorSource>(node_, camera_matrix_);
  }

  DlColorSourceType type() const override { return DlColorSourceType::kScene; }
  size_t size() const override { return sizeof(*this); }

  bool is_opaque() const override { return false; }

  std::shared_ptr<impeller::scene::Node> scene_node() const { return node_; }

  impeller::Matrix camera_matrix() const { return camera_matrix_; }

 protected:
  bool equals_(DlColorSource const& other) const override {
    FML_DCHECK(other.type() == DlColorSourceType::kScene);
    auto that = static_cast<DlSceneColorSource const*>(&other);
    if (node_ != that->node_) {
      return false;
    }
    return true;
  }

 private:
  std::shared_ptr<impeller::scene::Node> node_;
  impeller::Matrix camera_matrix_;  // the view-projection matrix of the scene.

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlSceneColorSource);
};
#endif  // IMPELLER_ENABLE_3D

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_DL_COLOR_SOURCE_H_
