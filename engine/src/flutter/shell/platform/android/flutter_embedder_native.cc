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
      platform_views_controller_(
          std::make_shared<AndroidPlatformViewsController>(
              platform_views_provider_)),
      jni_delegate_(std::make_shared<JniDelegate>(
          jvm_invoker_,
          std::make_shared<DefaultCallbackCacheProvider>(),
          std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_),
          platform_views_provider_,
          platform_views_controller_,
          window_metrics_provider_,
          vsync_waiter_,
          vm_init_,
          hardware_buffer_provider_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)),
      asset_provider_(std::make_shared<APKAssetProvider>(
          std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  jni_router_->SetInstanceEmbedderEnabled(true);
  AttachWindowMetricsCallbacks();
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
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider)
    : jvm_invoker_(std::move(jvm_invoker)),
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
          platform_views_controller_,
          window_metrics_provider_,
          vsync_waiter_,
          vm_init_,
          hardware_buffer_provider_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, legacy_delegate)),
      asset_provider_(
          asset_provider
              ? std::move(asset_provider)
              : std::make_shared<APKAssetProvider>(
                    std::make_shared<InMemoryAPKAssetProviderImpl>())) {
  jni_router_->SetInstanceEmbedderEnabled(true);
  AttachWindowMetricsCallbacks();
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
    std::shared_ptr<PlatformViewsProvider> platform_views_provider,
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(
      std::move(invoker), nullptr, nullptr, std::move(platform_views_provider),
      nullptr, std::move(window_metrics_provider), std::move(vsync_waiter),
      std::move(vm_init), std::move(hardware_buffer_provider));
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
  std::scoped_lock lock(decoder_registration_mutex_, engine_mutex_);
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
  std::scoped_lock lock(decoder_registration_mutex_, engine_mutex_);
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

static FlutterEngineResult EngineSendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterWindowMetricsEvent* event) {
  if (!engine || !event ||
      event->struct_size < sizeof(FlutterWindowMetricsEvent)) {
    return kInvalidArguments;
  }
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
  if (!engine || !displays || display_count == 0) {
    return kInvalidArguments;
  }
  for (size_t i = 0; i < display_count; ++i) {
    if (displays[i].struct_size < sizeof(FlutterEngineDisplay)) {
      return kInvalidArguments;
    }
  }
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

void FlutterEmbedderNative::SetEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                          engine) {
  {
    std::scoped_lock lock(engine_mutex_);
    registered_engine_ = engine;
  }
  AttachWindowMetricsCallbacks();
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    if (vsync_waiter_) {
      vsync_waiter_->SetEngine(engine);
    }
  }
}

FLUTTER_API_SYMBOL(FlutterEngine) FlutterEmbedderNative::GetEngine() const {
  std::scoped_lock lock(engine_mutex_);
  return registered_engine_;
}

void FlutterEmbedderNative::AttachWindowMetricsCallbacks() {
  std::scoped_lock lock(window_metrics_provider_mutex_);
  if (!window_metrics_provider_) {
    return;
  }
  window_metrics_provider_->SetMetricsCallback(
      [this](const AndroidViewportMetrics& metrics) -> bool {
        FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
        {
          std::scoped_lock eng_lock(engine_mutex_);
          engine = registered_engine_;
        }
        if (!engine) {
          return true;
        }
        return SendWindowMetricsEvent(engine, metrics) == kSuccess;
      });

  window_metrics_provider_->SetDisplayUpdateCallback(
      [this](const AndroidDisplayMetrics& metrics) -> bool {
        FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
        {
          std::scoped_lock eng_lock(engine_mutex_);
          engine = registered_engine_;
        }
        if (!engine) {
          return true;
        }
        return NotifyDisplayUpdate(engine, metrics) == kSuccess;
      });
}

std::shared_ptr<WindowMetricsProvider>
FlutterEmbedderNative::GetWindowMetricsProvider() const {
  std::scoped_lock lock(window_metrics_provider_mutex_);
  return window_metrics_provider_;
}

void FlutterEmbedderNative::SetWindowMetricsProvider(
    std::shared_ptr<WindowMetricsProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetWindowMetricsProvider");
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    window_metrics_provider_ =
        provider ? std::move(provider)
                 : std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_);
  }
  AttachWindowMetricsCallbacks();
  if (jni_delegate_) {
    std::shared_ptr<WindowMetricsProvider> current_provider;
    {
      std::scoped_lock lock(window_metrics_provider_mutex_);
      current_provider = window_metrics_provider_;
    }
    jni_delegate_->SetWindowMetricsProvider(current_provider);
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
    const FlutterWindowMetricsEvent* event) const {
  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  {
    std::scoped_lock lock(engine_mutex_);
    engine = registered_engine_;
  }
  if (!engine) {
    return kInvalidArguments;
  }
  return SendWindowMetricsEvent(engine, event);
}

FlutterEngineResult FlutterEmbedderNative::SendWindowMetricsEvent(
    const AndroidViewportMetrics& metrics) const {
  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  {
    std::scoped_lock lock(engine_mutex_);
    engine = registered_engine_;
  }
  if (!engine) {
    return kInvalidArguments;
  }
  return SendWindowMetricsEvent(engine, metrics);
}

FlutterEngineResult FlutterEmbedderNative::SendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterWindowMetricsEvent* event) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::SendWindowMetricsEvent(event)");
  if (!engine || !event ||
      event->struct_size < sizeof(FlutterWindowMetricsEvent)) {
    return kInvalidArguments;
  }
  SendWindowMetricsEventFn test_fn;
  {
    std::scoped_lock lock(engine_mutex_);
    test_fn = send_window_metrics_event_fn_;
  }
  if (test_fn) {
    return test_fn(engine, event);
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
    const AndroidDisplayMetrics& display,
    FlutterEngineDisplaysUpdateType update_type) const {
  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  {
    std::scoped_lock lock(engine_mutex_);
    engine = registered_engine_;
  }
  if (!engine) {
    return kInvalidArguments;
  }
  return NotifyDisplayUpdate(engine, display, update_type);
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
  for (size_t i = 0; i < display_count; ++i) {
    if (displays[i].struct_size < sizeof(FlutterEngineDisplay)) {
      return kInvalidArguments;
    }
  }
  NotifyDisplayUpdateFn test_fn;
  {
    std::scoped_lock lock(engine_mutex_);
    test_fn = notify_display_update_fn_;
  }
  if (test_fn) {
    return test_fn(engine, update_type, displays, display_count);
  }
  return EngineNotifyDisplayUpdate(engine, update_type, displays,
                                   display_count);
}

FlutterEngineResult FlutterEmbedderNative::NotifyDisplayUpdate(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const AndroidDisplayMetrics& display,
    FlutterEngineDisplaysUpdateType update_type) const {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::NotifyDisplayUpdate(display)");
  if (!engine) {
    return kInvalidArguments;
  }
  FlutterEngineDisplay engine_display = TranslateDisplayMetrics(display);
  return NotifyDisplayUpdate(engine, update_type, &engine_display, 1);
}

void FlutterEmbedderNative::SetSendWindowMetricsEventFnForTesting(
    SendWindowMetricsEventFn fn) {
  std::scoped_lock lock(engine_mutex_);
  send_window_metrics_event_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetNotifyDisplayUpdateFnForTesting(
    NotifyDisplayUpdateFn fn) {
  std::scoped_lock lock(engine_mutex_);
  notify_display_update_fn_ = std::move(fn);
}

std::shared_ptr<AndroidChoreographerProvider>
FlutterEmbedderNative::GetChoreographerProvider() const {
  std::scoped_lock lock(choreographer_provider_mutex_);
  return choreographer_provider_;
}

void FlutterEmbedderNative::SetChoreographerProvider(
    std::shared_ptr<AndroidChoreographerProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetChoreographerProvider");
  std::shared_ptr<AndroidChoreographerProvider> new_provider;
  {
    std::scoped_lock lock(choreographer_provider_mutex_);
    choreographer_provider_ =
        provider ? std::move(provider)
                 : std::make_shared<DefaultAndroidChoreographerProvider>(
                       library_loader_);
    new_provider = choreographer_provider_;
  }
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    if (vsync_waiter_) {
      vsync_waiter_->SetChoreographerProvider(new_provider);
    }
  }
}

std::shared_ptr<AndroidVsyncWaiter> FlutterEmbedderNative::GetVsyncWaiter()
    const {
  std::scoped_lock lock(vsync_waiter_mutex_);
  return vsync_waiter_;
}

void FlutterEmbedderNative::SetVsyncWaiter(
    std::shared_ptr<AndroidVsyncWaiter> waiter) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVsyncWaiter");
  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  {
    std::scoped_lock eng_lock(engine_mutex_);
    engine = registered_engine_;
  }
  std::shared_ptr<AndroidVsyncWaiter> new_waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_, choreographer_provider_mutex_);
    vsync_waiter_ = waiter ? std::move(waiter)
                           : std::make_shared<AndroidVsyncWaiter>(
                                 choreographer_provider_, jvm_invoker_);
    if (engine && vsync_waiter_) {
      vsync_waiter_->SetEngine(engine);
    }
    if (notify_vsync_fn_ && vsync_waiter_) {
      vsync_waiter_->SetNotifyVsyncFnForTesting(notify_vsync_fn_);
    }
    new_waiter = vsync_waiter_;
  }
  if (jni_delegate_) {
    jni_delegate_->SetVsyncWaiter(new_waiter);
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
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    waiter = vsync_waiter_;
  }
  if (waiter) {
    return waiter->AsyncWaitForVsync(baton);
  }
  if (jni_router_) {
    return jni_router_->RouteAsyncWaitForVsync(baton);
  }
  return false;
}

void FlutterEmbedderNative::UpdateRefreshRate(double refresh_rate_hz) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::UpdateRefreshRate",
               "refresh_rate", std::to_string(refresh_rate_hz).c_str());
  if (!std::isfinite(refresh_rate_hz) || refresh_rate_hz <= 0.0) {
    refresh_rate_hz = 60.0;
  } else {
    refresh_rate_hz = std::clamp(refresh_rate_hz, 1.0, 1000.0);
  }
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    waiter = vsync_waiter_;
  }
  if (waiter) {
    waiter->UpdateRefreshRate(refresh_rate_hz);
  }
}

double FlutterEmbedderNative::GetRefreshRate() const {
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    waiter = vsync_waiter_;
  }
  if (waiter) {
    return waiter->GetRefreshRate();
  }
  return 60.0;
}

int64_t FlutterEmbedderNative::GetRefreshPeriodNanos() const {
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    waiter = vsync_waiter_;
  }
  if (waiter) {
    return waiter->GetRefreshPeriodNanos();
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

FlutterEngineResult FlutterEmbedderNative::NotifyVsync(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    intptr_t baton,
    int64_t frame_start_time_nanos,
    int64_t frame_target_time_nanos) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::NotifyVsync");
  if (!engine || frame_start_time_nanos <= 0 ||
      frame_target_time_nanos <= frame_start_time_nanos) {
    return kInvalidArguments;
  }
  NotifyVsyncFn fn;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    fn = notify_vsync_fn_;
  }
  if (fn) {
    return fn(engine, baton, static_cast<uint64_t>(frame_start_time_nanos),
              static_cast<uint64_t>(frame_target_time_nanos));
  }
  return AndroidVsyncWaiter::NotifyVsyncToEngine(
      engine, baton, static_cast<uint64_t>(frame_start_time_nanos),
      static_cast<uint64_t>(frame_target_time_nanos));
}

void FlutterEmbedderNative::SetNotifyVsyncFnForTesting(NotifyVsyncFn fn) {
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    notify_vsync_fn_ = fn;
    waiter = vsync_waiter_;
  }
  if (waiter) {
    waiter->SetNotifyVsyncFnForTesting(std::move(fn));
  }
}

bool FlutterEmbedderNative::InitVM(const AndroidVMArgs& args) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::InitVM");
  if (jni_router_) {
    return jni_router_->RouteInitVM(args);
  }
  std::scoped_lock lock(vm_init_mutex_);
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
  std::scoped_lock lock(vm_init_mutex_);
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
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->SetVmServiceUri(uri);
  }
  return false;
}

std::string FlutterEmbedderNative::GetVmServiceUri() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->GetVmServiceUri();
  }
  return "";
}

bool FlutterEmbedderNative::IsVMInitialized() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->IsInitialized();
  }
  return false;
}

std::optional<AndroidVMArgs> FlutterEmbedderNative::GetVMArgs() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->GetVMArgs();
  }
  return std::nullopt;
}

AndroidRenderingAPI FlutterEmbedderNative::GetSelectedRenderingAPI() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->GetSelectedRenderingAPI();
  }
  return AndroidRenderingAPI::kSkiaOpenGLES;
}

const FlutterProjectArgs* FlutterEmbedderNative::GetProjectArgs() const {
  std::scoped_lock lock(vm_init_mutex_);
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
  if (!config || !args || !engine_out ||
      args->struct_size < sizeof(FlutterProjectArgs)) {
    return kInvalidArguments;
  }
  void* effective_user_data =
      user_data ? user_data : const_cast<FlutterEmbedderNative*>(this);
  return EngineInitialize(FLUTTER_ENGINE_VERSION, config, args,
                          effective_user_data, engine_out);
}

FlutterEngineResult FlutterEmbedderNative::DeinitializeEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DeinitializeEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  return EngineDeinitialize(engine);
}

FlutterEngineResult FlutterEmbedderNative::EngineCreateAOTData(
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

FlutterEngineResult FlutterEmbedderNative::EngineCollectAOTData(
    FlutterEngineAOTData data) {
  if (!data) {
    return kSuccess;
  }
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
  std::scoped_lock lock(aot_provider_mutex_);
  if (aot_provider_) {
    return aot_provider_->CreateAOTData(source, data_out);
  }
  return EngineCreateAOTData(source, data_out);
}

FlutterEngineResult FlutterEmbedderNative::CollectAOTData(
    FlutterEngineAOTData data) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CollectAOTData");
  if (!data) {
    return kSuccess;
  }
  std::scoped_lock lock(aot_provider_mutex_);
  if (aot_provider_) {
    return aot_provider_->CollectAOTData(data);
  }
  return EngineCollectAOTData(data);
}

std::shared_ptr<AndroidVMInit> FlutterEmbedderNative::GetVMInit() const {
  std::scoped_lock lock(vm_init_mutex_);
  return vm_init_;
}

void FlutterEmbedderNative::SetVMInit(std::shared_ptr<AndroidVMInit> vm_init) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVMInit");
  std::shared_ptr<AndroidVMInit> new_init;
  {
    std::scoped_lock lock(vm_init_mutex_, font_provider_mutex_,
                          aot_provider_mutex_);
    vm_init_ = vm_init ? std::move(vm_init)
                       : std::make_shared<AndroidVMInit>(
                             jvm_invoker_, font_provider_, aot_provider_);
    new_init = vm_init_;
  }
  if (jni_delegate_) {
    jni_delegate_->SetVMInit(new_init);
  }
}

std::shared_ptr<FontCollectionProvider>
FlutterEmbedderNative::GetFontCollectionProvider() const {
  std::scoped_lock lock(font_provider_mutex_);
  return font_provider_;
}

void FlutterEmbedderNative::SetFontCollectionProvider(
    std::shared_ptr<FontCollectionProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetFontCollectionProvider");
  std::scoped_lock lock(font_provider_mutex_, vm_init_mutex_);
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
  std::scoped_lock lock(aot_provider_mutex_);
  return aot_provider_;
}

void FlutterEmbedderNative::SetAOTProvider(
    std::shared_ptr<AndroidAOTProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetAOTProvider");
  std::scoped_lock lock(aot_provider_mutex_, vm_init_mutex_);
  aot_provider_ = provider ? std::move(provider)
                           : std::make_shared<DefaultAndroidAOTProvider>();
  if (vm_init_) {
    vm_init_->SetAOTProvider(aot_provider_);
  }
}

std::shared_ptr<AndroidHardwareBufferProvider>
FlutterEmbedderNative::GetHardwareBufferProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetHardwareBufferProvider");
  std::scoped_lock lock(hardware_buffer_provider_mutex_);
  return hardware_buffer_provider_;
}

void FlutterEmbedderNative::SetHardwareBufferProvider(
    std::shared_ptr<AndroidHardwareBufferProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetHardwareBufferProvider");
  std::scoped_lock lock(hardware_buffer_provider_mutex_);
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

}  // namespace android
}  // namespace flutter
