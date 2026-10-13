// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_

#include <memory>
#include <mutex>
#include <utility>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/shell/platform/embedder/android/context/android_context.h"
#include "flutter/shell/platform/embedder/android/surface/android_native_window.h"
#include "flutter/shell/platform/embedder/android/surface/android_surface.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Platform callbacks used by `AndroidExternalViewEmbedder`,
/// `AndroidExternalViewEmbedder2`, and `SurfacePool` to manage overlay
/// surfaces and position Android platform views.
///
class AndroidExternalViewEmbedderDelegate {
 public:
  //----------------------------------------------------------------------------
  /// The metadata for an overlay surface created by the platform, converted
  /// into an |OverlayLayer| by |SurfacePool|.
  ///
  struct OverlayMetadata {
    OverlayMetadata(int id, fml::RefPtr<AndroidNativeWindow> window)
        : id(id), window(std::move(window)) {}

    ~OverlayMetadata() = default;

    // A unique id to identify the overlay when it gets recycled.
    const int id;

    // Holds a reference to the native window (`ANativeWindow`).
    const fml::RefPtr<AndroidNativeWindow> window;
  };

  virtual ~AndroidExternalViewEmbedderDelegate() = default;

  virtual void FlutterViewOnDisplayPlatformView(
      int view_id,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      MutatorsStack mutators_stack) = 0;

  virtual void FlutterViewDisplayOverlaySurface(int surface_id,
                                                int x,
                                                int y,
                                                int width,
                                                int height) = 0;

  virtual void FlutterViewBeginFrame() = 0;

  virtual void FlutterViewEndFrame() = 0;

  virtual std::unique_ptr<OverlayMetadata>
  FlutterViewCreateOverlaySurface() = 0;

  virtual void FlutterViewDestroyOverlaySurfaces() = 0;

  virtual void swapTransaction() = 0;

  virtual std::unique_ptr<OverlayMetadata> createOverlaySurface2() = 0;

  virtual void destroyOverlaySurface2() = 0;

  virtual void onEndFrame2() = 0;

  virtual void onDisplayPlatformView2(int32_t view_id,
                                      int32_t x,
                                      int32_t y,
                                      int32_t width,
                                      int32_t height,
                                      int32_t viewWidth,
                                      int32_t viewHeight,
                                      MutatorsStack mutators_stack) = 0;

  virtual void hidePlatformView2(int32_t view_id) = 0;

  virtual void showOverlaySurface2() = 0;

  virtual void hideOverlaySurface2() = 0;

  virtual void MaybeResizeSurfaceView(int32_t width, int32_t height) const = 0;
};

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
  intptr_t gr_context_key;
};

class SurfacePool {
 public:
  explicit SurfacePool(bool use_new_surface_methods);

  ~SurfacePool();

  // Gets a layer from the pool if available, or allocates a new one.
  // Finally, it marks the layer as used. That is, it increments
  // `available_layer_index_`.
  std::shared_ptr<OverlayLayer> GetLayer(
      GrDirectContext* gr_context,
      const AndroidContext& android_context,
      const std::shared_ptr<AndroidExternalViewEmbedderDelegate>& jni_facade,
      const std::shared_ptr<AndroidSurfaceFactory>& surface_factory);

  // Gets the layers in the pool that aren't currently used.
  // This method doesn't mark the layers as unused.
  std::vector<std::shared_ptr<OverlayLayer>> GetUnusedLayers();

  // Marks the layers in the pool as available for reuse.
  void RecycleLayers();

  // Destroys all the layers in the pool.
  void DestroyLayers(
      const std::shared_ptr<AndroidExternalViewEmbedderDelegate>& jni_facade);

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

  void DestroyLayersLocked(
      const std::shared_ptr<AndroidExternalViewEmbedderDelegate>& jni_facade);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_POOL_H_
