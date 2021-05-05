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
    : success_(true),
      size_(size),
      components_(components),
      allocation_(std::move(allocation)) {}

ImageResult::~ImageResult() = default;

bool ImageResult::WasSuccessful() const {
  return success_;
}

const geom::Size& ImageResult::GetSize() const {
  return size_;
}

ImageResult::Components ImageResult::GetComponents() const {
  return components_;
}

const std::shared_ptr<const fml::Mapping>& ImageResult::Allocation() const {
  return allocation_;
}

}  // namespace image
}  // namespace rl
