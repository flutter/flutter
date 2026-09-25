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

//------------------------------------------------------------------------------
// AndroidAssetResolver
//------------------------------------------------------------------------------

AndroidAssetResolver::AndroidAssetResolver(AAssetManager* asset_manager,
                                           std::string directory)
    : asset_manager_(asset_manager), directory_(std::move(directory)) {}

AndroidAssetResolver::AndroidAssetResolver(AssetFinder test_finder)
    : test_finder_(std::move(test_finder)) {}

AndroidAssetResolver::~AndroidAssetResolver() = default;

bool AndroidAssetResolver::IsValid() const {
  return asset_manager_ != nullptr || test_finder_ != nullptr;
}

std::string AndroidAssetResolver::NormalizeAssetPath(const std::string& dir,
                                                     const std::string& asset) {
  std::string clean_asset = asset;
  while (!clean_asset.empty() && clean_asset.front() == '/') {
    clean_asset.erase(0, 1);
  }
  std::string clean_dir = dir;
  while (!clean_dir.empty() && clean_dir.back() == '/') {
    clean_dir.pop_back();
  }
  while (!clean_dir.empty() && clean_dir.front() == '/') {
    clean_dir.erase(0, 1);
  }
  if (clean_dir.empty()) {
    return clean_asset;
  }
  if (clean_asset.rfind(clean_dir + "/", 0) == 0) {
    return clean_asset;
  }
  return clean_dir + "/" + clean_asset;
}

bool AndroidAssetResolver::FindAssetCallback(void* user_data,
                                             const char* asset_name,
                                             FlutterAsset* asset_out) {
  if (user_data == nullptr || asset_name == nullptr || asset_out == nullptr) {
    return false;
  }
  auto* ctx = static_cast<Context*>(user_data);
  TRACE_EVENT1("flutter", "AndroidAssetResolver::FindAsset", "asset",
               asset_name);

  if (ctx->test_finder != nullptr) {
    const uint8_t* data = nullptr;
    size_t size = 0;
    void* baton = nullptr;
    VoidCallback free_cb = nullptr;
    if (!ctx->test_finder(asset_name, &data, &size, &baton, &free_cb)) {
      return false;
    }
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = data;
    asset_out->size = size;
    asset_out->user_data = baton;
    asset_out->asset_free_callback = free_cb;
    return true;
  }

#if defined(__ANDROID__)
  if (ctx->asset_manager == nullptr) {
    return false;
  }
  std::string full_path = NormalizeAssetPath(ctx->directory, asset_name);
  AAsset* asset = AAssetManager_open(ctx->asset_manager, full_path.c_str(),
                                     AASSET_MODE_BUFFER);
  if (asset == nullptr) {
    std::string clean_asset = asset_name;
    while (!clean_asset.empty() && clean_asset.front() == '/') {
      clean_asset.erase(0, 1);
    }
    if (full_path.rfind("flutter_assets/", 0) != 0) {
      std::string fallback_path = "flutter_assets/" + clean_asset;
      asset = AAssetManager_open(ctx->asset_manager, fallback_path.c_str(),
                                 AASSET_MODE_BUFFER);
    } else if (clean_asset.rfind("flutter_assets/", 0) == 0 &&
               clean_asset.length() > 15) {
      std::string stripped = clean_asset.substr(15);
      asset = AAssetManager_open(ctx->asset_manager, stripped.c_str(),
                                 AASSET_MODE_BUFFER);
    }
    if (asset == nullptr && full_path != clean_asset) {
      asset = AAssetManager_open(ctx->asset_manager, clean_asset.c_str(),
                                 AASSET_MODE_BUFFER);
    }
  }
  if (asset == nullptr) {
    return false;
  }
  const void* buffer = AAsset_getBuffer(asset);
  off_t length = AAsset_getLength(asset);
  if (length < 0 || (buffer == nullptr && length > 0)) {
    AAsset_close(asset);
    return false;
  }
  asset_out->struct_size = sizeof(FlutterAsset);
  asset_out->data = static_cast<const uint8_t*>(buffer);
  asset_out->size = static_cast<size_t>(length);
  asset_out->user_data = asset;
  asset_out->asset_free_callback = [](void* user_data) {
    if (user_data != nullptr) {
      AAsset_close(static_cast<AAsset*>(user_data));
    }
  };
  return true;
#else
  return false;
#endif
}

bool AndroidAssetResolver::IsValidCallback(void* user_data) {
  return user_data != nullptr;
}

bool AndroidAssetResolver::IsValidAfterChangeCallback(void* user_data) {
  return true;
}

void AndroidAssetResolver::DestructionCallback(void* user_data) {
  if (user_data != nullptr) {
    delete static_cast<Context*>(user_data);
  }
}

FlutterAssetResolver AndroidAssetResolver::CreateFlutterAssetResolver(
    AAssetManager* asset_manager,
    std::string directory) {
  auto* ctx = new Context{asset_manager, std::move(directory), nullptr};
  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = ctx;
  resolver.find_asset_callback = &AndroidAssetResolver::FindAssetCallback;
  resolver.is_valid_callback = &AndroidAssetResolver::IsValidCallback;
  resolver.is_valid_after_change_callback =
      &AndroidAssetResolver::IsValidAfterChangeCallback;
  resolver.destruction_callback = &AndroidAssetResolver::DestructionCallback;
  return resolver;
}

FlutterAssetResolver AndroidAssetResolver::ToFlutterAssetResolver() const {
  auto* ctx = new Context{asset_manager_, directory_, test_finder_};
  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = ctx;
  resolver.find_asset_callback = &AndroidAssetResolver::FindAssetCallback;
  resolver.is_valid_callback = &AndroidAssetResolver::IsValidCallback;
  resolver.is_valid_after_change_callback =
      &AndroidAssetResolver::IsValidAfterChangeCallback;
  resolver.destruction_callback = &AndroidAssetResolver::DestructionCallback;
  return resolver;
}

}  // namespace flutter
