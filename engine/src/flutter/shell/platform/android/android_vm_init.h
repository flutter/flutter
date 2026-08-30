// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Minimum Android API level required for Impeller autoselection.
constexpr int kMinimumAndroidApiLevelForImpeller = 29;

/// @brief VM initialization arguments and configuration parameters provided
/// from the Android platform / Java embedder layer.
struct AndroidVMArgs {
  /// Command-line argument strings passed to the engine (e.g. from FlutterJNI).
  std::vector<std::string> command_line_args;

  /// Path to the application kernel snapshot or dill asset (debug/JIT).
  std::string kernel_path;

  /// Path to the application's persistent storage directory (for callback
  /// cache).
  std::string app_storage_path;

  /// Path to the engine caches directory (for persistent shader cache).
  std::string engine_caches_path;

  /// Path to the `icudtl.dat` file or ICU asset directory.
  std::string icu_data_path;

  /// Path to the ELF AOT shared library (e.g., `libapp.so`).
  std::string aot_library_path;

  /// VM snapshot data buffer (AOT).
  const uint8_t* aot_vm_snapshot_data = nullptr;
  size_t aot_vm_snapshot_data_size = 0;

  /// VM snapshot instructions buffer (AOT).
  const uint8_t* aot_vm_snapshot_instructions = nullptr;
  size_t aot_vm_snapshot_instructions_size = 0;

  /// Isolate snapshot data buffer (AOT).
  const uint8_t* aot_isolate_snapshot_data = nullptr;
  size_t aot_isolate_snapshot_data_size = 0;

  /// Isolate snapshot instructions buffer (AOT).
  const uint8_t* aot_isolate_snapshot_instructions = nullptr;
  size_t aot_isolate_snapshot_instructions_size = 0;

  /// Android device initialization start timestamp in milliseconds.
  int64_t init_time_millis = 0;

  /// Target Android device API level (e.g. 29, 34).
  int32_t api_level = 0;

  /// Whether the persistent cache should be opened in read-only mode.
  bool is_persistent_cache_read_only = false;

  /// Old generation heap size limit in MB (-1 for default, 0 for unlimited).
  int64_t dart_old_gen_heap_size = -1;

  /// Tag string used for application log messages.
  std::string log_tag = "flutter";

  /// Requested rendering backend override (e.g. "vulkan", "opengles").
  std::string requested_rendering_backend;

  /// Whether Impeller is enabled.
  bool enable_impeller = true;

  /// Whether software rendering fallback is requested.
  bool enable_software_rendering = false;

  /// Whether systrace tracing is enabled.
  bool trace_systrace = false;

  /// Initial VM service URI (if available).
  std::string vm_service_uri;

  bool operator==(const AndroidVMArgs& other) const {
    return command_line_args == other.command_line_args &&
           kernel_path == other.kernel_path &&
           app_storage_path == other.app_storage_path &&
           engine_caches_path == other.engine_caches_path &&
           icu_data_path == other.icu_data_path &&
           aot_library_path == other.aot_library_path &&
           aot_vm_snapshot_data == other.aot_vm_snapshot_data &&
           aot_vm_snapshot_data_size == other.aot_vm_snapshot_data_size &&
           aot_vm_snapshot_instructions == other.aot_vm_snapshot_instructions &&
           aot_vm_snapshot_instructions_size ==
               other.aot_vm_snapshot_instructions_size &&
           aot_isolate_snapshot_data == other.aot_isolate_snapshot_data &&
           aot_isolate_snapshot_data_size ==
               other.aot_isolate_snapshot_data_size &&
           aot_isolate_snapshot_instructions ==
               other.aot_isolate_snapshot_instructions &&
           aot_isolate_snapshot_instructions_size ==
               other.aot_isolate_snapshot_instructions_size &&
           init_time_millis == other.init_time_millis &&
           api_level == other.api_level &&
           is_persistent_cache_read_only ==
               other.is_persistent_cache_read_only &&
           dart_old_gen_heap_size == other.dart_old_gen_heap_size &&
           log_tag == other.log_tag &&
           requested_rendering_backend == other.requested_rendering_backend &&
           enable_impeller == other.enable_impeller &&
           enable_software_rendering == other.enable_software_rendering &&
           trace_systrace == other.trace_systrace &&
           vm_service_uri == other.vm_service_uri;
  }
};

/// @brief Determines the appropriate rendering API for the Android device.
AndroidRenderingAPI SelectRenderingAPI(const AndroidVMArgs& args,
                                       bool is_vivante = false);

/// @brief Abstract interface for font collection prefetching.
///
/// Decouples font prefetching from internal Skia/UI dependencies to adhere to
/// GN quarantine rules.
class FontCollectionProvider {
 public:
  virtual ~FontCollectionProvider() = default;

  /// @brief Prefetches the default font manager / collection.
  virtual bool PrefetchDefaultFontManager() = 0;

  /// @brief Checks whether font prefetching was initiated.
  virtual bool IsPrefetched() const = 0;

  /// @brief Returns the count of font prefetch invocations.
  virtual size_t GetPrefetchCount() const = 0;
};

/// @brief Default production font collection provider.
class DefaultFontCollectionProvider : public FontCollectionProvider {
 public:
  explicit DefaultFontCollectionProvider(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr);
  ~DefaultFontCollectionProvider() override;

  bool PrefetchDefaultFontManager() override;
  bool IsPrefetched() const override;
  size_t GetPrefetchCount() const override;

 private:
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::atomic<bool> is_prefetched_{false};
  std::atomic<size_t> prefetch_count_{0};

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultFontCollectionProvider);
};

/// @brief In-memory mock font collection provider for unit testing.
class InMemoryFontCollectionProvider : public FontCollectionProvider {
 public:
  InMemoryFontCollectionProvider();
  ~InMemoryFontCollectionProvider() override;

  void SetResult(bool result);
  void Reset();

  bool PrefetchDefaultFontManager() override;
  bool IsPrefetched() const override;
  size_t GetPrefetchCount() const override;

 private:
  mutable std::mutex mutex_;
  bool result_ = true;
  bool is_prefetched_ = false;
  size_t prefetch_count_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryFontCollectionProvider);
};

/// @brief Abstract interface for AOT snapshot creation and collection.
class AndroidAOTProvider {
 public:
  virtual ~AndroidAOTProvider() = default;

  /// @brief Creates AOT data structure for launching in AOT mode.
  virtual FlutterEngineResult CreateAOTData(
      const FlutterEngineAOTDataSource* source,
      FlutterEngineAOTData* data_out) = 0;

  /// @brief Collects/releases AOT data structure.
  virtual FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) = 0;
};

/// @brief Default production AOT provider that calls the C-API embedder.
class DefaultAndroidAOTProvider : public AndroidAOTProvider {
 public:
  DefaultAndroidAOTProvider();
  ~DefaultAndroidAOTProvider() override;

  FlutterEngineResult CreateAOTData(const FlutterEngineAOTDataSource* source,
                                    FlutterEngineAOTData* data_out) override;

  FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidAOTProvider);
};

/// @brief In-memory mock AOT provider for unit testing without ELF files.
class InMemoryAndroidAOTProvider : public AndroidAOTProvider {
 public:
  InMemoryAndroidAOTProvider();
  ~InMemoryAndroidAOTProvider() override;

  void SetCreateResult(FlutterEngineResult result);
  void SetCollectResult(FlutterEngineResult result);
  size_t GetCreateCount() const;
  size_t GetCollectCount() const;
  std::string GetLastElfPath() const;
  void Reset();

  FlutterEngineResult CreateAOTData(const FlutterEngineAOTDataSource* source,
                                    FlutterEngineAOTData* data_out) override;

  FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) override;

 private:
  mutable std::mutex mutex_;
  FlutterEngineResult create_result_ = kSuccess;
  FlutterEngineResult collect_result_ = kSuccess;
  size_t create_count_ = 0;
  size_t collect_count_ = 0;
  std::string last_elf_path_;
  uintptr_t next_mock_handle_ = 0x1000;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidAOTProvider);
};

/// @brief Holds and manages memory lifetimes of C-API FlutterProjectArgs.
class AndroidProjectArgsHolder {
 public:
  AndroidProjectArgsHolder();
  ~AndroidProjectArgsHolder();

  /// @brief Populates FlutterProjectArgs from AndroidVMArgs and components.
  void Populate(const AndroidVMArgs& args,
                FlutterEngineAOTData aot_data = nullptr,
                void* user_data = nullptr);

  /// @brief Returns the populated FlutterProjectArgs pointer.
  const FlutterProjectArgs* GetProjectArgs() const;

  /// @brief Returns a reference to mutable FlutterProjectArgs for
  /// customization.
  FlutterProjectArgs& GetMutableProjectArgs();

  /// @brief Returns stored argv string copies.
  const std::vector<std::string>& GetArgvStrings() const;

 private:
  FlutterProjectArgs project_args_{};
  std::vector<std::string> argv_strings_;
  std::vector<const char*> argv_ptrs_;
  std::string assets_path_;
  std::string icu_data_path_;
  std::string persistent_cache_path_;
  std::string log_tag_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidProjectArgsHolder);
};

/// @brief Coordinates global VM startup, AOT data mapping, font prefetching,
/// and FlutterProjectArgs configuration.
class AndroidVMInit {
 public:
  explicit AndroidVMInit(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr,
      std::shared_ptr<FontCollectionProvider> font_provider = nullptr,
      std::shared_ptr<AndroidAOTProvider> aot_provider = nullptr);
  virtual ~AndroidVMInit();

  /// @brief Initializes the global VM settings and configurations.
  bool Init(const AndroidVMArgs& args);

  /// @brief Prefetches the default font collection.
  bool PrefetchDefaultFontManager();

  /// @brief Updates the VM service URI and notifies JVM.
  bool SetVmServiceUri(const std::string& uri);

  /// @brief Returns the last recorded VM service URI.
  std::string GetVmServiceUri() const;

  /// @brief Returns true if Init has been executed successfully.
  bool IsInitialized() const;

  /// @brief Returns current AndroidVMArgs if initialized.
  std::optional<AndroidVMArgs> GetVMArgs() const;

  /// @brief Returns the selected AndroidRenderingAPI.
  AndroidRenderingAPI GetSelectedRenderingAPI() const;

  /// @brief Returns populated FlutterProjectArgs pointer (valid after Init).
  const FlutterProjectArgs* GetProjectArgs() const;

  /// @brief Creates AOT data using the managed AOT provider.
  FlutterEngineResult CreateAOTData(const FlutterEngineAOTDataSource* source,
                                    FlutterEngineAOTData* data_out);

  /// @brief Collects AOT data using the managed AOT provider.
  FlutterEngineResult CollectAOTData(FlutterEngineAOTData data);

  /// @brief Returns the FontCollectionProvider instance.
  std::shared_ptr<FontCollectionProvider> GetFontCollectionProvider() const;

  /// @brief Sets or replaces the FontCollectionProvider.
  void SetFontCollectionProvider(
      std::shared_ptr<FontCollectionProvider> provider);

  /// @brief Returns the AndroidAOTProvider instance.
  std::shared_ptr<AndroidAOTProvider> GetAOTProvider() const;

  /// @brief Sets or replaces the AndroidAOTProvider.
  void SetAOTProvider(std::shared_ptr<AndroidAOTProvider> provider);

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<FontCollectionProvider> font_provider_;
  std::shared_ptr<AndroidAOTProvider> aot_provider_;

  mutable std::mutex mutex_;
  bool initialized_ = false;
  AndroidVMArgs vm_args_;
  AndroidRenderingAPI rendering_api_ = AndroidRenderingAPI::kSkiaOpenGLES;
  std::string vm_service_uri_;
  FlutterEngineAOTData aot_data_ = nullptr;
  std::unique_ptr<AndroidProjectArgsHolder> project_args_holder_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidVMInit);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_
