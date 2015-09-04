// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/picture_layer.h"
#include "base/logging.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace sky {
namespace compositor {

PictureLayer::PictureLayer() : last_picture_id_(UINT32_MAX) {
}

PictureLayer::~PictureLayer() {
}

SkMatrix PictureLayer::model_view_matrix(const SkMatrix& model_matrix) const {
  SkMatrix modelView = model_matrix;
  modelView.postTranslate(offset_.x(), offset_.y());
  return modelView;
}

static void ImageReleaseProc(SkImage::ReleaseContext texture) {
  DCHECK(texture);
  reinterpret_cast<GrTexture*>(texture)->unref();
}

static RefPtr<SkImage> ImageFromPicture(GrContext* context,
                                        SkPicture* picture,
                                        const SkRect& paintBounds) {
  // Step 1: Create a texture from the context's texture provider

  GrSurfaceDesc desc;
  desc.fWidth = paintBounds.width();
  desc.fHeight = paintBounds.height();
  desc.fFlags = kRenderTarget_GrSurfaceFlag;
  desc.fConfig = kRGBA_8888_GrPixelConfig;

  GrTexture* texture = context->textureProvider()->createTexture(desc, true);

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

  // Step 4: Create an image representation from the texture

  RefPtr<SkImage> image = adoptRef(SkImage::NewFromTexture(
      context, backendDesc, kPremul_SkAlphaType, &ImageReleaseProc, texture));
  return image;
}

void PictureLayer::Paint(GrContext* context, SkCanvas* canvas) {
  DCHECK(picture_);

  if (last_picture_id_ == picture_->uniqueID()) {
    // The last picture painted was the same as this one. Cache this into an
    // offscreen surface and render that instead
    if (!cached_image_) {
      // Generate the cached image
      cached_image_ = ImageFromPicture(context, picture_.get(), paint_bounds());
    }
  } else {
    // Release the cached image if one is present
    cached_image_.release();
  }

  last_picture_id_ = picture_->uniqueID();

  if (cached_image_) {
    canvas->drawImage(cached_image_.get(), offset_.x(), offset_.y());
  } else {
    canvas->save();
    canvas->translate(offset_.x(), offset_.y());
    canvas->drawPicture(picture_.get());
    canvas->restore();
  }
}

}  // namespace compositor
}  // namespace sky
