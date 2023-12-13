// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_COLOR_FILTER_H_
#define FLUTTER_IMPELLER_AIKS_COLOR_FILTER_H_

#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct Paint;

/*******************************************************************************
 ******* ColorFilter
 ******************************************************************************/

class ColorFilter {
 public:
  /// A procedure that filters a given unpremultiplied color to produce a new
  /// unpremultiplied color.
  using ColorFilterProc = std::function<Color(Color)>;

  ColorFilter();

  virtual ~ColorFilter();

  static std::shared_ptr<ColorFilter> MakeBlend(BlendMode blend_mode,
                                                Color color);

  static std::shared_ptr<ColorFilter> MakeMatrix(ColorMatrix color_matrix);

  static std::shared_ptr<ColorFilter> MakeSrgbToLinear();

  static std::shared_ptr<ColorFilter> MakeLinearToSrgb();

  static std::shared_ptr<ColorFilter> MakeComposed(
      const std::shared_ptr<ColorFilter>& outer,
      const std::shared_ptr<ColorFilter>& inner);

  /// @brief  Wraps the given filter input with a GPU-based filter that will
  ///         perform the color operation. The given input will first be
  ///         rendered to a texture and then filtered.
  ///
  ///         Note that this operation has no consideration for the original
  ///         geometry mask of the filter input. And the entire input texture is
  ///         treated as color information.
  virtual std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const = 0;

  /// @brief Returns a function that can be used to filter unpremultiplied
  ///        Impeller Colors on the CPU.
  virtual ColorFilterProc GetCPUColorFilterProc() const = 0;

  virtual std::shared_ptr<ColorFilter> Clone() const = 0;
};

/*******************************************************************************
 ******* BlendColorFilter
 ******************************************************************************/

class BlendColorFilter final : public ColorFilter {
 public:
  BlendColorFilter(BlendMode blend_mode, Color color);

  ~BlendColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

  // |ColorFilter|
  std::shared_ptr<ColorFilter> Clone() const override;

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
  std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

  // |ColorFilter|
  std::shared_ptr<ColorFilter> Clone() const override;

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
  std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

  // |ColorFilter|
  std::shared_ptr<ColorFilter> Clone() const override;
};

/*******************************************************************************
 ******* LinearToSrgbColorFilter
 ******************************************************************************/

class LinearToSrgbColorFilter final : public ColorFilter {
 public:
  explicit LinearToSrgbColorFilter();

  ~LinearToSrgbColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

  // |ColorFilter|
  std::shared_ptr<ColorFilter> Clone() const override;
};

/// @brief Applies color filters as f(g(x)), where x is the input color.
class ComposedColorFilter final : public ColorFilter {
 public:
  ComposedColorFilter(const std::shared_ptr<ColorFilter>& outer,
                      const std::shared_ptr<ColorFilter>& inner);

  ~ComposedColorFilter() override;

  // |ColorFilter|
  std::shared_ptr<ColorFilterContents> WrapWithGPUColorFilter(
      std::shared_ptr<FilterInput> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity) const override;

  // |ColorFilter|
  ColorFilterProc GetCPUColorFilterProc() const override;

  // |ColorFilter|
  std::shared_ptr<ColorFilter> Clone() const override;

 private:
  std::shared_ptr<ColorFilter> outer_;
  std::shared_ptr<ColorFilter> inner_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_COLOR_FILTER_H_
