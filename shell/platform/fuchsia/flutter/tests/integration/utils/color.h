// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_COLOR_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_COLOR_H_

#include <map>
#include <ostream>
#include <tuple>

namespace fuchsia_test_utils {

struct Color {
  // Constructor is idiomatic RGBA, but memory layout is native BGRA.
  constexpr Color(uint8_t r, uint8_t g, uint8_t b, uint8_t a)
      : b(b), g(g), r(r), a(a) {}

  uint8_t b;
  uint8_t g;
  uint8_t r;
  uint8_t a;
};

inline bool operator==(const Color& a, const Color& b) {
  return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
}

inline bool operator<(const Color& a, const Color& b) {
  return std::tie(a.r, a.g, a.b, a.a) < std::tie(b.r, b.g, b.b, b.a);
}

// RGBA hex dump. Note that this differs from the internal BGRA memory layout.
std::ostream& operator<<(std::ostream& os, const Color& c);

}  // namespace fuchsia_test_utils

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_COLOR_H_
