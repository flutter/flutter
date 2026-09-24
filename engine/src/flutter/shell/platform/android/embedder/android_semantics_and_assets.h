// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SEMANTICS_AND_ASSETS_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SEMANTICS_AND_ASSETS_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#if defined(__ANDROID__)
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#else
struct AAssetManager;
typedef struct AAssetManager AAssetManager;
#endif

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      In-place `FlutterSemanticsUpdate2` coordinator and action
///             dispatcher for Android Accessibility
///             (`AccessibilityBridge.java`) (RFC 410.0000, ADR-0009).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`.
///
class AndroidSemanticsBridge {
 public:
  struct SerializedSemanticsBatch {
    FlutterViewId view_id = 0;
    size_t node_count = 0;
    size_t custom_action_count = 0;
    std::vector<int32_t> node_ids;
    std::vector<int32_t> action_ids;
  };

  AndroidSemanticsBridge(std::shared_ptr<JniDelegate> jni_delegate,
                         const FlutterEngineProcTable& proc_table);

  ~AndroidSemanticsBridge();

  /// Enables or disables semantics tree updates via
  /// `embedder_api_.UpdateSemanticsEnabled`.
  bool SetSemanticsEnabled(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                           bool enabled);

  /// Dispatches an Android accessibility action to the engine via
  /// `embedder_api_.DispatchSemanticsAction`.
  bool DispatchSemanticsAction(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                               uint64_t node_id,
                               FlutterSemanticsAction action,
                               const uint8_t* data,
                               size_t data_length);

  /// Processes an in-place `FlutterSemanticsUpdate2` batch from the engine.
  void HandleSemanticsUpdate2(const FlutterSemanticsUpdate2* update);

  /// Static trampoline suitable for
  /// `FlutterProjectArgs.update_semantics_callback2`.
  static void OnSemanticsUpdate2Callback(const FlutterSemanticsUpdate2* update,
                                         void* user_data);

  bool GetLastBatchForView(FlutterViewId view_id,
                           SerializedSemanticsBatch* out_batch) const;

 private:
  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};

  mutable std::mutex mutex_;
  std::unordered_map<FlutterViewId, SerializedSemanticsBatch> last_batches_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSemanticsBridge);
};

//------------------------------------------------------------------------------
/// @brief      Manages zero-copy memory-mapped (`mmap` / `AAssetManager`)
///             split-APK Dart deferred library loading units
///             (`FlutterDartDeferredLibrary`) (RFC 410.0000, ADR-0009).
///
///             Enforces the strict zero-copy memory contract: `snapshot_data`
///             and `snapshot_instructions` mappings remain pinned until the
///             Dart VM invokes
///             `FlutterDartDeferredLibrary.destruction_callback` (or
///             immediately unmapped if `LoadDartDeferredLibrary` fails).
///
class AndroidDeferredLibraryLoader {
 public:
  using UnmapFn = std::function<void(intptr_t loading_unit_id,
                                     const uint8_t* snapshot_data,
                                     size_t snapshot_data_size,
                                     const uint8_t* snapshot_instructions,
                                     size_t snapshot_instructions_size)>;

  explicit AndroidDeferredLibraryLoader(
      const FlutterEngineProcTable& proc_table,
      UnmapFn unmap_callback = nullptr);

  ~AndroidDeferredLibraryLoader();

  /// Loads a memory-mapped deferred library into `engine` via
  /// `embedder_api_.LoadDartDeferredLibrary` and binds `unmap_callback_` to
  /// `FlutterDartDeferredLibrary.destruction_callback`.
  bool LoadMappedDeferredLibrary(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 intptr_t loading_unit_id,
                                 const uint8_t* snapshot_data,
                                 size_t snapshot_data_size,
                                 const uint8_t* snapshot_instructions,
                                 size_t snapshot_instructions_size);

  size_t GetActiveMappedUnitCount() const;

 private:
  struct MappedUnitLease {
    AndroidDeferredLibraryLoader* owner = nullptr;
    intptr_t loading_unit_id = 0;
    const uint8_t* snapshot_data = nullptr;
    size_t snapshot_data_size = 0;
    const uint8_t* snapshot_instructions = nullptr;
    size_t snapshot_instructions_size = 0;
    UnmapFn unmap_callback;
  };

  static void OnReleaseMappedUnitLease(void* user_data);

  FlutterEngineProcTable embedder_api_ = {};
  UnmapFn unmap_callback_;

  mutable std::mutex mutex_;
  size_t active_mapped_units_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidDeferredLibraryLoader);
};

//------------------------------------------------------------------------------
/// @brief      Direct NDK `AAssetManager` asset resolver for the Flutter
///             Embedder C-API (RFC 410.0000, ADR-0009).
///
///             Resolves flutter assets directly from the APK package using
///             `AAssetManager` with fallback paths (`flutter_assets/`).
///             Supports a pluggable `AssetFinder` delegate for host Linux x64
///             compilation and unit testing under
///             `FLUTTER_ENGINE_NO_PROTOTYPES` and `check_includes = true`.
///
class AndroidAssetResolver {
 public:
  using AssetFinder = std::function<bool(const std::string& name,
                                         const uint8_t** out_data,
                                         size_t* out_size,
                                         void** out_baton,
                                         VoidCallback* out_free)>;

  AndroidAssetResolver(AAssetManager* asset_manager, std::string directory);
  explicit AndroidAssetResolver(AssetFinder test_finder);
  ~AndroidAssetResolver();

  FlutterAssetResolver ToFlutterAssetResolver() const;

  static FlutterAssetResolver CreateFlutterAssetResolver(
      AAssetManager* asset_manager,
      std::string directory);

  static std::string NormalizeAssetPath(const std::string& dir,
                                        const std::string& asset);

  bool IsValid() const;

 private:
  struct Context {
    AAssetManager* asset_manager = nullptr;
    std::string directory;
    AssetFinder test_finder = nullptr;
  };

  static bool FindAssetCallback(void* user_data,
                                const char* asset_name,
                                FlutterAsset* asset_out);
  static bool IsValidCallback(void* user_data);
  static bool IsValidAfterChangeCallback(void* user_data);
  static void DestructionCallback(void* user_data);

  AAssetManager* asset_manager_ = nullptr;
  std::string directory_;
  AssetFinder test_finder_ = nullptr;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SEMANTICS_AND_ASSETS_H_
