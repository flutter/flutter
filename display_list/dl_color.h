// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_COLOR_H_
#define FLUTTER_DISPLAY_LIST_DL_COLOR_H_

#include "third_party/skia/include/core/SkScalar.h"

namespace flutter {

struct DlColor {
 public:
  constexpr DlColor() : argb_(0xFF000000) {}
  constexpr explicit DlColor(uint32_t argb) : argb_(argb) {}

  static constexpr uint8_t toAlpha(SkScalar opacity) { return toC(opacity); }
  static constexpr SkScalar toOpacity(uint8_t alpha) { return toF(alpha); }

  // clang-format off
  static constexpr DlColor kTransparent()        {return DlColor(0x00000000);};
  static constexpr DlColor kBlack()              {return DlColor(0xFF000000);};
  static constexpr DlColor kWhite()              {return DlColor(0xFFFFFFFF);};
  static constexpr DlColor kRed()                {return DlColor(0xFFFF0000);};
  static constexpr DlColor kGreen()              {return DlColor(0xFF00FF00);};
  static constexpr DlColor kBlue()               {return DlColor(0xFF0000FF);};
  static constexpr DlColor kCyan()               {return DlColor(0xFF00FFFF);};
  static constexpr DlColor kMagenta()            {return DlColor(0xFFFF00FF);};
  static constexpr DlColor kYellow()             {return DlColor(0xFFFFFF00);};
  static constexpr DlColor kDarkGrey()           {return DlColor(0xFF3F3F3F);};
  static constexpr DlColor kMidGrey()            {return DlColor(0xFF808080);};
  static constexpr DlColor kLightGrey()          {return DlColor(0xFFC0C0C0);};
  // clang-format on

  constexpr bool isOpaque() const { return getAlpha() == 0xFF; }
  constexpr bool isTransparent() const { return getAlpha() == 0; }

  constexpr int getAlpha() const { return argb_ >> 24; }
  constexpr int getRed() const { return (argb_ >> 16) & 0xFF; }
  constexpr int getGreen() const { return (argb_ >> 8) & 0xFF; }
  constexpr int getBlue() const { return argb_ & 0xFF; }

  constexpr float getAlphaF() const { return toF(getAlpha()); }
  constexpr float getRedF() const { return toF(getRed()); }
  constexpr float getGreenF() const { return toF(getGreen()); }
  constexpr float getBlueF() const { return toF(getBlue()); }

  constexpr uint32_t premultipliedArgb() const {
    if (isOpaque()) {
      return argb_;
    }
    float f = getAlphaF();
    return (argb_ & 0xFF000000) |       //
           toC(getRedF() * f) << 16 |   //
           toC(getGreenF() * f) << 8 |  //
           toC(getBlueF() * f);
  }

  constexpr DlColor withAlpha(uint8_t alpha) const {  //
    return DlColor((argb_ & 0x00FFFFFF) | (alpha << 24));
  }
  constexpr DlColor withRed(uint8_t red) const {  //
    return DlColor((argb_ & 0xFF00FFFF) | (red << 16));
  }
  constexpr DlColor withGreen(uint8_t green) const {  //
    return DlColor((argb_ & 0xFFFF00FF) | (green << 8));
  }
  constexpr DlColor withBlue(uint8_t blue) const {  //
    return DlColor((argb_ & 0xFFFFFF00) | (blue << 0));
  }

  constexpr DlColor modulateOpacity(float opacity) const {
    return opacity <= 0   ? withAlpha(0)
           : opacity >= 1 ? *this
                          : withAlpha(round(getAlpha() * opacity));
  }

  constexpr uint32_t argb() const { return argb_; }

  bool operator==(DlColor const& other) const { return argb_ == other.argb_; }
  bool operator!=(DlColor const& other) const { return argb_ != other.argb_; }
  bool operator==(uint32_t const& other) const { return argb_ == other; }
  bool operator!=(uint32_t const& other) const { return argb_ != other; }

 private:
  uint32_t argb_;

  static float toF(uint8_t comp) { return comp * (1.0f / 255); }
  static uint8_t toC(float fComp) { return round(fComp * 255); }
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_COLOR_H_
