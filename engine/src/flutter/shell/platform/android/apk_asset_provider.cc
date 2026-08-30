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
// Helper Mappings & Path Normalization
// =============================================================================

namespace {

class SharedVectorMapping : public fml::Mapping {
 public:
  explicit SharedVectorMapping(std::shared_ptr<const std::vector<uint8_t>> data)
      : data_(std::move(data)) {}
  ~SharedVectorMapping() override = default;

  size_t GetSize() const override { return data_ ? data_->size() : 0; }
  const uint8_t* GetMapping() const override {
    return data_ && !data_->empty() ? data_->data() : nullptr;
  }
  bool IsDontNeedSafe() const override { return true; }

 private:
  std::shared_ptr<const std::vector<uint8_t>> data_;

  FML_DISALLOW_COPY_AND_ASSIGN(SharedVectorMapping);
};

class CustomAssetMapping : public fml::Mapping {
 public:
  explicit CustomAssetMapping(FlutterAsset asset) : asset_(asset) {}
  ~CustomAssetMapping() override {
    if (asset_.asset_free_callback) {
      asset_.asset_free_callback(asset_.user_data);
    }
  }

  size_t GetSize() const override { return asset_.size; }
  const uint8_t* GetMapping() const override { return asset_.data; }
  bool IsDontNeedSafe() const override { return true; }

 private:
  FlutterAsset asset_;

  FML_DISALLOW_COPY_AND_ASSIGN(CustomAssetMapping);
};

std::string NormalizeAssetPath(const std::string& dir,
                               const std::string& asset_name) {
  std::string clean_asset = asset_name;
  while (!clean_asset.empty() && clean_asset.front() == '/') {
    clean_asset.erase(0, 1);
  }
  std::string clean_dir = dir;
  while (!clean_dir.empty() && clean_dir.back() == '/') {
    clean_dir.pop_back();
  }
  while (!clean_dir.empty() && clean_dir.front() == '/') {
    clean_dir.erase(0, 1);
  }
  return clean_dir.empty() ? clean_asset : clean_dir + "/" + clean_asset;
}

}  // namespace

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
#if defined(__ANDROID__)
  if (asset_) {
    off64_t len = AAsset_getLength64(asset_);
    return len > 0 ? static_cast<size_t>(len) : 0;
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
    // Fallback stream reading for compressed assets under mutex lock
    std::lock_guard<std::mutex> lock(stream_mutex_);
    if (buffer_.empty()) {
      TRACE_EVENT0("flutter", "APKAssetMapping::StreamRead");
      off64_t length = AAsset_getLength64(asset_);
      if (length <= 0) {
        return nullptr;
      }
      buffer_.resize(static_cast<size_t>(length));
      AAsset_seek64(asset_, 0, SEEK_SET);
      size_t total_read = 0;
      while (total_read < static_cast<size_t>(length)) {
        int bytes_read = AAsset_read(asset_, buffer_.data() + total_read,
                                     static_cast<size_t>(length) - total_read);
        if (bytes_read <= 0) {
          buffer_.clear();
          return nullptr;
        }
        total_read += static_cast<size_t>(bytes_read);
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
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_[asset_name] =
      std::make_shared<const std::vector<uint8_t>>(std::move(data));
}

void InMemoryAPKAssetProviderImpl::AddAsset(const std::string& asset_name,
                                            const std::string& data) {
  AddAsset(asset_name, std::vector<uint8_t>(data.begin(), data.end()));
}

void InMemoryAPKAssetProviderImpl::RemoveAsset(const std::string& asset_name) {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::RemoveAsset", "name",
               asset_name.c_str());
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_.erase(asset_name);
}

void InMemoryAPKAssetProviderImpl::ClearAssets() {
  TRACE_EVENT0("flutter", "InMemoryAPKAssetProviderImpl::ClearAssets");
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_.clear();
}

std::unique_ptr<fml::Mapping> InMemoryAPKAssetProviderImpl::GetAsMapping(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::GetAsMapping", "name",
               asset_name.c_str());
  std::shared_lock<std::shared_mutex> lock(mutex_);
  auto it = assets_.find(asset_name);
  if (it == assets_.end()) {
    return nullptr;
  }
  return std::make_unique<SharedVectorMapping>(it->second);
}

std::vector<std::unique_ptr<fml::Mapping>>
InMemoryAPKAssetProviderImpl::GetAsMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  TRACE_EVENT1("flutter", "InMemoryAPKAssetProviderImpl::GetAsMappings",
               "pattern", asset_pattern.c_str());
  std::shared_lock<std::shared_mutex> lock(mutex_);
  std::vector<std::unique_ptr<fml::Mapping>> results;
  std::string prefix =
      subdir.has_value() && !subdir.value().empty() ? subdir.value() + "/" : "";
  for (const auto& [name, data] : assets_) {
    if (!prefix.empty()) {
      if (name.rfind(prefix, 0) != 0) {
        continue;
      }
      // Subdirectory specified -> flat search within subdirectory
      std::string rel_name = name.substr(prefix.length());
      if (rel_name.find('/') != std::string::npos) {
        continue;
      }
    }
    if (asset_pattern.empty() || asset_pattern == "*" ||
        name.find(asset_pattern) != std::string::npos) {
      results.push_back(std::make_unique<SharedVectorMapping>(data));
    }
  }
  return results;
}

const std::string& InMemoryAPKAssetProviderImpl::GetDirectory() const {
  return directory_;
}

// =============================================================================
// CustomAssetResolverAdapter Implementation
// =============================================================================

CustomAssetResolverAdapter::CustomAssetResolverAdapter(
    FlutterCustomAssetResolver resolver)
    : resolver_(resolver) {
  TRACE_EVENT0("flutter",
               "CustomAssetResolverAdapter::CustomAssetResolverAdapter");
}

CustomAssetResolverAdapter::~CustomAssetResolverAdapter() {
  TRACE_EVENT0("flutter",
               "CustomAssetResolverAdapter::~CustomAssetResolverAdapter");
  if (resolver_.destruction_callback) {
    resolver_.destruction_callback(resolver_.user_data);
  }
}

bool CustomAssetResolverAdapter::IsValid() const {
  if (resolver_.is_valid_callback) {
    return resolver_.is_valid_callback(resolver_.user_data);
  }
  return true;
}

bool CustomAssetResolverAdapter::IsValidAfterAssetManagerChange() const {
  if (resolver_.is_valid_after_change_callback) {
    return resolver_.is_valid_after_change_callback(resolver_.user_data);
  }
  return true;
}

AssetResolver::AssetResolverType CustomAssetResolverAdapter::GetType() const {
  return AssetResolver::AssetResolverType::kApkAssetProvider;
}

std::unique_ptr<fml::Mapping> CustomAssetResolverAdapter::GetAsMapping(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "CustomAssetResolverAdapter::GetAsMapping", "name",
               asset_name.c_str());
  if (!resolver_.find_asset_callback) {
    return nullptr;
  }
  FlutterAsset asset = {};
  asset.struct_size = sizeof(FlutterAsset);
  if (!resolver_.find_asset_callback(resolver_.user_data, asset_name.c_str(),
                                     &asset)) {
    return nullptr;
  }
  return std::make_unique<CustomAssetMapping>(asset);
}

std::vector<std::unique_ptr<fml::Mapping>>
CustomAssetResolverAdapter::GetAsMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  return {};
}

bool CustomAssetResolverAdapter::operator==(const AssetResolver& other) const {
  auto other_apk = other.as_apk_asset_provider();
  if (!other_apk) {
    return false;
  }
  return false;
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
    std::string full_path = NormalizeAssetPath(directory_, asset_name);
    AAsset* asset = AAssetManager_open(asset_manager_, full_path.c_str(),
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
      dir_to_open = NormalizeAssetPath(directory_, subdir.value());
    } else {
      while (!dir_to_open.empty() && dir_to_open.back() == '/') {
        dir_to_open.pop_back();
      }
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

  const std::string& GetDirectory() const override { return directory_; }

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

FlutterCustomAssetResolver APKAssetProvider::CreateCustomAssetResolver() const {
  TRACE_EVENT0("flutter", "APKAssetProvider::CreateCustomAssetResolver");
  FlutterCustomAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterCustomAssetResolver);
  auto* holder = new std::shared_ptr<APKAssetProviderInternal>(impl_);
  resolver.user_data = holder;
  resolver.find_asset_callback = [](void* user_data, const char* asset_name,
                                    FlutterAsset* asset_out) -> bool {
    if (!user_data || !asset_name || !asset_out) {
      return false;
    }
    auto* p_holder =
        static_cast<std::shared_ptr<APKAssetProviderInternal>*>(user_data);
    if (!p_holder || !(*p_holder)) {
      return false;
    }
    auto mapping = (*p_holder)->GetAsMapping(asset_name);
    if (!mapping) {
      return false;
    }
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = mapping->GetMapping();
    asset_out->size = mapping->GetSize();
    asset_out->user_data = mapping.release();
    asset_out->asset_free_callback = [](void* mapping_ptr) {
      if (mapping_ptr) {
        delete static_cast<fml::Mapping*>(mapping_ptr);
      }
    };
    return true;
  };
  resolver.is_valid_callback = [](void* user_data) -> bool {
    if (!user_data) {
      return false;
    }
    auto* p_holder =
        static_cast<std::shared_ptr<APKAssetProviderInternal>*>(user_data);
    return p_holder && (*p_holder);
  };
  resolver.is_valid_after_change_callback = [](void* user_data) -> bool {
    return true;
  };
  resolver.destruction_callback = [](void* user_data) {
    if (user_data) {
      delete static_cast<std::shared_ptr<APKAssetProviderInternal>*>(user_data);
    }
  };
  return resolver;
}

std::unique_ptr<AssetResolver> APKAssetProvider::CreateAssetResolver(
    FlutterCustomAssetResolver resolver) {
  return std::make_unique<CustomAssetResolverAdapter>(resolver);
}

bool APKAssetProvider::operator==(const AssetResolver& other) const {
  auto other_provider = other.as_apk_asset_provider();
  if (!other_provider) {
    return false;
  }
  return impl_ == other_provider->impl_;
}

}  // namespace flutter
