// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/image/dl_image_skia.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"

namespace flutter {

sk_sp<DlImage> DlImageSkia::Make(const SkImage* image) {
  if (!image) {
    return nullptr;
  }
  return sk_make_sp<DlImageSkia>(sk_ref_sp(image));
}

sk_sp<DlImage> DlImageSkia::Make(sk_sp<SkImage> image) {
  if (!image) {
    return nullptr;
  }
  return sk_make_sp<DlImageSkia>(std::move(image));
}

DlImageSkia::DlImageSkia(sk_sp<SkImage> image) : image_(std::move(image)) {}

// |DlImage|
DlImageSkia::~DlImageSkia() = default;

// |DlImage|
sk_sp<SkImage> DlImageSkia::skia_image() const {
  return image_;
};

// |DlImage|
bool DlImageSkia::isTextureBacked() const {
  return image_ ? image_->isTextureBacked() : false;
}

// |DlImage|
bool DlImageSkia::isOpaque() const {
  return image_ ? image_->isOpaque() : false;
}

// |DlImage|
bool DlImageSkia::isUIThreadSafe() const {
  // Technically if the image is null then we are thread-safe, and possibly
  // if the image is constructed from a heap raster as well, but there
  // should never be a leak of an instance of this class into any data that
  // is shared with the UI thread, regardless of value.
  // All images intended to be shared with the UI thread should be constructed
  // via one of the DlImage subclasses designed for that purpose.
  return false;
}

// |DlImage|
DlISize DlImageSkia::GetSize() const {
  return image_ ? ToDlISize(image_->dimensions()) : DlISize();
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

// |DlImage|
DlColorSpace DlImageSkia::GetColorSpace() const {
  return DlColorSpace::kSRGB;
}

}  // namespace flutter
