// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_COMPOSITOR_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_COMPOSITOR_H_

#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_surface_manager.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

/// @brief Delegate interface for receiving platform view presentation updates
///        during frame composition.
class AndroidCompositorPlatformViewDelegate {
 public:
  virtual ~AndroidCompositorPlatformViewDelegate() = default;

  /// Invoked when beginning frame presentation.
  virtual void OnBeginFrame() {}

  /// Invoked when a platform view layer is encountered in the frame composition
  /// stack.
  virtual void OnPlatformViewPresented(
      int64_t view_id,
      const FlutterPoint& offset,
      const FlutterSize& size,
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations) = 0;

  /// Invoked after all layers in a frame have been presented.
  virtual void OnFramePresented() = 0;
};

/// @brief Implements the Flutter Embedder C-API compositor interface for
/// Android,
///        handling backing store lifecycle, layer presentation (Software,
///        OpenGL, Vulkan), platform view composition, and ANR-safe concurrent
///        surface detachment.
class AndroidCompositor {
 public:
  explicit AndroidCompositor(
      std::shared_ptr<AndroidSurfaceManager> surface_manager,
      std::shared_ptr<AndroidCompositorPlatformViewDelegate>
          platform_view_delegate = nullptr);
  virtual ~AndroidCompositor();

  /// Returns the underlying surface manager.
  std::shared_ptr<AndroidSurfaceManager> GetSurfaceManager() const {
    return surface_manager_;
  }

  /// Sets or updates the platform view delegate.
  void SetPlatformViewDelegate(
      std::shared_ptr<AndroidCompositorPlatformViewDelegate> delegate);

  /// Creates a backing store matching the render target configuration.
  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  /// Collects/recycles a previously created backing store.
  bool CollectBackingStore(const FlutterBackingStore* renderer);

  /// Presents the composited layers to the display/native window.
  /// ANR-safe: Non-blocking and resilient to concurrent surface detachment.
  bool PresentLayers(const FlutterLayer** layers, size_t layers_count);

  /// Presents the composited layers for a target view.
  bool PresentView(const FlutterPresentViewInfo* present_info);

  /// Populates the FlutterCompositor C struct for engine configuration.
  void PopulateCompositorConfig(FlutterCompositor* compositor_out);

  // ---------------------------------------------------------------------------
  // Inspection & Metrics (for Unit Testing)
  // ---------------------------------------------------------------------------
  size_t GetPresentedFrameCount() const;
  size_t GetLastPresentedLayersCount() const;
  size_t GetLastPresentedPlatformViewsCount() const;

 private:
  const std::shared_ptr<AndroidSurfaceManager> surface_manager_;
  std::shared_ptr<AndroidCompositorPlatformViewDelegate>
      platform_view_delegate_;

  mutable std::mutex present_mutex_;
  size_t presented_frame_count_ = 0;
  size_t last_presented_layers_count_ = 0;
  size_t last_presented_platform_views_count_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidCompositor);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_COMPOSITOR_H_
