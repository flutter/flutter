// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl.h"

#include <utility>

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

namespace flutter {

EmbedderExternalTextureGL::EmbedderExternalTextureGL(
    int64_t texture_identifier,
    ExternalTextureCallback callback,
    UVTransformationCallback uv_transformation_callback)
    : Texture(texture_identifier),
      external_texture_callback_(std::move(callback)),
      uv_transformation_callback_(std::move(uv_transformation_callback)) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureGL::~EmbedderExternalTextureGL() = default;

// |flutter::Texture|
void EmbedderExternalTextureGL::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  if (last_image_ == nullptr) {
    last_image_ =
        ResolveTexture(Id(),                                                 //
                       context.gr_context,                                   //
                       context.aiks_context,                                 //
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight())  //
        );
  }

  DlCanvas* canvas = context.canvas;
  const DlPaint* paint = context.paint;

  if (last_image_) {
    if (has_uv_transformation_) {
      if (!uv_transformation_.IsInvertible()) {
        FML_LOG(ERROR) << "Invalid (not invertible) external texture UV "
                          "transformation matrix.";
        return;
      }
      DlMatrix transform = uv_transformation_.Invert();

      DlAutoCanvasRestore auto_restore(canvas, true);

      // The incoming texture is vertically flipped, so we flip it back.
      // OpenGL's coordinate system has Positive Y equivalent to up, while
      // Skia/Impeller's coordinate system has Negative Y equivalent to up.
      canvas->Translate(bounds.GetX(), bounds.GetY() + bounds.GetHeight());
      canvas->Scale(bounds.GetWidth(), -bounds.GetHeight());

      // Normalized [0, 1] unit quad matching the 1x1 DlImage dimensions.
      constexpr DlScalar kUnitQuadSize = 1.0f;
      auto source =
          DlColorSource::MakeImage(last_image_, DlTileMode::kClamp,
                                   DlTileMode::kClamp, sampling, &transform);

      DlPaint paint_with_shader;
      if (paint) {
        paint_with_shader = *paint;
      }
      paint_with_shader.setColorSource(source);
      canvas->DrawRect(DlRect::MakeWH(kUnitQuadSize, kUnitQuadSize),
                       paint_with_shader);
      return;
    }

    DlRect image_bounds = DlRect::Make(last_image_->GetBounds());
    if (bounds != image_bounds) {
      canvas->DrawImageRect(last_image_, image_bounds, bounds, sampling, paint);
    } else {
      canvas->DrawImage(last_image_, bounds.GetOrigin(), sampling, paint);
    }
  }
}

sk_sp<DlImage> EmbedderExternalTextureGL::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  if (!!aiks_context) {
    return ResolveTextureImpeller(texture_id, aiks_context, size);
  } else if (context) {
    return ResolveTextureSkia(texture_id, context, size);
  }
  return nullptr;
}

sk_sp<DlImage> EmbedderExternalTextureGL::ResolveTextureSkia(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  if (!context) {
    return nullptr;
  }
  context->flushAndSubmit();
  context->resetContext(kAll_GrBackendState);
  std::unique_ptr<FlutterOpenGLTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  has_uv_transformation_ = false;
  uv_transformation_ = DlMatrix();
  if (uv_transformation_callback_) {
    DlMatrix uv_matrix;
    if (uv_transformation_callback_(texture_id, &uv_matrix)) {
      uv_transformation_ = uv_matrix;
      has_uv_transformation_ = true;
    }
  }

  GrGLTextureInfo gr_texture_info = {texture->target, texture->name,
                                     texture->format};

  size_t width = size.width();
  size_t height = size.height();

  if (has_uv_transformation_) {
    // Wrap UV-transformed external textures as a 1x1 unit texture so shader
    // coordinate normalization operates directly in [0, 1] UV space.
    constexpr size_t kUnitTextureDimension = 1;
    width = kUnitTextureDimension;
    height = kUnitTextureDimension;
  } else if (texture->width != 0 && texture->height != 0) {
    width = texture->width;
    height = texture->height;
  }

  auto gr_backend_texture = GrBackendTextures::MakeGL(
      width, height, skgpu::Mipmapped::kNo, gr_texture_info);
  SkImages::TextureReleaseProc release_proc = texture->destruction_callback;
  auto image =
      SkImages::BorrowTextureFrom(context,                   // context
                                  gr_backend_texture,        // texture handle
                                  kTopLeft_GrSurfaceOrigin,  // origin
                                  kRGBA_8888_SkColorType,    // color type
                                  kPremul_SkAlphaType,       // alpha type
                                  nullptr,                   // colorspace
                                  release_proc,       // texture release proc
                                  texture->user_data  // texture release context
      );

  if (!image) {
    // In case Skia rejects the image, call the release proc so that
    // embedders can perform collection of intermediates.
    if (release_proc) {
      release_proc(texture->user_data);
    }
    FML_LOG(ERROR) << "Could not create external texture->";
    return nullptr;
  }

  // This image should not escape local use by EmbedderExternalTextureGL
  return DlImageSkia::Make(std::move(image));
}

sk_sp<DlImage> EmbedderExternalTextureGL::ResolveTextureImpeller(
    int64_t texture_id,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  if (!aiks_context || !aiks_context->GetContext() ||
      aiks_context->GetContext()->GetBackendType() !=
          impeller::Context::BackendType::kOpenGLES) {
    return nullptr;
  }

  std::unique_ptr<FlutterOpenGLTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  has_uv_transformation_ = false;
  uv_transformation_ = DlMatrix();
  if (uv_transformation_callback_) {
    DlMatrix uv_matrix;
    if (uv_transformation_callback_(texture_id, &uv_matrix)) {
      uv_transformation_ = uv_matrix;
      has_uv_transformation_ = true;
    }
  }

  // Call the destruction callback if an error occurs.
  fml::ScopedCleanupClosure scoped_cleanup([&texture]() {
    if (texture->destruction_callback) {
      texture->destruction_callback(texture->user_data);
    }
  });

  if (texture->format != GL_RGBA8) {
    FML_LOG(ERROR) << "Only support GL_RGBA8 format now";
    return nullptr;
  }

  impeller::TextureDescriptor desc;
  if (has_uv_transformation_) {
    // Wrap UV-transformed external textures as a 1x1 unit texture so Impeller
    // shader coordinate normalization operates directly in [0, 1] UV space.
    constexpr int64_t kUnitTextureDimension = 1;
    desc.size = impeller::ISize(kUnitTextureDimension, kUnitTextureDimension);
  } else {
    desc.size = impeller::ISize(texture->width, texture->height);
  }
  desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  if (texture->target == GL_TEXTURE_EXTERNAL_OES) {
    desc.type = impeller::TextureType::kTextureExternalOES;
  }

  impeller::ContextGLES& context =
      impeller::ContextGLES::Cast(*aiks_context->GetContext());
  impeller::HandleGLES handle = context.GetReactor()->CreateHandle(
      impeller::HandleType::kTexture, texture->name);
  std::shared_ptr<impeller::TextureGLES> image =
      impeller::TextureGLES::WrapTexture(context.GetReactor(), desc, handle);

  if (!image) {
    FML_LOG(ERROR) << "Could not create external texture";
    return nullptr;
  }
  image->MarkContentsInitialized();

  VoidCallback destruction_callback = texture->destruction_callback;
  if (!destruction_callback) {
    // Set a no-op cleanup callback if the texture does not provide a callback.
    // The presence of a cleanup callback indicates that the embedder controls
    // the GL texture's lifetime and Impeller should not delete it.
    destruction_callback = [](void*) {};
  }
  auto cleanup_callback = [callback = destruction_callback,
                           user_data = texture->user_data]() {
    callback(user_data);
  };
  if (!context.GetReactor()->RegisterCleanupCallback(handle,
                                                     cleanup_callback)) {
    FML_LOG(ERROR) << "Could not register destruction callback";
    return nullptr;
  }

  scoped_cleanup.Release();

  return impeller::DlImageImpeller::Make(image);
}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnGrContextCreated() {}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnGrContextDestroyed() {}

// |flutter::Texture|
void EmbedderExternalTextureGL::MarkNewFrameAvailable() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnTextureUnregistered() {}

}  // namespace flutter
