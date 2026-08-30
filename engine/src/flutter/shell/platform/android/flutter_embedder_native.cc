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
      window_metrics_provider_(
          std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_)),
      library_loader_(GetDefaultLibraryLoader()),
      choreographer_provider_(
          std::make_shared<DefaultAndroidChoreographerProvider>(
              library_loader_)),
      vsync_waiter_(
          std::make_shared<AndroidVsyncWaiter>(choreographer_provider_,
                                               jvm_invoker_)),
      font_provider_(
          std::make_shared<DefaultFontCollectionProvider>(library_loader_)),
      aot_provider_(std::make_shared<DefaultAndroidAOTProvider>()),
      vm_init_(std::make_shared<AndroidVMInit>(jvm_invoker_,
                                               font_provider_,
                                               aot_provider_)),
      hardware_buffer_provider_(
          std::make_shared<DefaultAndroidHardwareBufferProvider>(
              library_loader_)),
      vulkan_texture_provider_(
          std::make_shared<DefaultAndroidVulkanTextureProvider>(
              library_loader_)),
      surface_control_provider_(
          std::make_shared<DefaultAndroidSurfaceControlProvider>(
              library_loader_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_,
                                                  callback_cache_,
                                                  image_decoder_,
                                                  platform_views_provider_,
                                                  window_metrics_provider_,
                                                  vsync_waiter_,
                                                  vm_init_,
                                                  hardware_buffer_provider_,
                                                  vulkan_texture_provider_,
                                                  surface_control_provider_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)),
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
    std::shared_ptr<PlatformViewsProvider> platform_views_provider,
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidChoreographerProvider> choreographer_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<FontCollectionProvider> font_provider,
    std::shared_ptr<AndroidAOTProvider> aot_provider,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider)
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
      window_metrics_provider_(
          window_metrics_provider
              ? std::move(window_metrics_provider)
              : std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_)),
      library_loader_(library_loader ? std::move(library_loader)
                                     : GetDefaultLibraryLoader()),
      choreographer_provider_(
          choreographer_provider
              ? std::move(choreographer_provider)
              : std::make_shared<DefaultAndroidChoreographerProvider>(
                    library_loader_)),
      vsync_waiter_(vsync_waiter ? std::move(vsync_waiter)
                                 : std::make_shared<AndroidVsyncWaiter>(
                                       choreographer_provider_,
                                       jvm_invoker_)),
      font_provider_(font_provider
                         ? std::move(font_provider)
                         : std::make_shared<DefaultFontCollectionProvider>(
                               library_loader_)),
      aot_provider_(aot_provider
                        ? std::move(aot_provider)
                        : std::make_shared<DefaultAndroidAOTProvider>()),
      vm_init_(vm_init ? std::move(vm_init)
                       : std::make_shared<AndroidVMInit>(jvm_invoker_,
                                                         font_provider_,
                                                         aot_provider_)),
      hardware_buffer_provider_(
          hardware_buffer_provider
              ? std::move(hardware_buffer_provider)
              : std::make_shared<DefaultAndroidHardwareBufferProvider>(
                    library_loader_)),
      vulkan_texture_provider_(
          vulkan_texture_provider
              ? std::move(vulkan_texture_provider)
              : std::make_shared<DefaultAndroidVulkanTextureProvider>(
                    library_loader_)),
      surface_control_provider_(
          surface_control_provider
              ? std::move(surface_control_provider)
              : std::make_shared<DefaultAndroidSurfaceControlProvider>(
                    library_loader_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_,
                                                  callback_cache_,
                                                  image_decoder_,
                                                  platform_views_provider_,
                                                  window_metrics_provider_,
                                                  vsync_waiter_,
                                                  vm_init_,
                                                  hardware_buffer_provider_,
                                                  vulkan_texture_provider_,
                                                  surface_control_provider_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, legacy_delegate)),
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
    std::shared_ptr<PlatformViewsProvider> platform_views_provider,
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(
      std::move(invoker), nullptr, nullptr, std::move(platform_views_provider),
      std::move(window_metrics_provider), std::move(vsync_waiter),
      std::move(vm_init), std::move(hardware_buffer_provider),
      std::move(vulkan_texture_provider), std::move(surface_control_provider));
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

bool FlutterEmbedderNative::SetHcppEnabled(bool enabled) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetHcppEnabled", "enabled",
               enabled ? "true" : "false");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetHcppEnabled(enabled);
}

bool FlutterEmbedderNative::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsHcppEnabled");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteIsHcppEnabled();
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

bool FlutterEmbedderNative::CreateSurfaceControl(
    int64_t surface_id,
    const std::string& debug_name) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::CreateSurfaceControl",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteCreateSurfaceControl(surface_id, debug_name);
}

bool FlutterEmbedderNative::DestroySurfaceControl(int64_t surface_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::DestroySurfaceControl",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteDestroySurfaceControl(surface_id);
}

bool FlutterEmbedderNative::ReparentSurfaceControl(
    int64_t surface_id,
    int64_t new_parent_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ReparentSurfaceControl",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteReparentSurfaceControl(surface_id, new_parent_id);
}

bool FlutterEmbedderNative::SetSurfaceControlGeometry(
    int64_t surface_id,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    int32_t transform) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlGeometry",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlGeometry(surface_id, source,
                                                     destination, transform);
}

bool FlutterEmbedderNative::SetSurfaceControlVisibility(int64_t surface_id,
                                                        bool visible) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlVisibility",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlVisibility(surface_id, visible);
}

bool FlutterEmbedderNative::SetSurfaceControlZOrder(int64_t surface_id,
                                                    int32_t z_order) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlZOrder",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlZOrder(surface_id, z_order);
}

bool FlutterEmbedderNative::SetSurfaceControlDamageRegion(
    int64_t surface_id,
    const std::vector<AndroidSurfaceControlRect>& rects) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::SetSurfaceControlDamageRegion",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlDamageRegion(surface_id, rects);
}

bool FlutterEmbedderNative::SetSurfaceControlBuffer(int64_t surface_id,
                                                    void* buffer,
                                                    int fence_fd) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlBuffer",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlBuffer(surface_id, buffer,
                                                   fence_fd);
}

bool FlutterEmbedderNative::SetSurfaceControlBufferAlpha(int64_t surface_id,
                                                         float alpha) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlBufferAlpha",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlBufferAlpha(surface_id, alpha);
}

bool FlutterEmbedderNative::SetSurfaceControlColor(int64_t surface_id,
                                                   float r,
                                                   float g,
                                                   float b,
                                                   float alpha) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetSurfaceControlColor",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetSurfaceControlColor(surface_id, r, g, b, alpha);
}

std::optional<AndroidSurfaceControlState>
FlutterEmbedderNative::GetSurfaceControlState(int64_t surface_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::GetSurfaceControlState",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return std::nullopt;
  }
  return jni_router_->RouteGetSurfaceControlState(surface_id);
}

std::shared_ptr<AndroidSurfaceControl> FlutterEmbedderNative::GetSurfaceControl(
    int64_t surface_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::GetSurfaceControl",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jni_router_) {
    return nullptr;
  }
  return jni_router_->RouteGetSurfaceControl(surface_id);
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

static FlutterEngineResult EngineSendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterWindowMetricsEvent* event) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendWindowMetricsEvent) {
    return s_procs.SendWindowMetricsEvent(engine, event);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineNotifyDisplayUpdate(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterEngineDisplaysUpdateType update_type,
    const FlutterEngineDisplay* displays,
    size_t display_count) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.NotifyDisplayUpdate) {
    return s_procs.NotifyDisplayUpdate(engine, update_type, displays,
                                       display_count);
  }
  return kInternalInconsistency;
}

std::shared_ptr<WindowMetricsProvider>
FlutterEmbedderNative::GetWindowMetricsProvider() const {
  return window_metrics_provider_;
}

void FlutterEmbedderNative::SetWindowMetricsProvider(
    std::shared_ptr<WindowMetricsProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetWindowMetricsProvider");
  window_metrics_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_);
  if (jni_delegate_) {
    jni_delegate_->SetWindowMetricsProvider(window_metrics_provider_);
  }
}

bool FlutterEmbedderNative::SetViewportMetrics(
    const AndroidViewportMetrics& metrics) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetViewportMetrics");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetViewportMetrics(metrics);
}

bool FlutterEmbedderNative::UpdateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::UpdateDisplayMetrics(struct)");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteUpdateDisplayMetrics(metrics);
}

bool FlutterEmbedderNative::UpdateDisplayMetrics(
    uint64_t display_id,
    double refresh_rate,
    double width,
    double height,
    double device_pixel_ratio) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::UpdateDisplayMetrics(params)");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteUpdateDisplayMetrics(display_id, refresh_rate, width,
                                                height, device_pixel_ratio);
}

FlutterWindowMetricsEvent FlutterEmbedderNative::TranslateViewportMetrics(
    const AndroidViewportMetrics& metrics) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::TranslateViewportMetrics");
  return AndroidWindowMetricsMapper::ToFlutterWindowMetricsEvent(metrics);
}

FlutterEngineDisplay FlutterEmbedderNative::TranslateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::TranslateDisplayMetrics");
  return AndroidWindowMetricsMapper::ToFlutterEngineDisplay(metrics);
}

FlutterEngineResult FlutterEmbedderNative::SendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterWindowMetricsEvent* event) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::SendWindowMetricsEvent(event)");
  if (!engine || !event) {
    return kInvalidArguments;
  }
  return EngineSendWindowMetricsEvent(engine, event);
}

FlutterEngineResult FlutterEmbedderNative::SendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const AndroidViewportMetrics& metrics) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::SendWindowMetricsEvent(metrics)");
  if (!engine) {
    return kInvalidArguments;
  }
  FlutterWindowMetricsEvent event = TranslateViewportMetrics(metrics);
  return SendWindowMetricsEvent(engine, &event);
}

FlutterEngineResult FlutterEmbedderNative::NotifyDisplayUpdate(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterEngineDisplaysUpdateType update_type,
    const FlutterEngineDisplay* displays,
    size_t display_count) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::NotifyDisplayUpdate(displays)");
  if (!engine || (!displays && display_count > 0)) {
    return kInvalidArguments;
  }
  return EngineNotifyDisplayUpdate(engine, update_type, displays,
                                   display_count);
}

FlutterEngineResult FlutterEmbedderNative::NotifyDisplayUpdate(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const AndroidDisplayMetrics& display) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::NotifyDisplayUpdate(display)");
  if (!engine) {
    return kInvalidArguments;
  }
  FlutterEngineDisplay engine_display = TranslateDisplayMetrics(display);
  return NotifyDisplayUpdate(engine, kFlutterEngineDisplaysUpdateTypeStartup,
                             &engine_display, 1);
}

std::shared_ptr<AndroidChoreographerProvider>
FlutterEmbedderNative::GetChoreographerProvider() const {
  return choreographer_provider_;
}

void FlutterEmbedderNative::SetChoreographerProvider(
    std::shared_ptr<AndroidChoreographerProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetChoreographerProvider");
  choreographer_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidChoreographerProvider>(
                     library_loader_);
  if (vsync_waiter_) {
    vsync_waiter_->SetChoreographerProvider(choreographer_provider_);
  }
}

std::shared_ptr<AndroidVsyncWaiter> FlutterEmbedderNative::GetVsyncWaiter()
    const {
  return vsync_waiter_;
}

void FlutterEmbedderNative::SetVsyncWaiter(
    std::shared_ptr<AndroidVsyncWaiter> waiter) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVsyncWaiter");
  vsync_waiter_ = waiter ? std::move(waiter)
                         : std::make_shared<AndroidVsyncWaiter>(
                               choreographer_provider_, jvm_invoker_);
  if (jni_delegate_) {
    jni_delegate_->SetVsyncWaiter(vsync_waiter_);
  }
}

void FlutterEmbedderNative::OnVsyncCallback(void* user_data, intptr_t baton) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnVsyncCallback");
  if (!user_data) {
    return;
  }
  auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
  native->AsyncWaitForVsync(baton);
}

bool FlutterEmbedderNative::AsyncWaitForVsync(intptr_t baton) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::AsyncWaitForVsync", "baton",
               std::to_string(baton).c_str());
  if (vsync_waiter_) {
    return vsync_waiter_->AsyncWaitForVsync(baton);
  }
  if (jni_router_) {
    return jni_router_->RouteAsyncWaitForVsync(baton);
  }
  return false;
}

void FlutterEmbedderNative::UpdateRefreshRate(double refresh_rate_hz) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::UpdateRefreshRate",
               "refresh_rate", std::to_string(refresh_rate_hz).c_str());
  if (vsync_waiter_) {
    vsync_waiter_->UpdateRefreshRate(refresh_rate_hz);
  }
}

double FlutterEmbedderNative::GetRefreshRate() const {
  if (vsync_waiter_) {
    return vsync_waiter_->GetRefreshRate();
  }
  return 60.0;
}

int64_t FlutterEmbedderNative::GetRefreshPeriodNanos() const {
  if (vsync_waiter_) {
    return vsync_waiter_->GetRefreshPeriodNanos();
  }
  return static_cast<int64_t>(1000000000.0 / 60.0);
}

AndroidVsyncFrameInfo FlutterEmbedderNative::ComputeFramePacing(
    int64_t frame_time_nanos,
    double refresh_rate_hz) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ComputeFramePacing");
  return AndroidVsyncWaiter::ComputeFramePacing(frame_time_nanos,
                                                refresh_rate_hz);
}

static FlutterEngineResult EngineNotifyVsync(FLUTTER_API_SYMBOL(FlutterEngine)
                                                 engine,
                                             intptr_t baton,
                                             uint64_t frame_start_time_nanos,
                                             uint64_t frame_target_time_nanos) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.OnVsync) {
    return s_procs.OnVsync(engine, baton, frame_start_time_nanos,
                           frame_target_time_nanos);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::NotifyVsync(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    intptr_t baton,
    int64_t frame_start_time_nanos,
    int64_t frame_target_time_nanos) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::NotifyVsync");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineNotifyVsync(engine, baton, frame_start_time_nanos,
                           frame_target_time_nanos);
}

bool FlutterEmbedderNative::InitVM(const AndroidVMArgs& args) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::InitVM");
  if (jni_router_) {
    return jni_router_->RouteInitVM(args);
  }
  if (vm_init_) {
    return vm_init_->Init(args);
  }
  return false;
}

bool FlutterEmbedderNative::PrefetchDefaultFontManager() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::PrefetchDefaultFontManager");
  if (jni_router_) {
    return jni_router_->RoutePrefetchDefaultFontManager();
  }
  if (vm_init_) {
    return vm_init_->PrefetchDefaultFontManager();
  }
  return false;
}

bool FlutterEmbedderNative::SetVmServiceUri(const std::string& uri) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SetVmServiceUri", "uri",
               uri.c_str());
  if (jni_router_) {
    return jni_router_->RouteSetVmServiceUri(uri);
  }
  if (vm_init_) {
    return vm_init_->SetVmServiceUri(uri);
  }
  return false;
}

std::string FlutterEmbedderNative::GetVmServiceUri() const {
  if (vm_init_) {
    return vm_init_->GetVmServiceUri();
  }
  return "";
}

bool FlutterEmbedderNative::IsVMInitialized() const {
  if (vm_init_) {
    return vm_init_->IsInitialized();
  }
  return false;
}

std::optional<AndroidVMArgs> FlutterEmbedderNative::GetVMArgs() const {
  if (vm_init_) {
    return vm_init_->GetVMArgs();
  }
  return std::nullopt;
}

AndroidRenderingAPI FlutterEmbedderNative::GetSelectedRenderingAPI() const {
  if (vm_init_) {
    return vm_init_->GetSelectedRenderingAPI();
  }
  return AndroidRenderingAPI::kSkiaOpenGLES;
}

const FlutterProjectArgs* FlutterEmbedderNative::GetProjectArgs() const {
  if (vm_init_) {
    return vm_init_->GetProjectArgs();
  }
  return nullptr;
}

static FlutterEngineResult EngineInitialize(size_t version,
                                            const FlutterRendererConfig* config,
                                            const FlutterProjectArgs* args,
                                            void* user_data,
                                            FLUTTER_API_SYMBOL(FlutterEngine) *
                                                engine_out) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.Initialize) {
    return s_procs.Initialize(version, config, args, user_data, engine_out);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineDeinitialize(FLUTTER_API_SYMBOL(FlutterEngine)
                                                  engine) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.Deinitialize) {
    return s_procs.Deinitialize(engine);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::InitializeEngine(
    const FlutterRendererConfig* config,
    const FlutterProjectArgs* args,
    void* user_data,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::InitializeEngine");
  if (!config || !args || !engine_out) {
    return kInvalidArguments;
  }
  return EngineInitialize(FLUTTER_ENGINE_VERSION, config, args, user_data,
                          engine_out);
}

FlutterEngineResult FlutterEmbedderNative::DeinitializeEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DeinitializeEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineDeinitialize(engine);
}

static FlutterEngineResult EngineCreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.CreateAOTData) {
    return s_procs.CreateAOTData(source, data_out);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineCollectAOTData(FlutterEngineAOTData data) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.CollectAOTData) {
    return s_procs.CollectAOTData(data);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::CreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateAOTData");
  if (!source || !data_out) {
    return kInvalidArguments;
  }
  if (aot_provider_) {
    return aot_provider_->CreateAOTData(source, data_out);
  }
  return EngineCreateAOTData(source, data_out);
}

FlutterEngineResult FlutterEmbedderNative::CollectAOTData(
    FlutterEngineAOTData data) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CollectAOTData");
  if (!data) {
    return kInvalidArguments;
  }
  if (aot_provider_) {
    return aot_provider_->CollectAOTData(data);
  }
  return EngineCollectAOTData(data);
}

std::shared_ptr<AndroidVMInit> FlutterEmbedderNative::GetVMInit() const {
  return vm_init_;
}

void FlutterEmbedderNative::SetVMInit(std::shared_ptr<AndroidVMInit> vm_init) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVMInit");
  vm_init_ = vm_init ? std::move(vm_init)
                     : std::make_shared<AndroidVMInit>(
                           jvm_invoker_, font_provider_, aot_provider_);
  if (jni_delegate_) {
    jni_delegate_->SetVMInit(vm_init_);
  }
}

std::shared_ptr<FontCollectionProvider>
FlutterEmbedderNative::GetFontCollectionProvider() const {
  return font_provider_;
}

void FlutterEmbedderNative::SetFontCollectionProvider(
    std::shared_ptr<FontCollectionProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetFontCollectionProvider");
  font_provider_ =
      provider
          ? std::move(provider)
          : std::make_shared<DefaultFontCollectionProvider>(library_loader_);
  if (vm_init_) {
    vm_init_->SetFontCollectionProvider(font_provider_);
  }
}

std::shared_ptr<AndroidAOTProvider> FlutterEmbedderNative::GetAOTProvider()
    const {
  return aot_provider_;
}

void FlutterEmbedderNative::SetAOTProvider(
    std::shared_ptr<AndroidAOTProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetAOTProvider");
  aot_provider_ = provider ? std::move(provider)
                           : std::make_shared<DefaultAndroidAOTProvider>();
  if (vm_init_) {
    vm_init_->SetAOTProvider(aot_provider_);
  }
}

std::shared_ptr<AndroidHardwareBufferProvider>
FlutterEmbedderNative::GetHardwareBufferProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetHardwareBufferProvider");
  return hardware_buffer_provider_;
}

void FlutterEmbedderNative::SetHardwareBufferProvider(
    std::shared_ptr<AndroidHardwareBufferProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetHardwareBufferProvider");
  hardware_buffer_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidHardwareBufferProvider>(
                     library_loader_);
  if (jni_delegate_) {
    jni_delegate_->SetHardwareBufferProvider(hardware_buffer_provider_);
  }
}

bool FlutterEmbedderNative::RegisterHardwareBufferTexture(
    int64_t texture_id,
    const std::shared_ptr<AndroidHardwareBuffer>& initial_buffer) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::RegisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  bool registered = jni_router_->RouteRegisterHardwareBufferTexture(texture_id);
  if (registered && initial_buffer) {
    jni_router_->RouteSetHardwareBufferFrame(texture_id, initial_buffer);
  }
  return registered;
}

bool FlutterEmbedderNative::UnregisterHardwareBufferTexture(
    int64_t texture_id) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::UnregisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteUnregisterHardwareBufferTexture(texture_id);
}

bool FlutterEmbedderNative::SetHardwareBufferFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidHardwareBuffer>& buffer) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::SetHardwareBufferFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetHardwareBufferFrame(texture_id, buffer);
}

bool FlutterEmbedderNative::SetHardwareBufferFrame(
    int64_t texture_id,
    const FlutterHardwareBufferExternalTexture& texture) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::SetHardwareBufferFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetHardwareBufferFrame(texture_id, texture);
}

bool FlutterEmbedderNative::GetHardwareBufferTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterHardwareBufferExternalTexture* texture_out) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::GetHardwareBufferTextureFrame",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteGetHardwareBufferTextureFrame(texture_id, width,
                                                         height, texture_out);
}

bool FlutterEmbedderNative::OnHardwareBufferFrameAvailable(
    int64_t texture_id) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::OnHardwareBufferFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOnHardwareBufferFrameAvailable(texture_id);
}

bool FlutterEmbedderNative::OnHardwareBufferExternalTextureFrameCallback(
    void* user_data,
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterHardwareBufferExternalTexture* texture_out) {
  TRACE_EVENT1(
      "flutter",
      "FlutterEmbedderNative::OnHardwareBufferExternalTextureFrameCallback",
      "texture_id", std::to_string(texture_id).c_str());
  if (!user_data || !texture_out) {
    return false;
  }
  auto* native_instance = static_cast<FlutterEmbedderNative*>(user_data);
  return native_instance->GetHardwareBufferTextureFrame(texture_id, width,
                                                        height, texture_out);
}

FlutterHardwareBufferExternalTextureFrameCallback
FlutterEmbedderNative::GetHardwareBufferFrameCallback() {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::GetHardwareBufferFrameCallback");
  return &FlutterEmbedderNative::OnHardwareBufferExternalTextureFrameCallback;
}

FlutterEngineResult FlutterEmbedderNative::MarkExternalTextureFrameAvailable(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::MarkExternalTextureFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  if (!engine) {
    return kInvalidArguments;
  }
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.MarkExternalTextureFrameAvailable) {
    return s_procs.MarkExternalTextureFrameAvailable(engine, texture_id);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::RegisterExternalTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::RegisterExternalTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!engine) {
    return kInvalidArguments;
  }
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.RegisterExternalTexture) {
    return s_procs.RegisterExternalTexture(engine, texture_id);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::UnregisterExternalTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::UnregisterExternalTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!engine) {
    return kInvalidArguments;
  }
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.UnregisterExternalTexture) {
    return s_procs.UnregisterExternalTexture(engine, texture_id);
  }
  return kInternalInconsistency;
}

std::shared_ptr<AndroidVulkanTextureProvider>
FlutterEmbedderNative::GetVulkanTextureProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetVulkanTextureProvider");
  return vulkan_texture_provider_;
}

void FlutterEmbedderNative::SetVulkanTextureProvider(
    std::shared_ptr<AndroidVulkanTextureProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVulkanTextureProvider");
  vulkan_texture_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidVulkanTextureProvider>(
                     library_loader_);
  if (jni_delegate_) {
    jni_delegate_->SetVulkanTextureProvider(vulkan_texture_provider_);
  }
}

bool FlutterEmbedderNative::RegisterVulkanTexture(
    int64_t texture_id,
    const std::shared_ptr<AndroidVulkanExternalTexture>& initial_texture)
    const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::RegisterVulkanTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  bool registered = jni_router_->RouteRegisterVulkanTexture(texture_id);
  if (registered && initial_texture) {
    jni_router_->RouteSetVulkanTextureFrame(texture_id, initial_texture);
  }
  return registered;
}

bool FlutterEmbedderNative::UnregisterVulkanTexture(int64_t texture_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::UnregisterVulkanTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteUnregisterVulkanTexture(texture_id);
}

bool FlutterEmbedderNative::SetVulkanTextureFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidVulkanExternalTexture>& texture) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::SetVulkanTextureFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetVulkanTextureFrame(texture_id, texture);
}

bool FlutterEmbedderNative::SetVulkanTextureFrame(
    int64_t texture_id,
    const FlutterVulkanExternalTexture& texture) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::SetVulkanTextureFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetVulkanTextureFrame(texture_id, texture);
}

bool FlutterEmbedderNative::GetVulkanTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::GetVulkanTextureFrame",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteGetVulkanTextureFrame(texture_id, width, height,
                                                 texture_out);
}

bool FlutterEmbedderNative::OnVulkanTextureFrameAvailable(
    int64_t texture_id) const {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::OnVulkanTextureFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteOnVulkanTextureFrameAvailable(texture_id);
}

bool FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback(
    void* user_data,
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback",
               "texture_id", std::to_string(texture_id).c_str());
  if (!user_data || !texture_out) {
    return false;
  }
  auto* native_instance = static_cast<FlutterEmbedderNative*>(user_data);
  return native_instance->GetVulkanTextureFrame(texture_id, width, height,
                                                texture_out);
}

FlutterVulkanExternalTextureFrameCallback
FlutterEmbedderNative::GetVulkanExternalTextureFrameCallback() {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::GetVulkanExternalTextureFrameCallback");
  return &FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback;
}

std::shared_ptr<AndroidSurfaceControlProvider>
FlutterEmbedderNative::GetSurfaceControlProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetSurfaceControlProvider");
  return surface_control_provider_;
}

void FlutterEmbedderNative::SetSurfaceControlProvider(
    std::shared_ptr<AndroidSurfaceControlProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetSurfaceControlProvider");
  surface_control_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidSurfaceControlProvider>(
                     library_loader_);
  if (jni_delegate_) {
    jni_delegate_->SetSurfaceControlProvider(surface_control_provider_);
  }
}

}  // namespace android
}  // namespace flutter
