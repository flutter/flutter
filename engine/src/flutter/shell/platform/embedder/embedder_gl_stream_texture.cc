// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_gl_stream_texture.h"

#include <utility>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if FML_OS_ANDROID && defined(SHELL_ENABLE_GL) && !SLIMPELLER
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream_skia.h"
#endif  // FML_OS_ANDROID && defined(SHELL_ENABLE_GL) && !SLIMPELLER

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/impeller/display_list/aiks_context.h"
#if defined(SHELL_ENABLE_GL)
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream_impeller.h"
#endif  // defined(SHELL_ENABLE_GL)
#if FML_OS_ANDROID && defined(SHELL_ENABLE_VULKAN)
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream_vk.h"
#endif  // FML_OS_ANDROID && defined(SHELL_ENABLE_VULKAN)
#endif  // IMPELLER_SUPPORTS_RENDERING

namespace flutter {

std::unique_ptr<EmbedderGLStreamTexture> EmbedderGLStreamTexture::Create(
    const FlutterExternalTextureInfo& info) {
  if (info.type != kFlutterExternalTextureTypeOpenGLStream) {
    return nullptr;
  }
  const FlutterOpenGLTextureStreamSource* source = info.open_gl_stream;
  if (source == nullptr ||
      source->struct_size < sizeof(FlutterOpenGLTextureStreamSource) ||
      source->attach_callback == nullptr ||
      source->update_callback == nullptr ||
      source->detach_callback == nullptr) {
    return nullptr;
  }
  return std::unique_ptr<EmbedderGLStreamTexture>(new EmbedderGLStreamTexture(
      info.texture_id,
      EmbedderOpenGLTextureStream{.callbacks = *source,
                                  .user_data = info.user_data},
      info.destruction_callback));
}

EmbedderGLStreamTexture::EmbedderGLStreamTexture(
    int64_t id,
    EmbedderOpenGLTextureStream stream,
    VoidCallback destruction_callback)
    : Texture(id),
      stream_(stream),
      destruction_callback_(destruction_callback) {}

EmbedderGLStreamTexture::~EmbedderGLStreamTexture() {
  // The implementation calls the stream until it is gone.
  implementation_.reset();
  if (destruction_callback_ != nullptr) {
    destruction_callback_(stream_.user_data);
  }
}

std::unique_ptr<EmbedderExternalTextureGLStream>
EmbedderGLStreamTexture::CreateImplementation(PaintContext& context) {
#if IMPELLER_SUPPORTS_RENDERING
  if (context.aiks_context != nullptr) {
    const std::shared_ptr<impeller::Context>& impeller_context =
        context.aiks_context->GetContext();
    switch (impeller_context->GetBackendType()) {
#if defined(SHELL_ENABLE_GL)
      case impeller::Context::BackendType::kOpenGLES:
        return std::make_unique<EmbedderExternalTextureGLStreamImpeller>(
            std::static_pointer_cast<impeller::ContextGLES>(impeller_context),
            Id(), stream_);
#endif  // defined(SHELL_ENABLE_GL)
#if FML_OS_ANDROID && defined(SHELL_ENABLE_VULKAN)
      case impeller::Context::BackendType::kVulkan:
        // Like EmbedderExternalTextureGLStreamVK::ProcessFrame, this expects
        // the surface context that onscreen and snapshot surfaces paint with.
        return std::make_unique<EmbedderExternalTextureGLStreamVK>(
            std::static_pointer_cast<impeller::ContextVK>(
                impeller::SurfaceContextVK::Cast(*impeller_context)
                    .GetParent()),
            Id(), stream_);
#endif  // FML_OS_ANDROID && defined(SHELL_ENABLE_VULKAN)
      default:
        return nullptr;
    }
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
#if FML_OS_ANDROID && defined(SHELL_ENABLE_GL) && !SLIMPELLER
  if (context.gr_context != nullptr) {
    return std::make_unique<EmbedderExternalTextureGLStreamSkia>(Id(), stream_);
  }
#endif  // FML_OS_ANDROID && defined(SHELL_ENABLE_GL) && !SLIMPELLER
  return nullptr;
}

void EmbedderGLStreamTexture::Paint(PaintContext& context,
                                    const DlRect& bounds,
                                    bool freeze,
                                    const DlImageSampling sampling) {
  if (!implementation_) {
    TRACE_EVENT0("flutter", "EmbedderGLStreamTexture::CreateImplementation");
    implementation_ = CreateImplementation(context);
    if (!implementation_) {
      if (!logged_unsupported_renderer_) {
        FML_LOG(ERROR) << "OpenGL stream textures are not supported by the "
                          "current renderer; texture "
                       << Id() << " is not drawn.";
        logged_unsupported_renderer_ = true;
      }
      return;
    }
  }
  static_cast<Texture&>(*implementation_)
      .Paint(context, bounds, freeze, sampling);
}

void EmbedderGLStreamTexture::OnGrContextCreated() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnGrContextCreated();
  }
}

void EmbedderGLStreamTexture::OnGrContextDestroyed() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnGrContextDestroyed();
  }
}

void EmbedderGLStreamTexture::MarkNewFrameAvailable() {
  // The stream reports new frames through has_pending_frame_callback.
}

void EmbedderGLStreamTexture::OnTextureUnregistered() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnTextureUnregistered();
  }
}

}  // namespace flutter
