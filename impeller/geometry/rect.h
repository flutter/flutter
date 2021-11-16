// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

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
    return p.x >= origin.x && p.x <= size.width && p.y >= origin.y &&
           p.y <= size.height;
  }

  constexpr bool IsZero() const { return size.IsZero(); }

  constexpr bool IsEmpty() const { return size.IsEmpty(); }

  constexpr TRect WithPoint(const TPoint<Type>& p) const {
    TRect copy = *this;
    if (p.x < origin.x) {
      copy.origin.x = p.x;
      copy.size.width += (origin.x - p.x);
    }

    if (p.y < origin.y) {
      copy.origin.y = p.y;
      copy.size.height += (origin.y - p.y);
    }

    if (p.x > (size.width + origin.x)) {
      copy.size.width += p.x - (size.width + origin.x);
    }

    if (p.y > (size.height + origin.y)) {
      copy.size.height += p.y - (size.height + origin.y);
    }

    return copy;
  }

  constexpr TRect WithPoints(const std::vector<TPoint<Type>>& points) const {
    TRect box = *this;
    for (const auto& point : points) {
      box = box.WithPoint(point);
    }
    return box;
  }
};

using Rect = TRect<Scalar>;
using IRect = TRect<int64_t>;

}  // namespace impeller
