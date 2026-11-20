// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/image_layer_pool.h"

#include "flutter/fml/logging.h"

namespace flutter {

HybridReaderHandle::HybridReaderHandle(
    HybridJavaGlobalRef reader,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : reader_(std::move(reader)), jni_facade_(std::move(jni_facade)) {}

HybridReaderHandle::~HybridReaderHandle() {
  if (!reader_) {
    return;
  }
  if (jni_facade_) {
    jni_facade_->RetireHybridImageReader(std::move(reader_));
  } else {
    reader_.Reset();
  }
}

void HybridReaderHandle::ReleaseImage(HybridJavaGlobalRef image) const {
  if (!image) {
    return;
  }
  if (jni_facade_) {
    jni_facade_->ReleaseHybridImage(reader_, std::move(image));
  } else {
    image.Reset();
  }
}

ImageLayer::ImageLayer(int id,
                       DlISize size,
                       intptr_t gr_context_key,
                       std::shared_ptr<HybridReaderHandle> reader_handle,
                       fml::RefPtr<AndroidNativeWindow> window,
                       std::unique_ptr<AndroidSurface> android_surface,
                       std::unique_ptr<Surface> surface)
    : id(id),
      size(size),
      gr_context_key(gr_context_key),
      reader_handle(std::move(reader_handle)),
      window(std::move(window)),
      android_surface(std::move(android_surface)),
      surface(std::move(surface)) {}

ImageLayer::~ImageLayer() = default;

ImageLayerPool::~ImageLayerPool() {
  DestroyAllLayers();
}

std::unique_ptr<ImageLayer> ImageLayerPool::CreateLayer(
    int id,
    const DlISize& size,
    GrDirectContext* gr_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory) {
  if (size.width <= 0 || size.height <= 0 || !jni_facade || !surface_factory) {
    return nullptr;
  }

  std::unique_ptr<AndroidSurface> android_surface =
      surface_factory->CreateSurface();
  if (!android_surface || !android_surface->IsValid()) {
    FML_LOG(ERROR) << "ImageLayerPool could not create AndroidSurface for id "
                   << id << ".";
    return nullptr;
  }

  std::unique_ptr<PlatformViewAndroidJNI::HybridImageReaderMetadata> metadata =
      jni_facade->CreateHybridImageReader(size.width, size.height);
  if (!metadata || !metadata->reader) {
    FML_LOG(ERROR)
        << "ImageLayerPool could not create HybridImageReader for id " << id
        << ".";
    return nullptr;
  }

  auto reader_handle = std::make_shared<HybridReaderHandle>(
      std::move(metadata->reader), jni_facade);
  if (!metadata->window) {
    FML_LOG(ERROR)
        << "ImageLayerPool received null AndroidNativeWindow for id " << id
        << ".";
    return nullptr;
  }

  // Initialize dynamic Impeller surface selection before binding the native
  // window so swapchain / EGL validation runs eagerly.
  android_surface->SetupImpellerSurface();
  if (!android_surface->SetNativeWindow(metadata->window, jni_facade)) {
    FML_LOG(ERROR) << "ImageLayerPool could not bind native window for id "
                   << id << ".";
    return nullptr;
  }

  std::unique_ptr<Surface> gpu_surface =
      android_surface->CreateGPUSurface(gr_context);
  if (!gpu_surface || !gpu_surface->IsValid()) {
    FML_LOG(ERROR) << "ImageLayerPool could not create GPU surface for id "
                   << id << ".";
    return nullptr;
  }

  const intptr_t gr_context_key = reinterpret_cast<intptr_t>(gr_context);
  return std::make_unique<ImageLayer>(
      id, size, gr_context_key, std::move(reader_handle),
      std::move(metadata->window), std::move(android_surface),
      std::move(gpu_surface));
}

bool ImageLayerPool::EnsureLayerMatches(
    std::unique_ptr<ImageLayer>& slot,
    int id,
    const DlISize& size,
    GrDirectContext* gr_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
    bool* out_destroyed_existing_layer) {
  bool destroyed_existing = false;
  if (size.width <= 0 || size.height <= 0) {
    if (slot) {
      slot.reset();
      destroyed_existing = true;
    }
    if (out_destroyed_existing_layer != nullptr) {
      *out_destroyed_existing_layer = destroyed_existing;
    }
    return false;
  }

  if (slot && slot->size != size) {
    slot.reset();
    destroyed_existing = true;
  }

  const intptr_t gr_context_key = reinterpret_cast<intptr_t>(gr_context);
  if (slot && slot->gr_context_key != gr_context_key) {
    std::unique_ptr<Surface> replacement_surface =
        slot->android_surface->CreateGPUSurface(gr_context);
    if (!replacement_surface || !replacement_surface->IsValid()) {
      FML_LOG(ERROR) << "ImageLayerPool could not recreate GPU surface for id "
                     << id << ".";
      slot.reset();
      destroyed_existing = true;
      if (out_destroyed_existing_layer != nullptr) {
        *out_destroyed_existing_layer = destroyed_existing;
      }
      return false;
    }
    // Replacing `slot->surface` destroys the previous GPU surface, which may
    // clear the current GL context on Skia GLES.
    slot->surface = std::move(replacement_surface);
    slot->gr_context_key = gr_context_key;
    destroyed_existing = true;
  }

  if (!slot) {
    slot = CreateLayer(id, size, gr_context, jni_facade, surface_factory);
  }

  if (out_destroyed_existing_layer != nullptr) {
    *out_destroyed_existing_layer = destroyed_existing;
  }
  return slot != nullptr;
}

ImageLayer* ImageLayerPool::GetOrCreateBackgroundLayer(
    const DlISize& size,
    GrDirectContext* gr_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
    bool* out_destroyed_existing_layer) {
  if (!EnsureLayerMatches(background_layer_, ImageLayer::kBackgroundLayerId,
                          size, gr_context, jni_facade, surface_factory,
                          out_destroyed_existing_layer)) {
    return nullptr;
  }
  return background_layer_.get();
}

ImageLayer* ImageLayerPool::GetOrCreateOverlayLayer(
    size_t overlay_index,
    const DlISize& size,
    GrDirectContext* gr_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
    bool* out_destroyed_existing_layer) {
  if (size.width <= 0 || size.height <= 0) {
    if (out_destroyed_existing_layer != nullptr) {
      *out_destroyed_existing_layer = false;
    }
    return nullptr;
  }
  if (overlay_index >= overlay_layers_.size()) {
    overlay_layers_.resize(overlay_index + 1);
  }
  if (!EnsureLayerMatches(overlay_layers_[overlay_index],
                          static_cast<int>(overlay_index), size, gr_context,
                          jni_facade, surface_factory,
                          out_destroyed_existing_layer)) {
    return nullptr;
  }
  return overlay_layers_[overlay_index].get();
}

bool ImageLayerPool::RecycleAndTrimUnusedOverlays(size_t used_overlay_count) {
  if (overlay_layers_.size() <= used_overlay_count) {
    return false;
  }
  bool destroyed_any = false;
  for (size_t i = used_overlay_count; i < overlay_layers_.size(); ++i) {
    if (overlay_layers_[i] != nullptr) {
      overlay_layers_[i].reset();
      destroyed_any = true;
    }
  }
  overlay_layers_.resize(used_overlay_count);
  return destroyed_any;
}

bool ImageLayerPool::DestroyBackgroundLayer() {
  if (!background_layer_) {
    return false;
  }
  background_layer_.reset();
  return true;
}

bool ImageLayerPool::DestroyAllLayers() {
  bool destroyed_any = DestroyBackgroundLayer();
  for (std::unique_ptr<ImageLayer>& layer : overlay_layers_) {
    if (layer != nullptr) {
      layer.reset();
      destroyed_any = true;
    }
  }
  overlay_layers_.clear();
  return destroyed_any;
}

}  // namespace flutter
