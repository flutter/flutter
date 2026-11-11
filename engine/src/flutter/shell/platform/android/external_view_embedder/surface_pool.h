// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_

#include <mutex>

#include "flutter/flow/surface.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

//------------------------------------------------------------------------------
/// An Overlay layer represents an `android.view.View` in the C side.
///
/// The `id` is used to uniquely identify the layer and recycle it between
/// frames.
///
struct OverlayLayer {
  OverlayLayer(int id,
               std::unique_ptr<AndroidSurface> android_surface,
               std::unique_ptr<Surface> surface);

  ~OverlayLayer();

  // A unique id to identify the overlay when it gets recycled.
  const int id;

  // A GPU surface.
  const std::unique_ptr<AndroidSurface> android_surface;

  // A GPU surface. This may change when the overlay is recycled.
  std::unique_ptr<Surface> surface;

  // The `GrContext` that is currently used by the overlay surfaces.
  // We track this to know when the GrContext for the Flutter app has changed
  // so we can update the overlay with the new context.
  //
  // This may change when the overlay is recycled.
  intptr_t gr_context_key = 0;
};

class SurfacePool {
 public:
  explicit SurfacePool(bool use_new_surface_methods);

  ~SurfacePool();

  // Gets a layer from the pool if available, or allocates a new one. If
  // |TakeLayers| left stale Java overlay surfaces pending destruction, flushes
  // them first via `jni_facade` (requiring the platform thread whenever
  // |HasPendingDestroy| is true or a new/resized HC layer must be created).
  // Finally, it marks the layer as used. That is, it increments
  // `available_layer_index_`.
  std::shared_ptr<OverlayLayer> GetLayer(
      GrDirectContext* gr_context,
      const AndroidContext& android_context,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory);

  // Gets the layers in the pool that aren't currently used.
  // This method doesn't mark the layers as unused.
  std::vector<std::shared_ptr<OverlayLayer>> GetUnusedLayers();

  // Marks the layers in the pool as available for reuse.
  void RecycleLayers();

  // Destroys all the layers in the pool and any taken layers still awaiting
  // destruction on the platform thread. Must be called on the platform thread
  // when |HasLayers| or |HasPendingDestroy| is true.
  void DestroyLayers(const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  // Destroys any Java overlay surfaces whose layers were removed by
  // |TakeLayers| if they have not already been destroyed. Must be called on the
  // platform thread.
  void DestroyPendingLayers(
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  // Removes all the layers from the pool and returns them without calling into
  // Java, marking their Java overlay surfaces as pending destruction on the
  // platform thread (via |DestroyPendingLayers|, |GetLayer|, or
  // |DestroyLayers|).
  std::vector<std::shared_ptr<OverlayLayer>> TakeLayers();

  // Returns true if |TakeLayers| removed layers whose Java overlay surfaces
  // have not yet been destroyed on the platform thread.
  bool HasPendingDestroy();

  // Sets the frame size used by the layers in the pool.
  // If the current layers in the pool have a different frame size,
  // then they are deallocated as soon as |GetLayer| is called.
  void SetFrameSize(DlISize frame_size);

  // Returns true if the current pool has layers in use.
  bool HasLayers();

  // Reset the layer index but do not release any layers.
  void ResetLayers();

  void TrimLayers();

 private:
  // The index of the entry in the layers_ vector that determines the beginning
  // of the unused layers. For example, consider the following vector:
  //  _____
  //  | 0 |
  //  |---|
  //  | 1 | <-- `available_layer_index_`
  //  |---|
  //  | 2 |
  //  |---|
  //
  //  This indicates that entries starting from 1 can be reused meanwhile the
  //  entry at position 0 cannot be reused.
  size_t available_layer_index_ = 0;

  // The layers in the pool.
  std::vector<std::shared_ptr<OverlayLayer>> layers_;

  // The frame size of the layers in the pool.
  DlISize current_frame_size_;

  // The frame size to be used by future layers.
  DlISize requested_frame_size_;

  // Used to guard public methods.
  std::mutex mutex_;
  bool use_new_surface_methods_ = false;
  bool pending_java_destroy_ = false;

  void DestroyLayersLocked(
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);
  void DestroyJavaLayersLocked(
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_
