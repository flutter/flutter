// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

std::mutex FlutterEmbedderNative::default_library_loader_mutex_;
std::shared_ptr<OSLibraryLoader>
    FlutterEmbedderNative::default_library_loader_ = nullptr;

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
  return jvm_invoker_->DecodeImage(data, size, generator_handle);
}

void DefaultImageDecoderProvider::OnImageHeader(int64_t generator_handle,
                                                int32_t width,
                                                int32_t height) {
  TRACE_EVENT0("flutter", "DefaultImageDecoderProvider::OnImageHeader");
  std::scoped_lock lock(mutex_);
  if (headers_.size() >= kMaxHeaderCount) {
    headers_.erase(headers_.begin());
  }
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

void DefaultImageDecoderProvider::RemoveImageHeader(int64_t generator_handle) {
  TRACE_EVENT0("flutter", "DefaultImageDecoderProvider::RemoveImageHeader");
  std::scoped_lock lock(mutex_);
  headers_.erase(generator_handle);
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

void InMemoryImageDecoderProvider::RemoveImageHeader(int64_t generator_handle) {
  TRACE_EVENT0("flutter", "InMemoryImageDecoderProvider::RemoveImageHeader");
  std::scoped_lock lock(mutex_);
  headers_.erase(generator_handle);
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
    entries_[0].image_handle = image_handle;
    return;
  }
  size_t i = 1;
  for (; i < capacity_; ++i) {
    if (entries_[i].key == key) {
      break;
    }
  }
  if (i >= capacity_) {
    return;
  }
  for (auto j = i; j > 0; --j) {
    entries_[j] = entries_[j - 1];
  }
  entries_[0] = Entry{.key = key, .image_handle = image_handle};
}

uint64_t EmbedderImageLRU::AddImage(uint64_t image_handle, uint64_t key) {
  TRACE_EVENT0("flutter", "EmbedderImageLRU::AddImage");
  if (key == 0) {
    return 0;
  }
  std::scoped_lock lock(mutex_);
  for (size_t i = 0; i < capacity_; ++i) {
    if (entries_[i].key == key) {
      entries_[i].image_handle = image_handle;
      UpdateKey(image_handle, key);
      return 0;
    }
  }
  uint64_t lru_key = entries_[capacity_ - 1].key;
  entries_[capacity_ - 1] = Entry{.key = key, .image_handle = image_handle};
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
      image_lru_(std::make_shared<EmbedderImageLRU>()),
      platform_views_provider_(
          std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(
          jvm_invoker_,
          std::make_shared<DefaultCallbackCacheProvider>(),
          std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_),
          platform_views_provider_,
          platform_views_controller_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)),
      library_loader_(GetDefaultLibraryLoader()),
      asset_provider_(std::make_shared<APKAssetProvider>(
          std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  jni_router_->SetInstanceEmbedderEnabled(true);
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
      image_lru_(image_lru ? std::move(image_lru)
                           : std::make_shared<EmbedderImageLRU>()),
      platform_views_provider_(
          platform_views_provider
              ? std::move(platform_views_provider)
              : std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_)),
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(
          jvm_invoker_,
          std::move(callback_cache),
          image_decoder
              ? std::move(image_decoder)
              : std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_),
          platform_views_provider_,
          platform_views_controller_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, legacy_delegate)),
      library_loader_(library_loader ? std::move(library_loader)
                                     : GetDefaultLibraryLoader()),
      asset_provider_(
          asset_provider
              ? std::move(asset_provider)
              : std::make_shared<APKAssetProvider>(
                    std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  jni_router_->SetInstanceEmbedderEnabled(true);
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterEmbedderNative(custom)");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with custom components.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  UnregisterImageDecoder();
  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);
  std::lock_guard<std::mutex> surf_lock(surface_mutex_);
#if defined(__ANDROID__)
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
#endif
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

void FlutterEmbedderNative::SetNativeWindow(ANativeWindow* window) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetNativeWindow");
  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);
  std::lock_guard<std::mutex> surf_lock(surface_mutex_);
  if (native_window_ == window) {
    return;
  }
#if defined(__ANDROID__)
  if (window) {
    ANativeWindow_acquire(window);
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
  }
#endif
  native_window_ = window;
}

ANativeWindow* FlutterEmbedderNative::GetNativeWindow() {
  std::lock_guard<std::mutex> lock(surface_mutex_);
  return native_window_;
}

ANativeWindow* FlutterEmbedderNative::AcquireNativeWindow() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::AcquireNativeWindow");
  std::lock_guard<std::mutex> lock(surface_mutex_);
#if defined(__ANDROID__)
  if (native_window_) {
    ANativeWindow_acquire(native_window_);
  }
#endif
  return native_window_;
}

bool FlutterEmbedderNative::BlitSoftwareRaster(
    const void* allocation,
    size_t row_bytes,
    size_t height,
    const SoftwareBuffer& dst_buffer) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::BlitSoftwareRaster");
  if (!allocation || row_bytes < 4 || (row_bytes % 4 != 0) || height == 0) {
    return false;
  }
  if (!dst_buffer.bits || dst_buffer.width <= 0 || dst_buffer.height <= 0 ||
      dst_buffer.stride <= 0 || dst_buffer.stride < dst_buffer.width) {
    return false;
  }

  const size_t src_width = row_bytes / 4;
  const size_t copy_width_px =
      std::min(src_width, static_cast<size_t>(dst_buffer.width));
  const size_t copy_height =
      std::min(height, static_cast<size_t>(dst_buffer.height));

  const uint8_t* src_row = reinterpret_cast<const uint8_t*>(allocation);
  uint8_t* dst_row = reinterpret_cast<uint8_t*>(dst_buffer.bits);

  if (dst_buffer.format == kFormatRgba8888) {
    const size_t copy_bytes_per_row = copy_width_px * 4;
    const size_t dst_stride_bytes = dst_buffer.stride * 4;

    for (size_t y = 0; y < copy_height; ++y) {
      std::memcpy(dst_row, src_row, copy_bytes_per_row);

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  } else if (dst_buffer.format == kFormatRgbx8888) {
    const size_t copy_bytes_per_row = copy_width_px * 4;
    const size_t dst_stride_bytes = dst_buffer.stride * 4;

    for (size_t y = 0; y < copy_height; ++y) {
      const uint32_t* src_px = reinterpret_cast<const uint32_t*>(src_row);
      uint32_t* dst_px = reinterpret_cast<uint32_t*>(dst_row);

      for (size_t x = 0; x < copy_width_px; ++x) {
        // Little endian: byte 0=R, 1=G, 2=B, 3=X. Force opaque alpha channel on
        // RGBX.
        dst_px[x] = src_px[x] | 0xFF000000;
      }

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  } else if (dst_buffer.format == kFormatRgb565) {
    const size_t copy_bytes_per_row = copy_width_px * 2;
    const size_t dst_stride_bytes = dst_buffer.stride * 2;

    for (size_t y = 0; y < copy_height; ++y) {
      const uint32_t* src_px = reinterpret_cast<const uint32_t*>(src_row);
      uint16_t* dst_px = reinterpret_cast<uint16_t*>(dst_row);

      for (size_t x = 0; x < copy_width_px; ++x) {
        uint32_t pixel = src_px[x];
        // Premultiplied RGBA (Little Endian: R=byte0, G=byte1, B=byte2,
        // A=byte3)
        uint8_t r = pixel & 0xFF;
        uint8_t g = (pixel >> 8) & 0xFF;
        uint8_t b = (pixel >> 16) & 0xFF;
        uint8_t a = (pixel >> 24) & 0xFF;

        if (a > 0 && a < 255) {
          r = static_cast<uint8_t>(std::min<uint32_t>(255, (r * 255) / a));
          g = static_cast<uint8_t>(std::min<uint32_t>(255, (g * 255) / a));
          b = static_cast<uint8_t>(std::min<uint32_t>(255, (b * 255) / a));
        }

        dst_px[x] = static_cast<uint16_t>(((r >> 3) << 11) | ((g >> 2) << 5) |
                                          (b >> 3));
      }

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  }

  FML_LOG(ERROR) << "Unsupported buffer format for software presentation: "
                 << dst_buffer.format;
  return false;
}

bool FlutterEmbedderNative::PresentSoftware(const void* allocation,
                                            size_t row_bytes,
                                            size_t height) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::PresentSoftware");
  if (!allocation || row_bytes == 0 || height == 0) {
    return false;
  }

  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);

#if defined(__ANDROID__)
  ANativeWindow* window = nullptr;
  {
    std::lock_guard<std::mutex> lock(surface_mutex_);
    if (!native_window_) {
      return false;
    }
    window = native_window_;
    ANativeWindow_acquire(window);
  }

  // RAII guard to guarantee ANativeWindow_release on all exit paths.
  struct WindowReleaser {
    ANativeWindow* win;
    ~WindowReleaser() {
      if (win) {
        ANativeWindow_release(win);
      }
    }
  } releaser{window};

  ANativeWindow_Buffer native_buffer;
  if (ANativeWindow_lock(window, &native_buffer, nullptr) != 0) {
    FML_LOG(ERROR)
        << "Failed to lock ANativeWindow buffer for software presentation.";
    return false;
  }

  // RAII guard to guarantee ANativeWindow_unlockAndPost on all exit paths.
  struct BufferUnlocker {
    ANativeWindow* win;
    ~BufferUnlocker() {
      if (win) {
        ANativeWindow_unlockAndPost(win);
      }
    }
  } unlocker{window};

  SoftwareBuffer buffer;
  buffer.bits = native_buffer.bits;
  buffer.width = native_buffer.width;
  buffer.height = native_buffer.height;
  buffer.stride = native_buffer.stride;
  buffer.format = native_buffer.format;

  return BlitSoftwareRaster(allocation, row_bytes, height, buffer);
#else
  // Non-Android host stub for testing
  std::lock_guard<std::mutex> lock(surface_mutex_);
  return native_window_ != nullptr;
#endif
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
  std::shared_ptr<OSLibraryLoader> old_loader;
  {
    std::lock_guard<std::mutex> lock(default_library_loader_mutex_);
    old_loader = std::move(default_library_loader_);
    default_library_loader_ = std::move(loader);
  }
}

std::shared_ptr<OSLibraryLoader>
FlutterEmbedderNative::GetDefaultLibraryLoader() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetDefaultLibraryLoader");
  std::lock_guard<std::mutex> lock(default_library_loader_mutex_);
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
  std::lock_guard<std::mutex> lock(asset_provider_mutex_);
  return asset_provider_;
}

void FlutterEmbedderNative::SetAssetProvider(
    std::shared_ptr<APKAssetProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetAssetProvider");
  std::lock_guard<std::mutex> lock(asset_provider_mutex_);
  asset_provider_ = std::move(provider);
}

void FlutterEmbedderNative::UpdateJavaAssetManager(
    JNIEnv* env,
    jobject jasset_manager,
    const std::string& asset_bundle_path) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateJavaAssetManager");
  if (jasset_manager != nullptr) {
    auto asset_provider = std::make_shared<APKAssetProvider>(
        env, jasset_manager, asset_bundle_path);
    SetAssetProvider(std::move(asset_provider));
  }
}

std::unique_ptr<fml::Mapping> FlutterEmbedderNative::ResolveAsset(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ResolveAsset", "name",
               asset_name.c_str());
  std::shared_ptr<APKAssetProvider> provider;
  {
    std::lock_guard<std::mutex> lock(asset_provider_mutex_);
    provider = asset_provider_;
  }
  if (!provider) {
    return nullptr;
  }
  return provider->GetAsMapping(asset_name);
}

std::vector<std::unique_ptr<fml::Mapping>>
FlutterEmbedderNative::ResolveAssetMappings(
    const std::string& asset_pattern,
    const std::optional<std::string>& subdir) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ResolveAssetMappings",
               "pattern", asset_pattern.c_str());
  std::shared_ptr<APKAssetProvider> provider;
  {
    std::lock_guard<std::mutex> lock(asset_provider_mutex_);
    provider = asset_provider_;
  }
  if (!provider) {
    return {};
  }
  return provider->GetAsMappings(asset_pattern, subdir);
}

FlutterCustomAssetResolver FlutterEmbedderNative::CreateCustomAssetResolver()
    const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateCustomAssetResolver");
  std::shared_ptr<APKAssetProvider> provider;
  {
    std::lock_guard<std::mutex> lock(asset_provider_mutex_);
    provider = asset_provider_;
  }
  if (!provider) {
    FlutterCustomAssetResolver resolver = {};
    resolver.struct_size = sizeof(FlutterCustomAssetResolver);
    return resolver;
  }
  return provider->CreateCustomAssetResolver();
}

std::unique_ptr<AssetResolver> FlutterEmbedderNative::CreateAssetResolver()
    const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateAssetResolver");
  std::shared_ptr<APKAssetProvider> provider;
  {
    std::lock_guard<std::mutex> lock(asset_provider_mutex_);
    provider = asset_provider_;
  }
  if (!provider) {
    return nullptr;
  }
  return provider->Clone();
}

std::shared_ptr<CallbackCacheProvider> FlutterEmbedderNative::GetCallbackCache()
    const {
  return jni_delegate_ ? jni_delegate_->GetCallbackCache() : nullptr;
}

void FlutterEmbedderNative::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetCallbackCache");
  if (jni_delegate_) {
    jni_delegate_->SetCallbackCache(std::move(provider));
  }
}

std::optional<DartCallbackInfo>
FlutterEmbedderNative::LookupCallbackInformation(int64_t handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::LookupCallbackInformation");
  if (jni_router_) {
    return jni_router_->RouteLookupCallbackInformation(handle);
  }
  return std::nullopt;
}

std::shared_ptr<ImageDecoderProvider>
FlutterEmbedderNative::GetImageDecoderProvider() const {
  return jni_delegate_ ? jni_delegate_->GetImageDecoderProvider() : nullptr;
}

void FlutterEmbedderNative::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetImageDecoderProvider");
  if (jni_delegate_) {
    jni_delegate_->SetImageDecoderProvider(std::move(provider));
  }
}

bool FlutterEmbedderNative::DecodeImage(const uint8_t* data,
                                        size_t size,
                                        int64_t generator_handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DecodeImage");
  if (jni_router_) {
    return jni_router_->RouteDecodeImage(data, size, generator_handle);
  }
  return false;
}

void FlutterEmbedderNative::OnNativeImageHeader(int64_t generator_handle,
                                                int32_t width,
                                                int32_t height) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnNativeImageHeader");
  if (jni_router_) {
    jni_router_->RouteNativeImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> FlutterEmbedderNative::GetImageHeader(
    int64_t generator_handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetImageHeader");
  if (jni_router_) {
    return jni_router_->RouteGetImageHeader(generator_handle);
  }
  return std::nullopt;
}

void FlutterEmbedderNative::RemoveImageHeader(int64_t generator_handle) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RemoveImageHeader");
  if (jni_router_) {
    jni_router_->RouteRemoveImageHeader(generator_handle);
  }
}

static FlutterEngineResult RegisterImageDecoderWithEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterImageDecoderCallback callback,
    void* user_data,
    int32_t priority,
    FlutterImageDecoderRegistration* registration_out) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.RegisterImageDecoder) {
    return s_procs.RegisterImageDecoder(engine, callback, user_data, priority,
                                        registration_out);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult UnregisterImageDecoderWithEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterImageDecoderRegistration registration) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.UnregisterImageDecoder) {
    return s_procs.UnregisterImageDecoder(engine, registration);
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
  std::lock_guard<std::mutex> lock(decoder_registration_mutex_);
  if (registered_engine_ && decoder_registration_ != 0) {
    UnregisterImageDecoderWithEngine(registered_engine_, decoder_registration_);
    registered_engine_ = nullptr;
    decoder_registration_ = 0;
  }

  auto callback = [](const uint8_t* data, size_t size,
                     FlutterDecodedImage* decoded_image_out,
                     void* user_data) -> bool {
    auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
    if (!native || !decoded_image_out) {
      return false;
    }
    static std::atomic<int64_t> s_generator_handle(1);
    int64_t handle = s_generator_handle.fetch_add(1);
    if (!native->DecodeImage(data, size, handle)) {
      native->RemoveImageHeader(handle);
      return false;
    }
    auto header = native->GetImageHeader(handle);
    native->RemoveImageHeader(handle);
    if (!header.has_value() || header->width <= 0 || header->height <= 0) {
      return false;
    }
    decoded_image_out->width = static_cast<uint32_t>(header->width);
    decoded_image_out->height = static_cast<uint32_t>(header->height);
    decoded_image_out->row_bytes = decoded_image_out->width * 4;
    auto* pixels =
        new uint8_t[decoded_image_out->row_bytes * decoded_image_out->height]();
    decoded_image_out->raw_pixels = pixels;
    decoded_image_out->user_data = pixels;
    decoded_image_out->destruction_callback = [](void* user_data) {
      delete[] reinterpret_cast<uint8_t*>(user_data);
    };
    return true;
  };

  FlutterImageDecoderRegistration reg_id = 0;
  FlutterEngineResult result =
      RegisterImageDecoderWithEngine(engine, callback, this, priority, &reg_id);
  if (result == kSuccess) {
    registered_engine_ = engine;
    decoder_registration_ = reg_id;
  }
  return result;
}

FlutterEngineResult FlutterEmbedderNative::UnregisterImageDecoder() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UnregisterImageDecoder");
  std::lock_guard<std::mutex> lock(decoder_registration_mutex_);
  if (!registered_engine_ || decoder_registration_ == 0) {
    return kSuccess;
  }
  FlutterEngineResult result = UnregisterImageDecoderWithEngine(
      registered_engine_, decoder_registration_);
  registered_engine_ = nullptr;
  decoder_registration_ = 0;
  return result;
}

std::shared_ptr<EmbedderImageLRU> FlutterEmbedderNative::GetImageLRU() const {
  std::lock_guard<std::mutex> lock(image_lru_mutex_);
  return image_lru_;
}

void FlutterEmbedderNative::SetImageLRU(std::shared_ptr<EmbedderImageLRU> lru) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetImageLRU");
  std::lock_guard<std::mutex> lock(image_lru_mutex_);
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
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
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
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  mutators_stack);
}

bool FlutterEmbedderNative::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::PushPlatformViewMutators");
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RoutePlatformViewMutators(
      view_id, x, y, width, height, view_width, view_height, mutators_stack);
}

bool FlutterEmbedderNative::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) const {
  return PushPlatformViewMutators(platform_view, x, y, width, height, width,
                                  height);
}

bool FlutterEmbedderNative::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::PushPlatformViewMutators(view)");
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RoutePlatformViewMutators(
      platform_view, x, y, width, height, view_width, view_height);
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
  if (!info || info->struct_size < sizeof(FlutterSendSemanticsActionInfo)) {
    return kInvalidArguments;
  }
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.SendSemanticsAction) {
    return s_procs.SendSemanticsAction(engine, info);
  }
  if (s_procs.DispatchSemanticsAction) {
    return s_procs.DispatchSemanticsAction(engine, info->node_id, info->action,
                                           info->data, info->data_length);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::SendSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterSendSemanticsActionInfo* info) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SendSemanticsAction");
  if (!engine || !info ||
      info->struct_size < sizeof(FlutterSendSemanticsActionInfo)) {
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
