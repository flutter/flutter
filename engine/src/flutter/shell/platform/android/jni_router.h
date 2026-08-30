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
