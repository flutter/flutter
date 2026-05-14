// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_color.h"

#include <algorithm>
#include <cmath>

namespace flutter {

namespace {

/// sRGB standard constants for transfer functions.
/// See https://en.wikipedia.org/wiki/SRGB.
constexpr double kSrgbGamma = 2.4;
constexpr double kSrgbLinearThreshold = 0.04045;
constexpr double kSrgbLinearSlope = 12.92;
constexpr double kSrgbEncodedOffset = 0.055;
constexpr double kSrgbEncodedDivisor = 1.055;
constexpr double kSrgbLinearToEncodedThreshold = 0.0031308;

/// sRGB electro-optical transfer function (gamma decode, gamma ~2.2 to linear).
double srgbEOTF(double v) {
  if (v <= kSrgbLinearThreshold) {
    return v / kSrgbLinearSlope;
  }
  return std::pow((v + kSrgbEncodedOffset) / kSrgbEncodedDivisor, kSrgbGamma);
}

/// sRGB opto-electronic transfer function (linear to gamma encode).
double srgbOETF(double v) {
  if (v <= kSrgbLinearToEncodedThreshold) {
    return v * kSrgbLinearSlope;
  }
  return kSrgbEncodedDivisor * std::pow(v, 1.0 / kSrgbGamma) -
         kSrgbEncodedOffset;
}

/// sRGB EOTF extended to handle negative values (for extended sRGB).
double srgbEOTFExtended(double v) {
  return v < 0.0 ? -srgbEOTF(-v) : srgbEOTF(v);
}

/// sRGB OETF extended to handle negative values (for extended sRGB).
double srgbOETFExtended(double v) {
  return v < 0.0 ? -srgbOETF(-v) : srgbOETF(v);
}

/// Display P3 to sRGB linear 3x3 matrix.
/// Both P3 and sRGB use the same D65 white point.
/// P3 has wider primaries than sRGB, so converting P3 colors to sRGB
/// can produce values outside [0,1] (extended sRGB).
///
/// Matrix derived from:
///   M = sRGB_XYZ_to_RGB * P3_RGB_to_XYZ
static constexpr double kP3ToSrgbLinear[9] = {
    1.2249401, -0.2249402, 0.0,        -0.0420569, 1.0420571,
    0.0,       -0.0196376, -0.0786507, 1.0982884,
};

/// Converts a Display P3 color (gamma-encoded) to extended sRGB
/// (gamma-encoded). Steps: P3 gamma decode -> linear P3 -> linear sRGB (via 3x3
/// matrix) -> sRGB gamma encode.
DlColor p3ToExtendedSrgb(const DlColor& color) {
  // Linearize P3 values (P3 uses same transfer function as sRGB).
  double r_lin = srgbEOTFExtended(static_cast<double>(color.getRedF()));
  double g_lin = srgbEOTFExtended(static_cast<double>(color.getGreenF()));
  double b_lin = srgbEOTFExtended(static_cast<double>(color.getBlueF()));

  // Apply 3x3 P3-to-sRGB matrix in linear space.
  double r_srgb_lin = kP3ToSrgbLinear[0] * r_lin + kP3ToSrgbLinear[1] * g_lin +
                      kP3ToSrgbLinear[2] * b_lin;
  double g_srgb_lin = kP3ToSrgbLinear[3] * r_lin + kP3ToSrgbLinear[4] * g_lin +
                      kP3ToSrgbLinear[5] * b_lin;
  double b_srgb_lin = kP3ToSrgbLinear[6] * r_lin + kP3ToSrgbLinear[7] * g_lin +
                      kP3ToSrgbLinear[8] * b_lin;

  // Gamma encode back to sRGB.
  double r_out = srgbOETFExtended(r_srgb_lin);
  double g_out = srgbOETFExtended(g_srgb_lin);
  double b_out = srgbOETFExtended(b_srgb_lin);

  return DlColor(color.getAlphaF(), static_cast<float>(r_out),
                 static_cast<float>(g_out), static_cast<float>(b_out),
                 DlColorSpace::kExtendedSRGB);
}

}  // namespace

DlColor DlColor::withColorSpace(DlColorSpace color_space) const {
  switch (color_space_) {
    case DlColorSpace::kSRGB:
      switch (color_space) {
        case DlColorSpace::kSRGB:
          return *this;
        case DlColorSpace::kExtendedSRGB:
          return DlColor(alpha_, red_, green_, blue_,
                         DlColorSpace::kExtendedSRGB);
        case DlColorSpace::kDisplayP3:
          FML_CHECK(false) << "not implemented";
          return *this;
      }
    case DlColorSpace::kExtendedSRGB:
      switch (color_space) {
        case DlColorSpace::kSRGB:
          return DlColor(alpha_, std::clamp(red_, 0.0f, 1.0f),
                         std::clamp(green_, 0.0f, 1.0f),
                         std::clamp(blue_, 0.0f, 1.0f), DlColorSpace::kSRGB);
        case DlColorSpace::kExtendedSRGB:
          return *this;
        case DlColorSpace::kDisplayP3:
          FML_CHECK(false) << "not implemented";
          return *this;
      }
    case DlColorSpace::kDisplayP3:
      switch (color_space) {
        case DlColorSpace::kSRGB:
          return p3ToExtendedSrgb(*this).withColorSpace(DlColorSpace::kSRGB);
        case DlColorSpace::kExtendedSRGB:
          return p3ToExtendedSrgb(*this);
        case DlColorSpace::kDisplayP3:
          return *this;
      }
  }
}

}  // namespace flutter
