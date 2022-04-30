// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_texture_registrar.h"

#include <iostream>
#include <mutex>

#include "flutter/shell/platform/embedder/embedder_struct_macros.h"
#include "flutter/shell/platform/windows/external_texture_d3d.h"
#include "flutter/shell/platform/windows/external_texture_pixelbuffer.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace {
static constexpr int64_t kInvalidTexture = -1;
}

namespace flutter {

FlutterWindowsTextureRegistrar::FlutterWindowsTextureRegistrar(
    FlutterWindowsEngine* engine,
    const GlProcs& gl_procs)
    : engine_(engine), gl_procs_(gl_procs) {}

int64_t FlutterWindowsTextureRegistrar::RegisterTexture(
    const FlutterDesktopTextureInfo* texture_info) {
  if (!gl_procs_.valid) {
    return kInvalidTexture;
  }

  if (texture_info->type == kFlutterDesktopPixelBufferTexture) {
    if (!texture_info->pixel_buffer_config.callback) {
      std::cerr << "Invalid pixel buffer texture callback." << std::endl;
      return kInvalidTexture;
    }

    return EmplaceTexture(std::make_unique<flutter::ExternalTexturePixelBuffer>(
        texture_info->pixel_buffer_config.callback,
        texture_info->pixel_buffer_config.user_data, gl_procs_));
  } else if (texture_info->type == kFlutterDesktopGpuSurfaceTexture) {
    const FlutterDesktopGpuSurfaceTextureConfig* gpu_surface_config =
        &texture_info->gpu_surface_config;
    auto surface_type = SAFE_ACCESS(gpu_surface_config, type,
                                    kFlutterDesktopGpuSurfaceTypeNone);
    if (surface_type == kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle ||
        surface_type == kFlutterDesktopGpuSurfaceTypeD3d11Texture2D) {
      auto callback = SAFE_ACCESS(gpu_surface_config, callback, nullptr);
      if (!callback) {
        std::cerr << "Invalid GPU surface descriptor callback." << std::endl;
        return kInvalidTexture;
      }

      auto user_data = SAFE_ACCESS(gpu_surface_config, user_data, nullptr);
      return EmplaceTexture(std::make_unique<flutter::ExternalTextureD3d>(
          surface_type, callback, user_data, engine_->surface_manager(),
          gl_procs_));
    }
  }

  std::cerr << "Attempted to register texture of unsupport type." << std::endl;
  return kInvalidTexture;
}

int64_t FlutterWindowsTextureRegistrar::EmplaceTexture(
    std::unique_ptr<ExternalTexture> texture) {
  int64_t texture_id = texture->texture_id();
  {
    std::lock_guard<std::mutex> lock(map_mutex_);
    textures_[texture_id] = std::move(texture);
  }

  engine_->task_runner()->RunNowOrPostTask([engine = engine_, texture_id]() {
    engine->RegisterExternalTexture(texture_id);
  });

  return texture_id;
}

bool FlutterWindowsTextureRegistrar::UnregisterTexture(int64_t texture_id) {
  {
    std::lock_guard<std::mutex> lock(map_mutex_);
    auto it = textures_.find(texture_id);
    if (it == textures_.end()) {
      return false;
    }
    textures_.erase(it);
  }

  engine_->task_runner()->RunNowOrPostTask([engine = engine_, texture_id]() {
    engine->UnregisterExternalTexture(texture_id);
  });
  return true;
}

bool FlutterWindowsTextureRegistrar::MarkTextureFrameAvailable(
    int64_t texture_id) {
  engine_->task_runner()->RunNowOrPostTask([engine = engine_, texture_id]() {
    engine->MarkExternalTextureFrameAvailable(texture_id);
  });
  return true;
}

bool FlutterWindowsTextureRegistrar::PopulateTexture(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLTexture* opengl_texture) {
  flutter::ExternalTexture* texture;
  {
    std::lock_guard<std::mutex> lock(map_mutex_);
    auto it = textures_.find(texture_id);
    if (it == textures_.end()) {
      return false;
    }
    texture = it->second.get();
  }
  return texture->PopulateTexture(width, height, opengl_texture);
}

void FlutterWindowsTextureRegistrar::ResolveGlFunctions(GlProcs& procs) {
  procs.glGenTextures =
      reinterpret_cast<glGenTexturesProc>(eglGetProcAddress("glGenTextures"));
  procs.glDeleteTextures = reinterpret_cast<glDeleteTexturesProc>(
      eglGetProcAddress("glDeleteTextures"));
  procs.glBindTexture =
      reinterpret_cast<glBindTextureProc>(eglGetProcAddress("glBindTexture"));
  procs.glTexParameteri = reinterpret_cast<glTexParameteriProc>(
      eglGetProcAddress("glTexParameteri"));
  procs.glTexImage2D =
      reinterpret_cast<glTexImage2DProc>(eglGetProcAddress("glTexImage2D"));

  procs.valid = procs.glGenTextures && procs.glDeleteTextures &&
                procs.glBindTexture && procs.glTexParameteri &&
                procs.glTexImage2D;
}

};  // namespace flutter
