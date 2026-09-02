// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <iostream>
#if defined(__ANDROID__)
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES3/gl3.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#endif

#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif
#ifndef GL_RGBA8_OES
#define GL_RGBA8_OES 0x8058
#endif

#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_main.h"

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

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;
static jfieldID g_jni_shell_holder_field = nullptr;
static jmethodID g_jni_constructor = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_java_long_class = nullptr;
static jmethodID g_long_constructor = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_callback_info_class =
    nullptr;
static jmethodID g_flutter_callback_info_constructor = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_weak_reference_class = nullptr;
static jmethodID g_weak_reference_get = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_surface_texture_wrapper_class =
    nullptr;
static jmethodID g_surface_texture_wrapper_attach_to_gl_context = nullptr;
static jmethodID g_surface_texture_wrapper_update_tex_image = nullptr;
static jmethodID g_surface_texture_wrapper_detach_from_gl_context = nullptr;
static jmethodID g_surface_texture_wrapper_release = nullptr;

static FlutterEngineResult EngineShutdown(FLUTTER_API_SYMBOL(FlutterEngine)
                                              engine);

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
      engine_group_provider_(
          std::make_shared<DefaultAndroidEngineGroupProvider>()),
      engine_group_(std::make_shared<AndroidEngineGroup>(engine_group_provider_,
                                                         jvm_invoker_)),
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
                                                  surface_control_provider_,
                                                  engine_group_provider_,
                                                  engine_group_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)),
      asset_provider_(std::make_shared<APKAssetProvider>(
          std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterEmbedderNative");
  if (FlutterMain::IsInitialized() && platform_views_provider_) {
    platform_views_provider_->SetHcppEnabled(
        FlutterMain::Get().GetSettings().enable_surface_control);
  }
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
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group)
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
      engine_group_provider_(
          engine_group_provider
              ? std::move(engine_group_provider)
              : std::make_shared<DefaultAndroidEngineGroupProvider>()),
      engine_group_(engine_group ? std::move(engine_group)
                                 : std::make_shared<AndroidEngineGroup>(
                                       engine_group_provider_,
                                       jvm_invoker_)),
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
                                                  surface_control_provider_,
                                                  engine_group_provider_,
                                                  engine_group_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, legacy_delegate)),
      asset_provider_(
          asset_provider
              ? std::move(asset_provider)
              : std::make_shared<APKAssetProvider>(
                    std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterEmbedderNative(custom)");
  if (FlutterMain::IsInitialized() && platform_views_provider_) {
    platform_views_provider_->SetHcppEnabled(
        FlutterMain::Get().GetSettings().enable_surface_control);
  }
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with custom components.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  if (vsync_waiter_) {
    vsync_waiter_->SetEngine(nullptr);
  }
  if (engine_) {
    EngineShutdown(engine_);
    engine_ = nullptr;
  }
  TeardownEGL();
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
  return true;
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

static std::shared_ptr<AndroidVsyncWaiter> g_default_vsync_waiter = nullptr;

void FlutterEmbedderNative::SetDefaultVsyncWaiter(
    std::shared_ptr<AndroidVsyncWaiter> waiter) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetDefaultVsyncWaiter");
  g_default_vsync_waiter = std::move(waiter);
}

std::shared_ptr<AndroidVsyncWaiter>
FlutterEmbedderNative::GetDefaultVsyncWaiter() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetDefaultVsyncWaiter");
  if (!g_default_vsync_waiter) {
    g_default_vsync_waiter = std::make_shared<AndroidVsyncWaiter>(
        std::make_shared<DefaultAndroidChoreographerProvider>(),
        std::make_shared<DefaultJvmInvoker>());
  }
  return g_default_vsync_waiter;
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
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(
      std::move(invoker), nullptr, nullptr, std::move(platform_views_provider),
      std::move(window_metrics_provider), std::move(vsync_waiter),
      std::move(vm_init), std::move(hardware_buffer_provider),
      std::move(vulkan_texture_provider), std::move(surface_control_provider),
      std::move(engine_group_provider), std::move(engine_group));
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

FlutterCustomAssetResolver FlutterEmbedderNative::CreateCustomAssetResolver() {
  FlutterCustomAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterCustomAssetResolver);
  resolver.user_data = this;
  resolver.get_asset = [](const char* asset_name, const uint8_t** buffer_out,
                          size_t* size_out, void** allocation_baton_out,
                          void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    if (!native || !asset_name || !buffer_out || !size_out ||
        !allocation_baton_out) {
      return false;
    }
    auto mapping = native->ResolveAsset(asset_name);
    if (!mapping || !mapping->GetMapping()) {
      return false;
    }
    *buffer_out = mapping->GetMapping();
    *size_out = mapping->GetSize();
    *allocation_baton_out = mapping.release();
    return true;
  };
  resolver.free_asset = [](void* allocation_baton, void* user_data) {
    auto* mapping = reinterpret_cast<fml::Mapping*>(allocation_baton);
    delete mapping;
  };
  return resolver;
}

static FlutterEngineResult EngineUpdateAssetResolver(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterCustomAssetResolver* resolver) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.UpdateAssetResolver) {
    return s_procs.UpdateAssetResolver(engine, resolver);
  }
  return kInternalInconsistency;
}

void FlutterEmbedderNative::UpdateAssetManager(JNIEnv* env,
                                               jobject jasset_manager,
                                               const std::string& bundle_path) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateAssetManager");
  if (jasset_manager != nullptr) {
    auto asset_provider =
        std::make_shared<APKAssetProvider>(env, jasset_manager, bundle_path);
    SetAssetProvider(std::move(asset_provider));
  }
  if (engine_) {
    FlutterCustomAssetResolver custom_resolver = CreateCustomAssetResolver();
    EngineUpdateAssetResolver(engine_, &custom_resolver);
  }
  GetRouter()->RouteAssetManagerChanged();
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
  if (FlutterMain::IsInitialized() && platform_views_provider_) {
    platform_views_provider_->SetHcppEnabled(
        FlutterMain::Get().GetSettings().enable_surface_control);
  }
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

static FlutterEngineResult EngineRunInitialized(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.RunInitialized) {
    return s_procs.RunInitialized(engine);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineShutdown(FLUTTER_API_SYMBOL(FlutterEngine)
                                              engine) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.Shutdown) {
    return s_procs.Shutdown(engine);
  }
  if (s_procs.Deinitialize) {
    return s_procs.Deinitialize(engine);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineSendPlatformMessage(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPlatformMessage* message) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendPlatformMessage) {
    return s_procs.SendPlatformMessage(engine, message);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineCreateResponseHandle(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterDataCallback data_callback,
    void* user_data,
    FlutterPlatformMessageResponseHandle** response_out) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.PlatformMessageCreateResponseHandle) {
    return s_procs.PlatformMessageCreateResponseHandle(engine, data_callback,
                                                       user_data, response_out);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineReleaseResponseHandle(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterPlatformMessageResponseHandle* response) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.PlatformMessageReleaseResponseHandle) {
    return s_procs.PlatformMessageReleaseResponseHandle(engine, response);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineSendPlatformMessageResponse(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendPlatformMessageResponse) {
    return s_procs.SendPlatformMessageResponse(engine, handle, data,
                                               data_length);
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

FlutterEngineResult FlutterEmbedderNative::ScheduleFrame(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ScheduleFrame");
  if (!engine) {
    return kInvalidArguments;
  }
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.ScheduleFrame) {
    return s_procs.ScheduleFrame(engine);
  }
  return kInternalInconsistency;
}

void FlutterEmbedderNative::RegisterSurfaceTexture(JNIEnv* env,
                                                   int64_t texture_id,
                                                   jobject surface_texture) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::RegisterSurfaceTexture",
               "texture_id", std::to_string(texture_id).c_str());
  std::scoped_lock lock(surface_textures_mutex_);
  auto entry = std::make_unique<SurfaceTextureEntry>();
  if (surface_texture != nullptr && env != nullptr) {
    entry->weak_surface_texture.Reset(env, surface_texture);
  }
  surface_textures_[texture_id] = std::move(entry);
}

void FlutterEmbedderNative::UnregisterSurfaceTexture(JNIEnv* env,
                                                     int64_t texture_id) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::UnregisterSurfaceTexture",
               "texture_id", std::to_string(texture_id).c_str());
  std::scoped_lock lock(surface_textures_mutex_);
  auto it = surface_textures_.find(texture_id);
  if (it != surface_textures_.end()) {
#if defined(__ANDROID__)
    if (it->second && it->second->gl_texture_id != 0) {
      glDeleteTextures(1, &it->second->gl_texture_id);
      it->second->gl_texture_id = 0;
    }
#endif
    surface_textures_.erase(it);
  }
}

bool FlutterEmbedderNative::GetGlExternalTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLTexture* texture_out) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::GetGlExternalTextureFrame",
               "texture_id", std::to_string(texture_id).c_str());
  if (!texture_out) {
    return false;
  }

  std::scoped_lock lock(surface_textures_mutex_);
  auto it = surface_textures_.find(texture_id);
  if (it == surface_textures_.end() || !it->second) {
    return false;
  }

  auto& entry = *it->second;

  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }

  if (entry.weak_surface_texture.is_null()) {
    return false;
  }

  if (!g_weak_reference_get) {
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> wrapper(
      env, env->CallObjectMethod(entry.weak_surface_texture.obj(),
                                 g_weak_reference_get));
  if (wrapper.is_null()) {
    return false;
  }

#if defined(__ANDROID__)
  if (entry.gl_texture_id == 0) {
    glGenTextures(1, &entry.gl_texture_id);
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, entry.gl_texture_id);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S,
                    GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T,
                    GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  }

  if (!entry.attached && g_surface_texture_wrapper_attach_to_gl_context) {
    env->CallVoidMethod(wrapper.obj(),
                        g_surface_texture_wrapper_attach_to_gl_context,
                        static_cast<jint>(entry.gl_texture_id));
    entry.attached = true;
  }

  if (g_surface_texture_wrapper_update_tex_image) {
    env->CallVoidMethod(wrapper.obj(),
                        g_surface_texture_wrapper_update_tex_image);
  }

  texture_out->target = GL_TEXTURE_EXTERNAL_OES;
  texture_out->name = entry.gl_texture_id;
  texture_out->format = GL_RGBA8_OES;
  texture_out->width = width;
  texture_out->height = height;
  texture_out->user_data = nullptr;
  texture_out->destruction_callback = nullptr;
  return true;
#else
  if (entry.gl_texture_id == 0) {
    entry.gl_texture_id = static_cast<uint32_t>(texture_id);
  }
  texture_out->target = 0x8D65;  // GL_TEXTURE_EXTERNAL_OES
  texture_out->name = entry.gl_texture_id;
  texture_out->format = 0x8058;  // GL_RGBA8
  texture_out->width = width;
  texture_out->height = height;
  texture_out->user_data = nullptr;
  texture_out->destruction_callback = nullptr;
  return true;
#endif
}

bool FlutterEmbedderNative::OnGlExternalTextureFrameCallback(
    void* user_data,
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLTexture* texture_out) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::OnGlExternalTextureFrameCallback",
               "texture_id", std::to_string(texture_id).c_str());
  if (!user_data || !texture_out) {
    return false;
  }
  auto* native_instance = static_cast<FlutterEmbedderNative*>(user_data);
  return native_instance->GetGlExternalTextureFrame(texture_id, width, height,
                                                    texture_out);
}

void FlutterEmbedderNative::MarkAllTexturesFrameAvailable() const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::MarkAllTexturesFrameAvailable");
  if (!engine_) {
    return;
  }
  std::scoped_lock lock(surface_textures_mutex_);
  for (const auto& [texture_id, entry] : surface_textures_) {
    MarkExternalTextureFrameAvailable(engine_, texture_id);
  }
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

std::shared_ptr<AndroidEngineGroup> FlutterEmbedderNative::GetEngineGroup()
    const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEngineGroup");
  return engine_group_;
}

void FlutterEmbedderNative::SetEngineGroup(
    std::shared_ptr<AndroidEngineGroup> group) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEngineGroup");
  engine_group_ = std::move(group);
  if (jni_delegate_) {
    jni_delegate_->SetEngineGroup(engine_group_);
  }
}

std::shared_ptr<AndroidEngineGroupProvider>
FlutterEmbedderNative::GetEngineGroupProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEngineGroupProvider");
  return engine_group_provider_;
}

void FlutterEmbedderNative::SetEngineGroupProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEngineGroupProvider");
  engine_group_provider_ = std::move(provider);
  if (engine_group_) {
    engine_group_->SetProvider(engine_group_provider_);
  }
  if (jni_delegate_) {
    jni_delegate_->SetEngineGroupProvider(engine_group_provider_);
  }
}

FLUTTER_API_SYMBOL(FlutterEngine)
FlutterEmbedderNative::SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                       parent_engine,
                                   const AndroidEngineSpawnArgs& args) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SpawnEngine", "entrypoint",
               args.entrypoint.c_str());
  if (engine_group_) {
    return engine_group_->SpawnEngine(parent_engine, args);
  }
  if (!parent_engine || !engine_group_provider_) {
    return nullptr;
  }
  AndroidEngineGroupSpawnConfigHolder holder;
  holder.Build(args);
  FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine = nullptr;
  if (engine_group_provider_->SpawnEngine(parent_engine,
                                          holder.GetSpawnConfig(),
                                          &spawned_engine) == kSuccess) {
    return spawned_engine;
  }
  return nullptr;
}

FLUTTER_API_SYMBOL(FlutterEngine)
FlutterEmbedderNative::SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                       parent_engine,
                                   const FlutterEngineSpawnConfig* config,
                                   int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SpawnEngine(config)",
               "engine_id", std::to_string(engine_id).c_str());
  if (engine_group_) {
    return engine_group_->SpawnEngineWithConfig(parent_engine, config,
                                                engine_id);
  }
  if (!parent_engine || !config || !engine_group_provider_) {
    return nullptr;
  }
  FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine = nullptr;
  if (engine_group_provider_->SpawnEngine(parent_engine, config,
                                          &spawned_engine) == kSuccess) {
    return spawned_engine;
  }
  return nullptr;
}

FlutterEngineResult FlutterEmbedderNative::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnConfig* config,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SpawnEngine(raw)");
  if (!engine_group_provider_) {
    return kInternalInconsistency;
  }
  return engine_group_provider_->SpawnEngine(parent_engine, config, engine_out);
}

FlutterEngineResult FlutterEmbedderNative::ShutdownEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ShutdownEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  if (engine_group_ && engine_group_->IsEngineActive(engine)) {
    return engine_group_->ShutdownEngine(engine) ? kSuccess : kInvalidArguments;
  }
  if (engine_group_provider_) {
    return engine_group_provider_->ShutdownEngine(engine);
  }
  return kInternalInconsistency;
}

bool FlutterEmbedderNative::ShutdownSpawnedEngine(int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ShutdownSpawnedEngine",
               "engine_id", std::to_string(engine_id).c_str());
  if (jni_router_) {
    return jni_router_->RouteShutdownSpawnedEngine(engine_id);
  }
  if (engine_group_) {
    return engine_group_->ShutdownEngine(engine_id);
  }
  return false;
}

bool FlutterEmbedderNative::OnEngineGarbageCollected(int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::OnEngineGarbageCollected",
               "engine_id", std::to_string(engine_id).c_str());
  if (jni_router_) {
    return jni_router_->RouteOnEngineGarbageCollected(engine_id);
  }
  if (engine_group_) {
    return engine_group_->OnEngineGarbageCollected(engine_id);
  }
  return false;
}

size_t FlutterEmbedderNative::GetActiveEngineCount() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetActiveEngineCount");
  if (jni_router_) {
    return jni_router_->RouteGetActiveEngineCount();
  }
  if (engine_group_) {
    return engine_group_->GetActiveEngineCount();
  }
  return 0;
}

FLUTTER_API_SYMBOL(FlutterEngine) FlutterEmbedderNative::GetEngine() const {
  return engine_;
}

void FlutterEmbedderNative::OnPlatformMessageCallback(
    const FlutterPlatformMessage* message,
    void* user_data) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnPlatformMessageCallback");
  if (!message || !user_data) {
    return;
  }
  auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
  std::string channel = message->channel ? message->channel : "";
  bool has_data = (message->message != nullptr);
  std::vector<uint8_t> data;
  if (message->message && message->message_size > 0) {
    data.assign(message->message, message->message + message->message_size);
  }
  int32_t response_id = 0;
  if (message->response_handle != nullptr) {
    response_id = native->next_response_id_++;
    std::scoped_lock lock(native->response_mutex_);
    native->pending_responses_[response_id] = message->response_handle;
  }
  native->GetRouter()->RoutePlatformMessage(channel, data, response_id,
                                            has_data);
}

static FlutterEngineResult EngineSendPointerEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPointerEvent* events,
    size_t events_count) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendPointerEvent) {
    return s_procs.SendPointerEvent(engine, events, events_count);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::SendPointerEvents(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPointerEvent* events,
    size_t events_count) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPointerEvents", "count",
               std::to_string(events_count).c_str());
  if (!engine || !events || events_count == 0) {
    return kInvalidArguments;
  }
  return EngineSendPointerEvent(engine, events, events_count);
}

void FlutterEmbedderNative::DispatchPointerDataPacket(const uint8_t* buffer,
                                                      size_t size) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::DispatchPointerDataPacket",
               "size", std::to_string(size).c_str());
  if (!buffer || size == 0 || !engine_) {
    return;
  }
  constexpr size_t kPointerRecordSize = 36 * sizeof(int64_t);
  size_t record_count = size / kPointerRecordSize;
  if (record_count == 0) {
    return;
  }
  std::vector<FlutterPointerEvent> events;
  events.reserve(record_count);
  for (size_t i = 0; i < record_count; ++i) {
    const int64_t* fields =
        reinterpret_cast<const int64_t*>(buffer + i * kPointerRecordSize);
    const double* dfields = reinterpret_cast<const double*>(fields);

    FlutterPointerEvent event = {};
    event.struct_size = sizeof(FlutterPointerEvent);
    event.timestamp = static_cast<size_t>(fields[1]);

    int64_t change = fields[2];
    switch (change) {
      case 0:
        event.phase = kCancel;
        break;
      case 1:
        event.phase = kAdd;
        break;
      case 2:
        event.phase = kRemove;
        break;
      case 3:
        event.phase = kHover;
        break;
      case 4:
        event.phase = kDown;
        break;
      case 5:
        event.phase = kMove;
        break;
      case 6:
        event.phase = kUp;
        break;
      case 7:
        event.phase = kPanZoomStart;
        break;
      case 8:
        event.phase = kPanZoomUpdate;
        break;
      case 9:
        event.phase = kPanZoomEnd;
        break;
      default:
        event.phase = kCancel;
        break;
    }

    int64_t kind = fields[3];
    switch (kind) {
      case 0:
        event.device_kind = kFlutterPointerDeviceKindTouch;
        break;
      case 1:
        event.device_kind = kFlutterPointerDeviceKindMouse;
        break;
      case 2:
        event.device_kind = kFlutterPointerDeviceKindStylus;
        break;
      case 3:
        event.device_kind = kFlutterPointerDeviceKindInvertedStylus;
        break;
      case 4:
        event.device_kind = kFlutterPointerDeviceKindTrackpad;
        break;
      default:
        event.device_kind = kFlutterPointerDeviceKindTouch;
        break;
    }

    int64_t signal = fields[4];
    switch (signal) {
      case 0:
        event.signal_kind = kFlutterPointerSignalKindNone;
        break;
      case 1:
        event.signal_kind = kFlutterPointerSignalKindScroll;
        break;
      case 2:
        event.signal_kind = kFlutterPointerSignalKindScrollInertiaCancel;
        break;
      case 3:
        event.signal_kind = kFlutterPointerSignalKindScale;
        break;
      default:
        event.signal_kind = kFlutterPointerSignalKindNone;
        break;
    }

    event.device = static_cast<int32_t>(fields[5]);
    event.x = dfields[7];
    event.y = dfields[8];
    event.buttons = fields[11];
    event.pressure = dfields[14];
    event.pressure_min = dfields[15];
    event.pressure_max = dfields[16];
    event.distance = dfields[17];
    event.distance_max = dfields[18];
    event.size = dfields[19];
    event.radius_major = dfields[20];
    event.radius_minor = dfields[21];
    event.radius_min = dfields[22];
    event.radius_max = dfields[23];
    event.orientation = dfields[24];
    event.tilt = dfields[25];
    event.platform_data = fields[26];
    event.scroll_delta_x = dfields[27];
    event.scroll_delta_y = dfields[28];
    event.pan_x = dfields[29];
    event.pan_y = dfields[30];
    event.scale = dfields[33];
    event.rotation = dfields[34];
    event.view_id = static_cast<FlutterViewId>(fields[35]);

    events.push_back(event);
  }

  if (!events.empty()) {
    SendPointerEvents(engine_, events.data(), events.size());
  }
}

bool FlutterEmbedderNative::EnsureEGLInitialized() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::EnsureEGLInitialized");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (egl_initialized_) {
    return true;
  }
  display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display_ == EGL_NO_DISPLAY) {
    FML_LOG(ERROR) << "Failed to get EGL display: " << eglGetError();
    return false;
  }
  EGLint major = 0;
  EGLint minor = 0;
  if (!eglInitialize(display_, &major, &minor)) {
    FML_LOG(ERROR) << "Failed to initialize EGL: " << eglGetError();
    return false;
  }
  const EGLint config_attribs[] = {
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT | EGL_OPENGL_ES3_BIT,
      EGL_SURFACE_TYPE,
      EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
      EGL_RED_SIZE,
      8,
      EGL_GREEN_SIZE,
      8,
      EGL_BLUE_SIZE,
      8,
      EGL_ALPHA_SIZE,
      8,
      EGL_DEPTH_SIZE,
      0,
      EGL_STENCIL_SIZE,
      8,
      EGL_NONE,
  };
  EGLint num_configs = 0;
  if (!eglChooseConfig(display_, config_attribs, &config_, 1, &num_configs) ||
      num_configs < 1) {
    const EGLint fallback_attribs[] = {
        EGL_RENDERABLE_TYPE,
        EGL_OPENGL_ES2_BIT,
        EGL_SURFACE_TYPE,
        EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
        EGL_RED_SIZE,
        8,
        EGL_GREEN_SIZE,
        8,
        EGL_BLUE_SIZE,
        8,
        EGL_ALPHA_SIZE,
        8,
        EGL_DEPTH_SIZE,
        0,
        EGL_STENCIL_SIZE,
        8,
        EGL_NONE,
    };
    if (!eglChooseConfig(display_, fallback_attribs, &config_, 1,
                         &num_configs) ||
        num_configs < 1) {
      FML_LOG(ERROR) << "Failed to choose EGL config: " << eglGetError();
      return false;
    }
  }

  const EGLint gles3_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      3,
      EGL_NONE,
  };
  render_context_ =
      eglCreateContext(display_, config_, EGL_NO_CONTEXT, gles3_attribs);
  if (render_context_ == EGL_NO_CONTEXT) {
    const EGLint gles2_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION,
        2,
        EGL_NONE,
    };
    render_context_ =
        eglCreateContext(display_, config_, EGL_NO_CONTEXT, gles2_attribs);
  }
  if (render_context_ == EGL_NO_CONTEXT) {
    FML_LOG(ERROR) << "Failed to create EGL render context: " << eglGetError();
    return false;
  }

  const EGLint resource_gles3_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      3,
      EGL_NONE,
  };
  resource_context_ = eglCreateContext(display_, config_, render_context_,
                                       resource_gles3_attribs);
  if (resource_context_ == EGL_NO_CONTEXT) {
    const EGLint resource_gles2_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION,
        2,
        EGL_NONE,
    };
    resource_context_ = eglCreateContext(display_, config_, render_context_,
                                         resource_gles2_attribs);
  }

  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE,
  };
  pbuffer_surface_ =
      eglCreatePbufferSurface(display_, config_, pbuffer_attribs);
  if (pbuffer_surface_ == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "Failed to create EGL pbuffer surface: " << eglGetError();
  }

  egl_initialized_ = true;
  return true;
#else
  return true;
#endif
}

void FlutterEmbedderNative::TeardownEGL() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::TeardownEGL");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (display_ != EGL_NO_DISPLAY) {
    eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    if (window_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, window_surface_);
      window_surface_ = EGL_NO_SURFACE;
    }
    if (pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, pbuffer_surface_);
      pbuffer_surface_ = EGL_NO_SURFACE;
    }
    if (render_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, render_context_);
      render_context_ = EGL_NO_CONTEXT;
    }
    if (resource_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, resource_context_);
      resource_context_ = EGL_NO_CONTEXT;
    }
    display_ = EGL_NO_DISPLAY;
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
  egl_initialized_ = false;
#endif
}

bool FlutterEmbedderNative::MakeCurrent() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::MakeCurrent");
#if defined(__ANDROID__)
  EnsureEGLInitialized();
  std::lock_guard<std::mutex> lock(surface_mutex_);
  EGLSurface surface =
      (window_surface_ != EGL_NO_SURFACE) ? window_surface_ : pbuffer_surface_;
  if (display_ == EGL_NO_DISPLAY || surface == EGL_NO_SURFACE ||
      render_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  return eglMakeCurrent(display_, surface, surface, render_context_) ==
         EGL_TRUE;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::ClearCurrent() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ClearCurrent");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (display_ == EGL_NO_DISPLAY) {
    return false;
  }
  return eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::MakeResourceCurrent() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::MakeResourceCurrent");
#if defined(__ANDROID__)
  EnsureEGLInitialized();
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (display_ == EGL_NO_DISPLAY || pbuffer_surface_ == EGL_NO_SURFACE ||
      resource_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  return eglMakeCurrent(display_, pbuffer_surface_, pbuffer_surface_,
                        resource_context_) == EGL_TRUE;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::Present() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Present");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (display_ == EGL_NO_DISPLAY || window_surface_ == EGL_NO_SURFACE) {
    return true;
  }
  return eglSwapBuffers(display_, window_surface_) == EGL_TRUE;
#else
  return true;
#endif
}

uint32_t FlutterEmbedderNative::FboCallback() const {
  return 0;
}

void* FlutterEmbedderNative::GlProcResolver(const char* name) const {
#if defined(__ANDROID__)
  return reinterpret_cast<void*>(eglGetProcAddress(name));
#else
  return nullptr;
#endif
}

void FlutterEmbedderNative::SurfaceCreated(JNIEnv* env, jobject jsurface) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceCreated");
#if defined(__ANDROID__)
  EnsureEGLInitialized();
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (window_surface_ != EGL_NO_SURFACE && display_ != EGL_NO_DISPLAY) {
    eglDestroySurface(display_, window_surface_);
    window_surface_ = EGL_NO_SURFACE;
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
  if (env && jsurface) {
    native_window_ = ANativeWindow_fromSurface(env, jsurface);
    if (native_window_ && display_ != EGL_NO_DISPLAY && config_ != nullptr) {
      window_surface_ =
          eglCreateWindowSurface(display_, config_, native_window_, nullptr);
    }
  }
#endif
  if (jni_router_) {
    jni_router_->RouteFirstFrame();
  }
}

void FlutterEmbedderNative::SurfaceWindowChanged(JNIEnv* env,
                                                 jobject jsurface) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceWindowChanged");
#if defined(__ANDROID__)
  EnsureEGLInitialized();
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (window_surface_ != EGL_NO_SURFACE && display_ != EGL_NO_DISPLAY) {
    eglDestroySurface(display_, window_surface_);
    window_surface_ = EGL_NO_SURFACE;
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
  if (env && jsurface) {
    native_window_ = ANativeWindow_fromSurface(env, jsurface);
    if (native_window_ && display_ != EGL_NO_DISPLAY && config_ != nullptr) {
      window_surface_ =
          eglCreateWindowSurface(display_, config_, native_window_, nullptr);
    }
  }
#endif
}

void FlutterEmbedderNative::SurfaceChanged(int32_t width, int32_t height) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceChanged");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (native_window_) {
    ANativeWindow_setBuffersGeometry(native_window_, width, height, 0);
  }
#endif
  AndroidViewportMetrics metrics;
  if (window_metrics_provider_) {
    auto current = window_metrics_provider_->GetViewportMetrics(0);
    if (current.has_value()) {
      metrics = *current;
    }
  }
  metrics.physical_width = width;
  metrics.physical_height = height;
  SetViewportMetrics(metrics);
  if (engine_) {
    SendWindowMetricsEvent(engine_, metrics);
  }
}

void FlutterEmbedderNative::SurfaceDestroyed() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceDestroyed");
#if defined(__ANDROID__)
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (window_surface_ != EGL_NO_SURFACE && display_ != EGL_NO_DISPLAY) {
    eglDestroySurface(display_, window_surface_);
    window_surface_ = EGL_NO_SURFACE;
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
#endif
}

FlutterEngineResult FlutterEmbedderNative::RunEngineWithBundle(
    const std::string& bundle_path,
    const std::string& entrypoint,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::RunEngineWithBundle",
               "engine_id", std::to_string(engine_id).c_str());
  if (engine_ != nullptr) {
    return kSuccess;
  }

  if (vm_init_ && !vm_init_->IsInitialized() && FlutterMain::IsInitialized()) {
    vm_init_->Init(FlutterMain::Get().GetVMArgs());
  }

  EnsureEGLInitialized();

  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  config.open_gl.make_current = [](void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->MakeCurrent() : false;
  };
  config.open_gl.clear_current = [](void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->ClearCurrent() : false;
  };
  config.open_gl.present = [](void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->Present() : false;
  };
  config.open_gl.fbo_callback = [](void* user_data) -> uint32_t {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->FboCallback() : 0;
  };
  config.open_gl.make_resource_current = [](void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->MakeResourceCurrent() : false;
  };
  config.open_gl.gl_proc_resolver = [](void* user_data,
                                       const char* name) -> void* {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    return native ? native->GlProcResolver(name) : nullptr;
  };
  config.open_gl.gl_external_texture_frame_callback =
      &FlutterEmbedderNative::OnGlExternalTextureFrameCallback;
  config.open_gl.hardware_buffer_external_texture_frame_callback =
      &FlutterEmbedderNative::OnHardwareBufferExternalTextureFrameCallback;

  FlutterProjectArgs project_args = {};
  if (vm_init_ && vm_init_->GetProjectArgs()) {
    project_args = *vm_init_->GetProjectArgs();
  } else {
    project_args.struct_size = sizeof(FlutterProjectArgs);
  }

  std::string assets_path = bundle_path;
  if (assets_path.empty() ||
      !fml::IsFile(fml::paths::JoinPaths({assets_path, "kernel_blob.bin"}))) {
    if (vm_init_) {
      const auto vm_args = vm_init_->GetVMArgs();
      if (vm_args.has_value() && !vm_args->kernel_path.empty()) {
        assets_path = fml::paths::GetDirectoryName(vm_args->kernel_path);
      }
    }
  }
  if (!assets_path.empty()) {
    project_args.assets_path = assets_path.c_str();
  }

  if (!entrypoint.empty()) {
    project_args.custom_dart_entrypoint = entrypoint.c_str();
  }

  std::vector<const char*> entrypoint_arg_ptrs;
  if (!entrypoint_args.empty()) {
    entrypoint_arg_ptrs.reserve(entrypoint_args.size());
    for (const auto& arg : entrypoint_args) {
      entrypoint_arg_ptrs.push_back(arg.c_str());
    }
    project_args.dart_entrypoint_argc =
        static_cast<int>(entrypoint_arg_ptrs.size());
    project_args.dart_entrypoint_argv = entrypoint_arg_ptrs.data();
  }

  project_args.platform_message_callback =
      &FlutterEmbedderNative::OnPlatformMessageCallback;
  project_args.vsync_callback = &FlutterEmbedderNative::OnVsyncCallback;
  project_args.update_semantics_callback2 =
      &FlutterEmbedderNative::OnUpdateSemantics2;

  if (project_args.log_message_callback == nullptr) {
    project_args.log_message_callback = [](const char* tag, const char* message,
                                           void* user_data) {
#if defined(__ANDROID__)
      __android_log_print(ANDROID_LOG_INFO, tag ? tag : "flutter", "%s",
                          message ? message : "");
#else
      if (tag && strlen(tag) > 0) {
        std::cout << tag << ": ";
      }
      if (message) {
        std::cout << message << std::endl;
      }
#endif
    };
  }

  FlutterCustomAssetResolver custom_asset_resolver =
      CreateCustomAssetResolver();
  project_args.custom_asset_resolver = &custom_asset_resolver;

  project_args.get_scaled_font_size_callback = [](double unscaled_font_size,
                                                  int configuration_id,
                                                  void* user_data) -> double {
    auto* native_instance = static_cast<FlutterEmbedderNative*>(user_data);
    if (!native_instance || !native_instance->GetRouter()) {
      return unscaled_font_size;
    }
    return native_instance->GetRouter()->RouteGetScaledFontSize(
        unscaled_font_size, configuration_id);
  };

  FlutterEngineResult result =
      InitializeEngine(&config, &project_args, this, &engine_);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "Failed to initialize Flutter Engine: " << result;
    return result;
  }

  if (vsync_waiter_) {
    vsync_waiter_->SetEngine(engine_);
  }

  result = EngineRunInitialized(engine_);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "Failed to run initialized Flutter Engine: " << result;
    if (vsync_waiter_) {
      vsync_waiter_->SetEngine(nullptr);
    }
    EngineShutdown(engine_);
    engine_ = nullptr;
    return result;
  }

  {
    std::scoped_lock lock(surface_textures_mutex_);
    for (const auto& [texture_id, entry] : surface_textures_) {
      RegisterExternalTexture(engine_, texture_id);
    }
  }

  return kSuccess;
}

struct OutgoingResponseContext {
  FlutterEmbedderNative* native;
  int32_t response_id;
  FlutterPlatformMessageResponseHandle* handle = nullptr;
};

static void OnOutgoingPlatformMessageResponse(const uint8_t* data,
                                              size_t size,
                                              void* user_data) {
  auto* ctx = reinterpret_cast<OutgoingResponseContext*>(user_data);
  if (!ctx) {
    return;
  }
  std::vector<uint8_t> response_data;
  bool has_data = (data != nullptr);
  if (data && size > 0) {
    response_data.assign(data, data + size);
  }
  if (ctx->native && ctx->native->GetRouter()) {
    ctx->native->GetRouter()->RoutePlatformMessageResponse(
        ctx->response_id, response_data, has_data);
  }
  if (ctx->native && ctx->native->GetEngine() && ctx->handle) {
    EngineReleaseResponseHandle(ctx->native->GetEngine(), ctx->handle);
  }
  delete ctx;
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessage(
    const std::string& channel,
    const uint8_t* message_data,
    size_t message_size,
    int32_t response_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPlatformMessage",
               "channel", channel.c_str());
  if (!engine_) {
    return kInternalInconsistency;
  }
  FlutterPlatformMessage platform_message = {};
  platform_message.struct_size = sizeof(FlutterPlatformMessage);
  platform_message.channel = channel.c_str();
  platform_message.message = message_data;
  platform_message.message_size = message_size;

  if (response_id != 0) {
    auto* ctx = new OutgoingResponseContext();
    ctx->native = const_cast<FlutterEmbedderNative*>(this);
    ctx->response_id = response_id;
    FlutterPlatformMessageResponseHandle* response_handle = nullptr;
    FlutterEngineResult res = EngineCreateResponseHandle(
        engine_, &OnOutgoingPlatformMessageResponse, ctx, &response_handle);
    if (res != kSuccess) {
      delete ctx;
      return res;
    }
    platform_message.response_handle = response_handle;
    ctx->handle = response_handle;
  }

  return EngineSendPlatformMessage(engine_, &platform_message);
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessage(
    const std::string& channel,
    const std::vector<uint8_t>& message,
    int32_t response_id) const {
  return SendPlatformMessage(channel,
                             message.empty() ? nullptr : message.data(),
                             message.size(), response_id);
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessageResponse(
    int32_t response_id,
    const uint8_t* data,
    size_t data_length) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPlatformMessageResponse",
               "response_id", std::to_string(response_id).c_str());
  if (!engine_) {
    return kInternalInconsistency;
  }
  const FlutterPlatformMessageResponseHandle* handle = nullptr;
  {
    std::scoped_lock lock(response_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it != pending_responses_.end()) {
      handle = it->second;
      pending_responses_.erase(it);
    }
  }
  if (!handle) {
    return kInvalidArguments;
  }
  return EngineSendPlatformMessageResponse(engine_, handle, data, data_length);
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data) const {
  return SendPlatformMessageResponse(
      response_id, data.empty() ? nullptr : data.data(), data.size());
}

static jlong FlutterJNI_Attach(JNIEnv* env, jclass clazz, jobject flutterJNI) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_Attach");
  auto jvm_invoker = std::make_shared<DefaultJvmInvoker>(env, flutterJNI);
  auto native_instance =
      std::make_unique<FlutterEmbedderNative>(std::move(jvm_invoker));
  return reinterpret_cast<jlong>(native_instance.release());
}

static void FlutterJNI_Destroy(JNIEnv* env,
                               jobject jcaller,
                               jlong native_handle) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_Destroy");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  delete native_instance;
}

static jobject FlutterJNI_Spawn(JNIEnv* env,
                                jobject jcaller,
                                jlong native_handle,
                                jstring jEntrypoint,
                                jstring jLibraryUrl,
                                jstring jInitialRoute,
                                jobject jEntrypointArgs,
                                jlong engineId) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::FlutterJNI_Spawn",
               "engine_id", std::to_string(engineId).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return nullptr;
  }

  AndroidEngineSpawnArgs spawn_args;
  if (jEntrypoint != nullptr) {
    spawn_args.entrypoint = fml::jni::JavaStringToString(env, jEntrypoint);
  }
  if (jLibraryUrl != nullptr) {
    spawn_args.library_url = fml::jni::JavaStringToString(env, jLibraryUrl);
  }
  if (jInitialRoute != nullptr) {
    spawn_args.initial_route = fml::jni::JavaStringToString(env, jInitialRoute);
  }
  if (jEntrypointArgs != nullptr) {
    spawn_args.entrypoint_args =
        fml::jni::StringListToVector(env, jEntrypointArgs);
  }
  spawn_args.engine_id = engineId;

  native_instance->GetRouter()->RouteSpawnEngine(engineId, spawn_args);
  auto spawned_instance = std::make_unique<FlutterEmbedderNative>();

  if (!g_flutter_jni_class || g_flutter_jni_class->is_null() ||
      !g_jni_constructor) {
    return nullptr;
  }

  jobject jni = env->NewObject(g_flutter_jni_class->obj(), g_jni_constructor);
  if (!jni) {
    return nullptr;
  }

  if (g_java_long_class && !g_java_long_class->is_null() &&
      g_long_constructor && g_jni_shell_holder_field) {
    jobject javaLong = env->CallStaticObjectMethod(
        g_java_long_class->obj(), g_long_constructor,
        reinterpret_cast<jlong>(spawned_instance.release()));
    if (javaLong != nullptr) {
      env->SetObjectField(jni, g_jni_shell_holder_field, javaLong);
    }
  }

  return jni;
}

static void FlutterJNI_RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                                       jobject jcaller,
                                                       jlong native_handle,
                                                       jstring jBundlePath,
                                                       jstring jEntrypoint,
                                                       jstring jLibraryUrl,
                                                       jobject jAssetManager,
                                                       jobject jEntrypointArgs,
                                                       jlong engineId) {
  TRACE_EVENT1(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_RunBundleAndSnapshotFromLibrary",
      "engine_id", std::to_string(engineId).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  std::string bundle_path =
      jBundlePath ? fml::jni::JavaStringToString(env, jBundlePath) : "";
  std::string entrypoint =
      jEntrypoint ? fml::jni::JavaStringToString(env, jEntrypoint) : "";
  std::vector<std::string> entrypoint_args;
  if (jEntrypointArgs != nullptr) {
    entrypoint_args = fml::jni::StringListToVector(env, jEntrypointArgs);
  }
  if (jAssetManager != nullptr) {
    auto asset_provider =
        std::make_shared<APKAssetProvider>(env, jAssetManager, bundle_path);
    native_instance->SetAssetProvider(std::move(asset_provider));
  }
  native_instance->GetRouter()->RouteAssetManagerChanged();
  native_instance->RunEngineWithBundle(bundle_path, entrypoint, entrypoint_args,
                                       engineId);
}

static void FlutterJNI_DispatchEmptyPlatformMessage(JNIEnv* env,
                                                    jobject jcaller,
                                                    jlong native_handle,
                                                    jstring channel,
                                                    jint responseId) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_DispatchEmptyPlatformMessage");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  std::string str_channel =
      channel ? fml::jni::JavaStringToString(env, channel) : "";
  if (native_instance->GetEngine()) {
    native_instance->SendPlatformMessage(str_channel, std::vector<uint8_t>(),
                                         responseId);
  }
}

static void FlutterJNI_CleanupMessageData(JNIEnv* env,
                                          jobject jcaller,
                                          jlong message_data) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_CleanupMessageData");
  free(reinterpret_cast<void*>(message_data));
}

static void FlutterJNI_DispatchPlatformMessage(JNIEnv* env,
                                               jobject jcaller,
                                               jlong native_handle,
                                               jstring channel,
                                               jobject message,
                                               jint position,
                                               jint responseId) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_DispatchPlatformMessage");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  std::string str_channel =
      channel ? fml::jni::JavaStringToString(env, channel) : "";
  const uint8_t* buffer = nullptr;
  uint8_t dummy = 0;
  if (message != nullptr) {
    if (position > 0) {
      buffer =
          static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
    } else {
      buffer = &dummy;
    }
  }
  if (native_instance->GetEngine()) {
    native_instance->SendPlatformMessage(str_channel, buffer, position,
                                         responseId);
  }
}

static void FlutterJNI_InvokePlatformMessageResponseCallback(
    JNIEnv* env,
    jobject jcaller,
    jlong native_handle,
    jint responseId,
    jobject message,
    jint position) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_"
               "InvokePlatformMessageResponseCallback");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  const uint8_t* buffer = nullptr;
  uint8_t dummy = 0;
  if (message != nullptr) {
    if (position > 0) {
      buffer =
          static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
    } else {
      buffer = &dummy;
    }
  }
  if (native_instance->GetEngine()) {
    native_instance->SendPlatformMessageResponse(responseId, buffer, position);
  }
}

static void FlutterJNI_InvokePlatformMessageEmptyResponseCallback(
    JNIEnv* env,
    jobject jcaller,
    jlong native_handle,
    jint responseId) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_"
               "InvokePlatformMessageEmptyResponseCallback");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  if (native_instance->GetEngine()) {
    native_instance->SendPlatformMessageResponse(responseId,
                                                 std::vector<uint8_t>());
  }
}

static void FlutterJNI_NotifyLowMemoryWarning(JNIEnv* env,
                                              jobject obj,
                                              jlong native_handle) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_NotifyLowMemoryWarning");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  if (native_instance->GetEngine()) {
    static FlutterEngineProcTable s_procs = []() {
      FlutterEngineProcTable procs = {};
      procs.struct_size = sizeof(FlutterEngineProcTable);
      FlutterEngineGetProcAddresses(&procs);
      return procs;
    }();
    if (s_procs.NotifyLowMemoryWarning) {
      s_procs.NotifyLowMemoryWarning(native_instance->GetEngine());
    }
  }
}

static jobject FlutterJNI_GetBitmap(JNIEnv* env,
                                    jobject jcaller,
                                    jlong native_handle) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_GetBitmap");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return nullptr;
  }
  return nullptr;
}

static void FlutterJNI_SurfaceCreated(JNIEnv* env,
                                      jobject jcaller,
                                      jlong native_handle,
                                      jobject jsurface) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_SurfaceCreated");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->SurfaceCreated(env, jsurface);
}

static void FlutterJNI_SurfaceWindowChanged(JNIEnv* env,
                                            jobject jcaller,
                                            jlong native_handle,
                                            jobject jsurface) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_SurfaceWindowChanged");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->SurfaceWindowChanged(env, jsurface);
}

static void FlutterJNI_SurfaceChanged(JNIEnv* env,
                                      jobject jcaller,
                                      jlong native_handle,
                                      jint width,
                                      jint height) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_SurfaceChanged");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->SurfaceChanged(width, height);
}

static void FlutterJNI_SurfaceDestroyed(JNIEnv* env,
                                        jobject jcaller,
                                        jlong native_handle) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_SurfaceDestroyed");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->SurfaceDestroyed();
}

static void FlutterJNI_SetViewportMetrics(
    JNIEnv* env,
    jobject jcaller,
    jlong native_handle,
    jfloat devicePixelRatio,
    jint physicalWidth,
    jint physicalHeight,
    jint physicalPaddingTop,
    jint physicalPaddingRight,
    jint physicalPaddingBottom,
    jint physicalPaddingLeft,
    jint physicalViewInsetTop,
    jint physicalViewInsetRight,
    jint physicalViewInsetBottom,
    jint physicalViewInsetLeft,
    jint systemGestureInsetTop,
    jint systemGestureInsetRight,
    jint systemGestureInsetBottom,
    jint systemGestureInsetLeft,
    jint physicalTouchSlop,
    jintArray javaDisplayFeaturesBounds,
    jintArray javaDisplayFeaturesType,
    jintArray javaDisplayFeaturesState,
    jint physicalMinWidth,
    jint physicalMaxWidth,
    jint physicalMinHeight,
    jint physicalMaxHeight,
    jint physicalDisplayCornerRadiusTopLeft,
    jint physicalDisplayCornerRadiusTopRight,
    jint physicalDisplayCornerRadiusBottomRight,
    jint physicalDisplayCornerRadiusBottomLeft) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_SetViewportMetrics");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }

  AndroidViewportMetrics metrics;
  metrics.device_pixel_ratio = devicePixelRatio;
  metrics.physical_width = physicalWidth;
  metrics.physical_height = physicalHeight;
  metrics.physical_padding_top = physicalPaddingTop;
  metrics.physical_padding_right = physicalPaddingRight;
  metrics.physical_padding_bottom = physicalPaddingBottom;
  metrics.physical_padding_left = physicalPaddingLeft;
  metrics.physical_view_inset_top = physicalViewInsetTop;
  metrics.physical_view_inset_right = physicalViewInsetRight;
  metrics.physical_view_inset_bottom = physicalViewInsetBottom;
  metrics.physical_view_inset_left = physicalViewInsetLeft;
  metrics.system_gesture_inset_top = systemGestureInsetTop;
  metrics.system_gesture_inset_right = systemGestureInsetRight;
  metrics.system_gesture_inset_bottom = systemGestureInsetBottom;
  metrics.system_gesture_inset_left = systemGestureInsetLeft;
  metrics.physical_touch_slop = physicalTouchSlop;
  metrics.physical_min_width = physicalMinWidth;
  metrics.physical_max_width = physicalMaxWidth;
  metrics.physical_min_height = physicalMinHeight;
  metrics.physical_max_height = physicalMaxHeight;
  metrics.physical_display_corner_radius_top_left =
      physicalDisplayCornerRadiusTopLeft;
  metrics.physical_display_corner_radius_top_right =
      physicalDisplayCornerRadiusTopRight;
  metrics.physical_display_corner_radius_bottom_right =
      physicalDisplayCornerRadiusBottomRight;
  metrics.physical_display_corner_radius_bottom_left =
      physicalDisplayCornerRadiusBottomLeft;

  if (javaDisplayFeaturesBounds != nullptr) {
    jsize rectSize = env->GetArrayLength(javaDisplayFeaturesBounds);
    if (rectSize > 0) {
      std::vector<int> bounds(rectSize);
      env->GetIntArrayRegion(javaDisplayFeaturesBounds, 0, rectSize,
                             &bounds[0]);
      metrics.display_features_bounds.assign(bounds.begin(), bounds.end());
    }
  }

  if (javaDisplayFeaturesType != nullptr) {
    jsize typeSize = env->GetArrayLength(javaDisplayFeaturesType);
    if (typeSize > 0) {
      std::vector<int> types(typeSize);
      env->GetIntArrayRegion(javaDisplayFeaturesType, 0, typeSize, &types[0]);
      metrics.display_features_type.assign(types.begin(), types.end());
    }
  }

  if (javaDisplayFeaturesState != nullptr) {
    jsize stateSize = env->GetArrayLength(javaDisplayFeaturesState);
    if (stateSize > 0) {
      std::vector<int> states(stateSize);
      env->GetIntArrayRegion(javaDisplayFeaturesState, 0, stateSize,
                             &states[0]);
      metrics.display_features_state.assign(states.begin(), states.end());
    }
  }

  native_instance->SetViewportMetrics(metrics);
  if (native_instance->GetEngine()) {
    native_instance->SendWindowMetricsEvent(native_instance->GetEngine(),
                                            metrics);
  }
}

static void FlutterJNI_DispatchPointerDataPacket(JNIEnv* env,
                                                 jobject jcaller,
                                                 jlong native_handle,
                                                 jobject buffer,
                                                 jint position) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_DispatchPointerDataPacket");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance || !buffer || position <= 0) {
    return;
  }
  const uint8_t* data =
      static_cast<const uint8_t*>(env->GetDirectBufferAddress(buffer));
  if (data != nullptr) {
    native_instance->DispatchPointerDataPacket(data,
                                               static_cast<size_t>(position));
  }
}

static void FlutterJNI_DispatchSemanticsAction(JNIEnv* env,
                                               jobject jcaller,
                                               jlong native_handle,
                                               jint id,
                                               jint action,
                                               jobject args,
                                               jint args_position) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_DispatchSemanticsAction");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  std::vector<uint8_t> action_data;
  if (args != nullptr && args_position > 0) {
    const uint8_t* buffer =
        static_cast<const uint8_t*>(env->GetDirectBufferAddress(args));
    if (buffer != nullptr) {
      action_data.assign(buffer, buffer + args_position);
    }
  }
  if (native_instance->GetEngine()) {
    native_instance->DispatchSemanticsActionToEngine(
        native_instance->GetEngine(), id,
        static_cast<FlutterSemanticsAction>(action),
        action_data.empty() ? nullptr : action_data.data(), action_data.size());
  }
}

static void FlutterJNI_SetSemanticsEnabled(JNIEnv* env,
                                           jobject jcaller,
                                           jlong native_handle,
                                           jboolean enabled) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_SetSemanticsEnabled");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  if (native_instance->GetEngine()) {
    native_instance->UpdateSemanticsEnabled(native_instance->GetEngine(),
                                            enabled);
  }
}

static void FlutterJNI_SetAccessibilityFeatures(JNIEnv* env,
                                                jobject jcaller,
                                                jlong native_handle,
                                                jint flags) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_SetAccessibilityFeatures");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  if (native_instance->GetEngine()) {
    native_instance->UpdateAccessibilityFeatures(
        native_instance->GetEngine(),
        static_cast<FlutterAccessibilityFeature>(flags));
  }
}

static jboolean FlutterJNI_GetIsSoftwareRendering(JNIEnv* env,
                                                  jobject jcaller) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_GetIsSoftwareRendering");
  return false;
}

static void FlutterJNI_RegisterTexture(JNIEnv* env,
                                       jobject jcaller,
                                       jlong native_handle,
                                       jlong texture_id,
                                       jobject surface_texture) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::FlutterJNI_RegisterTexture",
               "texture_id", std::to_string(texture_id).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->RegisterSurfaceTexture(env, texture_id, surface_texture);
  native_instance->RegisterHardwareBufferTexture(texture_id);
  if (native_instance->GetEngine()) {
    native_instance->RegisterExternalTexture(native_instance->GetEngine(),
                                             texture_id);
  }
}

static void FlutterJNI_RegisterImageTexture(JNIEnv* env,
                                            jobject jcaller,
                                            jlong native_handle,
                                            jlong texture_id,
                                            jobject image_texture_entry,
                                            jboolean reset_on_background) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::FlutterJNI_RegisterImageTexture",
               "texture_id", std::to_string(texture_id).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->RegisterHardwareBufferTexture(texture_id);
  if (native_instance->GetEngine()) {
    native_instance->RegisterExternalTexture(native_instance->GetEngine(),
                                             texture_id);
  }
}

static void FlutterJNI_MarkTextureFrameAvailable(JNIEnv* env,
                                                 jobject jcaller,
                                                 jlong native_handle,
                                                 jlong texture_id) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::FlutterJNI_MarkTextureFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->OnHardwareBufferFrameAvailable(texture_id);
  if (native_instance->GetEngine()) {
    native_instance->MarkExternalTextureFrameAvailable(
        native_instance->GetEngine(), texture_id);
    native_instance->ScheduleFrame(native_instance->GetEngine());
  }
}

static void FlutterJNI_ScheduleFrame(JNIEnv* env,
                                     jobject jcaller,
                                     jlong native_handle) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_ScheduleFrame");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  if (native_instance->GetEngine()) {
    native_instance->MarkAllTexturesFrameAvailable();
    native_instance->ScheduleFrame(native_instance->GetEngine());
  }
}

static void FlutterJNI_UnregisterTexture(JNIEnv* env,
                                         jobject jcaller,
                                         jlong native_handle,
                                         jlong texture_id) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::FlutterJNI_UnregisterTexture",
               "texture_id", std::to_string(texture_id).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->UnregisterSurfaceTexture(env, texture_id);
  native_instance->UnregisterHardwareBufferTexture(texture_id);
  if (native_instance->GetEngine()) {
    native_instance->UnregisterExternalTexture(native_instance->GetEngine(),
                                               texture_id);
  }
}

static jobject FlutterJNI_LookupCallbackInformation(JNIEnv* env,
                                                    jobject jcaller,
                                                    jlong handle) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_LookupCallbackInformation");
  DefaultCallbackCacheProvider provider;
  auto info = provider.GetCallbackInformation(handle);
  if (!info.has_value() || !g_flutter_callback_info_class ||
      g_flutter_callback_info_class->is_null() ||
      !g_flutter_callback_info_constructor) {
    return nullptr;
  }
  return env->NewObject(g_flutter_callback_info_class->obj(),
                        g_flutter_callback_info_constructor,
                        env->NewStringUTF(info->name.c_str()),
                        env->NewStringUTF(info->class_name.c_str()),
                        env->NewStringUTF(info->library_path.c_str()));
}

static jboolean FlutterJNI_FlutterTextUtilsIsEmoji(JNIEnv* env,
                                                   jobject obj,
                                                   jint codePoint) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsEmoji");
  return (codePoint >= 0x1F600 && codePoint <= 0x1F64F) ||
         (codePoint >= 0x1F300 && codePoint <= 0x1F5FF) ||
         (codePoint >= 0x1F680 && codePoint <= 0x1F6FF) ||
         (codePoint >= 0x1F700 && codePoint <= 0x1F77F) ||
         (codePoint >= 0x1F780 && codePoint <= 0x1F7FF) ||
         (codePoint >= 0x1F800 && codePoint <= 0x1F8FF) ||
         (codePoint >= 0x1F900 && codePoint <= 0x1F9FF) ||
         (codePoint >= 0x1FA00 && codePoint <= 0x1FA6F) ||
         (codePoint >= 0x1FA70 && codePoint <= 0x1FAFF) ||
         (codePoint >= 0x2600 && codePoint <= 0x26FF) ||
         (codePoint >= 0x2700 && codePoint <= 0x27BF) ||
         (codePoint >= 0xFE00 && codePoint <= 0xFE0F) ||
         (codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF);
}

static jboolean FlutterJNI_FlutterTextUtilsIsEmojiModifier(JNIEnv* env,
                                                           jobject obj,
                                                           jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsEmojiModifier");
  return codePoint >= 0x1F3FB && codePoint <= 0x1F3FF;
}

static jboolean FlutterJNI_FlutterTextUtilsIsEmojiModifierBase(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsEmojiModifierBase");
  return (codePoint >= 0x1F3C2 && codePoint <= 0x1F3C4) ||
         (codePoint >= 0x1F3C7 && codePoint <= 0x1F3CC) ||
         (codePoint >= 0x1F442 && codePoint <= 0x1F443) ||
         (codePoint >= 0x1F446 && codePoint <= 0x1F450) ||
         (codePoint >= 0x1F466 && codePoint <= 0x1F478) ||
         (codePoint >= 0x1F47C && codePoint <= 0x1F487) ||
         (codePoint == 0x1F4AA) ||
         (codePoint >= 0x1F574 && codePoint <= 0x1F57A) ||
         (codePoint >= 0x1F590 && codePoint <= 0x1F596) ||
         (codePoint >= 0x1F645 && codePoint <= 0x1F647) ||
         (codePoint >= 0x1F64B && codePoint <= 0x1F64F) ||
         (codePoint >= 0x1F6A3 && codePoint <= 0x1F6B6) ||
         (codePoint >= 0x1F6C0 && codePoint <= 0x1F6CC) ||
         (codePoint >= 0x1F90F && codePoint <= 0x1F93E) ||
         (codePoint == 0x1F977) ||
         (codePoint >= 0x1F9B5 && codePoint <= 0x1F9B9) ||
         (codePoint >= 0x1F9CD && codePoint <= 0x1F9CF) ||
         (codePoint >= 0x1F9D1 && codePoint <= 0x1F9DD) ||
         (codePoint == 0x261D) || (codePoint == 0x26F9) ||
         (codePoint >= 0x270A && codePoint <= 0x270D);
}

static jboolean FlutterJNI_FlutterTextUtilsIsVariationSelector(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsVariationSelector");
  return (codePoint >= 0xFE00 && codePoint <= 0xFE0F) ||
         (codePoint >= 0xE0100 && codePoint <= 0xE01EF);
}

static jboolean FlutterJNI_FlutterTextUtilsIsRegionalIndicator(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsRegionalIndicator");
  return codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF;
}

static void FlutterJNI_LoadDartDeferredLibrary(JNIEnv* env,
                                               jobject obj,
                                               jlong native_handle,
                                               jint jLoadingUnitId,
                                               jobjectArray jSearchPaths) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::FlutterJNI_LoadDartDeferredLibrary",
               "loading_unit_id", std::to_string(jLoadingUnitId).c_str());
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  native_instance->GetRouter()->RouteRequestDartDeferredLibrary(
      static_cast<int64_t>(jLoadingUnitId));
}

static void FlutterJNI_UpdateJavaAssetManager(JNIEnv* env,
                                              jobject obj,
                                              jlong native_handle,
                                              jobject jAssetManager,
                                              jstring jAssetBundlePath) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_UpdateJavaAssetManager");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  std::string bundle_path =
      jAssetBundlePath ? fml::jni::JavaStringToString(env, jAssetBundlePath)
                       : "";
  native_instance->UpdateAssetManager(env, jAssetManager, bundle_path);
}

static void FlutterJNI_DeferredComponentInstallFailure(JNIEnv* env,
                                                       jobject obj,
                                                       jint jLoadingUnitId,
                                                       jstring jError,
                                                       jboolean jTransient) {
  TRACE_EVENT1("flutter",
               "FlutterEmbedderNative::"
               "FlutterJNI_DeferredComponentInstallFailure",
               "loading_unit_id", std::to_string(jLoadingUnitId).c_str());
}

static void FlutterJNI_UpdateDisplayMetrics(JNIEnv* env,
                                            jobject jcaller,
                                            jlong native_handle) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_UpdateDisplayMetrics");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  AndroidDisplayMetrics metrics;
  native_instance->GetRouter()->RouteUpdateDisplayMetrics(metrics);
}

static jboolean FlutterJNI_IsSurfaceControlEnabled(JNIEnv* env,
                                                   jobject jcaller,
                                                   jlong native_handle) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_IsSurfaceControlEnabled");
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return false;
  }
  return native_instance->IsHcppEnabled();
}

static void FlutterJNI_PrefetchDefaultFontManager(JNIEnv* env, jclass clazz) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_PrefetchDefaultFontManager");
  DefaultFontCollectionProvider font_provider(
      FlutterEmbedderNative::GetDefaultLibraryLoader());
  font_provider.PrefetchDefaultFontManager();
}

static void FlutterJNI_UpdateRefreshRate(JNIEnv* env,
                                         jobject jcaller,
                                         jfloat refreshRateFPS) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_UpdateRefreshRate");
  if (refreshRateFPS > 0) {
    FlutterEmbedderNative::GetDefaultVsyncWaiter()->UpdateRefreshRate(
        static_cast<double>(refreshRateFPS));
  }
}

static void FlutterJNI_OnVsync(JNIEnv* env,
                               jobject jcaller,
                               jlong frameDelayNanos,
                               jlong refreshPeriodNanos,
                               jlong cookie) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_OnVsync");
  FlutterEmbedderNative::GetDefaultVsyncWaiter()->ConsumePendingVsync(
      static_cast<intptr_t>(cookie), static_cast<int64_t>(frameDelayNanos));
}

bool FlutterEmbedderNative::RegisterJni(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RegisterJni");
  if (!env) {
    FML_LOG(ERROR)
        << "No JNIEnv provided to FlutterEmbedderNative::RegisterJni";
    return false;
  }

  static const JNINativeMethod flutter_jni_methods[] = {
      {
          .name = "nativeUpdateRefreshRate",
          .signature = "(F)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_UpdateRefreshRate),
      },
      {
          .name = "nativeOnVsync",
          .signature = "(JJJ)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_OnVsync),
      },
      {
          .name = "nativeAttach",
          .signature = "(Lio/flutter/embedding/engine/FlutterJNI;)J",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_Attach),
      },
      {
          .name = "nativeDestroy",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_Destroy),
      },
      {
          .name = "nativeSpawn",
          .signature = "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/"
                       "String;Ljava/util/List;J)Lio/flutter/"
                       "embedding/engine/FlutterJNI;",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_Spawn),
      },
      {
          .name = "nativeRunBundleAndSnapshotFromLibrary",
          .signature = "(JLjava/lang/String;Ljava/lang/String;"
                       "Ljava/lang/String;Landroid/content/res/"
                       "AssetManager;Ljava/util/List;J)V",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_RunBundleAndSnapshotFromLibrary),
      },
      {
          .name = "nativeDispatchEmptyPlatformMessage",
          .signature = "(JLjava/lang/String;I)V",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_DispatchEmptyPlatformMessage),
      },
      {
          .name = "nativeCleanupMessageData",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_CleanupMessageData),
      },
      {
          .name = "nativeDispatchPlatformMessage",
          .signature = "(JLjava/lang/String;Ljava/nio/ByteBuffer;II)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_DispatchPlatformMessage),
      },
      {
          .name = "nativeInvokePlatformMessageResponseCallback",
          .signature = "(JILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_InvokePlatformMessageResponseCallback),
      },
      {
          .name = "nativeInvokePlatformMessageEmptyResponseCallback",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_InvokePlatformMessageEmptyResponseCallback),
      },
      {
          .name = "nativeNotifyLowMemoryWarning",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_NotifyLowMemoryWarning),
      },
      {
          .name = "nativeGetBitmap",
          .signature = "(J)Landroid/graphics/Bitmap;",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_GetBitmap),
      },
      {
          .name = "nativeSurfaceCreated",
          .signature = "(JLandroid/view/Surface;)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SurfaceCreated),
      },
      {
          .name = "nativeSurfaceWindowChanged",
          .signature = "(JLandroid/view/Surface;)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SurfaceWindowChanged),
      },
      {
          .name = "nativeSurfaceChanged",
          .signature = "(JII)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SurfaceChanged),
      },
      {
          .name = "nativeSurfaceDestroyed",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SurfaceDestroyed),
      },
      {
          .name = "nativeSetViewportMetrics",
          .signature = "(JFIIIIIIIIIIIIIII[I[I[IIIIIIIII)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SetViewportMetrics),
      },
      {
          .name = "nativeDispatchPointerDataPacket",
          .signature = "(JLjava/nio/ByteBuffer;I)V",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_DispatchPointerDataPacket),
      },
      {
          .name = "nativeDispatchSemanticsAction",
          .signature = "(JIILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_DispatchSemanticsAction),
      },
      {
          .name = "nativeSetSemanticsEnabled",
          .signature = "(JZ)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_SetSemanticsEnabled),
      },
      {
          .name = "nativeSetAccessibilityFeatures",
          .signature = "(JI)V",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_SetAccessibilityFeatures),
      },
      {
          .name = "nativeGetIsSoftwareRenderingEnabled",
          .signature = "()Z",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_GetIsSoftwareRendering),
      },
      {
          .name = "nativeRegisterTexture",
          .signature = "(JJLjava/lang/ref/WeakReference;)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_RegisterTexture),
      },
      {
          .name = "nativeRegisterImageTexture",
          .signature = "(JJLjava/lang/ref/WeakReference;Z)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_RegisterImageTexture),
      },
      {
          .name = "nativeMarkTextureFrameAvailable",
          .signature = "(JJ)V",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_MarkTextureFrameAvailable),
      },
      {
          .name = "nativeScheduleFrame",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_ScheduleFrame),
      },
      {
          .name = "nativeUnregisterTexture",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_UnregisterTexture),
      },
      {
          .name = "nativeLookupCallbackInformation",
          .signature = "(J)Lio/flutter/view/FlutterCallbackInformation;",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_LookupCallbackInformation),
      },
      {
          .name = "nativeFlutterTextUtilsIsEmoji",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_FlutterTextUtilsIsEmoji),
      },
      {
          .name = "nativeFlutterTextUtilsIsEmojiModifier",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_FlutterTextUtilsIsEmojiModifier),
      },
      {
          .name = "nativeFlutterTextUtilsIsEmojiModifierBase",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_FlutterTextUtilsIsEmojiModifierBase),
      },
      {
          .name = "nativeFlutterTextUtilsIsVariationSelector",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_FlutterTextUtilsIsVariationSelector),
      },
      {
          .name = "nativeFlutterTextUtilsIsRegionalIndicator",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_FlutterTextUtilsIsRegionalIndicator),
      },
      {
          .name = "nativeLoadDartDeferredLibrary",
          .signature = "(JI[Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_LoadDartDeferredLibrary),
      },
      {
          .name = "nativeUpdateJavaAssetManager",
          .signature =
              "(JLandroid/content/res/AssetManager;Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_UpdateJavaAssetManager),
      },
      {
          .name = "nativeDeferredComponentInstallFailure",
          .signature = "(ILjava/lang/String;Z)V",
          .fnPtr = reinterpret_cast<void*>(
              &FlutterJNI_DeferredComponentInstallFailure),
      },
      {
          .name = "nativeUpdateDisplayMetrics",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_UpdateDisplayMetrics),
      },
      {
          .name = "nativeIsSurfaceControlEnabled",
          .signature = "(J)Z",
          .fnPtr = reinterpret_cast<void*>(&FlutterJNI_IsSurfaceControlEnabled),
      },
      {
          .name = "nativePrefetchDefaultFontManager",
          .signature = "()V",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterJNI_PrefetchDefaultFontManager),
      },
  };

  jclass clazz = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
  if (!clazz) {
    FML_LOG(ERROR) << "Failed to find FlutterJNI Class in "
                      "FlutterEmbedderNative::RegisterJni.";
    return false;
  }

  if (env->RegisterNatives(clazz, flutter_jni_methods,
                           std::size(flutter_jni_methods)) != 0) {
    FML_LOG(ERROR) << "Failed to RegisterNatives with FlutterJNI in "
                      "FlutterEmbedderNative::RegisterJni.";
    return false;
  }

  g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, clazz);
  g_jni_shell_holder_field =
      env->GetFieldID(clazz, "nativeShellHolderId", "Ljava/lang/Long;");
  g_jni_constructor = env->GetMethodID(clazz, "<init>", "()V");

  jclass java_long_class = env->FindClass("java/lang/Long");
  if (java_long_class) {
    g_java_long_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, java_long_class);
    g_long_constructor = env->GetStaticMethodID(java_long_class, "valueOf",
                                                "(J)Ljava/lang/Long;");
  }

  jclass callback_info_class =
      env->FindClass("io/flutter/view/FlutterCallbackInformation");
  if (callback_info_class) {
    g_flutter_callback_info_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, callback_info_class);
    g_flutter_callback_info_constructor = env->GetMethodID(
        callback_info_class, "<init>",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
  }

  jclass weak_reference_class = env->FindClass("java/lang/ref/WeakReference");
  if (weak_reference_class) {
    g_weak_reference_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, weak_reference_class);
    g_weak_reference_get =
        env->GetMethodID(weak_reference_class, "get", "()Ljava/lang/Object;");
  }

  jclass wrapper_class = env->FindClass(
      "io/flutter/embedding/engine/renderer/SurfaceTextureWrapper");
  if (wrapper_class) {
    g_surface_texture_wrapper_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, wrapper_class);
    g_surface_texture_wrapper_attach_to_gl_context =
        env->GetMethodID(wrapper_class, "attachToGLContext", "(I)V");
    g_surface_texture_wrapper_update_tex_image =
        env->GetMethodID(wrapper_class, "updateTexImage", "()V");
    g_surface_texture_wrapper_detach_from_gl_context =
        env->GetMethodID(wrapper_class, "detachFromGLContext", "()V");
    g_surface_texture_wrapper_release =
        env->GetMethodID(wrapper_class, "release", "()V");
  }

  return true;
}

}  // namespace android
}  // namespace flutter
