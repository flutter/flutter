// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

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

/// @brief Abstract provider interface for resolving Dart callback
/// representations.
class CallbackCacheProvider {
 public:
  virtual ~CallbackCacheProvider() = default;

  /// @brief Looks up Dart callback information for a given callback handle.
  virtual std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) = 0;
};

/// @brief Default C-API backed callback cache provider that calls
/// FlutterEngineGetCallbackInformation.
class DefaultCallbackCacheProvider : public CallbackCacheProvider {
 public:
  DefaultCallbackCacheProvider();
  ~DefaultCallbackCacheProvider() override;

  std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) override;
};

/// @brief In-memory mock callback cache provider for unit testing without
/// Dart VM or disk cache dependencies.
class InMemoryCallbackCacheProvider : public CallbackCacheProvider {
 public:
  InMemoryCallbackCacheProvider();
  ~InMemoryCallbackCacheProvider() override;

  void AddCallback(int64_t handle,
                   const std::string& name,
                   const std::string& class_name,
                   const std::string& library_path);

  void RemoveCallback(int64_t handle);

  void Clear();

  size_t GetSize() const;

  std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) override;

 private:
  mutable std::shared_mutex mutex_;
  std::map<int64_t, DartCallbackInfo> cache_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryCallbackCacheProvider);
};

/// @brief Delegate that adapts Flutter Embedder C-API operations to the JVM.
///
/// Holds an injected JvmInvoker instance that abstracts all direct JVM/JNI
/// calls, guaranteeing host testability without native JNI dependencies.
class JniDelegate {
 public:
  explicit JniDelegate(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      std::shared_ptr<CallbackCacheProvider> callback_cache = nullptr);
  virtual ~JniDelegate();

  /// @brief Handles an incoming platform message dispatch to the JVM.
  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const uint8_t* message,
                                     size_t message_size,
                                     int32_t response_id,
                                     int64_t message_data = 0);

  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id,
                                     int64_t message_data = 0);

  /// @brief Handles a platform message response back to the JVM.
  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const uint8_t* data,
                                             size_t data_size);

  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data);

  /// @brief Updates accessibility semantics tree in the JVM.
  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args = {});

  /// @brief Enables or disables accessibility semantics tree in the JVM.
  virtual bool SetSemanticsTreeEnabled(bool enabled);

  /// @brief Sets application locale in the JVM.
  virtual bool SetApplicationLocale(const std::string& locale);

  /// @brief Notifies the JVM that the first frame has rendered.
  virtual bool OnFirstFrame();

  /// @brief Notifies the JVM before the Flutter engine restarts.
  virtual bool OnPreEngineRestart();

  /// @brief Requests loading of a Dart deferred library component.
  virtual bool RequestDartDeferredLibrary(int loading_unit_id);

  /// @brief Looks up Dart callback information for a given handle.
  virtual std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle);

  /// @brief Sets or replaces the CallbackCacheProvider used for lookups.
  void SetCallbackCache(std::shared_ptr<CallbackCacheProvider> provider);

  /// @brief Returns the current CallbackCacheProvider.
  std::shared_ptr<CallbackCacheProvider> GetCallbackCache() const;

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  mutable std::mutex callback_cache_mutex_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniDelegate);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
