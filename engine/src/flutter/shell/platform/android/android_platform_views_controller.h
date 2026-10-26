// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

struct ANativeWindow;

namespace flutter {

/// Android API level 34 (Android 14 / UpsideDownCake), which introduced
/// `android.graphics.Path.conicTo` support for native conic path verbs.
inline constexpr int32_t kAndroidApiLevelPathConics = 34;

/// Default implicit `FlutterViewId` for the primary Flutter view.
inline constexpr FlutterViewId kPlatformViewsImplicitViewId = 0;

/// Default OpenGL framebuffer ID for the primary onscreen window surface.
inline constexpr uint32_t kDefaultOnscreenFramebufferId = 0;

/// Base OpenGL framebuffer ID assigned to off-screen overlay surfaces when no
/// custom render delegate overrides FBO allocation.
inline constexpr uint32_t kBaseOverlayFramebufferId = 1000;

/// Number of bytes per RGBA8888 pixel in software backing stores.
inline constexpr size_t kRgba8888BytesPerPixel = 4;

/**
 * @brief Composition mode for an Android Platform View.
 */
enum class PlatformViewCompositionType {
  kTextureLayer = 0,
  kHybridComposition = 1,
  kHybridCompositionWithSurfaceControl = 2,
};

/**
 * @brief Parameters for creating a new Android Platform View.
 */
struct PlatformViewCreationParams {
  int64_t view_id = 0;
  std::string view_type;
  double width = 0.0;
  double height = 0.0;
  int32_t direction = 0;
  int64_t texture_id = -1;
  std::vector<uint8_t> creation_params;
};

/**
 * @brief Parameters for resizing an Android Platform View.
 */
struct PlatformViewResizeRequest {
  int64_t view_id = 0;
  double width = 0.0;
  double height = 0.0;
};

/**
 * @brief Parameters for a touch event dispatched to an Android Platform View.
 */
struct PlatformViewTouch {
  int64_t view_id = 0;
  int64_t down_time = 0;
  int64_t event_time = 0;
  int32_t action = 0;
  int32_t pointer_count = 0;
  std::vector<int32_t> pointer_properties;
  std::vector<float> pointer_coords;
  int32_t meta_state = 0;
  int32_t button_state = 0;
  float x_precision = 0.0f;
  float y_precision = 0.0f;
  int32_t device_id = 0;
  int32_t edge_flags = 0;
  int32_t source = 0;
  int32_t flags = 0;
  int64_t motion_event_id = 0;
};

/**
 * @brief Geometry and mutators stack for displaying a Platform View in a frame.
 */
struct PlatformViewGeometry {
  int64_t view_id = 0;
  int32_t x = 0;
  int32_t y = 0;
  int32_t width = 0;
  int32_t height = 0;
  int32_t view_width = 0;
  int32_t view_height = 0;
  AndroidMutatorsStack mutators_stack;
};

/**
 * @brief Overlay surface geometry for Hybrid Composition.
 */
struct PlatformViewOverlay {
  int32_t surface_id = 0;
  int32_t x = 0;
  int32_t y = 0;
  int32_t width = 0;
  int32_t height = 0;
  ANativeWindow* window = nullptr;
};

/**
 * @brief Interface for platform view lifecycle and composition operations.
 */
class PlatformViewsProvider {
 public:
  virtual ~PlatformViewsProvider() = default;

  virtual int64_t CreatePlatformView(const PlatformViewCreationParams& params,
                                     PlatformViewCompositionType type) = 0;
  virtual bool DisposePlatformView(int64_t view_id) = 0;
  virtual bool ResizePlatformView(const PlatformViewResizeRequest& request,
                                  double* out_width,
                                  double* out_height) = 0;
  virtual bool OffsetPlatformView(int64_t view_id, double top, double left) = 0;
  virtual bool SetPlatformViewDirection(int64_t view_id, int32_t direction) = 0;
  virtual bool ClearPlatformViewFocus(int64_t view_id) = 0;
  virtual bool DispatchPlatformViewTouch(const PlatformViewTouch& touch) = 0;

  virtual bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) = 0;
  virtual bool HidePlatformView(int64_t view_id) = 0;
  virtual bool SynchronizeToNativeViewHierarchy(bool yes) = 0;
  virtual bool OnBeginFrame() = 0;
  virtual bool OnEndFrame() = 0;

  virtual std::optional<int32_t> CreateOverlaySurface() = 0;
  virtual bool DestroyOverlaySurfaces() = 0;
  virtual bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) = 0;
  virtual bool ShowOverlaySurface(int32_t surface_id) = 0;
  virtual bool HideOverlaySurface(int32_t surface_id) = 0;
  virtual ANativeWindow* GetOverlayWindow(int32_t surface_id) = 0;

  virtual bool CreateTransaction() = 0;
  virtual bool SwapTransactions() = 0;
  virtual bool ApplyTransactions() = 0;
  virtual bool SetHcppEnabled(bool enabled) = 0;
  virtual bool IsHcppEnabled() = 0;
  virtual void* GetSurfaceControl(int32_t surface_id) = 0;
};

/**
 * @brief Default implementation of `PlatformViewsProvider` that routes calls to
 * Java (`FlutterJNI`) through `JvmInvoker`.
 */
class DefaultPlatformViewsProvider final : public PlatformViewsProvider {
 public:
  explicit DefaultPlatformViewsProvider(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  explicit DefaultPlatformViewsProvider(JvmInvoker* raw_jvm_invoker);
  ~DefaultPlatformViewsProvider() override;

  void SetJvmInvoker(std::shared_ptr<JvmInvoker> jvm_invoker);
  void SetJvmInvoker(JvmInvoker* raw_jvm_invoker);

  int64_t CreatePlatformView(const PlatformViewCreationParams& params,
                             PlatformViewCompositionType type) override;
  bool DisposePlatformView(int64_t view_id) override;
  bool ResizePlatformView(const PlatformViewResizeRequest& request,
                          double* out_width,
                          double* out_height) override;
  bool OffsetPlatformView(int64_t view_id, double top, double left) override;
  bool SetPlatformViewDirection(int64_t view_id, int32_t direction) override;
  bool ClearPlatformViewFocus(int64_t view_id) override;
  bool DispatchPlatformViewTouch(const PlatformViewTouch& touch) override;

  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override;
  bool HidePlatformView(int64_t view_id) override;
  bool SynchronizeToNativeViewHierarchy(bool yes) override;
  bool OnBeginFrame() override;
  bool OnEndFrame() override;

  std::optional<int32_t> CreateOverlaySurface() override;
  bool DestroyOverlaySurfaces() override;
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) override;
  bool ShowOverlaySurface(int32_t surface_id) override;
  bool HideOverlaySurface(int32_t surface_id) override;
  ANativeWindow* GetOverlayWindow(int32_t surface_id) override;

  bool CreateTransaction() override;
  bool SwapTransactions() override;
  bool ApplyTransactions() override;
  bool SetHcppEnabled(bool enabled) override;
  bool IsHcppEnabled() override;
  void* GetSurfaceControl(int32_t surface_id) override;

 private:
  JvmInvoker* GetInvoker() const;

  mutable std::mutex mutex_;
  std::shared_ptr<JvmInvoker> shared_jvm_invoker_;
  JvmInvoker* raw_jvm_invoker_ = nullptr;
  std::unordered_map<int32_t, ANativeWindow*> overlay_windows_;
  int32_t next_fallback_surface_id_ = 1;
  bool hcpp_enabled_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultPlatformViewsProvider);
};

/**
 * @brief In-memory implementation of `PlatformViewsProvider` for deterministic
 * unit testing without an Android JVM.
 */
class InMemoryPlatformViewsProvider final : public PlatformViewsProvider {
 public:
  InMemoryPlatformViewsProvider();
  ~InMemoryPlatformViewsProvider() override;

  int64_t CreatePlatformView(const PlatformViewCreationParams& params,
                             PlatformViewCompositionType type) override;
  bool DisposePlatformView(int64_t view_id) override;
  bool ResizePlatformView(const PlatformViewResizeRequest& request,
                          double* out_width,
                          double* out_height) override;
  bool OffsetPlatformView(int64_t view_id, double top, double left) override;
  bool SetPlatformViewDirection(int64_t view_id, int32_t direction) override;
  bool ClearPlatformViewFocus(int64_t view_id) override;
  bool DispatchPlatformViewTouch(const PlatformViewTouch& touch) override;

  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) override;
  bool HidePlatformView(int64_t view_id) override;
  bool SynchronizeToNativeViewHierarchy(bool yes) override;
  bool OnBeginFrame() override;
  bool OnEndFrame() override;

  std::optional<int32_t> CreateOverlaySurface() override;
  bool DestroyOverlaySurfaces() override;
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) override;
  bool ShowOverlaySurface(int32_t surface_id) override;
  bool HideOverlaySurface(int32_t surface_id) override;
  ANativeWindow* GetOverlayWindow(int32_t surface_id) override;

  bool CreateTransaction() override;
  bool SwapTransactions() override;
  bool ApplyTransactions() override;
  bool SetHcppEnabled(bool enabled) override;
  bool IsHcppEnabled() override;
  void* GetSurfaceControl(int32_t surface_id) override;

  void SetOverlayWindowForTesting(int32_t surface_id, ANativeWindow* window);
  void SetSurfaceControlForTesting(int32_t surface_id, void* surface_control);
  void SetOnCreateOverlaySurfaceHook(std::function<void()> hook);

  bool IsViewCreated(int64_t view_id) const;
  std::optional<PlatformViewGeometry> GetLastGeometry(int64_t view_id) const;
  std::optional<PlatformViewOverlay> GetOverlay(int32_t surface_id) const;
  bool IsOverlayVisible(int32_t surface_id) const;
  size_t GetBeginFrameCount() const;
  size_t GetEndFrameCount() const;
  size_t GetSwapTransactionCount() const;
  size_t GetDisplayPlatformViewCount() const;
  size_t GetCreateOverlaySurfaceCount() const;
  std::vector<int64_t> GetHiddenPlatformViews() const;

 private:
  struct ViewRecord {
    PlatformViewCreationParams params;
    PlatformViewCompositionType type =
        PlatformViewCompositionType::kTextureLayer;
    double top = 0.0;
    double left = 0.0;
    bool focused = true;
    bool visible = true;
    PlatformViewTouch last_touch{};
  };

  mutable std::mutex mutex_;
  std::unordered_map<int64_t, ViewRecord> views_;
  std::unordered_map<int64_t, PlatformViewGeometry> geometries_;
  std::unordered_map<int32_t, PlatformViewOverlay> overlays_;
  std::unordered_map<int32_t, bool> overlay_visibility_;
  std::unordered_map<int32_t, ANativeWindow*> overlay_windows_;
  std::unordered_map<int32_t, void*> surface_controls_;
  std::vector<int64_t> hidden_views_;
  std::function<void()> on_create_overlay_surface_hook_;
  int64_t next_texture_id_ = 100;
  int32_t next_surface_id_ = 1;
  bool synchronized_ = false;
  bool in_frame_ = false;
  bool hcpp_enabled_ = false;
  size_t begin_frame_count_ = 0;
  size_t end_frame_count_ = 0;
  size_t transaction_count_ = 0;
  size_t swap_count_ = 0;
  size_t apply_count_ = 0;
  size_t display_platform_view_count_ = 0;
  size_t create_overlay_surface_count_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryPlatformViewsProvider);
};

/**
 * @brief Delegate interface invoked by `AndroidPlatformViewsController` during
 * `create_backing_store_callback` and `present_view_callback` to bind/resize
 * the on-screen `ANativeWindow*` swapchain/FBO (`is_root_layer == true`) and
 * off-screen overlay surfaces (`is_root_layer == false`).
 */
class AndroidCompositorRenderDelegate {
 public:
  virtual ~AndroidCompositorRenderDelegate() = default;

  virtual bool BindAndResizeOnscreenSurface(
      FlutterViewId view_id,
      ANativeWindow* onscreen_window,
      size_t width,
      size_t height,
      FlutterBackingStore* backing_store_out) = 0;

  virtual bool BindAndResizeOverlaySurface(
      FlutterViewId view_id,
      int32_t overlay_surface_id,
      ANativeWindow* overlay_window,
      size_t width,
      size_t height,
      FlutterBackingStore* backing_store_out) = 0;

  virtual bool PresentOnscreenSurface(
      FlutterViewId view_id,
      const FlutterBackingStore* backing_store) {
    (void)view_id;
    (void)backing_store;
    return true;
  }

  virtual bool PresentOverlaySurface(FlutterViewId view_id,
                                     int32_t overlay_surface_id,
                                     const FlutterBackingStore* backing_store) {
    (void)view_id;
    (void)overlay_surface_id;
    (void)backing_store;
    return true;
  }
};

/**
 * @brief Manages Android Platform Views and implements the `FlutterCompositor`
 * C-API callbacks (`create_backing_store_callback`,
 * `collect_backing_store_callback`, `present_view_callback`) for Hybrid
 * Composition (HC), Texture Layer Hybrid Composition (TLHC), and Hybrid
 * Composition++ (`SurfaceControl` / HCPP).
 */
class AndroidPlatformViewsController {
 public:
  using RenderDelegate = AndroidCompositorRenderDelegate;

  /**
   * @brief Value-captured root backing store layer state within a single
   * `FlutterViewId` frame.
   */
  struct CapturedRootLayer {
    bool present = false;
    FlutterViewId view_id = kPlatformViewsImplicitViewId;
    int32_t x = 0;
    int32_t y = 0;
    int32_t width = 0;
    int32_t height = 0;
    uint32_t framebuffer_id = kDefaultOnscreenFramebufferId;
    ANativeWindow* native_window = nullptr;
  };

  /**
   * @brief Value-captured off-screen overlay backing store layer state within
   * a single `FlutterViewId` frame.
   */
  struct CapturedOverlayLayer {
    size_t overlay_index = 0;
    int32_t surface_id = -1;
    int32_t x = 0;
    int32_t y = 0;
    int32_t width = 0;
    int32_t height = 0;
    uint32_t framebuffer_id = 0;
    ANativeWindow* native_window = nullptr;
  };

  /**
   * @brief Value-captured platform view layer and mutator stack within a
   * single `FlutterViewId` frame.
   */
  struct CapturedPlatformViewLayer {
    int64_t platform_view_id = 0;
    int32_t x = 0;
    int32_t y = 0;
    int32_t width = 0;
    int32_t height = 0;
    int32_t view_width = 0;
    int32_t view_height = 0;
    AndroidMutatorsStack mutators_stack;
    std::vector<AndroidMutatorRecord> mutator_records;
    SurfaceControlTransactionTransform surface_control_transform;
  };

  /**
   * @brief Immutable snapshot of all layers and mutators captured by value for
   * a specific `FlutterViewId` during `present_view_callback`.
   */
  struct ViewFrameSnapshot {
    FlutterViewId view_id = kPlatformViewsImplicitViewId;
    CapturedRootLayer root_layer;
    std::vector<CapturedOverlayLayer> overlay_layers;
    std::vector<CapturedPlatformViewLayer> platform_views;
  };

  AndroidPlatformViewsController();
  explicit AndroidPlatformViewsController(
      std::shared_ptr<PlatformViewsProvider> provider,
      fml::RefPtr<fml::TaskRunner> platform_task_runner = nullptr);
  explicit AndroidPlatformViewsController(
      JvmInvoker* jvm_invoker,
      fml::RefPtr<fml::TaskRunner> platform_task_runner = nullptr);
  explicit AndroidPlatformViewsController(
      const std::shared_ptr<JvmInvoker>& jvm_invoker,
      fml::RefPtr<fml::TaskRunner> platform_task_runner = nullptr);
  ~AndroidPlatformViewsController();

  void SetProvider(std::shared_ptr<PlatformViewsProvider> provider);
  std::shared_ptr<PlatformViewsProvider> GetProvider() const;

  void SetPlatformTaskRunner(fml::RefPtr<fml::TaskRunner> platform_task_runner);
  fml::RefPtr<fml::TaskRunner> GetPlatformTaskRunner() const;

  void SetRenderDelegate(
      std::shared_ptr<AndroidCompositorRenderDelegate> render_delegate);
  void SetRenderDelegate(AndroidCompositorRenderDelegate* raw_render_delegate);
  std::shared_ptr<AndroidCompositorRenderDelegate> GetRenderDelegate() const;

  void SetMergeRasterThreadOnPlatformViews(bool merge);
  bool GetMergeRasterThreadOnPlatformViews() const;

  /// Callback invoked on the platform thread after a frame that dispatched at
  /// least one platform view to Java has finished presenting (after
  /// `OnEndFrame`). Platform-view-only frames have no backing store, so the
  /// render delegate's `Present*Surface` hooks never fire for them; the owner
  /// uses this to raise `FlutterJNI.onFirstFrame()` (and must dedup it).
  using FramePresentedCallback = std::function<void(FlutterViewId view_id)>;
  void SetFramePresentedCallback(FramePresentedCallback callback);

  void ConfigureForPlatform(bool enable_surface_control, int32_t api_level);

  void SetDevicePixelRatio(double device_pixel_ratio);
  double GetDevicePixelRatio() const;

  void SetApiLevel(int32_t api_level);
  int32_t GetApiLevel() const;

  // ===========================================================================
  // FlutterCompositor C-API Configuration & Callbacks
  // ===========================================================================

  /**
   * @brief Populates `compositor_out` with RFC 410.0000 settings:
   * - `avoid_backing_store_cache = true`
   * - `merge_raster_thread_on_platform_views = !enable_surface_control`
   * - `coalesce_overlay_layers = enable_surface_control`
   * - `platform_view_mutation_capabilities = (api_level >= 34 ?
   *    kFlutterPlatformViewMutationCapabilityPathConics :
   *    kFlutterPlatformViewMutationCapabilityDefault)`
   * - `present_view_callback = &PresentViewCallback`
   */
  void ConfigureFlutterCompositor(FlutterCompositor* compositor_out,
                                  bool enable_surface_control,
                                  int32_t api_level);

  /**
   * @brief Populates `compositor_out` using the controller's current HCPP
   * (`IsHcppEnabled()`) and API level settings.
   */
  void PopulateCompositorConfig(FlutterCompositor* compositor_out);

  /**
   * @brief Returns a pointer to the controller's embedded `FlutterCompositor`
   * struct updated with the current configuration.
   */
  const FlutterCompositor* GetEmbedderCompositor();

  static bool CreateBackingStoreCallback(
      const FlutterBackingStoreConfig* config,
      FlutterBackingStore* backing_store_out,
      void* user_data);

  static bool CollectBackingStoreCallback(const FlutterBackingStore* renderer,
                                          void* user_data);

  static bool PresentViewCallback(const FlutterPresentViewInfo* info);

  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  bool CollectBackingStore(const FlutterBackingStore* renderer);

  bool PresentView(const FlutterPresentViewInfo* info);

  // ===========================================================================
  // Onscreen Swapchain & Frame State Accessors
  // ===========================================================================

  void SetOnscreenWindow(FlutterViewId view_id,
                         ANativeWindow* window,
                         size_t width = 0,
                         size_t height = 0);
  ANativeWindow* GetOnscreenWindow(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;
  FlutterSize GetBoundOnscreenSize(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;
  uint32_t GetBoundOnscreenFbo(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;
  size_t GetOnscreenBindCount(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;
  size_t GetOverlayBindCount(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;
  size_t GetAllocatedStoreCount() const;
  size_t GetPresentCount() const;

  std::optional<ViewFrameSnapshot> GetLastCommittedFrameSnapshot(
      FlutterViewId view_id = kPlatformViewsImplicitViewId) const;

  // ===========================================================================
  // Overlay Surface Pool & Thread-Safe Allocation
  // ===========================================================================

  /**
   * @brief Ensures an off-screen overlay surface exists at `overlay_index`.
   * When called from an unmerged raster thread, releases the controller state
   * mutex before waiting on the platform-thread latch so merged/unmerged
   * threads never deadlock.
   */
  std::optional<int32_t> EnsureOverlaySurfaceAllocated(size_t overlay_index);

  /**
   * @brief Allocates a new overlay surface on the platform thread (releasing
   * any state mutex before `latch.Wait()` when invoked off the platform
   * thread).
   */
  std::optional<int32_t> RouteCreateOverlaySurface();

  std::optional<int32_t> CreateOverlaySurface();
  bool DestroyOverlaySurfaces();
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay);
  bool OnDisplayOverlaySurface(int32_t surface_id,
                               int32_t x,
                               int32_t y,
                               int32_t width,
                               int32_t height);
  bool ShowOverlaySurface(int32_t surface_id);
  bool HideOverlaySurface(int32_t surface_id);
  ANativeWindow* GetOverlayWindow(int32_t surface_id) const;
  void SetOverlayWindow(int32_t surface_id, ANativeWindow* window);
  std::optional<PlatformViewOverlay> GetOverlaySurface(
      int32_t surface_id) const;
  size_t GetActiveOverlaySurfacesCount() const;

  // ===========================================================================
  // Platform View Lifecycle & Display (No Prior C-API Registration Required)
  // ===========================================================================

  int64_t CreatePlatformView(const PlatformViewCreationParams& params,
                             PlatformViewCompositionType type);
  bool DisposePlatformView(int64_t view_id);
  bool ResizePlatformView(int64_t view_id,
                          double width,
                          double height,
                          double* out_width = nullptr,
                          double* out_height = nullptr);
  bool OffsetPlatformView(int64_t view_id, double top, double left);
  bool SetDirection(int64_t view_id, int32_t direction);
  bool ClearFocus(int64_t view_id);
  bool DispatchTouchEvent(const PlatformViewTouch& touch);

  /**
   * @brief Dispatches `OnDisplayPlatformView` to Java without requiring prior
   * C-API `CreatePlatformView` registration.
   */
  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry);
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

  bool PushPlatformViewMutators(int64_t view_id,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                const AndroidMutatorsStack& mutators_stack);
  bool PushPlatformViewMutators(int64_t view_id,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                int32_t view_width,
                                int32_t view_height,
                                const AndroidMutatorsStack& mutators_stack);
  bool PushPlatformViewMutators(const FlutterPlatformView& platform_view,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height);
  bool PushPlatformViewMutators(const FlutterPlatformView& platform_view,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                int32_t view_width,
                                int32_t view_height);

  bool HidePlatformView(int64_t view_id);
  bool SynchronizeToNativeViewHierarchy(bool yes);
  bool OnBeginFrame();
  bool OnEndFrame();

  bool CreateTransaction();
  bool SwapTransactions();
  bool ApplyTransactions();
  bool SetHcppEnabled(bool enabled);
  bool IsHcppEnabled() const;
  void* GetSurfaceControl(int32_t surface_id) const;

  size_t GetActiveViewsCount() const;
  bool HasPlatformView(int64_t view_id) const;
  std::optional<PlatformViewCompositionType> GetCompositionType(
      int64_t view_id) const;
  std::optional<PlatformViewGeometry> GetPlatformViewGeometry(
      int64_t view_id) const;

 private:
  struct BackingStoreContext {
    uint64_t magic = 0;
    AndroidPlatformViewsController* owner = nullptr;
    bool is_root_layer = false;
    FlutterViewId view_id = kPlatformViewsImplicitViewId;
    size_t overlay_index = 0;
    int32_t overlay_surface_id = -1;
    size_t width = 0;
    size_t height = 0;
    uint32_t framebuffer_id = 0;
    ANativeWindow* native_window = nullptr;
    std::vector<uint8_t> software_pixels;
  };

  struct OnscreenSwapchainState {
    ANativeWindow* window = nullptr;
    size_t width = 0;
    size_t height = 0;
    uint32_t framebuffer_id = kDefaultOnscreenFramebufferId;
    size_t bind_count = 0;
  };

  std::optional<int32_t> CreateOverlaySurfaceInternal(
      const std::shared_ptr<PlatformViewsProvider>& provider,
      const fml::RefPtr<fml::TaskRunner>& task_runner);
  AndroidCompositorRenderDelegate* GetActiveRenderDelegateLocked() const;

  mutable std::mutex mutex_;
  std::shared_ptr<PlatformViewsProvider> provider_;
  JvmInvoker* jvm_invoker_ = nullptr;
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
  std::shared_ptr<AndroidCompositorRenderDelegate> render_delegate_;
  AndroidCompositorRenderDelegate* raw_render_delegate_ = nullptr;
  FlutterCompositor compositor_{};
  double device_pixel_ratio_ = 1.0;
  int32_t api_level_ = kAndroidApiLevelPathConics;
  bool merge_raster_thread_on_platform_views_ = true;
  size_t present_count_ = 0;
  FramePresentedCallback frame_presented_callback_;

  std::unordered_map<FlutterViewId, OnscreenSwapchainState>
      onscreen_swapchains_;
  std::unordered_map<FlutterViewId, size_t> per_view_overlay_cursor_;
  std::unordered_map<FlutterViewId, size_t> per_view_overlay_bind_count_;
  std::unordered_map<FlutterViewId, ViewFrameSnapshot> per_view_snapshots_;
  std::unordered_map<FlutterViewId, std::unordered_set<int64_t>>
      per_view_visible_platform_views_;
  std::unordered_map<FlutterViewId, bool> per_view_overlay_shown_;

  std::vector<int32_t> allocated_overlay_surface_ids_;
  std::unordered_map<int32_t, PlatformViewOverlay> active_overlay_surfaces_;
  std::unordered_map<int64_t, PlatformViewCompositionType>
      active_composition_types_;
  std::unordered_map<int64_t, PlatformViewGeometry> active_view_geometries_;
  std::unordered_set<const BackingStoreContext*> active_backing_stores_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidPlatformViewsController);
};

namespace android {
using ::flutter::AndroidCompositorRenderDelegate;
using ::flutter::AndroidPlatformViewsController;
using ::flutter::DefaultPlatformViewsProvider;
using ::flutter::InMemoryPlatformViewsProvider;
using ::flutter::PlatformViewCompositionType;
using ::flutter::PlatformViewCreationParams;
using ::flutter::PlatformViewGeometry;
using ::flutter::PlatformViewOverlay;
using ::flutter::PlatformViewResizeRequest;
using ::flutter::PlatformViewsProvider;
using ::flutter::PlatformViewTouch;
}  // namespace android

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
