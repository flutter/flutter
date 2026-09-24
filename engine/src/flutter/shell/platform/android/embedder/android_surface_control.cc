// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/android_surface_control.h"

#if !defined(_WIN32)
#include <unistd.h>
#else
#include <io.h>
#endif

#if defined(__ANDROID__)
#include <android/native_window.h>
#endif

#include <string>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

constexpr FlutterViewId kPrimaryImplicitViewId = 0;

int DefaultCloseFd(int fd) {
#if !defined(_WIN32)
  return ::close(fd);
#else
  return ::_close(fd);
#endif
}

void DefaultReleaseNativeWindow(uintptr_t handle) {
#if defined(__ANDROID__)
  if (handle != 0 && handle != 1) {
    ANativeWindow_release(reinterpret_cast<ANativeWindow*>(handle));
  }
#endif
}

}  // namespace

ScopedSyncFenceFd::ScopedSyncFenceFd(int* fd_slot, CloserFn closer)
    : closer_(closer ? std::move(closer) : DefaultCloseFd) {
  if (fd_slot != nullptr && *fd_slot >= 0) {
    fd_ = *fd_slot;
    *fd_slot = -1;
  }
}

ScopedSyncFenceFd::ScopedSyncFenceFd(
    FlutterBackingStorePresentInfo* present_info,
    CloserFn closer)
    : closer_(closer ? std::move(closer) : DefaultCloseFd) {
  if (present_info != nullptr && present_info->synchronization_fence_fd >= 0) {
    fd_ = present_info->synchronization_fence_fd;
    present_info->synchronization_fence_fd = -1;
  }
}

ScopedSyncFenceFd::~ScopedSyncFenceFd() {
  Reset();
}

ScopedSyncFenceFd::ScopedSyncFenceFd(ScopedSyncFenceFd&& other) noexcept
    : fd_(other.fd_), closer_(std::move(other.closer_)) {
  other.fd_ = -1;
}

ScopedSyncFenceFd& ScopedSyncFenceFd::operator=(
    ScopedSyncFenceFd&& other) noexcept {
  if (this != &other) {
    Reset();
    fd_ = other.fd_;
    closer_ = std::move(other.closer_);
    other.fd_ = -1;
  }
  return *this;
}

int ScopedSyncFenceFd::Release() {
  const int released = fd_;
  fd_ = -1;
  return released;
}

void ScopedSyncFenceFd::Reset() {
  if (fd_ >= 0) {
    const int fd_to_close = fd_;
    fd_ = -1;
    if (closer_) {
      closer_(fd_to_close);
    }
  }
}

AndroidSurfaceControl::AndroidSurfaceControl(
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table,
    FenceCloserFn fence_closer,
    WindowReleaserFn window_releaser)
    : jni_delegate_(std::move(jni_delegate)),
      embedder_api_(proc_table),
      fence_closer_(fence_closer ? std::move(fence_closer) : DefaultCloseFd),
      window_releaser_(window_releaser ? std::move(window_releaser)
                                       : DefaultReleaseNativeWindow) {}

AndroidSurfaceControl::~AndroidSurfaceControl() {
  std::lock_guard<std::mutex> lock(mutex_);
  for (auto& [view_id, record] : views_) {
    ReleaseAllLayersForViewLocked(&record);
    if (record.native_window_handle != 0) {
      if (window_releaser_) {
        window_releaser_(record.native_window_handle);
      }
      record.native_window_handle = 0;
    }
  }
  views_.clear();
}

bool AndroidSurfaceControl::NotifySurfaceCreated(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterViewId view_id,
    uintptr_t native_window_handle,
    int32_t width,
    int32_t height,
    double pixel_ratio) {
  TRACE_EVENT0("flutter", "AndroidSurfaceControl::NotifySurfaceCreated");
  if (engine == nullptr) {
    return false;
  }

  {
    std::lock_guard<std::mutex> lock(mutex_);
    ViewSurfaceRecord& record = views_[view_id];
    if (record.native_window_handle != 0 &&
        record.native_window_handle != native_window_handle) {
      if (window_releaser_) {
        window_releaser_(record.native_window_handle);
      }
    }
    record.native_window_handle = native_window_handle;
    record.width = width;
    record.height = height;
    record.pixel_ratio = pixel_ratio;
    record.surface_attached = true;
  }

  if (view_id == kPrimaryImplicitViewId) {
    if (embedder_api_.NotifyCreated == nullptr) {
      return false;
    }
    if (embedder_api_.NotifyCreated(engine) != kSuccess) {
      return false;
    }
    if (width > 0 && height > 0 &&
        embedder_api_.SendWindowMetricsEvent != nullptr) {
      FlutterWindowMetricsEvent metrics = {};
      metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
      metrics.width = static_cast<size_t>(width);
      metrics.height = static_cast<size_t>(height);
      metrics.pixel_ratio = pixel_ratio;
      metrics.view_id = view_id;
      return embedder_api_.SendWindowMetricsEvent(engine, &metrics) == kSuccess;
    }
    return true;
  }

  if (embedder_api_.AddView == nullptr) {
    return false;
  }
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = static_cast<size_t>(width > 0 ? width : 1);
  metrics.height = static_cast<size_t>(height > 0 ? height : 1);
  metrics.pixel_ratio = pixel_ratio;
  metrics.view_id = view_id;

  bool add_succeeded = true;
  FlutterAddViewInfo add_info = {};
  add_info.struct_size = sizeof(FlutterAddViewInfo);
  add_info.view_id = view_id;
  add_info.view_metrics = &metrics;
  add_info.user_data = &add_succeeded;
  add_info.add_view_callback = [](const FlutterAddViewResult* result) {
    if (result != nullptr && result->user_data != nullptr) {
      *static_cast<bool*>(result->user_data) = result->added;
    }
  };
  return embedder_api_.AddView(engine, &add_info) == kSuccess && add_succeeded;
}

bool AndroidSurfaceControl::NotifySurfaceChanged(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterViewId view_id,
    int32_t width,
    int32_t height,
    double pixel_ratio) {
  TRACE_EVENT0("flutter", "AndroidSurfaceControl::NotifySurfaceChanged");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end() || !it->second.surface_attached) {
    return false;
  }
  it->second.width = width;
  it->second.height = height;
  it->second.pixel_ratio = pixel_ratio;
  return true;
}

bool AndroidSurfaceControl::NotifySurfaceDestroyed(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterViewId view_id) {
  TRACE_EVENT0("flutter", "AndroidSurfaceControl::NotifySurfaceDestroyed");
  if (engine == nullptr) {
    return false;
  }

  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = views_.find(view_id);
    if (it != views_.end()) {
      ReleaseAllLayersForViewLocked(&it->second);
      it->second.surface_attached = false;
      if (it->second.native_window_handle != 0) {
        if (window_releaser_) {
          window_releaser_(it->second.native_window_handle);
        }
        it->second.native_window_handle = 0;
      }
    }
  }

  // Synchronous Surface Destruction Invariant (ADR-0004, Invariant 5):
  // `FlutterEngineNotifyDestroyed` / `FlutterEngineRemoveView` must complete
  // synchronously before `surfaceDestroyed()` returns to the Android OS.
  if (view_id == kPrimaryImplicitViewId) {
    if (embedder_api_.NotifyDestroyed == nullptr) {
      return false;
    }
    return embedder_api_.NotifyDestroyed(engine) == kSuccess;
  }

  if (embedder_api_.RemoveView == nullptr) {
    return false;
  }
  bool remove_succeeded = true;
  FlutterRemoveViewInfo remove_info = {};
  remove_info.struct_size = sizeof(FlutterRemoveViewInfo);
  remove_info.view_id = view_id;
  remove_info.user_data = &remove_succeeded;
  remove_info.remove_view_callback = [](const FlutterRemoveViewResult* result) {
    if (result != nullptr && result->user_data != nullptr) {
      *static_cast<bool*>(result->user_data) = result->removed;
    }
  };
  return embedder_api_.RemoveView(engine, &remove_info) == kSuccess &&
         remove_succeeded;
}

bool AndroidSurfaceControl::PresentBackingStore(
    FlutterViewId view_id,
    int64_t layer_id,
    uintptr_t hardware_buffer_handle,
    int32_t width,
    int32_t height,
    FlutterBackingStorePresentInfo* present_info) {
  TRACE_EVENT0("flutter", "AndroidSurfaceControl::PresentBackingStore");

  // Take immediate RAII ownership of `synchronization_fence_fd` and reset
  // `present_info->synchronization_fence_fd = -1` (ADR-0005, Invariant 3).
  ScopedSyncFenceFd scoped_fence(present_info, fence_closer_);

  if (jni_delegate_ == nullptr || hardware_buffer_handle == 0 || width <= 0 ||
      height <= 0) {
    // `scoped_fence` automatically closes the descriptor upon scope exit.
    return false;
  }

  uintptr_t surface_control_handle = 0;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto view_it = views_.find(view_id);
    if (view_it == views_.end() || !view_it->second.surface_attached) {
      return false;
    }

    ViewSurfaceRecord& record = view_it->second;
    auto layer_it = record.active_layers.find(layer_id);
    if (layer_it != record.active_layers.end()) {
      surface_control_handle = layer_it->second;
    } else if (!record.free_layer_pool.empty()) {
      surface_control_handle = record.free_layer_pool.back();
      record.free_layer_pool.pop_back();
      record.active_layers[layer_id] = surface_control_handle;
    } else {
      const std::string debug_name = "FlutterHcppLayer_v" +
                                     std::to_string(view_id) + "_l" +
                                     std::to_string(layer_id);
      surface_control_handle =
          jni_delegate_->CreateSurfaceControl(debug_name, width, height);
      if (surface_control_handle == 0) {
        return false;
      }
      record.active_layers[layer_id] = surface_control_handle;
    }
    record.touched_layers_in_frame.insert(layer_id);
  }

  if (!jni_delegate_->SetBufferWithFence(
          surface_control_handle, hardware_buffer_handle, scoped_fence.Get())) {
    // SetBufferWithFence failed before accepting the fence; `scoped_fence`
    // closes the descriptor cleanly on scope exit.
    return false;
  }

  // Ownership of `synchronization_fence_fd` has transferred to the Android
  // `SurfaceControl.Transaction`. Release from `scoped_fence` to prevent
  // double-close.
  scoped_fence.Release();

  NotifyFirstFrame();

  return true;
}

bool AndroidSurfaceControl::NotifyFirstFrame() {
  bool is_first_frame = !first_frame_dispatched_.exchange(true);
  if (is_first_frame && jni_delegate_ != nullptr) {
    jni_delegate_->OnFirstFrame();
  }
  return is_first_frame;
}

bool AndroidSurfaceControl::CommitTransaction(FlutterViewId view_id) {
  TRACE_EVENT0("flutter", "AndroidSurfaceControl::CommitTransaction");
  if (jni_delegate_ == nullptr) {
    return false;
  }

  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto view_it = views_.find(view_id);
    if (view_it == views_.end() || !view_it->second.surface_attached) {
      return false;
    }

    ViewSurfaceRecord& record = view_it->second;
    for (auto it = record.active_layers.begin();
         it != record.active_layers.end();) {
      if (record.touched_layers_in_frame.find(it->first) ==
          record.touched_layers_in_frame.end()) {
        record.free_layer_pool.push_back(it->second);
        it = record.active_layers.erase(it);
      } else {
        ++it;
      }
    }
    record.touched_layers_in_frame.clear();
  }

  return jni_delegate_->ApplyTransaction();
}

bool AndroidSurfaceControl::HasAttachedSurface(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  return it != views_.end() && it->second.surface_attached;
}

uintptr_t AndroidSurfaceControl::GetNativeWindowHandle(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end() || !it->second.surface_attached) {
    return 0;
  }
  return it->second.native_window_handle;
}

size_t AndroidSurfaceControl::GetActiveLayerCount(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  return it != views_.end() ? it->second.active_layers.size() : 0;
}

size_t AndroidSurfaceControl::GetPooledLayerCount(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  return it != views_.end() ? it->second.free_layer_pool.size() : 0;
}

void AndroidSurfaceControl::ReleaseAllLayersForViewLocked(
    ViewSurfaceRecord* record) {
  if (record == nullptr) {
    return;
  }
  if (jni_delegate_ != nullptr) {
    for (const auto& [layer_id, handle] : record->active_layers) {
      if (handle != 0) {
        jni_delegate_->ReleaseSurfaceControl(handle);
      }
    }
    for (const uintptr_t handle : record->free_layer_pool) {
      if (handle != 0) {
        jni_delegate_->ReleaseSurfaceControl(handle);
      }
    }
  }
  record->active_layers.clear();
  record->touched_layers_in_frame.clear();
  record->free_layer_pool.clear();
}

}  // namespace flutter
