// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ImageResult.h"

namespace rl {
namespace image {

ImageResult::ImageResult() = default;

ImageResult::ImageResult(geom::Size size,
                         Components components,
                         std::shared_ptr<const fml::Mapping> allocation)
    : _success(true),
      _size(size),
      _components(components),
      _allocation(std::move(allocation)) {}

ImageResult::~ImageResult() = default;

bool ImageResult::wasSuccessful() const {
  return _success;
}

const geom::Size& ImageResult::size() const {
  return _size;
}

ImageResult::Components ImageResult::components() const {
  return _components;
}

const std::shared_ptr<const fml::Mapping>& ImageResult::allocation() const {
  return _allocation;
}

}  // namespace image
}  // namespace rl
