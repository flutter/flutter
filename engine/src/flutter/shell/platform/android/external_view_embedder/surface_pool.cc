// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/surface_pool.h"

#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {

OverlayLayer::OverlayLayer(int id,
                           std::unique_ptr<AndroidSurface> android_surface,
                           std::unique_ptr<Surface> surface)
    : id(id),
      android_surface(std::move(android_surface)),
      surface(std::move(surface)) {};

OverlayLayer::~OverlayLayer() = default;

SurfacePool::SurfacePool(bool use_new_surface_methods)
    : use_new_surface_methods_(use_new_surface_methods) {}

SurfacePool::~SurfacePool() = default;

std::shared_ptr<OverlayLayer> SurfacePool::GetLayer(
    GrDirectContext* gr_context,
    const AndroidContext& android_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory) {
  std::lock_guard lock(mutex_);
  if (pending_java_destroy_ && use_new_surface_methods_) {
    DestroyJavaLayersLocked(jni_facade);
  }
  if (requested_frame_size_ != current_frame_size_) {
    if (use_new_surface_methods_) {
      // The overlay surface is persistent, so resize it in place. Nothing else
      // resizes the swapchain: |Surface::AcquireFrame| ignores the size it is
      // handed.
      for (const std::shared_ptr<OverlayLayer>& layer : layers_) {
        layer->android_surface->OnScreenSurfaceResize(requested_frame_size_);
      }
    } else {
      // Retire existing layers without calling into JNI here so |GetLayer|
      // stays safe off the platform thread. The embedder drains
      // |TakeRetiredLayerIds| and destroys them on the platform thread.
      for (const std::shared_ptr<OverlayLayer>& layer : layers_) {
        retired_layer_ids_.push_back(layer->id);
      }
      layers_.clear();
      available_layer_index_ = 0;
    }
  }
  intptr_t gr_context_key = reinterpret_cast<intptr_t>(gr_context);
  // Allocate a new surface if there isn't one available.
  if (available_layer_index_ >= layers_.size()) {
    if (!AddLayerLocked(gr_context, android_context, jni_facade,
                        surface_factory, gr_context_key)) {
      return nullptr;
    }
  }

  std::shared_ptr<OverlayLayer> layer = layers_[available_layer_index_];
  // Since the surfaces are recycled, it's possible that the GrContext is
  // different.
  if (gr_context_key != layer->gr_context_key) {
    // The overlay already exists, but the GrContext was changed so we need to
    // recreate the rendering surface with the new GrContext.
    std::unique_ptr<Surface> surface =
        layer->android_surface->CreateGPUSurface(gr_context);
    if (!surface) {
      if (!use_new_surface_methods_) {
        retired_layer_ids_.push_back(layer->id);
      }
      layers_.erase(layers_.begin() + available_layer_index_);
      FML_LOG(ERROR) << "Could not recreate GPU surface for overlay layer "
                     << layer->id << ".";
      return nullptr;
    }
    layer->gr_context_key = gr_context_key;
    layer->surface = std::move(surface);
  }
  available_layer_index_++;
  current_frame_size_ = requested_frame_size_;
  return layer;
}

bool SurfacePool::AddLayerLocked(
    GrDirectContext* gr_context,
    const AndroidContext& android_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
    intptr_t gr_context_key) {
  std::unique_ptr<AndroidSurface> android_surface =
      surface_factory->CreateSurface();
  if (!android_surface || !android_surface->IsValid()) {
    FML_LOG(ERROR)
        << "Could not create an OpenGL, Vulkan or Software surface to set up "
           "rendering.";
    return false;
  }

  std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata> java_metadata =
      use_new_surface_methods_
          ? jni_facade->createOverlaySurface2()
          : jni_facade->FlutterViewCreateOverlaySurface(
                requested_frame_size_.width, requested_frame_size_.height);

  if (!java_metadata) {
    FML_LOG(ERROR) << "Could not create Java overlay surface for frame size "
                   << requested_frame_size_.width << "x"
                   << requested_frame_size_.height << ".";
    return false;
  }
  if (!java_metadata->window || (!java_metadata->window->IsValid() &&
                                 !java_metadata->window->IsFakeWindow())) {
    if (!use_new_surface_methods_) {
      retired_layer_ids_.push_back(java_metadata->id);
    }
    FML_LOG(ERROR) << "Java overlay surface " << java_metadata->id
                   << " returned an invalid native window for frame size "
                   << requested_frame_size_.width << "x"
                   << requested_frame_size_.height << ".";
    return false;
  }
  android_surface->SetupImpellerSurface();
  if (!android_surface->SetNativeWindow(java_metadata->window, jni_facade)) {
    if (!use_new_surface_methods_) {
      retired_layer_ids_.push_back(java_metadata->id);
    }
    FML_LOG(ERROR) << "Could not bind native window for overlay layer "
                   << java_metadata->id << ".";
    return false;
  }

  std::unique_ptr<Surface> surface =
      android_surface->CreateGPUSurface(gr_context);
  if (!surface) {
    if (!use_new_surface_methods_) {
      retired_layer_ids_.push_back(java_metadata->id);
    }
    FML_LOG(ERROR) << "Could not create GPU surface for overlay layer "
                   << java_metadata->id << ".";
    return false;
  }

  std::shared_ptr<OverlayLayer> layer =
      std::make_shared<OverlayLayer>(java_metadata->id,           //
                                     std::move(android_surface),  //
                                     std::move(surface)           //
      );
  layer->gr_context_key = gr_context_key;
  layers_.push_back(layer);
  return true;
}

void SurfacePool::RecycleLayers() {
  std::lock_guard lock(mutex_);
  available_layer_index_ = 0;
}

bool SurfacePool::HasLayers() {
  std::lock_guard lock(mutex_);
  return !layers_.empty();
}

void SurfacePool::DestroyLayers(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  std::lock_guard lock(mutex_);
  DestroyLayersLocked(jni_facade);
}

void SurfacePool::DestroyPendingLayers(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  std::lock_guard lock(mutex_);
  if (use_new_surface_methods_) {
    if (!pending_java_destroy_) {
      return;
    }
    DestroyJavaLayersLocked(jni_facade);
    return;
  }
  if (retired_layer_ids_.empty()) {
    return;
  }
  std::vector<int32_t> retired_ids;
  retired_ids.swap(retired_layer_ids_);
  jni_facade->FlutterViewDestroyOverlaySurfacesByIds(retired_ids);
}

std::vector<std::shared_ptr<OverlayLayer>> SurfacePool::TakeLayers() {
  std::lock_guard lock(mutex_);
  std::vector<std::shared_ptr<OverlayLayer>> layers;
  layers.swap(layers_);
  available_layer_index_ = 0;
  if (!use_new_surface_methods_) {
    for (const std::shared_ptr<OverlayLayer>& layer : layers) {
      retired_layer_ids_.push_back(layer->id);
    }
  } else if (!layers.empty()) {
    pending_java_destroy_ = true;
  }
  return layers;
}

std::vector<int32_t> SurfacePool::TakeRetiredLayerIds() {
  std::lock_guard lock(mutex_);
  std::vector<int32_t> retired_ids;
  retired_ids.swap(retired_layer_ids_);
  return retired_ids;
}

bool SurfacePool::HasPendingDestroy() {
  std::lock_guard lock(mutex_);
  return !retired_layer_ids_.empty() || pending_java_destroy_;
}

void SurfacePool::DestroyLayersLocked(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  if (layers_.empty() && retired_layer_ids_.empty() && !pending_java_destroy_) {
    return;
  }
  retired_layer_ids_.clear();
  DestroyJavaLayersLocked(jni_facade);
  layers_.clear();
  available_layer_index_ = 0;
}

void SurfacePool::DestroyJavaLayersLocked(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  pending_java_destroy_ = false;
  if (use_new_surface_methods_) {
    jni_facade->destroyOverlaySurface2();
  } else {
    jni_facade->FlutterViewDestroyOverlaySurfaces();
  }
}

std::vector<std::shared_ptr<OverlayLayer>> SurfacePool::GetUnusedLayers() {
  std::lock_guard lock(mutex_);
  std::vector<std::shared_ptr<OverlayLayer>> results;
  for (size_t i = available_layer_index_; i < layers_.size(); i++) {
    results.push_back(layers_[i]);
  }
  return results;
}

void SurfacePool::SetFrameSize(DlISize frame_size) {
  std::lock_guard lock(mutex_);
  requested_frame_size_ = frame_size;
}

void SurfacePool::ResetLayers() {
  available_layer_index_ = 0;
}

void SurfacePool::TrimLayers() {
  std::lock_guard lock(mutex_);
  layers_.erase(layers_.begin() + available_layer_index_, layers_.end());
  available_layer_index_ = 0;
}
}  // namespace flutter
