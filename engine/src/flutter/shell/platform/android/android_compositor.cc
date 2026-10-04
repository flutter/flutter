// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_compositor.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <new>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"

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
  if (config->struct_size <
      offsetof(FlutterBackingStoreConfig, view_id) + sizeof(FlutterViewId)) {
    return false;
  }
  if (config->size.width <= 0.0 || config->size.height <= 0.0 ||
      config->size.width > 65536.0 || config->size.height > 65536.0) {
    return false;
  }
  if (!surface_manager_ || !surface_manager_->IsValid()) {
    return false;
  }

  bool is_overlay = SAFE_ACCESS(config, is_overlay, false);

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
    case AndroidRenderingAPI::kImpellerVulkan:
    case AndroidRenderingAPI::kImpellerAutoselect: {
      if (surface_manager_->IsVulkanInitialized() ||
          surface_manager_->IsFakeWindow()) {
        FlutterFrameInfo frame_info = {};
        frame_info.struct_size = sizeof(FlutterFrameInfo);
        frame_info.size.width =
            static_cast<uint32_t>(std::round(config->size.width));
        frame_info.size.height =
            static_cast<uint32_t>(std::round(config->size.height));
        if (!is_overlay && backing_stores_created_in_frame_ == 0) {
          bool expected = false;
          if (!has_active_onscreen_vulkan_backing_store_
                   .compare_exchange_strong(expected, true)) {
            FML_LOG(WARNING)
                << "AndroidCompositor: multiple onscreen Vulkan backing stores "
                   "requested in a single frame.";
            return false;
          }
          FlutterVulkanImage img = surface_manager_->GetNextImage(&frame_info);
          if (img.image == 0 && !surface_manager_->IsFakeWindow()) {
            has_active_onscreen_vulkan_backing_store_ = false;
            return false;
          }
          auto* tracker = new VulkanBackingStoreTracker{
              .image = img,
              .is_onscreen = true,
              .overlay_window = nullptr,
          };
          backing_store_out->type = kFlutterBackingStoreTypeVulkan;
          backing_store_out->user_data = tracker;
          backing_store_out->vulkan.struct_size =
              sizeof(FlutterVulkanBackingStore);
          backing_store_out->vulkan.image = &tracker->image;
          backing_store_out->vulkan.user_data = tracker;
          backing_store_out->vulkan.destruction_callback = nullptr;
          backing_stores_created_in_frame_++;
          return true;
        } else {
          // Secondary / overlay backing store.
          std::shared_ptr<AndroidCompositorPlatformViewDelegate> delegate;
          {
            std::lock_guard<std::mutex> lock(present_mutex_);
            delegate = platform_view_delegate_;
          }
          if (delegate == nullptr) {
            FML_LOG(WARNING) << "AndroidCompositor: secondary Vulkan backing "
                                "store requested "
                                "without a platform view delegate.";
            return false;
          }

          size_t overlay_index = overlay_backing_stores_created_in_frame_++;
          ANativeWindow* overlay_window =
              delegate->GetOverlayWindow(overlay_index);
          if (overlay_window == nullptr && !surface_manager_->IsFakeWindow()) {
            FML_LOG(WARNING)
                << "AndroidCompositor: overlay Vulkan backing store requested "
                   "for overlay_index="
                << overlay_index
                << " but no overlay native window is available.";
            return false;
          }
          FlutterVulkanImage img = surface_manager_->GetNextOverlayImage(
              overlay_window, &frame_info);
          if (img.image == 0 && !surface_manager_->IsFakeWindow()) {
            FML_LOG(WARNING)
                << "AndroidCompositor: failed to acquire overlay Vulkan image "
                   "for overlay_index="
                << overlay_index;
            return false;
          }
          auto* tracker = new VulkanBackingStoreTracker{
              .image = img,
              .is_onscreen = false,
              .overlay_window = overlay_window,
          };
          backing_store_out->type = kFlutterBackingStoreTypeVulkan;
          backing_store_out->user_data = tracker;
          backing_store_out->vulkan.struct_size =
              sizeof(FlutterVulkanBackingStore);
          backing_store_out->vulkan.image = &tracker->image;
          backing_store_out->vulkan.user_data = tracker;
          backing_store_out->vulkan.destruction_callback = nullptr;
          backing_stores_created_in_frame_++;
          return true;
        }
      }
      [[fallthrough]];
    }
    case AndroidRenderingAPI::kSkiaOpenGLES:
    case AndroidRenderingAPI::kImpellerOpenGLES: {
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      // 0x8058 is GL_RGBA8, required by embedder.cc format conversion.
      backing_store_out->open_gl.framebuffer.target = 0x8058;

      size_t width = static_cast<size_t>(std::round(config->size.width));
      size_t height = static_cast<size_t>(std::round(config->size.height));

      bool has_current_egl_context = false;
#if FML_OS_ANDROID
      has_current_egl_context = (eglGetCurrentContext() != EGL_NO_CONTEXT);
#endif
      if (!is_overlay && backing_stores_created_in_frame_ == 0 &&
          !has_current_egl_context) {
        backing_store_out->user_data = nullptr;
        backing_store_out->open_gl.framebuffer.name =
            surface_manager_->GetFBO();
      } else {
        auto offscreen = surface_manager_->AcquireOffscreenFBO(width, height);
        auto* tracker = new OffscreenTracker{offscreen};
        backing_store_out->user_data = tracker;
        backing_store_out->open_gl.framebuffer.name = offscreen.fbo;
      }
      backing_stores_created_in_frame_++;

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
  if (backing_stores_created_in_frame_ > 0) {
    backing_stores_created_in_frame_--;
  }
  if (renderer->type == kFlutterBackingStoreTypeSoftware &&
      renderer->user_data != nullptr) {
    delete[] static_cast<const uint8_t*>(renderer->user_data);
  } else if (renderer->type == kFlutterBackingStoreTypeOpenGL &&
             renderer->user_data != nullptr) {
    auto* tracker = static_cast<OffscreenTracker*>(renderer->user_data);
    surface_manager_->ReleaseOffscreenFBO(tracker->fbo);
    delete tracker;
  } else if (renderer->type == kFlutterBackingStoreTypeVulkan &&
             renderer->user_data != nullptr) {
    auto* tracker =
        static_cast<VulkanBackingStoreTracker*>(renderer->user_data);
    if (tracker->is_onscreen) {
      has_active_onscreen_vulkan_backing_store_ = false;
    } else {
      if (overlay_backing_stores_created_in_frame_ > 0) {
        overlay_backing_stores_created_in_frame_--;
      }
    }
    delete tracker;
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
    delegate->SetPendingRootOpenGLBackingStore(0, 0, 0);
    delegate->OnBeginFrame();
  }

  bool present_success = true;
  size_t platform_views_count = 0;
  size_t overlays_count = 0;
  backing_stores_created_in_frame_ = 0;
  overlay_backing_stores_created_in_frame_ = 0;
  has_active_onscreen_vulkan_backing_store_ = false;
  const FlutterLayer* root_backing_store_layer = nullptr;

  // Identify the root onscreen backing store layer first. For Vulkan, present
  // the root swapchain image before OnPlatformViewPresented runs, because
  // OnPlatformViewPresented on the first non-HCPP platform view frame invokes
  // convertToImageView() -> SetNativeWindow(FlutterImageView), which replaces
  // the active swapchain.
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    if (layer == nullptr || layer->struct_size < sizeof(FlutterLayer)) {
      continue;
    }
    if (layer->type == kFlutterLayerContentTypePlatformView) {
      break;
    }
    if (layer->type == kFlutterLayerContentTypeBackingStore &&
        layer->backing_store != nullptr) {
      bool is_root = false;
      if (layer->backing_store->type == kFlutterBackingStoreTypeVulkan) {
        if (layer->backing_store->user_data != nullptr) {
          auto* tracker = static_cast<VulkanBackingStoreTracker*>(
              layer->backing_store->user_data);
          is_root = tracker->is_onscreen;
        } else {
          is_root = true;
        }
      } else {
        is_root = true;
      }
      if (is_root) {
        root_backing_store_layer = layer;
      }
      break;
    }
  }

  bool root_vulkan_presented_before_views = false;
  if (root_backing_store_layer != nullptr &&
      root_backing_store_layer->backing_store->type ==
          kFlutterBackingStoreTypeVulkan) {
    const FlutterBackingStore* bs = root_backing_store_layer->backing_store;
    bool res = surface_manager_->PresentImage(bs->vulkan.image);
    if (!res && !surface_manager_->IsFakeWindow()) {
      present_success = false;
    }
    root_vulkan_presented_before_views = true;
  }

  ANativeWindow* window_before_present = surface_manager_->GetNativeWindow();

  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    if (layer == nullptr || layer->struct_size < sizeof(FlutterLayer)) {
      continue;
    }

    if (layer->type == kFlutterLayerContentTypeBackingStore) {
      if (layer->backing_store != nullptr) {
        if (layer == root_backing_store_layer) {
          continue;
        }
        ANativeWindow* overlay_window = nullptr;
        if (delegate != nullptr) {
          overlay_window = delegate->GetOverlayWindow(overlays_count);
        }
        if (layer->backing_store->type == kFlutterBackingStoreTypeOpenGL) {
          if (overlay_window != nullptr) {
            surface_manager_->BlitAndSwapOverlaySurface(
                overlay_window, layer->backing_store->open_gl.framebuffer.name,
                static_cast<size_t>(std::round(layer->size.width)),
                static_cast<size_t>(std::round(layer->size.height)));
          }
        } else if (layer->backing_store->type ==
                   kFlutterBackingStoreTypeVulkan) {
          if (layer->backing_store->user_data != nullptr) {
            auto* tracker = static_cast<VulkanBackingStoreTracker*>(
                layer->backing_store->user_data);
            if (tracker->overlay_window != nullptr) {
              overlay_window = tracker->overlay_window;
            }
          }
          if (overlay_window != nullptr || surface_manager_->IsFakeWindow()) {
            surface_manager_->PresentOverlayImage(
                overlay_window, layer->backing_store->vulkan.image);
          }
        }
        if (delegate != nullptr) {
          delegate->OnOverlayPresented(overlays_count, layer->offset,
                                       layer->size);
        }
        overlays_count++;
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

  ANativeWindow* window_after_present = surface_manager_->GetNativeWindow();
  bool window_switched_during_present =
      (window_after_present != window_before_present &&
       window_after_present != nullptr);

  if (root_backing_store_layer != nullptr &&
      !root_vulkan_presented_before_views) {
    const FlutterBackingStore* bs = root_backing_store_layer->backing_store;
    if (bs->type == kFlutterBackingStoreTypeSoftware) {
      bool res = surface_manager_->PresentSoftware(
          bs->software.allocation, bs->software.row_bytes, bs->software.height);
      if (!res && !surface_manager_->IsFakeWindow()) {
        present_success = false;
      }
    } else if (bs->type == kFlutterBackingStoreTypeOpenGL) {
      uint32_t fbo = bs->open_gl.framebuffer.name;
      size_t root_width =
          static_cast<size_t>(std::round(root_backing_store_layer->size.width));
      size_t root_height = static_cast<size_t>(
          std::round(root_backing_store_layer->size.height));
      if (delegate != nullptr) {
        delegate->SetPendingRootOpenGLBackingStore(fbo, root_width,
                                                   root_height);
      }
      bool res = false;
      if (fbo != 0) {
        res = surface_manager_->BlitAndPresentOnscreenSurface(fbo, root_width,
                                                              root_height);
      } else {
        res = surface_manager_->Present();
      }
      if (!res && !surface_manager_->IsFakeWindow()) {
        present_success = false;
      }
    }
  }

  if (platform_views_count > 0 &&
      surface_manager_->GetRenderingAPI() != AndroidRenderingAPI::kSoftware &&
      (root_backing_store_layer == nullptr ||
       (root_vulkan_presented_before_views &&
        window_switched_during_present))) {
    if (delegate != nullptr &&
        delegate->RequiresOnscreenClearanceWhenNoBackgroundLayer()) {
      // When a frame contains platform views (and optionally overlays) but no
      // background Flutter layer (or when Vulkan transitioned from
      // FlutterSurfaceView to FlutterImageView mid-frame), swap a transparent
      // frame to the onscreen FlutterImageView surface so that
      // FlutterView.acquireLatestImageViewFrame() succeeds in onEndFrame().
      surface_manager_->ClearAndPresentOnscreenSurface();
    }
  }

  const bool has_valid_surface =
      surface_manager_->GetNativeWindow() != nullptr ||
      surface_manager_->IsFakeWindow();
  const bool has_presented_content = root_backing_store_layer != nullptr ||
                                     overlays_count > 0 ||
                                     platform_views_count > 0;
  if (delegate != nullptr && has_valid_surface && present_success &&
      has_presented_content) {
    delegate->OnFramePresented();
  }

  {
    std::lock_guard<std::mutex> lock(present_mutex_);
    last_presented_platform_views_count_ = platform_views_count;
    last_presented_overlays_count_ = overlays_count;
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
  compositor_out->avoid_backing_store_cache = true;
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

size_t AndroidCompositor::GetLastPresentedOverlaysCount() const {
  std::lock_guard<std::mutex> lock(present_mutex_);
  return last_presented_overlays_count_;
}

}  // namespace flutter
