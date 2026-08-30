// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_

#include <atomic>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jni_delegate.h"

namespace flutter {
namespace android {

/// @brief Abstract legacy delegate interface allowing fallback execution
/// when the embedder C-API rollout flag is disabled.
class LegacyJniDelegate {
 public:
  virtual ~LegacyJniDelegate() = default;

  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const uint8_t* message,
                                     size_t message_size,
                                     int32_t response_id,
                                     int64_t message_data = 0) = 0;

  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id,
                                     int64_t message_data = 0) {
    return HandlePlatformMessage(channel, message.data(), message.size(),
                                 response_id, message_data);
  }

  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const uint8_t* data,
                                             size_t data_size) = 0;

  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data) {
    return HandlePlatformMessageResponse(response_id, data.data(), data.size());
  }

  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) = 0;

  virtual bool UpdateSemantics(const std::vector<uint8_t>& buffer,
                               const std::vector<std::string>& strings) {
    return UpdateSemantics(buffer, strings, {});
  }

  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) = 0;

  virtual bool UpdateSemantics(const FlutterSemanticsUpdate2& update) = 0;

  virtual bool SetSemanticsTreeEnabled(bool enabled) = 0;

  virtual bool SetSemanticsEnabled(bool enabled) {
    return SetSemanticsTreeEnabled(enabled);
  }

  virtual bool SetApplicationLocale(const std::string& locale) = 0;

  virtual bool OnFirstFrame() = 0;

  virtual bool OnPreEngineRestart() = 0;

  virtual bool OnVsync(int64_t frame_time_nanos,
                       int64_t frame_target_time_nanos) {
    return true;
  }

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

  virtual bool RequestDartDeferredLibrary(int loading_unit_id) = 0;

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

  virtual bool CreatePlatformViewTransaction() = 0;

  virtual bool SwapPlatformViewTransactions() = 0;

  virtual bool ApplyPlatformViewTransactions() = 0;

  virtual bool IsHcppEnabled() const = 0;

  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      const AndroidMutatorsStack& mutators_stack) = 0;

  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      int32_t view_width,
      int32_t view_height,
      const AndroidMutatorsStack& mutators_stack) {
    return PushPlatformViewMutators(view_id, x, y, width, height,
                                    mutators_stack);
  }

  virtual bool PushPlatformViewMutators(
      const FlutterPlatformView& platform_view,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height) = 0;

  virtual bool PushPlatformViewMutators(
      const FlutterPlatformView& platform_view,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      int32_t view_width,
      int32_t view_height) {
    return PushPlatformViewMutators(platform_view, x, y, width, height);
  }

  virtual bool InitVM(const AndroidVMArgs& args) { return true; }

  virtual bool PrefetchDefaultFontManager() { return true; }

  virtual bool SetVmServiceUri(const std::string& uri) { return true; }
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

  JniRouter(std::shared_ptr<JniDelegate> embedder_delegate,
            std::shared_ptr<LegacyJniDelegate> legacy_delegate = nullptr);
  virtual ~JniRouter();

  /// @brief Checks whether the Embedder C-API pipeline is active globally.
  static bool IsGlobalEmbedderEnabled();

  /// @brief Sets whether the Embedder C-API pipeline is active globally.
  static void SetGlobalEmbedderEnabled(bool enabled);

  /// @brief Backward-compatible alias for IsGlobalEmbedderEnabled.
  static bool IsEmbedderEnabled();

  /// @brief Backward-compatible alias for SetGlobalEmbedderEnabled.
  static void SetEmbedderEnabled(bool enabled);

  /// @brief Sets per-instance override for embedder routing.
  void SetInstanceEmbedderEnabled(std::optional<bool> enabled);

  /// @brief Checks whether embedder pipeline is active for this router
  /// instance.
  bool IsInstanceEmbedderEnabled() const;

  /// @brief Returns the active routing path according to current flag.
  RoutingPath GetActiveRoutingPath() const;

  // Routing entry points:
  bool RoutePlatformMessage(const std::string& channel,
                            const uint8_t* message,
                            size_t message_size,
                            int32_t response_id,
                            int64_t message_data = 0);

  bool RoutePlatformMessage(const std::string& channel,
                            const std::vector<uint8_t>& message,
                            int32_t response_id,
                            int64_t message_data = 0);

  bool RoutePlatformMessageResponse(int32_t response_id,
                                    const uint8_t* data,
                                    size_t data_size);

  bool RoutePlatformMessageResponse(int32_t response_id,
                                    const std::vector<uint8_t>& data);

  bool RouteSemanticsUpdate(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args);

  bool RouteSemanticsUpdate(const std::vector<uint8_t>& buffer,
                            const std::vector<std::string>& strings) {
    return RouteSemanticsUpdate(buffer, strings, {});
  }

  bool RouteCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings);

  bool RouteSemanticsUpdate(const FlutterSemanticsUpdate2& update);

  bool RouteSemanticsTreeEnabled(bool enabled);

  bool RouteSemanticsEnabled(bool enabled) {
    return RouteSemanticsTreeEnabled(enabled);
  }

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

  bool RouteRequestDartDeferredLibrary(int loading_unit_id);

  std::optional<DartCallbackInfo> RouteLookupCallbackInformation(
      int64_t handle);

  bool RouteDecodeImage(const uint8_t* data,
                        size_t size,
                        int64_t generator_handle);

  void RouteNativeImageHeader(int64_t generator_handle,
                              int32_t width,
                              int32_t height);

  std::optional<ImageHeaderInfo> RouteGetImageHeader(int64_t generator_handle);

  void RouteRemoveImageHeader(int64_t generator_handle);

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

  bool RouteCreatePlatformViewTransaction();

  bool RouteSwapPlatformViewTransactions();

  bool RouteApplyPlatformViewTransactions();

  bool RouteIsHcppEnabled() const;

  bool RoutePlatformViewMutators(int64_t view_id,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height,
                                 const AndroidMutatorsStack& mutators_stack);

  bool RoutePlatformViewMutators(int64_t view_id,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height,
                                 int32_t view_width,
                                 int32_t view_height,
                                 const AndroidMutatorsStack& mutators_stack);

  bool RoutePlatformViewMutators(const FlutterPlatformView& platform_view,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height);

  bool RoutePlatformViewMutators(const FlutterPlatformView& platform_view,
                                 int32_t x,
                                 int32_t y,
                                 int32_t width,
                                 int32_t height,
                                 int32_t view_width,
                                 int32_t view_height);

  bool RouteInitVM(const AndroidVMArgs& args);

  bool RoutePrefetchDefaultFontManager();

  bool RouteSetVmServiceUri(const std::string& uri);

  std::shared_ptr<JniDelegate> GetEmbedderDelegate() const;
  std::shared_ptr<LegacyJniDelegate> GetLegacyDelegate() const;

 private:
  enum class InstanceOverride : int8_t {
    kUseGlobal = -1,
    kDisabled = 0,
    kEnabled = 1,
  };

  static std::atomic<bool> embedder_enabled_;
  std::atomic<InstanceOverride> instance_embedder_enabled_{
      InstanceOverride::kUseGlobal};

  std::shared_ptr<JniDelegate> embedder_delegate_;
  std::shared_ptr<LegacyJniDelegate> legacy_delegate_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniRouter);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_ROUTER_H_
