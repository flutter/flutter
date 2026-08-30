// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

std::shared_ptr<OSLibraryLoader>
    FlutterEmbedderNative::default_library_loader_ = nullptr;

DefaultCallbackCacheProvider::DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::DefaultCallbackCacheProvider");
}

DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider");
}

static FlutterEngineResult GetCallbackInformationFromEngine(
    int64_t handle,
    FlutterCallbackInformation* info) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.GetCallbackInformation) {
    return s_procs.GetCallbackInformation(handle, info);
  }
  return kInternalInconsistency;
}

std::optional<DartCallbackInfo>
DefaultCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::GetCallbackInformation");
  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  if (GetCallbackInformationFromEngine(handle, &info) == kSuccess) {
    DartCallbackInfo result;
    result.name = info.name ? info.name : "";
    result.class_name = info.class_name ? info.class_name : "";
    result.library_path = info.library_path ? info.library_path : "";
    return result;
  }
  return std::nullopt;
}

InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider");
}

InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider");
}

void InMemoryCallbackCacheProvider::AddCallback(
    int64_t handle,
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::AddCallback");
  std::scoped_lock lock(mutex_);
  cache_[handle] = DartCallbackInfo{name, class_name, library_path};
}

void InMemoryCallbackCacheProvider::RemoveCallback(int64_t handle) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::RemoveCallback");
  std::scoped_lock lock(mutex_);
  cache_.erase(handle);
}

void InMemoryCallbackCacheProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::Clear");
  std::scoped_lock lock(mutex_);
  cache_.clear();
}

size_t InMemoryCallbackCacheProvider::GetSize() const {
  std::scoped_lock lock(mutex_);
  return cache_.size();
}

std::optional<DartCallbackInfo>
InMemoryCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::GetCallbackInformation");
  std::scoped_lock lock(mutex_);
  auto it = cache_.find(handle);
  if (it != cache_.end()) {
    return it->second;
  }
  return std::nullopt;
}

FlutterEmbedderNative::FlutterEmbedderNative()
    : jvm_invoker_(std::make_shared<DefaultJvmInvoker>()),
      callback_cache_(std::make_shared<DefaultCallbackCacheProvider>()),
      jni_delegate_(
          std::make_shared<JniDelegate>(jvm_invoker_, callback_cache_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)),
      library_loader_(GetDefaultLibraryLoader()),
      asset_provider_(std::make_shared<APKAssetProvider>(
          std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterEmbedderNative");
  FML_DLOG(INFO)
      << "Initialized FlutterEmbedderNative with default components.";
}

FlutterEmbedderNative::FlutterEmbedderNative(
    std::shared_ptr<JvmInvoker> jvm_invoker,
    const std::shared_ptr<LegacyJniDelegate>& legacy_delegate,
    std::shared_ptr<OSLibraryLoader> library_loader,
    std::shared_ptr<APKAssetProvider> asset_provider,
    std::shared_ptr<CallbackCacheProvider> callback_cache)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(callback_cache
                          ? std::move(callback_cache)
                          : std::make_shared<DefaultCallbackCacheProvider>()),
      jni_delegate_(
          std::make_shared<JniDelegate>(jvm_invoker_, callback_cache_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, legacy_delegate)),
      library_loader_(library_loader ? std::move(library_loader)
                                     : GetDefaultLibraryLoader()),
      asset_provider_(
          asset_provider
              ? std::move(asset_provider)
              : std::make_shared<APKAssetProvider>(
                    std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterEmbedderNative(custom)");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with custom components.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
}

bool FlutterEmbedderNative::IsQuarantineEnforced() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsQuarantineEnforced");
  // The quarantine enforces zero internal UI / Skia header inclusions.
  return true;
}

bool FlutterEmbedderNative::VerifyEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::VerifyEmbedderVersion");
  return FLUTTER_ENGINE_VERSION >= 1;
}

size_t FlutterEmbedderNative::GetEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEmbedderVersion");
  return FLUTTER_ENGINE_VERSION;
}

bool FlutterEmbedderNative::IsEmbedderEnabled() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsEmbedderEnabled");
  return JniRouter::IsEmbedderEnabled();
}

void FlutterEmbedderNative::SetEmbedderEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEmbedderEnabled");
  JniRouter::SetEmbedderEnabled(enabled);
}

void FlutterEmbedderNative::SetDefaultLibraryLoader(
    std::shared_ptr<OSLibraryLoader> loader) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetDefaultLibraryLoader");
  default_library_loader_ = std::move(loader);
}

std::shared_ptr<OSLibraryLoader>
FlutterEmbedderNative::GetDefaultLibraryLoader() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetDefaultLibraryLoader");
  if (!default_library_loader_) {
    default_library_loader_ = std::make_shared<DefaultOSLibraryLoader>();
  }
  return default_library_loader_;
}

std::shared_ptr<JniRouter> FlutterEmbedderNative::CreateDefaultRouter(
    std::shared_ptr<JvmInvoker> invoker,
    const std::shared_ptr<LegacyJniDelegate>& legacy_delegate) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(std::move(invoker));
  return std::make_shared<JniRouter>(std::move(delegate), legacy_delegate);
}

std::shared_ptr<JniRouter> FlutterEmbedderNative::GetRouter() const {
  return jni_router_;
}

std::shared_ptr<JniDelegate> FlutterEmbedderNative::GetJniDelegate() const {
  return jni_delegate_;
}

std::shared_ptr<JvmInvoker> FlutterEmbedderNative::GetJvmInvoker() const {
  return jvm_invoker_;
}

std::shared_ptr<OSLibraryLoader> FlutterEmbedderNative::GetLibraryLoader()
    const {
  return library_loader_;
}

std::shared_ptr<APKAssetProvider> FlutterEmbedderNative::GetAssetProvider()
    const {
  return asset_provider_;
}

void FlutterEmbedderNative::SetAssetProvider(
    std::shared_ptr<APKAssetProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetAssetProvider");
  asset_provider_ = std::move(provider);
}

std::unique_ptr<fml::Mapping> FlutterEmbedderNative::ResolveAsset(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ResolveAsset", "name",
               asset_name.c_str());
  if (!asset_provider_) {
    return nullptr;
  }
  return asset_provider_->GetAsMapping(asset_name);
}

std::vector<std::unique_ptr<fml::Mapping>>
FlutterEmbedderNative::ResolveAssetMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ResolveAssetMappings",
               "pattern", asset_pattern.c_str());
  if (!asset_provider_) {
    return {};
  }
  return asset_provider_->GetAsMappings(asset_pattern, subdir);
}

std::shared_ptr<CallbackCacheProvider> FlutterEmbedderNative::GetCallbackCache()
    const {
  return callback_cache_;
}

void FlutterEmbedderNative::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetCallbackCache");
  callback_cache_ = provider ? std::move(provider)
                             : std::make_shared<DefaultCallbackCacheProvider>();
  if (jni_delegate_) {
    jni_delegate_->SetCallbackCache(callback_cache_);
  }
}

std::optional<DartCallbackInfo>
FlutterEmbedderNative::LookupCallbackInformation(int64_t handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::LookupCallbackInformation");
  if (!callback_cache_) {
    return std::nullopt;
  }
  return callback_cache_->GetCallbackInformation(handle);
}

}  // namespace android
}  // namespace flutter
