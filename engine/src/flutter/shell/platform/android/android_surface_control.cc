// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_control.h"

#include <chrono>
#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {
namespace android {

// Function pointer signatures matching Android NDK ASurfaceControl &
// ASurfaceTransaction APIs.
typedef void* (*ASurfaceControl_createFromWindow_fn)(void* parent,
                                                     const char* debug_name);
typedef void* (*ASurfaceControl_create_fn)(void* parent,
                                           const char* debug_name);
typedef void (*ASurfaceControl_acquire_fn)(void* surface_control);
typedef void (*ASurfaceControl_release_fn)(void* surface_control);
typedef void* (*ASurfaceTransaction_create_fn)();
typedef void (*ASurfaceTransaction_delete_fn)(void* transaction);
typedef void (*ASurfaceTransaction_apply_fn)(void* transaction);
typedef void (*ASurfaceTransaction_reparent_fn)(void* transaction,
                                                void* surface_control,
                                                void* new_parent);
typedef void (*ASurfaceTransaction_setVisibility_fn)(void* transaction,
                                                     void* surface_control,
                                                     int8_t visibility);
typedef void (*ASurfaceTransaction_setZOrder_fn)(void* transaction,
                                                 void* surface_control,
                                                 int32_t z_order);
typedef void (*ASurfaceTransaction_setBuffer_fn)(void* transaction,
                                                 void* surface_control,
                                                 void* buffer,
                                                 int acquire_fence_fd);
typedef void (*ASurfaceTransaction_setGeometry_fn)(void* transaction,
                                                   void* surface_control,
                                                   const void* source,
                                                   const void* destination,
                                                   int32_t transform);
typedef void (*ASurfaceTransaction_setDamageRegion_fn)(void* transaction,
                                                       void* surface_control,
                                                       const void* rects,
                                                       uint32_t count);
typedef void (*ASurfaceTransaction_setBufferAlpha_fn)(void* transaction,
                                                      void* surface_control,
                                                      float alpha);
typedef void (*ASurfaceTransaction_setColor_fn)(void* transaction,
                                                void* surface_control,
                                                float r,
                                                float g,
                                                float b,
                                                float alpha,
                                                int32_t dataspace);
typedef void (*ASurfaceTransaction_OnComplete_fn)(void* context, void* stats);
typedef void (*ASurfaceTransaction_setOnComplete_fn)(
    void* transaction,
    void* context,
    ASurfaceTransaction_OnComplete_fn func);
typedef int (*ASurfaceTransactionStats_getPreviousReleaseFenceFd_fn)(
    void* stats);

// =============================================================================
// DefaultAndroidSurfaceControl Implementation
// =============================================================================

DefaultAndroidSurfaceControl::DefaultAndroidSurfaceControl(
    void* handle,
    std::string debug_name,
    uint64_t id,
    void* parent_handle,
    uint64_t parent_id,
    bool owns_handle,
    std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider)
    : handle_(handle),
      debug_name_(std::move(debug_name)),
      id_(id),
      parent_handle_(parent_handle),
      parent_id_(parent_id),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControl::DefaultAndroidSurfaceControl");
}

DefaultAndroidSurfaceControl::~DefaultAndroidSurfaceControl() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControl::~DefaultAndroidSurfaceControl");
  if (owns_handle_ && handle_ && provider_) {
    provider_->Release(handle_);
    handle_ = nullptr;
  }
}

void* DefaultAndroidSurfaceControl::GetHandle() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::GetHandle");
  return handle_;
}

const std::string& DefaultAndroidSurfaceControl::GetDebugName() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::GetDebugName");
  return debug_name_;
}

uint64_t DefaultAndroidSurfaceControl::GetId() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::GetId");
  return id_;
}

bool DefaultAndroidSurfaceControl::IsValid() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::IsValid");
  return handle_ != nullptr;
}

void DefaultAndroidSurfaceControl::Acquire() {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::Acquire");
  if (handle_ && provider_) {
    provider_->Acquire(handle_);
  }
}

void DefaultAndroidSurfaceControl::Release() {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::Release");
  if (handle_ && provider_) {
    provider_->Release(handle_);
  }
}

bool DefaultAndroidSurfaceControl::RemoveFromParent() {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::RemoveFromParent");
  if (!handle_ || !provider_) {
    return false;
  }
  auto transaction = provider_->CreateTransaction();
  if (!transaction) {
    return false;
  }
  if (!transaction->Reparent(this, nullptr)) {
    return false;
  }
  return transaction->Apply();
}

void* DefaultAndroidSurfaceControl::GetParentHandle() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::GetParentHandle");
  return parent_handle_;
}

uint64_t DefaultAndroidSurfaceControl::GetParentId() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControl::GetParentId");
  return parent_id_;
}

// =============================================================================
// DefaultAndroidSurfaceTransaction Implementation
// =============================================================================

DefaultAndroidSurfaceTransaction::DefaultAndroidSurfaceTransaction(
    void* handle,
    bool owns_handle,
    std::shared_ptr<DefaultAndroidSurfaceControlProvider> provider)
    : handle_(handle),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0(
      "flutter",
      "DefaultAndroidSurfaceTransaction::DefaultAndroidSurfaceTransaction");
}

DefaultAndroidSurfaceTransaction::~DefaultAndroidSurfaceTransaction() {
  TRACE_EVENT0(
      "flutter",
      "DefaultAndroidSurfaceTransaction::~DefaultAndroidSurfaceTransaction");
  if (owns_handle_ && handle_ && provider_) {
    provider_->DeleteTransaction(handle_);
    handle_ = nullptr;
  }
}

void* DefaultAndroidSurfaceTransaction::GetHandle() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::GetHandle");
  return handle_;
}

bool DefaultAndroidSurfaceTransaction::IsValid() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::IsValid");
  return handle_ != nullptr;
}

bool DefaultAndroidSurfaceTransaction::SetVisibility(
    AndroidSurfaceControl* surface_control,
    AndroidSurfaceControlVisibility visibility) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetVisibility");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetVisibility(
      handle_, surface_control->GetHandle(),
      static_cast<int8_t>(
          visibility == AndroidSurfaceControlVisibility::kShow ? 1 : 0));
}

bool DefaultAndroidSurfaceTransaction::SetZOrder(
    AndroidSurfaceControl* surface_control,
    int32_t z_order) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetZOrder");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetZOrder(handle_, surface_control->GetHandle(), z_order);
}

bool DefaultAndroidSurfaceTransaction::SetBuffer(
    AndroidSurfaceControl* surface_control,
    void* hardware_buffer,
    int acquire_fence_fd) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetBuffer");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetBuffer(handle_, surface_control->GetHandle(),
                              hardware_buffer, acquire_fence_fd);
}

bool DefaultAndroidSurfaceTransaction::SetGeometry(
    AndroidSurfaceControl* surface_control,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    AndroidSurfaceControlTransform transform) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetGeometry");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetGeometry(handle_, surface_control->GetHandle(), &source,
                                &destination, static_cast<int32_t>(transform));
}

bool DefaultAndroidSurfaceTransaction::SetDamageRegion(
    AndroidSurfaceControl* surface_control,
    const std::vector<AndroidSurfaceControlRect>& rects) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetDamageRegion");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetDamageRegion(handle_, surface_control->GetHandle(),
                                    rects.empty() ? nullptr : rects.data(),
                                    static_cast<uint32_t>(rects.size()));
}

bool DefaultAndroidSurfaceTransaction::SetBufferAlpha(
    AndroidSurfaceControl* surface_control,
    float alpha) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetBufferAlpha");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetBufferAlpha(handle_, surface_control->GetHandle(),
                                   alpha);
}

bool DefaultAndroidSurfaceTransaction::SetColor(
    AndroidSurfaceControl* surface_control,
    float r,
    float g,
    float b,
    float alpha) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetColor");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetColor(handle_, surface_control->GetHandle(), r, g, b,
                             alpha);
}

bool DefaultAndroidSurfaceTransaction::Reparent(
    AndroidSurfaceControl* surface_control,
    AndroidSurfaceControl* new_parent) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::Reparent");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  void* parent_handle = new_parent ? new_parent->GetHandle() : nullptr;
  return provider_->Reparent(handle_, surface_control->GetHandle(),
                             parent_handle);
}

bool DefaultAndroidSurfaceTransaction::SetOnComplete(
    OnCompleteCallback callback) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::SetOnComplete");
  if (!handle_ || !provider_) {
    return false;
  }
  on_complete_callback_ = std::move(callback);
  return provider_->SetOnComplete(handle_, on_complete_callback_);
}

bool DefaultAndroidSurfaceTransaction::Apply() {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceTransaction::Apply");
  if (!handle_ || !provider_) {
    return false;
  }
  return provider_->ApplyTransaction(handle_);
}

// =============================================================================
// DefaultAndroidSurfaceControlProvider Implementation
// =============================================================================

DefaultAndroidSurfaceControlProvider::DefaultAndroidSurfaceControlProvider(
    std::shared_ptr<OSLibraryLoader> library_loader)
    : library_loader_(std::move(library_loader)) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::"
               "DefaultAndroidSurfaceControlProvider");
}

DefaultAndroidSurfaceControlProvider::~DefaultAndroidSurfaceControlProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::"
               "~DefaultAndroidSurfaceControlProvider");
}

void DefaultAndroidSurfaceControlProvider::EnsureLoaded() const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (loaded_) {
    return;
  }
  loaded_ = true;

  if (!library_loader_) {
    library_loader_ = FlutterEmbedderNative::GetDefaultLibraryLoader();
    if (!library_loader_) {
      library_loader_ = std::make_shared<DefaultOSLibraryLoader>();
    }
  }

  libandroid_ = library_loader_->LoadDynamicLibrary("libandroid.so");
  if (!libandroid_ || !libandroid_->IsValid()) {
    is_available_ = false;
    return;
  }

  create_from_window_fn_ =
      libandroid_->ResolveSymbol("ASurfaceControl_createFromWindow");
  create_fn_ = libandroid_->ResolveSymbol("ASurfaceControl_create");
  acquire_fn_ = libandroid_->ResolveSymbol("ASurfaceControl_acquire");
  release_fn_ = libandroid_->ResolveSymbol("ASurfaceControl_release");
  transaction_create_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_create");
  transaction_delete_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_delete");
  transaction_apply_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_apply");
  transaction_reparent_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_reparent");
  transaction_set_visibility_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setVisibility");
  transaction_set_z_order_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setZOrder");
  transaction_set_buffer_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setBuffer");
  transaction_set_geometry_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setGeometry");
  transaction_set_damage_region_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setDamageRegion");
  transaction_set_buffer_alpha_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setBufferAlpha");
  transaction_set_color_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setColor");
  transaction_set_on_complete_fn_ =
      libandroid_->ResolveSymbol("ASurfaceTransaction_setOnComplete");
  stats_get_release_fence_fn_ = libandroid_->ResolveSymbol(
      "ASurfaceTransactionStats_getPreviousReleaseFenceFd");

  is_available_ =
      (create_from_window_fn_ != nullptr && release_fn_ != nullptr &&
       transaction_create_fn_ != nullptr && transaction_delete_fn_ != nullptr &&
       transaction_apply_fn_ != nullptr);
}

bool DefaultAndroidSurfaceControlProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::IsAvailable");
  EnsureLoaded();
  return is_available_;
}

std::unique_ptr<AndroidSurfaceControl>
DefaultAndroidSurfaceControlProvider::CreateFromWindow(
    void* window,
    const std::string& debug_name) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::CreateFromWindow");
  EnsureLoaded();
  if (!is_available_ || !create_from_window_fn_ || !window) {
    return nullptr;
  }

  auto create_func = reinterpret_cast<ASurfaceControl_createFromWindow_fn>(
      create_from_window_fn_);
  void* handle = create_func(window, debug_name.c_str());
  if (!handle) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  return std::make_unique<DefaultAndroidSurfaceControl>(
      handle, debug_name, id, nullptr, 0, true, shared_from_this());
}

std::unique_ptr<AndroidSurfaceControl>
DefaultAndroidSurfaceControlProvider::Create(AndroidSurfaceControl* parent,
                                             const std::string& debug_name) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::Create");
  EnsureLoaded();
  if (!is_available_ || !create_fn_ || !parent || !parent->GetHandle()) {
    return nullptr;
  }

  auto create_func = reinterpret_cast<ASurfaceControl_create_fn>(create_fn_);
  void* handle = create_func(parent->GetHandle(), debug_name.c_str());
  if (!handle) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  return std::make_unique<DefaultAndroidSurfaceControl>(
      handle, debug_name, id, parent->GetHandle(), parent->GetId(), true,
      shared_from_this());
}

std::unique_ptr<AndroidSurfaceControl>
DefaultAndroidSurfaceControlProvider::CreateFromNativeHandle(
    void* handle,
    const std::string& debug_name,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::CreateFromNativeHandle");
  EnsureLoaded();
  if (!handle) {
    return nullptr;
  }
  uint64_t id = next_id_++;
  return std::make_unique<DefaultAndroidSurfaceControl>(
      handle, debug_name, id, nullptr, 0, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidSurfaceTransaction>
DefaultAndroidSurfaceControlProvider::CreateTransaction() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::CreateTransaction");
  EnsureLoaded();
  if (!is_available_ || !transaction_create_fn_) {
    return nullptr;
  }

  auto create_func =
      reinterpret_cast<ASurfaceTransaction_create_fn>(transaction_create_fn_);
  void* handle = create_func();
  if (!handle) {
    return nullptr;
  }

  return std::make_unique<DefaultAndroidSurfaceTransaction>(handle, true,
                                                            shared_from_this());
}

std::unique_ptr<AndroidSurfaceTransaction>
DefaultAndroidSurfaceControlProvider::CreateTransactionFromNativeHandle(
    void* handle,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::"
               "CreateTransactionFromNativeHandle");
  EnsureLoaded();
  if (!handle) {
    return nullptr;
  }
  return std::make_unique<DefaultAndroidSurfaceTransaction>(
      handle, take_ownership, shared_from_this());
}

void DefaultAndroidSurfaceControlProvider::Acquire(void* handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::Acquire");
  EnsureLoaded();
  if (acquire_fn_ && handle) {
    auto func = reinterpret_cast<ASurfaceControl_acquire_fn>(acquire_fn_);
    func(handle);
  }
}

void DefaultAndroidSurfaceControlProvider::Release(void* handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::Release");
  EnsureLoaded();
  if (release_fn_ && handle) {
    auto func = reinterpret_cast<ASurfaceControl_release_fn>(release_fn_);
    func(handle);
  }
}

void DefaultAndroidSurfaceControlProvider::DeleteTransaction(
    void* transaction_handle) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::DeleteTransaction");
  EnsureLoaded();
  if (transaction_delete_fn_ && transaction_handle) {
    auto func =
        reinterpret_cast<ASurfaceTransaction_delete_fn>(transaction_delete_fn_);
    func(transaction_handle);
  }
}

bool DefaultAndroidSurfaceControlProvider::ApplyTransaction(
    void* transaction_handle) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::ApplyTransaction");
  EnsureLoaded();
  if (!transaction_apply_fn_ || !transaction_handle) {
    return false;
  }
  auto func =
      reinterpret_cast<ASurfaceTransaction_apply_fn>(transaction_apply_fn_);
  func(transaction_handle);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::Reparent(
    void* transaction_handle,
    void* surface_control_handle,
    void* new_parent_handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::Reparent");
  EnsureLoaded();
  if (!transaction_reparent_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_reparent_fn>(
      transaction_reparent_fn_);
  func(transaction_handle, surface_control_handle, new_parent_handle);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetVisibility(
    void* transaction_handle,
    void* surface_control_handle,
    int8_t visibility) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::SetVisibility");
  EnsureLoaded();
  if (!transaction_set_visibility_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setVisibility_fn>(
      transaction_set_visibility_fn_);
  func(transaction_handle, surface_control_handle, visibility);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetZOrder(
    void* transaction_handle,
    void* surface_control_handle,
    int32_t z_order) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::SetZOrder");
  EnsureLoaded();
  if (!transaction_set_z_order_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setZOrder_fn>(
      transaction_set_z_order_fn_);
  func(transaction_handle, surface_control_handle, z_order);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetBuffer(
    void* transaction_handle,
    void* surface_control_handle,
    void* hardware_buffer,
    int acquire_fence_fd) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::SetBuffer");
  EnsureLoaded();
  if (!transaction_set_buffer_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setBuffer_fn>(
      transaction_set_buffer_fn_);
  func(transaction_handle, surface_control_handle, hardware_buffer,
       acquire_fence_fd);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetGeometry(
    void* transaction_handle,
    void* surface_control_handle,
    const AndroidSurfaceControlRect* source,
    const AndroidSurfaceControlRect* destination,
    int32_t transform) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::SetGeometry");
  EnsureLoaded();
  if (!transaction_set_geometry_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setGeometry_fn>(
      transaction_set_geometry_fn_);
  func(transaction_handle, surface_control_handle, source, destination,
       transform);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetDamageRegion(
    void* transaction_handle,
    void* surface_control_handle,
    const AndroidSurfaceControlRect* rects,
    uint32_t count) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::SetDamageRegion");
  EnsureLoaded();
  if (!transaction_set_damage_region_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setDamageRegion_fn>(
      transaction_set_damage_region_fn_);
  func(transaction_handle, surface_control_handle, rects, count);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetBufferAlpha(
    void* transaction_handle,
    void* surface_control_handle,
    float alpha) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::SetBufferAlpha");
  EnsureLoaded();
  if (!transaction_set_buffer_alpha_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setBufferAlpha_fn>(
      transaction_set_buffer_alpha_fn_);
  func(transaction_handle, surface_control_handle, alpha);
  return true;
}

bool DefaultAndroidSurfaceControlProvider::SetColor(
    void* transaction_handle,
    void* surface_control_handle,
    float r,
    float g,
    float b,
    float alpha) {
  TRACE_EVENT0("flutter", "DefaultAndroidSurfaceControlProvider::SetColor");
  EnsureLoaded();
  if (!transaction_set_color_fn_ || !transaction_handle ||
      !surface_control_handle) {
    return false;
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setColor_fn>(
      transaction_set_color_fn_);
  func(transaction_handle, surface_control_handle, r, g, b, alpha, 0);
  return true;
}

struct SurfaceTransactionCallbackWrapper {
  std::function<void(const AndroidSurfaceControlStats&)> callback;
  ASurfaceTransactionStats_getPreviousReleaseFenceFd_fn get_fence_fn = nullptr;
};

static void OnSurfaceTransactionComplete(void* context, void* stats) {
  auto* wrapper = static_cast<SurfaceTransactionCallbackWrapper*>(context);
  if (!wrapper) {
    return;
  }
  AndroidSurfaceControlStats result;
  if (wrapper->get_fence_fn && stats) {
    result.previous_release_fence_fd = wrapper->get_fence_fn(stats);
  }
  auto now = std::chrono::steady_clock::now().time_since_epoch();
  result.present_time_nanos =
      std::chrono::duration_cast<std::chrono::nanoseconds>(now).count();
  if (wrapper->callback) {
    wrapper->callback(result);
  }
  delete wrapper;
}

bool DefaultAndroidSurfaceControlProvider::SetOnComplete(
    void* transaction_handle,
    std::function<void(const AndroidSurfaceControlStats&)> callback) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidSurfaceControlProvider::SetOnComplete");
  EnsureLoaded();
  if (!transaction_set_on_complete_fn_ || !transaction_handle) {
    return false;
  }
  auto* wrapper = new SurfaceTransactionCallbackWrapper();
  wrapper->callback = std::move(callback);
  if (stats_get_release_fence_fn_) {
    wrapper->get_fence_fn =
        reinterpret_cast<ASurfaceTransactionStats_getPreviousReleaseFenceFd_fn>(
            stats_get_release_fence_fn_);
  }
  auto func = reinterpret_cast<ASurfaceTransaction_setOnComplete_fn>(
      transaction_set_on_complete_fn_);
  func(transaction_handle, wrapper, &OnSurfaceTransactionComplete);
  return true;
}

// =============================================================================
// InMemoryAndroidSurfaceControl Implementation
// =============================================================================

InMemoryAndroidSurfaceControl::InMemoryAndroidSurfaceControl(
    uint64_t id,
    std::string debug_name,
    void* handle,
    void* parent_handle,
    uint64_t parent_id,
    bool owns_handle,
    std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider)
    : id_(id),
      debug_name_(std::move(debug_name)),
      handle_(handle),
      parent_handle_(parent_handle),
      parent_id_(parent_id),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControl::InMemoryAndroidSurfaceControl");
}

InMemoryAndroidSurfaceControl::~InMemoryAndroidSurfaceControl() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControl::~InMemoryAndroidSurfaceControl");
  if (owns_handle_ && handle_ && provider_) {
    provider_->Release(handle_);
    handle_ = nullptr;
  }
}

void* InMemoryAndroidSurfaceControl::GetHandle() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::GetHandle");
  return handle_;
}

const std::string& InMemoryAndroidSurfaceControl::GetDebugName() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::GetDebugName");
  return debug_name_;
}

uint64_t InMemoryAndroidSurfaceControl::GetId() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::GetId");
  return id_;
}

bool InMemoryAndroidSurfaceControl::IsValid() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::IsValid");
  return handle_ != nullptr;
}

void InMemoryAndroidSurfaceControl::Acquire() {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::Acquire");
  if (handle_ && provider_) {
    provider_->Acquire(handle_);
  }
}

void InMemoryAndroidSurfaceControl::Release() {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::Release");
  if (handle_ && provider_) {
    provider_->Release(handle_);
  }
}

bool InMemoryAndroidSurfaceControl::RemoveFromParent() {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::RemoveFromParent");
  if (!handle_ || !provider_) {
    return false;
  }
  auto transaction = provider_->CreateTransaction();
  if (!transaction) {
    return false;
  }
  if (!transaction->Reparent(this, nullptr)) {
    return false;
  }
  bool applied = transaction->Apply();
  if (applied) {
    parent_handle_ = nullptr;
    parent_id_ = 0;
  }
  return applied;
}

void* InMemoryAndroidSurfaceControl::GetParentHandle() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::GetParentHandle");
  if (provider_) {
    auto state = provider_->GetSurfaceState(id_);
    if (state) {
      return state->parent_handle;
    }
  }
  return parent_handle_;
}

uint64_t InMemoryAndroidSurfaceControl::GetParentId() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControl::GetParentId");
  if (provider_) {
    auto state = provider_->GetSurfaceState(id_);
    if (state) {
      return state->parent_id;
    }
  }
  return parent_id_;
}

// =============================================================================
// InMemoryAndroidSurfaceTransaction Implementation
// =============================================================================

InMemoryAndroidSurfaceTransaction::InMemoryAndroidSurfaceTransaction(
    void* handle,
    bool owns_handle,
    std::shared_ptr<InMemoryAndroidSurfaceControlProvider> provider)
    : handle_(handle),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidSurfaceTransaction::InMemoryAndroidSurfaceTransaction");
}

InMemoryAndroidSurfaceTransaction::~InMemoryAndroidSurfaceTransaction() {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidSurfaceTransaction::~InMemoryAndroidSurfaceTransaction");
  if (owns_handle_ && handle_ && provider_) {
    provider_->DeleteTransaction(handle_);
    handle_ = nullptr;
  }
}

void* InMemoryAndroidSurfaceTransaction::GetHandle() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::GetHandle");
  return handle_;
}

bool InMemoryAndroidSurfaceTransaction::IsValid() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::IsValid");
  return handle_ != nullptr;
}

bool InMemoryAndroidSurfaceTransaction::SetVisibility(
    AndroidSurfaceControl* surface_control,
    AndroidSurfaceControlVisibility visibility) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetVisibility");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetVisibility(
      handle_, surface_control->GetHandle(),
      static_cast<int8_t>(
          visibility == AndroidSurfaceControlVisibility::kShow ? 1 : 0));
}

bool InMemoryAndroidSurfaceTransaction::SetZOrder(
    AndroidSurfaceControl* surface_control,
    int32_t z_order) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetZOrder");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetZOrder(handle_, surface_control->GetHandle(), z_order);
}

bool InMemoryAndroidSurfaceTransaction::SetBuffer(
    AndroidSurfaceControl* surface_control,
    void* hardware_buffer,
    int acquire_fence_fd) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetBuffer");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetBuffer(handle_, surface_control->GetHandle(),
                              hardware_buffer, acquire_fence_fd);
}

bool InMemoryAndroidSurfaceTransaction::SetGeometry(
    AndroidSurfaceControl* surface_control,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    AndroidSurfaceControlTransform transform) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetGeometry");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetGeometry(handle_, surface_control->GetHandle(), &source,
                                &destination, static_cast<int32_t>(transform));
}

bool InMemoryAndroidSurfaceTransaction::SetDamageRegion(
    AndroidSurfaceControl* surface_control,
    const std::vector<AndroidSurfaceControlRect>& rects) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetDamageRegion");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetDamageRegion(handle_, surface_control->GetHandle(),
                                    rects.empty() ? nullptr : rects.data(),
                                    static_cast<uint32_t>(rects.size()));
}

bool InMemoryAndroidSurfaceTransaction::SetBufferAlpha(
    AndroidSurfaceControl* surface_control,
    float alpha) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetBufferAlpha");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetBufferAlpha(handle_, surface_control->GetHandle(),
                                   alpha);
}

bool InMemoryAndroidSurfaceTransaction::SetColor(
    AndroidSurfaceControl* surface_control,
    float r,
    float g,
    float b,
    float alpha) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetColor");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  return provider_->SetColor(handle_, surface_control->GetHandle(), r, g, b,
                             alpha);
}

bool InMemoryAndroidSurfaceTransaction::Reparent(
    AndroidSurfaceControl* surface_control,
    AndroidSurfaceControl* new_parent) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::Reparent");
  if (!handle_ || !surface_control || !provider_) {
    return false;
  }
  void* parent_handle = new_parent ? new_parent->GetHandle() : nullptr;
  return provider_->Reparent(handle_, surface_control->GetHandle(),
                             parent_handle);
}

bool InMemoryAndroidSurfaceTransaction::SetOnComplete(
    OnCompleteCallback callback) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::SetOnComplete");
  if (!handle_ || !provider_) {
    return false;
  }
  on_complete_callback_ = std::move(callback);
  return provider_->SetOnComplete(handle_, on_complete_callback_);
}

bool InMemoryAndroidSurfaceTransaction::Apply() {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceTransaction::Apply");
  if (!handle_ || !provider_) {
    return false;
  }
  return provider_->ApplyTransaction(handle_);
}

// =============================================================================
// InMemoryAndroidSurfaceControlProvider Implementation
// =============================================================================

InMemoryAndroidSurfaceControlProvider::InMemoryAndroidSurfaceControlProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::"
               "InMemoryAndroidSurfaceControlProvider");
}

InMemoryAndroidSurfaceControlProvider::
    ~InMemoryAndroidSurfaceControlProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::"
               "~InMemoryAndroidSurfaceControlProvider");
}

bool InMemoryAndroidSurfaceControlProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::IsAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  return is_available_;
}

std::unique_ptr<AndroidSurfaceControl>
InMemoryAndroidSurfaceControlProvider::CreateFromWindow(
    void* window,
    const std::string& debug_name) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::CreateFromWindow");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || creation_failure_ || !window) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  void* handle = reinterpret_cast<void*>(static_cast<uintptr_t>(0x2000 + id));

  AndroidSurfaceControlState state;
  state.id = id;
  state.debug_name = debug_name;
  state.handle = handle;
  state.parent_handle = nullptr;
  state.parent_id = 0;
  state.is_valid = true;
  state.ref_count = 1;

  surfaces_[id] = state;
  handle_to_id_[handle] = id;

  return std::make_unique<InMemoryAndroidSurfaceControl>(
      id, debug_name, handle, nullptr, 0, true, shared_from_this());
}

std::unique_ptr<AndroidSurfaceControl>
InMemoryAndroidSurfaceControlProvider::Create(AndroidSurfaceControl* parent,
                                              const std::string& debug_name) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::Create");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || creation_failure_ || !parent || !parent->GetHandle()) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  void* handle = reinterpret_cast<void*>(static_cast<uintptr_t>(0x2000 + id));

  AndroidSurfaceControlState state;
  state.id = id;
  state.debug_name = debug_name;
  state.handle = handle;
  state.parent_handle = parent->GetHandle();
  state.parent_id = parent->GetId();
  state.is_valid = true;
  state.ref_count = 1;

  surfaces_[id] = state;
  handle_to_id_[handle] = id;

  return std::make_unique<InMemoryAndroidSurfaceControl>(
      id, debug_name, handle, parent->GetHandle(), parent->GetId(), true,
      shared_from_this());
}

std::unique_ptr<AndroidSurfaceControl>
InMemoryAndroidSurfaceControlProvider::CreateFromNativeHandle(
    void* handle,
    const std::string& debug_name,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::CreateFromNativeHandle");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle) {
    return nullptr;
  }

  uint64_t id = next_id_++;
  AndroidSurfaceControlState state;
  state.id = id;
  state.debug_name = debug_name;
  state.handle = handle;
  state.parent_handle = nullptr;
  state.parent_id = 0;
  state.is_valid = true;
  state.ref_count = 1;

  surfaces_[id] = state;
  handle_to_id_[handle] = id;

  return std::make_unique<InMemoryAndroidSurfaceControl>(
      id, debug_name, handle, nullptr, 0, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidSurfaceTransaction>
InMemoryAndroidSurfaceControlProvider::CreateTransaction() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::CreateTransaction");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || creation_failure_) {
    return nullptr;
  }

  uint64_t tx_id = next_transaction_id_++;
  void* tx_handle =
      reinterpret_cast<void*>(static_cast<uintptr_t>(0x9000 + tx_id));

  PendingTransaction tx;
  tx.handle = tx_handle;
  transactions_[tx_handle] = tx;

  return std::make_unique<InMemoryAndroidSurfaceTransaction>(
      tx_handle, true, shared_from_this());
}

std::unique_ptr<AndroidSurfaceTransaction>
InMemoryAndroidSurfaceControlProvider::CreateTransactionFromNativeHandle(
    void* handle,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::"
               "CreateTransactionFromNativeHandle");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!handle) {
    return nullptr;
  }

  PendingTransaction tx;
  tx.handle = handle;
  transactions_[handle] = tx;

  return std::make_unique<InMemoryAndroidSurfaceTransaction>(
      handle, take_ownership, shared_from_this());
}

void InMemoryAndroidSurfaceControlProvider::Acquire(void* handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = handle_to_id_.find(handle);
  if (it != handle_to_id_.end()) {
    surfaces_[it->second].ref_count++;
  }
}

void InMemoryAndroidSurfaceControlProvider::Release(void* handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::Release");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = handle_to_id_.find(handle);
  if (it != handle_to_id_.end()) {
    auto& state = surfaces_[it->second];
    state.ref_count--;
    if (state.ref_count <= 0) {
      surfaces_.erase(it->second);
      handle_to_id_.erase(it);
    }
  }
}

void InMemoryAndroidSurfaceControlProvider::DeleteTransaction(
    void* transaction_handle) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::DeleteTransaction");
  std::lock_guard<std::mutex> lock(mutex_);
  transactions_.erase(transaction_handle);
}

bool InMemoryAndroidSurfaceControlProvider::ApplyTransaction(
    void* transaction_handle) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::ApplyTransaction");
  std::function<void(const AndroidSurfaceControlStats&)> on_complete;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = transactions_.find(transaction_handle);
    if (it == transactions_.end()) {
      return false;
    }

    auto& tx = it->second;
    for (const auto& [surface_handle, update_state] : tx.updates) {
      auto id_it = handle_to_id_.find(surface_handle);
      if (id_it != handle_to_id_.end()) {
        auto& target = surfaces_[id_it->second];
        target.visibility = update_state.visibility;
        target.z_order = update_state.z_order;
        target.buffer_handle = update_state.buffer_handle;
        target.buffer_fence_fd = update_state.buffer_fence_fd;
        target.source_rect = update_state.source_rect;
        target.destination_rect = update_state.destination_rect;
        target.transform = update_state.transform;
        target.damage_region = update_state.damage_region;
        target.alpha = update_state.alpha;
        target.color = update_state.color;
        target.parent_handle = update_state.parent_handle;
        target.parent_id = update_state.parent_id;
      }
    }

    apply_count_++;
    on_complete = std::move(tx.on_complete);
    transactions_.erase(it);
  }

  if (on_complete) {
    AndroidSurfaceControlStats stats;
    stats.previous_release_fence_fd = -1;
    auto now = std::chrono::steady_clock::now().time_since_epoch();
    stats.present_time_nanos =
        std::chrono::duration_cast<std::chrono::nanoseconds>(now).count();
    stats.latch_time_nanos = stats.present_time_nanos;
    on_complete(stats);
  }

  return true;
}

bool InMemoryAndroidSurfaceControlProvider::Reparent(
    void* transaction_handle,
    void* surface_control_handle,
    void* new_parent_handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::Reparent");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  uint64_t parent_id = 0;
  if (new_parent_handle) {
    auto p_it = handle_to_id_.find(new_parent_handle);
    if (p_it != handle_to_id_.end()) {
      parent_id = p_it->second;
    }
  }
  auto& update = it->second.updates[surface_control_handle];
  update.parent_handle = new_parent_handle;
  update.parent_id = parent_id;
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetVisibility(
    void* transaction_handle,
    void* surface_control_handle,
    int8_t visibility) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetVisibility");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.visibility = visibility == 1 ? AndroidSurfaceControlVisibility::kShow
                                      : AndroidSurfaceControlVisibility::kHide;
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetZOrder(
    void* transaction_handle,
    void* surface_control_handle,
    int32_t z_order) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::SetZOrder");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.z_order = z_order;
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetBuffer(
    void* transaction_handle,
    void* surface_control_handle,
    void* hardware_buffer,
    int acquire_fence_fd) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::SetBuffer");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.buffer_handle = hardware_buffer;
  update.buffer_fence_fd = acquire_fence_fd;
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetGeometry(
    void* transaction_handle,
    void* surface_control_handle,
    const AndroidSurfaceControlRect* source,
    const AndroidSurfaceControlRect* destination,
    int32_t transform) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::SetGeometry");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  if (source) {
    update.source_rect = *source;
  }
  if (destination) {
    update.destination_rect = *destination;
  }
  update.transform = static_cast<AndroidSurfaceControlTransform>(transform);
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetDamageRegion(
    void* transaction_handle,
    void* surface_control_handle,
    const AndroidSurfaceControlRect* rects,
    uint32_t count) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetDamageRegion");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.damage_region.clear();
  if (rects && count > 0) {
    update.damage_region.assign(rects, rects + count);
  }
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetBufferAlpha(
    void* transaction_handle,
    void* surface_control_handle,
    float alpha) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetBufferAlpha");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.alpha = alpha;
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetColor(
    void* transaction_handle,
    void* surface_control_handle,
    float r,
    float g,
    float b,
    float alpha) {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::SetColor");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end() || !surface_control_handle) {
    return false;
  }
  auto& update = it->second.updates[surface_control_handle];
  update.color = AndroidSurfaceControlColor{r, g, b, alpha};
  return true;
}

bool InMemoryAndroidSurfaceControlProvider::SetOnComplete(
    void* transaction_handle,
    std::function<void(const AndroidSurfaceControlStats&)> callback) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetOnComplete");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = transactions_.find(transaction_handle);
  if (it == transactions_.end()) {
    return false;
  }
  it->second.on_complete = std::move(callback);
  return true;
}

void InMemoryAndroidSurfaceControlProvider::SetAvailable(bool available) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  is_available_ = available;
}

void InMemoryAndroidSurfaceControlProvider::SetCreationFailure(bool fail) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::SetCreationFailure");
  std::lock_guard<std::mutex> lock(mutex_);
  creation_failure_ = fail;
}

size_t InMemoryAndroidSurfaceControlProvider::GetActiveSurfaceControlCount()
    const {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidSurfaceControlProvider::GetActiveSurfaceControlCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return surfaces_.size();
}

size_t InMemoryAndroidSurfaceControlProvider::GetTransactionCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::GetTransactionCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return transactions_.size();
}

size_t InMemoryAndroidSurfaceControlProvider::GetApplyCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::GetApplyCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return apply_count_;
}

std::optional<AndroidSurfaceControlState>
InMemoryAndroidSurfaceControlProvider::GetSurfaceState(uint64_t id) const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidSurfaceControlProvider::GetSurfaceState");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = surfaces_.find(id);
  if (it != surfaces_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<AndroidSurfaceControlState>
InMemoryAndroidSurfaceControlProvider::GetSurfaceStateByHandle(
    void* handle) const {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidSurfaceControlProvider::GetSurfaceStateByHandle");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = handle_to_id_.find(handle);
  if (it != handle_to_id_.end()) {
    auto s_it = surfaces_.find(it->second);
    if (s_it != surfaces_.end()) {
      return s_it->second;
    }
  }
  return std::nullopt;
}

void InMemoryAndroidSurfaceControlProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryAndroidSurfaceControlProvider::Clear");
  std::lock_guard<std::mutex> lock(mutex_);
  surfaces_.clear();
  handle_to_id_.clear();
  transactions_.clear();
  apply_count_ = 0;
}

}  // namespace android
}  // namespace flutter
