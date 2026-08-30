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
      const std::vector<std::vector<uint8_t>>& string_attribute_args = {}) = 0;

  virtual bool SetSemanticsTreeEnabled(bool enabled) = 0;

  virtual bool SetApplicationLocale(const std::string& locale) = 0;

  virtual bool OnFirstFrame() = 0;

  virtual bool OnPreEngineRestart() = 0;

  virtual bool RequestDartDeferredLibrary(int loading_unit_id) = 0;
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
      const std::vector<std::vector<uint8_t>>& string_attribute_args = {});

  bool RouteSemanticsTreeEnabled(bool enabled);

  bool RouteApplicationLocale(const std::string& locale);

  bool RouteFirstFrame();

  bool RoutePreEngineRestart();

  bool RouteRequestDartDeferredLibrary(int loading_unit_id);

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
