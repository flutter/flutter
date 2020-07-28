// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/surface_pool.h"

namespace flutter {

OverlayLayer::OverlayLayer(int id,
                           std::unique_ptr<AndroidSurface> android_surface,
                           std::unique_ptr<Surface> surface)
    : id(id),
      android_surface(std::move(android_surface)),
      surface(std::move(surface)){};

OverlayLayer::~OverlayLayer() = default;

SurfacePool::SurfacePool() = default;

SurfacePool::~SurfacePool() = default;

std::shared_ptr<OverlayLayer> SurfacePool::GetLayer(
    GrDirectContext* gr_context,
    std::shared_ptr<AndroidContext> android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const AndroidSurface::Factory& surface_factory) {
  intptr_t gr_context_key = reinterpret_cast<intptr_t>(gr_context);
  // Allocate a new surface if there isn't one available.
  if (available_layer_index_ >= layers_.size()) {
    std::unique_ptr<AndroidSurface> android_surface =
        surface_factory(android_context, jni_facade);

    FML_CHECK(android_surface && android_surface->IsValid())
        << "Could not create an OpenGL, Vulkan or Software surface to setup "
           "rendering.";

    std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata> java_metadata =
        jni_facade->FlutterViewCreateOverlaySurface();

    FML_CHECK(java_metadata->window);
    android_surface->SetNativeWindow(java_metadata->window);

    std::unique_ptr<Surface> surface =
        android_surface->CreateGPUSurface(gr_context);

    std::shared_ptr<OverlayLayer> layer =
        std::make_shared<OverlayLayer>(java_metadata->id,           //
                                       std::move(android_surface),  //
                                       std::move(surface)           //
        );
    layer->gr_context_key = gr_context_key;
    layers_.push_back(layer);
  }
  std::shared_ptr<OverlayLayer> layer = layers_[available_layer_index_];
  // Since the surfaces are recycled, it's possible that the GrContext is
  // different.
  if (gr_context_key != layer->gr_context_key) {
    layer->gr_context_key = gr_context_key;
    // The overlay already exists, but the GrContext was changed so we need to
    // recreate the rendering surface with the new GrContext.
    std::unique_ptr<Surface> surface =
        layer->android_surface->CreateGPUSurface(gr_context);
    layer->surface = std::move(surface);
  }
  available_layer_index_++;
  return layer;
}

void SurfacePool::RecycleLayers() {
  available_layer_index_ = 0;
}

void SurfacePool::DestroyLayers(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade) {
  if (layers_.size() > 0) {
    jni_facade->FlutterViewDestroyOverlaySurfaces();
  }
  layers_.clear();
  available_layer_index_ = 0;
}

std::vector<std::shared_ptr<OverlayLayer>> SurfacePool::GetUnusedLayers() {
  std::vector<std::shared_ptr<OverlayLayer>> results;
  for (size_t i = available_layer_index_; i < layers_.size(); i++) {
    results.push_back(layers_[i]);
  }
  return results;
}

}  // namespace flutter
