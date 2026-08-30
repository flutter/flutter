// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstddef>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Quarantined native entry point and manager for the Android C-API
/// Embedder.
///
/// This class enforces strict GN and C-ABI isolation from legacy Skia /
/// internal UI headers, serving as the foundational shield for Phase 1 of
/// the Android embedder migration.
class FlutterEmbedderNative {
 public:
  FlutterEmbedderNative();
  explicit FlutterEmbedderNative(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      std::shared_ptr<LegacyJniDelegate> legacy_delegate = nullptr);
  ~FlutterEmbedderNative();

  /// @brief Checks whether the embedder C-API quarantine is active.
  /// @return True if quarantined and running strictly on top of embedder.h.
  static bool IsQuarantineEnforced();

  /// @brief Verifies that the embedder engine version is compatible with the
  /// current build.
  /// @return True if version verification succeeds.
  static bool VerifyEmbedderVersion();

  /// @brief Returns the version number of the Embedder C-API.
  static size_t GetEmbedderVersion();

  /// @brief Checks whether the Embedder C-API rollout flag is active.
  static bool IsEmbedderEnabled();

  /// @brief Sets the Embedder C-API rollout flag.
  static void SetEmbedderEnabled(bool enabled);

  /// @brief Creates a default JniRouter instance with an injected JvmInvoker.
  static std::shared_ptr<JniRouter> CreateDefaultRouter(
      std::shared_ptr<JvmInvoker> invoker,
      std::shared_ptr<LegacyJniDelegate> legacy_delegate = nullptr);

  /// @brief Returns the JniRouter managed by this native instance.
  std::shared_ptr<JniRouter> GetRouter() const;

  /// @brief Returns the JniDelegate managed by this native instance.
  std::shared_ptr<JniDelegate> GetJniDelegate() const;

  /// @brief Returns the JvmInvoker managed by this native instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  std::shared_ptr<JniRouter> jni_router_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
