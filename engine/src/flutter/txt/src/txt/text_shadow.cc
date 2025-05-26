// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "text_shadow.h"
#include "third_party/skia/include/core/SkColor.h"

namespace txt {

TextShadow::TextShadow() {}
TextShadow::TextShadow(SkColor color, SkPoint offset, double blur_sigma)
    : color(color), offset(offset), blur_sigma(blur_sigma) {}

bool TextShadow::operator==(const TextShadow& other) const {
  if (color != other.color) {
    return false;
  }
  if (offset != other.offset) {
    return false;
  }
  if (blur_sigma != other.blur_sigma) {
    return false;
  }

  return true;
}

bool TextShadow::operator!=(const TextShadow& other) const {
  return !(*this == other);
}

bool TextShadow::hasShadow() const {
  if (!offset.isZero()) {
    return true;
  }
  if (blur_sigma > 0.5) {
    return true;
  }

  return false;
}

}  // namespace txt
