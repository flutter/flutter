// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/android_platform_views_controller.h"

#include "flutter/shell/platform/android/embedder/flutter_embedder_native.h"

#if !defined(_WIN32)
#include <unistd.h>
#else
#include <io.h>
#endif

#include <algorithm>
#include <cstring>
#include <utility>

#if defined(__ANDROID__)
#include <android/native_window.h>
#endif

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

int CloseFd(int fd) {
#if !defined(_WIN32)
  return ::close(fd);
#else
  return ::_close(fd);
#endif
}

void DefaultSynchronousPlatformDispatcher(const std::function<void()>& task) {
  if (task) {
    task();
  }
}

}  // namespace

CapturedLayer::CapturedLayer() = default;

CapturedLayer::~CapturedLayer() {
  ResetFence();
}

CapturedLayer::CapturedLayer(CapturedLayer&& other) noexcept
    : type(other.type),
      identifier(other.identifier),
      offset(other.offset),
      size(other.size),
      hardware_buffer_handle(other.hardware_buffer_handle),
      software_allocation(other.software_allocation),
      software_row_bytes(other.software_row_bytes),
      software_height(other.software_height),
      synchronization_fence_fd(other.synchronization_fence_fd),
      mutations(std::move(other.mutations)) {
  other.software_allocation = nullptr;
  other.software_row_bytes = 0;
  other.software_height = 0;
  other.synchronization_fence_fd = -1;
}

CapturedLayer& CapturedLayer::operator=(CapturedLayer&& other) noexcept {
  if (this != &other) {
    ResetFence();
    type = other.type;
    identifier = other.identifier;
    offset = other.offset;
    size = other.size;
    hardware_buffer_handle = other.hardware_buffer_handle;
    software_allocation = other.software_allocation;
    software_row_bytes = other.software_row_bytes;
    software_height = other.software_height;
    synchronization_fence_fd = other.synchronization_fence_fd;
    mutations = std::move(other.mutations);
    other.software_allocation = nullptr;
    other.software_row_bytes = 0;
    other.software_height = 0;
    other.synchronization_fence_fd = -1;
  }
  return *this;
}

void CapturedLayer::ResetFence() {
  if (synchronization_fence_fd >= 0) {
    CloseFd(synchronization_fence_fd);
    synchronization_fence_fd = -1;
  }
}

AndroidPlatformViewsController::AndroidPlatformViewsController(
    std::shared_ptr<JniDelegate> jni_delegate,
    AndroidSurfaceControl* surface_control,
    TaskRunnerDispatcher platform_dispatcher)
    : jni_delegate_(std::move(jni_delegate)),
      surface_control_(surface_control),
      platform_dispatcher_(platform_dispatcher
                               ? std::move(platform_dispatcher)
                               : DefaultSynchronousPlatformDispatcher) {}

AndroidPlatformViewsController::~AndroidPlatformViewsController() = default;

CapturedViewFrameState AndroidPlatformViewsController::CaptureLayersByValue(
    FlutterViewId view_id,
    const FlutterLayer** layers,
    size_t layers_count) {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::CaptureLayersByValue");
  CapturedViewFrameState state;
  state.view_id = view_id;
  if (layers == nullptr || layers_count == 0) {
    return state;
  }

  state.layers.reserve(layers_count);
  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* src = layers[i];
    if (src == nullptr) {
      continue;
    }

    CapturedLayer captured;
    captured.type = src->type;
    captured.offset = src->offset;
    captured.size = src->size;

    if (src->type == kFlutterLayerContentTypeBackingStore &&
        src->backing_store != nullptr) {
      captured.identifier = static_cast<int64_t>(i);
      captured.hardware_buffer_handle =
          reinterpret_cast<uintptr_t>(src->backing_store->user_data);
      if (src->backing_store->type == kFlutterBackingStoreTypeSoftware) {
        captured.software_allocation = src->backing_store->software.allocation;
        captured.software_row_bytes = src->backing_store->software.row_bytes;
        captured.software_height = src->backing_store->software.height;
      }
      if (src->backing_store_present_info != nullptr) {
        // Take ownership of `synchronization_fence_fd` immediately and reset
        // the caller's descriptor to `-1` (ADR-0005, Invariant 3).
        auto* mutable_present_info =
            const_cast<FlutterBackingStorePresentInfo*>(
                src->backing_store_present_info);
        captured.synchronization_fence_fd =
            mutable_present_info->synchronization_fence_fd;
        mutable_present_info->synchronization_fence_fd = -1;
      }
    } else if (src->type == kFlutterLayerContentTypePlatformView &&
               src->platform_view != nullptr) {
      captured.identifier = src->platform_view->identifier;
      const size_t mutation_count = src->platform_view->mutations_count;
      if (src->platform_view->mutations != nullptr && mutation_count > 0) {
        captured.mutations.reserve(mutation_count);
        for (size_t m = 0; m < mutation_count; ++m) {
          const FlutterPlatformViewMutation* mut_src =
              src->platform_view->mutations[m];
          if (mut_src == nullptr) {
            continue;
          }
          CapturedPlatformViewMutation mut_copy;
          mut_copy.type = mut_src->type;
          switch (mut_src->type) {
            case kFlutterPlatformViewMutationTypeOpacity:
              mut_copy.opacity = mut_src->opacity;
              break;
            case kFlutterPlatformViewMutationTypeClipRect:
              mut_copy.clip_rect = mut_src->clip_rect;
              break;
            case kFlutterPlatformViewMutationTypeClipRoundedRect:
              mut_copy.clip_rrect = mut_src->clip_rounded_rect;
              break;
            case kFlutterPlatformViewMutationTypeTransformation:
              mut_copy.transformation = mut_src->transformation;
              break;
            case kFlutterPlatformViewMutationTypeClipRoundSuperellipse:
            case kFlutterPlatformViewMutationTypeClipPath:
              break;
          }
          captured.mutations.push_back(mut_copy);
        }
      }
    }

    state.layers.push_back(std::move(captured));
  }

  return state;
}

bool AndroidPlatformViewsController::PresentView(
    const FlutterPresentViewInfo* info) {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::PresentView");
  if (info == nullptr) {
    return false;
  }

  // Invariant 4 (Multi-View Value Capture): Capture all `FlutterLayer` and
  // `FlutterPlatformViewMutation` slices by value BEFORE dispatching to the
  // platform thread so concurrent views (e.g. View A and View B) never race on
  // shared mutable fields.
  CapturedViewFrameState captured_state =
      CaptureLayersByValue(info->view_id, info->layers, info->layers_count);

  auto captured =
      std::make_shared<CapturedViewFrameState>(std::move(captured_state));
  platform_dispatcher_([this, captured]() {
    ApplyCapturedFrameOnPlatformThread(std::move(*captured));
  });
  return true;
}

bool AndroidPlatformViewsController::OnPresentViewCallback(
    const FlutterPresentViewInfo* info) {
  if (info == nullptr || info->user_data == nullptr) {
    return false;
  }
  return static_cast<AndroidPlatformViewsController*>(info->user_data)
      ->PresentView(info);
}

void AndroidPlatformViewsController::ApplyCapturedFrameOnPlatformThread(
    CapturedViewFrameState captured_state) {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::ApplyCapturedFrameOnPlatformThread");

  CommittedViewSummary summary;
  summary.view_id = captured_state.view_id;

  bool has_software_layer = false;
  for (auto& layer : captured_state.layers) {
    if (layer.type == kFlutterLayerContentTypeBackingStore) {
      summary.backing_store_layer_count++;
      FlutterBackingStorePresentInfo present_info = {};
      present_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
      present_info.synchronization_fence_fd = layer.synchronization_fence_fd;
      layer.synchronization_fence_fd = -1;

      if (layer.software_allocation != nullptr) {
        has_software_layer = true;
#if defined(__ANDROID__)
        if (surface_control_ != nullptr) {
          uintptr_t handle =
              surface_control_->GetNativeWindowHandle(captured_state.view_id);
          if (handle != 0 && handle != 1) {
            auto* window = reinterpret_cast<ANativeWindow*>(handle);
            ANativeWindow_Buffer buffer;
            if (ANativeWindow_lock(window, &buffer, nullptr) == 0) {
              FlutterEmbedderNative::SoftwareBufferView dst_view;
              dst_view.bits = buffer.bits;
              dst_view.format = buffer.format;
              dst_view.stride = buffer.stride;
              dst_view.height = buffer.height;
              FlutterEmbedderNative::CopySoftwarePixels(
                  layer.software_allocation, layer.software_row_bytes,
                  layer.software_height, dst_view);
              ANativeWindow_unlockAndPost(window);
            }
          }
        }
#endif
        if (present_info.synchronization_fence_fd >= 0) {
          CloseFd(present_info.synchronization_fence_fd);
          present_info.synchronization_fence_fd = -1;
        }
      } else if (surface_control_ != nullptr) {
        surface_control_->PresentBackingStore(
            captured_state.view_id, layer.identifier,
            layer.hardware_buffer_handle != 0 ? layer.hardware_buffer_handle
                                              : 0x1,
            static_cast<int32_t>(layer.size.width > 0 ? layer.size.width : 1),
            static_cast<int32_t>(layer.size.height > 0 ? layer.size.height : 1),
            &present_info);
      } else if (present_info.synchronization_fence_fd >= 0) {
        CloseFd(present_info.synchronization_fence_fd);
        present_info.synchronization_fence_fd = -1;
      }
    } else if (layer.type == kFlutterLayerContentTypePlatformView) {
      summary.platform_view_layer_count++;
      summary.platform_view_ids.push_back(layer.identifier);
      summary.mutation_counts_per_view.push_back(layer.mutations.size());
    }
  }

  if (surface_control_ != nullptr) {
    surface_control_->NotifyTexturesUpdated();
    surface_control_->CommitTransaction(captured_state.view_id);
    if (has_software_layer) {
      surface_control_->NotifyFirstFrame();
    }
  } else {
    bool is_first_frame = !first_frame_dispatched_.exchange(true);
    if (is_first_frame && jni_delegate_ != nullptr) {
      jni_delegate_->OnFirstFrame();
    }
  }

  {
    std::lock_guard<std::mutex> lock(summary_mutex_);
    CommittedViewSummary& stored = committed_views_[captured_state.view_id];
    summary.committed_frames = stored.committed_frames + 1;
    stored = std::move(summary);
  }
}

bool AndroidPlatformViewsController::GetCommittedViewSummary(
    FlutterViewId view_id,
    CommittedViewSummary* out_summary) const {
  if (out_summary == nullptr) {
    return false;
  }
  std::lock_guard<std::mutex> lock(summary_mutex_);
  auto it = committed_views_.find(view_id);
  if (it == committed_views_.end()) {
    return false;
  }
  *out_summary = it->second;
  return true;
}

bool AndroidPlatformViewsController::OnCreateBackingStoreCallback(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out,
    void* user_data) {
  if (config == nullptr || backing_store_out == nullptr) {
    return false;
  }
  size_t width =
      static_cast<size_t>(config->size.width > 0 ? config->size.width : 1);
  size_t height =
      static_cast<size_t>(config->size.height > 0 ? config->size.height : 1);
  size_t row_bytes = width * 4;
  size_t allocation_size = row_bytes * height;
  uint8_t* allocation = new (std::nothrow) uint8_t[allocation_size]();
  if (allocation == nullptr) {
    return false;
  }

  std::memset(backing_store_out, 0, sizeof(FlutterBackingStore));
  backing_store_out->struct_size = sizeof(FlutterBackingStore);
  backing_store_out->type = kFlutterBackingStoreTypeSoftware;
  backing_store_out->user_data = allocation;
  backing_store_out->did_update = true;
  backing_store_out->software.allocation = allocation;
  backing_store_out->software.row_bytes = row_bytes;
  backing_store_out->software.height = height;
  backing_store_out->software.user_data = allocation;
  backing_store_out->software.destruction_callback = nullptr;
  return true;
}

bool AndroidPlatformViewsController::OnCollectBackingStoreCallback(
    const FlutterBackingStore* renderer,
    void* user_data) {
  if (renderer == nullptr) {
    return false;
  }
  if (renderer->type == kFlutterBackingStoreTypeSoftware &&
      renderer->user_data != nullptr) {
    delete[] static_cast<const uint8_t*>(renderer->user_data);
  }
  return true;
}

}  // namespace flutter
