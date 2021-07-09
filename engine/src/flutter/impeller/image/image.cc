// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/image/image.h"

namespace impeller {

Image::Image() = default;

Image::Image(ISize size,
             Format components,
             std::shared_ptr<const fml::Mapping> allocation)
    : size_(size), components_(components), allocation_(std::move(allocation)) {
  if (!allocation_ || !size.IsPositive()) {
    return;
  }
  is_valid_ = true;
}

Image::~Image() = default;

bool Image::IsValid() const {
  return is_valid_;
}

const ISize& Image::GetSize() const {
  return size_;
}

Image::Format Image::GetComponents() const {
  return components_;
}

const std::shared_ptr<const fml::Mapping>& Image::GetAllocation() const {
  return allocation_;
}

}  // namespace impeller
