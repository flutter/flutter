// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_RECT_H_
#define FLUTTER_IMPELLER_GEOMETRY_RECT_H_

#include <array>
#include <optional>
#include <ostream>
#include <vector>

#include "fml/logging.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

template <class T>
struct TRect {
  using Type = T;

  constexpr TRect() : origin({0, 0}), size({0, 0}) {}

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

  template <typename U>
  constexpr static std::optional<TRect> MakePointBounds(const U& value) {
    return MakePointBounds(value.begin(), value.end());
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
      : origin(static_cast<T>(other.GetX()), static_cast<T>(other.GetY())),
        size(static_cast<T>(other.GetWidth()),
             static_cast<T>(other.GetHeight())) {}

  [[nodiscard]] constexpr TRect operator+(const TRect& r) const {
    return TRect({origin.x + r.origin.x, origin.y + r.origin.y},
                 {size.width + r.size.width, size.height + r.size.height});
  }

  [[nodiscard]] constexpr TRect operator-(const TRect& r) const {
    return TRect({origin.x - r.origin.x, origin.y - r.origin.y},
                 {size.width - r.size.width, size.height - r.size.height});
  }

  [[nodiscard]] constexpr TRect operator*(Type scale) const {
    return Scale(scale);
  }

  [[nodiscard]] constexpr TRect operator*(const TRect& r) const {
    return TRect({origin.x * r.origin.x, origin.y * r.origin.y},
                 {size.width * r.size.width, size.height * r.size.height});
  }

  [[nodiscard]] constexpr bool operator==(const TRect& r) const {
    return origin == r.origin && size == r.size;
  }

  [[nodiscard]] constexpr TRect Scale(Type scale) const {
    return TRect({origin.x * scale, origin.y * scale},
                 {size.width * scale, size.height * scale});
  }

  [[nodiscard]] constexpr TRect Scale(Type scale_x, Type scale_y) const {
    return TRect({origin.x * scale_x, origin.y * scale_y},
                 {size.width * scale_x, size.height * scale_y});
  }

  [[nodiscard]] constexpr TRect Scale(TPoint<T> scale) const {
    return TRect({origin.x * scale.x, origin.y * scale.y},
                 {size.width * scale.x, size.height * scale.y});
  }

  [[nodiscard]] constexpr TRect Scale(TSize<T> scale) const {
    return Scale(TPoint<T>(scale));
  }

  [[nodiscard]] constexpr bool Contains(const TPoint<Type>& p) const {
    return p.x >= GetLeft() && p.x < GetRight() && p.y >= GetTop() &&
           p.y < GetBottom();
  }

  [[nodiscard]] constexpr bool Contains(const TRect& o) const {
    return o.GetLeft() >= GetLeft() && o.GetTop() >= GetTop() &&
           o.GetRight() <= GetRight() && o.GetBottom() <= GetBottom();
  }

  /// Returns true if either of the width or height are 0, negative, or NaN.
  [[nodiscard]] constexpr bool IsEmpty() const { return size.IsEmpty(); }

  /// Returns true if width and height are equal and neither is NaN.
  [[nodiscard]] constexpr bool IsSquare() const { return size.IsSquare(); }

  [[nodiscard]] constexpr bool IsMaximum() const {
    return *this == MakeMaximum();
  }

  /// @brief Returns the upper left corner of the rectangle as specified
  ///        when it was constructed.
  ///
  ///        Note that unlike the |GetLeft|, |GetTop|, and |GetLeftTop|
  ///        methods which will return values as if the rectangle had been
  ///        "unswapped" by calling |GetPositive| on it, this method
  ///        returns the raw origin values.
  [[nodiscard]] constexpr TPoint<Type> GetOrigin() const { return origin; }

  /// @brief Returns the size of the rectangle as specified when it was
  ///        constructed and which may be negative in either width or
  ///        height.
  [[nodiscard]] constexpr TSize<Type> GetSize() const { return size; }

  /// @brief Returns the X coordinate of the upper left corner, equivalent
  ///        to |GetOrigin().x|
  [[nodiscard]] constexpr Type GetX() const { return origin.x; }

  /// @brief Returns the Y coordinate of the upper left corner, equivalent
  ///        to |GetOrigin().y|
  [[nodiscard]] constexpr Type GetY() const { return origin.y; }

  /// @brief Returns the width of the rectangle, equivalent to
  ///        |GetSize().width|
  [[nodiscard]] constexpr Type GetWidth() const { return size.width; }

  /// @brief Returns the height of the rectangle, equivalent to
  ///        |GetSize().height|
  [[nodiscard]] constexpr Type GetHeight() const { return size.height; }

  [[nodiscard]] constexpr auto GetLeft() const {
    if (IsMaximum()) {
      return -std::numeric_limits<Type>::infinity();
    }
    return std::min(origin.x, origin.x + size.width);
  }

  [[nodiscard]] constexpr auto GetTop() const {
    if (IsMaximum()) {
      return -std::numeric_limits<Type>::infinity();
    }
    return std::min(origin.y, origin.y + size.height);
  }

  [[nodiscard]] constexpr auto GetRight() const {
    if (IsMaximum()) {
      return std::numeric_limits<Type>::infinity();
    }
    return std::max(origin.x, origin.x + size.width);
  }

  [[nodiscard]] constexpr auto GetBottom() const {
    if (IsMaximum()) {
      return std::numeric_limits<Type>::infinity();
    }
    return std::max(origin.y, origin.y + size.height);
  }

  [[nodiscard]] constexpr TPoint<T> GetLeftTop() const {
    return {GetLeft(), GetTop()};
  }

  [[nodiscard]] constexpr TPoint<T> GetRightTop() const {
    return {GetRight(), GetTop()};
  }

  [[nodiscard]] constexpr TPoint<T> GetLeftBottom() const {
    return {GetLeft(), GetBottom()};
  }

  [[nodiscard]] constexpr TPoint<T> GetRightBottom() const {
    return {GetRight(), GetBottom()};
  }

  /// @brief  Get the area of the rectangle, equivalent to |GetSize().Area()|
  [[nodiscard]] constexpr T Area() const { return size.Area(); }

  /// @brief  Get the center point as a |Point|.
  [[nodiscard]] constexpr Point GetCenter() const {
    return Point(origin.x + size.width * 0.5f, origin.y + size.height * 0.5f);
  }

  [[nodiscard]] constexpr std::array<T, 4> GetLTRB() const {
    return {GetLeft(), GetTop(), GetRight(), GetBottom()};
  }

  /// @brief  Get the x, y coordinates of the origin and the width and
  ///         height of the rectangle in an array.
  [[nodiscard]] constexpr std::array<T, 4> GetXYWH() const {
    return {origin.x, origin.y, size.width, size.height};
  }

  /// @brief  Get a version of this rectangle that has a non-negative size.
  [[nodiscard]] constexpr TRect GetPositive() const {
    auto ltrb = GetLTRB();
    return MakeLTRB(ltrb[0], ltrb[1], ltrb[2], ltrb[3]);
  }

  /// @brief  Get the points that represent the 4 corners of this rectangle.
  ///         The order is: Top left, top right, bottom left, bottom right.
  [[nodiscard]] constexpr std::array<TPoint<T>, 4> GetPoints() const {
    auto [left, top, right, bottom] = GetLTRB();
    return {TPoint(left, top), TPoint(right, top), TPoint(left, bottom),
            TPoint(right, bottom)};
  }

  [[nodiscard]] constexpr std::array<TPoint<T>, 4> GetTransformedPoints(
      const Matrix& transform) const {
    auto points = GetPoints();
    for (size_t i = 0; i < points.size(); i++) {
      points[i] = transform * points[i];
    }
    return points;
  }

  /// @brief  Creates a new bounding box that contains this transformed
  ///         rectangle.
  [[nodiscard]] constexpr TRect TransformBounds(const Matrix& transform) const {
    auto points = GetTransformedPoints(transform);
    auto bounds = TRect::MakePointBounds(points.begin(), points.end());
    if (bounds.has_value()) {
      return bounds.value();
    }
    FML_UNREACHABLE();
  }

  /// @brief  Constructs a Matrix that will map all points in the coordinate
  ///         space of the rectangle into a new normalized coordinate space
  ///         where the upper left corner of the rectangle maps to (0, 0)
  ///         and the lower right corner of the rectangle maps to (1, 1).
  ///
  ///         Empty and non-finite rectangles will return a zero-scaling
  ///         transform that maps all points to (0, 0).
  [[nodiscard]] constexpr Matrix GetNormalizingTransform() const {
    if (!IsEmpty()) {
      Scalar sx = 1.0 / size.width;
      Scalar sy = 1.0 / size.height;
      Scalar tx = origin.x * -sx;
      Scalar ty = origin.y * -sy;

      // Exclude NaN and infinities and either scale underflowing to zero
      if (sx != 0.0 && sy != 0.0 && 0.0 * sx * sy * tx * ty == 0.0) {
        // clang-format off
        return Matrix(  sx, 0.0f, 0.0f, 0.0f,
                      0.0f,   sy, 0.0f, 0.0f,
                      0.0f, 0.0f, 1.0f, 0.0f,
                        tx,   ty, 0.0f, 1.0f);
        // clang-format on
      }
    }

    // Map all coordinates to the origin.
    return Matrix::MakeScale({0.0f, 0.0f, 1.0f});
  }

  [[nodiscard]] constexpr TRect Union(const TRect& o) const {
    auto this_ltrb = GetLTRB();
    auto other_ltrb = o.GetLTRB();
    return TRect::MakeLTRB(std::min(this_ltrb[0], other_ltrb[0]),  //
                           std::min(this_ltrb[1], other_ltrb[1]),  //
                           std::max(this_ltrb[2], other_ltrb[2]),  //
                           std::max(this_ltrb[3], other_ltrb[3])   //
    );
  }

  [[nodiscard]] constexpr std::optional<TRect<T>> Intersection(
      const TRect& o) const {
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

  [[nodiscard]] constexpr bool IntersectsWithRect(const TRect& o) const {
    return Intersection(o).has_value();
  }

  /// @brief Returns the new boundary rectangle that would result from the
  ///        rectangle being cutout by a second rectangle.
  [[nodiscard]] constexpr std::optional<TRect<T>> Cutout(const TRect& o) const {
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
  [[nodiscard]] constexpr TRect<T> Shift(TPoint<T> offset) const {
    return TRect(origin.x + offset.x, origin.y + offset.y, size.width,
                 size.height);
  }

  /// @brief  Returns a rectangle with expanded edges. Negative expansion
  ///         results in shrinking.
  [[nodiscard]] constexpr TRect<T> Expand(T left,
                                          T top,
                                          T right,
                                          T bottom) const {
    return TRect(origin.x - left,            //
                 origin.y - top,             //
                 size.width + left + right,  //
                 size.height + top + bottom);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  [[nodiscard]] constexpr TRect<T> Expand(T amount) const {
    return TRect(origin.x - amount,        //
                 origin.y - amount,        //
                 size.width + amount * 2,  //
                 size.height + amount * 2);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  [[nodiscard]] constexpr TRect<T> Expand(T horizontal_amount,
                                          T vertical_amount) const {
    return TRect(origin.x - horizontal_amount,        //
                 origin.y - vertical_amount,          //
                 size.width + horizontal_amount * 2,  //
                 size.height + vertical_amount * 2);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  [[nodiscard]] constexpr TRect<T> Expand(TPoint<T> amount) const {
    return TRect(origin.x - amount.x,        //
                 origin.y - amount.y,        //
                 size.width + amount.x * 2,  //
                 size.height + amount.y * 2);
  }

  /// @brief  Returns a rectangle with expanded edges in all directions.
  ///         Negative expansion results in shrinking.
  [[nodiscard]] constexpr TRect<T> Expand(TSize<T> amount) const {
    return TRect(origin.x - amount.width,        //
                 origin.y - amount.height,       //
                 size.width + amount.width * 2,  //
                 size.height + amount.height * 2);
  }

  /// @brief  Returns a new rectangle that represents the projection of the
  ///         source rectangle onto this rectangle. In other words, the source
  ///         rectangle is redefined in terms of the corrdinate space of this
  ///         rectangle.
  [[nodiscard]] constexpr TRect<T> Project(TRect<T> source) const {
    return source.Shift(-origin).Scale(
        TSize<T>(1.0 / static_cast<Scalar>(size.width),
                 1.0 / static_cast<Scalar>(size.height)));
  }

  [[nodiscard]] constexpr static TRect RoundOut(const TRect& r) {
    return TRect::MakeLTRB(floor(r.GetLeft()), floor(r.GetTop()),
                           ceil(r.GetRight()), ceil(r.GetBottom()));
  }

  [[nodiscard]] constexpr static std::optional<TRect> Union(
      const TRect& a,
      const std::optional<TRect> b) {
    return b.has_value() ? a.Union(b.value()) : a;
  }

  [[nodiscard]] constexpr static std::optional<TRect> Union(
      const std::optional<TRect> a,
      const TRect& b) {
    return Union(b, a);
  }

  [[nodiscard]] constexpr static std::optional<TRect> Union(
      const std::optional<TRect> a,
      const std::optional<TRect> b) {
    return a.has_value() ? Union(a.value(), b) : b;
  }

  [[nodiscard]] constexpr static std::optional<TRect> Intersection(
      const TRect& a,
      const std::optional<TRect> b) {
    return b.has_value() ? a.Intersection(b.value()) : a;
  }

  [[nodiscard]] constexpr static std::optional<TRect> Intersection(
      const std::optional<TRect> a,
      const TRect& b) {
    return Intersection(b, a);
  }

  [[nodiscard]] constexpr static std::optional<TRect> Intersection(
      const std::optional<TRect> a,
      const std::optional<TRect> b) {
    return a.has_value() ? Intersection(a.value(), b) : b;
  }

 private:
  constexpr TRect(Type x, Type y, Type width, Type height)
      : origin(x, y), size(width, height) {}

  constexpr TRect(TPoint<Type> origin, TSize<Type> size)
      : origin(origin), size(size) {}

  // NOLINTBEGIN
  // These fields should be named origin_ and size_, but will be renamed to
  // left_/top_/right_/bottom_ during the next phase of the reworking of the
  // TRect class and we will deal with the renaming of all the usages here
  // and in path_builder.cc at that time
  TPoint<Type> origin;
  TSize<Type> size;
  // NOLINTEND
};

using Rect = TRect<Scalar>;
using IRect = TRect<int64_t>;

}  // namespace impeller

namespace std {

template <class T>
inline std::ostream& operator<<(std::ostream& out,
                                const impeller::TRect<T>& r) {
  out << "(" << r.GetOrigin() << ", " << r.GetSize() << ")";
  return out;
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_GEOMETRY_RECT_H_
