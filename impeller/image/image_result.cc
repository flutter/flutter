// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "image_result.h"

namespace impeller {

ImageResult::ImageResult() = default;

ImageResult::ImageResult(ISize size,
                         Components components,
                         std::shared_ptr<const fml::Mapping> allocation)
    : size_(size), components_(components), allocation_(std::move(allocation)) {
  if (!allocation_ || !size.IsPositive()) {
    return;
  }
  is_valid_ = true;
}

ImageResult::~ImageResult() = default;

bool ImageResult::IsValid() const {
  return is_valid_;
}

const ISize& ImageResult::GetSize() const {
  return size_;
}

ImageResult::Components ImageResult::GetComponents() const {
  return components_;
}

const std::shared_ptr<const fml::Mapping>& ImageResult::GetAllocation() const {
  return allocation_;
}

}  // namespace impeller
