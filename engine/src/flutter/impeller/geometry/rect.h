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

  constexpr static TRect MakeOriginSize(const TPoint<Type>& origin,
                                        const TSize<Type>& size) {
    return TRect(origin, size);
  }

  template <class U>
  constexpr static TRect MakeSize(const TSize<U>& size) {
    return TRect(0.0, 0.0, size.width, size.height);
  }

  template <typename PointIter>
  constexpr static std::optional<TRect> MakePointBounds(const PointIter first,
                                                        const PointIter last) {
    if (first == last) {
      return std::nullopt;
    }
    auto left = first->x;
    auto top = first->y;
    auto right = first->x;
    auto bottom = first->y;
    for (auto it = first + 1; it < last; ++it) {
      left = std::min(left, it->x);
      top = std::min(top, it->y);
      right = std::max(right, it->x);
      bottom = std::max(bottom, it->y);
    }
    return TRect::MakeLTRB(left, top, right, bottom);
  }

  constexpr static TRect MakeMaximum() {
    return TRect::MakeLTRB(-std::numeric_limits<Type>::infinity(),
                           -std::numeric_limits<Type>::infinity(),
                           std::numeric_limits<Type>::infinity(),
                           std::numeric_limits<Type>::infinity());
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

  constexpr TRect operator*(Type scale) const { return Scale(scale); }

  constexpr TRect operator*(const TRect& r) const {
    return TRect({origin.x * r.origin.x, origin.y * r.origin.y},
                 {size.width * r.size.width, size.height * r.size.height});
  }

  constexpr bool operator==(const TRect& r) const {
    return origin == r.origin && size == r.size;
  }

  constexpr TRect Scale(Type scale) const {
    return TRect({origin.x * scale, origin.y * scale},
                 {size.width * scale, size.height * scale});
  }

  constexpr TRect Scale(TPoint<T> scale) const {
    return TRect({origin.x * scale.x, origin.y * scale.y},
                 {size.width * scale.x, size.height * scale.y});
  }

  constexpr TRect Scale(TSize<T> scale) const {
    return Scale(TPoint<T>(scale));
  }

  constexpr bool Contains(const TPoint<Type>& p) const {
    return p.x >= GetLeft() && p.x < GetRight() && p.y >= GetTop() &&
           p.y < GetBottom();
  }

  constexpr bool Contains(const TRect& o) const {
    return Union(o).size == size;
  }

  constexpr bool IsZero() const { return size.IsZero(); }

  constexpr bool IsEmpty() const { return size.IsEmpty(); }

  constexpr bool IsMaximum() const { return *this == MakeMaximum(); }

  /// @brief Returns the upper left corner of the rectangle as specified
  ///        when it was constructed.
  ///
  ///        Note that unlike the |GetLeft|, |GetTop|, and |GetLeftTop|
  ///        methods which will return values as if the rectangle had been
  ///        "unswapped" by calling |GetPositive| on it, this method
  ///        returns the raw origin values.
  constexpr TPoint<Type> GetOrigin() const { return origin; }

  /// @brief Returns the size of the rectangle as specified when it was
  ///        constructed and which may be negative in either width or
  ///        height.
  constexpr TSize<Type> GetSize() const { return size; }

  constexpr auto GetLeft() const {
    if (IsMaximum()) {
      return -std::numeric_limits<Type>::infinity();
    }
    return std::min(origin.x, origin.x + size.width);
  }

  constexpr auto GetTop() const {
    if (IsMaximum()) {
      return -std::numeric_limits<Type>::infinity();
    }
    return std::min(origin.y, origin.y + size.height);
  }

  constexpr auto GetRight() const {
    if (IsMaximum()) {
      return std::numeric_limits<Type>::infinity();
    }
    return std::max(origin.x, origin.x + size.width);
  }

  constexpr auto GetBottom() const {
    if (IsMaximum()) {
      return std::numeric_limits<Type>::infinity();
    }
    return std::max(origin.y, origin.y + size.height);
  }

  constexpr TPoint<T> GetLeftTop() const { return {GetLeft(), GetTop()}; }

  constexpr TPoint<T> GetRightTop() const { return {GetRight(), GetTop()}; }

  constexpr TPoint<T> GetLeftBottom() const { return {GetLeft(), GetBottom()}; }

  constexpr TPoint<T> GetRightBottom() const {
    return {GetRight(), GetBottom()};
  }

  constexpr std::array<T, 4> GetLTRB() const {
    return {GetLeft(), GetTop(), GetRight(), GetBottom()};
  }

  /// @brief  Get a version of this rectangle that has a non-negative size.
  constexpr TRect GetPositive() const {
    auto ltrb = GetLTRB();
    return MakeLTRB(ltrb[0], ltrb[1], ltrb[2], ltrb[3]);
  }

  /// @brief  Get the points that represent the 4 corners of this rectangle. The
  ///         order is: Top left, top right, bottom left, bottom right.
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
    return TRect::MakePointBounds(points.begin(), points.end()).value();
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
    return Intersection(o).has_value();
  }

  /// @brief Returns the new boundary rectangle that would result from the
  ///        rectangle being cutout by a second rectangle.
  constexpr std::optional<TRect<T>> Cutout(const TRect& o) const {
    const auto& [a_left, a_top, a_right, a_bottom] = GetLTRB();  // Source rect.
    const auto& [b_left, b_top, b_right, b_bottom] = o.GetLTRB();  // Cutout.
    if (b_left <= a_left && b_right >= a_right) {
      if (b_top <= a_top && b_bottom >= a_bottom) {
        // Full cutout.
        return std::nullopt;
      }
      if (b_top <= a_top && b_bottom > a_top) {
        // Cuts off the top.
        return TRect::MakeLTRB(a_left, b_bottom, a_right, a_bottom);
      }
      if (b_bottom >= a_bottom && b_top < a_bottom) {
        // Cuts out the bottom.
        return TRect::MakeLTRB(a_left, a_top, a_right, b_top);
      }
    }
    if (b_top <= a_top && b_bottom >= a_bottom) {
      if (b_left <= a_left && b_right > a_left) {
        // Cuts out the left.
        return TRect::MakeLTRB(b_right, a_top, a_right, a_bottom);
      }
      if (b_right >= a_right && b_left < a_right) {
        // Cuts out the right.
        return TRect::MakeLTRB(a_left, a_top, b_left, a_bottom);
      }
    }

    return *this;
  }

  /// @brief  Returns a new rectangle translated by the given offset.
  constexpr TRect<T> Shift(TPoint<T> offset) const {
    return TRect(origin.x + offset.x, origin.y + offset.y, size.width,
                 size.height);
  }

  /// @brief  Returns a rectangle with expanded edges. Negative expansion
  ///         results in shrinking.
  constexpr TRect<T> Expand(T left, T top, T right, T bottom) const {
    return TRect(origin.x - left,            //
                 origin.y - top,             //
                 size.width + left + right,  //
                 size.height + top + bottom);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  constexpr TRect<T> Expand(T amount) const {
    return TRect(origin.x - amount,        //
                 origin.y - amount,        //
                 size.width + amount * 2,  //
                 size.height + amount * 2);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  constexpr TRect<T> Expand(TPoint<T> amount) const {
    return TRect(origin.x - amount.x,        //
                 origin.y - amount.y,        //
                 size.width + amount.x * 2,  //
                 size.height + amount.y * 2);
  }

  /// @brief  Returns a new rectangle that represents the projection of the
  ///         source rectangle onto this rectangle. In other words, the source
  ///         rectangle is redefined in terms of the corrdinate space of this
  ///         rectangle.
  constexpr TRect<T> Project(TRect<T> source) const {
    return source.Shift(-origin).Scale(
        TSize<T>(1.0 / static_cast<Scalar>(size.width),
                 1.0 / static_cast<Scalar>(size.height)));
  }

  constexpr static TRect RoundOut(const TRect& r) {
    return TRect::MakeLTRB(floor(r.GetLeft()), floor(r.GetTop()),
                           ceil(r.GetRight()), ceil(r.GetBottom()));
  }

  constexpr static std::optional<TRect> Union(const TRect& a,
                                              const std::optional<TRect> b) {
    return b.has_value() ? a.Union(b.value()) : a;
  }

  constexpr static std::optional<TRect> Union(const std::optional<TRect> a,
                                              const TRect& b) {
    return Union(b, a);
  }

  constexpr static std::optional<TRect> Union(const std::optional<TRect> a,
                                              const std::optional<TRect> b) {
    return a.has_value() ? Union(a.value(), b) : b;
  }

  constexpr static std::optional<TRect> Intersection(
      const TRect& a,
      const std::optional<TRect> b) {
    return b.has_value() ? a.Intersection(b.value()) : a;
  }

  constexpr static std::optional<TRect> Intersection(
      const std::optional<TRect> a,
      const TRect& b) {
    return Intersection(b, a);
  }

  constexpr static std::optional<TRect> Intersection(
      const std::optional<TRect> a,
      const std::optional<TRect> b) {
    return a.has_value() ? Intersection(a.value(), b) : b;
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
