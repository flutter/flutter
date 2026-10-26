// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"

#include <unistd.h>
#include <algorithm>
#include <sstream>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

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

[[maybe_unused]] std::string NormalizeAssetPath(const std::string& dir,
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

class APKAssetProviderImpl final : public APKAssetProviderInternal {
 public:
  explicit APKAssetProviderImpl(JNIEnv* env,
                                jobject jasset_manager,
                                std::string directory)
      : directory_(std::move(directory)) {
    APKAssetProviderImpl::UpdateAssetManager(env, jasset_manager, directory_);
  }

  ~APKAssetProviderImpl() override = default;

  void UpdateAssetManager(JNIEnv* env,
                          jobject jasset_manager,
                          const std::string& directory) override {
    std::unique_lock<std::shared_mutex> lock(mutex_);
    directory_ = directory;
    if (env != nullptr && jasset_manager != nullptr) {
      java_asset_manager_.Reset(env, jasset_manager);
#if FML_OS_ANDROID
      asset_manager_.store(AAssetManager_fromJava(env, jasset_manager),
                           std::memory_order_release);
#else
      asset_manager_.store(reinterpret_cast<AAssetManager*>(jasset_manager),
                           std::memory_order_release);
#endif
    } else {
      java_asset_manager_.Reset();
      asset_manager_.store(nullptr, std::memory_order_release);
    }
  }

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override {
    std::shared_lock<std::shared_mutex> lock(mutex_);
    AAssetManager* mgr = asset_manager_.load(std::memory_order_acquire);
    if (mgr == nullptr) {
      return nullptr;
    }
#if FML_OS_ANDROID
    std::string full_path = NormalizeAssetPath(directory_, asset_name);
    AAsset* asset =
        AAssetManager_open(mgr, full_path.c_str(), AASSET_MODE_BUFFER);
    if (!asset) {
      return nullptr;
    }
    return std::make_unique<APKAssetMapping>(asset);
#else
    return nullptr;
#endif
  }

  std::vector<std::unique_ptr<fml::Mapping>> GetAsMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir) const override {
    std::shared_lock<std::shared_mutex> lock(mutex_);
    std::vector<std::unique_ptr<fml::Mapping>> mappings;
    AAssetManager* mgr = asset_manager_.load(std::memory_order_acquire);
    if (mgr == nullptr) {
      return mappings;
    }
#if FML_OS_ANDROID
    std::string dir_path = directory_;
    if (subdir.has_value() && !subdir.value().empty()) {
      dir_path = NormalizeAssetPath(directory_, subdir.value());
    }
    AAssetDir* asset_dir = AAssetManager_openDir(mgr, dir_path.c_str());
    if (!asset_dir) {
      return mappings;
    }
    const char* file_name = nullptr;
    while ((file_name = AAssetDir_getNextFileName(asset_dir)) != nullptr) {
      std::string name_str(file_name);
      if (!asset_pattern.empty() && asset_pattern != "*" &&
          name_str.find(asset_pattern) == std::string::npos) {
        continue;
      }
      std::string rel_path = subdir.has_value() && !subdir.value().empty()
                                 ? NormalizeAssetPath(subdir.value(), name_str)
                                 : name_str;
      std::string full_path = NormalizeAssetPath(directory_, rel_path);
      AAsset* asset =
          AAssetManager_open(mgr, full_path.c_str(), AASSET_MODE_BUFFER);
      if (asset) {
        mappings.push_back(std::make_unique<APKAssetMapping>(asset));
      }
    }
    AAssetDir_close(asset_dir);
#endif
    return mappings;
  }

  const std::string& GetDirectory() const override {
    std::shared_lock<std::shared_mutex> lock(mutex_);
    return directory_;
  }

 private:
  mutable std::shared_mutex mutex_;
  fml::jni::ScopedJavaGlobalRef<jobject> java_asset_manager_;
  std::atomic<AAssetManager*> asset_manager_{nullptr};
  std::string directory_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetProviderImpl);
};

}  // namespace

APKAssetMapping::APKAssetMapping(AAsset* asset) : asset_(asset) {
  TRACE_EVENT0("flutter", "APKAssetMapping::APKAssetMapping");
}

APKAssetMapping::APKAssetMapping(std::vector<uint8_t> memory_data)
    : buffer_(std::move(memory_data)) {
  TRACE_EVENT0("flutter", "APKAssetMapping::APKAssetMapping(memory)");
}

APKAssetMapping::~APKAssetMapping() {
  TRACE_EVENT0("flutter", "APKAssetMapping::~APKAssetMapping");
#if FML_OS_ANDROID
  if (asset_) {
    AAsset_close(asset_);
  }
#else
  (void)asset_;
#endif
}

size_t APKAssetMapping::GetSize() const {
#if FML_OS_ANDROID
  if (asset_) {
    off64_t len = AAsset_getLength64(asset_);
    return len > 0 ? static_cast<size_t>(len) : 0;
  }
#endif
  return buffer_.size();
}

const uint8_t* APKAssetMapping::GetMapping() const {
  TRACE_EVENT0("flutter", "APKAssetMapping::GetMapping");
#if FML_OS_ANDROID
  if (asset_) {
    const void* buf = AAsset_getBuffer(asset_);
    if (buf) {
      return reinterpret_cast<const uint8_t*>(buf);
    }
    std::lock_guard<std::mutex> lock(stream_mutex_);
    if (buffer_.empty()) {
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
  return buffer_.empty() ? nullptr : buffer_.data();
}

bool APKAssetMapping::IsDontNeedSafe() const {
#if FML_OS_ANDROID
  if (asset_) {
    return !AAsset_isAllocated(asset_);
  }
#endif
  return true;
}

InMemoryAPKAssetProviderImpl::InMemoryAPKAssetProviderImpl(
    std::string directory)
    : directory_(std::move(directory)) {}

InMemoryAPKAssetProviderImpl::~InMemoryAPKAssetProviderImpl() = default;

void InMemoryAPKAssetProviderImpl::AddAsset(const std::string& asset_name,
                                            std::vector<uint8_t> data) {
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_[asset_name] =
      std::make_shared<const std::vector<uint8_t>>(std::move(data));
}

void InMemoryAPKAssetProviderImpl::AddAsset(const std::string& asset_name,
                                            const std::string& data) {
  AddAsset(asset_name, std::vector<uint8_t>(data.begin(), data.end()));
}

void InMemoryAPKAssetProviderImpl::RemoveAsset(const std::string& asset_name) {
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_.erase(asset_name);
}

void InMemoryAPKAssetProviderImpl::ClearAssets() {
  std::unique_lock<std::shared_mutex> lock(mutex_);
  assets_.clear();
}

std::unique_ptr<fml::Mapping> InMemoryAPKAssetProviderImpl::GetAsMapping(
    const std::string& asset_name) const {
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
  std::shared_lock<std::shared_mutex> lock(mutex_);
  std::vector<std::unique_ptr<fml::Mapping>> results;
  std::string prefix =
      subdir.has_value() && !subdir.value().empty() ? subdir.value() + "/" : "";
  for (const auto& [name, data] : assets_) {
    if (!prefix.empty()) {
      if (name.rfind(prefix, 0) != 0) {
        continue;
      }
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
  std::shared_lock<std::shared_mutex> lock(mutex_);
  return directory_;
}

void InMemoryAPKAssetProviderImpl::UpdateAssetManager(
    JNIEnv* env,
    jobject jasset_manager,
    const std::string& directory) {
  std::unique_lock<std::shared_mutex> lock(mutex_);
  directory_ = directory;
}

APKAssetProvider::APKAssetProvider()
    : impl_(std::make_shared<InMemoryAPKAssetProviderImpl>()) {}

APKAssetProvider::APKAssetProvider(JNIEnv* env,
                                   jobject asset_manager,
                                   std::string directory)
    : impl_(std::make_shared<APKAssetProviderImpl>(env,
                                                   asset_manager,
                                                   std::move(directory))) {}

APKAssetProvider::APKAssetProvider(
    std::shared_ptr<APKAssetProviderInternal> impl)
    : impl_(std::move(impl)) {}

APKAssetProvider::~APKAssetProvider() = default;

bool APKAssetProvider::IsValid() const {
  return impl_ != nullptr;
}

bool APKAssetProvider::IsValidAfterAssetManagerChange() const {
  return true;
}

std::unique_ptr<fml::Mapping> APKAssetProvider::GetAsMapping(
    const std::string& asset_name) const {
  if (!impl_) {
    return nullptr;
  }
  return impl_->GetAsMapping(asset_name);
}

std::vector<std::unique_ptr<fml::Mapping>> APKAssetProvider::GetAsMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  if (!impl_) {
    return {};
  }
  return impl_->GetAsMappings(asset_pattern, subdir);
}

const std::string& APKAssetProvider::GetDirectory() const {
  if (!impl_) {
    static const std::string kEmpty;
    return kEmpty;
  }
  return impl_->GetDirectory();
}

void APKAssetProvider::UpdateAssetManager(JNIEnv* env,
                                          jobject asset_manager,
                                          const std::string& directory) {
  if (impl_) {
    impl_->UpdateAssetManager(env, asset_manager, directory);
  }
}

std::unique_ptr<APKAssetProvider> APKAssetProvider::Clone() const {
  return std::make_unique<APKAssetProvider>(impl_);
}

FlutterCustomAssetResolver APKAssetProvider::CreateCustomAssetResolver() const {
  FlutterCustomAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterCustomAssetResolver);
  auto* holder = new std::shared_ptr<APKAssetProviderInternal>(impl_);
  resolver.user_data = holder;
  resolver.get_as_mapping_callback =
      [](const char* asset_name, void* user_data,
         FlutterAssetMapping* mapping_out) -> bool {
    if (!asset_name || !user_data || !mapping_out) {
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
    mapping_out->struct_size = sizeof(FlutterAssetMapping);
    mapping_out->mapping = mapping->GetMapping();
    mapping_out->mapping_size = mapping->GetSize();
    mapping_out->user_data = mapping.release();
    mapping_out->destruction_callback = [](void* mapping_ptr) {
      delete static_cast<fml::Mapping*>(mapping_ptr);
    };
    return true;
  };
  resolver.destruction_callback = [](void* user_data) {
    delete static_cast<std::shared_ptr<APKAssetProviderInternal>*>(user_data);
  };
  return resolver;
}

}  // namespace flutter
