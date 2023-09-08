// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/color_filter.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/geometry/color.h"

namespace impeller {

/*******************************************************************************
 ******* ColorFilter
 ******************************************************************************/

ColorFilter::ColorFilter() = default;

ColorFilter::~ColorFilter() = default;

std::shared_ptr<ColorFilter> ColorFilter::MakeBlend(BlendMode blend_mode,
                                                    Color color) {
  return std::make_shared<BlendColorFilter>(blend_mode, color);
}

std::shared_ptr<ColorFilter> ColorFilter::MakeMatrix(ColorMatrix color_matrix) {
  return std::make_shared<MatrixColorFilter>(color_matrix);
}

std::shared_ptr<ColorFilter> ColorFilter::MakeSrgbToLinear() {
  return std::make_shared<SrgbToLinearColorFilter>();
}

std::shared_ptr<ColorFilter> ColorFilter::MakeLinearToSrgb() {
  return std::make_shared<LinearToSrgbColorFilter>();
}

/*******************************************************************************
 ******* BlendColorFilter
 ******************************************************************************/

BlendColorFilter::BlendColorFilter(BlendMode blend_mode, Color color)
    : blend_mode_(blend_mode), color_(color) {}

BlendColorFilter::~BlendColorFilter() = default;

std::shared_ptr<ColorFilterContents> BlendColorFilter::WrapWithGPUColorFilter(
    std::shared_ptr<FilterInput> input,
    bool absorb_opacity) const {
  auto filter =
      ColorFilterContents::MakeBlend(blend_mode_, {std::move(input)}, color_);
  filter->SetAbsorbOpacity(absorb_opacity);
  return filter;
}

ColorFilter::ColorFilterProc BlendColorFilter::GetCPUColorFilterProc() const {
  return [filter_blend_mode = blend_mode_, filter_color = color_](Color color) {
    return color.Blend(filter_color, filter_blend_mode);
  };
}

std::shared_ptr<ColorFilter> BlendColorFilter::Clone() const {
  return std::make_shared<BlendColorFilter>(*this);
}

/*******************************************************************************
 ******* MatrixColorFilter
 ******************************************************************************/

MatrixColorFilter::MatrixColorFilter(ColorMatrix color_matrix)
    : color_matrix_(color_matrix) {}

MatrixColorFilter::~MatrixColorFilter() = default;

std::shared_ptr<ColorFilterContents> MatrixColorFilter::WrapWithGPUColorFilter(
    std::shared_ptr<FilterInput> input,
    bool absorb_opacity) const {
  auto filter =
      ColorFilterContents::MakeColorMatrix({std::move(input)}, color_matrix_);
  filter->SetAbsorbOpacity(absorb_opacity);
  return filter;
}

ColorFilter::ColorFilterProc MatrixColorFilter::GetCPUColorFilterProc() const {
  return [color_matrix = color_matrix_](Color color) {
    return color.ApplyColorMatrix(color_matrix);
  };
}

std::shared_ptr<ColorFilter> MatrixColorFilter::Clone() const {
  return std::make_shared<MatrixColorFilter>(*this);
}

/*******************************************************************************
 ******* SrgbToLinearColorFilter
 ******************************************************************************/

SrgbToLinearColorFilter::SrgbToLinearColorFilter() = default;

SrgbToLinearColorFilter::~SrgbToLinearColorFilter() = default;

std::shared_ptr<ColorFilterContents>
SrgbToLinearColorFilter::WrapWithGPUColorFilter(
    std::shared_ptr<FilterInput> input,
    bool absorb_opacity) const {
  auto filter = ColorFilterContents::MakeSrgbToLinearFilter({std::move(input)});
  filter->SetAbsorbOpacity(absorb_opacity);
  return filter;
}

ColorFilter::ColorFilterProc SrgbToLinearColorFilter::GetCPUColorFilterProc()
    const {
  return [](Color color) { return color.SRGBToLinear(); };
}

std::shared_ptr<ColorFilter> SrgbToLinearColorFilter::Clone() const {
  return std::make_shared<SrgbToLinearColorFilter>(*this);
}

/*******************************************************************************
 ******* LinearToSrgbColorFilter
 ******************************************************************************/

LinearToSrgbColorFilter::LinearToSrgbColorFilter() = default;

LinearToSrgbColorFilter::~LinearToSrgbColorFilter() = default;

std::shared_ptr<ColorFilterContents>
LinearToSrgbColorFilter::WrapWithGPUColorFilter(
    std::shared_ptr<FilterInput> input,
    bool absorb_opacity) const {
  auto filter = ColorFilterContents::MakeSrgbToLinearFilter({std::move(input)});
  filter->SetAbsorbOpacity(absorb_opacity);
  return filter;
}

ColorFilter::ColorFilterProc LinearToSrgbColorFilter::GetCPUColorFilterProc()
    const {
  return [](Color color) { return color.LinearToSRGB(); };
}

std::shared_ptr<ColorFilter> LinearToSrgbColorFilter::Clone() const {
  return std::make_shared<LinearToSrgbColorFilter>(*this);
}

}  // namespace impeller
