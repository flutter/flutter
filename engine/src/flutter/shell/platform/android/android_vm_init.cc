// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_vm_init.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>

#include "flutter/fml/callback_cache.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/trace_event.h"

#if FML_OS_ANDROID
#include <android/api-level.h>
#include <android/log.h>
#include <sys/system_properties.h>
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/paths_android.h"
#endif

extern "C" __attribute__((weak)) FlutterEngineResult
FlutterEngineGetProcAddresses(FlutterEngineProcTable* table);

namespace flutter {
namespace android {

namespace {

using GetProcAddressesFn = FlutterEngineResult (*)(FlutterEngineProcTable*);

FlutterEngineProcTable ResolveDefaultProcTable() {
  FlutterEngineProcTable table{};
  table.struct_size = sizeof(FlutterEngineProcTable);
  if (&FlutterEngineGetProcAddresses != nullptr) {
    FlutterEngineGetProcAddresses(&table);
    return table;
  }
  auto self_lib = fml::NativeLibrary::CreateForCurrentProcess();
  if (self_lib) {
    auto get_procs = self_lib->ResolveFunction<GetProcAddressesFn>(
        "FlutterEngineGetProcAddresses");
    if (get_procs.has_value() && get_procs.value()) {
      get_procs.value()(&table);
    }
  }
  return table;
}

bool IsVivanteDevice() {
#if FML_OS_ANDROID
  char product_model[PROP_VALUE_MAX] = {};
  __system_property_get("ro.hardware.egl", product_model);
  return std::strcmp(product_model, "VIVANTE") == 0;
#else
  return false;
#endif
}

#if FML_OS_ANDROID
bool IsAndroidATraceEnabled() {
  auto lib = fml::NativeLibrary::Create("libandroid.so");
  if (lib) {
    auto fn = lib->ResolveFunction<bool (*)()>("ATrace_isEnabled");
    if (fn.has_value() && fn.value()) {
      return fn.value()();
    }
  }
  return false;
}
#endif

std::mutex g_global_vm_mutex;
std::optional<AndroidVMArgs> g_global_vm_args;
std::atomic<bool> g_software_rendering_enabled{false};
std::atomic<AndroidVMInit*> g_active_vm_init{nullptr};
std::function<void(const std::string&)> g_vm_service_uri_callback;
#if FML_OS_ANDROID
jclass g_vm_service_flutter_jni_class = nullptr;
jfieldID g_vm_service_uri_field = nullptr;
fml::RefPtr<fml::TaskRunner> g_vm_service_platform_runner;
#endif

constexpr std::string_view kBackendPrefix = "--impeller-backend=";
constexpr std::string_view kOldGenHeapPrefix = "--old-gen-heap-size=";
constexpr std::string_view kLogTagPrefix = "--log-tag=";

}  // namespace

std::optional<bool> ParseHcppFlag(std::string_view arg) {
  while (!arg.empty() && arg.front() == '-') {
    arg.remove_prefix(1);
  }
  if (arg == "enable-surface-control" || arg == "enable-surface-control=true" ||
      arg == "enable-surface-control=1" ||
      arg == "enable-hcpp-and-surface-control" ||
      arg == "enable-hcpp-and-surface-control=true" ||
      arg == "enable-hcpp-and-surface-control=1" || arg == "enable-hcpp" ||
      arg == "enable-hcpp=true" || arg == "enable-hcpp=1") {
    return true;
  }
  if (arg == "enable-surface-control=false" ||
      arg == "enable-surface-control=0" ||
      arg == "enable-hcpp-and-surface-control=false" ||
      arg == "enable-hcpp-and-surface-control=0" ||
      arg == "enable-hcpp=false" || arg == "enable-hcpp=0" ||
      arg == "no-enable-surface-control" ||
      arg == "no-enable-hcpp-and-surface-control" || arg == "no-enable-hcpp") {
    return false;
  }
  return std::nullopt;
}

std::optional<bool> ParseMergedPlatformUIThreadFlag(std::string_view arg) {
  if (arg == "--merged-platform-ui-thread" ||
      arg == "--merged-platform-ui-thread=true" ||
      arg == "--merged-platform-ui-thread=1" ||
      arg == "--merged-platform-ui-thread=enabled" ||
      arg == "--enable-merged-platform-ui-thread") {
    return true;
  }
  if (arg == "--merged-platform-ui-thread=false" ||
      arg == "--merged-platform-ui-thread=0" ||
      arg == "--merged-platform-ui-thread=disabled" ||
      arg == "--no-merged-platform-ui-thread" ||
      arg == "--disable-merged-platform-ui-thread" ||
      arg == "--no-enable-merged-platform-ui-thread") {
    return false;
  }
  return std::nullopt;
}

std::vector<std::string> SynthesizeCommandLineArgs(
    const std::vector<std::string>& raw_args,
    bool enable_surface_control,
    bool disable_service_origin_check) {
  std::vector<std::string> result = raw_args;
  bool has_hcpp_flag = false;
  bool has_origin_check_flag = false;
  for (const auto& arg : raw_args) {
    if (ParseHcppFlag(arg).has_value()) {
      has_hcpp_flag = true;
    }
    if (arg == "--disable-service-origin-check") {
      has_origin_check_flag = true;
    }
  }
  if (enable_surface_control && !has_hcpp_flag) {
    result.push_back("--enable-hcpp-and-surface-control=true");
  }
  if (disable_service_origin_check && !has_origin_check_flag) {
    result.push_back("--disable-service-origin-check");
  }
  return result;
}

AndroidVMArgs ParseCommandLineIntoVMArgs(
    const std::vector<std::string>& raw_args,
    const std::string& kernel_path,
    const std::string& app_storage_path,
    const std::string& engine_caches_path,
    int64_t init_time_millis,
    int32_t api_level) {
  AndroidVMArgs vm_args;
  vm_args.command_line_args = raw_args;
  vm_args.kernel_path = kernel_path;
  vm_args.app_storage_path = app_storage_path;
  vm_args.engine_caches_path = engine_caches_path;
  vm_args.init_time_millis = init_time_millis;
  vm_args.api_level = api_level;

  for (const auto& arg : raw_args) {
    if (arg == "--enable-software-rendering" ||
        arg == "--enable-software-rendering=true") {
      vm_args.enable_software_rendering = true;
      vm_args.enable_impeller = false;
    } else if (arg == "--enable-impeller" || arg == "--enable-impeller=true") {
      vm_args.enable_impeller = true;
    } else if (arg == "--enable-impeller=false" ||
               arg == "--no-enable-impeller") {
      vm_args.enable_impeller = false;
    } else if (arg == "--trace-systrace" || arg == "--trace-systrace=true") {
      vm_args.trace_systrace = true;
    } else if (arg == "--enable-wide-gamut" ||
               arg == "--enable-wide-gamut=true") {
      vm_args.enable_wide_gamut = true;
    } else if (arg.rfind(kBackendPrefix, 0) == 0) {
      vm_args.requested_rendering_backend = arg.substr(kBackendPrefix.length());
    } else if (arg.rfind(kOldGenHeapPrefix, 0) == 0) {
      std::string val_str = arg.substr(kOldGenHeapPrefix.length());
      char* end_ptr = nullptr;
      constexpr int kDecimalBase = 10;
      int64_t parsed = std::strtoll(val_str.c_str(), &end_ptr, kDecimalBase);
      if (end_ptr != val_str.c_str()) {
        vm_args.dart_old_gen_heap_size = parsed;
      }
    } else if (arg.find("--old_gen_heap_size=") != std::string::npos) {
      constexpr std::string_view kDartOldGenKey = "--old_gen_heap_size=";
      size_t pos = arg.find(kDartOldGenKey);
      std::string val_str = arg.substr(pos + kDartOldGenKey.length());
      char* end_ptr = nullptr;
      constexpr int kDecimalBase = 10;
      int64_t parsed = std::strtoll(val_str.c_str(), &end_ptr, kDecimalBase);
      if (end_ptr != val_str.c_str()) {
        vm_args.dart_old_gen_heap_size = parsed;
      }
    } else if (arg.rfind(kLogTagPrefix, 0) == 0) {
      vm_args.log_tag = arg.substr(kLogTagPrefix.length());
    } else {
      auto hcpp = ParseHcppFlag(arg);
      if (hcpp.has_value()) {
        vm_args.enable_surface_control = hcpp.value();
      }
      auto merged = ParseMergedPlatformUIThreadFlag(arg);
      if (merged.has_value()) {
        vm_args.merged_platform_ui_thread = merged.value();
      }
    }
  }
  return vm_args;
}

AndroidRenderingAPI SelectRenderingAPI(
    const AndroidVMArgs& args,
    std::optional<bool> is_vivante,
    const std::optional<VulkanDriverInfo>& vulkan_driver_info,
    bool is_release_build) {
  TRACE_EVENT0("flutter", "SelectRenderingAPI");
#if !SLIMPELLER
  if (args.enable_software_rendering) {
    if (args.enable_impeller) {
      FML_LOG(WARNING)
          << "Impeller does not support software rendering. Either disable "
             "software rendering or disable impeller.";
    }
    return AndroidRenderingAPI::kSoftware;
  }
#endif  // !SLIMPELLER

#ifndef FLUTTER_RELEASE
  if (!is_release_build) {
    if (args.requested_rendering_backend == "opengles" &&
        args.enable_impeller) {
      return AndroidRenderingAPI::kImpellerOpenGLES;
    }
    if (args.requested_rendering_backend == "vulkan" && args.enable_impeller) {
      return AndroidRenderingAPI::kImpellerVulkan;
    }
  }
#else
  (void)is_release_build;
#endif  // !FLUTTER_RELEASE

#if !SLIMPELLER
  bool vivante = is_vivante.value_or(IsVivanteDevice());
  if (args.enable_impeller &&
      args.api_level >= kMinimumAndroidApiLevelForImpeller && !vivante) {
    if (vulkan_driver_info.has_value()) {
      if (vulkan_driver_info->IsKnownBadDriver() ||
          vulkan_driver_info->IsEmulator()) {
        FML_LOG(INFO) << "Impeller Vulkan autoselect disabled on driver ("
                      << vulkan_driver_info->GetDriverName()
                      << "), falling back to OpenGLES.";
        return AndroidRenderingAPI::kImpellerOpenGLES;
      }
      return AndroidRenderingAPI::kImpellerVulkan;
    }
    return AndroidRenderingAPI::kImpellerAutoselect;
  }
  return AndroidRenderingAPI::kSkiaOpenGLES;
#else
  if (vulkan_driver_info.has_value()) {
    if (vulkan_driver_info->IsKnownBadDriver() ||
        vulkan_driver_info->IsEmulator()) {
      return AndroidRenderingAPI::kImpellerOpenGLES;
    }
    return AndroidRenderingAPI::kImpellerVulkan;
  }
  return AndroidRenderingAPI::kImpellerAutoselect;
#endif  // !SLIMPELLER
}

bool ShouldEnableSurfaceControl(const AndroidVMArgs& args,
                                AndroidRenderingAPI rendering_api,
                                bool is_release_build) {
  bool hcpp_enabled = args.enable_surface_control;
  for (const auto& raw_arg : args.command_line_args) {
    auto parsed = ParseHcppFlag(raw_arg);
    if (parsed.has_value()) {
      hcpp_enabled = parsed.value();
    }
  }
  if (!hcpp_enabled || !args.enable_impeller) {
    return false;
  }
#ifndef FLUTTER_RELEASE
  if (!is_release_build && args.requested_rendering_backend == "opengles") {
    return false;
  }
#else
  (void)is_release_build;
#endif  // !FLUTTER_RELEASE
  int32_t effective_api_level = args.api_level;
#if FML_OS_ANDROID
  if (effective_api_level <= 0) {
    effective_api_level = android_get_device_api_level();
  }
#else
  if (effective_api_level <= 0) {
    effective_api_level = kMinimumAndroidApiLevelForSurfaceControl;
  }
#endif
  if (effective_api_level < kMinimumAndroidApiLevelForSurfaceControl) {
    return false;
  }
  return rendering_api == AndroidRenderingAPI::kImpellerVulkan ||
         rendering_api == AndroidRenderingAPI::kImpellerAutoselect;
}

// ---------------------------------------------------------------------------
// DefaultFontCollectionProvider
// ---------------------------------------------------------------------------

DefaultFontCollectionProvider::DefaultFontCollectionProvider(
    const FlutterEngineProcTable* proc_table) {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::DefaultFontCollectionProvider");
  if (proc_table != nullptr) {
    proc_table_ = *proc_table;
  } else {
    proc_table_ = ResolveDefaultProcTable();
  }
}

DefaultFontCollectionProvider::~DefaultFontCollectionProvider() {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::~DefaultFontCollectionProvider");
}

bool DefaultFontCollectionProvider::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::PrefetchDefaultFontManager");
  if (proc_table_.PrefetchDefaultFontManager) {
    FlutterEngineResult result = proc_table_.PrefetchDefaultFontManager();
    if (result != kSuccess) {
      return false;
    }
  }
  is_prefetched_.store(true);
  prefetch_count_.fetch_add(1);
  return true;
}

bool DefaultFontCollectionProvider::IsPrefetched() const {
  return is_prefetched_.load();
}

size_t DefaultFontCollectionProvider::GetPrefetchCount() const {
  return prefetch_count_.load();
}

// ---------------------------------------------------------------------------
// InMemoryFontCollectionProvider
// ---------------------------------------------------------------------------

InMemoryFontCollectionProvider::InMemoryFontCollectionProvider() {
  TRACE_EVENT0(
      "flutter",
      "InMemoryFontCollectionProvider::InMemoryFontCollectionProvider");
}

InMemoryFontCollectionProvider::~InMemoryFontCollectionProvider() {
  TRACE_EVENT0(
      "flutter",
      "InMemoryFontCollectionProvider::~InMemoryFontCollectionProvider");
}

void InMemoryFontCollectionProvider::SetResult(bool result) {
  std::scoped_lock lock(mutex_);
  result_ = result;
}

void InMemoryFontCollectionProvider::Reset() {
  std::scoped_lock lock(mutex_);
  result_ = true;
  is_prefetched_ = false;
  prefetch_count_ = 0;
}

bool InMemoryFontCollectionProvider::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter",
               "InMemoryFontCollectionProvider::PrefetchDefaultFontManager");
  std::scoped_lock lock(mutex_);
  prefetch_count_++;
  if (result_) {
    is_prefetched_ = true;
    return true;
  }
  return false;
}

bool InMemoryFontCollectionProvider::IsPrefetched() const {
  std::scoped_lock lock(mutex_);
  return is_prefetched_;
}

size_t InMemoryFontCollectionProvider::GetPrefetchCount() const {
  std::scoped_lock lock(mutex_);
  return prefetch_count_;
}

// ---------------------------------------------------------------------------
// DefaultAndroidAOTProvider
// ---------------------------------------------------------------------------

DefaultAndroidAOTProvider::DefaultAndroidAOTProvider(
    const FlutterEngineProcTable* proc_table) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidAOTProvider::DefaultAndroidAOTProvider");
  if (proc_table != nullptr) {
    proc_table_ = *proc_table;
  } else {
    proc_table_ = ResolveDefaultProcTable();
  }
}

DefaultAndroidAOTProvider::~DefaultAndroidAOTProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidAOTProvider::~DefaultAndroidAOTProvider");
}

FlutterEngineResult DefaultAndroidAOTProvider::CreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) {
  TRACE_EVENT0("flutter", "DefaultAndroidAOTProvider::CreateAOTData");
  if (!source || !data_out) {
    return kInvalidArguments;
  }
  if (!proc_table_.CreateAOTData) {
    return kInternalInconsistency;
  }
  return proc_table_.CreateAOTData(source, data_out);
}

FlutterEngineResult DefaultAndroidAOTProvider::CollectAOTData(
    FlutterEngineAOTData data) {
  TRACE_EVENT0("flutter", "DefaultAndroidAOTProvider::CollectAOTData");
  if (!data) {
    return kSuccess;
  }
  if (!proc_table_.CollectAOTData) {
    return kInternalInconsistency;
  }
  return proc_table_.CollectAOTData(data);
}

// ---------------------------------------------------------------------------
// InMemoryAndroidAOTProvider
// ---------------------------------------------------------------------------

InMemoryAndroidAOTProvider::InMemoryAndroidAOTProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidAOTProvider::InMemoryAndroidAOTProvider");
}

InMemoryAndroidAOTProvider::~InMemoryAndroidAOTProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidAOTProvider::~InMemoryAndroidAOTProvider");
}

void InMemoryAndroidAOTProvider::SetCreateResult(FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  create_result_ = result;
}

void InMemoryAndroidAOTProvider::SetCollectResult(FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  collect_result_ = result;
}

size_t InMemoryAndroidAOTProvider::GetCreateCount() const {
  std::scoped_lock lock(mutex_);
  return create_count_;
}

size_t InMemoryAndroidAOTProvider::GetCollectCount() const {
  std::scoped_lock lock(mutex_);
  return collect_count_;
}

std::string InMemoryAndroidAOTProvider::GetLastElfPath() const {
  std::scoped_lock lock(mutex_);
  return last_elf_path_;
}

void InMemoryAndroidAOTProvider::Reset() {
  std::scoped_lock lock(mutex_);
  create_result_ = kSuccess;
  collect_result_ = kSuccess;
  create_count_ = 0;
  collect_count_ = 0;
  last_elf_path_.clear();
  next_mock_handle_ = kInitialMockHandleAddress;
}

FlutterEngineResult InMemoryAndroidAOTProvider::CreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) {
  TRACE_EVENT0("flutter", "InMemoryAndroidAOTProvider::CreateAOTData");
  if (!source || !data_out) {
    return kInvalidArguments;
  }
  std::scoped_lock lock(mutex_);
  create_count_++;
  if (source->type == kFlutterEngineAOTDataSourceTypeElfPath &&
      source->elf_path) {
    last_elf_path_ = source->elf_path;
  }
  if (create_result_ == kSuccess) {
    *data_out = reinterpret_cast<FlutterEngineAOTData>(next_mock_handle_++);
    return kSuccess;
  }
  return create_result_;
}

FlutterEngineResult InMemoryAndroidAOTProvider::CollectAOTData(
    FlutterEngineAOTData data) {
  TRACE_EVENT0("flutter", "InMemoryAndroidAOTProvider::CollectAOTData");
  if (!data) {
    return kSuccess;
  }
  std::scoped_lock lock(mutex_);
  collect_count_++;
  return collect_result_;
}

// ---------------------------------------------------------------------------
// AndroidProjectArgsHolder
// ---------------------------------------------------------------------------

AndroidProjectArgsHolder::AndroidProjectArgsHolder() {
  project_args_.struct_size = sizeof(FlutterProjectArgs);
}

AndroidProjectArgsHolder::~AndroidProjectArgsHolder() = default;

void AndroidProjectArgsHolder::Populate(const AndroidVMArgs& args,
                                        FlutterEngineAOTData aot_data,
                                        void* user_data) {
  TRACE_EVENT0("flutter", "AndroidProjectArgsHolder::Populate");
  (void)user_data;
  argv_strings_.clear();
  argv_ptrs_.clear();

  // Executable name must be the first entry in command_line_argv.
  argv_strings_.push_back("flutter");
  bool has_trace_systrace = false;
  for (const auto& arg : args.command_line_args) {
    if (arg == "--trace-systrace" || arg == "--trace-systrace=true") {
      has_trace_systrace = true;
    }
    argv_strings_.push_back(arg);
  }
  if (args.trace_systrace && !has_trace_systrace) {
    argv_strings_.push_back("--trace-systrace");
  }
  for (const auto& str : argv_strings_) {
    argv_ptrs_.push_back(str.c_str());
  }

  assets_path_ = args.assets_path;
  icu_data_path_ = args.icu_data_path;
  persistent_cache_path_ = args.engine_caches_path;
  log_tag_ = args.log_tag.empty() ? "flutter" : args.log_tag;

  std::memset(&project_args_, 0, sizeof(FlutterProjectArgs));
  project_args_.struct_size = sizeof(FlutterProjectArgs);
  project_args_.assets_path =
      assets_path_.empty() ? nullptr : assets_path_.c_str();
  project_args_.icu_data_path =
      icu_data_path_.empty() ? nullptr : icu_data_path_.c_str();
  project_args_.command_line_argc = static_cast<int>(argv_ptrs_.size());
  project_args_.command_line_argv =
      argv_ptrs_.empty() ? nullptr : argv_ptrs_.data();
  project_args_.persistent_cache_path =
      persistent_cache_path_.empty() ? nullptr : persistent_cache_path_.c_str();
  project_args_.is_persistent_cache_read_only =
      args.is_persistent_cache_read_only;
  project_args_.dart_old_gen_heap_size = args.dart_old_gen_heap_size;
  project_args_.log_tag = log_tag_.c_str();
  project_args_.aot_data = aot_data;
  project_args_.vm_snapshot_data = args.aot_vm_snapshot_data;
  project_args_.vm_snapshot_data_size = args.aot_vm_snapshot_data_size;
  project_args_.vm_snapshot_instructions = args.aot_vm_snapshot_instructions;
  project_args_.vm_snapshot_instructions_size =
      args.aot_vm_snapshot_instructions_size;
  project_args_.isolate_snapshot_data = args.aot_isolate_snapshot_data;
  project_args_.isolate_snapshot_data_size =
      args.aot_isolate_snapshot_data_size;
  project_args_.isolate_snapshot_instructions =
      args.aot_isolate_snapshot_instructions;
  project_args_.isolate_snapshot_instructions_size =
      args.aot_isolate_snapshot_instructions_size;
  project_args_.enable_wide_gamut = args.enable_wide_gamut;
  project_args_.enable_direct_platform_message_dispatch = true;
  project_args_.vm_service_uri_callback =
      &AndroidVMInit::OnVmServiceUriCallback;
}

const FlutterProjectArgs* AndroidProjectArgsHolder::GetProjectArgs() const {
  return &project_args_;
}

FlutterProjectArgs& AndroidProjectArgsHolder::GetMutableProjectArgs() {
  return project_args_;
}

const std::vector<std::string>& AndroidProjectArgsHolder::GetArgvStrings()
    const {
  return argv_strings_;
}

// ---------------------------------------------------------------------------
// AndroidVMInit
// ---------------------------------------------------------------------------

AndroidVMInit::AndroidVMInit(
    std::shared_ptr<JvmInvoker> jvm_invoker,
    std::shared_ptr<FontCollectionProvider> font_provider,
    std::shared_ptr<AndroidAOTProvider> aot_provider,
    const FlutterEngineProcTable* proc_table)
    : proc_table_(proc_table ? *proc_table : ResolveDefaultProcTable()),
      jvm_invoker_(std::move(jvm_invoker)),
      font_provider_(
          font_provider
              ? std::move(font_provider)
              : std::make_shared<DefaultFontCollectionProvider>(&proc_table_)),
      aot_provider_(aot_provider ? std::move(aot_provider)
                                 : std::make_shared<DefaultAndroidAOTProvider>(
                                       &proc_table_)),
      project_args_holder_(std::make_unique<AndroidProjectArgsHolder>()) {
  TRACE_EVENT0("flutter", "AndroidVMInit::AndroidVMInit");
  g_active_vm_init.store(this, std::memory_order_release);
}

AndroidVMInit::~AndroidVMInit() {
  TRACE_EVENT0("flutter", "AndroidVMInit::~AndroidVMInit");
  AndroidVMInit* expected = this;
  g_active_vm_init.compare_exchange_strong(expected, nullptr,
                                           std::memory_order_acq_rel);
  if (aot_data_ && aot_provider_) {
    aot_provider_->CollectAOTData(aot_data_);
    aot_data_ = nullptr;
  }
}

bool AndroidVMInit::Init(JNIEnv* env,
                         jclass clazz,
                         jobject context,
                         const std::vector<std::string>& args,
                         const std::string& kernel_path,
                         const std::string& app_storage_path,
                         const std::string& engine_caches_path,
                         int64_t init_time_millis,
                         int api_level,
                         const FlutterEngineProcTable* proc_table) {
  TRACE_EVENT0("flutter", "AndroidVMInit::Init(JNI)");
  (void)env;
  (void)clazz;
  (void)context;

  AndroidVMArgs vm_args = ParseCommandLineIntoVMArgs(
      args, kernel_path, app_storage_path, engine_caches_path, init_time_millis,
      static_cast<int32_t>(api_level));

#if FML_OS_ANDROID
  if (!vm_args.trace_systrace && IsAndroidATraceEnabled()) {
    vm_args.trace_systrace = true;
    vm_args.command_line_args.push_back("--trace-systrace");
    __android_log_print(
        ANDROID_LOG_INFO, "Flutter",
        "ATrace was enabled at startup. Flutter and Dart "
        "tracing will be forwarded to systrace and will not show up in "
        "Dart DevTools.");
  }
#endif

  FlutterEngineProcTable resolved =
      proc_table ? *proc_table : ResolveDefaultProcTable();
  bool is_aot = false;
  if (resolved.RunsAOTCompiledDartCode) {
    is_aot = resolved.RunsAOTCompiledDartCode();
  }
#if FML_OS_ANDROID
  if (!is_aot && !kernel_path.empty() && fml::IsFile(kernel_path)) {
    vm_args.kernel_path = kernel_path;
  } else {
    vm_args.kernel_path.clear();
  }
#else
  if (!is_aot && !kernel_path.empty()) {
    vm_args.kernel_path = kernel_path;
  } else {
    vm_args.kernel_path.clear();
  }
#endif

  if (!app_storage_path.empty()) {
    fml::CallbackCache::SetCachePath(app_storage_path);
    fml::CallbackCache::LoadCacheFromDisk();
  }

#if FML_OS_ANDROID
  if (!engine_caches_path.empty()) {
    fml::paths::InitializeAndroidCachesPath(engine_caches_path);
  }
  if (env != nullptr) {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    g_vm_service_platform_runner =
        fml::MessageLoop::GetCurrent().GetTaskRunner();
    jclass local_cls = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      local_cls = nullptr;
    }
    if (local_cls != nullptr) {
      if (g_vm_service_flutter_jni_class == nullptr) {
        g_vm_service_flutter_jni_class =
            static_cast<jclass>(env->NewGlobalRef(local_cls));
      }
      g_vm_service_uri_field = env->GetStaticFieldID(local_cls, "vmServiceUri",
                                                     "Ljava/lang/String;");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        g_vm_service_uri_field = nullptr;
      }
      env->DeleteLocalRef(local_cls);
    }
  }
#endif

  g_software_rendering_enabled.store(vm_args.enable_software_rendering);
  SetGlobalVMArgs(vm_args);
  return true;
}

bool AndroidVMInit::PrefetchDefaultFontManager(
    const FlutterEngineProcTable* proc_table) {
  TRACE_EVENT0("flutter", "AndroidVMInit::PrefetchDefaultFontManager(Static)");
  DefaultFontCollectionProvider provider(proc_table);
  return provider.PrefetchDefaultFontManager();
}

bool AndroidVMInit::GetIsSoftwareRenderingEnabled() {
  return g_software_rendering_enabled.load();
}

void AndroidVMInit::RegisterVmServiceUriCallback(
    std::function<void(const std::string&)> callback) {
  std::scoped_lock lock(g_global_vm_mutex);
  g_vm_service_uri_callback = std::move(callback);
}

void AndroidVMInit::OnVmServiceUriCallback(const FlutterVMServiceUriInfo* info,
                                           void* user_data) {
  TRACE_EVENT0("flutter", "AndroidVMInit::OnVmServiceUriCallback");
  if (!info || !info->uri) {
    return;
  }
  std::string uri(info->uri);
  std::function<void(const std::string&)> callback;
  {
    std::scoped_lock lock(g_global_vm_mutex);
    if (g_global_vm_args.has_value()) {
      g_global_vm_args->vm_service_uri = uri;
    }
    callback = g_vm_service_uri_callback;
  }
  if (callback) {
    callback(uri);
  } else {
#if FML_OS_ANDROID
    __android_log_print(ANDROID_LOG_INFO, "flutter",
                        "The Dart VM service is listening on %s", uri.c_str());
    auto set_uri_on_platform = [uri]() {
      if (g_vm_service_flutter_jni_class != nullptr &&
          g_vm_service_uri_field != nullptr) {
        JNIEnv* env = fml::jni::AttachCurrentThread();
        if (env != nullptr) {
          jstring java_uri = env->NewStringUTF(uri.c_str());
          if (java_uri != nullptr) {
            env->SetStaticObjectField(g_vm_service_flutter_jni_class,
                                      g_vm_service_uri_field, java_uri);
            env->DeleteLocalRef(java_uri);
          }
        }
      }
    };
    if (g_vm_service_platform_runner) {
      fml::TaskRunner::RunNowOrPostTask(g_vm_service_platform_runner,
                                        set_uri_on_platform);
    } else {
      set_uri_on_platform();
    }
#endif
  }
  if (user_data != nullptr &&
      user_data == g_active_vm_init.load(std::memory_order_acquire)) {
    auto* vm_init = static_cast<AndroidVMInit*>(user_data);
    vm_init->SetVmServiceUri(uri);
  }
}

void AndroidVMInit::SetGlobalVMArgs(const AndroidVMArgs& args) {
  std::scoped_lock lock(g_global_vm_mutex);
  g_global_vm_args = args;
  g_software_rendering_enabled.store(args.enable_software_rendering);
}

std::optional<AndroidVMArgs> AndroidVMInit::GetGlobalVMArgs() {
  std::scoped_lock lock(g_global_vm_mutex);
  return g_global_vm_args;
}

void AndroidVMInit::ResetGlobalStateForTesting() {
  std::scoped_lock lock(g_global_vm_mutex);
  g_global_vm_args.reset();
  g_software_rendering_enabled.store(false);
  g_vm_service_uri_callback = nullptr;
}

bool AndroidVMInit::Init(
    const AndroidVMArgs& args,
    const std::optional<VulkanDriverInfo>& vulkan_driver_info) {
  TRACE_EVENT0("flutter", "AndroidVMInit::Init");
  std::scoped_lock lock(mutex_);
  if (initialized_) {
    FML_LOG(WARNING) << "AndroidVMInit::Init called more than once; ignoring.";
    return true;
  }
  vm_args_ = args;
  rendering_api_ =
      SelectRenderingAPI(vm_args_, std::nullopt, vulkan_driver_info);

  if (!vm_args_.app_storage_path.empty()) {
    fml::CallbackCache::SetCachePath(vm_args_.app_storage_path);
    fml::CallbackCache::LoadCacheFromDisk();
  }

#if FML_OS_ANDROID
  if (!vm_args_.engine_caches_path.empty()) {
    fml::paths::InitializeAndroidCachesPath(vm_args_.engine_caches_path);
  }
#endif

  if (aot_data_ && aot_provider_) {
    aot_provider_->CollectAOTData(aot_data_);
    aot_data_ = nullptr;
  }

  if (!vm_args_.aot_library_path.empty() && aot_provider_) {
    FlutterEngineAOTDataSource source = {};
    source.type = kFlutterEngineAOTDataSourceTypeElfPath;
    source.elf_path = vm_args_.aot_library_path.c_str();
    FlutterEngineResult result =
        aot_provider_->CreateAOTData(&source, &aot_data_);
    if (result != kSuccess) {
      FML_LOG(ERROR) << "Failed to create AOT data from elf library: "
                     << vm_args_.aot_library_path;
      initialized_ = false;
      return false;
    }
  }

  project_args_holder_->Populate(vm_args_, aot_data_, this);

  if (!vm_args_.vm_service_uri.empty()) {
    vm_service_uri_ = vm_args_.vm_service_uri;
  }

  g_software_rendering_enabled.store(vm_args_.enable_software_rendering);
  SetGlobalVMArgs(vm_args_);
  initialized_ = true;
  return true;
}

bool AndroidVMInit::PrefetchFontManager() {
  TRACE_EVENT0("flutter", "AndroidVMInit::PrefetchFontManager");
  std::scoped_lock lock(mutex_);
  if (font_provider_) {
    return font_provider_->PrefetchDefaultFontManager();
  }
  return false;
}

bool AndroidVMInit::RunsAOTCompiledDartCode() const {
  if (proc_table_.RunsAOTCompiledDartCode) {
    return proc_table_.RunsAOTCompiledDartCode();
  }
  return false;
}

bool AndroidVMInit::SetVmServiceUri(const std::string& uri) {
  TRACE_EVENT1("flutter", "AndroidVMInit::SetVmServiceUri", "uri", uri.c_str());
  std::scoped_lock lock(mutex_);
  vm_service_uri_ = uri;
  return true;
}

std::string AndroidVMInit::GetVmServiceUri() const {
  std::scoped_lock lock(mutex_);
  return vm_service_uri_;
}

bool AndroidVMInit::IsInitialized() const {
  std::scoped_lock lock(mutex_);
  return initialized_;
}

std::optional<AndroidVMArgs> AndroidVMInit::GetVMArgs() const {
  std::scoped_lock lock(mutex_);
  if (!initialized_) {
    return std::nullopt;
  }
  return vm_args_;
}

AndroidRenderingAPI AndroidVMInit::GetSelectedRenderingAPI() const {
  std::scoped_lock lock(mutex_);
  return rendering_api_;
}

const FlutterProjectArgs* AndroidVMInit::GetProjectArgs() const {
  std::scoped_lock lock(mutex_);
  if (!initialized_) {
    return nullptr;
  }
  return project_args_holder_->GetProjectArgs();
}

FlutterEngineResult AndroidVMInit::CreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) {
  std::scoped_lock lock(mutex_);
  if (!aot_provider_) {
    return kInternalInconsistency;
  }
  return aot_provider_->CreateAOTData(source, data_out);
}

FlutterEngineResult AndroidVMInit::CollectAOTData(FlutterEngineAOTData data) {
  std::scoped_lock lock(mutex_);
  if (!aot_provider_) {
    return kInternalInconsistency;
  }
  return aot_provider_->CollectAOTData(data);
}

std::shared_ptr<FontCollectionProvider>
AndroidVMInit::GetFontCollectionProvider() const {
  std::scoped_lock lock(mutex_);
  return font_provider_;
}

void AndroidVMInit::SetFontCollectionProvider(
    std::shared_ptr<FontCollectionProvider> provider) {
  std::scoped_lock lock(mutex_);
  font_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultFontCollectionProvider>(&proc_table_);
}

std::shared_ptr<AndroidAOTProvider> AndroidVMInit::GetAOTProvider() const {
  std::scoped_lock lock(mutex_);
  return aot_provider_;
}

void AndroidVMInit::SetAOTProvider(
    std::shared_ptr<AndroidAOTProvider> provider) {
  std::scoped_lock lock(mutex_);
  aot_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidAOTProvider>(&proc_table_);
}

std::shared_ptr<JvmInvoker> AndroidVMInit::GetJvmInvoker() const {
  return jvm_invoker_;
}

}  // namespace android
}  // namespace flutter
