// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_backingstore_producer_gl.h"

#include "flutter/fml/logging.h"
#include "flutter/testing/test_gl_surface.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

namespace flutter::testing {

EmbedderTestBackingStoreProducerGL::EmbedderTestBackingStoreProducerGL(
    sk_sp<GrDirectContext> context,
    RenderTargetType type,
    std::shared_ptr<TestEGLContext> egl_context)
    : EmbedderTestBackingStoreProducer(std::move(context), type),
      test_egl_context_(std::move(egl_context)) {}

EmbedderTestBackingStoreProducerGL::~EmbedderTestBackingStoreProducerGL() =
    default;

bool EmbedderTestBackingStoreProducerGL::Create(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  switch (type_) {
    case RenderTargetType::kOpenGLTexture:
      return CreateTexture(config, backing_store_out);
    case RenderTargetType::kOpenGLFramebuffer:
      return CreateFramebuffer(config, backing_store_out);
    case RenderTargetType::kOpenGLSurface:
      return CreateSurface(config, backing_store_out);
    default:
      return false;
  };
}

bool EmbedderTestBackingStoreProducerGL::CreateFramebuffer(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface =
      SkSurfaces::RenderTarget(context_.get(),               // context
                               skgpu::Budgeted::kNo,         // budgeted
                               image_info,                   // image info
                               1,                            // sample count
                               kBottomLeft_GrSurfaceOrigin,  // surface origin
                               nullptr,  // surface properties
                               false     // mipmaps
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendRenderTarget render_target = SkSurfaces::GetBackendRenderTarget(
      surface.get(), SkSurfaces::BackendHandleAccess::kDiscardWrite);

  if (!render_target.isValid()) {
    FML_LOG(ERROR) << "Backend render target was invalid.";
    return false;
  }

  GrGLFramebufferInfo framebuffer_info = {};
  if (!GrBackendRenderTargets::GetGLFramebufferInfo(render_target,
                                                    &framebuffer_info)) {
    FML_LOG(ERROR) << "Could not access backend framebuffer info.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = framebuffer_info.fFormat;
  backing_store_out->open_gl.framebuffer.name = framebuffer_info.fFBOID;
  backing_store_out->open_gl.framebuffer.user_data = user_data;
  backing_store_out->open_gl.framebuffer.destruction_callback =
      [](void* user_data) { delete reinterpret_cast<UserData*>(user_data); };

  return true;
}

bool EmbedderTestBackingStoreProducerGL::CreateTexture(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface =
      SkSurfaces::RenderTarget(context_.get(),               // context
                               skgpu::Budgeted::kNo,         // budgeted
                               image_info,                   // image info
                               1,                            // sample count
                               kBottomLeft_GrSurfaceOrigin,  // surface origin
                               nullptr,  // surface properties
                               false     // mipmaps
      );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendTexture render_texture = SkSurfaces::GetBackendTexture(
      surface.get(), SkSurfaces::BackendHandleAccess::kDiscardWrite);

  if (!render_texture.isValid()) {
    FML_LOG(ERROR) << "Backend render texture was invalid.";
    return false;
  }

  GrGLTextureInfo texture_info = {};
  if (!GrBackendTextures::GetGLTextureInfo(render_texture, &texture_info)) {
    FML_LOG(ERROR) << "Could not access backend texture info.";
    return false;
  }

  auto user_data = new UserData(surface);

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeTexture;
  backing_store_out->open_gl.texture.target = texture_info.fTarget;
  backing_store_out->open_gl.texture.name = texture_info.fID;
  backing_store_out->open_gl.texture.format = texture_info.fFormat;
  backing_store_out->open_gl.texture.user_data = user_data;
  backing_store_out->open_gl.texture.destruction_callback =
      [](void* user_data) { delete reinterpret_cast<UserData*>(user_data); };

  return true;
}

bool EmbedderTestBackingStoreProducerGL::CreateSurface(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  FML_CHECK(test_egl_context_);
  auto surface = std::make_unique<TestGLOnscreenOnlySurface>(
      test_egl_context_,
      SkSize::Make(config->size.width, config->size.height).toRound());

  auto make_current = [](void* user_data, bool* invalidate_state) -> bool {
    *invalidate_state = false;
    return reinterpret_cast<UserData*>(user_data)->gl_surface->MakeCurrent();
  };

  auto clear_current = [](void* user_data, bool* invalidate_state) -> bool {
    *invalidate_state = false;
    // return
    // reinterpret_cast<GLUserData*>(user_data)->gl_surface->ClearCurrent();
    return true;
  };

  auto destruction_callback = [](void* user_data) {
    delete reinterpret_cast<UserData*>(user_data);
  };

  auto sk_surface = surface->GetOnscreenSurface();

  auto user_data = new UserData(sk_surface, nullptr, std::move(surface));

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = user_data;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeSurface;
  backing_store_out->open_gl.surface.user_data = user_data;
  backing_store_out->open_gl.surface.make_current_callback = make_current;
  backing_store_out->open_gl.surface.clear_current_callback = clear_current;
  backing_store_out->open_gl.surface.destruction_callback =
      destruction_callback;
  backing_store_out->open_gl.surface.format = 0x93A1 /* GL_BGRA8_EXT */;

  return true;
}

}  // namespace flutter::testing
