// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/image_filter.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

/*******************************************************************************
 ******* ImageFilter
 ******************************************************************************/

ImageFilter::ImageFilter() = default;

ImageFilter::~ImageFilter() = default;

std::shared_ptr<ImageFilter> ImageFilter::MakeBlur(
    Sigma sigma_x,
    Sigma sigma_y,
    FilterContents::BlurStyle blur_style,
    Entity::TileMode tile_mode) {
  return std::make_shared<BlurImageFilter>(sigma_x, sigma_y, blur_style,
                                           tile_mode);
}

std::shared_ptr<ImageFilter> ImageFilter::MakeDilate(Radius radius_x,
                                                     Radius radius_y) {
  return std::make_shared<DilateImageFilter>(radius_x, radius_y);
}

std::shared_ptr<ImageFilter> ImageFilter::MakeErode(Radius radius_x,
                                                    Radius radius_y) {
  return std::make_shared<ErodeImageFilter>(radius_x, radius_y);
}

std::shared_ptr<ImageFilter> ImageFilter::MakeMatrix(
    const Matrix& matrix,
    SamplerDescriptor sampler_descriptor) {
  return std::make_shared<MatrixImageFilter>(matrix,
                                             std::move(sampler_descriptor));
}

std::shared_ptr<ImageFilter> ImageFilter::MakeCompose(
    const ImageFilter& inner,
    const ImageFilter& outer) {
  return std::make_shared<ComposeImageFilter>(inner, outer);
}

std::shared_ptr<ImageFilter> ImageFilter::MakeFromColorFilter(
    const ColorFilter& color_filter) {
  return std::make_shared<ColorImageFilter>(color_filter);
}

std::shared_ptr<ImageFilter> ImageFilter::MakeLocalMatrix(
    const Matrix& matrix,
    const ImageFilter& internal_filter) {
  return std::make_shared<LocalMatrixImageFilter>(matrix, internal_filter);
}

std::shared_ptr<FilterContents> ImageFilter::GetFilterContents() const {
  return WrapInput(FilterInput::Make(Rect()));
}

/*******************************************************************************
 ******* BlurImageFilter
 ******************************************************************************/

BlurImageFilter::BlurImageFilter(Sigma sigma_x,
                                 Sigma sigma_y,
                                 FilterContents::BlurStyle blur_style,
                                 Entity::TileMode tile_mode)
    : sigma_x_(sigma_x),
      sigma_y_(sigma_y),
      blur_style_(blur_style),
      tile_mode_(tile_mode) {}

BlurImageFilter::~BlurImageFilter() = default;

std::shared_ptr<FilterContents> BlurImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return FilterContents::MakeGaussianBlur(input, sigma_x_, sigma_y_, tile_mode_,
                                          blur_style_);
}

std::shared_ptr<ImageFilter> BlurImageFilter::Clone() const {
  return std::make_shared<BlurImageFilter>(*this);
}

/*******************************************************************************
 ******* DilateImageFilter
 ******************************************************************************/

DilateImageFilter::DilateImageFilter(Radius radius_x, Radius radius_y)
    : radius_x_(radius_x), radius_y_(radius_y) {}

DilateImageFilter::~DilateImageFilter() = default;

std::shared_ptr<FilterContents> DilateImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return FilterContents::MakeMorphology(input, radius_x_, radius_y_,
                                        FilterContents::MorphType::kDilate);
}

std::shared_ptr<ImageFilter> DilateImageFilter::Clone() const {
  return std::make_shared<DilateImageFilter>(*this);
}

/*******************************************************************************
 ******* ErodeImageFilter
 ******************************************************************************/

ErodeImageFilter::ErodeImageFilter(Radius radius_x, Radius radius_y)
    : radius_x_(radius_x), radius_y_(radius_y) {}

ErodeImageFilter::~ErodeImageFilter() = default;

std::shared_ptr<FilterContents> ErodeImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return FilterContents::MakeMorphology(input, radius_x_, radius_y_,
                                        FilterContents::MorphType::kErode);
}

std::shared_ptr<ImageFilter> ErodeImageFilter::Clone() const {
  return std::make_shared<ErodeImageFilter>(*this);
}

/*******************************************************************************
 ******* MatrixImageFilter
 ******************************************************************************/

MatrixImageFilter::MatrixImageFilter(const Matrix& matrix,
                                     SamplerDescriptor sampler_descriptor)
    : matrix_(matrix), sampler_descriptor_(std::move(sampler_descriptor)) {}

MatrixImageFilter::~MatrixImageFilter() = default;

std::shared_ptr<FilterContents> MatrixImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return FilterContents::MakeMatrixFilter(input, matrix_, sampler_descriptor_);
}

std::shared_ptr<ImageFilter> MatrixImageFilter::Clone() const {
  return std::make_shared<MatrixImageFilter>(*this);
}

/*******************************************************************************
 ******* ComposeImageFilter
 ******************************************************************************/

ComposeImageFilter::ComposeImageFilter(const ImageFilter& inner,
                                       const ImageFilter& outer)
    : inner_(inner.Clone()), outer_(outer.Clone()) {}

ComposeImageFilter::~ComposeImageFilter() = default;

std::shared_ptr<FilterContents> ComposeImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return outer_->WrapInput(FilterInput::Make(inner_->WrapInput(input)));
}

std::shared_ptr<ImageFilter> ComposeImageFilter::Clone() const {
  return std::make_shared<ComposeImageFilter>(*this);
}

/*******************************************************************************
 ******* ColorImageFilter
 ******************************************************************************/

ColorImageFilter::ColorImageFilter(const ColorFilter& color_filter)
    : color_filter_(color_filter.Clone()) {}

ColorImageFilter::~ColorImageFilter() = default;

std::shared_ptr<FilterContents> ColorImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return color_filter_->WrapWithGPUColorFilter(
      input, ColorFilterContents::AbsorbOpacity::kNo);
}

std::shared_ptr<ImageFilter> ColorImageFilter::Clone() const {
  return std::make_shared<ColorImageFilter>(*this);
}

/*******************************************************************************
 ******* LocalMatrixImageFilter
 ******************************************************************************/

LocalMatrixImageFilter::LocalMatrixImageFilter(
    const Matrix& matrix,
    const ImageFilter& internal_filter)
    : matrix_(matrix), internal_filter_(internal_filter.Clone()) {}

LocalMatrixImageFilter::~LocalMatrixImageFilter() = default;

std::shared_ptr<FilterContents> LocalMatrixImageFilter::WrapInput(
    const FilterInput::Ref& input) const {
  return FilterContents::MakeLocalMatrixFilter(
      FilterInput::Make(internal_filter_->WrapInput(input)), matrix_);
}

std::shared_ptr<ImageFilter> LocalMatrixImageFilter::Clone() const {
  return std::make_shared<LocalMatrixImageFilter>(*this);
}

}  // namespace impeller
