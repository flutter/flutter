// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Point.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Point::toString() const {
  std::stringstream stream;
  stream << x << "," << y;
  return stream.str();
}

void Point::fromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> x;
  stream.ignore();
  stream >> y;
}

double Point::distanceSquared(const Point& p) const {
  double dx = p.x - x;
  double dy = p.y - y;
  return dx * dx + dy * dy;
}

double Point::distance(const Point& p) const {
  return sqrt(distanceSquared(p));
}

}  // namespace geom
}  // namespace rl
