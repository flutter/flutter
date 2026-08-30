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

DefaultImageDecoderProvider::DefaultImageDecoderProvider(
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter",
               "DefaultImageDecoderProvider::DefaultImageDecoderProvider");
}

DefaultImageDecoderProvider::~DefaultImageDecoderProvider() {
  TRACE_EVENT0("flutter",
               "DefaultImageDecoderProvider::~DefaultImageDecoderProvider");
}

bool DefaultImageDecoderProvider::DecodeImage(const uint8_t* data,
                                              size_t size,
                                              int64_t generator_handle) {
  TRACE_EVENT0("flutter", "DefaultImageDecoderProvider::DecodeImage");
  if (!jvm_invoker_ || !data || size == 0) {
    return false;
  }
  std::vector<uint8_t> payload(data, data + size);
  return jvm_invoker_->InvokeBooleanMethod(
      "decodeImage", "(Ljava/nio/ByteBuffer;J)Landroid/graphics/Bitmap;",
      payload);
}

void DefaultImageDecoderProvider::OnImageHeader(int64_t generator_handle,
                                                int32_t width,
                                                int32_t height) {
  TRACE_EVENT0("flutter", "DefaultImageDecoderProvider::OnImageHeader");
  std::scoped_lock lock(mutex_);
  headers_[generator_handle] = ImageHeaderInfo{width, height};
}

std::optional<ImageHeaderInfo> DefaultImageDecoderProvider::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "DefaultImageDecoderProvider::GetImageHeader");
  std::scoped_lock lock(mutex_);
  auto it = headers_.find(generator_handle);
  if (it != headers_.end()) {
    return it->second;
  }
  return std::nullopt;
}

InMemoryImageDecoderProvider::InMemoryImageDecoderProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryImageDecoderProvider::InMemoryImageDecoderProvider");
}

InMemoryImageDecoderProvider::~InMemoryImageDecoderProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryImageDecoderProvider::~InMemoryImageDecoderProvider");
}

void InMemoryImageDecoderProvider::SetDecodeResult(bool success) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::SetDecodeResult");
  std::scoped_lock lock(mutex_);
  decode_result_ = success;
}

void InMemoryImageDecoderProvider::SetHeaderInfo(int64_t generator_handle,
                                                 int32_t width,
                                                 int32_t height) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::SetHeaderInfo");
  std::scoped_lock lock(mutex_);
  headers_[generator_handle] = ImageHeaderInfo{width, height};
}

size_t InMemoryImageDecoderProvider::GetDecodeCount() const {
  std::scoped_lock lock(mutex_);
  return decode_count_;
}

size_t InMemoryImageDecoderProvider::GetLastDecodedSize() const {
  std::scoped_lock lock(mutex_);
  return last_decoded_size_;
}

void InMemoryImageDecoderProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::Clear");
  std::scoped_lock lock(mutex_);
  decode_count_ = 0;
  last_decoded_size_ = 0;
  headers_.clear();
}

bool InMemoryImageDecoderProvider::DecodeImage(const uint8_t* data,
                                               size_t size,
                                               int64_t generator_handle) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::DecodeImage");
  std::scoped_lock lock(mutex_);
  decode_count_++;
  last_decoded_size_ = size;
  return decode_result_;
}

void InMemoryImageDecoderProvider::OnImageHeader(int64_t generator_handle,
                                                 int32_t width,
                                                 int32_t height) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::OnImageHeader");
  std::scoped_lock lock(mutex_);
  headers_[generator_handle] = ImageHeaderInfo{width, height};
}

std::optional<ImageHeaderInfo> InMemoryImageDecoderProvider::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::GetImageHeader");
  std::scoped_lock lock(mutex_);
  auto it = headers_.find(generator_handle);
  if (it != headers_.end()) {
    return it->second;
  }
  return std::nullopt;
}

EmbedderImageLRU::EmbedderImageLRU(size_t capacity)
    : capacity_(capacity > 0 ? capacity : kDefaultCapacity),
      entries_(capacity_) {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::EmbedderImageLRU");
}

EmbedderImageLRU::~EmbedderImageLRU() {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::~EmbedderImageLRU");
}

uint64_t EmbedderImageLRU::FindImage(uint64_t key) {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::FindImage");
  if (key == 0) {
    return 0;
  }
  std::scoped_lock lock(mutex_);
  for (size_t i = 0; i < capacity_; ++i) {
    if (entries_[i].key == key) {
      uint64_t result = entries_[i].image_handle;
      UpdateKey(result, key);
      return result;
    }
  }
  return 0;
}

void EmbedderImageLRU::UpdateKey(uint64_t image_handle, uint64_t key) {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::UpdateKey");
  if (entries_[0].key == key) {
    return;
  }
  size_t i = 1;
  for (; i < capacity_; ++i) {
    if (entries_[i].key == key) {
      break;
    }
  }
  for (auto j = (i < capacity_ ? i : capacity_ - 1); j > 0; --j) {
    entries_[j] = entries_[j - 1];
  }
  entries_[0] = Entry{.key = key, .image_handle = image_handle};
}

uint64_t EmbedderImageLRU::AddImage(uint64_t image_handle, uint64_t key) {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::AddImage");
  std::scoped_lock lock(mutex_);
  uint64_t lru_key = entries_[capacity_ - 1].key;
  bool updated_image = false;
  for (size_t i = 0; i < capacity_; ++i) {
    if (entries_[i].key == lru_key) {
      updated_image = true;
      entries_[i] = Entry{.key = key, .image_handle = image_handle};
      break;
    }
  }
  if (!updated_image) {
    entries_[0] = Entry{.key = key, .image_handle = image_handle};
  }
  UpdateKey(image_handle, key);
  return lru_key;
}

void EmbedderImageLRU::Clear() {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::Clear");
  std::scoped_lock lock(mutex_);
  for (size_t i = 0; i < capacity_; ++i) {
    entries_[i] = Entry{.key = 0, .image_handle = 0};
  }
}

size_t EmbedderImageLRU::GetSize() const {
  std::scoped_lock lock(mutex_);
  size_t count = 0;
  for (size_t i = 0; i < capacity_; ++i) {
    if (entries_[i].key != 0) {
      count++;
    }
  }
  return count;
}

FlutterEmbedderNative::FlutterEmbedderNative()
    : jvm_invoker_(std::make_shared<DefaultJvmInvoker>()),
      callback_cache_(std::make_shared<DefaultCallbackCacheProvider>()),
      image_decoder_(
          std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_)),
      image_lru_(std::make_shared<EmbedderImageLRU>()),
      platform_views_provider_(
          std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_,
                                                  callback_cache_,
                                                  image_decoder_,
                                                  platform_views_provider_)),
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
    std::shared_ptr<CallbackCacheProvider> callback_cache,
    std::shared_ptr<ImageDecoderProvider> image_decoder,
    std::shared_ptr<EmbedderImageLRU> image_lru,
    std::shared_ptr<PlatformViewsProvider> platform_views_provider)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(callback_cache
                          ? std::move(callback_cache)
                          : std::make_shared<DefaultCallbackCacheProvider>()),
      image_decoder_(
          image_decoder
              ? std::move(image_decoder)
              : std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_)),
      image_lru_(image_lru ? std::move(image_lru)
                           : std::make_shared<EmbedderImageLRU>()),
      platform_views_provider_(
          platform_views_provider
              ? std::move(platform_views_provider)
              : std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_,
                                                  callback_cache_,
                                                  image_decoder_,
                                                  platform_views_provider_)),
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
    const std::shared_ptr<LegacyJniDelegate>& legacy_delegate,
    std::shared_ptr<PlatformViewsProvider> platform_views_provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(
      std::move(invoker), nullptr, nullptr, std::move(platform_views_provider));
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

std::shared_ptr<ImageDecoderProvider>
FlutterEmbedderNative::GetImageDecoderProvider() const {
  return image_decoder_;
}

void FlutterEmbedderNative::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetImageDecoderProvider");
  image_decoder_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_);
  if (jni_delegate_) {
    jni_delegate_->SetImageDecoderProvider(image_decoder_);
  }
}

bool FlutterEmbedderNative::DecodeImage(const uint8_t* data,
                                        size_t size,
                                        int64_t generator_handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DecodeImage");
  if (!image_decoder_) {
    return false;
  }
  return image_decoder_->DecodeImage(data, size, generator_handle);
}

void FlutterEmbedderNative::OnNativeImageHeader(int64_t generator_handle,
                                                int32_t width,
                                                int32_t height) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnNativeImageHeader");
  if (image_decoder_) {
    image_decoder_->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> FlutterEmbedderNative::GetImageHeader(
    int64_t generator_handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetImageHeader");
  if (image_decoder_) {
    return image_decoder_->GetImageHeader(generator_handle);
  }
  return std::nullopt;
}

static FlutterEngineResult RegisterImageDecoderWithEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterImageDecoderCallback callback,
    void* user_data,
    int32_t priority) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.RegisterImageDecoder) {
    return s_procs.RegisterImageDecoder(engine, callback, user_data, priority);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::RegisterImageDecoder(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int32_t priority) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RegisterImageDecoder");
  if (!engine) {
    return kInvalidArguments;
  }
  auto callback = [](const uint8_t* data, size_t size,
                     void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    if (!native) {
      return false;
    }
    return native->DecodeImage(data, size, 0);
  };
  return RegisterImageDecoderWithEngine(engine, callback, this, priority);
}

std::shared_ptr<EmbedderImageLRU> FlutterEmbedderNative::GetImageLRU() const {
  return image_lru_;
}

void FlutterEmbedderNative::SetImageLRU(std::shared_ptr<EmbedderImageLRU> lru) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetImageLRU");
  image_lru_ = lru ? std::move(lru) : std::make_shared<EmbedderImageLRU>();
}

std::shared_ptr<PlatformViewsProvider>
FlutterEmbedderNative::GetPlatformViewsProvider() const {
  return platform_views_provider_;
}

void FlutterEmbedderNative::SetPlatformViewsProvider(
    std::shared_ptr<PlatformViewsProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetPlatformViewsProvider");
  platform_views_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_);
  if (platform_views_controller_) {
    platform_views_controller_->SetProvider(platform_views_provider_);
  }
  if (jni_delegate_) {
    jni_delegate_->SetPlatformViewsProvider(platform_views_provider_);
  }
}

std::shared_ptr<AndroidPlatformViewsController>
FlutterEmbedderNative::GetPlatformViewsController() const {
  return platform_views_controller_;
}

int64_t FlutterEmbedderNative::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  if (!jni_router_) {
    return -1;
  }
  return jni_router_->RouteCreatePlatformView(params, composition_type);
}

bool FlutterEmbedderNative::DisposePlatformView(int64_t view_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteDisposePlatformView(view_id);
}

bool FlutterEmbedderNative::ResizePlatformView(
    const PlatformViewResizeRequest& request) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ResizePlatformView",
               "view_id", std::to_string(request.view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteResizePlatformView(request);
}

bool FlutterEmbedderNative::OffsetPlatformView(int64_t view_id,
                                               double top,
                                               double left) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOffsetPlatformView(view_id, top, left);
}

bool FlutterEmbedderNative::SetPlatformViewDirection(int64_t view_id,
                                                     int32_t direction) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetPlatformViewDirection",
               "view_id", std::to_string(view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetPlatformViewDirection(view_id, direction);
}

bool FlutterEmbedderNative::ClearPlatformViewFocus(int64_t view_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ClearPlatformViewFocus",
               "view_id", std::to_string(view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteClearPlatformViewFocus(view_id);
}

bool FlutterEmbedderNative::DispatchPlatformViewTouch(
    const PlatformViewTouch& touch) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::DispatchPlatformViewTouch",
               "view_id", std::to_string(touch.view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteDispatchPlatformViewTouch(touch);
}

bool FlutterEmbedderNative::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::OnDisplayPlatformView",
               "view_id", std::to_string(geometry.view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOnDisplayPlatformView(geometry);
}

bool FlutterEmbedderNative::OnDisplayPlatformView(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::OnDisplayPlatformView(struct)",
               "view_id", std::to_string(platform_view.identifier).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOnDisplayPlatformView(
      platform_view, x, y, width, height, view_width, view_height);
}

bool FlutterEmbedderNative::HidePlatformView(int64_t view_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::HidePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteHidePlatformView(view_id);
}

bool FlutterEmbedderNative::SynchronizeToNativeViewHierarchy(
    bool synchronize) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::SynchronizeToNativeViewHierarchy");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSynchronizeToNativeViewHierarchy(synchronize);
}

bool FlutterEmbedderNative::OnBeginFrame() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnBeginFrame");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteBeginFrame();
}

bool FlutterEmbedderNative::OnEndFrame() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnEndFrame");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteEndFrame();
}

std::optional<int32_t> FlutterEmbedderNative::CreateOverlaySurface() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateOverlaySurface");
  if (!jni_router_) {
    return std::nullopt;
  }
  return jni_router_->RouteCreateOverlaySurface();
}

bool FlutterEmbedderNative::DestroyOverlaySurfaces() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DestroyOverlaySurfaces");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteDestroyOverlaySurfaces();
}

bool FlutterEmbedderNative::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::OnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOnDisplayOverlaySurface(overlay);
}

bool FlutterEmbedderNative::ShowOverlaySurface(int32_t surface_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteShowOverlaySurface(surface_id);
}

bool FlutterEmbedderNative::HideOverlaySurface(int32_t surface_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteHideOverlaySurface(surface_id);
}

bool FlutterEmbedderNative::CreatePlatformViewTransaction() const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::CreatePlatformViewTransaction");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteCreatePlatformViewTransaction();
}

bool FlutterEmbedderNative::SwapPlatformViewTransactions() const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::SwapPlatformViewTransactions");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSwapPlatformViewTransactions();
}

bool FlutterEmbedderNative::ApplyPlatformViewTransactions() const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::ApplyPlatformViewTransactions");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteApplyPlatformViewTransactions();
}

bool FlutterEmbedderNative::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsHcppEnabled");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteIsHcppEnabled();
}

AndroidMutatorsStack FlutterEmbedderNative::MapPlatformViewMutations(
    const FlutterPlatformViewMutation** mutations,
    size_t count) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::MapPlatformViewMutations");
  return AndroidMutatorsMapper::MapMutations(mutations, count);
}

AndroidMutatorsStack FlutterEmbedderNative::MapPlatformView(
    const FlutterPlatformView& platform_view) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::MapPlatformView");
  return AndroidMutatorsMapper::MapPlatformView(platform_view);
}

bool FlutterEmbedderNative::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::PushPlatformViewMutators");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RoutePlatformViewMutators(view_id, x, y, width, height,
                                                mutators_stack);
}

bool FlutterEmbedderNative::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::PushPlatformViewMutators(view)");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RoutePlatformViewMutators(platform_view, x, y, width,
                                                height);
}

bool FlutterEmbedderNative::UpdateSemantics(
    const FlutterSemanticsUpdate2& update) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateSemantics(struct)");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSemanticsUpdate(update);
}

bool FlutterEmbedderNative::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateSemantics(buffers)");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSemanticsUpdate(buffer, strings,
                                           string_attribute_args);
}

bool FlutterEmbedderNative::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::UpdateCustomAccessibilityActions");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteCustomAccessibilityActions(buffer, strings);
}

bool FlutterEmbedderNative::SetSemanticsEnabled(bool enabled) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetSemanticsEnabled");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSemanticsEnabled(enabled);
}

bool FlutterEmbedderNative::DispatchSemanticsAction(
    int32_t node_id,
    FlutterSemanticsAction action,
    const std::vector<uint8_t>& data,
    int64_t view_id) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DispatchSemanticsAction");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteDispatchSemanticsAction(node_id, action, data,
                                                   view_id);
}

bool FlutterEmbedderNative::SetAccessibilityFeatures(int32_t flags) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetAccessibilityFeatures");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetAccessibilityFeatures(flags);
}

static FlutterEngineResult EngineUpdateSemanticsEnabled(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    bool enabled) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.UpdateSemanticsEnabled) {
    return s_procs.UpdateSemanticsEnabled(engine, enabled);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::UpdateSemanticsEnabled(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    bool enabled) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateSemanticsEnabled");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineUpdateSemanticsEnabled(engine, enabled);
}

static FlutterEngineResult EngineUpdateAccessibilityFeatures(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterAccessibilityFeature features) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.UpdateAccessibilityFeatures) {
    return s_procs.UpdateAccessibilityFeatures(engine, features);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::UpdateAccessibilityFeatures(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterAccessibilityFeature features) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateAccessibilityFeatures");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineUpdateAccessibilityFeatures(engine, features);
}

static FlutterEngineResult EngineSendSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterSendSemanticsActionInfo* info) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendSemanticsAction) {
    return s_procs.SendSemanticsAction(engine, info);
  }
  if (s_procs.DispatchSemanticsAction && info) {
    return s_procs.DispatchSemanticsAction(engine, info->node_id, info->action,
                                           info->data, info->data_length);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::SendSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterSendSemanticsActionInfo* info) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SendSemanticsAction");
  if (!engine || !info) {
    return kInvalidArguments;
  }
  return EngineSendSemanticsAction(engine, info);
}

static FlutterEngineResult EngineDispatchSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.DispatchSemanticsAction) {
    return s_procs.DispatchSemanticsAction(engine, node_id, action, data,
                                           data_length);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::DispatchSemanticsActionToEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::DispatchSemanticsActionToEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineDispatchSemanticsAction(engine, node_id, action, data,
                                       data_length);
}

void FlutterEmbedderNative::OnUpdateSemantics2(
    const FlutterSemanticsUpdate2* update,
    void* user_data) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnUpdateSemantics2");
  if (!update || !user_data) {
    return;
  }
  auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
  native->UpdateSemantics(*update);
}

}  // namespace android
}  // namespace flutter
