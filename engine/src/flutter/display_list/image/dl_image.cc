// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/image/dl_image.h"

#include "flutter/display_list/image/dl_image_skia.h"

namespace flutter {

DlImage::DlImage() = default;

DlImage::~DlImage() = default;

int DlImage::width() const {
  return GetSize().width;
};

int DlImage::height() const {
  return GetSize().height;
};

DlIRect DlImage::GetBounds() const {
  return DlIRect::MakeSize(GetSize());
}

std::optional<std::string> DlImage::get_error() const {
  return std::nullopt;
}

bool DlImage::Equals(const DlImage* other) const {
  if (!other) {
    return false;
  }
  if (this == other) {
    return true;
  }

  auto skia_this = asSkiaImage();
  auto skia_other = other->asSkiaImage();
  if (!skia_this || !skia_other) {
    // Impeller images have pointer equality (handled by this == other)
    return false;
  }
  if (owning_context() == OwningContext::kRaster ||
      other->owning_context() == OwningContext::kRaster) {
    // Skia raster-owned images also have pointer equality (handled by
    // this == other).
    return false;
  }
  // For Skia non-raster-owned images, check whether they wrap the same
  // `SkImage`. Note that `skia_image()` must never be called on the UI thread
  // for a raster-owned image. `Equals` may be called from the UI thread, so
  // the `owning_context()` check above protects against this case.
  return skia_this->skia_image() == skia_other->skia_image();
}

}  // namespace flutter
