// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <array>
#include <optional>
#include <ostream>
#include <vector>

#include "impeller/geometry/matrix.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

template <class T>
struct TRect {
  using Type = T;

  TPoint<Type> origin;
  TSize<Type> size;

  constexpr TRect() : origin({0, 0}), size({0, 0}) {}

  constexpr TRect(TSize<Type> size) : origin({0.0, 0.0}), size(size) {}

  constexpr TRect(TPoint<Type> origin, TSize<Type> size)
      : origin(origin), size(size) {}

  constexpr TRect(const Type components[4])
      : origin(components[0], components[1]),
        size(components[2], components[3]) {}

  constexpr TRect(Type x, Type y, Type width, Type height)
      : origin(x, y), size(width, height) {}

  constexpr static TRect MakeLTRB(Type left,
                                  Type top,
                                  Type right,
                                  Type bottom) {
    return TRect(left, top, right - left, bottom - top);
  }

  constexpr static TRect MakeXYWH(Type x, Type y, Type width, Type height) {
    return TRect(x, y, width, height);
  }

  constexpr static TRect MakeSize(const TSize<Type>& size) {
    return TRect(0.0, 0.0, size.width, size.height);
  }

  constexpr static std::optional<TRect> MakePointBounds(
      const std::vector<TPoint<Type>>& points) {
    if (points.empty()) {
      return std::nullopt;
    }
    auto left = points[0].x;
    auto top = points[0].y;
    auto right = points[0].x;
    auto bottom = points[0].y;
    if (points.size() > 1) {
      for (size_t i = 1; i < points.size(); i++) {
        left = std::min(left, points[i].x);
        top = std::min(top, points[i].y);
        right = std::max(right, points[i].x);
        bottom = std::max(bottom, points[i].y);
      }
    }
    return TRect::MakeLTRB(left, top, right, bottom);
  }

  template <class U>
  constexpr explicit TRect(const TRect<U>& other)
      : origin(static_cast<TPoint<Type>>(other.origin)),
        size(static_cast<TSize<Type>>(other.size)) {}

  constexpr TRect operator+(const TRect& r) const {
    return TRect({origin.x + r.origin.x, origin.y + r.origin.y},
                 {size.width + r.size.width, size.height + r.size.height});
  }

  constexpr TRect operator-(const TRect& r) const {
    return TRect({origin.x - r.origin.x, origin.y - r.origin.y},
                 {size.width - r.size.width, size.height - r.size.height});
  }

  constexpr TRect operator*(Type scale) const {
    return TRect({origin.x * scale, origin.y * scale},
                 {size.width * scale, size.height * scale});
  }

  constexpr TRect operator*(const TRect& r) const {
    return TRect({origin.x * r.origin.x, origin.y * r.origin.y},
                 {size.width * r.size.width, size.height * r.size.height});
  }

  constexpr bool operator==(const TRect& r) const {
    return origin == r.origin && size == r.size;
  }

  constexpr bool Contains(const TPoint<Type>& p) const {
    return p.x >= origin.x && p.x < origin.x + size.width && p.y >= origin.y &&
           p.y < origin.y + size.height;
  }

  constexpr bool Contains(const TRect& o) const {
    return Union(o).size == size;
  }

  constexpr bool IsZero() const { return size.IsZero(); }

  constexpr bool IsEmpty() const { return size.IsEmpty(); }

  constexpr auto GetLeft() const {
    return std::min(origin.x, origin.x + size.width);
  }

  constexpr auto GetTop() const {
    return std::min(origin.y, origin.y + size.height);
  }

  constexpr auto GetRight() const {
    return std::max(origin.x, origin.x + size.width);
  }

  constexpr auto GetBottom() const {
    return std::max(origin.y, origin.y + size.height);
  }

  constexpr std::array<T, 4> GetLTRB() const {
    const auto left = std::min(origin.x, origin.x + size.width);
    const auto top = std::min(origin.y, origin.y + size.height);
    const auto right = std::max(origin.x, origin.x + size.width);
    const auto bottom = std::max(origin.y, origin.y + size.height);
    return {left, top, right, bottom};
  }

  constexpr std::array<TPoint<T>, 4> GetPoints() const {
    auto [left, top, right, bottom] = GetLTRB();
    return {TPoint(left, top), TPoint(right, top), TPoint(left, bottom),
            TPoint(right, bottom)};
  }

  constexpr std::array<TPoint<T>, 4> GetTransformedPoints(
      const Matrix& transform) const {
    auto points = GetPoints();
    for (size_t i = 0; i < points.size(); i++) {
      points[i] = transform * points[i];
    }
    return points;
  }

  /// @brief  Creates a new bounding box that contains this transformed
  ///         rectangle.
  constexpr TRect TransformBounds(const Matrix& transform) const {
    auto points = GetTransformedPoints(transform);
    return TRect::MakePointBounds({points.begin(), points.end()}).value();
  }

  constexpr TRect Union(const TRect& o) const {
    auto this_ltrb = GetLTRB();
    auto other_ltrb = o.GetLTRB();
    return TRect::MakeLTRB(std::min(this_ltrb[0], other_ltrb[0]),  //
                           std::min(this_ltrb[1], other_ltrb[1]),  //
                           std::max(this_ltrb[2], other_ltrb[2]),  //
                           std::max(this_ltrb[3], other_ltrb[3])   //
    );
  }

  constexpr std::optional<TRect<T>> Intersection(const TRect& o) const {
    auto this_ltrb = GetLTRB();
    auto other_ltrb = o.GetLTRB();
    auto intersection =
        TRect::MakeLTRB(std::max(this_ltrb[0], other_ltrb[0]),  //
                        std::max(this_ltrb[1], other_ltrb[1]),  //
                        std::min(this_ltrb[2], other_ltrb[2]),  //
                        std::min(this_ltrb[3], other_ltrb[3])   //
        );
    if (intersection.size.IsEmpty()) {
      return std::nullopt;
    }
    return intersection;
  }

  constexpr bool IntersectsWithRect(const TRect& o) const {
    return Interesection(o).has_value();
  }
};

using Rect = TRect<Scalar>;
using IRect = TRect<int64_t>;

}  // namespace impeller

namespace std {

template <class T>
inline std::ostream& operator<<(std::ostream& out,
                                const impeller::TRect<T>& r) {
  out << "(" << r.origin << ", " << r.size << ")";
  return out;
}

}  // namespace std
