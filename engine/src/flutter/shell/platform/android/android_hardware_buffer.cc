// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_hardware_buffer.h"

#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {
namespace android {

// Function pointer types resolved from libandroid.so via OSLibraryLoader.
typedef int (*AHardwareBuffer_allocate_fn)(const void* desc, void** outBuffer);
typedef void (*AHardwareBuffer_acquire_fn)(void* buffer);
typedef void (*AHardwareBuffer_release_fn)(void* buffer);
typedef void (*AHardwareBuffer_describe_fn)(const void* buffer, void* outDesc);
typedef void* (*AHardwareBuffer_fromHardwareBuffer_fn)(void* env,
                                                       void* hardwareBufferObj);
typedef void* (*AHardwareBuffer_toHardwareBuffer_fn)(void* env,
                                                     void* hardwareBuffer);
typedef int (*AHardwareBuffer_getId_fn)(const void* buffer, uint64_t* outId);
typedef int (*AHardwareBuffer_lock_fn)(void* buffer,
                                       uint64_t usage,
                                       int32_t fence,
                                       const void* rect,
                                       void** outVirtualAddress);
typedef int (*AHardwareBuffer_unlock_fn)(void* buffer, int32_t* fence);
typedef int (*AHardwareBuffer_isSupported_fn)(const void* desc);

size_t AndroidHardwareBufferBytesPerPixel(uint32_t format) {
  TRACE_EVENT0("flutter", "AndroidHardwareBufferBytesPerPixel");
  switch (static_cast<AndroidHardwareBufferFormat>(format)) {
    case AndroidHardwareBufferFormat::kR8G8B8A8Unorm:
    case AndroidHardwareBufferFormat::kR8G8B8X8Unorm:
    case AndroidHardwareBufferFormat::kR10G10B10A2Unorm:
    case AndroidHardwareBufferFormat::kD24UnormS8Uint:
    case AndroidHardwareBufferFormat::kD32Float:
    case AndroidHardwareBufferFormat::kR16G16Uint:
    case AndroidHardwareBufferFormat::kR10G10B10A10Unorm:
      return 4;
    case AndroidHardwareBufferFormat::kR8G8B8Unorm:
      return 3;
    case AndroidHardwareBufferFormat::kR5G6B5Unorm:
    case AndroidHardwareBufferFormat::kD16Unorm:
    case AndroidHardwareBufferFormat::kD24Unorm:
    case AndroidHardwareBufferFormat::kR16Uint:
    case AndroidHardwareBufferFormat::kYCbCrP010:
    case AndroidHardwareBufferFormat::kYCbCrP210:
      return 2;
    case AndroidHardwareBufferFormat::kR16G16B16A16Float:
    case AndroidHardwareBufferFormat::kD32FloatS8Uint:
      return 8;
    case AndroidHardwareBufferFormat::kR8Unorm:
    case AndroidHardwareBufferFormat::kS8Uint:
    case AndroidHardwareBufferFormat::kY8Cb8Cr8420:
    case AndroidHardwareBufferFormat::kBlob:
    default:
      return 1;
  }
}

AndroidHardwareBufferDesc AndroidHardwareBufferDesc::MakeRGBA8(uint32_t width,
                                                               uint32_t height,
                                                               uint64_t usage) {
  TRACE_EVENT0("flutter", "AndroidHardwareBufferDesc::MakeRGBA8");
  AndroidHardwareBufferDesc desc;
  desc.width = width;
  desc.height = height;
  desc.layers = 1;
  desc.format =
      static_cast<uint32_t>(AndroidHardwareBufferFormat::kR8G8B8A8Unorm);
  desc.usage = usage;
  desc.stride = width;
  return desc;
}

// =============================================================================
// DefaultAndroidHardwareBuffer Implementation
// =============================================================================

DefaultAndroidHardwareBuffer::DefaultAndroidHardwareBuffer(
    AndroidHardwareBufferDesc desc,
    void* handle,
    uint64_t id,
    bool owns_handle,
    std::shared_ptr<DefaultAndroidHardwareBufferProvider> provider)
    : desc_(desc),
      handle_(handle),
      id_(id),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBuffer::DefaultAndroidHardwareBuffer");
}

DefaultAndroidHardwareBuffer::~DefaultAndroidHardwareBuffer() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBuffer::~DefaultAndroidHardwareBuffer");
  if (owns_handle_ && handle_) {
    if (provider_) {
      provider_->Release(handle_);
    }
    handle_ = nullptr;
  }
}

const AndroidHardwareBufferDesc& DefaultAndroidHardwareBuffer::GetDescription()
    const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::GetDescription");
  return desc_;
}

void* DefaultAndroidHardwareBuffer::GetHandle() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::GetHandle");
  return handle_;
}

uint64_t DefaultAndroidHardwareBuffer::GetId() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::GetId");
  return id_;
}

bool DefaultAndroidHardwareBuffer::IsValid() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::IsValid");
  return handle_ != nullptr && desc_.IsValid();
}

int DefaultAndroidHardwareBuffer::Lock(uint64_t usage,
                                       int32_t fence,
                                       const AndroidHardwareBufferRect* rect,
                                       void** out_address) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::Lock");
  if (!handle_) {
    return -1;
  }
  if (provider_) {
    return provider_->Lock(handle_, usage, fence, rect, out_address);
  }
  return -1;
}

int DefaultAndroidHardwareBuffer::Unlock(int32_t* fence) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::Unlock");
  if (!handle_) {
    return -1;
  }
  if (provider_) {
    return provider_->Unlock(handle_, fence);
  }
  return -1;
}

void DefaultAndroidHardwareBuffer::Acquire() {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::Acquire");
  if (handle_ && provider_) {
    provider_->Acquire(handle_);
  }
}

void DefaultAndroidHardwareBuffer::Release() {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::Release");
  if (handle_ && provider_) {
    provider_->Release(handle_);
  }
}

FlutterHardwareBufferExternalTexture
DefaultAndroidHardwareBuffer::ToExternalTexture(
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::ToExternalTexture");
  FlutterHardwareBufferExternalTexture ext_texture = {};
  ext_texture.struct_size = sizeof(FlutterHardwareBufferExternalTexture);
  ext_texture.width = desc_.width;
  ext_texture.height = desc_.height;
  ext_texture.format = desc_.format;
  ext_texture.buffer = ToHandle();
  ext_texture.user_data = user_data;
  ext_texture.destruction_callback = destruction_callback;
  return ext_texture;
}

FlutterHardwareBufferHandle DefaultAndroidHardwareBuffer::ToHandle() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBuffer::ToHandle");
  return static_cast<FlutterHardwareBufferHandle>(handle_);
}

// =============================================================================
// DefaultAndroidHardwareBufferProvider Implementation
// =============================================================================

DefaultAndroidHardwareBufferProvider::DefaultAndroidHardwareBufferProvider(
    std::shared_ptr<OSLibraryLoader> library_loader)
    : library_loader_(library_loader
                          ? std::move(library_loader)
                          : FlutterEmbedderNative::GetDefaultLibraryLoader()) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBufferProvider::"
               "DefaultAndroidHardwareBufferProvider");
}

DefaultAndroidHardwareBufferProvider::~DefaultAndroidHardwareBufferProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBufferProvider::"
               "~DefaultAndroidHardwareBufferProvider");
}

void DefaultAndroidHardwareBufferProvider::EnsureLoaded() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::EnsureLoaded");
  std::lock_guard<std::mutex> lock(mutex_);
  if (loaded_) {
    return;
  }
  if (!library_loader_) {
    library_loader_ = FlutterEmbedderNative::GetDefaultLibraryLoader();
  }
  if (!library_loader_) {
    loaded_ = true;
    return;
  }

  libandroid_ = library_loader_->LoadDynamicLibrary("libandroid.so");
  if (libandroid_ && libandroid_->IsValid()) {
    allocate_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_allocate");
    release_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_release");
    describe_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_describe");
    acquire_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_acquire");
    from_hardware_buffer_fn_ =
        libandroid_->ResolveSymbol("AHardwareBuffer_fromHardwareBuffer");
    to_hardware_buffer_fn_ =
        libandroid_->ResolveSymbol("AHardwareBuffer_toHardwareBuffer");
    get_id_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_getId");
    lock_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_lock");
    unlock_fn_ = libandroid_->ResolveSymbol("AHardwareBuffer_unlock");
    is_supported_fn_ =
        libandroid_->ResolveSymbol("AHardwareBuffer_isSupported");

    if (allocate_fn_ && release_fn_ && describe_fn_) {
      is_available_ = true;
    }
  }

  // Also check libjnigraphics if from_hardware_buffer was not found in
  // libandroid
  if (!from_hardware_buffer_fn_) {
    libjnigraphics_ = library_loader_->LoadDynamicLibrary("libjnigraphics.so");
    if (libjnigraphics_ && libjnigraphics_->IsValid()) {
      from_hardware_buffer_fn_ =
          libjnigraphics_->ResolveSymbol("AHardwareBuffer_fromHardwareBuffer");
      to_hardware_buffer_fn_ =
          libjnigraphics_->ResolveSymbol("AHardwareBuffer_toHardwareBuffer");
    }
  }

  loaded_ = true;
}

bool DefaultAndroidHardwareBufferProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::IsAvailable");
  EnsureLoaded();
  return is_available_;
}

bool DefaultAndroidHardwareBufferProvider::IsSupported(
    const AndroidHardwareBufferDesc& desc) const {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::IsSupported");
  EnsureLoaded();
  if (is_supported_fn_) {
    auto fn =
        reinterpret_cast<AHardwareBuffer_isSupported_fn>(is_supported_fn_);
    return fn(&desc) != 0;
  }
  return is_available_ && desc.IsValid();
}

std::unique_ptr<AndroidHardwareBuffer>
DefaultAndroidHardwareBufferProvider::Allocate(
    const AndroidHardwareBufferDesc& desc) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Allocate");
  EnsureLoaded();
  if (!allocate_fn_ || !desc.IsValid()) {
    return nullptr;
  }

  void* native_buffer = nullptr;
  auto allocate = reinterpret_cast<AHardwareBuffer_allocate_fn>(allocate_fn_);
  int result = allocate(&desc, &native_buffer);
  if (result != 0 || !native_buffer) {
    return nullptr;
  }

  AndroidHardwareBufferDesc actual_desc = desc;
  if (describe_fn_) {
    auto describe = reinterpret_cast<AHardwareBuffer_describe_fn>(describe_fn_);
    describe(native_buffer, &actual_desc);
  }

  uint64_t id = 0;
  if (get_id_fn_) {
    auto get_id = reinterpret_cast<AHardwareBuffer_getId_fn>(get_id_fn_);
    get_id(native_buffer, &id);
  }

  return std::make_unique<DefaultAndroidHardwareBuffer>(
      actual_desc, native_buffer, id, /*owns_handle=*/true, shared_from_this());
}

std::unique_ptr<AndroidHardwareBuffer>
DefaultAndroidHardwareBufferProvider::CreateFromNativeHandle(
    void* handle,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBufferProvider::CreateFromNativeHandle");
  EnsureLoaded();
  if (!is_available_ || !handle) {
    return nullptr;
  }

  AndroidHardwareBufferDesc desc = {};
  if (describe_fn_) {
    auto describe = reinterpret_cast<AHardwareBuffer_describe_fn>(describe_fn_);
    describe(handle, &desc);
  }

  uint64_t id = 0;
  if (get_id_fn_) {
    auto get_id = reinterpret_cast<AHardwareBuffer_getId_fn>(get_id_fn_);
    get_id(handle, &id);
  }

  return std::make_unique<DefaultAndroidHardwareBuffer>(
      desc, handle, id, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidHardwareBuffer>
DefaultAndroidHardwareBufferProvider::CreateFromJavaHardwareBuffer(
    void* env,
    void* java_hardware_buffer) {
  TRACE_EVENT0(
      "flutter",
      "DefaultAndroidHardwareBufferProvider::CreateFromJavaHardwareBuffer");
  EnsureLoaded();
  if (!from_hardware_buffer_fn_ || !env || !java_hardware_buffer) {
    return nullptr;
  }

  auto from_hw_buf = reinterpret_cast<AHardwareBuffer_fromHardwareBuffer_fn>(
      from_hardware_buffer_fn_);
  void* native_buffer = from_hw_buf(env, java_hardware_buffer);
  if (!native_buffer) {
    return nullptr;
  }

  // Acquire reference since Java owns the original reference
  Acquire(native_buffer);

  return CreateFromNativeHandle(native_buffer, /*take_ownership=*/true);
}

void* DefaultAndroidHardwareBufferProvider::ToJavaHardwareBuffer(void* env,
                                                                 void* handle) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidHardwareBufferProvider::ToJavaHardwareBuffer");
  EnsureLoaded();
  if (!to_hardware_buffer_fn_ || !env || !handle) {
    return nullptr;
  }
  auto to_hw_buf = reinterpret_cast<AHardwareBuffer_toHardwareBuffer_fn>(
      to_hardware_buffer_fn_);
  return to_hw_buf(env, handle);
}

bool DefaultAndroidHardwareBufferProvider::Describe(
    void* handle,
    AndroidHardwareBufferDesc* out_desc) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Describe");
  EnsureLoaded();
  if (!is_available_ || !describe_fn_ || !handle || !out_desc) {
    return false;
  }
  auto describe = reinterpret_cast<AHardwareBuffer_describe_fn>(describe_fn_);
  describe(handle, out_desc);
  return true;
}

void DefaultAndroidHardwareBufferProvider::Acquire(void* handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Acquire");
  EnsureLoaded();
  if (acquire_fn_ && handle) {
    auto acquire = reinterpret_cast<AHardwareBuffer_acquire_fn>(acquire_fn_);
    acquire(handle);
  }
}

void DefaultAndroidHardwareBufferProvider::Release(void* handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Release");
  EnsureLoaded();
  if (release_fn_ && handle) {
    auto release = reinterpret_cast<AHardwareBuffer_release_fn>(release_fn_);
    release(handle);
  }
}

int DefaultAndroidHardwareBufferProvider::Lock(
    void* handle,
    uint64_t usage,
    int32_t fence,
    const AndroidHardwareBufferRect* rect,
    void** out_address) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Lock");
  EnsureLoaded();
  if (!lock_fn_ || !handle || !out_address) {
    return -1;
  }
  auto lock = reinterpret_cast<AHardwareBuffer_lock_fn>(lock_fn_);
  return lock(handle, usage, fence, rect, out_address);
}

int DefaultAndroidHardwareBufferProvider::Unlock(void* handle, int32_t* fence) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::Unlock");
  EnsureLoaded();
  if (!unlock_fn_ || !handle) {
    return -1;
  }
  auto unlock = reinterpret_cast<AHardwareBuffer_unlock_fn>(unlock_fn_);
  return unlock(handle, fence);
}

uint64_t DefaultAndroidHardwareBufferProvider::GetId(void* handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidHardwareBufferProvider::GetId");
  EnsureLoaded();
  if (!get_id_fn_ || !handle) {
    return 0;
  }
  uint64_t id = 0;
  auto get_id = reinterpret_cast<AHardwareBuffer_getId_fn>(get_id_fn_);
  get_id(handle, &id);
  return id;
}

// =============================================================================
// InMemoryAndroidHardwareBuffer Implementation
// =============================================================================

InMemoryAndroidHardwareBuffer::InMemoryAndroidHardwareBuffer(
    AndroidHardwareBufferDesc desc,
    uint64_t id,
    void* handle,
    bool owns_handle,
    std::shared_ptr<InMemoryAndroidHardwareBufferProvider> provider)
    : desc_(desc),
      id_(id),
      handle_(handle),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBuffer::"
               "InMemoryAndroidHardwareBuffer");
  if (desc_.stride == 0) {
    desc_.stride = desc_.width;
  }
  size_t bpp = AndroidHardwareBufferBytesPerPixel(desc_.format);
  size_t total_size = static_cast<size_t>(desc_.stride) * desc_.height * bpp;
  if (total_size == 0) {
    total_size = 64;
  }
  backing_data_.resize(total_size, 0);
}

InMemoryAndroidHardwareBuffer::~InMemoryAndroidHardwareBuffer() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBuffer::"
               "~InMemoryAndroidHardwareBuffer");
  if (owns_handle_ && provider_) {
    provider_->Release(handle_ ? handle_ : this);
  }
}

const AndroidHardwareBufferDesc& InMemoryAndroidHardwareBuffer::GetDescription()
    const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetDescription");
  return desc_;
}

void* InMemoryAndroidHardwareBuffer::GetHandle() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetHandle");
  return handle_ ? handle_ : const_cast<InMemoryAndroidHardwareBuffer*>(this);
}

uint64_t InMemoryAndroidHardwareBuffer::GetId() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetId");
  return id_;
}

bool InMemoryAndroidHardwareBuffer::IsValid() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::IsValid");
  return desc_.IsValid();
}

int InMemoryAndroidHardwareBuffer::Lock(uint64_t usage,
                                        int32_t fence,
                                        const AndroidHardwareBufferRect* rect,
                                        void** out_address) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::Lock");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!out_address) {
    return -1;
  }
  lock_count_++;
  *out_address = backing_data_.data();
  return 0;
}

int InMemoryAndroidHardwareBuffer::Unlock(int32_t* fence) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::Unlock");
  std::lock_guard<std::mutex> lock(mutex_);
  if (lock_count_ > 0) {
    lock_count_--;
  }
  if (fence) {
    *fence = -1;
  }
  return 0;
}

void InMemoryAndroidHardwareBuffer::Acquire() {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  ref_count_++;
}

void InMemoryAndroidHardwareBuffer::Release() {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::Release");
  std::lock_guard<std::mutex> lock(mutex_);
  if (ref_count_ > 0) {
    ref_count_--;
  }
}

FlutterHardwareBufferExternalTexture
InMemoryAndroidHardwareBuffer::ToExternalTexture(
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::ToExternalTexture");
  FlutterHardwareBufferExternalTexture ext_texture = {};
  ext_texture.struct_size = sizeof(FlutterHardwareBufferExternalTexture);
  ext_texture.width = desc_.width;
  ext_texture.height = desc_.height;
  ext_texture.format = desc_.format;
  ext_texture.buffer = ToHandle();
  ext_texture.user_data = user_data;
  ext_texture.destruction_callback = destruction_callback;
  return ext_texture;
}

FlutterHardwareBufferHandle InMemoryAndroidHardwareBuffer::ToHandle() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::ToHandle");
  return static_cast<FlutterHardwareBufferHandle>(GetHandle());
}

uint8_t* InMemoryAndroidHardwareBuffer::GetBackingData() {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetBackingData");
  std::lock_guard<std::mutex> lock(mutex_);
  return backing_data_.data();
}

size_t InMemoryAndroidHardwareBuffer::GetBackingDataSize() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetBackingDataSize");
  std::lock_guard<std::mutex> lock(mutex_);
  return backing_data_.size();
}

int32_t InMemoryAndroidHardwareBuffer::GetLockCount() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetLockCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return lock_count_;
}

int32_t InMemoryAndroidHardwareBuffer::GetRefCount() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBuffer::GetRefCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return ref_count_;
}

// =============================================================================
// InMemoryAndroidHardwareBufferProvider Implementation
// =============================================================================

InMemoryAndroidHardwareBufferProvider::InMemoryAndroidHardwareBufferProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::"
               "InMemoryAndroidHardwareBufferProvider");
}

InMemoryAndroidHardwareBufferProvider::
    ~InMemoryAndroidHardwareBufferProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::"
               "~InMemoryAndroidHardwareBufferProvider");
}

bool InMemoryAndroidHardwareBufferProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::IsAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  return is_available_;
}

bool InMemoryAndroidHardwareBufferProvider::IsSupported(
    const AndroidHardwareBufferDesc& desc) const {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::IsSupported");
  std::lock_guard<std::mutex> lock(mutex_);
  return is_available_ && !allocation_failure_ && desc.IsValid();
}

std::unique_ptr<AndroidHardwareBuffer>
InMemoryAndroidHardwareBufferProvider::Allocate(
    const AndroidHardwareBufferDesc& desc) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Allocate");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || allocation_failure_ || !desc.IsValid()) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  allocation_count_++;

  auto buffer = std::make_unique<InMemoryAndroidHardwareBuffer>(
      desc, id, nullptr, true, shared_from_this());
  void* handle = buffer->GetHandle();

  MockEntry entry;
  entry.desc = desc;
  entry.id = id;
  entry.ref_count = 1;
  mock_entries_[handle] = std::move(entry);

  return buffer;
}

std::unique_ptr<AndroidHardwareBuffer>
InMemoryAndroidHardwareBufferProvider::CreateFromNativeHandle(
    void* handle,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::CreateFromNativeHandle");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle) {
    return nullptr;
  }

  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    if (!take_ownership) {
      it->second.ref_count++;
    }
    return std::make_unique<InMemoryAndroidHardwareBuffer>(
        it->second.desc, it->second.id, handle, take_ownership,
        shared_from_this());
  }

  // If handle not recognized, create a default mock entry
  AndroidHardwareBufferDesc desc =
      AndroidHardwareBufferDesc::MakeRGBA8(100, 100);
  uint64_t id = next_id_++;
  MockEntry entry;
  entry.desc = desc;
  entry.id = id;
  entry.ref_count = 1;
  mock_entries_[handle] = std::move(entry);

  return std::make_unique<InMemoryAndroidHardwareBuffer>(
      desc, id, handle, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidHardwareBuffer>
InMemoryAndroidHardwareBufferProvider::CreateFromJavaHardwareBuffer(
    void* env,
    void* java_hardware_buffer) {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidHardwareBufferProvider::CreateFromJavaHardwareBuffer");
  if (!env || !java_hardware_buffer) {
    return nullptr;
  }
  return CreateFromNativeHandle(java_hardware_buffer, /*take_ownership=*/false);
}

void* InMemoryAndroidHardwareBufferProvider::ToJavaHardwareBuffer(
    void* env,
    void* handle) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::ToJavaHardwareBuffer");
  if (!env || !handle) {
    return nullptr;
  }
  return handle;
}

bool InMemoryAndroidHardwareBufferProvider::Describe(
    void* handle,
    AndroidHardwareBufferDesc* out_desc) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Describe");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle || !out_desc) {
    return false;
  }
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    *out_desc = it->second.desc;
    return true;
  }
  *out_desc = AndroidHardwareBufferDesc::MakeRGBA8(100, 100);
  return true;
}

void InMemoryAndroidHardwareBufferProvider::Acquire(void* handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    it->second.ref_count++;
  }
}

void InMemoryAndroidHardwareBufferProvider::Release(void* handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Release");
  std::lock_guard<std::mutex> lock(mutex_);
  release_count_++;
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    it->second.ref_count--;
    if (it->second.ref_count <= 0) {
      mock_entries_.erase(it);
    }
  }
}

int InMemoryAndroidHardwareBufferProvider::Lock(
    void* handle,
    uint64_t usage,
    int32_t fence,
    const AndroidHardwareBufferRect* rect,
    void** out_address) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Lock");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle || !out_address) {
    return -1;
  }
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    if (it->second.data.empty()) {
      size_t bpp = AndroidHardwareBufferBytesPerPixel(it->second.desc.format);
      size_t size = static_cast<size_t>(it->second.desc.stride) *
                    it->second.desc.height * bpp;
      if (size == 0) {
        size = 64;
      }
      it->second.data.resize(size, 0);
    }
    it->second.lock_count++;
    *out_address = it->second.data.data();
    return 0;
  }
  return -1;
}

int InMemoryAndroidHardwareBufferProvider::Unlock(void* handle,
                                                  int32_t* fence) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Unlock");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle) {
    return -1;
  }
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    if (it->second.lock_count > 0) {
      it->second.lock_count--;
    }
    if (fence) {
      *fence = -1;
    }
    return 0;
  }
  return -1;
}

uint64_t InMemoryAndroidHardwareBufferProvider::GetId(void* handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::GetId");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = mock_entries_.find(handle);
  if (it != mock_entries_.end()) {
    return it->second.id;
  }
  return 0;
}

void InMemoryAndroidHardwareBufferProvider::SetAvailable(bool available) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::SetAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  is_available_ = available;
}

void InMemoryAndroidHardwareBufferProvider::SetAllocationFailure(bool fail) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::SetAllocationFailure");
  std::lock_guard<std::mutex> lock(mutex_);
  allocation_failure_ = fail;
}

size_t InMemoryAndroidHardwareBufferProvider::GetAllocationCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::GetAllocationCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return allocation_count_;
}

size_t InMemoryAndroidHardwareBufferProvider::GetReleaseCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::GetReleaseCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return release_count_;
}

size_t InMemoryAndroidHardwareBufferProvider::GetActiveBufferCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::GetActiveBufferCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return mock_entries_.size();
}

void InMemoryAndroidHardwareBufferProvider::RegisterMockBuffer(
    void* handle,
    const AndroidHardwareBufferDesc& desc,
    uint64_t id) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidHardwareBufferProvider::RegisterMockBuffer");
  std::lock_guard<std::mutex> lock(mutex_);
  MockEntry entry;
  entry.desc = desc;
  entry.id = id;
  entry.ref_count = 1;
  mock_entries_[handle] = std::move(entry);
}

void InMemoryAndroidHardwareBufferProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryAndroidHardwareBufferProvider::Clear");
  std::lock_guard<std::mutex> lock(mutex_);
  mock_entries_.clear();
  allocation_count_ = 0;
  release_count_ = 0;
}

}  // namespace android
}  // namespace flutter
