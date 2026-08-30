// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstddef>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

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
  mutable std::mutex mutex_;
  std::map<int64_t, DartCallbackInfo> cache_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryCallbackCacheProvider);
};

/// @brief Quarantined native entry point and manager for the Android C-API
/// Embedder.
///
/// This class enforces strict GN and C-ABI isolation from legacy Skia /
/// internal UI headers, serving as the foundational shield for Phase 1 & 2 of
/// the Android embedder migration.
class FlutterEmbedderNative {
 public:
  FlutterEmbedderNative();
  explicit FlutterEmbedderNative(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr,
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr,
      std::shared_ptr<APKAssetProvider> asset_provider = nullptr,
      std::shared_ptr<CallbackCacheProvider> callback_cache = nullptr);
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

  /// @brief Sets the default global OSLibraryLoader instance.
  static void SetDefaultLibraryLoader(std::shared_ptr<OSLibraryLoader> loader);

  /// @brief Returns the default global OSLibraryLoader instance.
  static std::shared_ptr<OSLibraryLoader> GetDefaultLibraryLoader();

  /// @brief Creates a default JniRouter instance with an injected JvmInvoker.
  static std::shared_ptr<JniRouter> CreateDefaultRouter(
      std::shared_ptr<JvmInvoker> invoker,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr);

  /// @brief Returns the JniRouter managed by this native instance.
  std::shared_ptr<JniRouter> GetRouter() const;

  /// @brief Returns the JniDelegate managed by this native instance.
  std::shared_ptr<JniDelegate> GetJniDelegate() const;

  /// @brief Returns the JvmInvoker managed by this native instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

  /// @brief Returns the OSLibraryLoader managed by this native instance.
  std::shared_ptr<OSLibraryLoader> GetLibraryLoader() const;

  /// @brief Returns the APKAssetProvider managed by this native instance.
  std::shared_ptr<APKAssetProvider> GetAssetProvider() const;

  /// @brief Sets or replaces the APKAssetProvider managed by this native
  /// instance.
  void SetAssetProvider(std::shared_ptr<APKAssetProvider> provider);

  /// @brief Resolves an asset by name using the managed asset provider.
  std::unique_ptr<fml::Mapping> ResolveAsset(
      const std::string& asset_name) const;

  /// @brief Resolves asset mappings by pattern and optional subdirectory.
  std::vector<std::unique_ptr<fml::Mapping>> ResolveAssetMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir = std::nullopt) const;

  /// @brief Returns the CallbackCacheProvider managed by this native instance.
  std::shared_ptr<CallbackCacheProvider> GetCallbackCache() const;

  /// @brief Sets or replaces the CallbackCacheProvider managed by this native
  /// instance.
  void SetCallbackCache(std::shared_ptr<CallbackCacheProvider> provider);

  /// @brief Looks up Dart callback information for a given callback handle.
  std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle) const;

 private:
  static std::shared_ptr<OSLibraryLoader> default_library_loader_;

  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  std::shared_ptr<JniRouter> jni_router_;
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::shared_ptr<APKAssetProvider> asset_provider_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
