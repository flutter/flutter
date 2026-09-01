// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"

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
};

/// @brief Default in-memory / host-safe implementation of JvmInvoker.
class DefaultJvmInvoker : public JvmInvoker {
 public:
  DefaultJvmInvoker();
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
  bool attached_ = false;
  bool pending_exception_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultJvmInvoker);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JVM_INVOKER_H_
