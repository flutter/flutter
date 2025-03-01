// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TEXT_SHADOW_H_
#define FLUTTER_TXT_SRC_TXT_TEXT_SHADOW_H_

#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPoint.h"

namespace txt {

class TextShadow {
 public:
  SkColor color = SK_ColorBLACK;
  SkPoint offset;
  double blur_sigma = 0.0;

  TextShadow();

  TextShadow(SkColor color, SkPoint offset, double blur_sigma);

  bool operator==(const TextShadow& other) const;

  bool operator!=(const TextShadow& other) const;

  bool hasShadow() const;
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TEXT_SHADOW_H_
