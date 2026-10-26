// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_

#include <jni.h>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "flutter/common/vulkan_driver_info.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Minimum Android API level required for Impeller autoselection.
constexpr int kMinimumAndroidApiLevelForImpeller = 29;

/// @brief Minimum Android API level required for SurfaceControl / HCPP
/// (Android 14 / API 34).
constexpr int kMinimumAndroidApiLevelForSurfaceControl = 34;

/// @brief Default unset value for Dart old generation heap size in MB.
constexpr int64_t kDefaultDartOldGenHeapSize = -1;

/// @brief Parses SurfaceControl and HCPP flags from a single command-line
/// argument.
std::optional<bool> ParseHcppFlag(std::string_view arg);

/// @brief Parses merged platform and UI thread flags from a single command-line
/// argument.
std::optional<bool> ParseMergedPlatformUIThreadFlag(std::string_view arg);

/// @brief Synthesizes and normalizes command-line arguments from Android
/// initialization arguments.
std::vector<std::string> SynthesizeCommandLineArgs(
    const std::vector<std::string>& raw_args,
    bool enable_surface_control = false,
    bool disable_service_origin_check = false);

/// @brief VM initialization arguments and configuration parameters provided
/// from the Android platform / Java embedder layer.
struct AndroidVMArgs {
  /// Command-line argument strings passed to the engine (e.g. from FlutterJNI).
  std::vector<std::string> command_line_args;

  /// Path to the Flutter assets directory containing project assets.
  std::string assets_path;

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
  int64_t dart_old_gen_heap_size = kDefaultDartOldGenHeapSize;

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

  /// Whether SurfaceControl (HC++) is enabled.
  bool enable_surface_control = false;

  /// Whether platform and UI threads are merged.
  bool merged_platform_ui_thread = true;

  /// Whether wide gamut color spaces are enabled.
  bool enable_wide_gamut = false;

  /// Initial VM service URI (if available).
  std::string vm_service_uri;

  bool operator==(const AndroidVMArgs& other) const {
    return command_line_args == other.command_line_args &&
           assets_path == other.assets_path &&
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
           enable_surface_control == other.enable_surface_control &&
           merged_platform_ui_thread == other.merged_platform_ui_thread &&
           enable_wide_gamut == other.enable_wide_gamut &&
           vm_service_uri == other.vm_service_uri;
  }

  bool operator!=(const AndroidVMArgs& other) const {
    return !(*this == other);
  }
};

/// @brief Parses raw command-line arguments into an AndroidVMArgs struct.
AndroidVMArgs ParseCommandLineIntoVMArgs(
    const std::vector<std::string>& raw_args,
    const std::string& kernel_path = "",
    const std::string& app_storage_path = "",
    const std::string& engine_caches_path = "",
    int64_t init_time_millis = 0,
    int32_t api_level = 0);

/// @brief Determines the appropriate rendering API for the Android device.
AndroidRenderingAPI SelectRenderingAPI(
    const AndroidVMArgs& args,
    std::optional<bool> is_vivante = std::nullopt,
    const std::optional<VulkanDriverInfo>& vulkan_driver_info = std::nullopt,
    bool is_release_build =
#ifdef FLUTTER_RELEASE
        true
#else
        false
#endif
);

/// @brief Determines whether SurfaceControl / HCPP is supported for the given
/// VM arguments and resolved rendering API.
bool ShouldEnableSurfaceControl(const AndroidVMArgs& args,
                                AndroidRenderingAPI rendering_api,
                                bool is_release_build =
#ifdef FLUTTER_RELEASE
                                    true
#else
                                    false
#endif
);

/// @brief Abstract interface for font collection prefetching via C-API.
class FontCollectionProvider {
 public:
  virtual ~FontCollectionProvider() = default;

  virtual bool PrefetchDefaultFontManager() = 0;
  virtual bool IsPrefetched() const = 0;
  virtual size_t GetPrefetchCount() const = 0;
};

/// @brief Default production font collection provider dispatching via
/// FlutterEngineProcTable::PrefetchDefaultFontManager.
class DefaultFontCollectionProvider : public FontCollectionProvider {
 public:
  explicit DefaultFontCollectionProvider(
      const FlutterEngineProcTable* proc_table = nullptr);
  ~DefaultFontCollectionProvider() override;

  bool PrefetchDefaultFontManager() override;
  bool IsPrefetched() const override;
  size_t GetPrefetchCount() const override;

 private:
  FlutterEngineProcTable proc_table_{};
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

  virtual FlutterEngineResult CreateAOTData(
      const FlutterEngineAOTDataSource* source,
      FlutterEngineAOTData* data_out) = 0;

  virtual FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) = 0;
};

/// @brief Default production AOT provider dispatching via
/// FlutterEngineProcTable.
class DefaultAndroidAOTProvider : public AndroidAOTProvider {
 public:
  explicit DefaultAndroidAOTProvider(
      const FlutterEngineProcTable* proc_table = nullptr);
  ~DefaultAndroidAOTProvider() override;

  FlutterEngineResult CreateAOTData(const FlutterEngineAOTDataSource* source,
                                    FlutterEngineAOTData* data_out) override;

  FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) override;

 private:
  FlutterEngineProcTable proc_table_{};

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidAOTProvider);
};

/// @brief In-memory mock AOT provider for unit testing without ELF files.
class InMemoryAndroidAOTProvider : public AndroidAOTProvider {
 public:
  // Initial synthetic handle address for mock AOT data pointers.
  static constexpr uintptr_t kInitialMockHandleAddress = 0x1000;

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
  uintptr_t next_mock_handle_ = kInitialMockHandleAddress;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidAOTProvider);
};

/// @brief Holds and manages memory lifetimes of C-API FlutterProjectArgs.
class AndroidProjectArgsHolder {
 public:
  AndroidProjectArgsHolder();
  ~AndroidProjectArgsHolder();

  void Populate(const AndroidVMArgs& args,
                FlutterEngineAOTData aot_data = nullptr,
                void* user_data = nullptr);

  const FlutterProjectArgs* GetProjectArgs() const;
  FlutterProjectArgs& GetMutableProjectArgs();
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
/// and FlutterProjectArgs configuration via FlutterEngineProcTable.
class AndroidVMInit {
 public:
  explicit AndroidVMInit(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr,
      std::shared_ptr<FontCollectionProvider> font_provider = nullptr,
      std::shared_ptr<AndroidAOTProvider> aot_provider = nullptr,
      const FlutterEngineProcTable* proc_table = nullptr);
  virtual ~AndroidVMInit();

  /// @brief Static JNI entry point invoked by FlutterJNI.nativeInit via
  /// JniDelegate::Init.
  static bool Init(JNIEnv* env,
                   jclass clazz,
                   jobject context,
                   const std::vector<std::string>& args,
                   const std::string& kernel_path,
                   const std::string& app_storage_path,
                   const std::string& engine_caches_path,
                   int64_t init_time_millis,
                   int api_level,
                   const FlutterEngineProcTable* proc_table = nullptr);

  /// @brief Static JNI entry point invoked by
  /// FlutterJNI.nativePrefetchDefaultFontManager.
  static bool PrefetchDefaultFontManager(
      const FlutterEngineProcTable* proc_table = nullptr);

  /// @brief Static JNI entry point invoked by
  /// FlutterJNI.nativeGetIsSoftwareRenderingEnabled.
  static bool GetIsSoftwareRenderingEnabled();

  /// @brief Static C-API callback for
  /// FlutterProjectArgs::vm_service_uri_callback.
  static void OnVmServiceUriCallback(const FlutterVMServiceUriInfo* info,
                                     void* user_data);

  /// @brief Registers a callback to be notified when the Dart VM service URI
  /// becomes available.
  static void RegisterVmServiceUriCallback(
      std::function<void(const std::string&)> callback);

  /// @brief Sets the process-global VM initialization arguments.
  static void SetGlobalVMArgs(const AndroidVMArgs& args);

  /// @brief Returns the process-global VM initialization arguments if set.
  static std::optional<AndroidVMArgs> GetGlobalVMArgs();

  /// @brief Resets process-global VM initialization state for unit testing.
  static void ResetGlobalStateForTesting();

  /// @brief Initializes this VMInit instance with the given AndroidVMArgs.
  bool Init(
      const AndroidVMArgs& args,
      const std::optional<VulkanDriverInfo>& vulkan_driver_info = std::nullopt);

  /// @brief Prefetches the default font collection on this instance.
  bool PrefetchFontManager();

  /// @brief Checks whether the engine runs AOT compiled Dart code via
  /// FlutterEngineProcTable::RunsAOTCompiledDartCode.
  bool RunsAOTCompiledDartCode() const;

  /// @brief Updates the VM service URI and notifies JVM if attached.
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

  std::shared_ptr<FontCollectionProvider> GetFontCollectionProvider() const;
  void SetFontCollectionProvider(
      std::shared_ptr<FontCollectionProvider> provider);

  std::shared_ptr<AndroidAOTProvider> GetAOTProvider() const;
  void SetAOTProvider(std::shared_ptr<AndroidAOTProvider> provider);

  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  FlutterEngineProcTable proc_table_{};
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<FontCollectionProvider> font_provider_;
  std::shared_ptr<AndroidAOTProvider> aot_provider_;

  mutable std::mutex mutex_;
  bool initialized_ = false;
  AndroidVMArgs vm_args_;
  AndroidRenderingAPI rendering_api_ = AndroidRenderingAPI::kImpellerAutoselect;
  std::string vm_service_uri_;
  FlutterEngineAOTData aot_data_ = nullptr;
  std::unique_ptr<AndroidProjectArgsHolder> project_args_holder_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidVMInit);
};

using AndroidVmInit = AndroidVMInit;

}  // namespace android

using AndroidVMArgs = android::AndroidVMArgs;
using AndroidProjectArgsHolder = android::AndroidProjectArgsHolder;
using FontCollectionProvider = android::FontCollectionProvider;
using DefaultFontCollectionProvider = android::DefaultFontCollectionProvider;
using InMemoryFontCollectionProvider = android::InMemoryFontCollectionProvider;
using AndroidAOTProvider = android::AndroidAOTProvider;
using DefaultAndroidAOTProvider = android::DefaultAndroidAOTProvider;
using InMemoryAndroidAOTProvider = android::InMemoryAndroidAOTProvider;
using AndroidVMInit = android::AndroidVMInit;
using AndroidVmInit = android::AndroidVMInit;
using android::ParseCommandLineIntoVMArgs;
using android::ParseHcppFlag;
using android::ParseMergedPlatformUIThreadFlag;
using android::SelectRenderingAPI;
using android::ShouldEnableSurfaceControl;
using android::SynthesizeCommandLineArgs;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VM_INIT_H_
