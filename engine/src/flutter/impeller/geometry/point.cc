// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "point.h"
#include <sstream>

namespace impeller {

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

}  // namespace impeller
