// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <stdint.h>
#include <array>
#include <cstdlib>
#include <ostream>
#include "impeller/geometry/scalar.h"

namespace impeller {

struct ColorHSB;
struct Vector4;

enum class YUVColorSpace { kBT601LimitedRange, kBT601FullRange };

/// All blend modes assume that both the source (fragment output) and
/// destination (first color attachment) have colors with premultiplied alpha.
enum class BlendMode {
  // The following blend modes are able to be used as pipeline blend modes or
  // via `BlendFilterContents`.
  kClear,
  kSource,
  kDestination,
  kSourceOver,
  kDestinationOver,
  kSourceIn,
  kDestinationIn,
  kSourceOut,
  kDestinationOut,
  kSourceATop,
  kDestinationATop,
  kXor,
  kPlus,
  kModulate,

  // The following blend modes use equations that are not available for
  // pipelines on most graphics devices without extensions, and so they are
  // only able to be used via `BlendFilterContents`.
  kScreen,
  kOverlay,
  kDarken,
  kLighten,
  kColorDodge,
  kColorBurn,
  kHardLight,
  kSoftLight,
  kDifference,
  kExclusion,
  kMultiply,
  kHue,
  kSaturation,
  kColor,
  kLuminosity,
};

/**
 *  Represents a RGBA color
 */
struct Color {
  /**
   *  The red color component (0 to 1)
   */
  Scalar red = 0.0;

  /**
   *  The green color component (0 to 1)
   */
  Scalar green = 0.0;

  /**
   *  The blue color component (0 to 1)
   */
  Scalar blue = 0.0;

  /**
   *  The alpha component of the color (0 to 1)
   */
  Scalar alpha = 0.0;

  constexpr Color() {}

  explicit Color(const ColorHSB& hsbColor);

  Color(const Vector4& value);

  constexpr Color(Scalar r, Scalar g, Scalar b, Scalar a)
      : red(r), green(g), blue(b), alpha(a) {}

  static constexpr Color MakeRGBA8(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    return Color(static_cast<Scalar>(r) / 255, static_cast<Scalar>(g) / 255,
                 static_cast<Scalar>(b) / 255, static_cast<Scalar>(a) / 255);
  }

  /// @brief Convert this color to a 32-bit representation.
  static constexpr uint32_t ToIColor(Color color) {
    return (((std::lround(color.alpha * 255) & 0xff) << 24) |
            ((std::lround(color.red * 255) & 0xff) << 16) |
            ((std::lround(color.green * 255) & 0xff) << 8) |
            ((std::lround(color.blue * 255) & 0xff) << 0)) &
           0xFFFFFFFF;
  }

  constexpr bool operator==(const Color& c) const {
    return ScalarNearlyEqual(red, c.red) && ScalarNearlyEqual(green, c.green) &&
           ScalarNearlyEqual(blue, c.blue) && ScalarNearlyEqual(alpha, c.alpha);
  }

  constexpr Color Premultiply() const {
    return {red * alpha, green * alpha, blue * alpha, alpha};
  }

  constexpr Color Unpremultiply() const {
    if (ScalarNearlyEqual(alpha, 0.0)) {
      return Color::BlackTransparent();
    }
    return {red / alpha, green / alpha, blue / alpha, alpha};
  }

  /**
   * @brief Return a color that is linearly interpolated between colors a
   * and b, according to the value of t.
   *
   * @param a The lower color.
   * @param b The upper color.
   * @param t A value between 0.0 and 1.0, inclusive.
   * @return constexpr Color
   */
  constexpr static Color lerp(Color a, Color b, Scalar t) {
    Scalar tt = 1.0 - t;
    return {a.red * tt + b.red * t, a.green * tt + b.green * t,
            a.blue * tt + b.blue * t, a.alpha * tt + b.alpha * t};
  }

  /**
   * @brief Convert to R8G8B8A8 representation.
   *
   * @return constexpr std::array<u_int8, 4>
   */
  constexpr std::array<uint8_t, 4> ToR8G8B8A8() const {
    uint8_t r = std::round(red * 255);
    uint8_t g = std::round(green * 255);
    uint8_t b = std::round(blue * 255);
    uint8_t a = std::round(alpha * 255);
    return {r, g, b, a};
  }

  static constexpr Color White() { return {1.0, 1.0, 1.0, 1.0}; }

  static constexpr Color Black() { return {0.0, 0.0, 0.0, 1.0}; }

  static constexpr Color WhiteTransparent() { return {1.0, 1.0, 1.0, 0.0}; }

  static constexpr Color BlackTransparent() { return {0.0, 0.0, 0.0, 0.0}; }

  static constexpr Color Red() { return {1.0, 0.0, 0.0, 1.0}; }

  static constexpr Color Green() { return {0.0, 1.0, 0.0, 1.0}; }

  static constexpr Color Blue() { return {0.0, 0.0, 1.0, 1.0}; }

  constexpr Color WithAlpha(Scalar new_alpha) const {
    return {red, green, blue, new_alpha};
  }

  static constexpr Color AliceBlue() {
    return {240.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color AntiqueWhite() {
    return {250.0 / 255.0, 235.0 / 255.0, 215.0 / 255.0, 1.0};
  }

  static constexpr Color Aqua() {
    return {0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color AquaMarine() {
    return {127.0 / 255.0, 255.0 / 255.0, 212.0 / 255.0, 1.0};
  }

  static constexpr Color Azure() {
    return {240.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color Beige() {
    return {245.0 / 255.0, 245.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static constexpr Color Bisque() {
    return {255.0 / 255.0, 228.0 / 255.0, 196.0 / 255.0, 1.0};
  }

  static constexpr Color BlanchedAlmond() {
    return {255.0 / 255.0, 235.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static constexpr Color BlueViolet() {
    return {138.0 / 255.0, 43.0 / 255.0, 226.0 / 255.0, 1.0};
  }

  static constexpr Color Brown() {
    return {165.0 / 255.0, 42.0 / 255.0, 42.0 / 255.0, 1.0};
  }

  static constexpr Color BurlyWood() {
    return {222.0 / 255.0, 184.0 / 255.0, 135.0 / 255.0, 1.0};
  }

  static constexpr Color CadetBlue() {
    return {95.0 / 255.0, 158.0 / 255.0, 160.0 / 255.0, 1.0};
  }

  static constexpr Color Chartreuse() {
    return {127.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color Chocolate() {
    return {210.0 / 255.0, 105.0 / 255.0, 30.0 / 255.0, 1.0};
  }

  static constexpr Color Coral() {
    return {255.0 / 255.0, 127.0 / 255.0, 80.0 / 255.0, 1.0};
  }

  static constexpr Color CornflowerBlue() {
    return {100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1.0};
  }

  static constexpr Color Cornsilk() {
    return {255.0 / 255.0, 248.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static constexpr Color Crimson() {
    return {220.0 / 255.0, 20.0 / 255.0, 60.0 / 255.0, 1.0};
  }

  static constexpr Color Cyan() {
    return {0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color DarkBlue() {
    return {0.0 / 255.0, 0.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static constexpr Color DarkCyan() {
    return {0.0 / 255.0, 139.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static constexpr Color DarkGoldenrod() {
    return {184.0 / 255.0, 134.0 / 255.0, 11.0 / 255.0, 1.0};
  }

  static constexpr Color DarkGray() {
    return {169.0 / 255.0, 169.0 / 255.0, 169.0 / 255.0, 1.0};
  }

  static constexpr Color DarkGreen() {
    return {0.0 / 255.0, 100.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color DarkGrey() {
    return {169.0 / 255.0, 169.0 / 255.0, 169.0 / 255.0, 1.0};
  }

  static constexpr Color DarkKhaki() {
    return {189.0 / 255.0, 183.0 / 255.0, 107.0 / 255.0, 1.0};
  }

  static constexpr Color DarkMagenta() {
    return {139.0 / 255.0, 0.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static constexpr Color DarkOliveGreen() {
    return {85.0 / 255.0, 107.0 / 255.0, 47.0 / 255.0, 1.0};
  }

  static constexpr Color DarkOrange() {
    return {255.0 / 255.0, 140.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color DarkOrchid() {
    return {153.0 / 255.0, 50.0 / 255.0, 204.0 / 255.0, 1.0};
  }

  static constexpr Color DarkRed() {
    return {139.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color DarkSalmon() {
    return {233.0 / 255.0, 150.0 / 255.0, 122.0 / 255.0, 1.0};
  }

  static constexpr Color DarkSeagreen() {
    return {143.0 / 255.0, 188.0 / 255.0, 143.0 / 255.0, 1.0};
  }

  static constexpr Color DarkSlateBlue() {
    return {72.0 / 255.0, 61.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static constexpr Color DarkSlateGray() {
    return {47.0 / 255.0, 79.0 / 255.0, 79.0 / 255.0, 1.0};
  }

  static constexpr Color DarkSlateGrey() {
    return {47.0 / 255.0, 79.0 / 255.0, 79.0 / 255.0, 1.0};
  }

  static constexpr Color DarkTurquoise() {
    return {0.0 / 255.0, 206.0 / 255.0, 209.0 / 255.0, 1.0};
  }

  static constexpr Color DarkViolet() {
    return {148.0 / 255.0, 0.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static constexpr Color DeepPink() {
    return {255.0 / 255.0, 20.0 / 255.0, 147.0 / 255.0, 1.0};
  }

  static constexpr Color DeepSkyBlue() {
    return {0.0 / 255.0, 191.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color DimGray() {
    return {105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0, 1.0};
  }

  static constexpr Color DimGrey() {
    return {105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0, 1.0};
  }

  static constexpr Color DodgerBlue() {
    return {30.0 / 255.0, 144.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color Firebrick() {
    return {178.0 / 255.0, 34.0 / 255.0, 34.0 / 255.0, 1.0};
  }

  static constexpr Color FloralWhite() {
    return {255.0 / 255.0, 250.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static constexpr Color ForestGreen() {
    return {34.0 / 255.0, 139.0 / 255.0, 34.0 / 255.0, 1.0};
  }

  static constexpr Color Fuchsia() {
    return {255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color Gainsboro() {
    return {220.0 / 255.0, 220.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static constexpr Color Ghostwhite() {
    return {248.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color Gold() {
    return {255.0 / 255.0, 215.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color Goldenrod() {
    return {218.0 / 255.0, 165.0 / 255.0, 32.0 / 255.0, 1.0};
  }

  static constexpr Color Gray() {
    return {128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color GreenYellow() {
    return {173.0 / 255.0, 255.0 / 255.0, 47.0 / 255.0, 1.0};
  }

  static constexpr Color Grey() {
    return {128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color Honeydew() {
    return {240.0 / 255.0, 255.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static constexpr Color HotPink() {
    return {255.0 / 255.0, 105.0 / 255.0, 180.0 / 255.0, 1.0};
  }

  static constexpr Color IndianRed() {
    return {205.0 / 255.0, 92.0 / 255.0, 92.0 / 255.0, 1.0};
  }

  static constexpr Color Indigo() {
    return {75.0 / 255.0, 0.0 / 255.0, 130.0 / 255.0, 1.0};
  }

  static constexpr Color Ivory() {
    return {255.0 / 255.0, 255.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static constexpr Color Khaki() {
    return {240.0 / 255.0, 230.0 / 255.0, 140.0 / 255.0, 1.0};
  }

  static constexpr Color Lavender() {
    return {230.0 / 255.0, 230.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static constexpr Color LavenderBlush() {
    return {255.0 / 255.0, 240.0 / 255.0, 245.0 / 255.0, 1.0};
  }

  static constexpr Color LawnGreen() {
    return {124.0 / 255.0, 252.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color LemonChiffon() {
    return {255.0 / 255.0, 250.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static constexpr Color LightBlue() {
    return {173.0 / 255.0, 216.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static constexpr Color LightCoral() {
    return {240.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color LightCyan() {
    return {224.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color LightGoldenrodYellow() {
    return {50.0 / 255.0, 250.0 / 255.0, 210.0 / 255.0, 1.0};
  }

  static constexpr Color LightGray() {
    return {211.0 / 255.0, 211.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static constexpr Color LightGreen() {
    return {144.0 / 255.0, 238.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static constexpr Color LightGrey() {
    return {211.0 / 255.0, 211.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static constexpr Color LightPink() {
    return {255.0 / 255.0, 182.0 / 255.0, 193.0 / 255.0, 1.0};
  }

  static constexpr Color LightSalmon() {
    return {255.0 / 255.0, 160.0 / 255.0, 122.0 / 255.0, 1.0};
  }

  static constexpr Color LightSeaGreen() {
    return {32.0 / 255.0, 178.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static constexpr Color LightSkyBlue() {
    return {135.0 / 255.0, 206.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static constexpr Color LightSlateGray() {
    return {119.0 / 255.0, 136.0 / 255.0, 153.0 / 255.0, 1.0};
  }

  static constexpr Color LightSlateGrey() {
    return {119.0 / 255.0, 136.0 / 255.0, 153.0 / 255.0, 1.0};
  }

  static constexpr Color LightSteelBlue() {
    return {176.0 / 255.0, 196.0 / 255.0, 222.0 / 255.0, 1.0};
  }

  static constexpr Color LightYellow() {
    return {255.0 / 255.0, 255.0 / 255.0, 224.0 / 255.0, 1.0};
  }

  static constexpr Color Lime() {
    return {0.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color LimeGreen() {
    return {50.0 / 255.0, 205.0 / 255.0, 50.0 / 255.0, 1.0};
  }

  static constexpr Color Linen() {
    return {250.0 / 255.0, 240.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static constexpr Color Magenta() {
    return {255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static constexpr Color Maroon() {
    return {128.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color MediumAquamarine() {
    return {102.0 / 255.0, 205.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static constexpr Color MediumBlue() {
    return {0.0 / 255.0, 0.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static constexpr Color MediumOrchid() {
    return {186.0 / 255.0, 85.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static constexpr Color MediumPurple() {
    return {147.0 / 255.0, 112.0 / 255.0, 219.0 / 255.0, 1.0};
  }

  static constexpr Color MediumSeagreen() {
    return {60.0 / 255.0, 179.0 / 255.0, 113.0 / 255.0, 1.0};
  }

  static constexpr Color MediumSlateBlue() {
    return {123.0 / 255.0, 104.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static constexpr Color MediumSpringGreen() {
    return {0.0 / 255.0, 250.0 / 255.0, 154.0 / 255.0, 1.0};
  }

  static constexpr Color MediumTurquoise() {
    return {72.0 / 255.0, 209.0 / 255.0, 204.0 / 255.0, 1.0};
  }

  static constexpr Color MediumVioletRed() {
    return {199.0 / 255.0, 21.0 / 255.0, 133.0 / 255.0, 1.0};
  }

  static constexpr Color MidnightBlue() {
    return {25.0 / 255.0, 25.0 / 255.0, 112.0 / 255.0, 1.0};
  }

  static constexpr Color MintCream() {
    return {245.0 / 255.0, 255.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static constexpr Color MistyRose() {
    return {255.0 / 255.0, 228.0 / 255.0, 225.0 / 255.0, 1.0};
  }

  static constexpr Color Moccasin() {
    return {255.0 / 255.0, 228.0 / 255.0, 181.0 / 255.0, 1.0};
  }

  static constexpr Color NavajoWhite() {
    return {255.0 / 255.0, 222.0 / 255.0, 173.0 / 255.0, 1.0};
  }

  static constexpr Color Navy() {
    return {0.0 / 255.0, 0.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color OldLace() {
    return {253.0 / 255.0, 245.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static constexpr Color Olive() {
    return {128.0 / 255.0, 128.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color OliveDrab() {
    return {107.0 / 255.0, 142.0 / 255.0, 35.0 / 255.0, 1.0};
  }

  static constexpr Color Orange() {
    return {255.0 / 255.0, 165.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color OrangeRed() {
    return {255.0 / 255.0, 69.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color Orchid() {
    return {218.0 / 255.0, 112.0 / 255.0, 214.0 / 255.0, 1.0};
  }

  static constexpr Color PaleGoldenrod() {
    return {238.0 / 255.0, 232.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static constexpr Color PaleGreen() {
    return {152.0 / 255.0, 251.0 / 255.0, 152.0 / 255.0, 1.0};
  }

  static constexpr Color PaleTurquoise() {
    return {175.0 / 255.0, 238.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static constexpr Color PaleVioletRed() {
    return {219.0 / 255.0, 112.0 / 255.0, 147.0 / 255.0, 1.0};
  }

  static constexpr Color PapayaWhip() {
    return {255.0 / 255.0, 239.0 / 255.0, 213.0 / 255.0, 1.0};
  }

  static constexpr Color Peachpuff() {
    return {255.0 / 255.0, 218.0 / 255.0, 185.0 / 255.0, 1.0};
  }

  static constexpr Color Peru() {
    return {205.0 / 255.0, 133.0 / 255.0, 63.0 / 255.0, 1.0};
  }

  static constexpr Color Pink() {
    return {255.0 / 255.0, 192.0 / 255.0, 203.0 / 255.0, 1.0};
  }

  static constexpr Color Plum() {
    return {221.0 / 255.0, 160.0 / 255.0, 221.0 / 255.0, 1.0};
  }

  static constexpr Color PowderBlue() {
    return {176.0 / 255.0, 224.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static constexpr Color Purple() {
    return {128.0 / 255.0, 0.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color RosyBrown() {
    return {188.0 / 255.0, 143.0 / 255.0, 143.0 / 255.0, 1.0};
  }

  static constexpr Color RoyalBlue() {
    return {65.0 / 255.0, 105.0 / 255.0, 225.0 / 255.0, 1.0};
  }

  static constexpr Color SaddleBrown() {
    return {139.0 / 255.0, 69.0 / 255.0, 19.0 / 255.0, 1.0};
  }

  static constexpr Color Salmon() {
    return {250.0 / 255.0, 128.0 / 255.0, 114.0 / 255.0, 1.0};
  }

  static constexpr Color SandyBrown() {
    return {244.0 / 255.0, 164.0 / 255.0, 96.0 / 255.0, 1.0};
  }

  static constexpr Color Seagreen() {
    return {46.0 / 255.0, 139.0 / 255.0, 87.0 / 255.0, 1.0};
  }

  static constexpr Color Seashell() {
    return {255.0 / 255.0, 245.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static constexpr Color Sienna() {
    return {160.0 / 255.0, 82.0 / 255.0, 45.0 / 255.0, 1.0};
  }

  static constexpr Color Silver() {
    return {192.0 / 255.0, 192.0 / 255.0, 192.0 / 255.0, 1.0};
  }

  static constexpr Color SkyBlue() {
    return {135.0 / 255.0, 206.0 / 255.0, 235.0 / 255.0, 1.0};
  }

  static constexpr Color SlateBlue() {
    return {106.0 / 255.0, 90.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static constexpr Color SlateGray() {
    return {112.0 / 255.0, 128.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static constexpr Color SlateGrey() {
    return {112.0 / 255.0, 128.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static constexpr Color Snow() {
    return {255.0 / 255.0, 250.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static constexpr Color SpringGreen() {
    return {0.0 / 255.0, 255.0 / 255.0, 127.0 / 255.0, 1.0};
  }

  static constexpr Color SteelBlue() {
    return {70.0 / 255.0, 130.0 / 255.0, 180.0 / 255.0, 1.0};
  }

  static constexpr Color Tan() {
    return {210.0 / 255.0, 180.0 / 255.0, 140.0 / 255.0, 1.0};
  }

  static constexpr Color Teal() {
    return {0.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static constexpr Color Thistle() {
    return {216.0 / 255.0, 191.0 / 255.0, 216.0 / 255.0, 1.0};
  }

  static constexpr Color Tomato() {
    return {255.0 / 255.0, 99.0 / 255.0, 71.0 / 255.0, 1.0};
  }

  static constexpr Color Turquoise() {
    return {64.0 / 255.0, 224.0 / 255.0, 208.0 / 255.0, 1.0};
  }

  static constexpr Color Violet() {
    return {238.0 / 255.0, 130.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static constexpr Color Wheat() {
    return {245.0 / 255.0, 222.0 / 255.0, 179.0 / 255.0, 1.0};
  }

  static constexpr Color Whitesmoke() {
    return {245.0 / 255.0, 245.0 / 255.0, 245.0 / 255.0, 1.0};
  }

  static constexpr Color Yellow() {
    return {255.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static constexpr Color YellowGreen() {
    return {154.0 / 255.0, 205.0 / 255.0, 50.0 / 255.0, 1.0};
  }

  static Color Random() {
    return {
        static_cast<Scalar>((std::rand() % 255) / 255.0),  //
        static_cast<Scalar>((std::rand() % 255) / 255.0),  //
        static_cast<Scalar>((std::rand() % 255) / 255.0),  //
        1.0                                                //
    };
  }

  static Color BlendColor(const Color& src,
                          const Color& dst,
                          BlendMode blend_mode);

  Color operator*(const Color& c) const {
    return Color(red * c.red, green * c.green, blue * c.blue, alpha * c.alpha);
  }

  Color operator+(const Color& c) const;

  Color operator-(const Color& c) const;

  Color operator*(Scalar value) const;

  constexpr bool IsTransparent() const { return alpha == 0.0; }

  constexpr bool IsOpaque() const { return alpha == 1.0; }
};

/**
 *  Represents a color by its constituent hue, saturation, brightness and alpha
 */
struct ColorHSB {
  /**
   *  The hue of the color (0 to 1)
   */
  Scalar hue;

  /**
   *  The saturation of the color (0 to 1)
   */
  Scalar saturation;

  /**
   *  The brightness of the color (0 to 1)
   */
  Scalar brightness;

  /**
   *  The alpha of the color (0 to 1)
   */
  Scalar alpha;

  constexpr ColorHSB(Scalar h, Scalar s, Scalar b, Scalar a)
      : hue(h), saturation(s), brightness(b), alpha(a) {}

  static ColorHSB FromRGB(Color rgb);

  Color ToRGBA() const;
};

static_assert(sizeof(Color) == 4 * sizeof(Scalar));

}  // namespace impeller

namespace std {

inline std::ostream& operator<<(std::ostream& out, const impeller::Color& c) {
  out << "(" << c.red << ", " << c.green << ", " << c.blue << ", " << c.alpha
      << ")";
  return out;
}

}  // namespace std
