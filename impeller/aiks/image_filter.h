// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/aiks/color_filter.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/sigma.h"

namespace impeller {

struct Paint;

/*******************************************************************************
 ******* ImageFilter
 ******************************************************************************/

class ImageFilter {
 public:
  ImageFilter();

  virtual ~ImageFilter();

  static std::shared_ptr<ImageFilter> MakeBlur(
      Sigma sigma_x,
      Sigma sigma_y,
      FilterContents::BlurStyle blur_style,
      Entity::TileMode tile_mode);

  static std::shared_ptr<ImageFilter> MakeDilate(Radius radius_x,
                                                 Radius radius_y);

  static std::shared_ptr<ImageFilter> MakeErode(Radius radius_x,
                                                Radius radius_y);

  static std::shared_ptr<ImageFilter> MakeMatrix(
      const Matrix& matrix,
      SamplerDescriptor sampler_descriptor);

  static std::shared_ptr<ImageFilter> MakeCompose(const ImageFilter& inner,
                                                  const ImageFilter& outer);

  static std::shared_ptr<ImageFilter> MakeFromColorFilter(
      const ColorFilter& color_filter);

  static std::shared_ptr<ImageFilter> MakeLocalMatrix(
      const Matrix& matrix,
      const ImageFilter& internal_filter);

  /// @brief  Generate a new FilterContents using this filter's configuration.
  ///
  ///         This is the same as WrapInput, except no input is set. The input
  ///         for the filter chain can be set later using.
  ///         FilterContents::SetLeafInputs().
  ///
  /// @see    `FilterContents::SetLeafInputs`
  std::shared_ptr<FilterContents> GetFilterContents() const;

  /// @brief  Wraps the given filter input with a GPU-based image filter.
  virtual std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const = 0;

  virtual std::shared_ptr<ImageFilter> Clone() const = 0;
};

/*******************************************************************************
 ******* BlurImageFilter
 ******************************************************************************/

class BlurImageFilter : public ImageFilter {
 public:
  BlurImageFilter(Sigma sigma_x,
                  Sigma sigma_y,
                  FilterContents::BlurStyle blur_style,
                  Entity::TileMode tile_mode);

  ~BlurImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  Sigma sigma_x_;
  Sigma sigma_y_;
  FilterContents::BlurStyle blur_style_;
  Entity::TileMode tile_mode_;
};

/*******************************************************************************
 ******* DilateImageFilter
 ******************************************************************************/

class DilateImageFilter : public ImageFilter {
 public:
  DilateImageFilter(Radius radius_x, Radius radius_y);

  ~DilateImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  Radius radius_x_;
  Radius radius_y_;
};

/*******************************************************************************
 ******* ErodeImageFilter
 ******************************************************************************/

class ErodeImageFilter : public ImageFilter {
 public:
  ErodeImageFilter(Radius radius_x, Radius radius_y);

  ~ErodeImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  Radius radius_x_;
  Radius radius_y_;
};

/*******************************************************************************
 ******* MatrixImageFilter
 ******************************************************************************/

class MatrixImageFilter : public ImageFilter {
 public:
  MatrixImageFilter(const Matrix& matrix, SamplerDescriptor sampler_descriptor);

  ~MatrixImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  Matrix matrix_;
  SamplerDescriptor sampler_descriptor_;
};

/*******************************************************************************
 ******* ComposeImageFilter
 ******************************************************************************/

class ComposeImageFilter : public ImageFilter {
 public:
  ComposeImageFilter(const ImageFilter& inner, const ImageFilter& outer);

  ~ComposeImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  std::shared_ptr<ImageFilter> inner_;
  std::shared_ptr<ImageFilter> outer_;
};

/*******************************************************************************
 ******* ColorImageFilter
 ******************************************************************************/

class ColorImageFilter : public ImageFilter {
 public:
  explicit ColorImageFilter(const ColorFilter& color_filter);

  ~ColorImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  std::shared_ptr<ColorFilter> color_filter_;
};

/*******************************************************************************
 ******* LocalMatrixImageFilter
 ******************************************************************************/

class LocalMatrixImageFilter : public ImageFilter {
 public:
  LocalMatrixImageFilter(const Matrix& matrix,
                         const ImageFilter& internal_filter);

  ~LocalMatrixImageFilter() override;

  // |ImageFilter|
  std::shared_ptr<FilterContents> WrapInput(
      const FilterInput::Ref& input) const override;

  // |ImageFilter|
  std::shared_ptr<ImageFilter> Clone() const override;

 private:
  Matrix matrix_;
  std::shared_ptr<ImageFilter> internal_filter_;
};

}  // namespace impeller
