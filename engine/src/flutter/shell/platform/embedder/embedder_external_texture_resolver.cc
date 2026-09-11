// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_resolver.h"

#include <memory>
#include <utility>

namespace flutter {

class EmbedderExternalTextureDual : public flutter::Texture {
 public:
  EmbedderExternalTextureDual(
      int64_t texture_identifier,
      std::unique_ptr<EmbedderExternalTextureHB> hb_texture,
      std::unique_ptr<flutter::Texture> native_texture)
      : Texture(texture_identifier),
        hb_texture_(std::move(hb_texture)),
        native_texture_(std::move(native_texture)) {
    FML_DCHECK(hb_texture_);
    FML_DCHECK(native_texture_);
  }

  ~EmbedderExternalTextureDual() override = default;

  // |flutter::Texture|
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override {
    if (hb_texture_) {
      hb_texture_->Paint(context, bounds, freeze, sampling);
      if (hb_texture_->HasValidImage()) {
        return;
      }
    }
    if (native_texture_) {
      native_texture_->Paint(context, bounds, freeze, sampling);
    }
  }

  // |flutter::Texture|
  void OnGrContextCreated() override {
    if (hb_texture_) {
      hb_texture_->OnGrContextCreated();
    }
    if (native_texture_) {
      native_texture_->OnGrContextCreated();
    }
  }

  // |flutter::Texture|
  void OnGrContextDestroyed() override {
    if (hb_texture_) {
      hb_texture_->OnGrContextDestroyed();
    }
    if (native_texture_) {
      native_texture_->OnGrContextDestroyed();
    }
  }

  // |flutter::Texture|
  void MarkNewFrameAvailable() override {
    if (hb_texture_) {
      hb_texture_->MarkNewFrameAvailable();
    }
    if (native_texture_) {
      native_texture_->MarkNewFrameAvailable();
    }
  }

  // |flutter::Texture|
  void OnTextureUnregistered() override {
    if (hb_texture_) {
      hb_texture_->OnTextureUnregistered();
    }
    if (native_texture_) {
      native_texture_->OnTextureUnregistered();
    }
  }

 private:
  std::unique_ptr<EmbedderExternalTextureHB> hb_texture_;
  std::unique_ptr<flutter::Texture> native_texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureDual);
};

#ifdef SHELL_ENABLE_GL
EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureGL::ExternalTextureCallback gl_callback)
    : gl_callback_(std::move(gl_callback)) {}

EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureGL::ExternalTextureCallback gl_callback,
    EmbedderExternalTextureHB::ExternalTextureCallback hardware_buffer_callback)
    : gl_callback_(std::move(gl_callback)),
      hardware_buffer_callback_(std::move(hardware_buffer_callback)) {}

void EmbedderExternalTextureResolver::SetGLCallback(
    EmbedderExternalTextureGL::ExternalTextureCallback gl_callback) {
  gl_callback_ = std::move(gl_callback);
}
#endif

#ifdef SHELL_ENABLE_METAL
EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureMetal::ExternalTextureCallback metal_callback)
    : metal_callback_(std::move(metal_callback)) {}

EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureMetal::ExternalTextureCallback metal_callback,
    EmbedderExternalTextureHB::ExternalTextureCallback hardware_buffer_callback)
    : metal_callback_(std::move(metal_callback)),
      hardware_buffer_callback_(std::move(hardware_buffer_callback)) {}

void EmbedderExternalTextureResolver::SetMetalCallback(
    EmbedderExternalTextureMetal::ExternalTextureCallback metal_callback) {
  metal_callback_ = std::move(metal_callback);
}
#endif

#ifdef SHELL_ENABLE_VULKAN
EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureVK::ExternalTextureCallback vulkan_callback)
    : vulkan_callback_(std::move(vulkan_callback)) {}

EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureVK::ExternalTextureCallback vulkan_callback,
    EmbedderExternalTextureHB::ExternalTextureCallback hardware_buffer_callback)
    : vulkan_callback_(std::move(vulkan_callback)),
      hardware_buffer_callback_(std::move(hardware_buffer_callback)) {}

void EmbedderExternalTextureResolver::SetVulkanCallback(
    EmbedderExternalTextureVK::ExternalTextureCallback vulkan_callback) {
  vulkan_callback_ = std::move(vulkan_callback);
}
#endif

EmbedderExternalTextureResolver::EmbedderExternalTextureResolver(
    EmbedderExternalTextureHB::ExternalTextureCallback hardware_buffer_callback)
    : hardware_buffer_callback_(std::move(hardware_buffer_callback)) {}

void EmbedderExternalTextureResolver::SetHardwareBufferCallback(
    EmbedderExternalTextureHB::ExternalTextureCallback
        hardware_buffer_callback) {
  hardware_buffer_callback_ = std::move(hardware_buffer_callback);
}

std::unique_ptr<Texture>
EmbedderExternalTextureResolver::ResolveExternalTexture(int64_t texture_id) {
#ifdef SHELL_ENABLE_GL
  if (gl_callback_ && hardware_buffer_callback_) {
    auto hb = std::make_unique<EmbedderExternalTextureHB>(
        texture_id, hardware_buffer_callback_);
    auto gl =
        std::make_unique<EmbedderExternalTextureGL>(texture_id, gl_callback_);
    return std::make_unique<EmbedderExternalTextureDual>(
        texture_id, std::move(hb), std::move(gl));
  }
  if (gl_callback_) {
    return std::make_unique<EmbedderExternalTextureGL>(texture_id,
                                                       gl_callback_);
  }
#endif

#ifdef SHELL_ENABLE_VULKAN
  if (vulkan_callback_ && hardware_buffer_callback_) {
    auto hb = std::make_unique<EmbedderExternalTextureHB>(
        texture_id, hardware_buffer_callback_);
    auto vk = std::make_unique<EmbedderExternalTextureVK>(texture_id,
                                                          vulkan_callback_);
    return std::make_unique<EmbedderExternalTextureDual>(
        texture_id, std::move(hb), std::move(vk));
  }
  if (vulkan_callback_) {
    return std::make_unique<EmbedderExternalTextureVK>(texture_id,
                                                       vulkan_callback_);
  }
#endif

#ifdef SHELL_ENABLE_METAL
  if (metal_callback_ && hardware_buffer_callback_) {
    auto hb = std::make_unique<EmbedderExternalTextureHB>(
        texture_id, hardware_buffer_callback_);
    auto metal = std::make_unique<EmbedderExternalTextureMetal>(
        texture_id, metal_callback_);
    return std::make_unique<EmbedderExternalTextureDual>(
        texture_id, std::move(hb), std::move(metal));
  }
  if (metal_callback_) {
    return std::make_unique<EmbedderExternalTextureMetal>(texture_id,
                                                          metal_callback_);
  }
#endif

  if (hardware_buffer_callback_) {
    return std::make_unique<EmbedderExternalTextureHB>(
        texture_id, hardware_buffer_callback_);
  }

  return nullptr;
}

bool EmbedderExternalTextureResolver::SupportsExternalTextures() const {
#ifdef SHELL_ENABLE_GL
  if (gl_callback_) {
    return true;
  }
#endif

#ifdef SHELL_ENABLE_METAL
  if (metal_callback_) {
    return true;
  }
#endif

#ifdef SHELL_ENABLE_VULKAN
  if (vulkan_callback_) {
    return true;
  }
#endif

  if (hardware_buffer_callback_) {
    return true;
  }

  return false;
}

}  // namespace flutter
