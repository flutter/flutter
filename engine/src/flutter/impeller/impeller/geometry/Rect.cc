// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Rect.h"
#include <sstream>

namespace rl {
namespace geom {

Rect Rect::WithPoint(const Point& p) const {
  Rect copy = *this;
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

Rect Rect::WithPoints(const std::vector<Point>& points) const {
  Rect box = *this;
  for (const auto& point : points) {
    box = box.WithPoint(point);
  }
  return box;
}

std::string Rect::ToString() const {
  std::stringstream stream;
  stream << origin.x << "," << origin.y << "," << size.width << ","
         << size.height;
  return stream.str();
}

void Rect::FromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> origin.x;
  stream.ignore();
  stream >> origin.y;
  stream.ignore();
  stream >> size.width;
  stream.ignore();
  stream >> size.height;
}

}  // namespace geom
}  // namespace rl
