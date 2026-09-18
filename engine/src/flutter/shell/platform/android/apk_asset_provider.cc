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

namespace {

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
  if (clean_dir.empty()) {
    return clean_asset;
  }
  if (clean_asset.rfind(clean_dir + "/", 0) == 0) {
    return clean_asset;
  }
  return clean_dir + "/" + clean_asset;
}

AAsset* OpenAssetWithFallbacks(AAssetManager* asset_manager,
                               const std::string& directory,
                               const std::string& asset_name) {
  if (!asset_manager) {
    return nullptr;
  }
  std::string full_path = NormalizeAssetPath(directory, asset_name);
  AAsset* asset =
      AAssetManager_open(asset_manager, full_path.c_str(), AASSET_MODE_BUFFER);
  if (!asset) {
    std::string clean_asset = asset_name;
    while (!clean_asset.empty() && clean_asset.front() == '/') {
      clean_asset.erase(0, 1);
    }
    if (full_path.rfind("flutter_assets/", 0) != 0) {
      std::string fallback_path = "flutter_assets/" + clean_asset;
      asset = AAssetManager_open(asset_manager, fallback_path.c_str(),
                                 AASSET_MODE_BUFFER);
    } else if (clean_asset.rfind("flutter_assets/", 0) == 0 &&
               clean_asset.length() > 15) {
      std::string stripped = clean_asset.substr(15);
      asset = AAssetManager_open(asset_manager, stripped.c_str(),
                                 AASSET_MODE_BUFFER);
    }
    if (!asset && full_path != clean_asset) {
      asset = AAssetManager_open(asset_manager, clean_asset.c_str(),
                                 AASSET_MODE_BUFFER);
    }
  }
  return asset;
}

}  // namespace

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
    AAsset* asset =
        OpenAssetWithFallbacks(asset_manager_, directory_, asset_name);
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

FlutterAssetResolver APKAssetProviderInternal::ToFlutterAssetResolver() const {
  struct InternalContext {
    std::shared_ptr<const APKAssetProviderInternal> internal;
  };
  auto* context = new InternalContext{shared_from_this()};

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = context;
  resolver.find_asset_callback = [](void* user_data, const char* asset_name,
                                    FlutterAsset* asset_out) -> bool {
    if (!user_data || !asset_name || !asset_out) {
      return false;
    }
    auto* ctx = static_cast<InternalContext*>(user_data);
    auto mapping = ctx->internal->GetAsMapping(asset_name);
    if (!mapping) {
      return false;
    }
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = mapping->GetMapping();
    asset_out->size = mapping->GetSize();
    asset_out->user_data = mapping.release();
    asset_out->asset_free_callback = [](void* user_data) {
      if (user_data) {
        delete static_cast<fml::Mapping*>(user_data);
      }
    };
    return true;
  };
  resolver.is_valid_callback = [](void* user_data) -> bool {
    return user_data != nullptr;
  };
  resolver.is_valid_after_change_callback = [](void* user_data) -> bool {
    return true;
  };
  resolver.destruction_callback = [](void* user_data) {
    if (user_data) {
      delete static_cast<InternalContext*>(user_data);
    }
  };
  return resolver;
}

FlutterAssetResolver APKAssetProvider::ToFlutterAssetResolver() const {
  if (impl_) {
    return impl_->ToFlutterAssetResolver();
  }
  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  return resolver;
}

FlutterAssetResolver APKAssetProvider::CreateFlutterAssetResolver(
    JNIEnv* env,
    jobject asset_manager,
    std::string directory) {
  auto impl = std::make_shared<APKAssetProviderImpl>(env, asset_manager,
                                                     std::move(directory));
  return impl->ToFlutterAssetResolver();
}

FlutterAssetResolver APKAssetProvider::CreateFlutterAssetResolver(
    AAssetManager* asset_manager,
    std::string directory) {
  struct DirectContext {
    AAssetManager* asset_manager;
    std::string directory;
  };
  auto* context = new DirectContext{asset_manager, std::move(directory)};

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = context;
  resolver.find_asset_callback = [](void* user_data, const char* asset_name,
                                    FlutterAsset* asset_out) -> bool {
    if (!user_data || !asset_name || !asset_out) {
      return false;
    }
    auto* ctx = static_cast<DirectContext*>(user_data);
    if (!ctx->asset_manager) {
      return false;
    }
    AAsset* asset =
        OpenAssetWithFallbacks(ctx->asset_manager, ctx->directory, asset_name);
    if (!asset) {
      return false;
    }
    const void* buffer = AAsset_getBuffer(asset);
    off_t length = AAsset_getLength(asset);
    if (!buffer && length > 0) {
      AAsset_close(asset);
      return false;
    }
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = static_cast<const uint8_t*>(buffer);
    asset_out->size = static_cast<size_t>(length);
    asset_out->user_data = asset;
    asset_out->asset_free_callback = [](void* user_data) {
      if (user_data) {
        AAsset_close(static_cast<AAsset*>(user_data));
      }
    };
    return true;
  };
  resolver.is_valid_callback = [](void* user_data) -> bool {
    if (!user_data) {
      return false;
    }
    auto* ctx = static_cast<DirectContext*>(user_data);
    return ctx->asset_manager != nullptr;
  };
  resolver.is_valid_after_change_callback = [](void* user_data) -> bool {
    return true;
  };
  resolver.destruction_callback = [](void* user_data) {
    if (user_data) {
      delete static_cast<DirectContext*>(user_data);
    }
  };
  return resolver;
}

}  // namespace flutter
