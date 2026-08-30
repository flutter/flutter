// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"

namespace flutter {
namespace android {

/// @brief Delegate that adapts Flutter Embedder C-API operations to the JVM.
///
/// Holds an injected JvmInvoker instance that abstracts all direct JVM/JNI
/// calls, guaranteeing host testability without native JNI dependencies.
class JniDelegate {
 public:
  explicit JniDelegate(std::shared_ptr<JvmInvoker> jvm_invoker);
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

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniDelegate);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
