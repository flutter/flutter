// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/skia_conversions.h"
#include "display_list/dl_color.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

namespace impeller {
namespace skia_conversions {

static inline bool SkScalarsNearlyEqual(SkScalar a,
                                        SkScalar b,
                                        SkScalar c,
                                        SkScalar d) {
  return SkScalarNearlyEqual(a, b, kEhCloseEnough) &&
         SkScalarNearlyEqual(a, c, kEhCloseEnough) &&
         SkScalarNearlyEqual(a, d, kEhCloseEnough);
}

bool IsNearlySimpleRRect(const SkRRect& rr) {
  auto [xa, ya] = rr.radii(SkRRect::kUpperLeft_Corner);
  auto [xb, yb] = rr.radii(SkRRect::kLowerLeft_Corner);
  auto [xc, yc] = rr.radii(SkRRect::kUpperRight_Corner);
  auto [xd, yd] = rr.radii(SkRRect::kLowerRight_Corner);
  return SkScalarsNearlyEqual(xa, xb, xc, xd) &&
         SkScalarsNearlyEqual(ya, yb, yc, yd);
}

Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

std::optional<Rect> ToRect(const SkRect* rect) {
  if (rect == nullptr) {
    return std::nullopt;
  }
  return Rect::MakeLTRB(rect->fLeft, rect->fTop, rect->fRight, rect->fBottom);
}

std::optional<const Rect> ToRect(const flutter::DlRect* rect) {
  if (rect == nullptr) {
    return std::nullopt;
  }
  return *rect;
}

std::vector<Rect> ToRects(const SkRect tex[], int count) {
  auto result = std::vector<Rect>();
  for (int i = 0; i < count; i++) {
    result.push_back(ToRect(tex[i]));
  }
  return result;
}

std::vector<Rect> ToRects(const flutter::DlRect tex[], int count) {
  auto result = std::vector<Rect>();
  for (int i = 0; i < count; i++) {
    result.push_back(tex[i]);
  }
  return result;
}

std::vector<Point> ToPoints(const SkPoint points[], int count) {
  std::vector<Point> result(count);
  for (auto i = 0; i < count; i++) {
    result[i] = ToPoint(points[i]);
  }
  return result;
}

std::vector<Point> ToPoints(const flutter::DlPoint points[], int count) {
  std::vector<Point> result(count);
  for (auto i = 0; i < count; i++) {
    result[i] = points[i];
  }
  return result;
}

PathBuilder::RoundingRadii ToRoundingRadii(const SkRRect& rrect) {
  using Corner = SkRRect::Corner;
  PathBuilder::RoundingRadii radii;
  radii.bottom_left = ToPoint(rrect.radii(Corner::kLowerLeft_Corner));
  radii.bottom_right = ToPoint(rrect.radii(Corner::kLowerRight_Corner));
  radii.top_left = ToPoint(rrect.radii(Corner::kUpperLeft_Corner));
  radii.top_right = ToPoint(rrect.radii(Corner::kUpperRight_Corner));
  return radii;
}

Path ToPath(const SkRRect& rrect) {
  return PathBuilder{}
      .AddRoundedRect(ToRect(rrect.getBounds()), ToRoundingRadii(rrect))
      .SetConvexity(Convexity::kConvex)
      .SetBounds(ToRect(rrect.getBounds()))
      .TakePath();
}

Point ToPoint(const SkPoint& point) {
  return Point::MakeXY(point.fX, point.fY);
}

Size ToSize(const SkPoint& point) {
  return Size(point.fX, point.fY);
}

Color ToColor(const flutter::DlColor& color) {
  FML_DCHECK(color.getColorSpace() == flutter::DlColorSpace::kExtendedSRGB ||
             color.getColorSpace() == flutter::DlColorSpace::kSRGB);
  return {
      static_cast<Scalar>(color.getRedF()),    //
      static_cast<Scalar>(color.getGreenF()),  //
      static_cast<Scalar>(color.getBlueF()),   //
      static_cast<Scalar>(color.getAlphaF())   //
  };
}

std::vector<Matrix> ToRSXForms(const SkRSXform xform[], int count) {
  auto result = std::vector<Matrix>();
  for (int i = 0; i < count; i++) {
    auto form = xform[i];
    // clang-format off
    auto matrix = Matrix{
      form.fSCos, form.fSSin, 0, 0,
     -form.fSSin, form.fSCos, 0, 0,
      0,          0,          1, 0,
      form.fTx,   form.fTy,   0, 1
    };
    // clang-format on
    result.push_back(matrix);
  }
  return result;
}

std::optional<impeller::PixelFormat> ToPixelFormat(SkColorType type) {
  switch (type) {
    case kRGBA_8888_SkColorType:
      return impeller::PixelFormat::kR8G8B8A8UNormInt;
    case kBGRA_8888_SkColorType:
      return impeller::PixelFormat::kB8G8R8A8UNormInt;
    case kRGBA_F16_SkColorType:
      return impeller::PixelFormat::kR16G16B16A16Float;
    case kBGR_101010x_XR_SkColorType:
      return impeller::PixelFormat::kB10G10R10XR;
    default:
      return std::nullopt;
  }
  return std::nullopt;
}

void ConvertStops(const flutter::DlGradientColorSourceBase* gradient,
                  std::vector<Color>& colors,
                  std::vector<float>& stops) {
  FML_DCHECK(gradient->stop_count() >= 2)
      << "stop_count:" << gradient->stop_count();

  auto* dl_colors = gradient->colors();
  auto* dl_stops = gradient->stops();
  if (dl_stops[0] != 0.0) {
    colors.emplace_back(skia_conversions::ToColor(dl_colors[0]));
    stops.emplace_back(0);
  }
  for (auto i = 0; i < gradient->stop_count(); i++) {
    colors.emplace_back(skia_conversions::ToColor(dl_colors[i]));
    stops.emplace_back(std::clamp(dl_stops[i], 0.0f, 1.0f));
  }
  if (dl_stops[gradient->stop_count() - 1] != 1.0) {
    colors.emplace_back(colors.back());
    stops.emplace_back(1.0);
  }
  for (auto i = 1; i < gradient->stop_count(); i++) {
    stops[i] = std::clamp(stops[i], stops[i - 1], stops[i]);
  }
}

}  // namespace skia_conversions
}  // namespace impeller
