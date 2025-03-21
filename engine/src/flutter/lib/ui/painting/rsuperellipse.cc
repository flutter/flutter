// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rsuperellipse.h"

#include "flutter/fml/logging.h"
#include "flutter/lib/ui/floating_point.h"
#include "third_party/tonic/logging/dart_error.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, RSuperellipse);

namespace {}  // namespace

RSuperellipse::RSuperellipse(double left,
                             double top,
                             double right,
                             double bottom,
                             double tlRadiusX,
                             double tlRadiusY,
                             double trRadiusX,
                             double trRadiusY,
                             double brRadiusX,
                             double brRadiusY,
                             double blRadiusX,
                             double blRadiusY) {
  values_[kLeft] = left;
  values_[kTop] = top;
  values_[kRight] = right;
  values_[kBottom] = bottom;
  values_[kTopLeftX] = tlRadiusX;
  values_[kTopLeftY] = tlRadiusY;
  values_[kTopRightX] = trRadiusX;
  values_[kTopRightY] = trRadiusY;
  values_[kBottomRightX] = brRadiusX;
  values_[kBottomRightY] = brRadiusY;
  values_[kBottomLeftX] = blRadiusX;
  values_[kBottomLeftY] = blRadiusY;
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

bool RSuperellipse::contains(double x, double y) {
  return param().Contains(
      DlPoint(static_cast<DlScalar>(x), static_cast<DlScalar>(y)));
}

DlScalar RSuperellipse::scalar_value(int index) const {
  return SafeNarrow(getValue(index));
}

flutter::DlRect RSuperellipse::bounds() const {
  // The Flutter rect may be inverted (upside down, backward, or both)
  // Historically, Skia would normalize such rects but we will do that
  // manually below when we construct the Impeller RoundRect
  flutter::DlRect raw_rect =
      flutter::DlRect::MakeLTRB(scalar_value(kLeft), scalar_value(kTop),
                                scalar_value(kRight), scalar_value(kBottom));
  return raw_rect.GetPositive();
}

impeller::RoundingRadii RSuperellipse::radii() const {
  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  return impeller::RoundingRadii{
      .top_left =
          flutter::DlSize(scalar_value(kTopLeftX), scalar_value(kTopLeftY)),
      .top_right =
          flutter::DlSize(scalar_value(kTopRightX), scalar_value(kTopRightY)),
      .bottom_left = flutter::DlSize(scalar_value(kBottomLeftX),
                                     scalar_value(kBottomLeftY)),
      .bottom_right = flutter::DlSize(scalar_value(kBottomRightX),
                                      scalar_value(kBottomRightY)),
  };
}

const impeller::RoundSuperellipseParam& RSuperellipse::param() {
  if (!cached_param_.has_value()) {
    cached_param_ =
        impeller::RoundSuperellipseParam::MakeBoundsRadii(bounds(), radii());
  }
  return cached_param_.value();
}

}  // namespace flutter
