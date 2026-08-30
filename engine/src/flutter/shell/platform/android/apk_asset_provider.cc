// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"

#include <algorithm>
#include <sstream>
#include <utility>

#include "flutter/assets/asset_resolver.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

// =============================================================================
// APKAssetMapping Implementation
// =============================================================================

APKAssetMapping::APKAssetMapping(AAsset* asset) : asset_(asset) {
  TRACE_EVENT0("flutter", "APKAssetMapping::APKAssetMapping");
}

APKAssetMapping::APKAssetMapping(std::vector<uint8_t> memory_data)
    : asset_(nullptr), buffer_(std::move(memory_data)) {
  TRACE_EVENT0("flutter", "APKAssetMapping::APKAssetMapping(memory)");
}

APKAssetMapping::~APKAssetMapping() {
  TRACE_EVENT0("flutter", "APKAssetMapping::~APKAssetMapping");
#if defined(__ANDROID__)
  if (asset_) {
    AAsset_close(asset_);
  }
#endif
}

size_t APKAssetMapping::GetSize() const {
  TRACE_EVENT0("flutter", "APKAssetMapping::GetSize");
#if defined(__ANDROID__)
  if (asset_) {
    return AAsset_getLength(asset_);
  }
#endif
  return buffer_.size();
}

const uint8_t* APKAssetMapping::GetMapping() const {
  TRACE_EVENT0("flutter", "APKAssetMapping::GetMapping");
#if defined(__ANDROID__)
  if (asset_) {
    const void* buf = AAsset_getBuffer(asset_);
    if (buf) {
      return reinterpret_cast<const uint8_t*>(buf);
    }
    // Fallback stream reading for compressed assets
    if (buffer_.empty()) {
      TRACE_EVENT0("flutter", "APKAssetMapping::StreamRead");
      size_t length = AAsset_getLength(asset_);
      if (length > 0) {
        buffer_.resize(length);
        AAsset_seek(asset_, 0, SEEK_SET);
        int bytes_read = AAsset_read(asset_, buffer_.data(), length);
        if (bytes_read < 0) {
          buffer_.clear();
          return nullptr;
        }
      }
    }
    return buffer_.data();
  }
#endif
  return buffer_.data();
}

bool APKAssetMapping::IsDontNeedSafe() const {
#if defined(__ANDROID__)
  if (asset_) {
    return !AAsset_isAllocated(asset_);
  }
#endif
  return true;
}

// =============================================================================
// InMemoryAPKAssetProviderImpl Implementation
// =============================================================================

InMemoryAPKAssetProviderImpl::InMemoryAPKAssetProviderImpl(
    std::string directory)
    : directory_(std::move(directory)) {
  TRACE_EVENT0("flutter",
               "InMemoryAPKAssetProviderImpl::InMemoryAPKAssetProviderImpl");
}

InMemoryAPKAssetProviderImpl::~InMemoryAPKAssetProviderImpl() {
  TRACE_EVENT0("flutter",
               "InMemoryAPKAssetProviderImpl::~InMemoryAPKAssetProviderImpl");
}

void InMemoryAPKAssetProviderImpl::AddAsset(const std::string& asset_name,
                                            std::vector<uint8_t> data) {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::AddAsset", "name",
               asset_name.c_str());
  assets_[asset_name] = std::move(data);
}

void InMemoryAPKAssetProviderImpl::AddAsset(const std::string& asset_name,
                                            const std::string& data) {
  AddAsset(asset_name, std::vector<uint8_t>(data.begin(), data.end()));
}

void InMemoryAPKAssetProviderImpl::RemoveAsset(const std::string& asset_name) {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::RemoveAsset", "name",
               asset_name.c_str());
  assets_.erase(asset_name);
}

void InMemoryAPKAssetProviderImpl::ClearAssets() {
  TRACE_EVENT0("flutter", "InMemoryAPKAssetProviderImpl::ClearAssets");
  assets_.clear();
}

std::unique_ptr<fml::Mapping> InMemoryAPKAssetProviderImpl::GetAsMapping(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::GetAsMapping", "name",
               asset_name.c_str());
  auto it = assets_.find(asset_name);
  if (it == assets_.end()) {
    return nullptr;
  }
  return std::make_unique<fml::DataMapping>(it->second);
}

std::vector<std::unique_ptr<fml::Mapping>>
InMemoryAPKAssetProviderImpl::GetAsMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::GetAsMappings",
               "pattern", asset_pattern.c_str());
  std::vector<std::unique_ptr<fml::Mapping>> results;
  std::string prefix =
      subdir.has_value() && !subdir.value().empty() ? subdir.value() + "/" : "";
  for (const auto& [name, data] : assets_) {
    if (!prefix.empty() && name.rfind(prefix, 0) != 0) {
      continue;
    }
    if (asset_pattern.empty() || asset_pattern == "*" ||
        name.find(asset_pattern) != std::string::npos) {
      results.push_back(std::make_unique<fml::DataMapping>(data));
    }
  }
  return results;
}

const std::string& InMemoryAPKAssetProviderImpl::GetDirectory() const {
  TRACE_EVENT0("flutter", "InMemoryAPKAssetProviderImpl::GetDirectory");
  return directory_;
}

// =============================================================================
// APKAssetProviderImpl Implementation
// =============================================================================

#if defined(__ANDROID__)
class APKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  explicit APKAssetProviderImpl(JNIEnv* env,
                                jobject jassetManager,
                                std::string directory)
      : java_asset_manager_(env, jassetManager),
        directory_(std::move(directory)) {
    asset_manager_ = env && jassetManager
                         ? AAssetManager_fromJava(env, jassetManager)
                         : nullptr;
  }

  ~APKAssetProviderImpl() override = default;

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override {
    TRACE_EVENT1("flutter", "APKAssetProviderImpl::GetAsMapping", "name",
                 asset_name.c_str());
    if (!asset_manager_) {
      return nullptr;
    }
    std::stringstream ss;
    if (!directory_.empty()) {
      ss << directory_ << "/";
    }
    ss << asset_name;
    AAsset* asset = AAssetManager_open(asset_manager_, ss.str().c_str(),
                                       AASSET_MODE_BUFFER);
    if (!asset) {
      return nullptr;
    }

    return std::make_unique<APKAssetMapping>(asset);
  }

  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const override {
    TRACE_EVENT1("flutter", "APKAssetProviderImpl::GetAsMappings", "pattern",
                 asset_pattern.c_str());
    std::vector<std::unique_ptr<fml::Mapping>> results;
    if (!asset_manager_) {
      return results;
    }
    std::string dir_to_open = directory_;
    if (subdir.has_value() && !subdir.value().empty()) {
      if (!dir_to_open.empty()) {
        dir_to_open += "/";
      }
      dir_to_open += subdir.value();
    }
    AAssetDir* asset_dir =
        AAssetManager_openDir(asset_manager_, dir_to_open.c_str());
    if (!asset_dir) {
      return results;
    }
    const char* filename = nullptr;
    while ((filename = AAssetDir_getNextFileName(asset_dir)) != nullptr) {
      std::string fname(filename);
      if (asset_pattern.empty() || asset_pattern == "*" ||
          fname.find(asset_pattern) != std::string::npos) {
        std::string rel_path = subdir.has_value() && !subdir.value().empty()
                                   ? subdir.value() + "/" + fname
                                   : fname;
        auto mapping = GetAsMapping(rel_path);
        if (mapping) {
          results.push_back(std::move(mapping));
        }
      }
    }
    AAssetDir_close(asset_dir);
    return results;
  }

  const std::string& GetDirectory() const override {
    TRACE_EVENT0("flutter", "APKAssetProviderImpl::GetDirectory");
    return directory_;
  }

 private:
  fml::jni::ScopedJavaGlobalRef<jobject> java_asset_manager_;
  AAssetManager* asset_manager_ = nullptr;
  const std::string directory_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetProviderImpl);
};
#else   // !defined(__ANDROID__)
class APKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  explicit APKAssetProviderImpl([[maybe_unused]] JNIEnv* env,
                                [[maybe_unused]] jobject jassetManager,
                                std::string directory)
      : directory_(std::move(directory)) {}

  ~APKAssetProviderImpl() override = default;

  std::unique_ptr<fml::Mapping> GetAsMapping(
      [[maybe_unused]] const std::string& asset_name) const override {
    TRACE_EVENT0("flutter",
                 "APKAssetProviderImpl::GetAsMapping (Host fallback)");
    return nullptr;
  }

  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      [[maybe_unused]] const std::string& asset_pattern,
      [[maybe_unused]] const std::optional<std::string>& subdir)
      const override {
    TRACE_EVENT0("flutter",
                 "APKAssetProviderImpl::GetAsMappings (Host fallback)");
    return {};
  }

  const std::string& GetDirectory() const override { return directory_; }

 private:
  const std::string directory_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetProviderImpl);
};
#endif  // defined(__ANDROID__)

// =============================================================================
// APKAssetProvider Implementation
// =============================================================================

APKAssetProvider::APKAssetProvider(JNIEnv* env,
                                   jobject assetManager,
                                   std::string directory)
    : impl_(std::make_shared<APKAssetProviderImpl>(env,
                                                   assetManager,
                                                   std::move(directory))) {
  TRACE_EVENT0("flutter", "APKAssetProvider::APKAssetProvider(JNI)");
}

APKAssetProvider::APKAssetProvider(
    std::shared_ptr<APKAssetProviderInternal> impl)
    : impl_(std::move(impl)) {
  TRACE_EVENT0("flutter", "APKAssetProvider::APKAssetProvider(impl)");
}

APKAssetProvider::~APKAssetProvider() {
  TRACE_EVENT0("flutter", "APKAssetProvider::~APKAssetProvider");
}

bool APKAssetProvider::IsValid() const {
  return true;
}

bool APKAssetProvider::IsValidAfterAssetManagerChange() const {
  return true;
}

AssetResolver::AssetResolverType APKAssetProvider::GetType() const {
  return AssetResolver::AssetResolverType::kApkAssetProvider;
}

std::unique_ptr<fml::Mapping> APKAssetProvider::GetAsMapping(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "APKAssetProvider::GetAsMapping", "name",
               asset_name.c_str());
  if (!impl_) {
    return nullptr;
  }
  return impl_->GetAsMapping(asset_name);
}

std::vector<std::unique_ptr<fml::Mapping>> APKAssetProvider::GetAsMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  TRACE_EVENT1("flutter", "APKAssetProvider::GetAsMappings", "pattern",
               asset_pattern.c_str());
  if (!impl_) {
    return {};
  }
  return impl_->GetAsMappings(asset_pattern, subdir);
}

const std::string& APKAssetProvider::GetDirectory() const {
  TRACE_EVENT0("flutter", "APKAssetProvider::GetDirectory");
  if (!impl_) {
    static const std::string kEmpty = "";
    return kEmpty;
  }
  return impl_->GetDirectory();
}

std::unique_ptr<APKAssetProvider> APKAssetProvider::Clone() const {
  TRACE_EVENT0("flutter", "APKAssetProvider::Clone");
  return std::make_unique<APKAssetProvider>(impl_);
}

bool APKAssetProvider::operator==(const AssetResolver& other) const {
  auto other_provider = other.as_apk_asset_provider();
  if (!other_provider) {
    return false;
  }
  return impl_ == other_provider->impl_;
}

}  // namespace flutter
