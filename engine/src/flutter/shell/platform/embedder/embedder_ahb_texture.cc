// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_ahb_texture.h"

#include <utility>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"

#if FML_OS_ANDROID
#if defined(SHELL_ENABLE_GL) && !SLIMPELLER
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_gl_skia.h"
#endif  // defined(SHELL_ENABLE_GL) && !SLIMPELLER

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/impeller/display_list/aiks_context.h"
#if defined(SHELL_ENABLE_GL)
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_gl_impeller.h"
#endif  // defined(SHELL_ENABLE_GL)
#if defined(SHELL_ENABLE_VULKAN)
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_vk.h"
#endif  // defined(SHELL_ENABLE_VULKAN)
#endif  // IMPELLER_SUPPORTS_RENDERING
#endif  // FML_OS_ANDROID

namespace flutter {

std::unique_ptr<EmbedderAHBTexture> EmbedderAHBTexture::Create(
    const FlutterExternalTextureInfo& info,
    EmbedderImpellerDeviceContextGetter device_context) {
  if (info.type != kFlutterExternalTextureTypeAndroidHardwareBuffer) {
    return nullptr;
  }
  // SAFE_ACCESS takes a pointer variable.
  const FlutterExternalTextureInfo* info_pointer = &info;
  const FlutterAndroidHardwareBufferSource* source =
      SAFE_ACCESS(info_pointer, android_hardware_buffer, nullptr);
  if (source == nullptr ||
      source->struct_size < sizeof(FlutterAndroidHardwareBufferSource) ||
      source->acquire_frame_callback == nullptr) {
    return nullptr;
  }
  return std::unique_ptr<EmbedderAHBTexture>(new EmbedderAHBTexture(
      info.texture_id,
      EmbedderAndroidHardwareBufferSource{.callbacks = *source,
                                          .user_data = info.user_data},
      info.destruction_callback, std::move(device_context)));
}

EmbedderAHBTexture::EmbedderAHBTexture(
    int64_t id,
    EmbedderAndroidHardwareBufferSource source,
    VoidCallback destruction_callback,
    EmbedderImpellerDeviceContextGetter device_context)
    : Texture(id),
      source_(source),
      destruction_callback_(destruction_callback),
      device_context_(std::move(device_context)) {}

EmbedderAHBTexture::~EmbedderAHBTexture() {
  // The implementation calls the source until it is gone.
  implementation_.reset();
  if (destruction_callback_ != nullptr) {
    destruction_callback_(source_.user_data);
  }
}

std::unique_ptr<EmbedderExternalTextureAHB>
EmbedderAHBTexture::CreateImplementation(PaintContext& context) {
#if FML_OS_ANDROID
#if IMPELLER_SUPPORTS_RENDERING
  if (context.aiks_context != nullptr) {
    const std::shared_ptr<impeller::Context>& paint_context =
        context.aiks_context->GetContext();
    switch (paint_context->GetBackendType()) {
#if defined(SHELL_ENABLE_GL)
      case impeller::Context::BackendType::kOpenGLES:
        // OpenGL ES surfaces paint with the device context itself.
        return std::make_unique<EmbedderExternalTextureAHBGLImpeller>(
            std::static_pointer_cast<impeller::ContextGLES>(paint_context),
            Id(), source_);
#endif  // defined(SHELL_ENABLE_GL)
#if defined(SHELL_ENABLE_VULKAN)
      case impeller::Context::BackendType::kVulkan: {
        std::shared_ptr<impeller::Context> device =
            device_context_ ? device_context_() : paint_context;
        if (!device || device->GetBackendType() !=
                           impeller::Context::BackendType::kVulkan) {
          return nullptr;
        }
        // `AndroidSurfaceVKImpeller::GetImpellerContext()` and onscreen Vulkan
        // surfaces return a `SurfaceContextVK` (whose `GetSubmissionTracker()`
        // is null and whose `GetParent()` is the `ContextVK`), while
        // `AndroidSurfaceDynamicImpeller::GetImpellerContext()` and offscreen
        // contexts return the `ContextVK` directly.
        std::shared_ptr<impeller::ContextVK> context_vk =
            device->GetSubmissionTracker() != nullptr
                ? std::static_pointer_cast<impeller::ContextVK>(device)
                : impeller::SurfaceContextVK::Cast(*device).GetParent();
        return std::make_unique<EmbedderExternalTextureAHBVK>(
            std::move(context_vk), Id(), source_);
      }
#endif  // defined(SHELL_ENABLE_VULKAN)
      default:
        return nullptr;
    }
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
#if defined(SHELL_ENABLE_GL) && !SLIMPELLER
  if (context.gr_context != nullptr) {
    return std::make_unique<EmbedderExternalTextureAHBGLSkia>(Id(), source_);
  }
#endif  // defined(SHELL_ENABLE_GL) && !SLIMPELLER
#endif  // FML_OS_ANDROID
  return nullptr;
}

void EmbedderAHBTexture::Paint(PaintContext& context,
                               const DlRect& bounds,
                               bool freeze,
                               const DlImageSampling sampling) {
  if (!implementation_) {
    TRACE_EVENT0("flutter", "EmbedderAHBTexture::CreateImplementation");
    implementation_ = CreateImplementation(context);
    if (!implementation_) {
      if (!logged_unsupported_renderer_) {
        FML_LOG(ERROR) << "Android hardware buffer textures are not supported "
                          "by the current renderer; texture "
                       << Id() << " is not drawn.";
        logged_unsupported_renderer_ = true;
      }
      return;
    }
  }
  static_cast<Texture&>(*implementation_)
      .Paint(context, bounds, freeze, sampling);
}

void EmbedderAHBTexture::OnGrContextCreated() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnGrContextCreated();
  }
}

void EmbedderAHBTexture::OnGrContextDestroyed() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnGrContextDestroyed();
  }
}

void EmbedderAHBTexture::MarkNewFrameAvailable() {
  // The source hands out its newest frame at every unfrozen paint.
}

void EmbedderAHBTexture::OnTextureUnregistered() {
  if (implementation_) {
    static_cast<Texture&>(*implementation_).OnTextureUnregistered();
  }
}

}  // namespace flutter
