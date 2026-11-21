// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_heap_profiler.h"

#include <atomic>
#include <mutex>
#include <utility>

#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {
namespace {

constexpr intptr_t kDefaultSamplingIntervalBytes = 512 * 1024;

struct ProfilerState {
  std::mutex mutex;
  std::unique_ptr<DartHeapProfilerDelegate> owned_delegate;
  std::atomic<DartHeapProfilerDelegate*> active_delegate{nullptr};
  std::atomic<bool> sampling_active{false};
  intptr_t sampling_interval_bytes = kDefaultSamplingIntervalBytes;
  bool vm_initialized = false;
  bool callbacks_registered = false;
};

ProfilerState& GetState() {
  static auto* state = new ProfilerState();
  return *state;
}

void* OnDartSampleCreated(Dart_Isolate /*isolate*/,
                          Dart_IsolateGroup group,
                          const char* cls_name,
                          intptr_t size) {
  ProfilerState& state = GetState();
  if (size <= 0 || !state.sampling_active.load(std::memory_order_acquire)) {
    return nullptr;
  }
  DartHeapProfilerDelegate* delegate =
      state.active_delegate.load(std::memory_order_acquire);
  if (delegate == nullptr) {
    return nullptr;
  }
  const std::string_view safe_cls = (cls_name != nullptr && cls_name[0] != '\0')
                                        ? std::string_view(cls_name)
                                        : std::string_view("Unknown");
  return delegate->OnSampleCreated(reinterpret_cast<uintptr_t>(group), safe_cls,
                                   static_cast<size_t>(size));
}

void OnDartSampleDestroyed(void* data) {
  if (data == nullptr) {
    return;
  }
  DartHeapProfilerDelegate* delegate =
      GetState().active_delegate.load(std::memory_order_acquire);
  if (delegate != nullptr) {
    delegate->OnSampleDestroyed(data);
  }
}

}  // namespace

void DartHeapProfiler::SetDelegate(
    std::unique_ptr<DartHeapProfilerDelegate> delegate) {
  ProfilerState& state = GetState();
  std::unique_ptr<DartHeapProfilerDelegate> previous;
  {
    std::scoped_lock lock(state.mutex);
    if (delegate == nullptr && state.vm_initialized &&
        state.sampling_active.load(std::memory_order_relaxed)) {
      state.sampling_active.store(false, std::memory_order_release);
      Dart_DisableHeapSampling();
    }
    state.active_delegate.store(delegate.get(), std::memory_order_release);
    previous = std::move(state.owned_delegate);
    state.owned_delegate = std::move(delegate);
    if (state.vm_initialized && state.owned_delegate != nullptr) {
      if (!state.callbacks_registered) {
        Dart_RegisterHeapSamplingCallback(&OnDartSampleCreated,
                                          &OnDartSampleDestroyed);
        state.callbacks_registered = true;
      }
      state.owned_delegate->OnDartVMInitialized();
      if (state.sampling_active.load(std::memory_order_relaxed)) {
        Dart_SetHeapSamplingPeriod(state.sampling_interval_bytes);
        Dart_EnableHeapSampling();
      }
    }
  }
}

void DartHeapProfiler::StartSampling(intptr_t sampling_interval_bytes) {
  if (sampling_interval_bytes <= 0) {
    return;
  }
  ProfilerState& state = GetState();
  std::scoped_lock lock(state.mutex);
  state.sampling_interval_bytes = sampling_interval_bytes;
  state.sampling_active.store(true, std::memory_order_release);
  if (state.vm_initialized && state.owned_delegate != nullptr) {
    if (!state.callbacks_registered) {
      Dart_RegisterHeapSamplingCallback(&OnDartSampleCreated,
                                        &OnDartSampleDestroyed);
      state.callbacks_registered = true;
    }
    Dart_SetHeapSamplingPeriod(state.sampling_interval_bytes);
    Dart_EnableHeapSampling();
  }
}

void DartHeapProfiler::StopSampling() {
  ProfilerState& state = GetState();
  std::scoped_lock lock(state.mutex);
  const bool was_active =
      state.sampling_active.exchange(false, std::memory_order_acq_rel);
  if (was_active && state.vm_initialized) {
    Dart_DisableHeapSampling();
  }
}

void DartHeapProfiler::OnDartVMInitialized() {
  ProfilerState& state = GetState();
  std::scoped_lock lock(state.mutex);
  state.vm_initialized = true;
  if (state.owned_delegate == nullptr) {
    return;
  }
  state.owned_delegate->OnDartVMInitialized();
  Dart_RegisterHeapSamplingCallback(&OnDartSampleCreated,
                                    &OnDartSampleDestroyed);
  state.callbacks_registered = true;
  if (state.sampling_active.load(std::memory_order_relaxed)) {
    Dart_SetHeapSamplingPeriod(state.sampling_interval_bytes);
    Dart_EnableHeapSampling();
  }
}

void DartHeapProfiler::OnDartVMCleanup() {
  ProfilerState& state = GetState();
  std::scoped_lock lock(state.mutex);
  if (state.vm_initialized &&
      state.sampling_active.load(std::memory_order_relaxed)) {
    Dart_DisableHeapSampling();
  }
  if (state.owned_delegate != nullptr) {
    state.owned_delegate->OnDartVMCleanup();
  }
  state.vm_initialized = false;
  state.callbacks_registered = false;
}

}  // namespace flutter
