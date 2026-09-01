// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_

#include <cstddef>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "flutter/assets/asset_resolver.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

#if defined(__ANDROID__)
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"
#else
// Host-safe forward declarations for desktop / CI test builds
typedef struct _JNIEnv JNIEnv;
typedef void* jobject;
struct AAsset;
struct AAssetManager;
#endif

namespace flutter {

/// @brief Internal interface for Android APK asset provider implementations.
class APKAssetProviderInternal {
 public:
  virtual ~APKAssetProviderInternal() = default;

  /// @brief Resolves an asset by name into a memory mapping.
  virtual std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const = 0;

  /// @brief Resolves multiple assets matching a pattern in an optional
  /// subdirectory.
  virtual std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const {
    return {};
  }

  /// @brief Returns the base asset directory path.
  virtual const std::string& GetDirectory() const = 0;
};

/// @brief In-memory / host-safe implementation of APKAssetProviderInternal.
///
/// Enables host testing, mock injection, and Embedder C-API asset resolution
/// without requiring a live Android device or NDK AAssetManager.
class InMemoryAPKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  explicit InMemoryAPKAssetProviderImpl(
      std::string directory = "flutter_assets");
  ~InMemoryAPKAssetProviderImpl() override;

  /// @brief Adds an in-memory asset with the specified payload.
  void AddAsset(const std::string& asset_name, std::vector<uint8_t> data);

  /// @brief Adds an in-memory asset with the specified string content.
  void AddAsset(const std::string& asset_name, const std::string& data);

  /// @brief Removes an asset from the in-memory provider.
  void RemoveAsset(const std::string& asset_name);

  /// @brief Clears all assets from the in-memory provider.
  void ClearAssets();

  // |APKAssetProviderInternal|
  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override;

  // |APKAssetProviderInternal|
  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const override;

  // |APKAssetProviderInternal|
  const std::string& GetDirectory() const override;

 private:
  std::string directory_;
  std::map<std::string, std::vector<uint8_t>> assets_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAPKAssetProviderImpl);
};

/// @brief Memory mapping wrapper for an Android APK asset (`AAsset`).
class APKAssetMapping : public fml::Mapping {
 public:
  explicit APKAssetMapping(AAsset* asset);
  explicit APKAssetMapping(std::vector<uint8_t> memory_data);
  ~APKAssetMapping() override;

  size_t GetSize() const override;
  const uint8_t* GetMapping() const override;
  bool IsDontNeedSafe() const override;

 private:
  [[maybe_unused]] AAsset* const asset_;
  mutable std::vector<uint8_t> buffer_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetMapping);
};

/// @brief AssetResolver implementation that resolves assets from an Android APK
/// via AAssetManager or an injected provider implementation.
class APKAssetProvider final : public AssetResolver {
 public:
  explicit APKAssetProvider(JNIEnv* env,
                            jobject assetManager,
                            std::string directory);

  explicit APKAssetProvider(std::shared_ptr<APKAssetProviderInternal> impl);

  ~APKAssetProvider() override;

  /// @brief Returns a new `std::unique_ptr<APKAssetProvider>` sharing the same
  /// underlying implementation.
  std::unique_ptr<APKAssetProvider> Clone() const;

  /// @brief Returns a raw pointer to the internal implementation (intended for
  /// tests). Callers must not delete the returned pointer.
  APKAssetProviderInternal* GetImpl() const { return impl_.get(); }

  /// @brief Returns the base asset directory path.
  const std::string& GetDirectory() const;

  // |AssetResolver|
  bool operator==(const AssetResolver& other) const override;

  // |AssetResolver|
  bool IsValid() const override;

  // |AssetResolver|
  bool IsValidAfterAssetManagerChange() const override;

  // |AssetResolver|
  AssetResolver::AssetResolverType GetType() const override;

  // |AssetResolver|
  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override;

  // |AssetResolver|
  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const override;

  // |AssetResolver|
  const APKAssetProvider* as_apk_asset_provider() const override {
    return this;
  }

 private:
  std::shared_ptr<APKAssetProviderInternal> impl_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetProvider);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_
