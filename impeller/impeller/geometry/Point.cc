// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Point.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Point::ToString() const {
  std::stringstream stream;
  stream << x << "," << y;
  return stream.str();
}

void Point::FromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> x;
  stream.ignore();
  stream >> y;
}

double Point::GetDistanceSquared(const Point& p) const {
  double dx = p.x - x;
  double dy = p.y - y;
  return dx * dx + dy * dy;
}

double Point::GetDistance(const Point& p) const {
  return sqrt(GetDistanceSquared(p));
}

}  // namespace geom
}  // namespace rl
