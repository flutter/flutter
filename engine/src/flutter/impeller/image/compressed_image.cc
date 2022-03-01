// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/image/compressed_image.h"

#include "impeller/image/backends/skia/compressed_image_skia.h"

namespace impeller {

std::shared_ptr<CompressedImage> CompressedImage::Create(
    std::shared_ptr<const fml::Mapping> allocation) {
  // There is only one backend today.
  if (!allocation) {
    return nullptr;
  }
  return std::make_shared<CompressedImageSkia>(std::move(allocation));
}

CompressedImage::CompressedImage(std::shared_ptr<const fml::Mapping> allocation)
    : source_(std::move(allocation)) {}

CompressedImage::~CompressedImage() = default;

bool CompressedImage::IsValid() const {
  return static_cast<bool>(source_);
}

}  // namespace impeller
