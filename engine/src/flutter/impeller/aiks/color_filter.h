// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct Paint;

/*******************************************************************************
 ******* ColorFilter
 ******************************************************************************/

class ColorFilter {
 public:
  using ColorFilterProc = std::function<Color(Color)>;

  ColorFilter();

  virtual ~ColorFilter();

  static std::shared_ptr<ColorFilter> MakeBlend(BlendMode blend_mode,
                                                Color color);

  static std::shared_ptr<ColorFilter> MakeMatrix(ColorMatrix color_matrix);

  static std::shared_ptr<ColorFilter> MakeSrgbToLinear();

  static std::shared_ptr<ColorFilter> MakeLinearToSrgb();

  virtual std::shared_ptr<ColorFilterContents> GetColorFilter(
      std::shared_ptr<FilterInput> input,
      bool absorb_opacity) const = 0;

  virtual ColorFilterProc GetCPUColorFilterProc() const = 0;
};

/*******************************************************************************
 ******* BlendColorFilter
 ******************************************************************************/

class BlendColorFilter final : public ColorFilter {
 public:
  BlendColorFilter(BlendMode blend_mode, Color color);

  ~BlendColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> GetColorFilter(
      std::shared_ptr<FilterInput> input,
      bool absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

 private:
  BlendMode blend_mode_;
  Color color_;
};

/*******************************************************************************
 ******* MatrixColorFilter
 ******************************************************************************/

class MatrixColorFilter final : public ColorFilter {
 public:
  explicit MatrixColorFilter(ColorMatrix color_matrix);

  ~MatrixColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> GetColorFilter(
      std::shared_ptr<FilterInput> input,
      bool absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

 private:
  ColorMatrix color_matrix_;
};

/*******************************************************************************
 ******* SrgbToLinearColorFilter
 ******************************************************************************/

class SrgbToLinearColorFilter final : public ColorFilter {
 public:
  explicit SrgbToLinearColorFilter();

  ~SrgbToLinearColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> GetColorFilter(
      std::shared_ptr<FilterInput> input,
      bool absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;
};

/*******************************************************************************
 ******* LinearToSrgbColorFilter
 ******************************************************************************/

class LinearToSrgbColorFilter final : public ColorFilter {
 public:
  explicit LinearToSrgbColorFilter();

  ~LinearToSrgbColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> GetColorFilter(
      std::shared_ptr<FilterInput> input,
      bool absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;
};

}  // namespace impeller
