// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/compositor_options.h"
#include "sky/compositor/checkerboard.h"
#include "sky/compositor/picture_rasterizer.h"
#include "sky/compositor/paint_context.h"
#include "base/logging.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {
namespace compositor {

PictureRasterzier::PictureRasterzier() {
}

PictureRasterzier::~PictureRasterzier() {
}

static void ImageReleaseProc(SkImage::ReleaseContext texture) {
  DCHECK(texture);
  reinterpret_cast<GrTexture*>(texture)->unref();
}

PictureRasterzier::Key::Key(uint32_t ident, SkISize sz)
    : pictureID(ident), size(sz){};

PictureRasterzier::Key::Key(const Key& key) = default;

PictureRasterzier::Value::Value()
    : access_count(kDeadAccessCount), image(nullptr) {
}

PictureRasterzier::Value::~Value() {
}

static RefPtr<SkImage> ImageFromPicture(PaintContext& context,
                                        GrContext* gr_context,
                                        SkPicture* picture,
                                        const SkISize& size) {
  // Step 1: Create a texture from the context's texture provider

  GrSurfaceDesc desc;
  desc.fWidth = size.width();
  desc.fHeight = size.height();
  desc.fFlags = kRenderTarget_GrSurfaceFlag;
  desc.fConfig = kRGBA_8888_GrPixelConfig;

  GrTexture* texture = gr_context->textureProvider()->createTexture(desc, true);

  if (!texture) {
    // The texture provider could not allocate a texture backing. Render
    // directly to the surface from the picture till the memory pressure
    // subsides
    return nullptr;
  }

  // Step 2: Create a backend render target description for the created texture

  GrBackendTextureDesc backendDesc;
  backendDesc.fConfig = desc.fConfig;
  backendDesc.fWidth = desc.fWidth;
  backendDesc.fHeight = desc.fHeight;
  backendDesc.fSampleCnt = desc.fSampleCnt;
  backendDesc.fFlags = kRenderTarget_GrBackendTextureFlag;
  backendDesc.fConfig = desc.fConfig;
  backendDesc.fTextureHandle = texture->getTextureHandle();

  // Step 3: Render the picture into the offscreen texture

  GrRenderTarget* renderTarget = texture->asRenderTarget();
  DCHECK(renderTarget);

  PassRefPtr<SkSurface> surface =
      adoptRef(SkSurface::NewRenderTargetDirect(renderTarget));
  DCHECK(surface);

  SkCanvas* canvas = surface->getCanvas();
  DCHECK(canvas);

  canvas->drawPicture(picture);

  if (context.options().isEnabled(
          CompositorOptions::Option::HightlightRasterizedImages)) {
    DrawCheckerboard(canvas, desc.fWidth, desc.fHeight);
  }

  // Step 4: Create an image representation from the texture

  RefPtr<SkImage> image = adoptRef(
      SkImage::NewFromTexture(gr_context, backendDesc, kPremul_SkAlphaType,
                              &ImageReleaseProc, texture));
  return image;
}

RefPtr<SkImage> PictureRasterzier::GetCachedImageIfPresent(
    PaintContext& context,
    GrContext* gr_context,
    SkPicture* picture,
    SkISize size) {
  if (size.isEmpty() || picture == nullptr || gr_context == nullptr) {
    return nullptr;
  }

  const Key key(picture->uniqueID(), size);

  Value& value = cache_[key];

  if (value.access_count == Value::kDeadAccessCount) {
    value.access_count = 1;
    return nullptr;
  }

  value.access_count++;
  DCHECK(value.access_count == 1)
      << "Did you forget to call purge_cache between frames?";

  if (!value.image) {
    value.image = ImageFromPicture(context, gr_context, picture, size);
  }

  return value.image;
}

void PictureRasterzier::PurgeCache() {
  std::unordered_set<Key, KeyHash, KeyEqual> keys_to_purge;

  for (auto& item : cache_) {
    const auto count = --item.second.access_count;
    if (count == Value::kDeadAccessCount) {
      keys_to_purge.insert(item.first);
    }
  }

  for (const auto& key : keys_to_purge) {
    cache_.erase(key);
  }
}

}  // namespace compositor
}  // namespace sky
