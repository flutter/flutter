// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_image_skia.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"

namespace flutter {

sk_sp<DlImage> DlImageSkia::Make(const SkImage* image) {
  return Make(sk_ref_sp(image));
}

sk_sp<DlImage> DlImageSkia::Make(sk_sp<SkImage> image) {
  return sk_make_sp<DlImageSkiaImpl>(std::move(image));
}

DlImageSkiaImpl::DlImageSkiaImpl(sk_sp<SkImage> image)
    : image_(std::move(image)) {}

// |DlImage|
DlImageSkiaImpl::~DlImageSkiaImpl() = default;

DlImage::Type DlImageSkia::GetType() const { return Type::kSkia; }

// |DlImage|
const DlImageSkia* DlImageSkia::asDlImageSkia() const {
  return this;
};

// |DlImage|
const impeller::DlImageImpeller* DlImageSkia::asDlImageImpeller() const {
  return nullptr;
}

// |DlImage|
bool DlImageSkiaImpl::isOpaque() const {
  return image_ ? image_->isOpaque() : false;
}

// |DlImage|
bool DlImageSkiaImpl::isTextureBacked() const {
  return image_ ? image_->isTextureBacked() : false;
}

// |DlImage|
bool DlImageSkiaImpl::isUIThreadSafe() const {
  // Technically if the image is null then we are thread-safe, and possibly
  // if the image is constructed from a heap raster as well, but there
  // should never be a leak of an instance of this class into any data that
  // is shared with the UI thread, regardless of value.
  // All images intended to be shared with the UI thread should be constructed
  // via one of the DlImage subclasses designed for that purpose.
  return false;
}

// |DlImage|
DlISize DlImageSkiaImpl::GetSize() const {
  return image_ ? ToDlISize(image_->dimensions()) : DlISize();
}

// |DlImage|
size_t DlImageSkiaImpl::GetApproximateByteSize() const {
  auto size = sizeof(*this);
  if (image_) {
    const auto& info = image_->imageInfo();
    const auto kMipmapOverhead = image_->hasMipmaps() ? 4.0 / 3.0 : 1.0;
    const size_t image_byte_size = info.computeMinByteSize() * kMipmapOverhead;
    size += image_byte_size;
  }
  return size;
}

sk_sp<SkImage> DlImageSkiaImpl::skia_image() const {
  return image_;
}

}  // namespace flutter
