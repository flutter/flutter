// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_SCREENSHOT_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_SCREENSHOT_H_

#include <fuchsia/ui/scenic/cpp/fidl.h>

#include <map>
#include <ostream>
#include <tuple>

#include "color.h"

namespace fuchsia_test_utils {

/// A screenshot that has been taken from a Fuchsia device.
class Screenshot {
 public:
  Screenshot(const fuchsia::ui::scenic::ScreenshotData& screenshot_data);

  size_t width() const { return width_; }
  size_t height() const { return height_; }
  bool empty() const { return width_ == 0 || height_ == 0; }

  // Notably the indexer behaves like a row-major matrix, whereas the iterator
  // behaves like a flat array. *IMPORTANT*: Use caution because index values
  // are not validated, and out of bounds indexes can introduce memory errors.
  // Also when indexing a specific pixel with |screenshot[a][b]|, note that
  // the order of the indexes is non-traditional. The first index is for the
  // |y| position (the row), followed by the |x| position. Consider using
  // |ColorAtPixelXY()| instead.
  const Color* operator[](size_t row) const;

  // Coordinates are in the range [0, 1).
  const Color& ColorAt(float x, float y) const;

  // Returns the color of a pixel at the integer x and y indexes, after
  // asserting that the indexes are in range.
  const Color& ColorAtPixelXY(size_t ix, size_t iy) const;

  // Notably the iterator behaves like a flat array, whereas the indexer behaves
  // like a row-major matrix.
  const Color* begin() const;
  const Color* end() const;

  // Counts the frequencies of each color in a screenshot.
  std::map<Color, size_t> Histogram() const;

 private:
  const size_t width_, height_;
  std::vector<uint8_t> data_;
};

}  // namespace fuchsia_test_utils

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_INTEGRATION_UTILS_SCREENSHOT_H_
