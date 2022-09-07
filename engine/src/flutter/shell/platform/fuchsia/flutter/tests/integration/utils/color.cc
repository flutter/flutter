// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "color.h"

namespace fuchsia_test_utils {

// RGBA hex dump
std::ostream& operator<<(std::ostream& os, const Color& c) {
  char rgba[9] = {};
  snprintf(rgba, (sizeof(rgba) / sizeof(char)), "%02X%02X%02X%02X", c.r, c.g,
           c.b, c.a);
  return os << rgba;
}

}  // namespace fuchsia_test_utils
