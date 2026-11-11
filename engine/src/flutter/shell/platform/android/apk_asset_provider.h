// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_

#include <jni.h>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if FML_OS_ANDROID
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#else
struct AAsset;
struct AAssetManager;
#endif

namespace flutter {

class APKAssetMapping : public fml::Mapping {
 public:
  explicit APKAssetMapping(AAsset* asset);
  explicit APKAssetMapping(std::vector<uint8_t> memory_data);
  ~APKAssetMapping() override;

  size_t GetSize() const override;
  const uint8_t* GetMapping() const override;
  bool IsDontNeedSafe() const override;

 private:
  AAsset* const asset_ = nullptr;
  mutable std::mutex stream_mutex_;
  mutable std::vector<uint8_t> buffer_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetMapping);
};

class APKAssetProviderInternal {
 public:
  virtual ~APKAssetProviderInternal() = default;

  virtual std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const = 0;

  virtual std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const {
    return {};
  }

  virtual const std::string& GetDirectory() const {
    static const std::string kEmpty;
    return kEmpty;
  }

  virtual void UpdateAssetManager(JNIEnv* env,
                                  jobject jasset_manager,
                                  const std::string& directory) {}
};

class InMemoryAPKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  explicit InMemoryAPKAssetProviderImpl(std::string directory = "");
  ~InMemoryAPKAssetProviderImpl() override;

  void AddAsset(const std::string& asset_name, std::vector<uint8_t> data);
  void AddAsset(const std::string& asset_name, const std::string& data);
  void RemoveAsset(const std::string& asset_name);
  void ClearAssets();

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override;

  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const override;

  const std::string& GetDirectory() const override;

  void UpdateAssetManager(JNIEnv* env,
                          jobject jasset_manager,
                          const std::string& directory) override;

 private:
  mutable std::shared_mutex mutex_;
  std::string directory_;
  std::unordered_map<std::string, std::shared_ptr<const std::vector<uint8_t>>>
      assets_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAPKAssetProviderImpl);
};

class APKAssetProvider final {
 public:
  APKAssetProvider();

  explicit APKAssetProvider(JNIEnv* env,
                            jobject asset_manager,
                            std::string directory);

  explicit APKAssetProvider(std::shared_ptr<APKAssetProviderInternal> impl);

  ~APKAssetProvider();

  bool IsValid() const;
  bool IsValidAfterAssetManagerChange() const;

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const;

  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir = std::nullopt) const;

  const std::string& GetDirectory() const;

  // Atomically swaps the underlying AAssetManager* and asset bundle directory
  // in place so any active FlutterCustomAssetResolver user_data immediately
  // resolves assets from the updated AssetManager.
  void UpdateAssetManager(JNIEnv* env,
                          jobject asset_manager,
                          const std::string& directory);

  void UpdateJavaAssetManager(JNIEnv* env,
                              jobject asset_manager,
                              const std::string& directory) {
    UpdateAssetManager(env, asset_manager, directory);
  }

  std::unique_ptr<APKAssetProvider> Clone() const;

  FlutterCustomAssetResolver CreateCustomAssetResolver() const;

  APKAssetProviderInternal* GetImpl() const { return impl_.get(); }

  bool operator==(const APKAssetProvider& other) const {
    return impl_ == other.impl_;
  }

  bool operator!=(const APKAssetProvider& other) const {
    return !(*this == other);
  }

 private:
  std::shared_ptr<APKAssetProviderInternal> impl_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetProvider);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_APK_ASSET_PROVIDER_H_
