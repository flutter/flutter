// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Size.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Size::toString() const {
  std::stringstream stream;
  stream << width << "," << height;
  return stream.str();
}

void Size::fromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> width;
  stream.ignore();
  stream >> height;
}

}  // namespace geom
}  // namespace rl
