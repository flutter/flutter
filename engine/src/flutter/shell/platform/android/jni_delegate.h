// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#include "flutter/shell/platform/android/android_surface_control.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

class AndroidVsyncWaiter;

/// @brief Decoupled representation of Dart callback metadata.
struct DartCallbackInfo {
  std::string name;
  std::string class_name;
  std::string library_path;

  bool operator==(const DartCallbackInfo& other) const {
    return name == other.name && class_name == other.class_name &&
           library_path == other.library_path;
  }
};

/// @brief Decoupled representation of decoded image header metadata.
struct ImageHeaderInfo {
  int32_t width = 0;
  int32_t height = 0;

  bool operator==(const ImageHeaderInfo& other) const {
    return width == other.width && height == other.height;
  }
};

/// @brief Abstract provider interface for resolving Dart callback
/// representations.
class CallbackCacheProvider {
 public:
  virtual ~CallbackCacheProvider() = default;

  /// @brief Looks up Dart callback information for a given callback handle.
  virtual std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) = 0;
};

/// @brief Abstract provider interface for platform/custom image decoding.
class ImageDecoderProvider {
 public:
  virtual ~ImageDecoderProvider() = default;

  /// @brief Decodes image data given raw buffer bytes and generator handle.
  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle) = 0;

  /// @brief Handles native image header notification callback.
  virtual void OnImageHeader(int64_t generator_handle,
                             int32_t width,
                             int32_t height) = 0;

  /// @brief Returns the decoded image header info for a generator handle.
  virtual std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle) = 0;
};

/// @brief Delegate that adapts Flutter Embedder C-API operations to the JVM.
///
/// Holds an injected JvmInvoker instance that abstracts all direct JVM/JNI
/// calls, guaranteeing host testability without native JNI dependencies.
class JniDelegate {
 public:
  explicit JniDelegate(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      std::shared_ptr<CallbackCacheProvider> callback_cache = nullptr,
      std::shared_ptr<ImageDecoderProvider> image_decoder = nullptr,
      std::shared_ptr<PlatformViewsProvider> platform_views_provider = nullptr,
      std::shared_ptr<WindowMetricsProvider> window_metrics_provider = nullptr,
      std::shared_ptr<AndroidVsyncWaiter> vsync_waiter = nullptr,
      std::shared_ptr<AndroidVMInit> vm_init = nullptr,
      std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider =
          nullptr,
      std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider =
          nullptr,
      std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroup> engine_group = nullptr);
  virtual ~JniDelegate();

  /// @brief Handles an incoming platform message dispatch to the JVM.
  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id,
                                     bool has_data = true);

  /// @brief Handles a platform message response back to the JVM.
  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data,
                                             bool has_data = true);

  /// @brief Updates accessibility semantics tree in the JVM.
  virtual bool UpdateSemantics(const std::vector<uint8_t>& buffer,
                               const std::vector<std::string>& strings);

  /// @brief Updates accessibility semantics tree with string attributes in the
  /// JVM.
  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args);

  /// @brief Updates custom accessibility actions in the JVM.
  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings);

  /// @brief Updates complete semantics tree and custom actions from
  /// FlutterSemanticsUpdate2.
  virtual bool UpdateSemantics(const FlutterSemanticsUpdate2& update);

  /// @brief Enables or disables accessibility semantics tree in the JVM.
  virtual bool SetSemanticsEnabled(bool enabled);

  /// @brief Dispatches a semantics action to a node in the JVM.
  virtual bool DispatchSemanticsAction(int32_t node_id,
                                       FlutterSemanticsAction action,
                                       const std::vector<uint8_t>& data = {},
                                       int64_t view_id = 0);

  /// @brief Sets accessibility features bitmask in the JVM.
  virtual bool SetAccessibilityFeatures(int32_t flags);

  /// @brief Sets application locale in the JVM.
  virtual bool SetApplicationLocale(const std::string& locale);

  /// @brief Notifies the JVM that the first frame has rendered.
  virtual bool OnFirstFrame();

  /// @brief Notifies the JVM before the Flutter engine restarts.
  virtual bool OnPreEngineRestart();

  /// @brief Dispatches VSync callback timestamps to the JVM.
  virtual bool OnVsync(int64_t frame_time_nanos,
                       int64_t frame_target_time_nanos);

  /// @brief Asynchronously requests a VSync signal for the given baton.
  virtual bool AsyncWaitForVsync(intptr_t baton);

  /// @brief Sends full viewport metrics.
  virtual bool SetViewportMetrics(const AndroidViewportMetrics& metrics);

  /// @brief Updates display metrics.
  virtual bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics);

  /// @brief Updates display metrics with individual parameters.
  virtual bool UpdateDisplayMetrics(uint64_t display_id,
                                    double refresh_rate,
                                    double width,
                                    double height,
                                    double device_pixel_ratio);

  /// @brief Returns the last received viewport metrics for view_id.
  virtual std::optional<AndroidViewportMetrics> GetViewportMetrics(
      int64_t view_id = 0) const;

  /// @brief Returns the last received display metrics for display_id.
  virtual std::optional<AndroidDisplayMetrics> GetDisplayMetrics(
      uint64_t display_id = 0) const;

  /// @brief Updates display metrics for a view in the JVM (legacy helper).
  virtual bool DispatchViewportMetrics(int64_t view_id,
                                       double width,
                                       double height,
                                       double pixel_ratio);

  /// @brief Requests loading of a Dart deferred library component.
  virtual bool RequestDartDeferredLibrary(int64_t loading_unit_id);

  /// @brief Notifies the JVM that the asset manager / bundle has changed.
  virtual bool OnAssetManagerChanged();

  /// @brief Computes scaled font size for nonlinear font scaling.
  virtual double GetScaledFontSize(double unscaled_font_size,
                                   int configuration_id) const;

  /// @brief Looks up Dart callback information for a given handle.
  virtual std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle);

  /// @brief Decodes an image from buffer bytes.
  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle);

  /// @brief Notifies that image header dimensions are parsed.
  virtual void OnNativeImageHeader(int64_t generator_handle,
                                   int32_t width,
                                   int32_t height);

  /// @brief Gets parsed image header info for a generator handle.
  virtual std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle);

  /// @brief Creates a platform view in the JVM.
  virtual int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type);

  /// @brief Disposes a platform view by ID.
  virtual bool DisposePlatformView(int64_t view_id);

  /// @brief Resizes a platform view.
  virtual bool ResizePlatformView(const PlatformViewResizeRequest& request);

  /// @brief Sets top-left offset for a platform view.
  virtual bool OffsetPlatformView(int64_t view_id, double top, double left);

  /// @brief Sets layout direction for a platform view.
  virtual bool SetPlatformViewDirection(int64_t view_id, int32_t direction);

  /// @brief Clears focus from a platform view.
  virtual bool ClearPlatformViewFocus(int64_t view_id);

  /// @brief Dispatches a touch event to a platform view.
  virtual bool DispatchPlatformViewTouch(const PlatformViewTouch& touch);

  /// @brief Positions and displays a platform view with geometry.
  virtual bool OnDisplayPlatformView(const PlatformViewGeometry& geometry);

  /// @brief Positions and displays a platform view with FlutterPlatformView.
  virtual bool OnDisplayPlatformView(const FlutterPlatformView& platform_view,
                                     int32_t x,
                                     int32_t y,
                                     int32_t width,
                                     int32_t height,
                                     int32_t view_width,
                                     int32_t view_height);

  /// @brief Hides a platform view.
  virtual bool HidePlatformView(int64_t view_id);

  /// @brief Synchronizes rendering surface to native view hierarchy.
  virtual bool SynchronizeToNativeViewHierarchy(bool synchronize);

  /// @brief Signals start of a frame for hybrid composition.
  virtual bool OnBeginFrame();

  /// @brief Signals end of a frame for hybrid composition.
  virtual bool OnEndFrame();

  /// @brief Instantiates an overlay surface in hybrid composition.
  virtual std::optional<int32_t> CreateOverlaySurface();

  /// @brief Destroys all active overlay surfaces.
  virtual bool DestroyOverlaySurfaces();

  /// @brief Positions and sizes an overlay surface.
  virtual bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay);

  /// @brief Shows an overlay surface.
  virtual bool ShowOverlaySurface(int32_t surface_id);

  /// @brief Hides an overlay surface.
  virtual bool HideOverlaySurface(int32_t surface_id);

  /// @brief Sets whether HC++ presentation is supported and enabled.
  virtual bool SetHcppEnabled(bool enabled);

  /// @brief Checks whether HC++ presentation is supported and enabled.
  virtual bool IsHcppEnabled() const;

  /// @brief Creates a SurfaceControl transaction for HC++.
  virtual bool CreatePlatformViewTransaction();

  /// @brief Swaps active SurfaceControl transactions for HC++.
  virtual bool SwapPlatformViewTransactions();

  /// @brief Applies pending SurfaceControl transactions for HC++.
  virtual bool ApplyPlatformViewTransactions();

  /// @brief Creates a native SurfaceControl node.
  virtual bool CreateSurfaceControl(int64_t surface_id,
                                    const std::string& debug_name = "");

  /// @brief Destroys a native SurfaceControl node.
  virtual bool DestroySurfaceControl(int64_t surface_id);

  /// @brief Reparents a native SurfaceControl node under a new parent node.
  virtual bool ReparentSurfaceControl(int64_t surface_id,
                                      int64_t new_parent_id);

  /// @brief Sets geometry crop, scaling, and transform on a native
  /// SurfaceControl node.
  virtual bool SetSurfaceControlGeometry(
      int64_t surface_id,
      const AndroidSurfaceControlRect& source,
      const AndroidSurfaceControlRect& destination,
      int32_t transform = 0);

  /// @brief Sets visibility on a native SurfaceControl node.
  virtual bool SetSurfaceControlVisibility(int64_t surface_id, bool visible);

  /// @brief Sets z-order on a native SurfaceControl node.
  virtual bool SetSurfaceControlZOrder(int64_t surface_id, int32_t z_order);

  /// @brief Sets damage region rects on a native SurfaceControl node.
  virtual bool SetSurfaceControlDamageRegion(
      int64_t surface_id,
      const std::vector<AndroidSurfaceControlRect>& rects);

  /// @brief Sets buffer and fence on a native SurfaceControl node.
  virtual bool SetSurfaceControlBuffer(int64_t surface_id,
                                       void* buffer,
                                       int fence_fd = -1);

  /// @brief Sets buffer alpha transparency on a native SurfaceControl node.
  virtual bool SetSurfaceControlBufferAlpha(int64_t surface_id, float alpha);

  /// @brief Sets solid background color on a native SurfaceControl node.
  virtual bool SetSurfaceControlColor(int64_t surface_id,
                                      float r,
                                      float g,
                                      float b,
                                      float alpha);

  /// @brief Sets or replaces the AndroidSurfaceControlProvider.
  void SetSurfaceControlProvider(
      std::shared_ptr<AndroidSurfaceControlProvider> provider);

  /// @brief Returns the current AndroidSurfaceControlProvider.
  std::shared_ptr<AndroidSurfaceControlProvider> GetSurfaceControlProvider()
      const;

  /// @brief Returns the state snapshot of a SurfaceControl node.
  std::optional<AndroidSurfaceControlState> GetSurfaceControlState(
      int64_t surface_id) const;

  /// @brief Returns the managed AndroidSurfaceControl instance by surface ID.
  std::shared_ptr<AndroidSurfaceControl> GetSurfaceControl(
      int64_t surface_id) const;

  /// @brief Dispatches platform view mutator stack to the JVM.
  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      const AndroidMutatorsStack& mutators_stack);

  /// @brief Dispatches platform view mutator stack derived from a
  /// FlutterPlatformView.
  virtual bool PushPlatformViewMutators(
      const FlutterPlatformView& platform_view,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height);

  /// @brief Sets or replaces the CallbackCacheProvider used for lookups.
  void SetCallbackCache(std::shared_ptr<CallbackCacheProvider> provider);

  /// @brief Returns the current CallbackCacheProvider.
  std::shared_ptr<CallbackCacheProvider> GetCallbackCache() const;

  /// @brief Sets or replaces the ImageDecoderProvider.
  void SetImageDecoderProvider(std::shared_ptr<ImageDecoderProvider> provider);

  /// @brief Returns the current ImageDecoderProvider.
  std::shared_ptr<ImageDecoderProvider> GetImageDecoderProvider() const;

  /// @brief Sets or replaces the PlatformViewsProvider.
  void SetPlatformViewsProvider(
      std::shared_ptr<PlatformViewsProvider> provider);

  /// @brief Returns the current PlatformViewsProvider.
  std::shared_ptr<PlatformViewsProvider> GetPlatformViewsProvider() const;

  /// @brief Sets or replaces the WindowMetricsProvider.
  void SetWindowMetricsProvider(
      std::shared_ptr<WindowMetricsProvider> provider);

  /// @brief Returns the current WindowMetricsProvider.
  std::shared_ptr<WindowMetricsProvider> GetWindowMetricsProvider() const;

  /// @brief Sets or replaces the AndroidVsyncWaiter.
  void SetVsyncWaiter(std::shared_ptr<AndroidVsyncWaiter> provider);

  /// @brief Returns the current AndroidVsyncWaiter.
  std::shared_ptr<AndroidVsyncWaiter> GetVsyncWaiter() const;

  /// @brief Initializes the Android VM with the specified arguments.
  virtual bool InitVM(const AndroidVMArgs& args);

  /// @brief Prefetches the default font collection.
  virtual bool PrefetchDefaultFontManager();

  /// @brief Sets the Dart VM service URI and updates JVM.
  virtual bool SetVmServiceUri(const std::string& uri);

  /// @brief Returns the last recorded VM service URI.
  virtual std::string GetVmServiceUri() const;

  /// @brief Returns whether VM initialization has completed.
  virtual bool IsVMInitialized() const;

  /// @brief Returns the VM arguments if initialized.
  virtual std::optional<AndroidVMArgs> GetVMArgs() const;

  /// @brief Sets or replaces the AndroidVMInit coordinator.
  void SetVMInit(std::shared_ptr<AndroidVMInit> vm_init);

  /// @brief Returns the current AndroidVMInit coordinator.
  std::shared_ptr<AndroidVMInit> GetVMInit() const;

  /// @brief Returns the current AndroidPlatformViewsController.
  std::shared_ptr<AndroidPlatformViewsController> GetPlatformViewsController()
      const;

  /// @brief Registers a hardware buffer texture with texture_id in JVM /
  /// Delegate.
  virtual bool RegisterHardwareBufferTexture(int64_t texture_id);

  /// @brief Unregisters a hardware buffer texture by texture_id.
  virtual bool UnregisterHardwareBufferTexture(int64_t texture_id);

  /// @brief Sets the latest hardware buffer frame for texture_id.
  virtual bool SetHardwareBufferFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidHardwareBuffer>& buffer);

  /// @brief Sets the latest external texture struct for texture_id.
  virtual bool SetHardwareBufferFrame(
      int64_t texture_id,
      const FlutterHardwareBufferExternalTexture& texture);

  /// @brief Retrieves the latest hardware buffer frame for texture_id.
  virtual bool GetHardwareBufferTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out);

  /// @brief Notifies that a new hardware buffer frame is available for
  /// texture_id.
  virtual bool OnHardwareBufferFrameAvailable(int64_t texture_id);

  /// @brief Sets or replaces the AndroidHardwareBufferProvider.
  void SetHardwareBufferProvider(
      std::shared_ptr<AndroidHardwareBufferProvider> provider);

  /// @brief Returns the current AndroidHardwareBufferProvider.
  std::shared_ptr<AndroidHardwareBufferProvider> GetHardwareBufferProvider()
      const;

  /// @brief Registers a Vulkan external texture with texture_id in JVM /
  /// Delegate.
  virtual bool RegisterVulkanTexture(int64_t texture_id);

  /// @brief Unregisters a Vulkan external texture by texture_id.
  virtual bool UnregisterVulkanTexture(int64_t texture_id);

  /// @brief Sets the latest Vulkan texture frame for texture_id.
  virtual bool SetVulkanTextureFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidVulkanExternalTexture>& texture);

  /// @brief Sets the latest Vulkan external texture struct for texture_id.
  virtual bool SetVulkanTextureFrame(
      int64_t texture_id,
      const FlutterVulkanExternalTexture& texture);

  /// @brief Retrieves the latest Vulkan texture frame for texture_id.
  virtual bool GetVulkanTextureFrame(int64_t texture_id,
                                     size_t width,
                                     size_t height,
                                     FlutterVulkanExternalTexture* texture_out);

  /// @brief Notifies that a new Vulkan texture frame is available for
  /// texture_id.
  virtual bool OnVulkanTextureFrameAvailable(int64_t texture_id);

  /// @brief Sets or replaces the AndroidVulkanTextureProvider.
  void SetVulkanTextureProvider(
      std::shared_ptr<AndroidVulkanTextureProvider> provider);

  /// @brief Returns the current AndroidVulkanTextureProvider.
  std::shared_ptr<AndroidVulkanTextureProvider> GetVulkanTextureProvider()
      const;

  /// @brief Spawns a child FlutterEngine instance in the engine group.
  virtual int64_t SpawnEngine(int64_t parent_engine_id,
                              const AndroidEngineSpawnArgs& args);

  /// @brief Shuts down a spawned FlutterEngine instance by ID.
  virtual bool ShutdownSpawnedEngine(int64_t engine_id);

  /// @brief Returns the count of active engines in the group.
  virtual size_t GetActiveEngineCount() const;

  /// @brief Callback invoked by Java Cleaner / PhantomReference when an engine
  /// is GC'd.
  virtual bool OnEngineGarbageCollected(int64_t engine_id);

  /// @brief Returns the underlying AndroidEngineGroup instance.
  virtual std::shared_ptr<AndroidEngineGroup> GetEngineGroup() const;

  /// @brief Sets or replaces the AndroidEngineGroup instance.
  void SetEngineGroup(std::shared_ptr<AndroidEngineGroup> group);

  /// @brief Returns the underlying AndroidEngineGroupProvider.
  std::shared_ptr<AndroidEngineGroupProvider> GetEngineGroupProvider() const;

  /// @brief Sets or replaces the AndroidEngineGroupProvider.
  void SetEngineGroupProvider(
      std::shared_ptr<AndroidEngineGroupProvider> provider);

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<ImageDecoderProvider> image_decoder_;
  std::shared_ptr<PlatformViewsProvider> platform_views_provider_;
  std::shared_ptr<WindowMetricsProvider> window_metrics_provider_;
  std::shared_ptr<AndroidVsyncWaiter> vsync_waiter_;
  std::shared_ptr<AndroidVMInit> vm_init_;
  std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider_;
  std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider_;
  std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider_;
  std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider_;
  std::shared_ptr<AndroidEngineGroup> engine_group_;
  std::shared_ptr<AndroidPlatformViewsController> platform_views_controller_;
  bool hcpp_enabled_ = false;

  mutable std::mutex hardware_buffer_mutex_;
  std::unordered_set<int64_t> registered_hardware_textures_;
  std::map<int64_t, FlutterHardwareBufferExternalTexture>
      hardware_buffer_frames_;
  std::map<int64_t, std::shared_ptr<AndroidHardwareBuffer>>
      hardware_buffer_objects_;

  mutable std::mutex vulkan_texture_mutex_;
  std::unordered_set<int64_t> registered_vulkan_textures_;
  std::map<int64_t, FlutterVulkanExternalTexture> vulkan_texture_frames_;
  std::map<int64_t, std::shared_ptr<AndroidVulkanExternalTexture>>
      vulkan_texture_objects_;
  std::map<int64_t, FlutterVulkanYcbcrConversionInfo> vulkan_ycbcr_conversions_;

  mutable std::mutex surface_control_mutex_;
  std::map<int64_t, std::shared_ptr<AndroidSurfaceControl>> surface_controls_;
  std::map<int64_t, AndroidSurfaceControlState> surface_control_states_;
  std::shared_ptr<AndroidSurfaceTransaction> active_transaction_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniDelegate);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
