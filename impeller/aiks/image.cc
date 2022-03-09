// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/image.h"

namespace impeller {

Image::Image(std::shared_ptr<Texture> texture) : texture_(std::move(texture)) {}

Image::~Image() = default;

ISize Image::GetSize() const {
  return texture_ ? texture_->GetSize() : ISize{};
}

std::shared_ptr<Texture> Image::GetTexture() const {
  return texture_;
}

}  // namespace impeller
