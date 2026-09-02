// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_

#include <jni.h>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"

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

  /// @brief Routes platform message to JVM.
  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id,
                                     bool has_data = true) {
    return true;
  }

  /// @brief Routes platform message response to JVM.
  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data,
                                             bool has_data = true) {
    return true;
  }

  /// @brief Routes semantics update with nodes, strings, and string attributes
  /// to JVM.
  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) {
    return true;
  }

  /// @brief Routes custom accessibility actions to JVM.
  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) {
    return true;
  }

  /// @brief Notifies JVM whether semantics tree compilation is enabled.
  virtual bool SetSemanticsTreeEnabled(bool enabled) { return true; }

  /// @brief Sets application locale in JVM.
  virtual bool SetApplicationLocale(const std::string& locale) { return true; }

  /// @brief Gets scaled font size for nonlinear font scaling.
  virtual double GetScaledFontSize(double unscaled_font_size,
                                   int configuration_id) {
    return unscaled_font_size;
  }

  /// @brief Positions and displays a platform view with its mutators stack.
  virtual bool OnDisplayPlatformView(int64_t view_id,
                                     int32_t x,
                                     int32_t y,
                                     int32_t width,
                                     int32_t height,
                                     int32_t view_width,
                                     int32_t view_height,
                                     const AndroidMutatorsStack& mutators_stack,
                                     bool hcpp_enabled) {
    return true;
  }

  /// @brief Creates an overlay surface in the embedding.
  virtual std::optional<int32_t> CreateOverlaySurface(bool hcpp_enabled) {
    return std::nullopt;
  }

  /// @brief Displays an overlay surface with specified geometry.
  virtual bool OnDisplayOverlaySurface(int32_t surface_id,
                                       int32_t x,
                                       int32_t y,
                                       int32_t width,
                                       int32_t height) {
    return true;
  }

  /// @brief Creates a SurfaceControl transaction.
  virtual bool CreateTransaction() { return true; }

  /// @brief Resizes a platform view.
  virtual bool ResizePlatformView(int64_t view_id,
                                  double width,
                                  double height) {
    return true;
  }

  /// @brief Offsets a platform view.
  virtual bool OffsetPlatformView(int64_t view_id, double top, double left) {
    return true;
  }

  /// @brief Sets layout direction of a platform view.
  virtual bool SetPlatformViewDirection(int64_t view_id, int32_t direction) {
    return true;
  }
};

/// @brief Default in-memory / host-safe implementation of JvmInvoker.
class DefaultJvmInvoker : public JvmInvoker {
 public:
  DefaultJvmInvoker();
  DefaultJvmInvoker(JNIEnv* env, jobject java_object);
  ~DefaultJvmInvoker() override;

  bool EnsureAttachedToThread() override;
  void DetachFromThread() override;
  bool HasPendingException() const override;
  void ClearPendingException() override;

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

  double GetScaledFontSize(double unscaled_font_size,
                           int configuration_id) override;

  std::string InvokeStringMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) override;

  std::vector<uint8_t> InvokeBytesMethod(
      const std::string& method_name,
      const std::string& signature,
      const std::vector<uint8_t>& payload = {}) override;

  bool PostJvmTask(std::function<void()> task) override;

  bool HandlePlatformMessage(const std::string& channel,
                             const std::vector<uint8_t>& message,
                             int32_t response_id,
                             bool has_data = true) override;

  bool HandlePlatformMessageResponse(int32_t response_id,
                                     const std::vector<uint8_t>& data,
                                     bool has_data = true) override;

  bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args) override;

  bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings) override;

  bool SetSemanticsTreeEnabled(bool enabled) override;

  bool SetApplicationLocale(const std::string& locale) override;

  bool OnDisplayPlatformView(int64_t view_id,
                             int32_t x,
                             int32_t y,
                             int32_t width,
                             int32_t height,
                             int32_t view_width,
                             int32_t view_height,
                             const AndroidMutatorsStack& mutators_stack,
                             bool hcpp_enabled) override;

  std::optional<int32_t> CreateOverlaySurface(bool hcpp_enabled) override;

  bool OnDisplayOverlaySurface(int32_t surface_id,
                               int32_t x,
                               int32_t y,
                               int32_t width,
                               int32_t height) override;

  bool CreateTransaction() override;

  bool ResizePlatformView(int64_t view_id,
                          double width,
                          double height) override;

  bool OffsetPlatformView(int64_t view_id, double top, double left) override;

  bool SetPlatformViewDirection(int64_t view_id, int32_t direction) override;

 private:
  bool attached_ = false;
  bool pending_exception_ = false;
  std::unique_ptr<fml::jni::ScopedJavaGlobalRef<jobject>> java_object_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultJvmInvoker);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
