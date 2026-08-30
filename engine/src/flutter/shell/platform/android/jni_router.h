// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_

#include <atomic>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_surface_control.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/jni_delegate.h"

namespace flutter {
namespace android {

/// @brief Abstract legacy delegate interface allowing fallback execution
/// when the embedder C-API rollout flag is disabled.
class LegacyJniDelegate {
 public:
  virtual ~LegacyJniDelegate() = default;

  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id) = 0;

  virtual bool HandlePlatformMessageResponse(
      int32_t response_id,
      const std::vector<uint8_t>& data) = 0;

  virtual bool UpdateSemantics(const std::vector<uint8_t>& buffer,
                               const std::vector<std::string>& strings) = 0;

  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) = 0;

  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) = 0;

  virtual bool UpdateSemantics(const FlutterSemanticsUpdate2& update) = 0;

  virtual bool SetSemanticsEnabled(bool enabled) = 0;

  virtual bool DispatchSemanticsAction(int32_t node_id,
                                       FlutterSemanticsAction action,
                                       const std::vector<uint8_t>& data = {},
                                       int64_t view_id = 0) = 0;

  virtual bool SetAccessibilityFeatures(int32_t flags) = 0;

  virtual bool SetApplicationLocale(const std::string& locale) = 0;

  virtual bool OnFirstFrame() = 0;

  virtual bool OnPreEngineRestart() = 0;

  virtual bool OnVsync(int64_t frame_time_nanos,
                       int64_t frame_target_time_nanos) = 0;

  virtual bool AsyncWaitForVsync(intptr_t baton) { return true; }

  virtual bool SetViewportMetrics(const AndroidViewportMetrics& metrics) = 0;

  virtual bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) = 0;

  virtual bool UpdateDisplayMetrics(uint64_t display_id,
                                    double refresh_rate,
                                    double width,
                                    double height,
                                    double device_pixel_ratio) = 0;

  virtual bool DispatchViewportMetrics(int64_t view_id,
                                       double width,
                                       double height,
                                       double pixel_ratio) = 0;

  virtual bool RequestDartDeferredLibrary(int64_t loading_unit_id) = 0;

  virtual bool OnAssetManagerChanged() = 0;

  virtual std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle) = 0;

  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle) = 0;

  virtual void OnNativeImageHeader(int64_t generator_handle,
                                   int32_t width,
                                   int32_t height) = 0;

  virtual std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle) = 0;

  virtual int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type) = 0;

  virtual bool DisposePlatformView(int64_t view_id) = 0;

  virtual bool ResizePlatformView(const PlatformViewResizeRequest& request) = 0;

  virtual bool OffsetPlatformView(int64_t view_id, double top, double left) = 0;

  virtual bool SetPlatformViewDirection(int64_t view_id, int32_t direction) = 0;

  virtual bool ClearPlatformViewFocus(int64_t view_id) = 0;

  virtual bool DispatchPlatformViewTouch(const PlatformViewTouch& touch) = 0;

  virtual bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) = 0;

  virtual bool OnDisplayPlatformView(const FlutterPlatformView& platform_view,
                                     int32_t x,
                                     int32_t y,
                                     int32_t width,
                                     int32_t height,
                                     int32_t view_width,
                                     int32_t view_height) = 0;

  virtual bool HidePlatformView(int64_t view_id) = 0;

  virtual bool SynchronizeToNativeViewHierarchy(bool synchronize) = 0;

  virtual bool OnBeginFrame() = 0;

  virtual bool OnEndFrame() = 0;

  virtual std::optional<int32_t> CreateOverlaySurface() = 0;

  virtual bool DestroyOverlaySurfaces() = 0;

  virtual bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) = 0;

  virtual bool ShowOverlaySurface(int32_t surface_id) = 0;

  virtual bool HideOverlaySurface(int32_t surface_id) = 0;

  virtual bool SetHcppEnabled(bool enabled) { return true; }

  virtual bool CreatePlatformViewTransaction() = 0;

  virtual bool SwapPlatformViewTransactions() = 0;

  virtual bool ApplyPlatformViewTransactions() = 0;

  virtual bool IsHcppEnabled() const = 0;

  virtual bool CreateSurfaceControl(int64_t surface_id,
                                    const std::string& debug_name = "") = 0;

  virtual bool DestroySurfaceControl(int64_t surface_id) = 0;

  virtual bool ReparentSurfaceControl(int64_t surface_id,
                                      int64_t new_parent_id) = 0;

  virtual bool SetSurfaceControlGeometry(
      int64_t surface_id,
      const AndroidSurfaceControlRect& source,
      const AndroidSurfaceControlRect& destination,
      int32_t transform) = 0;

  virtual bool SetSurfaceControlVisibility(int64_t surface_id,
                                           bool visible) = 0;

  virtual bool SetSurfaceControlZOrder(int64_t surface_id, int32_t z_order) = 0;

  virtual bool SetSurfaceControlDamageRegion(
      int64_t surface_id,
      const std::vector<AndroidSurfaceControlRect>& rects) = 0;

  virtual bool SetSurfaceControlBuffer(int64_t surface_id,
                                       void* buffer,
                                       int fence_fd = -1) = 0;

  virtual bool SetSurfaceControlBufferAlpha(int64_t surface_id,
                                            float alpha) = 0;

  virtual bool SetSurfaceControlColor(int64_t surface_id,
                                      float r,
                                      float g,
                                      float b,
                                      float alpha) = 0;

  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      const AndroidMutatorsStack& mutators_stack) = 0;

  virtual bool PushPlatformViewMutators(
      const FlutterPlatformView& platform_view,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height) = 0;

  virtual bool InitVM(const AndroidVMArgs& args) = 0;

  virtual bool PrefetchDefaultFontManager() = 0;

  virtual bool SetVmServiceUri(const std::string& uri) = 0;

  virtual bool RegisterHardwareBufferTexture(int64_t texture_id) = 0;

  virtual bool UnregisterHardwareBufferTexture(int64_t texture_id) = 0;

  virtual bool SetHardwareBufferFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidHardwareBuffer>& buffer) = 0;

  virtual bool SetHardwareBufferFrame(
      int64_t texture_id,
      const FlutterHardwareBufferExternalTexture& texture) = 0;

  virtual bool GetHardwareBufferTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out) = 0;

  virtual bool OnHardwareBufferFrameAvailable(int64_t texture_id) = 0;

  virtual bool RegisterVulkanTexture(int64_t texture_id) = 0;

  virtual bool UnregisterVulkanTexture(int64_t texture_id) = 0;

  virtual bool SetVulkanTextureFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidVulkanExternalTexture>& texture) = 0;

  virtual bool SetVulkanTextureFrame(
      int64_t texture_id,
      const FlutterVulkanExternalTexture& texture) = 0;

  virtual bool GetVulkanTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterVulkanExternalTexture* texture_out) = 0;

  virtual bool OnVulkanTextureFrameAvailable(int64_t texture_id) = 0;

  virtual int64_t SpawnEngine(int64_t parent_engine_id,
                              const AndroidEngineSpawnArgs& args) = 0;

  virtual bool ShutdownSpawnedEngine(int64_t engine_id) = 0;

  virtual size_t GetActiveEngineCount() const = 0;

  virtual bool OnEngineGarbageCollected(int64_t engine_id) = 0;
};

/// @brief Native JNI Routing Boundary that dispatches calls based on
/// IsEmbedderEnabled() flag.
///
/// Implements the structural rollout flip: if IsEmbedderEnabled() is true,
/// dispatches to JniDelegate (injected with JvmInvoker). If false, dispatches
/// to LegacyJniDelegate.
class JniRouter {
 public:
  enum class RoutingPath {
    kLegacy,
    kEmbedder,
  };

  JniRouter(
      std::shared_ptr<JniDelegate> embedder_delegate,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr);
  virtual ~JniRouter();

  /// @brief Checks whether the Embedder C-API pipeline is active.
  static bool IsEmbedderEnabled();

  /// @brief Sets whether the Embedder C-API pipeline is active.
  static void SetEmbedderEnabled(bool enabled);

  /// @brief Returns the active routing path according to current flag.
  RoutingPath GetActiveRoutingPath() const;

  // Routing entry points:
  bool RoutePlatformMessage(const std::string& channel,
                            const std::vector<uint8_t>& message,
                            int32_t response_id);

  bool RoutePlatformMessageResponse(int32_t response_id,
                                    const std::vector<uint8_t>& data);

  bool RouteSemanticsUpdate(const std::vector<uint8_t>& buffer,
                            const std::vector<std::string>& strings);

  bool RouteSemanticsUpdate(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args);

  bool RouteCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings);

  bool RouteSemanticsUpdate(const FlutterSemanticsUpdate2& update);

  bool RouteSemanticsEnabled(bool enabled);

  bool RouteDispatchSemanticsAction(int32_t node_id,
                                    FlutterSemanticsAction action,
                                    const std::vector<uint8_t>& data = {},
                                    int64_t view_id = 0);

  bool RouteSetAccessibilityFeatures(int32_t flags);

  bool RouteApplicationLocale(const std::string& locale);

  bool RouteFirstFrame();

  bool RoutePreEngineRestart();

  bool RouteVsync(int64_t frame_time_nanos, int64_t frame_target_time_nanos);

  bool RouteAsyncWaitForVsync(intptr_t baton);

  bool RouteSetViewportMetrics(const AndroidViewportMetrics& metrics);

  bool RouteUpdateDisplayMetrics(const AndroidDisplayMetrics& metrics);

  bool RouteUpdateDisplayMetrics(uint64_t display_id,
                                 double refresh_rate,
                                 double width,
                                 double height,
                                 double device_pixel_ratio);

  bool RouteViewportMetrics(int64_t view_id,
                            double width,
                            double height,
                            double pixel_ratio);

  bool RouteRequestDartDeferredLibrary(int64_t loading_unit_id);

  bool RouteAssetManagerChanged();

  std::optional<DartCallbackInfo> RouteLookupCallbackInformation(
      int64_t handle);

  bool RouteDecodeImage(const uint8_t* data,
                        size_t size,
                        int64_t generator_handle);

  void RouteNativeImageHeader(int64_t generator_handle,
                              int32_t width,
                              int32_t height);

  std::optional<ImageHeaderInfo> RouteGetImageHeader(int64_t generator_handle);

  int64_t RouteCreatePlatformView(const PlatformViewCreationParams& params,
                                  PlatformViewCompositionType composition_type);

  bool RouteDisposePlatformView(int64_t view_id);

  bool RouteResizePlatformView(const PlatformViewResizeRequest& request);

  bool RouteOffsetPlatformView(int64_t view_id, double top, double left);

  bool RouteSetPlatformViewDirection(int64_t view_id, int32_t direction);

  bool RouteClearPlatformViewFocus(int64_t view_id);

  bool RouteDispatchPlatformViewTouch(const PlatformViewTouch& touch);

  bool RouteOnDisplayPlatformView(const PlatformViewGeometry& geometry);

  bool RouteOnDisplayPlatformView(const FlutterPlatformView& platform_view,
                                  int32_t x,
                                  int32_t y,
                                  int32_t width,
                                  int32_t height,
                                  int32_t view_width,
                                  int32_t view_height);

  bool RouteHidePlatformView(int64_t view_id);

  bool RouteSynchronizeToNativeViewHierarchy(bool synchronize);

  bool RouteBeginFrame();

  bool RouteEndFrame();

  std::optional<int32_t> RouteCreateOverlaySurface();

  bool RouteDestroyOverlaySurfaces();

  bool RouteOnDisplayOverlaySurface(const PlatformViewOverlay& overlay);

  bool RouteShowOverlaySurface(int32_t surface_id);

  bool RouteHideOverlaySurface(int32_t surface_id);

  bool RouteSetHcppEnabled(bool enabled);

  bool RouteCreatePlatformViewTransaction();

  bool RouteSwapPlatformViewTransactions();

  bool RouteApplyPlatformViewTransactions();

  bool RouteIsHcppEnabled() const;

  bool RouteCreateSurfaceControl(int64_t surface_id,
                                 const std::string& debug_name = "");

  bool RouteDestroySurfaceControl(int64_t surface_id);

  bool RouteReparentSurfaceControl(int64_t surface_id, int64_t new_parent_id);

  bool RouteSetSurfaceControlGeometry(
      int64_t surface_id,
      const AndroidSurfaceControlRect& source,
      const AndroidSurfaceControlRect& destination,
      int32_t transform = 0);

  bool RouteSetSurfaceControlVisibility(int64_t surface_id, bool visible);

  bool RouteSetSurfaceControlZOrder(int64_t surface_id, int32_t z_order);

  bool RouteSetSurfaceControlDamageRegion(
      int64_t surface_id,
      const std::vector<AndroidSurfaceControlRect>& rects);

  bool RouteSetSurfaceControlBuffer(int64_t surface_id,
                                    void* buffer,
                                    int fence_fd = -1);

  bool RouteSetSurfaceControlBufferAlpha(int64_t surface_id, float alpha);

  bool RouteSetSurfaceControlColor(int64_t surface_id,
                                   float r,
                                   float g,
                                   float b,
                                   float alpha);

  std::optional<AndroidSurfaceControlState> RouteGetSurfaceControlState(
      int64_t surface_id) const;

  std::shared_ptr<AndroidSurfaceControl> RouteGetSurfaceControl(
      int64_t surface_id) const;

  bool RoutePlatformViewMutators(int64_t view_id,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height,
                                 const AndroidMutatorsStack& mutators_stack);

  bool RoutePlatformViewMutators(const FlutterPlatformView& platform_view,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height);

  bool RouteInitVM(const AndroidVMArgs& args);

  bool RoutePrefetchDefaultFontManager();

  bool RouteSetVmServiceUri(const std::string& uri);

  bool RouteRegisterHardwareBufferTexture(int64_t texture_id);

  bool RouteUnregisterHardwareBufferTexture(int64_t texture_id);

  bool RouteSetHardwareBufferFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidHardwareBuffer>& buffer);

  bool RouteSetHardwareBufferFrame(
      int64_t texture_id,
      const FlutterHardwareBufferExternalTexture& texture);

  bool RouteGetHardwareBufferTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out);

  bool RouteOnHardwareBufferFrameAvailable(int64_t texture_id);

  bool RouteRegisterVulkanTexture(int64_t texture_id);

  bool RouteUnregisterVulkanTexture(int64_t texture_id);

  bool RouteSetVulkanTextureFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidVulkanExternalTexture>& texture);

  bool RouteSetVulkanTextureFrame(int64_t texture_id,
                                  const FlutterVulkanExternalTexture& texture);

  bool RouteGetVulkanTextureFrame(int64_t texture_id,
                                  size_t width,
                                  size_t height,
                                  FlutterVulkanExternalTexture* texture_out);

  bool RouteOnVulkanTextureFrameAvailable(int64_t texture_id);

  int64_t RouteSpawnEngine(int64_t parent_engine_id,
                           const AndroidEngineSpawnArgs& args);

  bool RouteShutdownSpawnedEngine(int64_t engine_id);

  size_t RouteGetActiveEngineCount() const;

  bool RouteOnEngineGarbageCollected(int64_t engine_id);

  std::shared_ptr<JniDelegate> GetEmbedderDelegate() const;
  std::shared_ptr<LegacyJniDelegate> GetLegacyDelegate() const;

 private:
  static std::atomic<bool> embedder_enabled_;

  std::shared_ptr<JniDelegate> embedder_delegate_;
  std::shared_ptr<LegacyJniDelegate> legacy_delegate_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniRouter);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
