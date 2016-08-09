// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/geometry/cpp/formatting.h"

#include <ostream>

namespace mojo {

std::ostream& operator<<(std::ostream& os, const mojo::Point& value) {
  return os << "{x=" << value.x << ", y=" << value.y << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::PointF& value) {
  return os << "{x=" << value.x << ", y=" << value.y << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::Rect& value) {
  return os << "{x=" << value.x << ", y=" << value.y
            << ", width=" << value.width << ", height=" << value.height << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::RectF& value) {
  return os << "{x=" << value.x << ", y=" << value.y
            << ", width=" << value.width << ", height=" << value.height << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::RRectF& value) {
  return os << "{x=" << value.x << ", y=" << value.y
            << ", width=" << value.width << ", height=" << value.height
            << ", top_left_radius_x=" << value.top_left_radius_x
            << ", top_left_radius_y=" << value.top_left_radius_y
            << ", top_right_radius_x=" << value.top_right_radius_x
            << ", top_right_radius_y=" << value.top_right_radius_y
            << ", bottom_left_radius_x=" << value.bottom_left_radius_x
            << ", bottom_left_radius_y=" << value.bottom_left_radius_y
            << ", bottom_right_radius_x=" << value.bottom_right_radius_x
            << ", bottom_right_radius_y=" << value.bottom_right_radius_y << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::Size& value) {
  return os << "{width=" << value.width << ", height=" << value.height << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::Transform& value) {
  if (value.matrix) {
    os << "[";
    for (size_t i = 0; i < 4; i++) {
      if (i != 0)
        os << ", ";
      os << "[";
      for (size_t j = 0; j < 4; j++) {
        if (j != 0)
          os << ", ";
        os << value.matrix[i * 4 + j];
      }
      os << "]";
    }
    os << "]";
  } else {
    os << "null";
  }
  return os;
}

}  // namespace mojo
