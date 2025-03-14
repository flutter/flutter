// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rsuperellipse.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/logging/dart_error.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, RSuperellipse);

namespace {}  // namespace

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
    FML_DCHECK(false) << "Invalid index " << index
                      << " for RSuperellipse::getValue.";
    return 0;
  }
  return values_[index];
}

bool RSuperellipse::contains(double x, double y) const {
  return param().Contains(
      DlPoint(static_cast<DlScalar>(x), static_cast<DlScalar>(y)));
}

DlScalar RSuperellipse::value32(int index) const {
  return static_cast<DlScalar>(getValue(index));
}

flutter::DlRect RSuperellipse::bounds() const {
  // The Flutter rect may be inverted (upside down, backward, or both)
  // Historically, Skia would normalize such rects but we will do that
  // manually below when we construct the Impeller RoundRect
  flutter::DlRect raw_rect = flutter::DlRect::MakeLTRB(
      value32(kLeft), value32(kTop), value32(kRight), value32(kBottom));
  return raw_rect.GetPositive();
}

impeller::RoundingRadii RSuperellipse::radii() const {
  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  return impeller::RoundingRadii{
      .top_left = flutter::DlSize(value32(kTopLeftX), value32(kTopLeftY)),
      .top_right = flutter::DlSize(value32(kTopRightX), value32(kTopRightY)),
      .bottom_left =
          flutter::DlSize(value32(kBottomLeftX), value32(kBottomLeftY)),
      .bottom_right =
          flutter::DlSize(value32(kBottomRightX), value32(kBottomRightY)),
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
