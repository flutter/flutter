// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <stdint.h>
#include <string>

namespace impeller {

struct ColorHSB;

/**
 *  Represents a RGBA color
 */
struct Color {
  /**
   *  The red color component (0 to 1)
   */
  double red = 0.0;

  /**
   *  The green color component (0 to 1)
   */
  double green = 0.0;

  /**
   *  The blue color component (0 to 1)
   */
  double blue = 0.0;

  /**
   *  The alpha component of the color (0 to 1)
   */
  double alpha = 0.0;

  Color() {}

  Color(const ColorHSB& hsbColor);

  Color(double r, double g, double b, double a)
      : red(r), green(g), blue(b), alpha(a) {}

  bool operator==(const Color& c) const {
    return red == c.red && green == c.green && blue == c.blue &&
           alpha == c.alpha;
  }

  Color operator+(const Color& other) const;

  std::string ToString() const;

  void FromString(const std::string& str);

  static Color White() { return {1.0, 1.0, 1.0, 1.0}; }

  static Color Black() { return {0.0, 0.0, 0.0, 1.0}; }

  static Color WhiteTransparent() { return {1.0, 1.0, 1.0, 0.0}; }

  static Color BlackTransparent() { return {0.0, 0.0, 0.0, 0.0}; }

  static Color Red() { return {1.0, 0.0, 0.0, 1.0}; }

  static Color Green() { return {0.0, 1.0, 0.0, 1.0}; }

  static Color Blue() { return {0.0, 0.0, 1.0, 1.0}; }

  static Color AliceBlue() {
    return {240.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color AntiqueWhite() {
    return {250.0 / 255.0, 235.0 / 255.0, 215.0 / 255.0, 1.0};
  }

  static Color Aqua() {
    return {0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color AquaMarine() {
    return {127.0 / 255.0, 255.0 / 255.0, 212.0 / 255.0, 1.0};
  }

  static Color Azure() {
    return {240.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color Beige() {
    return {245.0 / 255.0, 245.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static Color Bisque() {
    return {255.0 / 255.0, 228.0 / 255.0, 196.0 / 255.0, 1.0};
  }

  static Color BlanchedAlmond() {
    return {255.0 / 255.0, 235.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static Color BlueViolet() {
    return {138.0 / 255.0, 43.0 / 255.0, 226.0 / 255.0, 1.0};
  }

  static Color Brown() {
    return {165.0 / 255.0, 42.0 / 255.0, 42.0 / 255.0, 1.0};
  }

  static Color BurlyWood() {
    return {222.0 / 255.0, 184.0 / 255.0, 135.0 / 255.0, 1.0};
  }

  static Color CadetBlue() {
    return {95.0 / 255.0, 158.0 / 255.0, 160.0 / 255.0, 1.0};
  }

  static Color Chartreuse() {
    return {127.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color Chocolate() {
    return {210.0 / 255.0, 105.0 / 255.0, 30.0 / 255.0, 1.0};
  }

  static Color Coral() {
    return {255.0 / 255.0, 127.0 / 255.0, 80.0 / 255.0, 1.0};
  }

  static Color CornflowerBlue() {
    return {100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1.0};
  }

  static Color Cornsilk() {
    return {255.0 / 255.0, 248.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static Color Crimson() {
    return {220.0 / 255.0, 20.0 / 255.0, 60.0 / 255.0, 1.0};
  }

  static Color Cyan() {
    return {0.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color DarkBlue() {
    return {0.0 / 255.0, 0.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static Color DarkCyan() {
    return {0.0 / 255.0, 139.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static Color DarkGoldenrod() {
    return {184.0 / 255.0, 134.0 / 255.0, 11.0 / 255.0, 1.0};
  }

  static Color DarkGray() {
    return {169.0 / 255.0, 169.0 / 255.0, 169.0 / 255.0, 1.0};
  }

  static Color DarkGreen() {
    return {0.0 / 255.0, 100.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color DarkGrey() {
    return {169.0 / 255.0, 169.0 / 255.0, 169.0 / 255.0, 1.0};
  }

  static Color DarkKhaki() {
    return {189.0 / 255.0, 183.0 / 255.0, 107.0 / 255.0, 1.0};
  }

  static Color DarkMagenta() {
    return {139.0 / 255.0, 0.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static Color DarkOliveGreen() {
    return {85.0 / 255.0, 107.0 / 255.0, 47.0 / 255.0, 1.0};
  }

  static Color DarkOrange() {
    return {255.0 / 255.0, 140.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color DarkOrchid() {
    return {153.0 / 255.0, 50.0 / 255.0, 204.0 / 255.0, 1.0};
  }

  static Color DarkRed() {
    return {139.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color DarkSalmon() {
    return {233.0 / 255.0, 150.0 / 255.0, 122.0 / 255.0, 1.0};
  }

  static Color DarkSeagreen() {
    return {143.0 / 255.0, 188.0 / 255.0, 143.0 / 255.0, 1.0};
  }

  static Color DarkSlateBlue() {
    return {72.0 / 255.0, 61.0 / 255.0, 139.0 / 255.0, 1.0};
  }

  static Color DarkSlateGray() {
    return {47.0 / 255.0, 79.0 / 255.0, 79.0 / 255.0, 1.0};
  }

  static Color DarkSlateGrey() {
    return {47.0 / 255.0, 79.0 / 255.0, 79.0 / 255.0, 1.0};
  }

  static Color DarkTurquoise() {
    return {0.0 / 255.0, 206.0 / 255.0, 209.0 / 255.0, 1.0};
  }

  static Color DarkViolet() {
    return {148.0 / 255.0, 0.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static Color DeepPink() {
    return {255.0 / 255.0, 20.0 / 255.0, 147.0 / 255.0, 1.0};
  }

  static Color DeepSkyBlue() {
    return {0.0 / 255.0, 191.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color DimGray() {
    return {105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0, 1.0};
  }

  static Color DimGrey() {
    return {105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0, 1.0};
  }

  static Color DodgerBlue() {
    return {30.0 / 255.0, 144.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color Firebrick() {
    return {178.0 / 255.0, 34.0 / 255.0, 34.0 / 255.0, 1.0};
  }

  static Color FloralWhite() {
    return {255.0 / 255.0, 250.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static Color ForestGreen() {
    return {34.0 / 255.0, 139.0 / 255.0, 34.0 / 255.0, 1.0};
  }

  static Color Fuchsia() {
    return {255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color Gainsboro() {
    return {220.0 / 255.0, 220.0 / 255.0, 220.0 / 255.0, 1.0};
  }

  static Color Ghostwhite() {
    return {248.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color Gold() {
    return {255.0 / 255.0, 215.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color Goldenrod() {
    return {218.0 / 255.0, 165.0 / 255.0, 32.0 / 255.0, 1.0};
  }

  static Color Gray() {
    return {128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static Color GreenYellow() {
    return {173.0 / 255.0, 255.0 / 255.0, 47.0 / 255.0, 1.0};
  }

  static Color Grey() {
    return {128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static Color Honeydew() {
    return {240.0 / 255.0, 255.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static Color HotPink() {
    return {255.0 / 255.0, 105.0 / 255.0, 180.0 / 255.0, 1.0};
  }

  static Color IndianRed() {
    return {205.0 / 255.0, 92.0 / 255.0, 92.0 / 255.0, 1.0};
  }

  static Color Indigo() {
    return {75.0 / 255.0, 0.0 / 255.0, 130.0 / 255.0, 1.0};
  }

  static Color Ivory() {
    return {255.0 / 255.0, 255.0 / 255.0, 240.0 / 255.0, 1.0};
  }

  static Color Khaki() {
    return {240.0 / 255.0, 230.0 / 255.0, 140.0 / 255.0, 1.0};
  }

  static Color Lavender() {
    return {230.0 / 255.0, 230.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static Color LavenderBlush() {
    return {255.0 / 255.0, 240.0 / 255.0, 245.0 / 255.0, 1.0};
  }

  static Color LawnGreen() {
    return {124.0 / 255.0, 252.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color LemonChiffon() {
    return {255.0 / 255.0, 250.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static Color LightBlue() {
    return {173.0 / 255.0, 216.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static Color LightCoral() {
    return {240.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static Color LightCyan() {
    return {224.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color LightGoldenrodYellow() {
    return {50.0 / 255.0, 250.0 / 255.0, 210.0 / 255.0, 1.0};
  }

  static Color LightGray() {
    return {211.0 / 255.0, 211.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static Color LightGreen() {
    return {144.0 / 255.0, 238.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static Color LightGrey() {
    return {211.0 / 255.0, 211.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static Color LightPink() {
    return {255.0 / 255.0, 182.0 / 255.0, 193.0 / 255.0, 1.0};
  }

  static Color LightSalmon() {
    return {255.0 / 255.0, 160.0 / 255.0, 122.0 / 255.0, 1.0};
  }

  static Color LightSeaGreen() {
    return {32.0 / 255.0, 178.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static Color LightSkyBlue() {
    return {135.0 / 255.0, 206.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static Color LightSlateGray() {
    return {119.0 / 255.0, 136.0 / 255.0, 153.0 / 255.0, 1.0};
  }

  static Color LightSlateGrey() {
    return {119.0 / 255.0, 136.0 / 255.0, 153.0 / 255.0, 1.0};
  }

  static Color LightSteelBlue() {
    return {176.0 / 255.0, 196.0 / 255.0, 222.0 / 255.0, 1.0};
  }

  static Color LightYellow() {
    return {255.0 / 255.0, 255.0 / 255.0, 224.0 / 255.0, 1.0};
  }

  static Color Lime() { return {0.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0}; }

  static Color LimeGreen() {
    return {50.0 / 255.0, 205.0 / 255.0, 50.0 / 255.0, 1.0};
  }

  static Color Linen() {
    return {250.0 / 255.0, 240.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static Color Magenta() {
    return {255.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, 1.0};
  }

  static Color Maroon() {
    return {128.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color MediumAquamarine() {
    return {102.0 / 255.0, 205.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static Color MediumBlue() {
    return {0.0 / 255.0, 0.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static Color MediumOrchid() {
    return {186.0 / 255.0, 85.0 / 255.0, 211.0 / 255.0, 1.0};
  }

  static Color MediumPurple() {
    return {147.0 / 255.0, 112.0 / 255.0, 219.0 / 255.0, 1.0};
  }

  static Color MediumSeagreen() {
    return {60.0 / 255.0, 179.0 / 255.0, 113.0 / 255.0, 1.0};
  }

  static Color MediumSlateBlue() {
    return {123.0 / 255.0, 104.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static Color MediumSpringGreen() {
    return {0.0 / 255.0, 250.0 / 255.0, 154.0 / 255.0, 1.0};
  }

  static Color MediumTurquoise() {
    return {72.0 / 255.0, 209.0 / 255.0, 204.0 / 255.0, 1.0};
  }

  static Color MediumVioletRed() {
    return {199.0 / 255.0, 21.0 / 255.0, 133.0 / 255.0, 1.0};
  }

  static Color MidnightBlue() {
    return {25.0 / 255.0, 25.0 / 255.0, 112.0 / 255.0, 1.0};
  }

  static Color MintCream() {
    return {245.0 / 255.0, 255.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static Color MistyRose() {
    return {255.0 / 255.0, 228.0 / 255.0, 225.0 / 255.0, 1.0};
  }

  static Color Moccasin() {
    return {255.0 / 255.0, 228.0 / 255.0, 181.0 / 255.0, 1.0};
  }

  static Color NavajoWhite() {
    return {255.0 / 255.0, 222.0 / 255.0, 173.0 / 255.0, 1.0};
  }

  static Color Navy() { return {0.0 / 255.0, 0.0 / 255.0, 128.0 / 255.0, 1.0}; }

  static Color OldLace() {
    return {253.0 / 255.0, 245.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static Color Olive() {
    return {128.0 / 255.0, 128.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color OliveDrab() {
    return {107.0 / 255.0, 142.0 / 255.0, 35.0 / 255.0, 1.0};
  }

  static Color Orange() {
    return {255.0 / 255.0, 165.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color OrangeRed() {
    return {255.0 / 255.0, 69.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color Orchid() {
    return {218.0 / 255.0, 112.0 / 255.0, 214.0 / 255.0, 1.0};
  }

  static Color PaleGoldenrod() {
    return {238.0 / 255.0, 232.0 / 255.0, 170.0 / 255.0, 1.0};
  }

  static Color PaleGreen() {
    return {152.0 / 255.0, 251.0 / 255.0, 152.0 / 255.0, 1.0};
  }

  static Color PaleTurquoise() {
    return {175.0 / 255.0, 238.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static Color PaleVioletRed() {
    return {219.0 / 255.0, 112.0 / 255.0, 147.0 / 255.0, 1.0};
  }

  static Color PapayaWhip() {
    return {255.0 / 255.0, 239.0 / 255.0, 213.0 / 255.0, 1.0};
  }

  static Color Peachpuff() {
    return {255.0 / 255.0, 218.0 / 255.0, 185.0 / 255.0, 1.0};
  }

  static Color Peru() {
    return {205.0 / 255.0, 133.0 / 255.0, 63.0 / 255.0, 1.0};
  }

  static Color Pink() {
    return {255.0 / 255.0, 192.0 / 255.0, 203.0 / 255.0, 1.0};
  }

  static Color Plum() {
    return {221.0 / 255.0, 160.0 / 255.0, 221.0 / 255.0, 1.0};
  }

  static Color PowderBlue() {
    return {176.0 / 255.0, 224.0 / 255.0, 230.0 / 255.0, 1.0};
  }

  static Color Purple() {
    return {128.0 / 255.0, 0.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static Color RosyBrown() {
    return {188.0 / 255.0, 143.0 / 255.0, 143.0 / 255.0, 1.0};
  }

  static Color RoyalBlue() {
    return {65.0 / 255.0, 105.0 / 255.0, 225.0 / 255.0, 1.0};
  }

  static Color SaddleBrown() {
    return {139.0 / 255.0, 69.0 / 255.0, 19.0 / 255.0, 1.0};
  }

  static Color Salmon() {
    return {250.0 / 255.0, 128.0 / 255.0, 114.0 / 255.0, 1.0};
  }

  static Color SandyBrown() {
    return {244.0 / 255.0, 164.0 / 255.0, 96.0 / 255.0, 1.0};
  }

  static Color Seagreen() {
    return {46.0 / 255.0, 139.0 / 255.0, 87.0 / 255.0, 1.0};
  }

  static Color Seashell() {
    return {255.0 / 255.0, 245.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static Color Sienna() {
    return {160.0 / 255.0, 82.0 / 255.0, 45.0 / 255.0, 1.0};
  }

  static Color Silver() {
    return {192.0 / 255.0, 192.0 / 255.0, 192.0 / 255.0, 1.0};
  }

  static Color SkyBlue() {
    return {135.0 / 255.0, 206.0 / 255.0, 235.0 / 255.0, 1.0};
  }

  static Color SlateBlue() {
    return {106.0 / 255.0, 90.0 / 255.0, 205.0 / 255.0, 1.0};
  }

  static Color SlateGray() {
    return {112.0 / 255.0, 128.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static Color SlateGrey() {
    return {112.0 / 255.0, 128.0 / 255.0, 144.0 / 255.0, 1.0};
  }

  static Color Snow() {
    return {255.0 / 255.0, 250.0 / 255.0, 250.0 / 255.0, 1.0};
  }

  static Color SpringGreen() {
    return {0.0 / 255.0, 255.0 / 255.0, 127.0 / 255.0, 1.0};
  }

  static Color SteelBlue() {
    return {70.0 / 255.0, 130.0 / 255.0, 180.0 / 255.0, 1.0};
  }

  static Color Tan() {
    return {210.0 / 255.0, 180.0 / 255.0, 140.0 / 255.0, 1.0};
  }

  static Color Teal() {
    return {0.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.0};
  }

  static Color Thistle() {
    return {216.0 / 255.0, 191.0 / 255.0, 216.0 / 255.0, 1.0};
  }

  static Color Tomato() {
    return {255.0 / 255.0, 99.0 / 255.0, 71.0 / 255.0, 1.0};
  }

  static Color Turquoise() {
    return {64.0 / 255.0, 224.0 / 255.0, 208.0 / 255.0, 1.0};
  }

  static Color Violet() {
    return {238.0 / 255.0, 130.0 / 255.0, 238.0 / 255.0, 1.0};
  }

  static Color Wheat() {
    return {245.0 / 255.0, 222.0 / 255.0, 179.0 / 255.0, 1.0};
  }

  static Color Whitesmoke() {
    return {245.0 / 255.0, 245.0 / 255.0, 245.0 / 255.0, 1.0};
  }

  static Color Yellow() {
    return {255.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0};
  }

  static Color YellowGreen() {
    return {154.0 / 255.0, 205.0 / 255.0, 50.0 / 255.0, 1.0};
  }
};

/**
 *  Represents a color by its constituent hue, saturation, brightness and alpha
 */
struct ColorHSB {
  /**
   *  The hue of the color (0 to 1)
   */
  double hue;

  /**
   *  The saturation of the color (0 to 1)
   */
  double saturation;

  /**
   *  The brightness of the color (0 to 1)
   */
  double brightness;

  /**
   *  The alpha of the color (0 to 1)
   */
  double alpha;

  ColorHSB(double h, double s, double b, double a)
      : hue(h), saturation(s), brightness(b), alpha(a) {}

  static ColorHSB FromRGB(Color rgb);

  Color ToRGBA() const;

  std::string ToString() const;
};

}  // namespace impeller
