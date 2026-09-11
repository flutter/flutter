// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <string>
#include <vector>

#include "flutter/assets/asset_resolver.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

#include <jni.h>

#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"

#if defined(__cplusplus)
extern "C" {
#endif

/// @brief Asset descriptor passed across the Embedder C-ABI.
typedef struct {
  /// The size of this struct. Must be sizeof(FlutterAsset).
  size_t struct_size;
  /// Pointer to the asset data buffer.
  const uint8_t* data;
  /// Size of the asset data buffer in bytes.
  size_t size;
  /// User data associated with the asset for destruction callback.
  void* user_data;
  /// Callback invoked when the engine or embedder has finished using the asset.
  void (*asset_free_callback)(void* user_data);
#if UINTPTR_MAX == 0xffffffff
  /// Padding to enforce 8-byte natural alignment across 32-bit architectures.
  uint32_t reserved_padding;
#endif
} FlutterAsset;

/// @brief Custom asset resolver bridge structure for embedder integration.
typedef struct {
  /// The size of this struct. Must be sizeof(FlutterCustomAssetResolver).
  size_t struct_size;
  /// User data passed to all callbacks.
  void* user_data;
  /// Callback invoked to find and map an asset by name.
  bool (*find_asset_callback)(void* user_data,
                              const char* asset_name,
                              FlutterAsset* asset_out);
  /// Callback invoked to check whether this resolver is currently valid.
  bool (*is_valid_callback)(void* user_data);
  /// Callback invoked to check whether this resolver is valid after asset
  /// manager change.
  bool (*is_valid_after_change_callback)(void* user_data);
  /// Callback invoked when the custom resolver is destroyed.
  void (*destruction_callback)(void* user_data);
} FlutterCustomAssetResolver;

#if defined(__cplusplus)
}  // extern "C"
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
  const std::string directory_;
  mutable std::shared_mutex mutex_;
  std::map<std::string, std::shared_ptr<const std::vector<uint8_t>>> assets_;

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
  mutable std::mutex stream_mutex_;
  mutable std::vector<uint8_t> buffer_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetMapping);
};

/// @brief AssetResolver implementation that wraps a FlutterCustomAssetResolver
/// bridge for the C-API embedder engine.
class CustomAssetResolverAdapter final : public AssetResolver {
 public:
  explicit CustomAssetResolverAdapter(FlutterCustomAssetResolver resolver);
  ~CustomAssetResolverAdapter() override;

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

 private:
  FlutterCustomAssetResolver resolver_;

  FML_DISALLOW_COPY_AND_ASSIGN(CustomAssetResolverAdapter);
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

  /// @brief Creates a FlutterCustomAssetResolver bridge structure compatible
  /// with the embedder C-API.
  FlutterCustomAssetResolver CreateCustomAssetResolver() const;

  /// @brief Factory creating an AssetResolver from a
  /// FlutterCustomAssetResolver.
  static std::unique_ptr<AssetResolver> CreateAssetResolver(
      FlutterCustomAssetResolver resolver);

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
