// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_IMAGE_LAYER_POOL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_IMAGE_LAYER_POOL_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <utility>
#include <vector>

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

class GrDirectContext;

namespace flutter {

//------------------------------------------------------------------------------
/// Shared ownership handle around a move-only |HybridJavaGlobalRef| referencing
/// a Java `HybridImageReader`.
///
/// Both |ImageLayerPool| on the raster thread and any in-flight
/// |AcquiredHybridImage| inside a |FramePacket| hold a
/// `std::shared_ptr<HybridReaderHandle>`. When the pool retires a layer AND
/// every |FramePacket| referencing that reader has either handed its `Image` to
/// Java (which retains its own GC reference inside `releaseCallback`) or
/// released it via |ReleaseImage|, `~HybridReaderHandle()` invokes
/// `RetireHybridImageReader` and deletes the JNI global reference.
///
class HybridReaderHandle final {
 public:
  HybridReaderHandle(HybridJavaGlobalRef reader,
                     std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  ~HybridReaderHandle();

  HybridReaderHandle(const HybridReaderHandle&) = delete;
  HybridReaderHandle& operator=(const HybridReaderHandle&) = delete;
  HybridReaderHandle(HybridReaderHandle&&) = delete;
  HybridReaderHandle& operator=(HybridReaderHandle&&) = delete;

  const HybridJavaGlobalRef& reader() const noexcept { return reader_; }

  void ReleaseImage(HybridJavaGlobalRef image) const;

 private:
  HybridJavaGlobalRef reader_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
};

//------------------------------------------------------------------------------
/// A raster-thread-owned `HybridImageReader` rendering target (either the
/// Hybrid Composition background layer or an indexed overlay layer).
///
/// Member declaration order is load-bearing: C++ destroys members in reverse
/// declaration order, so `surface` (EGLSurface / VkSwapchainKHR) and
/// `android_surface` disconnect from `window` (`ANativeWindow`) BEFORE
/// `reader_handle` retires the underlying `HybridImageReader`.
///
struct ImageLayer {
  // Sentinel ID distinguishing the Hybrid Composition background layer from
  // non-negative sequential overlay layer IDs (`0..K-1`).
  static constexpr int kBackgroundLayerId = -1;

  ImageLayer(int id,
             DlISize size,
             intptr_t gr_context_key,
             std::shared_ptr<HybridReaderHandle> reader_handle,
             fml::RefPtr<AndroidNativeWindow> window,
             std::unique_ptr<AndroidSurface> android_surface,
             std::unique_ptr<Surface> surface);

  ~ImageLayer();

  ImageLayer(const ImageLayer&) = delete;
  ImageLayer& operator=(const ImageLayer&) = delete;
  ImageLayer(ImageLayer&&) = delete;
  ImageLayer& operator=(ImageLayer&&) = delete;

  int id = kBackgroundLayerId;
  DlISize size;
  intptr_t gr_context_key = 0;
  std::shared_ptr<HybridReaderHandle> reader_handle;
  fml::RefPtr<AndroidNativeWindow> window;
  std::unique_ptr<AndroidSurface> android_surface;
  std::unique_ptr<Surface> surface;
};

//------------------------------------------------------------------------------
/// Raster-thread-only pool of |ImageLayer| targets for Frame-Packet Hybrid
/// Composition.
///
/// Threading: Constructed, mutated, and destroyed exclusively on the raster
/// thread (`I4`), with zero platform-thread waits (`I1`).
///
class ImageLayerPool final {
 public:
  ImageLayerPool() = default;

  ~ImageLayerPool();

  ImageLayer* GetOrCreateBackgroundLayer(
      const DlISize& size,
      GrDirectContext* gr_context,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
      bool* out_destroyed_existing_layer = nullptr);

  ImageLayer* GetOrCreateOverlayLayer(
      size_t overlay_index,
      const DlISize& size,
      GrDirectContext* gr_context,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
      bool* out_destroyed_existing_layer = nullptr);

  // Destroys and retires overlay layers with index >= |used_overlay_count|.
  // Returns true if at least one existing GPU layer was destroyed (signaling
  // the caller to re-bind the root GL render context per Invariant I4).
  bool RecycleAndTrimUnusedOverlays(size_t used_overlay_count);

  // Destroys and retires only the background layer, returning true if an
  // existing background layer was destroyed.
  bool DestroyBackgroundLayer();

  // Destroys and retires both the background layer and all overlay layers,
  // returning true if at least one layer was destroyed.
  bool DestroyAllLayers();

  bool HasLayers() const noexcept {
    return background_layer_ != nullptr || !overlay_layers_.empty();
  }

  size_t OverlayLayerCount() const noexcept { return overlay_layers_.size(); }

  bool HasBackgroundLayer() const noexcept {
    return background_layer_ != nullptr;
  }

 private:
  static std::unique_ptr<ImageLayer> CreateLayer(
      int id,
      const DlISize& size,
      GrDirectContext* gr_context,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory);

  static bool EnsureLayerMatches(
      std::unique_ptr<ImageLayer>& slot,
      int id,
      const DlISize& size,
      GrDirectContext* gr_context,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory,
      bool* out_destroyed_existing_layer);

  std::unique_ptr<ImageLayer> background_layer_;
  std::vector<std::unique_ptr<ImageLayer>> overlay_layers_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageLayerPool);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_IMAGE_LAYER_POOL_H_
