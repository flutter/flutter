// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_H_

#include "flutter/display_list/types.h"

namespace flutter {

struct DlColor {
 public:
  constexpr DlColor() : argb(0xFF000000) {}
  constexpr DlColor(uint32_t argb) : argb(argb) {}

  static constexpr uint8_t toAlpha(SkScalar opacity) { return toC(opacity); }
  static constexpr SkScalar toOpacity(uint8_t alpha) { return toF(alpha); }

  // clang-format off
  static constexpr DlColor kTransparent()        {return 0x00000000;};
  static constexpr DlColor kBlack()              {return 0xFF000000;};
  static constexpr DlColor kWhite()              {return 0xFFFFFFFF;};
  static constexpr DlColor kRed()                {return 0xFFFF0000;};
  static constexpr DlColor kGreen()              {return 0xFF00FF00;};
  static constexpr DlColor kBlue()               {return 0xFF0000FF;};
  static constexpr DlColor kCyan()               {return 0xFF00FFFF;};
  static constexpr DlColor kMagenta()            {return 0xFFFF00FF;};
  static constexpr DlColor kYellow()             {return 0xFFFFFF00;};
  static constexpr DlColor kDarkGrey()           {return 0xFF3F3F3F;};
  static constexpr DlColor kMidGrey()            {return 0xFF808080;};
  static constexpr DlColor kLightGrey()          {return 0xFFC0C0C0;};
  // clang-format on

  uint32_t argb;

  bool isOpaque() const { return getAlpha() == 0xFF; }

  int getAlpha() const { return argb >> 24; }
  int getRed() const { return (argb >> 16) & 0xFF; }
  int getGreen() const { return (argb >> 8) & 0xFF; }
  int getBlue() const { return argb & 0xFF; }

  float getAlphaF() const { return toF(getAlpha()); }
  float getRedF() const { return toF(getRed()); }
  float getGreenF() const { return toF(getGreen()); }
  float getBlueF() const { return toF(getBlue()); }

  uint32_t premultipliedArgb() const {
    if (isOpaque()) {
      return argb;
    }
    float f = getAlphaF();
    return (argb & 0xFF000000) |        //
           toC(getRedF() * f) << 16 |   //
           toC(getGreenF() * f) << 8 |  //
           toC(getBlueF() * f);
  }

  DlColor withAlpha(uint8_t alpha) const {  //
    return (argb & 0x00FFFFFF) | (alpha << 24);
  }
  DlColor withRed(uint8_t red) const {  //
    return (argb & 0xFF00FFFF) | (red << 16);
  }
  DlColor withGreen(uint8_t green) const {  //
    return (argb & 0xFFFF00FF) | (green << 8);
  }
  DlColor withBlue(uint8_t blue) const {  //
    return (argb & 0xFFFFFF00) | (blue << 0);
  }

  DlColor modulateOpacity(float opacity) const {
    return opacity <= 0   ? withAlpha(0)
           : opacity >= 1 ? *this
                          : withAlpha(round(getAlpha() * opacity));
  }

  operator uint32_t() const { return argb; }
  bool operator==(DlColor const& other) const { return argb == other.argb; }
  bool operator!=(DlColor const& other) const { return argb != other.argb; }
  bool operator==(uint32_t const& other) const { return argb == other; }
  bool operator!=(uint32_t const& other) const { return argb != other; }

 private:
  static float toF(uint8_t comp) { return comp * (1.0 / 255); }
  static uint8_t toC(float fComp) { return round(fComp * 255); }
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_H_
