// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <zircon/status.h>

#include "flutter/fml/logging.h"
#include "src/ui/testing/views/color.h"

namespace scenic {

// RGBA hex dump
std::ostream& operator<<(std::ostream& os, const Color& c) {
  char rgba[9] = {};
  snprintf(rgba, (sizeof(rgba) / sizeof(char)), "%02X%02X%02X%02X", c.r, c.g,
           c.b, c.a);
  return os << rgba;
}

Screenshot::Screenshot(
    const fuchsia::ui::scenic::ScreenshotData& screenshot_data)
    : width_(screenshot_data.info.width), height_(screenshot_data.info.height) {
  FML_CHECK(screenshot_data.info.pixel_format ==
            fuchsia::images::PixelFormat::BGRA_8)
      << "Non-BGRA_8 pixel formats not supported";

  const auto& buffer = screenshot_data.data.vmo;
  const auto num_bytes = screenshot_data.data.size;

  data_.resize(num_bytes);

  if (num_bytes == 0) {
    return;
  }

  zx_status_t status = buffer.read(&data_[0], 0, num_bytes);
  if (status < 0) {
    FML_LOG(WARNING) << "zx::vmo::read failed " << zx_status_get_string(status);
  }
}

const Color* Screenshot::operator[](size_t row) const {
  return &begin()[row * width_];
}

const Color& Screenshot::ColorAt(float x, float y) const {
  FML_CHECK(x >= 0 && x < 1 && y >= 0 && y < 1)
      << "(" << x << ", " << y << ") is out of bounds [0, 1) x [0, 1)";
  const size_t ix = static_cast<size_t>(x * static_cast<float>(width_));
  const size_t iy = static_cast<size_t>(y * static_cast<float>(height_));
  return (*this)[iy][ix];
}

const Color& Screenshot::ColorAtPixelXY(size_t ix, size_t iy) const {
  FML_CHECK(ix < width_ && iy < height_);
  return (*this)[iy][ix];
}

const Color* Screenshot::begin() const {
  return reinterpret_cast<const Color*>(data_.data());
}

const Color* Screenshot::end() const {
  return &begin()[width_ * height_];
}

std::map<Color, size_t> Screenshot::Histogram() const {
  std::map<Color, size_t> histogram;

  for (const auto color : *this) {
    ++histogram[color];
  }

  return histogram;
}

}  // namespace scenic
