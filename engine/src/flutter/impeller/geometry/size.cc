// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "size.h"
#include <sstream>

namespace impeller {

std::string Size::ToString() const {
  std::stringstream stream;
  stream << width << "," << height;
  return stream.str();
}

void Size::FromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> width;
  stream.ignore();
  stream >> height;
}

}  // namespace impeller
