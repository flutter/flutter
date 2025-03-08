// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rsuperellipse.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/logging/dart_error.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, RSuperellipse);

RSuperellipse::RSuperellipse(const tonic::Float64List& values) {
  for (size_t i = 0; i < kValueCount; i++) {
    values_[i] = values[i];
  }
}

RSuperellipse::~RSuperellipse() = default;

flutter::DlRoundSuperellipse RSuperellipse::rsuperellipse() const {
  // The Flutter rect may be inverted (upside down, backward, or both)
  // Historically, Skia would normalize such rects but we will do that
  // manually below when we construct the Impeller RoundRect
  flutter::DlRect raw_rect = flutter::DlRect::MakeLTRB(
      _value32(0), _value32(1), _value32(2), _value32(3));

  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  impeller::RoundingRadii radii = {
      .top_left = flutter::DlSize(_value32(4), _value32(5)),
      .top_right = flutter::DlSize(_value32(6), _value32(7)),
      .bottom_left = flutter::DlSize(_value32(10), _value32(11)),
      .bottom_right = flutter::DlSize(_value32(8), _value32(9)),
  };

  return flutter::DlRoundSuperellipse::MakeRectRadii(raw_rect.GetPositive(),
                                                     radii);
}

double RSuperellipse::getValue(int index) const {
  if (index < 0 || index >= kValueCount) {
    return 0;
  }
  return values_[index];
}

impeller::Scalar RSuperellipse::_value32(int index) const {
  return static_cast<impeller::Scalar>(getValue(index));
}

}  // namespace flutter
