// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vm_init.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {
namespace android {

static FlutterEngineResult EngineCreateAOTData(
    const FlutterEngineAOTDataSource* source,
    FlutterEngineAOTData* data_out) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.CreateAOTData) {
    return s_procs.CreateAOTData(source, data_out);
  }
  return kInternalInconsistency;
}

static FlutterEngineResult EngineCollectAOTData(FlutterEngineAOTData data) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.CollectAOTData) {
    return s_procs.CollectAOTData(data);
  }
  return kInternalInconsistency;
}

AndroidRenderingAPI SelectRenderingAPI(const AndroidVMArgs& args,
                                       bool is_vivante) {
  TRACE_EVENT0("flutter", "SelectRenderingAPI");
#if !SLIMPELLER
  if (args.enable_software_rendering) {
    return AndroidRenderingAPI::kSoftware;
  }

  if (args.requested_rendering_backend == "opengles" && args.enable_impeller) {
    return AndroidRenderingAPI::kImpellerOpenGLES;
  }
  if (args.requested_rendering_backend == "vulkan" && args.enable_impeller) {
    return AndroidRenderingAPI::kImpellerVulkan;
  }

  if (args.enable_impeller &&
      args.api_level >= kMinimumAndroidApiLevelForImpeller && !is_vivante) {
    return AndroidRenderingAPI::kImpellerAutoselect;
  }

  return AndroidRenderingAPI::kSkiaOpenGLES;
#else
  return AndroidRenderingAPI::kImpellerAutoselect;
#endif  // !SLIMPELLER
}

// ---------------------------------------------------------------------------
// DefaultFontCollectionProvider
// ---------------------------------------------------------------------------

DefaultFontCollectionProvider::DefaultFontCollectionProvider(
    std::shared_ptr<OSLibraryLoader> library_loader)
    : library_loader_(std::move(library_loader)) {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::DefaultFontCollectionProvider");
}

DefaultFontCollectionProvider::~DefaultFontCollectionProvider() {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::~DefaultFontCollectionProvider");
}

bool DefaultFontCollectionProvider::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter",
               "DefaultFontCollectionProvider::PrefetchDefaultFontManager");
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
  TRACE_EVENT0("flutter", "InMemoryFontCollectionProvider::SetResult");
  std::scoped_lock lock(mutex_);
  result_ = result;
}

void InMemoryFontCollectionProvider::Reset() {
  TRACE_EVENT0("flutter", "InMemoryFontCollectionProvider::Reset");
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

DefaultAndroidAOTProvider::DefaultAndroidAOTProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidAOTProvider::DefaultAndroidAOTProvider");
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
  return EngineCreateAOTData(source, data_out);
}

FlutterEngineResult DefaultAndroidAOTProvider::CollectAOTData(
    FlutterEngineAOTData data) {
  TRACE_EVENT0("flutter", "DefaultAndroidAOTProvider::CollectAOTData");
  if (!data) {
    return kInvalidArguments;
  }
  return EngineCollectAOTData(data);
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
  TRACE_EVENT0("flutter", "InMemoryAndroidAOTProvider::SetCreateResult");
  std::scoped_lock lock(mutex_);
  create_result_ = result;
}

void InMemoryAndroidAOTProvider::SetCollectResult(FlutterEngineResult result) {
  TRACE_EVENT0("flutter", "InMemoryAndroidAOTProvider::SetCollectResult");
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
  TRACE_EVENT0("flutter", "InMemoryAndroidAOTProvider::Reset");
  std::scoped_lock lock(mutex_);
  create_result_ = kSuccess;
  collect_result_ = kSuccess;
  create_count_ = 0;
  collect_count_ = 0;
  last_elf_path_.clear();
  next_mock_handle_ = 0x1000;
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
    return kInvalidArguments;
  }
  std::scoped_lock lock(mutex_);
  collect_count_++;
  return collect_result_;
}

// ---------------------------------------------------------------------------
// AndroidProjectArgsHolder
// ---------------------------------------------------------------------------

AndroidProjectArgsHolder::AndroidProjectArgsHolder() {
  TRACE_EVENT0("flutter", "AndroidProjectArgsHolder::AndroidProjectArgsHolder");
  project_args_.struct_size = sizeof(FlutterProjectArgs);
}

AndroidProjectArgsHolder::~AndroidProjectArgsHolder() {
  TRACE_EVENT0("flutter",
               "AndroidProjectArgsHolder::~AndroidProjectArgsHolder");
}

void AndroidProjectArgsHolder::Populate(const AndroidVMArgs& args,
                                        FlutterEngineAOTData aot_data,
                                        void* user_data) {
  TRACE_EVENT0("flutter", "AndroidProjectArgsHolder::Populate");
  argv_strings_.clear();
  argv_ptrs_.clear();

  // Executable name must be first entry in command_line_argv.
  argv_strings_.push_back("flutter");
  for (const auto& arg : args.command_line_args) {
    argv_strings_.push_back(arg);
  }
  for (const auto& str : argv_strings_) {
    argv_ptrs_.push_back(str.c_str());
  }

  icu_data_path_ = args.icu_data_path;
  persistent_cache_path_ = args.engine_caches_path;
  log_tag_ = args.log_tag.empty() ? "flutter" : args.log_tag;

  memset(&project_args_, 0, sizeof(FlutterProjectArgs));
  project_args_.struct_size = sizeof(FlutterProjectArgs);
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

  project_args_.vsync_callback = &FlutterEmbedderNative::OnVsyncCallback;
  project_args_.update_semantics_callback2 =
      &FlutterEmbedderNative::OnUpdateSemantics2;
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
    std::shared_ptr<AndroidAOTProvider> aot_provider)
    : jvm_invoker_(std::move(jvm_invoker)),
      font_provider_(font_provider
                         ? std::move(font_provider)
                         : std::make_shared<DefaultFontCollectionProvider>()),
      aot_provider_(aot_provider
                        ? std::move(aot_provider)
                        : std::make_shared<DefaultAndroidAOTProvider>()),
      project_args_holder_(std::make_unique<AndroidProjectArgsHolder>()) {
  TRACE_EVENT0("flutter", "AndroidVMInit::AndroidVMInit");
}

AndroidVMInit::~AndroidVMInit() {
  TRACE_EVENT0("flutter", "AndroidVMInit::~AndroidVMInit");
  if (aot_data_ && aot_provider_) {
    aot_provider_->CollectAOTData(aot_data_);
    aot_data_ = nullptr;
  }
}

bool AndroidVMInit::Init(const AndroidVMArgs& args) {
  TRACE_EVENT0("flutter", "AndroidVMInit::Init");
  std::scoped_lock lock(mutex_);
  vm_args_ = args;
  rendering_api_ = SelectRenderingAPI(vm_args_);

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
      return false;
    }
  }

  project_args_holder_->Populate(vm_args_, aot_data_, this);

  if (!vm_args_.vm_service_uri.empty()) {
    vm_service_uri_ = vm_args_.vm_service_uri;
    if (jvm_invoker_) {
      std::vector<uint8_t> payload(vm_service_uri_.begin(),
                                   vm_service_uri_.end());
      jvm_invoker_->InvokeVoidMethod("setVmServiceUri", "(Ljava/lang/String;)V",
                                     payload);
    }
  }

  initialized_ = true;
  return true;
}

bool AndroidVMInit::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter", "AndroidVMInit::PrefetchDefaultFontManager");
  if (font_provider_) {
    return font_provider_->PrefetchDefaultFontManager();
  }
  return false;
}

bool AndroidVMInit::SetVmServiceUri(const std::string& uri) {
  TRACE_EVENT1("flutter", "AndroidVMInit::SetVmServiceUri", "uri", uri.c_str());
  std::scoped_lock lock(mutex_);
  vm_service_uri_ = uri;
  if (jvm_invoker_) {
    std::vector<uint8_t> payload(uri.begin(), uri.end());
    return jvm_invoker_->InvokeVoidMethod("setVmServiceUri",
                                          "(Ljava/lang/String;)V", payload);
  }
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
  TRACE_EVENT0("flutter", "AndroidVMInit::CreateAOTData");
  if (!aot_provider_) {
    return kInternalInconsistency;
  }
  return aot_provider_->CreateAOTData(source, data_out);
}

FlutterEngineResult AndroidVMInit::CollectAOTData(FlutterEngineAOTData data) {
  TRACE_EVENT0("flutter", "AndroidVMInit::CollectAOTData");
  if (!aot_provider_) {
    return kInternalInconsistency;
  }
  return aot_provider_->CollectAOTData(data);
}

std::shared_ptr<FontCollectionProvider>
AndroidVMInit::GetFontCollectionProvider() const {
  return font_provider_;
}

void AndroidVMInit::SetFontCollectionProvider(
    std::shared_ptr<FontCollectionProvider> provider) {
  TRACE_EVENT0("flutter", "AndroidVMInit::SetFontCollectionProvider");
  font_provider_ = provider ? std::move(provider)
                            : std::make_shared<DefaultFontCollectionProvider>();
}

std::shared_ptr<AndroidAOTProvider> AndroidVMInit::GetAOTProvider() const {
  return aot_provider_;
}

void AndroidVMInit::SetAOTProvider(
    std::shared_ptr<AndroidAOTProvider> provider) {
  TRACE_EVENT0("flutter", "AndroidVMInit::SetAOTProvider");
  aot_provider_ = provider ? std::move(provider)
                           : std::make_shared<DefaultAndroidAOTProvider>();
}

std::shared_ptr<JvmInvoker> AndroidVMInit::GetJvmInvoker() const {
  return jvm_invoker_;
}

}  // namespace android
}  // namespace flutter
