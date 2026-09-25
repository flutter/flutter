// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_hb.h"

#include <utility>

#if !defined(_WIN32)
#include <unistd.h>
#endif

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

namespace {

void CloseFenceFd(int32_t fence_fd) {
  if (fence_fd >= 0) {
#if !defined(_WIN32)
    close(fence_fd);
#endif
  }
}

class HardwareBufferDlImageSkia final : public DlImageSkia {
 public:
  HardwareBufferDlImageSkia(sk_sp<SkImage> image,
                            int32_t fence_fd,
                            VoidCallback destruction_callback,
                            void* user_data)
      : DlImageSkia(std::move(image)),
        fence_fd_(fence_fd),
        destruction_callback_(destruction_callback),
        user_data_(user_data) {}

  ~HardwareBufferDlImageSkia() override {
    CloseFenceFd(fence_fd_);
    if (destruction_callback_) {
      TRACE_EVENT0("flutter",
                   "HardwareBufferExternalTextureDestructionCallback");
      destruction_callback_(user_data_);
    }
  }

 private:
  int32_t fence_fd_;
  VoidCallback destruction_callback_;
  void* user_data_;
};

}  // namespace

EmbedderExternalTextureHB::EmbedderExternalTextureHB(
    int64_t texture_identifier,
    ExternalTextureCallback callback)
    : Texture(texture_identifier),
      external_texture_callback_(std::move(callback)) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureHB::~EmbedderExternalTextureHB() {
  TRACE_EVENT0("flutter",
               "EmbedderExternalTextureHB::~EmbedderExternalTextureHB");
  ReleaseLatestFrame();
}

void EmbedderExternalTextureHB::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::Paint");
  if (!freeze && has_new_frame_.exchange(false)) {
    sk_sp<DlImage> new_image =
        ResolveTexture(Id(), context.gr_context, context.aiks_context,
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight()));
    if (new_image) {
      last_image_ = std::move(new_image);
    }
  }

  DlCanvas* canvas = context.canvas;
  const DlPaint* paint = context.paint;

  if (last_image_ && canvas) {
    DlRect image_bounds = DlRect::Make(last_image_->GetBounds());
    if (bounds != image_bounds) {
      canvas->DrawImageRect(last_image_, image_bounds, bounds, sampling, paint);
    } else {
      canvas->DrawImage(last_image_, bounds.GetOrigin(), sampling, paint);
    }
  }
}

sk_sp<DlImage> EmbedderExternalTextureHB::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ResolveTexture");

  std::unique_ptr<FlutterHardwareBufferExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  if (texture->struct_size < sizeof(FlutterHardwareBufferExternalTexture)) {
    FML_LOG(ERROR)
        << "Invalid FlutterHardwareBufferExternalTexture struct_size: "
        << texture->struct_size;
    if (texture->struct_size >=
        offsetof(FlutterHardwareBufferExternalTexture, fence_fd) +
            sizeof(int32_t)) {
      CloseFenceFd(texture->fence_fd);
    }
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  size_t width = texture->width != 0 ? texture->width : size.width();
  size_t height = texture->height != 0 ? texture->height : size.height();

  if (texture->buffer == nullptr || width == 0 || height == 0) {
    FML_LOG(ERROR)
        << "Invalid HardwareBuffer external texture parameters (buffer="
        << texture->buffer << ", size=" << width << "x" << height << ")";
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  // Placeholder surface allocation for Phase 1.6 C-API extension testing.
  // We allocate a minimal 1x1 raster surface to prevent multi-megabyte heap
  // allocations on the raster thread. Full zero-copy GPU texture import (via
  // EGLImage or AHardwareBuffer Vulkan external memory) is wired in Phase 3.1.
  auto info =
      SkImageInfo::Make(1, 1, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
  auto sk_surface = SkSurfaces::Raster(info);
  if (!sk_surface) {
    CloseFenceFd(texture->fence_fd);
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
    return nullptr;
  }

  int32_t fence_fd = texture->fence_fd;
  VoidCallback destruction_callback = texture->destruction_callback;
  void* user_data = texture->user_data;
  // Detach fence_fd and destruction callback from the struct so that ownership
  // is solely held by the DlImage wrapper and fired when the GPU completes.
  texture->fence_fd = -1;
  texture->destruction_callback = nullptr;

  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    last_texture_frame_ = std::move(texture);
  }

  return sk_make_sp<HardwareBufferDlImageSkia>(sk_surface->makeImageSnapshot(),
                                               fence_fd, destruction_callback,
                                               user_data);
}

void EmbedderExternalTextureHB::ReleaseLatestFrame() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ReleaseLatestFrame");
  {
    std::lock_guard<std::mutex> lock(frame_mutex_);
    if (last_texture_frame_) {
      if (last_texture_frame_->destruction_callback) {
        TRACE_EVENT0("flutter",
                     "HardwareBufferExternalTextureDestructionCallback");
        last_texture_frame_->destruction_callback(
            last_texture_frame_->user_data);
      }
      last_texture_frame_.reset();
    }
  }
  last_image_ = nullptr;
}

void EmbedderExternalTextureHB::OnGrContextCreated() {
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::OnGrContextDestroyed() {
  ReleaseLatestFrame();
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::MarkNewFrameAvailable() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::MarkNewFrameAvailable");
  has_new_frame_.store(true);
}

void EmbedderExternalTextureHB::OnTextureUnregistered() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::OnTextureUnregistered");
  ReleaseLatestFrame();
}

}  // namespace flutter
