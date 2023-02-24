// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_image_skia.h"

namespace flutter {

DlImageSkia::DlImageSkia(sk_sp<SkImage> image) : image_(std::move(image)) {}

// |DlImage|
DlImageSkia::~DlImageSkia() = default;

// |DlImage|
sk_sp<SkImage> DlImageSkia::skia_image() const {
  return image_;
};

// |DlImage|
std::shared_ptr<impeller::Texture> DlImageSkia::impeller_texture() const {
  return nullptr;
}

// |DlImage|
bool DlImageSkia::isOpaque() const {
  return image_ ? image_->isOpaque() : false;
}

// |DlImage|
bool DlImageSkia::isTextureBacked() const {
  return image_ ? image_->isTextureBacked() : false;
}

// |DlImage|
SkISize DlImageSkia::dimensions() const {
  return image_ ? image_->dimensions() : SkISize::MakeEmpty();
}

// |DlImage|
size_t DlImageSkia::GetApproximateByteSize() const {
  auto size = sizeof(*this);
  if (image_) {
    const auto& info = image_->imageInfo();
    const auto kMipmapOverhead = image_->hasMipmaps() ? 4.0 / 3.0 : 1.0;
    const size_t image_byte_size = info.computeMinByteSize() * kMipmapOverhead;
    size += image_byte_size;
  }
  return size;
}

}  // namespace flutter
