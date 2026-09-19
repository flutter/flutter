// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"

namespace flutter {
namespace android {

/// @brief Abstract interface for safely and mockably invoking JVM methods
/// and managing JNI environment operations on host and target.
///
/// This abstraction decouples native embedder C-API code from direct JNIEnv/JVM
/// pointer interactions, enabling complete mockability on host test suites
/// without requiring an active Dalvik/ART JVM runtime.
class JvmInvoker {
 public:
  virtual ~JvmInvoker() = default;

  /// @brief Ensures the current thread is attached to the JVM.
  /// @return True if attached or successfully attached.
  virtual bool EnsureAttachedToThread() = 0;

  /// @brief Detaches the current thread from the JVM.
  virtual void DetachFromThread() = 0;

  /// @brief Checks if a JVM exception is pending on the current thread.
  /// @return True if an exception is pending.
  virtual bool HasPendingException() const = 0;

  /// @brief Clears any pending JVM exception on the current thread.
  virtual void ClearPendingException() = 0;

  // Typed dispatch methods matching FlutterJNI.java:

  /// @brief Handles platform message dispatch to
  /// FlutterJNI.handlePlatformMessage.
  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const uint8_t* message,
                                     size_t message_size,
                                     int32_t response_id,
                                     int64_t message_data) = 0;

  /// @brief Handles message response dispatch to
  /// FlutterJNI.handlePlatformMessageResponse.
  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const uint8_t* data,
                                             size_t data_size) = 0;

  /// @brief Dispatches accessibility semantics update to
  /// FlutterJNI.updateSemantics.
  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) = 0;

  /// @brief Dispatches custom accessibility actions to
  /// FlutterJNI.updateCustomAccessibilityActions.
  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) = 0;

  /// @brief Enables or disables accessibility tree via
  /// FlutterJNI.setSemanticsTreeEnabled.
  virtual bool SetSemanticsTreeEnabled(bool enabled) = 0;

  /// @brief Sets application locale via FlutterJNI.setApplicationLocale.
  virtual bool SetApplicationLocale(const std::string& locale) = 0;

  /// @brief Notifies FlutterJNI.onFirstFrame.
  virtual bool OnFirstFrame() = 0;

  /// @brief Notifies FlutterJNI.onPreEngineRestart.
  virtual bool OnPreEngineRestart() = 0;

  /// @brief Requests deferred library loading via
  /// FlutterJNI.requestDartDeferredLibrary.
  virtual bool RequestDartDeferredLibrary(int loading_unit_id) = 0;

  /// @brief Decodes an image from buffer bytes via FlutterJNI.decodeImage.
  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle) = 0;

  /// @brief Dispatches platform view mutators stack to
  /// FlutterJNI.pushPlatformViewMutators.
  virtual bool PushPlatformViewMutators(int64_t view_id,
                                        int32_t x,
                                        int32_t y,
                                        int32_t width,
                                        int32_t height,
                                        const std::vector<uint8_t>& payload) {
    return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                    payload);
  }

  /// @brief Dispatches platform view mutators stack and layout bounds to
  /// FlutterJNI.onDisplayPlatformView / onDisplayPlatformView2.
  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      int32_t view_width,
      int32_t view_height,
      const std::vector<uint8_t>& payload) = 0;

  /// @brief Invokes a void JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return True if invocation succeeded without exception.
  virtual bool InvokeVoidMethod(const std::string& method_name,
                                const std::string& signature,
                                const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Invokes a boolean JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return Result boolean from JVM method (or false on failure).
  virtual bool InvokeBooleanMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Invokes an integer (64-bit) JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return Result integer from JVM method.
  virtual int64_t InvokeIntMethod(const std::string& method_name,
                                  const std::string& signature,
                                  const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Invokes a double-precision floating point JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return Result double from JVM method.
  virtual double InvokeDoubleMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Invokes a String JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return Result string from JVM method.
  virtual std::string InvokeStringMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Invokes a byte array JVM method.
  /// @param method_name Name of the JVM method.
  /// @param signature JNI signature of the method.
  /// @param payload Optional serialized byte payload / arguments.
  /// @return Result byte buffer from JVM method.
  virtual std::vector<uint8_t> InvokeBytesMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) = 0;

  /// @brief Schedules an asynchronous task to run on the JVM platform thread.
  /// @param task Closure to execute.
  /// @return True if task was successfully scheduled.
  virtual bool PostJvmTask(std::function<void()> task) = 0;
};

/// @brief Default in-memory / host-safe implementation of JvmInvoker.
class DefaultJvmInvoker : public JvmInvoker {
 public:
  explicit DefaultJvmInvoker(
      fml::RefPtr<fml::TaskRunner> platform_task_runner = nullptr);
  ~DefaultJvmInvoker() override;

  bool EnsureAttachedToThread() override;
  void DetachFromThread() override;
  bool HasPendingException() const override;
  void ClearPendingException() override;

  bool HandlePlatformMessage(const std::string& channel,
                             const uint8_t* message,
                             size_t message_size,
                             int32_t response_id,
                             int64_t message_data) override;

  bool HandlePlatformMessageResponse(int32_t response_id,
                                     const uint8_t* data,
                                     size_t data_size) override;

  bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) override;

  bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) override;

  bool SetSemanticsTreeEnabled(bool enabled) override;
  bool SetApplicationLocale(const std::string& locale) override;
  bool OnFirstFrame() override;
  bool OnPreEngineRestart() override;
  bool RequestDartDeferredLibrary(int loading_unit_id) override;
  bool DecodeImage(const uint8_t* data,
                   size_t size,
                   int64_t generator_handle) override;
  bool PushPlatformViewMutators(int64_t view_id,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                const std::vector<uint8_t>& payload) override;
  bool PushPlatformViewMutators(int64_t view_id,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height,
                                int32_t view_width,
                                int32_t view_height,
                                const std::vector<uint8_t>& payload) override;

  bool InvokeVoidMethod(const std::string& method_name,
                        const std::string& signature,
                        const std::vector<uint8_t>& payload = {}) override;

  bool InvokeBooleanMethod(const std::string& method_name,
                           const std::string& signature,
                           const std::vector<uint8_t>& payload = {}) override;

  int64_t InvokeIntMethod(const std::string& method_name,
                          const std::string& signature,
                          const std::vector<uint8_t>& payload = {}) override;

  double InvokeDoubleMethod(const std::string& method_name,
                            const std::string& signature,
                            const std::vector<uint8_t>& payload = {}) override;

  std::string InvokeStringMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) override;

  std::vector<uint8_t> InvokeBytesMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) override;

  bool PostJvmTask(std::function<void()> task) override;

 private:
  std::atomic<bool> attached_{false};
  std::atomic<bool> pending_exception_{false};
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultJvmInvoker);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
