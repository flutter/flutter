// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/color.h"

#include <algorithm>
#include <cmath>
#include <sstream>

#include "impeller/geometry/scalar.h"
#include "impeller/geometry/vector.h"

namespace impeller {

#define _IMPELLER_ASSERT_BLEND_MODE(blend_mode)                            \
  auto enum_##blend_mode = static_cast<std::underlying_type_t<BlendMode>>( \
      BlendMode::k##blend_mode);                                           \
  if (i != enum_##blend_mode) {                                            \
    return false;                                                          \
  }                                                                        \
  ++i;

static constexpr inline bool ValidateBlendModes() {
  std::underlying_type_t<BlendMode> i = 0;
  // Ensure the order of the blend modes match.
  IMPELLER_FOR_EACH_BLEND_MODE(_IMPELLER_ASSERT_BLEND_MODE)
  // Ensure the total number of blend modes match.
  if (i - 1 !=
      static_cast<std::underlying_type_t<BlendMode>>(BlendMode::kLast)) {
    return false;
  }
  return true;
}
static_assert(ValidateBlendModes(),
              "IMPELLER_FOR_EACH_BLEND_MODE must match impeller::BlendMode.");

ColorHSB ColorHSB::FromRGB(Color rgb) {
  Scalar R = rgb.red;
  Scalar G = rgb.green;
  Scalar B = rgb.blue;

  Scalar v = 0.0;
  Scalar x = 0.0;
  Scalar f = 0.0;

  int64_t i = 0;

  x = fmin(R, G);
  x = fmin(x, B);

  v = fmax(R, G);
  v = fmax(v, B);

  if (v == x) {
    return ColorHSB(0.0, 0.0, v, rgb.alpha);
  }

  f = (R == x) ? G - B : ((G == x) ? B - R : R - G);
  i = (R == x) ? 3 : ((G == x) ? 5 : 1);

  return ColorHSB(((i - f / (v - x)) / 6.0), (v - x) / v, v, rgb.alpha);
}

Color ColorHSB::ToRGBA() const {
  Scalar h = hue * 6.0;
  Scalar s = saturation;
  Scalar v = brightness;

  Scalar m = 0.0;
  Scalar n = 0.0;
  Scalar f = 0.0;

  int64_t i = 0;

  if (h == 0) {
    h = 0.01;
  }

  if (h == 0.0) {
    return Color(v, v, v, alpha);
  }

  i = static_cast<int64_t>(floor(h));

  f = h - i;

  if (!(i & 1)) {
    f = 1 - f;
  }

  m = v * (1 - s);
  n = v * (1 - s * f);

  switch (i) {
    case 6:
    case 0:
      return Color(v, n, m, alpha);
    case 1:
      return Color(n, v, m, alpha);
    case 2:
      return Color(m, v, n, alpha);
    case 3:
      return Color(m, n, v, alpha);
    case 4:
      return Color(n, m, v, alpha);
    case 5:
      return Color(v, m, n, alpha);
  }
  return Color(0, 0, 0, alpha);
}

Color Color::operator+(const Color& c) const {
  return Color(Vector4(*this) + Vector4(c));
}

Color Color::operator-(const Color& c) const {
  return Color(Vector4(*this) - Vector4(c));
}

Color Color::operator*(Scalar value) const {
  return Color(red * value, green * value, blue * value, alpha * value);
}

Color::Color(const ColorHSB& hsbColor) : Color(hsbColor.ToRGBA()) {}

Color::Color(const Vector4& value)
    : red(value.x), green(value.y), blue(value.z), alpha(value.w) {}

Color Min(Color c, float threshold) {
  return Color(std::min(c.red, threshold), std::min(c.green, threshold),
               std::min(c.blue, threshold), std::min(c.alpha, threshold));
}

Color Color::BlendColor(const Color& src,
                        const Color& dst,
                        BlendMode blend_mode) {
  static auto apply_rgb_srcover_alpha = [&](auto f) -> Color {
    return Color(f(src.red, dst.red), f(src.green, dst.green),
                 f(src.blue, dst.blue),
                 dst.alpha * (1 - src.alpha) + src.alpha  // srcOver alpha
    );
  };

  switch (blend_mode) {
    case BlendMode::kClear:
      return Color::BlackTransparent();
    case BlendMode::kSource:
      return src;
    case BlendMode::kDestination:
      return dst;
    case BlendMode::kSourceOver:
      // r = s + (1-sa)*d
      return src + dst * (1 - src.alpha);
    case BlendMode::kDestinationOver:
      // r = d + (1-da)*s
      return dst + src * (1 - dst.alpha);
    case BlendMode::kSourceIn:
      // r = s * da
      return src * dst.alpha;
    case BlendMode::kDestinationIn:
      // r = d * sa
      return dst * src.alpha;
    case BlendMode::kSourceOut:
      // r = s * ( 1- da)
      return src * (1 - dst.alpha);
    case BlendMode::kDestinationOut:
      // r = d * (1-sa)
      return dst * (1 - src.alpha);
    case BlendMode::kSourceATop:
      // r = s*da + d*(1-sa)
      return src * dst.alpha + dst * (1 - src.alpha);
    case BlendMode::kDestinationATop:
      // r = d*sa + s*(1-da)
      return dst * src.alpha + src * (1 - dst.alpha);
    case BlendMode::kXor:
      // r = s*(1-da) + d*(1-sa)
      return src * (1 - dst.alpha) + dst * (1 - src.alpha);
    case BlendMode::kPlus:
      // r = min(s + d, 1)
      return Min(src + dst, 1);
    case BlendMode::kModulate:
      // r = s*d
      return src * dst;
    case BlendMode::kScreen: {
      // r = s + d - s*d
      return src + dst - src * dst;
    }
    case BlendMode::kOverlay:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        if (d * 2 < dst.alpha) {
          return 2 * s * d;
        }
        return src.alpha * dst.alpha - 2 * (dst.alpha - s) * (src.alpha - d);
      });
    case BlendMode::kDarken: {
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        return (1 - dst.alpha) * s + (1 - src.alpha) * d + std::min(s, d);
      });
    }
    case BlendMode::kLighten:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        return (1 - dst.alpha) * s + (1 - src.alpha) * d + std::max(s, d);
      });
    case BlendMode::kColorDodge:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        if (d == 0) {
          return s * (1 - src.alpha);
        }
        if (s == src.alpha) {
          return s + dst.alpha * (1 - src.alpha);
        }
        return src.alpha *
                   std::min(dst.alpha, d * src.alpha / (src.alpha - s)) +
               s * (1 - dst.alpha + dst.alpha * (1 - src.alpha));
      });
    case BlendMode::kColorBurn:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        if (s == 0) {
          return dst.alpha * (1 - src.alpha);
        }
        if (d == dst.alpha) {
          return d + s * (1 - dst.alpha);
        }
        // s.a * (d.a - min(d.a, (d.a - s) * s.a/s)) + s * (1-d.a) + d.a * (1 -
        // s.a)
        return src.alpha *
                   (dst.alpha -
                    std::min(dst.alpha, (dst.alpha - d) * src.alpha / s)) +
               s * (1 - dst.alpha) + dst.alpha * (1 - src.alpha);
      });
    case BlendMode::kHardLight:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        if (src.alpha >= s * (1 - dst.alpha) + d * (1 - src.alpha) + 2 * s) {
          return 2 * s * d;
        }
        // s.a * d.a - 2 * (d.a - d) * (s.a - s)
        return src.alpha * dst.alpha - 2 * (dst.alpha - d) * (src.alpha - s);
      });
    case BlendMode::kDifference:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        // s + d - 2 * min(s * d.a, d * s.a);
        return s + d - 2 * std::min(s * dst.alpha, d * src.alpha);
      });
    case BlendMode::kExclusion:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        // s + d - 2 * s * d
        return s + d - 2 * s * d;
      });
    case BlendMode::kMultiply:
      return apply_rgb_srcover_alpha([&](auto s, auto d) {
        // s * (1 - d.a) + d * (1 - s.a) + (s * d)
        return s * (1 - dst.alpha) + d * (1 - src.alpha) + (s * d);
      });
    case BlendMode::kHue:
    case BlendMode::kSaturation:
    case BlendMode::kColor:
    case BlendMode::kLuminosity:
    case BlendMode::kSoftLight:
    default:
      return src + dst * (1 - src.alpha);
  }
}

}  // namespace impeller
