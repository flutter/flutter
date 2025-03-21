// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rsuperellipse.h"

#include "flutter/fml/logging.h"
#include "flutter/lib/ui/floating_point.h"
#include "third_party/tonic/logging/dart_error.h"

namespace flutter {

namespace {

flutter::DlRect BuildBounds(float left, float top, float right, float bottom) {
  // The Flutter rect may be inverted (upside down, backward, or both)
  // Historically, Skia would normalize such rects but we will do that
  // manually below when we construct the Impeller Rect
  flutter::DlRect raw_rect =
      flutter::DlRect::MakeLTRB(left, top, right, bottom);
  return raw_rect.GetPositive();
}

impeller::RoundingRadii BuildRadii(float tl_radius_x,
                                   float tl_radius_y,
                                   float tr_radius_x,
                                   float tr_radius_y,
                                   float br_radius_x,
                                   float br_radius_y,
                                   float bl_radius_x,
                                   float bl_radius_y) {
  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  return impeller::RoundingRadii{
      .top_left = flutter::DlSize(tl_radius_x, tl_radius_y),
      .top_right = flutter::DlSize(tr_radius_x, tr_radius_y),
      .bottom_left = flutter::DlSize(bl_radius_x, bl_radius_y),
      .bottom_right = flutter::DlSize(br_radius_x, br_radius_y),
  };
}
}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(ui, RSuperellipse);

void RSuperellipse::Create(Dart_Handle wrapper,
                           double left,
                           double top,
                           double right,
                           double bottom,
                           double tl_radius_x,
                           double tl_radius_y,
                           double tr_radius_x,
                           double tr_radius_y,
                           double br_radius_x,
                           double br_radius_y,
                           double bl_radius_x,
                           double bl_radius_y) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto res = fml::MakeRefCounted<RSuperellipse>(
      BuildBounds(SafeNarrow(left), SafeNarrow(top), SafeNarrow(right),
                  SafeNarrow(bottom)),
      BuildRadii(SafeNarrow(tl_radius_x), SafeNarrow(tl_radius_y),
                 SafeNarrow(tr_radius_x), SafeNarrow(tr_radius_y),
                 SafeNarrow(br_radius_x), SafeNarrow(br_radius_y),
                 SafeNarrow(bl_radius_x), SafeNarrow(bl_radius_y)));
  res->AssociateWithDartWrapper(wrapper);
}

RSuperellipse::RSuperellipse(flutter::DlRect bounds,
                             impeller::RoundingRadii radii)
    : bounds_(bounds), radii_(radii) {}

RSuperellipse::~RSuperellipse() = default;

flutter::DlRoundSuperellipse RSuperellipse::rsuperellipse() const {
  return flutter::DlRoundSuperellipse::MakeRectRadii(bounds_, radii_);
}

impeller::RoundSuperellipseParam RSuperellipse::param() const {
  return impeller::RoundSuperellipseParam::MakeBoundsRadii(bounds_, radii_);
}

bool RSuperellipse::contains(double x, double y) {
  return param().Contains(DlPoint(SafeNarrow(x), SafeNarrow(y)));
}

}  // namespace flutter
