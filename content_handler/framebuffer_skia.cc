// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/framebuffer_skia.h"

#include <magenta/process.h>
#include <magenta/syscalls.h>

#include <utility>

#include "lib/ftl/logging.h"

namespace flutter_content_handler {
namespace {

struct BackingStoreInfo {
  mx_handle_t vmo;
  uintptr_t buffer;
  size_t size;
};

void DidReleaseSurface(void* pixels, void* context) {
  BackingStoreInfo* info = static_cast<BackingStoreInfo*>(context);
  mx_process_unmap_vm(mx_process_self(), info->buffer, info->size);
  mx_handle_close(info->vmo);
  delete info;
}

}  // namespace

FramebufferSkia::FramebufferSkia() {}

FramebufferSkia::~FramebufferSkia() {}

void FramebufferSkia::Bind(mojo::InterfaceHandle<mojo::Framebuffer> framebuffer,
                           mojo::FramebufferInfoPtr info) {
  if (!framebuffer) {
    FTL_LOG(ERROR) << "Failed to bind framebuffer";
    surface_ = nullptr;
    return;
  }

  framebuffer_.Bind(std::move(framebuffer));
  info_ = std::move(info);

  uintptr_t buffer = 0;
  size_t row_bytes = info_->row_bytes;
  size_t size = row_bytes * info_->size->height;

  mx_status_t status =
      mx_process_map_vm(mx_process_self(), info_->vmo.get().value(), 0, size,
                        &buffer, MX_VM_FLAG_PERM_READ | MX_VM_FLAG_PERM_WRITE);

  if (status < 0) {
    FTL_LOG(ERROR) << "Cannot map framebuffer (status=" << status << ")";
    return;
  }

  SkColorType sk_color_type;
  SkAlphaType sk_alpha_type;
  switch (info_->format) {
    case mojo::FramebufferFormat::RGB_565:
      sk_color_type = kRGB_565_SkColorType;
      sk_alpha_type = kOpaque_SkAlphaType;
      break;
    case mojo::FramebufferFormat::ARGB_8888:
    case mojo::FramebufferFormat::RGB_x888:
      sk_color_type = kRGBA_8888_SkColorType;
      sk_alpha_type = kPremul_SkAlphaType;
      break;
    default:
      FTL_LOG(WARNING) << "Unknown color type " << info_->format;
      sk_color_type = kRGB_565_SkColorType;
      sk_alpha_type = kOpaque_SkAlphaType;
      break;
  }

  SkImageInfo image_info = SkImageInfo::Make(
      info_->size->width, info_->size->height, sk_color_type, sk_alpha_type);

  BackingStoreInfo* backing_store_info = new BackingStoreInfo();
  backing_store_info->vmo = info_->vmo.release().value();
  backing_store_info->buffer = buffer;
  backing_store_info->size = size;

  surface_ = SkSurface::MakeRasterDirectReleaseProc(
      image_info, reinterpret_cast<void*>(buffer), row_bytes, DidReleaseSurface,
      backing_store_info);
}

void FramebufferSkia::ConvertToCorrectPixelFormatIfNeeded() {
  if (info_->format == mojo::FramebufferFormat::ARGB_8888 ||
      info_->format == mojo::FramebufferFormat::RGB_x888) {
    // we need to convert from RGBA to ARGB
    SkPixmap bufferPixmap;

    if (surface_->peekPixels(&bufferPixmap)) {
      uint8_t* buffer =
          reinterpret_cast<uint8_t*>(bufferPixmap.writable_addr());
      size_t buffer_size = bufferPixmap.getSafeSize();
      for (size_t i = 0; i < buffer_size; i += 4)
        std::swap(buffer[i + 0], buffer[i + 2]);
    }
  }
}

void FramebufferSkia::Finish() {
  framebuffer_->Flush([] {});
  framebuffer_.WaitForIncomingResponse();
}

}  // namespace flutter_content_handler
