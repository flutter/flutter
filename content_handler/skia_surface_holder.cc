// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/skia_surface_holder.h"

#include <mx/process.h>

#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter_runner {

SkiaSurfaceHolder::SkiaSurfaceHolder(const SkISize& size) {
  size_t row_bytes = size.width() * sizeof(uint32_t);
  size_t total_bytes = size.height() * row_bytes;

  mx_status_t rv = mx::vmo::create(total_bytes, 0, &vmo_);
  FTL_CHECK(rv == NO_ERROR);

  uintptr_t address = 0;
  rv = mx::process::self().map_vm(vmo_, 0, total_bytes, &address,
                                  MX_VM_FLAG_PERM_READ | MX_VM_FLAG_PERM_WRITE);
  FTL_CHECK(rv == NO_ERROR);

  buffer_ = reinterpret_cast<void*>(address);

  surface_ = SkSurface::MakeRasterDirect(
      SkImageInfo::Make(size.width(), size.height(), kBGRA_8888_SkColorType,
                        kPremul_SkAlphaType),
      buffer_, row_bytes);

  FTL_CHECK(surface_);
}

SkiaSurfaceHolder::~SkiaSurfaceHolder() {
  mx_status_t rv =
      mx::process::self().unmap_vm(reinterpret_cast<uintptr_t>(buffer_), 0);
  FTL_CHECK(rv == NO_ERROR);
}

mozart::ImagePtr SkiaSurfaceHolder::TakeImage() {
  FTL_DCHECK(vmo_);

  auto image = mozart::Image::New();
  image->size = mozart::Size::New();
  image->size->width = surface_->width();
  image->size->height = surface_->height();
  image->stride = image->size->width * sizeof(uint32_t);
  image->pixel_format = mozart::Image::PixelFormat::B8G8R8A8;
  image->alpha_format = mozart::Image::AlphaFormat::PREMULTIPLIED;
  image->buffer = std::move(vmo_);
  return image;
}

}  // namespace flutter_runner
