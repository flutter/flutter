// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/android_semantics_and_assets.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

AndroidSemanticsBridge::AndroidSemanticsBridge(
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table)
    : jni_delegate_(std::move(jni_delegate)), embedder_api_(proc_table) {}

AndroidSemanticsBridge::~AndroidSemanticsBridge() = default;

bool AndroidSemanticsBridge::SetSemanticsEnabled(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    bool enabled) {
  TRACE_EVENT0("flutter", "AndroidSemanticsBridge::SetSemanticsEnabled");
  if (engine == nullptr || embedder_api_.UpdateSemanticsEnabled == nullptr) {
    return false;
  }
  return embedder_api_.UpdateSemanticsEnabled(engine, enabled) == kSuccess;
}

bool AndroidSemanticsBridge::DispatchSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  TRACE_EVENT0("flutter", "AndroidSemanticsBridge::DispatchSemanticsAction");
  if (engine == nullptr || embedder_api_.DispatchSemanticsAction == nullptr) {
    return false;
  }
  return embedder_api_.DispatchSemanticsAction(engine, node_id, action, data,
                                               data_length) == kSuccess;
}

void AndroidSemanticsBridge::HandleSemanticsUpdate2(
    const FlutterSemanticsUpdate2* update) {
  TRACE_EVENT0("flutter", "AndroidSemanticsBridge::HandleSemanticsUpdate2");
  if (update == nullptr) {
    return;
  }

  SerializedSemanticsBatch batch;
  batch.view_id = update->view_id;
  batch.node_count = update->node_count;
  batch.custom_action_count = update->custom_action_count;

  if (update->nodes != nullptr && update->node_count > 0) {
    batch.node_ids.reserve(update->node_count);
    for (size_t i = 0; i < update->node_count; ++i) {
      if (update->nodes[i] != nullptr) {
        batch.node_ids.push_back(update->nodes[i]->id);
      }
    }
  }

  if (update->custom_actions != nullptr && update->custom_action_count > 0) {
    batch.action_ids.reserve(update->custom_action_count);
    for (size_t i = 0; i < update->custom_action_count; ++i) {
      if (update->custom_actions[i] != nullptr) {
        batch.action_ids.push_back(update->custom_actions[i]->id);
      }
    }
  }

  std::lock_guard<std::mutex> lock(mutex_);
  last_batches_[batch.view_id] = std::move(batch);
}

void AndroidSemanticsBridge::OnSemanticsUpdate2Callback(
    const FlutterSemanticsUpdate2* update,
    void* user_data) {
  if (update == nullptr || user_data == nullptr) {
    return;
  }
  static_cast<AndroidSemanticsBridge*>(user_data)->HandleSemanticsUpdate2(
      update);
}

bool AndroidSemanticsBridge::GetLastBatchForView(
    FlutterViewId view_id,
    SerializedSemanticsBatch* out_batch) const {
  if (out_batch == nullptr) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = last_batches_.find(view_id);
  if (it == last_batches_.end()) {
    return false;
  }
  *out_batch = it->second;
  return true;
}

AndroidDeferredLibraryLoader::AndroidDeferredLibraryLoader(
    const FlutterEngineProcTable& proc_table,
    UnmapFn unmap_callback)
    : embedder_api_(proc_table), unmap_callback_(std::move(unmap_callback)) {}

AndroidDeferredLibraryLoader::~AndroidDeferredLibraryLoader() = default;

bool AndroidDeferredLibraryLoader::LoadMappedDeferredLibrary(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    intptr_t loading_unit_id,
    const uint8_t* snapshot_data,
    size_t snapshot_data_size,
    const uint8_t* snapshot_instructions,
    size_t snapshot_instructions_size) {
  TRACE_EVENT0("flutter",
               "AndroidDeferredLibraryLoader::LoadMappedDeferredLibrary");
  if (engine == nullptr || embedder_api_.LoadDartDeferredLibrary == nullptr ||
      snapshot_data == nullptr || snapshot_data_size == 0) {
    if (unmap_callback_) {
      unmap_callback_(loading_unit_id, snapshot_data, snapshot_data_size,
                      snapshot_instructions, snapshot_instructions_size);
    }
    return false;
  }

  {
    std::lock_guard<std::mutex> lock(mutex_);
    active_mapped_units_++;
  }

  auto* lease = new MappedUnitLease{this,
                                    loading_unit_id,
                                    snapshot_data,
                                    snapshot_data_size,
                                    snapshot_instructions,
                                    snapshot_instructions_size,
                                    unmap_callback_};

  FlutterDartDeferredLibrary library = {};
  library.struct_size = sizeof(FlutterDartDeferredLibrary);
  library.loading_unit_id = loading_unit_id;
  library.snapshot_data = snapshot_data;
  library.snapshot_data_size = snapshot_data_size;
  library.snapshot_instructions = snapshot_instructions;
  library.snapshot_instructions_size = snapshot_instructions_size;
  library.user_data = lease;
  library.destruction_callback =
      &AndroidDeferredLibraryLoader::OnReleaseMappedUnitLease;

  if (embedder_api_.LoadDartDeferredLibrary(engine, &library) != kSuccess) {
    OnReleaseMappedUnitLease(lease);
    return false;
  }

  return true;
}

size_t AndroidDeferredLibraryLoader::GetActiveMappedUnitCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_mapped_units_;
}

void AndroidDeferredLibraryLoader::OnReleaseMappedUnitLease(void* user_data) {
  TRACE_EVENT0("flutter",
               "AndroidDeferredLibraryLoader::OnReleaseMappedUnitLease");
  auto* lease = static_cast<MappedUnitLease*>(user_data);
  if (lease == nullptr) {
    return;
  }
  if (lease->unmap_callback) {
    lease->unmap_callback(
        lease->loading_unit_id, lease->snapshot_data, lease->snapshot_data_size,
        lease->snapshot_instructions, lease->snapshot_instructions_size);
  }
  if (lease->owner != nullptr) {
    std::lock_guard<std::mutex> lock(lease->owner->mutex_);
    if (lease->owner->active_mapped_units_ > 0) {
      lease->owner->active_mapped_units_--;
    }
  }
  delete lease;
}

}  // namespace flutter
