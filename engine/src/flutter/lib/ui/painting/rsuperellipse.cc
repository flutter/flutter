// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rsuperellipse.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/logging/dart_error.h"

namespace flutter {

using impeller::Scalar;

IMPLEMENT_WRAPPERTYPEINFO(ui, RSuperellipse);

RSuperellipse::RSuperellipse(const tonic::Float64List& values) {
  for (size_t i = 0; i < kValueCount; i++) {
    values_[i] = values[i];
  }
}

RSuperellipse::~RSuperellipse() = default;

flutter::DlRoundSuperellipse RSuperellipse::rsuperellipse() const {
  return flutter::DlRoundSuperellipse::MakeRectRadii(bounds(), radii());
}

double RSuperellipse::getValue(int index) const {
  if (index < 0 || index >= kValueCount) {
    return 0;
  }
  return values_[index];
}

bool RSuperellipse::contains(double x, double y) const {
  return param().Contains(
      DlPoint(static_cast<Scalar>(x), static_cast<Scalar>(y)));
}

impeller::Scalar RSuperellipse::value32(int index) const {
  return static_cast<Scalar>(getValue(index));
}

flutter::DlRect RSuperellipse::bounds() const {
  // The Flutter rect may be inverted (upside down, backward, or both)
  // Historically, Skia would normalize such rects but we will do that
  // manually below when we construct the Impeller RoundRect
  flutter::DlRect raw_rect =
      flutter::DlRect::MakeLTRB(value32(0), value32(1), value32(2), value32(3));
  return raw_rect.GetPositive();
}

impeller::RoundingRadii RSuperellipse::radii() const {
  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  return impeller::RoundingRadii{
      .top_left = flutter::DlSize(value32(4), value32(5)),
      .top_right = flutter::DlSize(value32(6), value32(7)),
      .bottom_left = flutter::DlSize(value32(10), value32(11)),
      .bottom_right = flutter::DlSize(value32(8), value32(9)),
  };
}

const impeller::RoundSuperellipseParam& RSuperellipse::param() const {
  if (!cached_param_.has_value()) {
    cached_param_ =
        impeller::RoundSuperellipseParam::MakeBoundsRadii(bounds(), radii());
  }
  return cached_param_.value();
}

}  // namespace flutter
