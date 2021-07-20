// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/color.h"

#include <algorithm>
#include <cmath>
#include <sstream>

namespace impeller {

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

Color::Color(const ColorHSB& hsbColor) : Color(hsbColor.ToRGBA()) {}

}  // namespace impeller
