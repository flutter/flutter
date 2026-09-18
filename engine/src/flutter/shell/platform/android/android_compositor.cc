// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_compositor.h"

#include <algorithm>
#include <cstring>
#include <new>

#include "flutter/fml/logging.h"

namespace flutter {

AndroidCompositor::AndroidCompositor(
    std::shared_ptr<AndroidSurfaceManager> surface_manager,
    std::shared_ptr<AndroidCompositorPlatformViewDelegate>
        platform_view_delegate)
    : surface_manager_(std::move(surface_manager)),
      platform_view_delegate_(std::move(platform_view_delegate)) {}

AndroidCompositor::~AndroidCompositor() = default;

void AndroidCompositor::SetPlatformViewDelegate(
    std::shared_ptr<AndroidCompositorPlatformViewDelegate> delegate) {
  std::lock_guard<std::mutex> lock(present_mutex_);
  platform_view_delegate_ = std::move(delegate);
}

bool AndroidCompositor::CreateBackingStore(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  if (config == nullptr || backing_store_out == nullptr) {
    return false;
  }
  if (config->struct_size < sizeof(FlutterBackingStoreConfig)) {
    return false;
  }
  if (config->size.width <= 0.0 || config->size.height <= 0.0 ||
      config->size.width > 65536.0 || config->size.height > 65536.0) {
    return false;
  }
  if (!surface_manager_ || !surface_manager_->IsValid()) {
    return false;
  }

  std::memset(backing_store_out, 0, sizeof(FlutterBackingStore));
  backing_store_out->struct_size = sizeof(FlutterBackingStore);
  backing_store_out->user_data = nullptr;
  backing_store_out->did_update = true;

  switch (surface_manager_->GetRenderingAPI()) {
    case AndroidRenderingAPI::kSoftware: {
      size_t width = static_cast<size_t>(config->size.width);
      size_t height = static_cast<size_t>(config->size.height);
      size_t row_bytes = width * 4;
      size_t allocation_size = row_bytes * height;
      if (allocation_size == 0) {
        allocation_size = 4;
      }
      uint8_t* allocation = new (std::nothrow) uint8_t[allocation_size]();
      if (allocation == nullptr) {
        return false;
      }

      backing_store_out->type = kFlutterBackingStoreTypeSoftware;
      backing_store_out->user_data = allocation;
      backing_store_out->software.allocation = allocation;
      backing_store_out->software.row_bytes = row_bytes;
      backing_store_out->software.height = height;
      backing_store_out->software.user_data = allocation;
      backing_store_out->software.destruction_callback = nullptr;
      return true;
    }
    case AndroidRenderingAPI::kSkiaOpenGLES:
    case AndroidRenderingAPI::kImpellerOpenGLES:
    case AndroidRenderingAPI::kImpellerAutoselect:
    case AndroidRenderingAPI::kImpellerVulkan: {
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->user_data = this;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      // 0x8058 is GL_RGBA8, required by embedder.cc format conversion.
      backing_store_out->open_gl.framebuffer.target = 0x8058;
      backing_store_out->open_gl.framebuffer.name = surface_manager_->GetFBO();
      backing_store_out->open_gl.framebuffer.user_data = nullptr;
      backing_store_out->open_gl.framebuffer.destruction_callback = nullptr;
      return true;
    }
  }
  return false;
}

bool AndroidCompositor::CollectBackingStore(
    const FlutterBackingStore* renderer) {
  if (renderer == nullptr) {
    return false;
  }
  if (renderer->type == kFlutterBackingStoreTypeSoftware &&
      renderer->user_data != nullptr) {
    delete[] static_cast<const uint8_t*>(renderer->user_data);
  }
  return true;
}

bool AndroidCompositor::PresentLayers(const FlutterLayer** layers,
                                      size_t layers_count) {
  if (layers == nullptr && layers_count > 0) {
    return false;
  }

  std::shared_ptr<AndroidCompositorPlatformViewDelegate> delegate;
  {
    std::lock_guard<std::mutex> lock(present_mutex_);
    presented_frame_count_++;
    last_presented_layers_count_ = layers_count;
    delegate = platform_view_delegate_;
  }

  if (!surface_manager_) {
    return false;
  }

  if (delegate != nullptr) {
    delegate->OnBeginFrame();
  }

  bool present_success = true;
  size_t platform_views_count = 0;

  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    if (layer == nullptr || layer->struct_size < sizeof(FlutterLayer)) {
      continue;
    }

    if (layer->type == kFlutterLayerContentTypeBackingStore) {
      if (layer->backing_store != nullptr) {
        if (layer->backing_store->type == kFlutterBackingStoreTypeSoftware) {
          bool res = surface_manager_->PresentSoftware(
              layer->backing_store->software.allocation,
              layer->backing_store->software.row_bytes,
              layer->backing_store->software.height);
          if (!res && !surface_manager_->IsFakeWindow()) {
            present_success = false;
          }
        } else if (layer->backing_store->type ==
                   kFlutterBackingStoreTypeOpenGL) {
          bool res = surface_manager_->Present();
          if (!res && !surface_manager_->IsFakeWindow()) {
            present_success = false;
          }
        }
      }
    } else if (layer->type == kFlutterLayerContentTypePlatformView) {
      platform_views_count++;
      if (layer->platform_view != nullptr &&
          layer->platform_view->struct_size >= sizeof(FlutterPlatformView) &&
          delegate != nullptr) {
        delegate->OnPlatformViewPresented(layer->platform_view->identifier,
                                          layer->offset, layer->size,
                                          layer->platform_view->mutations_count,
                                          layer->platform_view->mutations);
      }
    }
  }

  if (delegate != nullptr) {
    delegate->OnFramePresented();
  }

  {
    std::lock_guard<std::mutex> lock(present_mutex_);
    last_presented_platform_views_count_ = platform_views_count;
  }

  // If the surface was detached concurrently, avoid crashing or failing fatally
  // to ensure ANR-safe non-blocking teardown and backgrounding behavior.
  if (surface_manager_->GetNativeWindow() == nullptr &&
      !surface_manager_->IsFakeWindow()) {
    return true;
  }

  return present_success;
}

bool AndroidCompositor::PresentView(
    const FlutterPresentViewInfo* present_info) {
  if (present_info == nullptr) {
    return false;
  }
  if (present_info->struct_size < sizeof(FlutterPresentViewInfo)) {
    return false;
  }
  return PresentLayers(present_info->layers, present_info->layers_count);
}

void AndroidCompositor::PopulateCompositorConfig(
    FlutterCompositor* compositor_out) {
  if (compositor_out == nullptr) {
    return;
  }
  compositor_out->struct_size = sizeof(FlutterCompositor);
  compositor_out->user_data = this;
  compositor_out->create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,
         FlutterBackingStore* backing_store_out, void* user_data) -> bool {
    return static_cast<AndroidCompositor*>(user_data)->CreateBackingStore(
        config, backing_store_out);
  };
  compositor_out->collect_backing_store_callback =
      [](const FlutterBackingStore* renderer, void* user_data) -> bool {
    return static_cast<AndroidCompositor*>(user_data)->CollectBackingStore(
        renderer);
  };
  compositor_out->present_layers_callback = nullptr;
  compositor_out->avoid_backing_store_cache = false;
  compositor_out->present_view_callback =
      [](const FlutterPresentViewInfo* info) -> bool {
    if (info == nullptr || info->user_data == nullptr) {
      return false;
    }
    return static_cast<AndroidCompositor*>(info->user_data)->PresentView(info);
  };
}

size_t AndroidCompositor::GetPresentedFrameCount() const {
  std::lock_guard<std::mutex> lock(present_mutex_);
  return presented_frame_count_;
}

size_t AndroidCompositor::GetLastPresentedLayersCount() const {
  std::lock_guard<std::mutex> lock(present_mutex_);
  return last_presented_layers_count_;
}

size_t AndroidCompositor::GetLastPresentedPlatformViewsCount() const {
  std::lock_guard<std::mutex> lock(present_mutex_);
  return last_presented_platform_views_count_;
}

}  // namespace flutter
