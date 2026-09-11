// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <android/native_window_jni.h>
#include <dlfcn.h>
#include <algorithm>
#include <cstring>

#include "unicode/uchar.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
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
    : jvm_invoker_(std::make_shared<AndroidJvmInvoker>()),
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
      jni_delegate_(std::make_shared<JniDelegate>(
          jvm_invoker_,
          std::make_shared<DefaultCallbackCacheProvider>(),
          std::make_shared<DefaultImageDecoderProvider>(jvm_invoker_),
          platform_views_provider_,
          platform_views_controller_,
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
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group)
    : jvm_invoker_(jvm_invoker ? std::move(jvm_invoker)
                               : std::make_shared<AndroidJvmInvoker>()),
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
  AttachWindowMetricsCallbacks();
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterEmbedderNative(custom)");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with custom components.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  UnregisterImageDecoder();
  auto engine = GetEngine();
  if (engine) {
    DeinitializeEngine(engine);
    SetEngine(nullptr);
  }
  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);
  std::lock_guard<std::mutex> surf_lock(surface_mutex_);
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
}

void FlutterEmbedderNative::AttachJavaObject(JNIEnv* env, jobject flutterJNI) {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  if (env && flutterJNI) {
    java_object_ =
        std::make_shared<fml::jni::JavaObjectWeakGlobalRef>(env, flutterJNI);
  } else {
    java_object_ = nullptr;
  }
  if (jvm_invoker_) {
    jvm_invoker_->SetJavaObject(java_object_);
  }
}

fml::jni::ScopedJavaLocalRef<jobject> FlutterEmbedderNative::GetJavaObject(
    JNIEnv* env) const {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  if (!java_object_ || !env) {
    return fml::jni::ScopedJavaLocalRef<jobject>();
  }
  return java_object_->get(env);
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
  if (window) {
    ANativeWindow_acquire(window);
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
  }
  native_window_ = window;
  if (jni_delegate_) {
    jni_delegate_->SetNativeWindow(window);
  }
}

ANativeWindow* FlutterEmbedderNative::GetNativeWindow() {
  std::lock_guard<std::mutex> lock(surface_mutex_);
  return native_window_;
}

ANativeWindow* FlutterEmbedderNative::AcquireNativeWindow() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::AcquireNativeWindow");
  std::lock_guard<std::mutex> lock(surface_mutex_);
  if (native_window_) {
    ANativeWindow_acquire(native_window_);
  }
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
}

bool FlutterEmbedderNative::IsEmbedderEnabled() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsEmbedderEnabled");
  return true;
}

void FlutterEmbedderNative::SetEmbedderEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEmbedderEnabled");
  (void)enabled;
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
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(
      std::move(invoker), nullptr, nullptr, std::move(platform_views_provider),
      nullptr, std::move(window_metrics_provider), std::move(vsync_waiter),
      std::move(vm_init), std::move(hardware_buffer_provider),
      std::move(vulkan_texture_provider), std::move(surface_control_provider),
      std::move(engine_group_provider), std::move(engine_group));
  (void)legacy_delegate;
  return std::make_shared<JniRouter>(std::move(delegate));
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
  {
    std::lock_guard<std::mutex> lock(viewport_metrics_mutex_);
    const_cast<FlutterEmbedderNative*>(this)->cached_viewport_metrics_ =
        metrics;
  }
  if (!jni_router_) {
    return false;
  }
  return jni_router_->RouteSetViewportMetrics(metrics);
}

AndroidViewportMetrics FlutterEmbedderNative::GetViewportMetrics() const {
  std::lock_guard<std::mutex> lock(viewport_metrics_mutex_);
  return cached_viewport_metrics_;
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

void FlutterEmbedderNative::OnPlatformMessageCallback(
    const FlutterPlatformMessage* message,
    void* user_data) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnPlatformMessageCallback");
  if (!message || !user_data) {
    return;
  }
  auto* native = reinterpret_cast<FlutterEmbedderNative*>(user_data);
  std::vector<uint8_t> data;
  if (message->message && message->message_size > 0) {
    data.assign(message->message, message->message + message->message_size);
  }
  int32_t response_id = 0;
  if (message->response_handle != nullptr) {
    response_id = native->RegisterResponseHandle(message->response_handle);
  }
  if (native->GetRouter()) {
    native->GetRouter()->RoutePlatformMessage(
        message->channel ? message->channel : "", data, response_id);
  }
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
  if (initialize_engine_fn_) {
    return initialize_engine_fn_(config, args, user_data, engine_out);
  }
  if (!config || !args || !engine_out ||
      args->struct_size < sizeof(FlutterProjectArgs)) {
    return kInvalidArguments;
  }
  void* effective_user_data =
      user_data ? user_data : const_cast<FlutterEmbedderNative*>(this);
  return EngineInitialize(FLUTTER_ENGINE_VERSION, config, args,
                          effective_user_data, engine_out);
}

FlutterEngineResult FlutterEmbedderNative::RunInitializedEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RunInitializedEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  if (run_initialized_engine_fn_) {
    return run_initialized_engine_fn_(engine);
  }
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

FlutterEngineResult FlutterEmbedderNative::Launch(
    const std::string& entrypoint,
    const std::string& library_url,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::Launch", "engine_id",
               std::to_string(engine_id).c_str());

  auto existing_engine = GetEngine();
  if (existing_engine != nullptr) {
    return RunInitializedEngine(existing_engine);
  }

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.engine_id = engine_id;
  args.custom_dart_entrypoint =
      entrypoint.empty() ? nullptr : entrypoint.c_str();

  std::vector<const char*> c_args;
  c_args.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    c_args.push_back(arg.c_str());
  }
  args.dart_entrypoint_argc = c_args.size();
  args.dart_entrypoint_argv = c_args.data();

  std::string asset_dir;
  {
    std::lock_guard<std::mutex> lock(asset_provider_mutex_);
    if (asset_provider_) {
      asset_dir = asset_provider_->GetDirectory();
    }
  }
  if (!asset_dir.empty()) {
    args.assets_path = asset_dir.c_str();
  }

  args.vsync_callback = &FlutterEmbedderNative::OnVsyncCallback;
  args.platform_message_callback =
      &FlutterEmbedderNative::OnPlatformMessageCallback;

  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = [](void* user_data) -> bool { return true; };
  config.open_gl.clear_current = [](void* user_data) -> bool { return true; };
  config.open_gl.present = [](void* user_data) -> bool { return true; };
  config.open_gl.fbo_callback = [](void* user_data) -> uint32_t { return 0; };

  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  FlutterEngineResult init_result =
      InitializeEngine(&config, &args, this, &engine);
  if (init_result != kSuccess || engine == nullptr) {
    return init_result;
  }

  SetEngine(engine);
  return RunInitializedEngine(engine);
}

FlutterEngineResult FlutterEmbedderNative::ScheduleFrame() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ScheduleFrame");
  auto engine = GetEngine();
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

FlutterEngineResult FlutterEmbedderNative::SendPointerEvents(
    const FlutterPointerEvent* events,
    size_t count) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPointerEvents", "count",
               std::to_string(count).c_str());

  if (send_pointer_event_fn_) {
    return send_pointer_event_fn_(events, count);
  }

  auto engine = GetEngine();
  if (!engine) {
    return kSuccess;
  }

  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();

  if (s_procs.SendPointerEvent) {
    return s_procs.SendPointerEvent(engine, events, count);
  }
  return kInternalInconsistency;
}

FlutterEngineResult FlutterEmbedderNative::SendPointerDataPacket(
    const uint8_t* buffer,
    size_t size) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPointerDataPacket",
               "size", std::to_string(size).c_str());

  if (!buffer || size == 0) {
    return kInvalidArguments;
  }

  constexpr size_t kBytesPerField = 8;
  constexpr size_t kFieldCount = 36;
  constexpr size_t kPacketEntrySize = kBytesPerField * kFieldCount;

  if (size % kPacketEntrySize != 0) {
    FML_LOG(ERROR) << "Invalid pointer data packet size: " << size
                   << " (must be multiple of " << kPacketEntrySize << ")";
    return kInvalidArguments;
  }

  size_t event_count = size / kPacketEntrySize;
  std::vector<FlutterPointerEvent> events;
  events.reserve(event_count);

  for (size_t i = 0; i < event_count; ++i) {
    const uint8_t* entry = buffer + (i * kPacketEntrySize);
    const int64_t* int_fields = reinterpret_cast<const int64_t*>(entry);
    const double* double_fields = reinterpret_cast<const double*>(entry);

    FlutterPointerEvent event = {};
    event.struct_size = sizeof(FlutterPointerEvent);

    int64_t change = int_fields[2];
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

    int64_t kind = int_fields[3];
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

    int64_t signal_kind = int_fields[4];
    switch (signal_kind) {
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

    event.timestamp = static_cast<size_t>(int_fields[1]);
    event.device = static_cast<int32_t>(int_fields[5]);
    event.x = double_fields[7];
    event.y = double_fields[8];
    event.buttons = int_fields[11];
    event.pressure = double_fields[14];
    event.pressure_min = double_fields[15];
    event.pressure_max = double_fields[16];
    event.distance = double_fields[17];
    event.distance_max = double_fields[18];
    event.size = double_fields[19];
    event.radius_major = double_fields[20];
    event.radius_minor = double_fields[21];
    event.radius_min = double_fields[22];
    event.radius_max = double_fields[23];
    event.orientation = double_fields[24];
    event.tilt = double_fields[25];
    event.platform_data = int_fields[26];
    event.embedder_id = int_fields[0];
    event.scroll_delta_x = double_fields[27];
    event.scroll_delta_y = double_fields[28];
    event.pan_x = double_fields[29];
    event.pan_y = double_fields[30];
    event.scale = double_fields[33];
    event.rotation = double_fields[34];
    event.view_id = static_cast<FlutterViewId>(int_fields[35]);

    events.push_back(event);
  }

  return SendPointerEvents(events.data(), events.size());
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessage(
    const std::string& channel,
    const uint8_t* message,
    size_t size,
    int32_t response_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPlatformMessage",
               "channel", channel.c_str());

  if (send_platform_message_fn_) {
    return send_platform_message_fn_(channel, message, size, response_id);
  }

  auto engine = GetEngine();
  if (!engine) {
    std::vector<uint8_t> data;
    if (message && size > 0) {
      data.assign(message, message + size);
    }
    if (jni_router_) {
      jni_router_->RoutePlatformMessage(channel, data, response_id);
    }
    return kSuccess;
  }

  FlutterPlatformMessage msg = {};
  msg.struct_size = sizeof(FlutterPlatformMessage);
  msg.channel = channel.c_str();
  msg.message = message;
  msg.message_size = size;

  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();

  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (response_id != 0 && s_procs.PlatformMessageCreateResponseHandle) {
    struct ResponseUserData {
      std::shared_ptr<JvmInvoker> invoker;
      int32_t response_id;
    };

    auto* user_data = new ResponseUserData{jvm_invoker_, response_id};

    FlutterEngineResult create_res =
        s_procs.PlatformMessageCreateResponseHandle(
            engine,
            [](const uint8_t* data, size_t data_size, void* udata) {
              auto* r_data = static_cast<ResponseUserData*>(udata);
              if (r_data && r_data->invoker) {
                r_data->invoker->HandlePlatformMessageResponse(
                    r_data->response_id, data, data_size);
              }
              delete r_data;
            },
            user_data, &response_handle);

    if (create_res == kSuccess) {
      msg.response_handle = response_handle;
    } else {
      delete user_data;
    }
  }

  FlutterEngineResult result = kInternalInconsistency;
  if (s_procs.SendPlatformMessage) {
    result = s_procs.SendPlatformMessage(engine, &msg);
  }

  if (response_handle && s_procs.PlatformMessageReleaseResponseHandle) {
    s_procs.PlatformMessageReleaseResponseHandle(engine, response_handle);
  }

  return result;
}

FlutterEngineResult FlutterEmbedderNative::SendPlatformMessageResponse(
    int32_t response_id,
    const uint8_t* data,
    size_t data_length) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SendPlatformMessageResponse",
               "response_id", std::to_string(response_id).c_str());

  if (send_platform_message_response_fn_) {
    return send_platform_message_response_fn_(response_id, data, data_length);
  }

  const auto* handle = ReleaseResponseHandle(response_id);
  if (!handle) {
    return kInvalidArguments;
  }

  auto engine = GetEngine();
  if (!engine) {
    if (jni_router_) {
      std::vector<uint8_t> vec;
      if (data && data_length > 0) {
        vec.assign(data, data + data_length);
      }
      jni_router_->RoutePlatformMessageResponse(response_id, vec);
    }
    return kSuccess;
  }

  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();

  if (s_procs.SendPlatformMessageResponse && handle) {
    return s_procs.SendPlatformMessageResponse(engine, handle, data,
                                               data_length);
  }
  return kInternalInconsistency;
}

int32_t FlutterEmbedderNative::RegisterResponseHandle(
    const FlutterPlatformMessageResponseHandle* handle) const {
  if (!handle) {
    return 0;
  }
  int32_t id = next_response_id_.fetch_add(1);
  std::scoped_lock lock(response_handles_mutex_);
  response_handles_[id] = handle;
  return id;
}

const FlutterPlatformMessageResponseHandle*
FlutterEmbedderNative::ReleaseResponseHandle(int32_t response_id) const {
  if (response_id == 0) {
    return nullptr;
  }
  std::scoped_lock lock(response_handles_mutex_);
  auto it = response_handles_.find(response_id);
  if (it != response_handles_.end()) {
    const auto* handle = it->second;
    response_handles_.erase(it);
    return handle;
  }
  return nullptr;
}

void FlutterEmbedderNative::RegisterSurfaceTexture(
    int64_t texture_id,
    fml::jni::ScopedJavaGlobalRef<jobject> surface_texture) {
  std::scoped_lock lock(surface_textures_mutex_);
  surface_textures_[texture_id] =
      std::make_shared<fml::jni::ScopedJavaGlobalRef<jobject>>(
          std::move(surface_texture));
}

void FlutterEmbedderNative::UnregisterSurfaceTexture(int64_t texture_id) {
  std::scoped_lock lock(surface_textures_mutex_);
  surface_textures_.erase(texture_id);
}

void FlutterEmbedderNative::SetSendPointerEventFnForTesting(
    SendPointerEventFn fn) {
  send_pointer_event_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetSendPlatformMessageFnForTesting(
    SendPlatformMessageFn fn) {
  send_platform_message_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetSendPlatformMessageResponseFnForTesting(
    SendPlatformMessageResponseFn fn) {
  send_platform_message_response_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetDeinitializeEngineFnForTesting(
    DeinitializeEngineFn fn) {
  deinitialize_engine_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetInitializeEngineFnForTesting(
    InitializeEngineFn fn) {
  initialize_engine_fn_ = std::move(fn);
}

void FlutterEmbedderNative::SetRunInitializedEngineFnForTesting(
    RunInitializedEngineFn fn) {
  run_initialized_engine_fn_ = std::move(fn);
}

FlutterEngineResult FlutterEmbedderNative::DeinitializeEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DeinitializeEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  if (deinitialize_engine_fn_) {
    return deinitialize_engine_fn_(engine);
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

std::shared_ptr<AndroidVulkanTextureProvider>
FlutterEmbedderNative::GetVulkanTextureProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetVulkanTextureProvider");
  std::lock_guard<std::mutex> lock(vulkan_texture_provider_mutex_);
  return vulkan_texture_provider_;
}

void FlutterEmbedderNative::SetVulkanTextureProvider(
    std::shared_ptr<AndroidVulkanTextureProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetVulkanTextureProvider");
  std::shared_ptr<AndroidVulkanTextureProvider> resolved_provider =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidVulkanTextureProvider>(
                     library_loader_);
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_provider_mutex_);
    vulkan_texture_provider_ = resolved_provider;
  }
  if (jni_delegate_) {
    jni_delegate_->SetVulkanTextureProvider(resolved_provider);
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
  std::scoped_lock lock(surface_control_provider_mutex_);
  return surface_control_provider_;
}

void FlutterEmbedderNative::SetSurfaceControlProvider(
    std::shared_ptr<AndroidSurfaceControlProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetSurfaceControlProvider");
  std::scoped_lock lock(surface_control_provider_mutex_);
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
  std::scoped_lock lock(engine_group_mutex_);
  return engine_group_;
}

void FlutterEmbedderNative::SetEngineGroup(
    std::shared_ptr<AndroidEngineGroup> group) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEngineGroup");
  {
    std::scoped_lock lock(engine_group_mutex_);
    engine_group_ = group;
  }
  if (jni_delegate_) {
    jni_delegate_->SetEngineGroup(group);
  }
}

std::shared_ptr<AndroidEngineGroupProvider>
FlutterEmbedderNative::GetEngineGroupProvider() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEngineGroupProvider");
  std::scoped_lock lock(engine_group_provider_mutex_);
  return engine_group_provider_;
}

void FlutterEmbedderNative::SetEngineGroupProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEngineGroupProvider");
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_provider_mutex_, engine_group_mutex_);
    engine_group_provider_ = provider;
    group = engine_group_;
  }
  if (group) {
    group->SetProvider(provider);
  }
  if (jni_delegate_) {
    jni_delegate_->SetEngineGroupProvider(provider);
  }
}

FLUTTER_API_SYMBOL(FlutterEngine)
FlutterEmbedderNative::SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                       parent_engine,
                                   const AndroidEngineSpawnArgs& args) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SpawnEngine", "entrypoint",
               args.entrypoint.c_str());
  std::shared_ptr<AndroidEngineGroup> group;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(engine_group_mutex_, engine_group_provider_mutex_);
    group = engine_group_;
    provider = engine_group_provider_;
  }
  if (group) {
    return group->SpawnEngine(parent_engine, args);
  }
  if (!parent_engine || !provider) {
    return nullptr;
  }
  AndroidEngineGroupSpawnConfigHolder holder;
  holder.Build(args);
  FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine = nullptr;
  if (provider->SpawnEngine(parent_engine, holder.GetSpawnConfig(),
                            &spawned_engine) == kSuccess) {
    return spawned_engine;
  }
  return nullptr;
}

int64_t FlutterEmbedderNative::SpawnEngine(
    int64_t parent_engine_id,
    const AndroidEngineSpawnArgs& args) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SpawnEngine(id)",
               "entrypoint", args.entrypoint.c_str());
  if (jni_router_) {
    return jni_router_->RouteSpawnEngine(parent_engine_id, args);
  }
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (group) {
    auto handle = group->SpawnEngine(parent_engine_id, args);
    if (handle) {
      auto id_opt = group->GetEngineId(handle);
      return id_opt.value_or(args.engine_id != 0 ? args.engine_id : 0);
    }
  }
  return 0;
}

FLUTTER_API_SYMBOL(FlutterEngine)
FlutterEmbedderNative::SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                       parent_engine,
                                   const FlutterEngineSpawnConfig* config,
                                   int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::SpawnEngine(config)",
               "engine_id", std::to_string(engine_id).c_str());
  if (!parent_engine || !config ||
      config->struct_size < sizeof(FlutterEngineSpawnConfig)) {
    return nullptr;
  }
  std::shared_ptr<AndroidEngineGroup> group;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(engine_group_mutex_, engine_group_provider_mutex_);
    group = engine_group_;
    provider = engine_group_provider_;
  }
  if (group) {
    return group->SpawnEngineWithConfig(parent_engine, config, engine_id);
  }
  if (!provider) {
    return nullptr;
  }
  FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine = nullptr;
  if (provider->SpawnEngine(parent_engine, config, &spawned_engine) ==
      kSuccess) {
    return spawned_engine;
  }
  return nullptr;
}

FlutterEngineResult FlutterEmbedderNative::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnConfig* config,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SpawnEngine(raw)");
  if (!parent_engine || !config || !engine_out ||
      config->struct_size < sizeof(FlutterEngineSpawnConfig)) {
    return kInvalidArguments;
  }
  std::shared_ptr<AndroidEngineGroup> group;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(engine_group_mutex_, engine_group_provider_mutex_);
    group = engine_group_;
    provider = engine_group_provider_;
  }
  if (group) {
    *engine_out = group->SpawnEngineWithConfig(parent_engine, config);
    return *engine_out ? kSuccess : kInvalidArguments;
  }
  if (!provider) {
    return kInternalInconsistency;
  }
  return provider->SpawnEngine(parent_engine, config, engine_out);
}

FlutterEngineResult FlutterEmbedderNative::ShutdownEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ShutdownEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  std::shared_ptr<AndroidEngineGroup> group;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(engine_group_mutex_, engine_group_provider_mutex_);
    group = engine_group_;
    provider = engine_group_provider_;
  }
  if (group) {
    return group->ShutdownEngine(engine) ? kSuccess : kInvalidArguments;
  }
  if (provider) {
    return provider->ShutdownEngine(engine);
  }
  return kInternalInconsistency;
}

bool FlutterEmbedderNative::ShutdownSpawnedEngine(int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::ShutdownSpawnedEngine",
               "engine_id", std::to_string(engine_id).c_str());
  if (jni_router_) {
    return jni_router_->RouteShutdownSpawnedEngine(engine_id);
  }
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (group) {
    return group->ShutdownEngine(engine_id);
  }
  return false;
}

bool FlutterEmbedderNative::OnEngineGarbageCollected(int64_t engine_id) const {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::OnEngineGarbageCollected",
               "engine_id", std::to_string(engine_id).c_str());
  if (jni_router_) {
    return jni_router_->RouteOnEngineGarbageCollected(engine_id);
  }
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (group) {
    return group->OnEngineGarbageCollected(engine_id);
  }
  return false;
}

size_t FlutterEmbedderNative::GetActiveEngineCount() const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetActiveEngineCount");
  if (jni_router_) {
    return jni_router_->RouteGetActiveEngineCount();
  }
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (group) {
    return group->GetActiveEngineCount();
  }
  return 0;
}

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;
static jfieldID g_jni_shell_holder_field = nullptr;
static jmethodID g_jni_constructor = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_java_long_class = nullptr;
static jmethodID g_long_constructor = nullptr;
static jmethodID g_long_value_method = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_callback_info_class =
    nullptr;
static jmethodID g_flutter_callback_info_constructor = nullptr;

static FlutterEmbedderNative* FromJavaFlutterJNI(JNIEnv* env, jobject obj) {
  if (!env || !obj || !g_jni_shell_holder_field || !g_long_value_method) {
    return nullptr;
  }
  jobject shellHolderLong = env->GetObjectField(obj, g_jni_shell_holder_field);
  if (!shellHolderLong) {
    return nullptr;
  }
  jlong raw_handle = env->CallLongMethod(shellHolderLong, g_long_value_method);
  return reinterpret_cast<FlutterEmbedderNative*>(raw_handle);
}

static jlong FlutterJNI_Attach(JNIEnv* env, jclass clazz, jobject flutterJNI) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterJNI_Attach");
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
  native_instance->AttachJavaObject(env, flutterJNI);
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

  int64_t spawned_id =
      native_instance->GetRouter()->RouteSpawnEngine(engineId, spawn_args);

  if (!g_flutter_jni_class || g_flutter_jni_class->is_null() ||
      !g_jni_constructor || !g_java_long_class ||
      g_java_long_class->is_null() || !g_long_constructor ||
      !g_jni_shell_holder_field) {
    return nullptr;
  }

  jobject jni = env->NewObject(g_flutter_jni_class->obj(), g_jni_constructor);
  if (!jni) {
    return nullptr;
  }

  auto spawned_instance = std::make_unique<FlutterEmbedderNative>();
  spawned_instance->AttachJavaObject(env, jni);
  if (spawned_id != 0 && native_instance->GetEngineGroup()) {
    auto spawned_engine =
        native_instance->GetEngineGroup()->GetEngineHandle(spawned_id);
    if (spawned_engine) {
      spawned_instance->SetEngine(spawned_engine);
    }
  }

  jlong raw_handle = reinterpret_cast<jlong>(spawned_instance.get());
  jobject javaLong = env->CallStaticObjectMethod(
      g_java_long_class->obj(), g_long_constructor, raw_handle);
  if (javaLong == nullptr) {
    return nullptr;
  }
  env->SetObjectField(jni, g_jni_shell_holder_field, javaLong);
  spawned_instance.release();

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
  if (jAssetManager != nullptr) {
    auto asset_provider =
        std::make_shared<APKAssetProvider>(env, jAssetManager, bundle_path);
    native_instance->SetAssetProvider(std::move(asset_provider));
  }

  std::string entrypoint =
      jEntrypoint ? fml::jni::JavaStringToString(env, jEntrypoint) : "main";
  std::string library_url =
      jLibraryUrl ? fml::jni::JavaStringToString(env, jLibraryUrl) : "";
  std::vector<std::string> entrypoint_args;
  if (jEntrypointArgs != nullptr) {
    entrypoint_args = fml::jni::StringListToVector(env, jEntrypointArgs);
  }

  native_instance->Launch(entrypoint, library_url, entrypoint_args, engineId);
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
  native_instance->SendPlatformMessage(str_channel, nullptr, 0, responseId);
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
  std::vector<uint8_t> data;
  if (message != nullptr && position > 0) {
    jlong capacity = env->GetDirectBufferCapacity(message);
    if (capacity >= 0 && position <= capacity) {
      const uint8_t* buffer =
          static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
      if (buffer != nullptr) {
        data.assign(buffer, buffer + position);
      }
    } else {
      FML_LOG(ERROR) << "DispatchPlatformMessage: position " << position
                     << " exceeds direct buffer capacity " << capacity;
    }
  }
  native_instance->SendPlatformMessage(str_channel, data.data(), data.size(),
                                       responseId);
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
  std::vector<uint8_t> data;
  if (message != nullptr && position > 0) {
    jlong capacity = env->GetDirectBufferCapacity(message);
    if (capacity >= 0 && position <= capacity) {
      const uint8_t* buffer =
          static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
      if (buffer != nullptr) {
        data.assign(buffer, buffer + position);
      }
    } else {
      FML_LOG(ERROR) << "InvokePlatformMessageResponseCallback: position "
                     << position << " exceeds direct buffer capacity "
                     << capacity;
    }
  }
  native_instance->SendPlatformMessageResponse(responseId, data.data(),
                                               data.size());
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
  native_instance->SendPlatformMessageResponse(responseId, nullptr, 0);
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
  auto engine = native_instance->GetEngine();
  if (engine) {
    static FlutterEngineProcTable s_procs = []() {
      FlutterEngineProcTable procs = {};
      procs.struct_size = sizeof(FlutterEngineProcTable);
      FlutterEngineGetProcAddresses(&procs);
      return procs;
    }();
    if (s_procs.NotifyLowMemoryWarning) {
      s_procs.NotifyLowMemoryWarning(engine);
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
  fml::jni::ScopedJavaLocalFrame scoped_local_frame(env);
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  ANativeWindow* window = nullptr;
  if (jsurface != nullptr) {
    window = ANativeWindow_fromSurface(env, jsurface);
  }
  native_instance->SetNativeWindow(window);
  if (window) {
    ANativeWindow_release(window);
  }
  native_instance->GetRouter()->RouteFirstFrame();
}

static void FlutterJNI_SurfaceWindowChanged(JNIEnv* env,
                                            jobject jcaller,
                                            jlong native_handle,
                                            jobject jsurface) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterJNI_SurfaceWindowChanged");
  fml::jni::ScopedJavaLocalFrame scoped_local_frame(env);
  auto* native_instance =
      reinterpret_cast<FlutterEmbedderNative*>(native_handle);
  if (!native_instance) {
    return;
  }
  ANativeWindow* window = nullptr;
  if (jsurface != nullptr) {
    window = ANativeWindow_fromSurface(env, jsurface);
  }
  native_instance->SetNativeWindow(window);
  if (window) {
    ANativeWindow_release(window);
  }
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
  AndroidViewportMetrics metrics = native_instance->GetViewportMetrics();
  metrics.physical_width = width;
  metrics.physical_height = height;
  if (metrics.device_pixel_ratio <= 0.0f) {
    metrics.device_pixel_ratio = 1.0f;
  }
  native_instance->SetViewportMetrics(metrics);
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
  native_instance->SetNativeWindow(nullptr);
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
  if (!native_instance) {
    return;
  }
  if (buffer == nullptr || position <= 0) {
    return;
  }
  jlong capacity = env->GetDirectBufferCapacity(buffer);
  if (capacity < 0 || position > capacity) {
    FML_LOG(ERROR) << "DispatchPointerDataPacket: position " << position
                   << " exceeds direct buffer capacity " << capacity;
    return;
  }
  const uint8_t* data =
      static_cast<const uint8_t*>(env->GetDirectBufferAddress(buffer));
  if (data != nullptr) {
    native_instance->SendPointerDataPacket(data, position);
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
    jlong capacity = env->GetDirectBufferCapacity(args);
    if (capacity >= 0 && args_position <= capacity) {
      const uint8_t* buffer =
          static_cast<const uint8_t*>(env->GetDirectBufferAddress(args));
      if (buffer != nullptr) {
        action_data.assign(buffer, buffer + args_position);
      }
    } else {
      FML_LOG(ERROR) << "DispatchSemanticsAction: args_position "
                     << args_position << " exceeds direct buffer capacity "
                     << capacity;
    }
  }
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->DispatchSemanticsActionToEngine(
        engine, id, static_cast<FlutterSemanticsAction>(action),
        action_data.data(), action_data.size());
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
  native_instance->SetSemanticsEnabled(enabled);
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->UpdateSemanticsEnabled(engine, enabled);
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
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->UpdateAccessibilityFeatures(
        engine, static_cast<FlutterAccessibilityFeature>(flags));
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
  if (surface_texture != nullptr) {
    native_instance->RegisterSurfaceTexture(
        texture_id,
        fml::jni::ScopedJavaGlobalRef<jobject>(env, surface_texture));
  }
  native_instance->RegisterHardwareBufferTexture(texture_id);
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->RegisterExternalTexture(engine, texture_id);
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
  if (image_texture_entry != nullptr) {
    native_instance->RegisterSurfaceTexture(
        texture_id,
        fml::jni::ScopedJavaGlobalRef<jobject>(env, image_texture_entry));
  }
  native_instance->RegisterHardwareBufferTexture(texture_id);
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->RegisterExternalTexture(engine, texture_id);
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
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->MarkExternalTextureFrameAvailable(engine, texture_id);
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
  native_instance->ScheduleFrame();
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
  native_instance->UnregisterSurfaceTexture(texture_id);
  native_instance->UnregisterHardwareBufferTexture(texture_id);
  auto engine = native_instance->GetEngine();
  if (engine) {
    native_instance->UnregisterExternalTexture(engine, texture_id);
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
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI);
}

static jboolean FlutterJNI_FlutterTextUtilsIsEmojiModifier(JNIEnv* env,
                                                           jobject obj,
                                                           jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsEmojiModifier");
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER);
}

static jboolean FlutterJNI_FlutterTextUtilsIsEmojiModifierBase(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsEmojiModifierBase");
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER_BASE);
}

static jboolean FlutterJNI_FlutterTextUtilsIsVariationSelector(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsVariationSelector");
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_VARIATION_SELECTOR);
}

static jboolean FlutterJNI_FlutterTextUtilsIsRegionalIndicator(JNIEnv* env,
                                                               jobject obj,
                                                               jint codePoint) {
  TRACE_EVENT0(
      "flutter",
      "FlutterEmbedderNative::FlutterJNI_FlutterTextUtilsIsRegionalIndicator");
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_REGIONAL_INDICATOR);
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
  auto engine = native_instance->GetEngine();
  int64_t loading_unit_id = static_cast<int64_t>(jLoadingUnitId);
  std::vector<std::string> search_paths;
  if (jSearchPaths != nullptr) {
    search_paths = fml::jni::StringArrayToVector(env, jSearchPaths);
  }

  void* handle = nullptr;
  for (const auto& path : search_paths) {
    handle = ::dlopen(path.c_str(), RTLD_NOW);
    if (handle != nullptr) {
      break;
    }
  }

  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();

  if (handle == nullptr) {
    if (engine && s_procs.NotifyDartDeferredLibraryLoadError) {
      s_procs.NotifyDartDeferredLibraryLoadError(
          engine, loading_unit_id,
          "No lib .so found for provided search paths.", true);
    }
    return;
  }

  fml::RefPtr<fml::NativeLibrary> native_lib =
      fml::NativeLibrary::CreateWithHandle(handle, false);
  fml::SymbolMapping data_mapping(native_lib, "kDartSnapshotData");
  fml::SymbolMapping instructions_mapping(native_lib, "kDartSnapshotText");

  if (engine && s_procs.LoadDartDeferredLibrary) {
    s_procs.LoadDartDeferredLibrary(
        engine, loading_unit_id, data_mapping.GetMapping(),
        data_mapping.GetSize(), instructions_mapping.GetMapping(),
        instructions_mapping.GetSize());
  }
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
  if (jAssetManager != nullptr) {
    auto asset_provider =
        std::make_shared<APKAssetProvider>(env, jAssetManager, bundle_path);
    native_instance->SetAssetProvider(std::move(asset_provider));
  }
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
  auto* native_instance = FromJavaFlutterJNI(env, obj);
  if (!native_instance) {
    return;
  }
  auto engine = native_instance->GetEngine();
  if (engine) {
    std::string error_message =
        jError != nullptr ? fml::jni::JavaStringToString(env, jError) : "";
    static FlutterEngineProcTable s_procs = []() {
      FlutterEngineProcTable procs = {};
      procs.struct_size = sizeof(FlutterEngineProcTable);
      FlutterEngineGetProcAddresses(&procs);
      return procs;
    }();
    if (s_procs.NotifyDartDeferredLibraryLoadError) {
      s_procs.NotifyDartDeferredLibraryLoadError(
          engine, static_cast<int64_t>(jLoadingUnitId), error_message.c_str(),
          static_cast<bool>(jTransient));
    }
  }
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

bool FlutterEmbedderNative::RegisterJni(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RegisterJni");
  if (!env) {
    FML_LOG(ERROR)
        << "No JNIEnv provided to FlutterEmbedderNative::RegisterJni";
    return false;
  }

  static const JNINativeMethod flutter_jni_methods[] = {
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

  if (!g_flutter_jni_class) {
    g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
  }
  g_flutter_jni_class->Reset(env, clazz);
  g_jni_shell_holder_field =
      env->GetFieldID(clazz, "nativeShellHolderId", "Ljava/lang/Long;");
  if (!g_jni_shell_holder_field) {
    FML_LOG(ERROR) << "Failed to find nativeShellHolderId field on FlutterJNI.";
    return false;
  }
  g_jni_constructor = env->GetMethodID(clazz, "<init>", "()V");
  if (!g_jni_constructor) {
    FML_LOG(ERROR) << "Failed to find FlutterJNI constructor.";
    return false;
  }

  jclass java_long_class = env->FindClass("java/lang/Long");
  if (!java_long_class) {
    FML_LOG(ERROR) << "Failed to find java/lang/Long class.";
    return false;
  }
  if (!g_java_long_class) {
    g_java_long_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
  }
  g_java_long_class->Reset(env, java_long_class);
  g_long_constructor =
      env->GetStaticMethodID(java_long_class, "valueOf", "(J)Ljava/lang/Long;");
  if (!g_long_constructor) {
    FML_LOG(ERROR) << "Failed to find java/lang/Long.valueOf method.";
    return false;
  }
  g_long_value_method = env->GetMethodID(java_long_class, "longValue", "()J");
  if (!g_long_value_method) {
    FML_LOG(ERROR) << "Failed to find java/lang/Long.longValue method.";
    return false;
  }

  jclass callback_info_class =
      env->FindClass("io/flutter/view/FlutterCallbackInformation");
  if (!callback_info_class) {
    FML_LOG(ERROR) << "Failed to find FlutterCallbackInformation class.";
    return false;
  }
  if (!g_flutter_callback_info_class) {
    g_flutter_callback_info_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
  }
  g_flutter_callback_info_class->Reset(env, callback_info_class);
  g_flutter_callback_info_constructor = env->GetMethodID(
      callback_info_class, "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
  if (!g_flutter_callback_info_constructor) {
    FML_LOG(ERROR) << "Failed to find FlutterCallbackInformation constructor.";
    return false;
  }

  if (!AndroidJvmInvoker::RegisterJni(env, clazz)) {
    FML_LOG(ERROR) << "Failed to RegisterJni for AndroidJvmInvoker.";
    return false;
  }

  return true;
}

}  // namespace android
}  // namespace flutter
