// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_engine_group.h"

#include <chrono>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/trace_event.h"

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

}  // namespace

// =============================================================================
// AndroidEngineGroupSpawnInfoHolder Implementation
// =============================================================================

AndroidEngineGroupSpawnInfoHolder::AndroidEngineGroupSpawnInfoHolder() {
  TRACE_EVENT0("flutter",
               "AndroidEngineGroupSpawnInfoHolder::"
               "AndroidEngineGroupSpawnInfoHolder");
}

AndroidEngineGroupSpawnInfoHolder::~AndroidEngineGroupSpawnInfoHolder() {
  TRACE_EVENT0("flutter",
               "AndroidEngineGroupSpawnInfoHolder::"
               "~AndroidEngineGroupSpawnInfoHolder");
}

void AndroidEngineGroupSpawnInfoHolder::Build(
    const AndroidEngineSpawnArgs& args,
    void* user_data,
    const FlutterCompositor* compositor) {
  TRACE_EVENT0("flutter", "AndroidEngineGroupSpawnInfoHolder::Build");
  entrypoint_ = args.entrypoint;
  library_url_ = args.library_url;
  initial_route_ = args.initial_route;
  entrypoint_args_ = args.entrypoint_args;

  argv_ptrs_.clear();
  argv_ptrs_.reserve(entrypoint_args_.size());
  for (const auto& arg : entrypoint_args_) {
    argv_ptrs_.push_back(arg.c_str());
  }

  spawn_info_ = {};
  spawn_info_.struct_size = sizeof(FlutterEngineSpawnInfo);
  spawn_info_.entrypoint = entrypoint_.empty() ? nullptr : entrypoint_.c_str();
  spawn_info_.library_uri =
      library_url_.empty() ? nullptr : library_url_.c_str();
  spawn_info_.initial_route =
      initial_route_.empty() ? nullptr : initial_route_.c_str();
  spawn_info_.entrypoint_argc = static_cast<int>(argv_ptrs_.size());
  spawn_info_.entrypoint_argv =
      argv_ptrs_.empty() ? nullptr : argv_ptrs_.data();
  spawn_info_.user_data = user_data ? user_data : args.user_data;
  spawn_info_.compositor = compositor ? compositor : args.compositor;
}

const FlutterEngineSpawnInfo* AndroidEngineGroupSpawnInfoHolder::GetSpawnInfo()
    const {
  return &spawn_info_;
}

const std::string& AndroidEngineGroupSpawnInfoHolder::GetEntrypoint() const {
  return entrypoint_;
}

const std::string& AndroidEngineGroupSpawnInfoHolder::GetLibraryUrl() const {
  return library_url_;
}

const std::string& AndroidEngineGroupSpawnInfoHolder::GetInitialRoute() const {
  return initial_route_;
}

const std::vector<std::string>&
AndroidEngineGroupSpawnInfoHolder::GetEntrypointArgs() const {
  return entrypoint_args_;
}

// =============================================================================
// DefaultAndroidEngineGroupProvider Implementation
// =============================================================================

DefaultAndroidEngineGroupProvider::DefaultAndroidEngineGroupProvider(
    const FlutterEngineProcTable* proc_table) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::"
               "DefaultAndroidEngineGroupProvider");
  if (proc_table != nullptr) {
    proc_table_ = *proc_table;
  } else {
    proc_table_ = ResolveDefaultProcTable();
  }
}

DefaultAndroidEngineGroupProvider::~DefaultAndroidEngineGroupProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::"
               "~DefaultAndroidEngineGroupProvider");
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnInfo* spawn_info,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter", "DefaultAndroidEngineGroupProvider::SpawnEngine");
  if (!parent_engine || !spawn_info || !engine_out ||
      spawn_info->struct_size < sizeof(FlutterEngineSpawnInfo)) {
    return kInvalidArguments;
  }
  if (proc_table_.Spawn) {
    return proc_table_.Spawn(parent_engine, spawn_info, engine_out);
  }
  return kInternalInconsistency;
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::ShutdownEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter", "DefaultAndroidEngineGroupProvider::ShutdownEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  if (proc_table_.Shutdown) {
    return proc_table_.Shutdown(engine);
  }
  return kInternalInconsistency;
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::InitializeEngine(
    const FlutterRendererConfig* config,
    const FlutterProjectArgs* args,
    void* user_data,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::InitializeEngine");
  if (!config || !args || !engine_out ||
      args->struct_size < sizeof(FlutterProjectArgs)) {
    return kInvalidArguments;
  }
  if (proc_table_.Initialize) {
    return proc_table_.Initialize(FLUTTER_ENGINE_VERSION, config, args,
                                  user_data, engine_out);
  }
  return kInternalInconsistency;
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::DeinitializeEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::DeinitializeEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  if (proc_table_.Deinitialize) {
    return proc_table_.Deinitialize(engine);
  }
  return kInternalInconsistency;
}

// =============================================================================
// InMemoryAndroidEngineGroupProvider Implementation
// =============================================================================

InMemoryAndroidEngineGroupProvider::InMemoryAndroidEngineGroupProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::"
               "InMemoryAndroidEngineGroupProvider");
}

InMemoryAndroidEngineGroupProvider::~InMemoryAndroidEngineGroupProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::"
               "~InMemoryAndroidEngineGroupProvider");
}

void InMemoryAndroidEngineGroupProvider::SetSpawnResult(
    FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  spawn_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetShutdownResult(
    FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  shutdown_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetInitializeResult(
    FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  initialize_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetDeinitializeResult(
    FlutterEngineResult result) {
  std::scoped_lock lock(mutex_);
  deinitialize_result_ = result;
}

size_t InMemoryAndroidEngineGroupProvider::GetSpawnCallCount() const {
  std::scoped_lock lock(mutex_);
  return spawn_call_count_;
}

size_t InMemoryAndroidEngineGroupProvider::GetShutdownCallCount() const {
  std::scoped_lock lock(mutex_);
  return shutdown_call_count_;
}

size_t InMemoryAndroidEngineGroupProvider::GetInitializeCallCount() const {
  std::scoped_lock lock(mutex_);
  return initialize_call_count_;
}

size_t InMemoryAndroidEngineGroupProvider::GetDeinitializeCallCount() const {
  std::scoped_lock lock(mutex_);
  return deinitialize_call_count_;
}

size_t InMemoryAndroidEngineGroupProvider::GetActiveHandleCount() const {
  std::scoped_lock lock(mutex_);
  return active_handles_.size();
}

std::vector<FLUTTER_API_SYMBOL(FlutterEngine)>
InMemoryAndroidEngineGroupProvider::GetShutdownHandles() const {
  std::scoped_lock lock(mutex_);
  return shutdown_handles_;
}

std::optional<AndroidEngineSpawnArgs>
InMemoryAndroidEngineGroupProvider::GetLastSpawnArgs() const {
  std::scoped_lock lock(mutex_);
  return last_spawn_args_;
}

void InMemoryAndroidEngineGroupProvider::SetMockEngineHandle(
    FLUTTER_API_SYMBOL(FlutterEngine) handle) {
  std::scoped_lock lock(mutex_);
  custom_mock_handle_ = handle;
}

void InMemoryAndroidEngineGroupProvider::Reset() {
  std::scoped_lock lock(mutex_);
  spawn_result_ = kSuccess;
  shutdown_result_ = kSuccess;
  initialize_result_ = kSuccess;
  deinitialize_result_ = kSuccess;
  spawn_call_count_ = 0;
  shutdown_call_count_ = 0;
  initialize_call_count_ = 0;
  deinitialize_call_count_ = 0;
  next_mock_handle_ = kInitialMockEngineAddress;
  custom_mock_handle_ = nullptr;
  active_handles_.clear();
  shutdown_handles_.clear();
  last_spawn_args_.reset();
}

FlutterEngineResult InMemoryAndroidEngineGroupProvider::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnInfo* spawn_info,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter", "InMemoryAndroidEngineGroupProvider::SpawnEngine");
  std::scoped_lock lock(mutex_);
  spawn_call_count_++;

  if (parent_engine == nullptr || spawn_info == nullptr ||
      engine_out == nullptr ||
      spawn_info->struct_size < sizeof(FlutterEngineSpawnInfo)) {
    return kInvalidArguments;
  }

  if (spawn_result_ != kSuccess) {
    return spawn_result_;
  }

  AndroidEngineSpawnArgs recorded_args;
  if (spawn_info->entrypoint) {
    recorded_args.entrypoint = spawn_info->entrypoint;
  }
  if (spawn_info->library_uri) {
    recorded_args.library_url = spawn_info->library_uri;
  }
  if (spawn_info->initial_route) {
    recorded_args.initial_route = spawn_info->initial_route;
  }
  if (spawn_info->entrypoint_argv && spawn_info->entrypoint_argc > 0) {
    for (int i = 0; i < spawn_info->entrypoint_argc; ++i) {
      if (spawn_info->entrypoint_argv[i]) {
        recorded_args.entrypoint_args.emplace_back(
            spawn_info->entrypoint_argv[i]);
      }
    }
  }
  recorded_args.user_data = spawn_info->user_data;
  recorded_args.compositor = spawn_info->compositor;
  last_spawn_args_ = recorded_args;

  FLUTTER_API_SYMBOL(FlutterEngine) generated_handle = nullptr;
  if (custom_mock_handle_ != nullptr) {
    generated_handle = custom_mock_handle_;
  } else {
    next_mock_handle_ += kMockEngineAddressStride;
    generated_handle =
        reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(next_mock_handle_);
  }

  active_handles_.insert(generated_handle);
  *engine_out = generated_handle;
  return kSuccess;
}

FlutterEngineResult InMemoryAndroidEngineGroupProvider::ShutdownEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter", "InMemoryAndroidEngineGroupProvider::ShutdownEngine");
  std::scoped_lock lock(mutex_);
  shutdown_call_count_++;

  if (engine == nullptr) {
    return kInvalidArguments;
  }

  if (shutdown_result_ != kSuccess) {
    return shutdown_result_;
  }

  active_handles_.erase(engine);
  shutdown_handles_.push_back(engine);
  return kSuccess;
}

FlutterEngineResult InMemoryAndroidEngineGroupProvider::InitializeEngine(
    const FlutterRendererConfig* config,
    const FlutterProjectArgs* args,
    void* user_data,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::InitializeEngine");
  (void)config;
  (void)args;
  (void)user_data;
  std::scoped_lock lock(mutex_);
  initialize_call_count_++;

  if (engine_out == nullptr) {
    return kInvalidArguments;
  }

  if (initialize_result_ != kSuccess) {
    return initialize_result_;
  }

  next_mock_handle_ += kMockEngineAddressStride;
  auto handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(next_mock_handle_);
  active_handles_.insert(handle);
  *engine_out = handle;
  return kSuccess;
}

FlutterEngineResult InMemoryAndroidEngineGroupProvider::DeinitializeEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::DeinitializeEngine");
  std::scoped_lock lock(mutex_);
  deinitialize_call_count_++;

  if (engine == nullptr) {
    return kInvalidArguments;
  }

  if (deinitialize_result_ != kSuccess) {
    return deinitialize_result_;
  }

  active_handles_.erase(engine);
  return kSuccess;
}

// =============================================================================
// AndroidEngineGroup Implementation
// =============================================================================

AndroidEngineGroup::AndroidEngineGroup(
    std::shared_ptr<AndroidEngineGroupProvider> provider,
    std::shared_ptr<JvmInvoker> jvm_invoker,
    const FlutterEngineProcTable* proc_table)
    : proc_table_(proc_table ? *proc_table : ResolveDefaultProcTable()),
      provider_(provider ? std::move(provider)
                         : std::make_shared<DefaultAndroidEngineGroupProvider>(
                               &proc_table_)),
      jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::AndroidEngineGroup");
}

AndroidEngineGroup::~AndroidEngineGroup() {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::~AndroidEngineGroup");
  ShutdownAllEngines();
}

bool AndroidEngineGroup::InitializeGroup(
    const AndroidEngineGroupConfig& config) {
  std::scoped_lock lock(mutex_);
  config_ = config;
  initialized_ = true;
  return true;
}

bool AndroidEngineGroup::IsInitialized() const {
  std::scoped_lock lock(mutex_);
  return initialized_;
}

AndroidEngineGroupConfig AndroidEngineGroup::GetConfig() const {
  std::scoped_lock lock(mutex_);
  return config_;
}

void AndroidEngineGroup::SetPrimaryEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                              engine,
                                          int64_t engine_id) {
  std::scoped_lock lock(mutex_);
  if (engine != nullptr && engine_id == 0) {
    engine_id = next_auto_engine_id_++;
  }
  primary_engine_ = engine;
  primary_engine_id_ = engine_id;
  if (engine != nullptr && engine_id != 0) {
    AndroidEngineRecord record;
    record.engine_id = engine_id;
    record.engine_handle = engine;
    record.is_running = true;
    record.is_garbage_collected = false;
    record.spawned_time_nanos =
        std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch())
            .count();
    active_engines_[engine_id] = record;
    handle_to_id_[engine] = engine_id;
  }
}

FLUTTER_API_SYMBOL(FlutterEngine) AndroidEngineGroup::GetPrimaryEngine() const {
  std::scoped_lock lock(mutex_);
  return primary_engine_;
}

int64_t AndroidEngineGroup::GetPrimaryEngineId() const {
  std::scoped_lock lock(mutex_);
  return primary_engine_id_;
}

FLUTTER_API_SYMBOL(FlutterEngine)
AndroidEngineGroup::SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
                                const AndroidEngineSpawnArgs& args) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::SpawnEngine", "entrypoint",
               args.entrypoint.c_str());
  if (parent_engine == nullptr) {
    FML_LOG(ERROR) << "Cannot spawn engine: null parent engine handle.";
    return nullptr;
  }

  AndroidEngineGroupSpawnInfoHolder holder;
  holder.Build(args, args.user_data, args.compositor);

  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(mutex_);
    provider = provider_;
  }

  if (!provider) {
    FML_LOG(ERROR) << "Cannot spawn engine: provider is null.";
    return nullptr;
  }

  FLUTTER_API_SYMBOL(FlutterEngine) spawned_handle = nullptr;
  FlutterEngineResult result = provider->SpawnEngine(
      parent_engine, holder.GetSpawnInfo(), &spawned_handle);

  if (result != kSuccess || spawned_handle == nullptr) {
    FML_LOG(ERROR) << "Failed to spawn Flutter engine, result: " << result;
    return nullptr;
  }

  int64_t assigned_engine_id = args.engine_id;
  {
    std::scoped_lock lock(mutex_);
    if (assigned_engine_id == 0 ||
        active_engines_.find(assigned_engine_id) != active_engines_.end()) {
      assigned_engine_id = next_auto_engine_id_++;
      while (active_engines_.find(assigned_engine_id) !=
             active_engines_.end()) {
        assigned_engine_id = next_auto_engine_id_++;
      }
    }

    AndroidEngineRecord record;
    record.engine_id = assigned_engine_id;
    record.engine_handle = spawned_handle;
    record.spawn_args = args;
    record.spawn_args.engine_id = assigned_engine_id;
    record.is_running = true;
    record.is_garbage_collected = false;
    record.spawned_time_nanos =
        std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch())
            .count();

    active_engines_[assigned_engine_id] = record;
    handle_to_id_[spawned_handle] = assigned_engine_id;
  }

  return spawned_handle;
}

FLUTTER_API_SYMBOL(FlutterEngine)
AndroidEngineGroup::SpawnEngine(int64_t parent_engine_id,
                                const AndroidEngineSpawnArgs& args) {
  FLUTTER_API_SYMBOL(FlutterEngine) parent_handle = nullptr;
  {
    std::scoped_lock lock(mutex_);
    auto it = active_engines_.find(parent_engine_id);
    if (it != active_engines_.end() && it->second.is_running) {
      parent_handle = it->second.engine_handle;
    } else if (parent_engine_id == primary_engine_id_ && primary_engine_) {
      parent_handle = primary_engine_;
    }
  }

  if (parent_handle == nullptr) {
    FML_LOG(ERROR) << "Cannot spawn engine: parent engine ID "
                   << parent_engine_id << " not found or not active.";
    return nullptr;
  }

  return SpawnEngine(parent_handle, args);
}

FLUTTER_API_SYMBOL(FlutterEngine)
AndroidEngineGroup::SpawnEngineWithInfo(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnInfo* spawn_info,
    int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::SpawnEngineWithInfo",
               "engine_id", std::to_string(engine_id).c_str());
  if (parent_engine == nullptr || spawn_info == nullptr ||
      spawn_info->struct_size < sizeof(FlutterEngineSpawnInfo)) {
    FML_LOG(ERROR)
        << "Cannot spawn engine: invalid parent or spawn_info pointer.";
    return nullptr;
  }

  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(mutex_);
    provider = provider_;
  }

  if (!provider) {
    return nullptr;
  }

  FLUTTER_API_SYMBOL(FlutterEngine) spawned_handle = nullptr;
  FlutterEngineResult result =
      provider->SpawnEngine(parent_engine, spawn_info, &spawned_handle);

  if (result != kSuccess || spawned_handle == nullptr) {
    return nullptr;
  }

  int64_t assigned_engine_id = engine_id;
  {
    std::scoped_lock lock(mutex_);
    if (assigned_engine_id == 0 ||
        active_engines_.find(assigned_engine_id) != active_engines_.end()) {
      assigned_engine_id = next_auto_engine_id_++;
      while (active_engines_.find(assigned_engine_id) !=
             active_engines_.end()) {
        assigned_engine_id = next_auto_engine_id_++;
      }
    }

    AndroidEngineRecord record;
    record.engine_id = assigned_engine_id;
    record.engine_handle = spawned_handle;
    record.is_running = true;
    record.is_garbage_collected = false;
    record.spawned_time_nanos =
        std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch())
            .count();

    if (spawn_info->entrypoint) {
      record.spawn_args.entrypoint = spawn_info->entrypoint;
    }
    if (spawn_info->library_uri) {
      record.spawn_args.library_url = spawn_info->library_uri;
    }
    if (spawn_info->initial_route) {
      record.spawn_args.initial_route = spawn_info->initial_route;
    }
    if (spawn_info->entrypoint_argv && spawn_info->entrypoint_argc > 0) {
      for (int i = 0; i < spawn_info->entrypoint_argc; ++i) {
        if (spawn_info->entrypoint_argv[i]) {
          record.spawn_args.entrypoint_args.emplace_back(
              spawn_info->entrypoint_argv[i]);
        }
      }
    }
    record.spawn_args.engine_id = assigned_engine_id;
    record.spawn_args.user_data = spawn_info->user_data;
    record.spawn_args.compositor = spawn_info->compositor;

    active_engines_[assigned_engine_id] = record;
    handle_to_id_[spawned_handle] = assigned_engine_id;
  }

  return spawned_handle;
}

bool AndroidEngineGroup::ShutdownEngine(int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::ShutdownEngine", "engine_id",
               std::to_string(engine_id).c_str());
  FLUTTER_API_SYMBOL(FlutterEngine) handle_to_shutdown = nullptr;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(mutex_);
    provider = provider_;
    auto it = active_engines_.find(engine_id);
    if (it == active_engines_.end() || !it->second.is_running) {
      return false;
    }
    it->second.is_running = false;
    it->second.is_garbage_collected = false;
    handle_to_shutdown = it->second.engine_handle;
    if (handle_to_shutdown) {
      handle_to_id_.erase(handle_to_shutdown);
    }
    retired_engines_[engine_id] = it->second;
    active_engines_.erase(it);
    if (primary_engine_id_ == engine_id) {
      primary_engine_id_ = 0;
      primary_engine_ = nullptr;
    }
  }

  if (handle_to_shutdown && provider) {
    provider->ShutdownEngine(handle_to_shutdown);
  }
  return true;
}

bool AndroidEngineGroup::ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine_handle) {
  if (engine_handle == nullptr) {
    return false;
  }
  int64_t engine_id = 0;
  {
    std::scoped_lock lock(mutex_);
    auto it = handle_to_id_.find(engine_handle);
    if (it != handle_to_id_.end()) {
      engine_id = it->second;
    }
  }
  if (engine_id != 0) {
    return ShutdownEngine(engine_id);
  }
  return false;
}

bool AndroidEngineGroup::ShutdownAllEngines() {
  std::vector<int64_t> ids_to_shutdown;
  {
    std::scoped_lock lock(mutex_);
    for (const auto& [id, record] : active_engines_) {
      if (record.is_running && id != primary_engine_id_) {
        ids_to_shutdown.push_back(id);
      }
    }
    if (primary_engine_id_ != 0 &&
        active_engines_.find(primary_engine_id_) != active_engines_.end()) {
      ids_to_shutdown.push_back(primary_engine_id_);
    }
  }
  bool all_succeeded = true;
  for (int64_t id : ids_to_shutdown) {
    if (!ShutdownEngine(id)) {
      all_succeeded = false;
    }
  }
  return all_succeeded;
}

bool AndroidEngineGroup::OnEngineGarbageCollected(int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::OnEngineGarbageCollected",
               "engine_id", std::to_string(engine_id).c_str());
  FLUTTER_API_SYMBOL(FlutterEngine) handle_to_shutdown = nullptr;
  std::shared_ptr<AndroidEngineGroupProvider> provider;
  {
    std::scoped_lock lock(mutex_);
    provider = provider_;
    auto it = active_engines_.find(engine_id);
    if (it == active_engines_.end() || !it->second.is_running) {
      return false;
    }
    it->second.is_running = false;
    it->second.is_garbage_collected = true;
    handle_to_shutdown = it->second.engine_handle;
    if (handle_to_shutdown) {
      handle_to_id_.erase(handle_to_shutdown);
    }
    retired_engines_[engine_id] = it->second;
    active_engines_.erase(it);
    if (primary_engine_id_ == engine_id) {
      primary_engine_id_ = 0;
      primary_engine_ = nullptr;
    }
  }

  if (handle_to_shutdown && provider) {
    provider->ShutdownEngine(handle_to_shutdown);
  }
  return true;
}

bool AndroidEngineGroup::RegisterEngine(int64_t engine_id,
                                        FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine_handle,
                                        const AndroidEngineSpawnArgs& args) {
  if (engine_id == 0 || engine_handle == nullptr) {
    return false;
  }
  std::scoped_lock lock(mutex_);
  if (active_engines_.find(engine_id) != active_engines_.end() ||
      handle_to_id_.find(engine_handle) != handle_to_id_.end()) {
    return false;
  }
  AndroidEngineRecord record;
  record.engine_id = engine_id;
  record.engine_handle = engine_handle;
  record.spawn_args = args;
  record.spawn_args.engine_id = engine_id;
  record.is_running = true;
  record.is_garbage_collected = false;
  record.spawned_time_nanos =
      std::chrono::duration_cast<std::chrono::nanoseconds>(
          std::chrono::steady_clock::now().time_since_epoch())
          .count();

  active_engines_[engine_id] = record;
  handle_to_id_[engine_handle] = engine_id;
  if (primary_engine_ == nullptr) {
    primary_engine_ = engine_handle;
    primary_engine_id_ = engine_id;
  }
  return true;
}

bool AndroidEngineGroup::UnregisterEngine(int64_t engine_id) {
  std::scoped_lock lock(mutex_);
  auto it = active_engines_.find(engine_id);
  if (it == active_engines_.end()) {
    return false;
  }
  if (it->second.engine_handle) {
    handle_to_id_.erase(it->second.engine_handle);
  }
  if (primary_engine_id_ == engine_id) {
    primary_engine_id_ = 0;
    primary_engine_ = nullptr;
  }
  active_engines_.erase(it);
  return true;
}

size_t AndroidEngineGroup::GetActiveEngineCount() const {
  std::scoped_lock lock(mutex_);
  return active_engines_.size();
}

bool AndroidEngineGroup::IsEngineActive(int64_t engine_id) const {
  std::scoped_lock lock(mutex_);
  auto it = active_engines_.find(engine_id);
  return it != active_engines_.end() && it->second.is_running;
}

bool AndroidEngineGroup::IsEngineActive(FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine_handle) const {
  if (engine_handle == nullptr) {
    return false;
  }
  std::scoped_lock lock(mutex_);
  auto it = handle_to_id_.find(engine_handle);
  if (it == handle_to_id_.end()) {
    return false;
  }
  auto record_it = active_engines_.find(it->second);
  return record_it != active_engines_.end() && record_it->second.is_running;
}

FLUTTER_API_SYMBOL(FlutterEngine)
AndroidEngineGroup::GetEngineHandle(int64_t engine_id) const {
  std::scoped_lock lock(mutex_);
  auto it = active_engines_.find(engine_id);
  if (it != active_engines_.end() && it->second.is_running) {
    return it->second.engine_handle;
  }
  return nullptr;
}

std::optional<int64_t> AndroidEngineGroup::GetEngineId(
    FLUTTER_API_SYMBOL(FlutterEngine) engine_handle) const {
  if (engine_handle == nullptr) {
    return std::nullopt;
  }
  std::scoped_lock lock(mutex_);
  auto it = handle_to_id_.find(engine_handle);
  if (it != handle_to_id_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<AndroidEngineSpawnArgs> AndroidEngineGroup::GetSpawnArgs(
    int64_t engine_id) const {
  std::scoped_lock lock(mutex_);
  auto it = active_engines_.find(engine_id);
  if (it != active_engines_.end()) {
    return it->second.spawn_args;
  }
  return std::nullopt;
}

std::vector<int64_t> AndroidEngineGroup::GetActiveEngineIds() const {
  std::scoped_lock lock(mutex_);
  std::vector<int64_t> ids;
  ids.reserve(active_engines_.size());
  for (const auto& [id, record] : active_engines_) {
    if (record.is_running) {
      ids.push_back(id);
    }
  }
  return ids;
}

std::vector<FLUTTER_API_SYMBOL(FlutterEngine)>
AndroidEngineGroup::GetActiveEngineHandles() const {
  std::scoped_lock lock(mutex_);
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> handles;
  handles.reserve(active_engines_.size());
  for (const auto& [id, record] : active_engines_) {
    if (record.is_running && record.engine_handle) {
      handles.push_back(record.engine_handle);
    }
  }
  return handles;
}

std::optional<AndroidEngineRecord> AndroidEngineGroup::GetEngineRecord(
    int64_t engine_id) const {
  std::scoped_lock lock(mutex_);
  auto it = active_engines_.find(engine_id);
  if (it != active_engines_.end()) {
    return it->second;
  }
  auto ret_it = retired_engines_.find(engine_id);
  if (ret_it != retired_engines_.end()) {
    return ret_it->second;
  }
  return std::nullopt;
}

std::shared_ptr<AndroidEngineGroupProvider> AndroidEngineGroup::GetProvider()
    const {
  std::scoped_lock lock(mutex_);
  return provider_;
}

void AndroidEngineGroup::SetProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  std::scoped_lock lock(mutex_);
  if (provider) {
    provider_ = std::move(provider);
  } else {
    provider_ =
        std::make_shared<DefaultAndroidEngineGroupProvider>(&proc_table_);
  }
}

std::shared_ptr<JvmInvoker> AndroidEngineGroup::GetJvmInvoker() const {
  std::scoped_lock lock(mutex_);
  return jvm_invoker_;
}

}  // namespace android
}  // namespace flutter
