// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_color_filter.h"

#include "flutter/display_list/display_list_color.h"

namespace flutter {

std::shared_ptr<DlColorFilter> DlBlendColorFilter::Make(DlColor color,
                                                        DlBlendMode mode) {
  switch (mode) {
    case DlBlendMode::kDst: {
      return nullptr;
    }
    case DlBlendMode::kSrcOver: {
      if (color.isTransparent()) {
        return nullptr;
      }
      if (color.isOpaque()) {
        mode = DlBlendMode::kSrc;
      }
      break;
    }
    case DlBlendMode::kDstOver:
    case DlBlendMode::kDstOut:
    case DlBlendMode::kSrcATop:
    case DlBlendMode::kXor:
    case DlBlendMode::kDarken: {
      if (color.isTransparent()) {
        return nullptr;
      }
      break;
    }
    case DlBlendMode::kDstIn: {
      if (color.isOpaque()) {
        return nullptr;
      }
      break;
    }
    default:
      break;
  }
  return std::make_shared<DlBlendColorFilter>(color, mode);
}

bool DlBlendColorFilter::modifies_transparent_black() const {
  switch (mode_) {
    // These modes all act like kSrc when the dest is all 0s.
    // So they modify transparent black when the src color is
    // not transparent.
    case DlBlendMode::kSrc:
    case DlBlendMode::kSrcOver:
    case DlBlendMode::kDstOver:
    case DlBlendMode::kSrcOut:
    case DlBlendMode::kDstATop:
    case DlBlendMode::kXor:
    case DlBlendMode::kPlus:
    case DlBlendMode::kScreen:
    case DlBlendMode::kOverlay:
    case DlBlendMode::kDarken:
    case DlBlendMode::kLighten:
    case DlBlendMode::kColorDodge:
    case DlBlendMode::kColorBurn:
    case DlBlendMode::kHardLight:
    case DlBlendMode::kSoftLight:
    case DlBlendMode::kDifference:
    case DlBlendMode::kExclusion:
    case DlBlendMode::kMultiply:
    case DlBlendMode::kHue:
    case DlBlendMode::kSaturation:
    case DlBlendMode::kColor:
    case DlBlendMode::kLuminosity:
      return !color_.isTransparent();

    // These modes are all like kDst when the dest is all 0s.
    // So they never modify transparent black.
    case DlBlendMode::kClear:
    case DlBlendMode::kDst:
    case DlBlendMode::kSrcIn:
    case DlBlendMode::kDstIn:
    case DlBlendMode::kDstOut:
    case DlBlendMode::kSrcATop:
    case DlBlendMode::kModulate:
      return false;
  }
}

bool DlBlendColorFilter::can_commute_with_opacity() const {
  switch (mode_) {
    case DlBlendMode::kClear:
    case DlBlendMode::kDst:
    case DlBlendMode::kSrcIn:
    case DlBlendMode::kDstIn:
    case DlBlendMode::kDstOut:
    case DlBlendMode::kSrcATop:
    case DlBlendMode::kModulate:
      return true;

    case DlBlendMode::kSrc:
    case DlBlendMode::kSrcOver:
    case DlBlendMode::kDstOver:
    case DlBlendMode::kSrcOut:
    case DlBlendMode::kDstATop:
    case DlBlendMode::kXor:
    case DlBlendMode::kPlus:
    case DlBlendMode::kScreen:
    case DlBlendMode::kOverlay:
    case DlBlendMode::kDarken:
    case DlBlendMode::kLighten:
    case DlBlendMode::kColorDodge:
    case DlBlendMode::kColorBurn:
    case DlBlendMode::kHardLight:
    case DlBlendMode::kSoftLight:
    case DlBlendMode::kDifference:
    case DlBlendMode::kExclusion:
    case DlBlendMode::kMultiply:
    case DlBlendMode::kHue:
    case DlBlendMode::kSaturation:
    case DlBlendMode::kColor:
    case DlBlendMode::kLuminosity:
      return color_.isTransparent();
  }
}

std::shared_ptr<DlColorFilter> DlMatrixColorFilter::Make(
    const float matrix[20]) {
  float product = 0;
  for (int i = 0; i < 20; i++) {
    product *= matrix[i];
  }
  // If any of the elements of the matrix are infinity or NaN, then
  // |product| will be NaN, otherwise 0.
  if (product == 0) {
    return std::make_shared<DlMatrixColorFilter>(matrix);
  }
  return nullptr;
}

bool DlMatrixColorFilter::modifies_transparent_black() const {
  // Values are considered in non-premultiplied form when the matrix is
  // applied, but we only care about this answer for whether it leaves
  // an incoming color with a transparent alpha as transparent on output.
  // Thus, we only need to consider the alpha part of the matrix equation,
  // which is the last row. Since the incoming alpha value is 0, the last
  // equation ends up becoming A' = matrix_[19]. Negative results will be
  // clamped to the range [0,1] so we only care about positive values.
  // Non-finite values are clamped to a zero alpha.
  return (SkScalarIsFinite(matrix_[19]) && matrix_[19] > 0);
}

bool DlMatrixColorFilter::can_commute_with_opacity() const {
  // We need to check if:
  //   filter(color) * opacity == filter(color * opacity).
  //
  // filter(RGBA) = R' = [ R*m[ 0] + G*m[ 1] + B*m[ 2] + A*m[ 3] + m[ 4] ]
  //                G' = [ R*m[ 5] + G*m[ 6] + B*m[ 7] + A*m[ 8] + m[ 9] ]
  //                B' = [ R*m[10] + G*m[11] + B*m[12] + A*m[13] + m[14] ]
  //                A' = [ R*m[15] + G*m[16] + B*m[17] + A*m[18] + m[19] ]
  //
  // Applying the opacity only affects the alpha value since the operations
  // are performed on non-premultiplied colors. (If the data is stored in
  // premultiplied form, though, there may be rounding errors due to
  // premul->unpremul->premul conversions.)

  // We test for the successful cases and return false if they fail so that
  // we fail and return false if any matrix values are NaN.

  // If any of the alpha column are non-zero then the prior alpha affects
  // the result color, so applying opacity before the filter will change
  // the incoming alpha and therefore the colors that are produced.
  if (!(matrix_[3] == 0 &&    // A does not affect R'
        matrix_[8] == 0 &&    // A does not affect G'
        matrix_[13] == 0)) {  // A does not affect B'
    return false;
  }

  // Similarly, if any of the alpha row are non-zero then the prior colors
  // affect the result alpha in a way that prevents opacity from commuting
  // through the filter operation.
  if (!(matrix_[15] == 0 &&   // R does not affect A'
        matrix_[16] == 0 &&   // G does not affect A'
        matrix_[17] == 0 &&   // B does not affect A'
        matrix_[19] == 0)) {  // A' is not offset by an absolute value
    return false;
  }

  return true;
}

const std::shared_ptr<DlSrgbToLinearGammaColorFilter>
    DlSrgbToLinearGammaColorFilter::instance =
        std::make_shared<DlSrgbToLinearGammaColorFilter>();

const std::shared_ptr<DlLinearToSrgbGammaColorFilter>
    DlLinearToSrgbGammaColorFilter::instance =
        std::make_shared<DlLinearToSrgbGammaColorFilter>();

}  // namespace flutter
