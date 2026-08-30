// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Composition strategy for Android platform views.
enum class PlatformViewCompositionType : uint32_t {
  /// @brief Texture Layer Hybrid Composition (TLHC) - renders into texture.
  kTextureLayer = 0,
  /// @brief Hybrid Composition (HC) - embeds native View into View hierarchy.
  kHybridComposition = 1,
  /// @brief Hybrid Composition++ (HC++) - SurfaceControl swapchain
  /// presentation.
  kHybridCompositionPlusPlus = 2,
};

/// @brief Creation arguments for a platform view.
struct PlatformViewCreationParams {
  int64_t view_id = 0;
  std::string view_type;
  double width = 0.0;
  double height = 0.0;
  int32_t direction = 0;  // 0: LTR, 1: RTL
  std::vector<uint8_t> params;

  bool operator==(const PlatformViewCreationParams& other) const {
    return view_id == other.view_id && view_type == other.view_type &&
           width == other.width && height == other.height &&
           direction == other.direction && params == other.params;
  }

  bool operator!=(const PlatformViewCreationParams& other) const {
    return !(*this == other);
  }
};

/// @brief Resize parameters for an existing platform view.
struct PlatformViewResizeRequest {
  int64_t view_id = 0;
  double width = 0.0;
  double height = 0.0;

  bool operator==(const PlatformViewResizeRequest& other) const {
    return view_id == other.view_id && width == other.width &&
           height == other.height;
  }

  bool operator!=(const PlatformViewResizeRequest& other) const {
    return !(*this == other);
  }
};

/// @brief Individual pointer coordinate in a multi-touch event.
struct PlatformViewPointerCoords {
  int32_t pointer_id = 0;
  float x = 0.0f;
  float y = 0.0f;
  float size = 0.0f;
  float pressure = 1.0f;
  float orientation = 0.0f;
  int32_t tool_type = 0;

  bool operator==(const PlatformViewPointerCoords& other) const {
    return pointer_id == other.pointer_id && x == other.x && y == other.y &&
           size == other.size && pressure == other.pressure &&
           orientation == other.orientation && tool_type == other.tool_type;
  }

  bool operator!=(const PlatformViewPointerCoords& other) const {
    return !(*this == other);
  }
};

/// @brief Touch event dispatched to a platform view.
struct PlatformViewTouch {
  int64_t view_id = 0;
  int32_t motion_event_id = 0;
  int32_t action = 0;
  int32_t pointer_count = 0;
  std::vector<PlatformViewPointerCoords> pointers;
  int64_t down_time = 0;
  int64_t event_time = 0;
  int32_t source = 0;
  int32_t flags = 0;
  int32_t meta_state = 0;
  int32_t button_state = 0;
  float raw_x = 0.0f;
  float raw_y = 0.0f;

  bool operator==(const PlatformViewTouch& other) const {
    return view_id == other.view_id &&
           motion_event_id == other.motion_event_id && action == other.action &&
           pointer_count == other.pointer_count && pointers == other.pointers &&
           down_time == other.down_time && event_time == other.event_time &&
           source == other.source && flags == other.flags &&
           meta_state == other.meta_state &&
           button_state == other.button_state && raw_x == other.raw_x &&
           raw_y == other.raw_y;
  }

  bool operator!=(const PlatformViewTouch& other) const {
    return !(*this == other);
  }
};

/// @brief Geometry, display bounds, and mutator stack for a platform view.
struct PlatformViewGeometry {
  int64_t view_id = 0;
  int32_t x = 0;
  int32_t y = 0;
  int32_t width = 0;
  int32_t height = 0;
  int32_t view_width = 0;
  int32_t view_height = 0;
  AndroidMutatorsStack mutators_stack;

  bool operator==(const PlatformViewGeometry& other) const {
    return view_id == other.view_id && x == other.x && y == other.y &&
           width == other.width && height == other.height &&
           view_width == other.view_width && view_height == other.view_height &&
           mutators_stack == other.mutators_stack;
  }

  bool operator!=(const PlatformViewGeometry& other) const {
    return !(*this == other);
  }
};

/// @brief Overlay surface bounds and identifier for hybrid composition.
struct PlatformViewOverlay {
  int32_t surface_id = 0;
  int32_t x = 0;
  int32_t y = 0;
  int32_t width = 0;
  int32_t height = 0;

  bool operator==(const PlatformViewOverlay& other) const {
    return surface_id == other.surface_id && x == other.x && y == other.y &&
           width == other.width && height == other.height;
  }

  bool operator!=(const PlatformViewOverlay& other) const {
    return !(*this == other);
  }
};

/// @brief Abstract provider interface for platform view operations on Android.
class PlatformViewsProvider {
 public:
  virtual ~PlatformViewsProvider() = default;

  /// @brief Creates a platform view with specified composition type.
  /// @return For Texture Layer, returns texture ID. For HC/HC++, returns 0 on
  /// success. Returns -1 on failure.
  virtual int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type) = 0;

  /// @brief Disposes a platform view by ID.
  virtual bool DisposePlatformView(int64_t view_id) = 0;

  /// @brief Resizes a platform view.
  virtual bool ResizePlatformView(const PlatformViewResizeRequest& request) = 0;

  /// @brief Sets top-left offset for a platform view.
  virtual bool OffsetPlatformView(int64_t view_id, double top, double left) = 0;

  /// @brief Sets layout direction (0: LTR, 1: RTL) for a platform view.
  virtual bool SetDirection(int64_t view_id, int32_t direction) = 0;

  /// @brief Clears focus from a platform view.
  virtual bool ClearFocus(int64_t view_id) = 0;

  /// @brief Dispatches a touch event to a platform view.
  virtual bool DispatchTouchEvent(const PlatformViewTouch& touch) = 0;

  /// @brief Positions and displays a platform view with mutator stack.
  virtual bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) = 0;

  /// @brief Hides a platform view.
  virtual bool HidePlatformView(int64_t view_id) = 0;

  /// @brief Controls whether render surface is synchronized to Android view
  /// tree.
  virtual bool SynchronizeToNativeViewHierarchy(bool synchronize) = 0;

  /// @brief Signals start of a frame for hybrid composition.
  virtual bool OnBeginFrame() = 0;

  /// @brief Signals end of a frame for hybrid composition.
  virtual bool OnEndFrame() = 0;

  /// @brief Instantiates an overlay surface in hybrid composition.
  virtual std::optional<int32_t> CreateOverlaySurface() = 0;

  /// @brief Destroys all active overlay surfaces.
  virtual bool DestroyOverlaySurfaces() = 0;

  /// @brief Positions and sizes an overlay surface.
  virtual bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) = 0;

  /// @brief Shows an overlay surface.
  virtual bool ShowOverlaySurface(int32_t surface_id) = 0;

  /// @brief Hides an overlay surface.
  virtual bool HideOverlaySurface(int32_t surface_id) = 0;

  /// @brief Creates a SurfaceControl transaction for HC++.
  virtual bool CreateTransaction() = 0;

  /// @brief Swaps active SurfaceControl transactions for HC++.
  virtual bool SwapTransactions() = 0;

  /// @brief Applies pending SurfaceControl transactions for HC++.
  virtual bool ApplyTransactions() = 0;

  /// @brief Returns whether HC++ presentation is supported and enabled.
  virtual bool IsHcppEnabled() const = 0;

  /// @brief Sets whether HC++ presentation is supported and enabled.
  virtual void SetHcppEnabled(bool enabled) {}
};

/// @brief Default JNI/JVM backed PlatformViewsProvider.
class DefaultPlatformViewsProvider : public PlatformViewsProvider {
 public:
  explicit DefaultPlatformViewsProvider(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  ~DefaultPlatformViewsProvider() override;

  int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type) override;

  bool DisposePlatformView(int64_t view_id) override;
  bool ResizePlatformView(const PlatformViewResizeRequest& request) override;
  bool OffsetPlatformView(int64_t view_id, double top, double left) override;
  bool SetDirection(int64_t view_id, int32_t direction) override;
  bool ClearFocus(int64_t view_id) override;
  bool DispatchTouchEvent(const PlatformViewTouch& touch) override;
  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override;
  bool HidePlatformView(int64_t view_id) override;
  bool SynchronizeToNativeViewHierarchy(bool synchronize) override;
  bool OnBeginFrame() override;
  bool OnEndFrame() override;
  std::optional<int32_t> CreateOverlaySurface() override;
  bool DestroyOverlaySurfaces() override;
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) override;
  bool ShowOverlaySurface(int32_t surface_id) override;
  bool HideOverlaySurface(int32_t surface_id) override;
  bool CreateTransaction() override;
  bool SwapTransactions() override;
  bool ApplyTransactions() override;
  bool IsHcppEnabled() const override;

  void SetHcppEnabled(bool enabled) override;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  bool hcpp_enabled_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultPlatformViewsProvider);
};

/// @brief In-memory mock platform views provider for unit testing without JVM.
class InMemoryPlatformViewsProvider : public PlatformViewsProvider {
 public:
  InMemoryPlatformViewsProvider();
  ~InMemoryPlatformViewsProvider() override;

  int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type) override;

  bool DisposePlatformView(int64_t view_id) override;
  bool ResizePlatformView(const PlatformViewResizeRequest& request) override;
  bool OffsetPlatformView(int64_t view_id, double top, double left) override;
  bool SetDirection(int64_t view_id, int32_t direction) override;
  bool ClearFocus(int64_t view_id) override;
  bool DispatchTouchEvent(const PlatformViewTouch& touch) override;
  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override;
  bool HidePlatformView(int64_t view_id) override;
  bool SynchronizeToNativeViewHierarchy(bool synchronize) override;
  bool OnBeginFrame() override;
  bool OnEndFrame() override;
  std::optional<int32_t> CreateOverlaySurface() override;
  bool DestroyOverlaySurfaces() override;
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) override;
  bool ShowOverlaySurface(int32_t surface_id) override;
  bool HideOverlaySurface(int32_t surface_id) override;
  bool CreateTransaction() override;
  bool SwapTransactions() override;
  bool ApplyTransactions() override;
  bool IsHcppEnabled() const override;

  void SetHcppEnabled(bool enabled) override;
  void SetNextTextureId(int64_t texture_id);
  void Clear();

  size_t GetCreatedViewsCount() const;
  bool IsViewCreated(int64_t view_id) const;
  bool IsViewDisposed(int64_t view_id) const;
  std::optional<PlatformViewCreationParams> GetCreationParams(
      int64_t view_id) const;
  std::optional<PlatformViewCompositionType> GetCompositionType(
      int64_t view_id) const;
  std::optional<PlatformViewResizeRequest> GetLastResizeRequest() const;
  std::optional<std::pair<double, double>> GetOffsets(int64_t view_id) const;
  std::optional<int32_t> GetDirection(int64_t view_id) const;
  size_t GetFocusClearedCount(int64_t view_id) const;
  const std::vector<PlatformViewTouch>& GetDispatchedTouches() const;
  std::optional<PlatformViewGeometry> GetLastGeometry(int64_t view_id) const;
  bool IsViewHidden(int64_t view_id) const;
  bool GetSynchronizeToNativeViewHierarchy() const;
  bool IsInFrame() const;
  size_t GetOverlaySurfacesCount() const;
  const std::map<int32_t, PlatformViewOverlay>& GetDisplayedOverlays() const;
  bool IsOverlayVisible(int32_t surface_id) const;
  size_t GetTransactionCount() const;

 private:
  mutable std::mutex mutex_;
  bool hcpp_enabled_ = false;
  int64_t next_texture_id_ = 100;
  int32_t next_overlay_id_ = 1;
  bool in_frame_ = false;
  bool synchronize_to_native_view_hierarchy_ = true;
  size_t transaction_count_ = 0;

  std::map<int64_t, PlatformViewCreationParams> created_views_;
  std::map<int64_t, PlatformViewCompositionType> composition_types_;
  std::set<int64_t> disposed_views_;
  std::optional<PlatformViewResizeRequest> last_resize_request_;
  std::map<int64_t, std::pair<double, double>> offsets_;
  std::map<int64_t, int32_t> directions_;
  std::map<int64_t, size_t> clear_focus_counts_;
  std::vector<PlatformViewTouch> dispatched_touches_;
  std::map<int64_t, PlatformViewGeometry> geometries_;
  std::set<int64_t> hidden_views_;
  std::set<int32_t> overlay_surfaces_;
  std::map<int32_t, PlatformViewOverlay> displayed_overlays_;
  std::set<int32_t> visible_overlays_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryPlatformViewsProvider);
};

/// @brief Decoupled coordinator for Android platform views in the Embedder
/// C-API.
///
/// Encapsulates platform view creation, lifecycle, mutator translation, touch
/// dispatch, and overlay presentation, strictly isolated behind C-ABI
/// primitives and Perfetto tracing.
class AndroidPlatformViewsController {
 public:
  explicit AndroidPlatformViewsController(
      std::shared_ptr<PlatformViewsProvider> provider = nullptr);
  ~AndroidPlatformViewsController();

  int64_t CreatePlatformView(const PlatformViewCreationParams& params,
                             PlatformViewCompositionType composition_type);

  bool DisposePlatformView(int64_t view_id);
  bool ResizePlatformView(int64_t view_id, double width, double height);
  bool OffsetPlatformView(int64_t view_id, double top, double left);
  bool SetDirection(int64_t view_id, int32_t direction);
  bool ClearFocus(int64_t view_id);
  bool DispatchTouchEvent(const PlatformViewTouch& touch);

  bool OnDisplayPlatformView(int64_t view_id,
                             int32_t x,
                             int32_t y,
                             int32_t width,
                             int32_t height,
                             int32_t view_width,
                             int32_t view_height,
                             const AndroidMutatorsStack& mutators_stack);

  bool OnDisplayPlatformView(const FlutterPlatformView& platform_view,
                             int32_t x,
                             int32_t y,
                             int32_t width,
                             int32_t height,
                             int32_t view_width,
                             int32_t view_height);

  bool HidePlatformView(int64_t view_id);

  bool PushPlatformViewMutators(int64_t view_id,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                const AndroidMutatorsStack& mutators_stack);

  bool PushPlatformViewMutators(const FlutterPlatformView& platform_view,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height);

  bool SynchronizeToNativeViewHierarchy(bool synchronize);
  bool OnBeginFrame();
  bool OnEndFrame();
  std::optional<int32_t> CreateOverlaySurface();
  bool DestroyOverlaySurfaces();
  bool OnDisplayOverlaySurface(int32_t surface_id,
                               int32_t x,
                               int32_t y,
                               int32_t width,
                               int32_t height);
  bool ShowOverlaySurface(int32_t surface_id);
  bool HideOverlaySurface(int32_t surface_id);
  bool CreateTransaction();
  bool SwapTransactions();
  bool ApplyTransactions();
  bool IsHcppEnabled() const;

  size_t GetActiveViewsCount() const;
  bool HasPlatformView(int64_t view_id) const;
  std::optional<PlatformViewGeometry> GetPlatformViewGeometry(
      int64_t view_id) const;
  std::optional<PlatformViewCompositionType> GetCompositionType(
      int64_t view_id) const;

  std::shared_ptr<PlatformViewsProvider> GetProvider() const;
  void SetProvider(std::shared_ptr<PlatformViewsProvider> provider);

 private:
  std::shared_ptr<PlatformViewsProvider> provider_;
  mutable std::mutex mutex_;
  std::map<int64_t, PlatformViewGeometry> active_geometries_;
  std::map<int64_t, PlatformViewCompositionType> active_composition_types_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidPlatformViewsController);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
