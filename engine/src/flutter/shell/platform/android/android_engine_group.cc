// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_engine_group.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

// =============================================================================
// AndroidEngineGroupSpawnConfigHolder Implementation
// =============================================================================

AndroidEngineGroupSpawnConfigHolder::AndroidEngineGroupSpawnConfigHolder() {
  TRACE_EVENT0("flutter",
               "AndroidEngineGroupSpawnConfigHolder::"
               "AndroidEngineGroupSpawnConfigHolder");
}

AndroidEngineGroupSpawnConfigHolder::~AndroidEngineGroupSpawnConfigHolder() {
  TRACE_EVENT0("flutter",
               "AndroidEngineGroupSpawnConfigHolder::"
               "~AndroidEngineGroupSpawnConfigHolder");
}

void AndroidEngineGroupSpawnConfigHolder::Build(
    const AndroidEngineSpawnArgs& args,
    void* user_data) {
  TRACE_EVENT0("flutter", "AndroidEngineGroupSpawnConfigHolder::Build");
  entrypoint_ = args.entrypoint;
  initial_route_ = args.initial_route;
  entrypoint_args_ = args.entrypoint_args;

  argv_ptrs_.clear();
  argv_ptrs_.reserve(entrypoint_args_.size());
  for (const auto& arg : entrypoint_args_) {
    argv_ptrs_.push_back(arg.c_str());
  }

  project_args_ = {};
  project_args_.struct_size = sizeof(FlutterProjectArgs);
  if (!entrypoint_.empty()) {
    project_args_.custom_dart_entrypoint = entrypoint_.c_str();
  }
  project_args_.dart_entrypoint_argc = static_cast<int>(argv_ptrs_.size());
  project_args_.dart_entrypoint_argv =
      argv_ptrs_.empty() ? nullptr : argv_ptrs_.data();
  project_args_.engine_id = args.engine_id;

  // Note: args.library_url is retained on the AndroidEngineSpawnArgs metadata
  // record and does not require explicit C-API FlutterProjectArgs mapping as
  // entrypoint resolution uses the root kernel library by default.
  spawn_config_ = {};
  spawn_config_.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config_.custom_args = &project_args_;
  spawn_config_.custom_renderer_config = nullptr;
  spawn_config_.user_data = user_data ? user_data : args.user_data;
  spawn_config_.initial_route =
      initial_route_.empty() ? nullptr : initial_route_.c_str();
}

const FlutterEngineSpawnConfig*
AndroidEngineGroupSpawnConfigHolder::GetSpawnConfig() const {
  return &spawn_config_;
}

const FlutterProjectArgs* AndroidEngineGroupSpawnConfigHolder::GetProjectArgs()
    const {
  return &project_args_;
}

const std::string& AndroidEngineGroupSpawnConfigHolder::GetEntrypoint() const {
  return entrypoint_;
}

const std::string& AndroidEngineGroupSpawnConfigHolder::GetInitialRoute()
    const {
  return initial_route_;
}

const std::vector<std::string>&
AndroidEngineGroupSpawnConfigHolder::GetEntrypointArgs() const {
  return entrypoint_args_;
}

// =============================================================================
// DefaultAndroidEngineGroupProvider Implementation
// =============================================================================

namespace {

const FlutterEngineProcTable& GetEngineProcTable() {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  return s_procs;
}

}  // namespace

DefaultAndroidEngineGroupProvider::DefaultAndroidEngineGroupProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::"
               "DefaultAndroidEngineGroupProvider");
}

DefaultAndroidEngineGroupProvider::~DefaultAndroidEngineGroupProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidEngineGroupProvider::"
               "~DefaultAndroidEngineGroupProvider");
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnConfig* config,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter", "DefaultAndroidEngineGroupProvider::SpawnEngine");
  if (!parent_engine || !config || !engine_out) {
    return kInvalidArguments;
  }
  const auto& procs = GetEngineProcTable();
  if (procs.Spawn) {
    return procs.Spawn(parent_engine, config, engine_out);
  }
  return kInternalInconsistency;
}

FlutterEngineResult DefaultAndroidEngineGroupProvider::ShutdownEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter", "DefaultAndroidEngineGroupProvider::ShutdownEngine");
  if (!engine) {
    return kInvalidArguments;
  }
  const auto& procs = GetEngineProcTable();
  if (procs.Shutdown) {
    return procs.Shutdown(engine);
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
  if (!config || !args || !engine_out) {
    return kInvalidArguments;
  }
  const auto& procs = GetEngineProcTable();
  if (procs.Initialize) {
    return procs.Initialize(FLUTTER_ENGINE_VERSION, config, args, user_data,
                            engine_out);
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
  const auto& procs = GetEngineProcTable();
  if (procs.Deinitialize) {
    return procs.Deinitialize(engine);
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
  TRACE_EVENT0("flutter", "InMemoryAndroidEngineGroupProvider::SetSpawnResult");
  std::scoped_lock lock(mutex_);
  spawn_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetShutdownResult(
    FlutterEngineResult result) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::SetShutdownResult");
  std::scoped_lock lock(mutex_);
  shutdown_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetInitializeResult(
    FlutterEngineResult result) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::SetInitializeResult");
  std::scoped_lock lock(mutex_);
  initialize_result_ = result;
}

void InMemoryAndroidEngineGroupProvider::SetDeinitializeResult(
    FlutterEngineResult result) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::SetDeinitializeResult");
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
  TRACE_EVENT0("flutter",
               "InMemoryAndroidEngineGroupProvider::SetMockEngineHandle");
  std::scoped_lock lock(mutex_);
  custom_mock_handle_ = handle;
}

void InMemoryAndroidEngineGroupProvider::Reset() {
  TRACE_EVENT0("flutter", "InMemoryAndroidEngineGroupProvider::Reset");
  std::scoped_lock lock(mutex_);
  spawn_result_ = kSuccess;
  shutdown_result_ = kSuccess;
  initialize_result_ = kSuccess;
  deinitialize_result_ = kSuccess;
  spawn_call_count_ = 0;
  shutdown_call_count_ = 0;
  initialize_call_count_ = 0;
  deinitialize_call_count_ = 0;
  next_mock_handle_ = 0x2000;
  custom_mock_handle_ = nullptr;
  active_handles_.clear();
  shutdown_handles_.clear();
  last_spawn_args_.reset();
}

FlutterEngineResult InMemoryAndroidEngineGroupProvider::SpawnEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnConfig* config,
    FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
  TRACE_EVENT0("flutter", "InMemoryAndroidEngineGroupProvider::SpawnEngine");
  std::scoped_lock lock(mutex_);
  spawn_call_count_++;

  if (parent_engine == nullptr || config == nullptr || engine_out == nullptr) {
    return kInvalidArguments;
  }
  if (config->struct_size != sizeof(FlutterEngineSpawnConfig)) {
    return kInvalidArguments;
  }

  if (spawn_result_ != kSuccess) {
    return spawn_result_;
  }

  AndroidEngineSpawnArgs recorded_args;
  if (config->custom_args &&
      config->custom_args->struct_size == sizeof(FlutterProjectArgs)) {
    if (config->custom_args->custom_dart_entrypoint) {
      recorded_args.entrypoint = config->custom_args->custom_dart_entrypoint;
    }
    if (config->custom_args->dart_entrypoint_argv &&
        config->custom_args->dart_entrypoint_argc > 0) {
      for (int i = 0; i < config->custom_args->dart_entrypoint_argc; ++i) {
        if (config->custom_args->dart_entrypoint_argv[i]) {
          recorded_args.entrypoint_args.emplace_back(
              config->custom_args->dart_entrypoint_argv[i]);
        }
      }
    }
    recorded_args.engine_id = config->custom_args->engine_id;
  }
  if (config->initial_route) {
    recorded_args.initial_route = config->initial_route;
  }
  recorded_args.user_data = config->user_data;
  last_spawn_args_ = recorded_args;

  FLUTTER_API_SYMBOL(FlutterEngine) generated_handle = nullptr;
  if (custom_mock_handle_ != nullptr) {
    generated_handle = custom_mock_handle_;
  } else {
    next_mock_handle_ += 0x100;
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
  std::scoped_lock lock(mutex_);
  initialize_call_count_++;

  if (engine_out == nullptr) {
    return kInvalidArguments;
  }

  if (initialize_result_ != kSuccess) {
    return initialize_result_;
  }

  next_mock_handle_ += 0x100;
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
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : provider_(provider
                    ? std::move(provider)
                    : std::make_shared<DefaultAndroidEngineGroupProvider>()),
      jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::AndroidEngineGroup");
}

AndroidEngineGroup::~AndroidEngineGroup() {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::~AndroidEngineGroup");
  ShutdownAllEngines();
}

bool AndroidEngineGroup::InitializeGroup(
    const AndroidEngineGroupConfig& config) {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::InitializeGroup");
  std::scoped_lock lock(mutex_);
  config_ = config;
  initialized_ = true;
  return true;
}

bool AndroidEngineGroup::IsInitialized() const {
  std::scoped_lock lock(mutex_);
  return initialized_;
}

const AndroidEngineGroupConfig& AndroidEngineGroup::GetConfig() const {
  std::scoped_lock lock(mutex_);
  return config_;
}

void AndroidEngineGroup::SetPrimaryEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                              engine,
                                          int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::SetPrimaryEngine", "engine_id",
               std::to_string(engine_id).c_str());
  std::scoped_lock lock(mutex_);
  primary_engine_ = engine;
  primary_engine_id_ = engine_id;
  if (engine != nullptr && engine_id != 0) {
    AndroidEngineRecord record;
    record.engine_id = engine_id;
    record.engine_handle = engine;
    record.is_running = true;
    record.is_garbage_collected = false;
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

  AndroidEngineGroupSpawnConfigHolder holder;
  holder.Build(args);

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
      parent_engine, holder.GetSpawnConfig(), &spawned_handle);

  if (result != kSuccess || spawned_handle == nullptr) {
    FML_LOG(ERROR) << "Failed to spawn Flutter engine, result: " << result;
    return nullptr;
  }

  int64_t assigned_engine_id = args.engine_id;
  {
    std::scoped_lock lock(mutex_);
    if (assigned_engine_id == 0) {
      assigned_engine_id = next_auto_engine_id_++;
    }

    AndroidEngineRecord record;
    record.engine_id = assigned_engine_id;
    record.engine_handle = spawned_handle;
    record.spawn_args = args;
    record.spawn_args.engine_id = assigned_engine_id;
    record.is_running = true;
    record.is_garbage_collected = false;

    active_engines_[assigned_engine_id] = record;
    handle_to_id_[spawned_handle] = assigned_engine_id;
  }

  if (jvm_invoker_) {
    jvm_invoker_->InvokeBooleanMethod(
        "onEngineSpawned", "(J)Z",
        std::vector<uint8_t>(
            reinterpret_cast<const uint8_t*>(&assigned_engine_id),
            reinterpret_cast<const uint8_t*>(&assigned_engine_id) +
                sizeof(assigned_engine_id)));
  }

  return spawned_handle;
}

FLUTTER_API_SYMBOL(FlutterEngine)
AndroidEngineGroup::SpawnEngine(int64_t parent_engine_id,
                                const AndroidEngineSpawnArgs& args) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::SpawnEngine(by id)",
               "parent_engine_id", std::to_string(parent_engine_id).c_str());
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
AndroidEngineGroup::SpawnEngineWithConfig(
    FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
    const FlutterEngineSpawnConfig* config,
    int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::SpawnEngineWithConfig",
               "engine_id", std::to_string(engine_id).c_str());
  if (parent_engine == nullptr || config == nullptr) {
    FML_LOG(ERROR) << "Cannot spawn engine: invalid parent or config pointer.";
    return nullptr;
  }

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
  FlutterEngineResult result =
      provider->SpawnEngine(parent_engine, config, &spawned_handle);

  if (result != kSuccess || spawned_handle == nullptr) {
    FML_LOG(ERROR) << "Failed to spawn Flutter engine with config, result: "
                   << result;
    return nullptr;
  }

  int64_t assigned_engine_id = engine_id;
  {
    std::scoped_lock lock(mutex_);
    if (assigned_engine_id == 0) {
      if (config->custom_args &&
          config->custom_args->struct_size == sizeof(FlutterProjectArgs) &&
          config->custom_args->engine_id != 0) {
        assigned_engine_id = config->custom_args->engine_id;
      } else {
        assigned_engine_id = next_auto_engine_id_++;
      }
    }

    AndroidEngineRecord record;
    record.engine_id = assigned_engine_id;
    record.engine_handle = spawned_handle;
    record.is_running = true;
    record.is_garbage_collected = false;

    if (config->custom_args &&
        config->custom_args->struct_size == sizeof(FlutterProjectArgs)) {
      if (config->custom_args->custom_dart_entrypoint) {
        record.spawn_args.entrypoint =
            config->custom_args->custom_dart_entrypoint;
      }
      if (config->custom_args->dart_entrypoint_argv &&
          config->custom_args->dart_entrypoint_argc > 0) {
        for (int i = 0; i < config->custom_args->dart_entrypoint_argc; ++i) {
          if (config->custom_args->dart_entrypoint_argv[i]) {
            record.spawn_args.entrypoint_args.emplace_back(
                config->custom_args->dart_entrypoint_argv[i]);
          }
        }
      }
    }
    if (config->initial_route) {
      record.spawn_args.initial_route = config->initial_route;
    }
    record.spawn_args.engine_id = assigned_engine_id;
    record.spawn_args.user_data = config->user_data;

    active_engines_[assigned_engine_id] = record;
    handle_to_id_[spawned_handle] = assigned_engine_id;
  }

  if (jvm_invoker_) {
    jvm_invoker_->InvokeBooleanMethod(
        "onEngineSpawned", "(J)Z",
        std::vector<uint8_t>(
            reinterpret_cast<const uint8_t*>(&assigned_engine_id),
            reinterpret_cast<const uint8_t*>(&assigned_engine_id) +
                sizeof(assigned_engine_id)));
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
    handle_to_shutdown = it->second.engine_handle;
    if (handle_to_shutdown) {
      handle_to_id_.erase(handle_to_shutdown);
    }
    active_engines_.erase(it);
    if (primary_engine_id_ == engine_id) {
      primary_engine_id_ = 0;
      primary_engine_ = nullptr;
    }
  }

  if (handle_to_shutdown && provider) {
    provider->ShutdownEngine(handle_to_shutdown);
  }

  if (jvm_invoker_) {
    jvm_invoker_->InvokeBooleanMethod(
        "onEngineDestroyed", "(J)Z",
        std::vector<uint8_t>(
            reinterpret_cast<const uint8_t*>(&engine_id),
            reinterpret_cast<const uint8_t*>(&engine_id) + sizeof(engine_id)));
  }

  return true;
}

bool AndroidEngineGroup::ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine_handle) {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::ShutdownEngine(handle)");
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
  TRACE_EVENT0("flutter", "AndroidEngineGroup::ShutdownAllEngines");
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
    handle_to_shutdown = it->second.engine_handle;
    if (handle_to_shutdown) {
      handle_to_id_.erase(handle_to_shutdown);
    }
    active_engines_.erase(it);
    if (primary_engine_id_ == engine_id) {
      primary_engine_id_ = 0;
      primary_engine_ = nullptr;
    }
  }

  if (handle_to_shutdown && provider) {
    provider->ShutdownEngine(handle_to_shutdown);
  }

  if (jvm_invoker_) {
    jvm_invoker_->InvokeBooleanMethod(
        "onEngineCleanerTriggered", "(J)Z",
        std::vector<uint8_t>(
            reinterpret_cast<const uint8_t*>(&engine_id),
            reinterpret_cast<const uint8_t*>(&engine_id) + sizeof(engine_id)));
  }

  return true;
}

bool AndroidEngineGroup::RegisterEngine(int64_t engine_id,
                                        FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine_handle,
                                        const AndroidEngineSpawnArgs& args) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::RegisterEngine", "engine_id",
               std::to_string(engine_id).c_str());
  if (engine_id == 0 || engine_handle == nullptr) {
    return false;
  }
  std::scoped_lock lock(mutex_);
  AndroidEngineRecord record;
  record.engine_id = engine_id;
  record.engine_handle = engine_handle;
  record.spawn_args = args;
  record.spawn_args.engine_id = engine_id;
  record.is_running = true;
  record.is_garbage_collected = false;

  active_engines_[engine_id] = record;
  handle_to_id_[engine_handle] = engine_id;
  if (primary_engine_ == nullptr) {
    primary_engine_ = engine_handle;
    primary_engine_id_ = engine_id;
  }
  return true;
}

bool AndroidEngineGroup::UnregisterEngine(int64_t engine_id) {
  TRACE_EVENT1("flutter", "AndroidEngineGroup::UnregisterEngine", "engine_id",
               std::to_string(engine_id).c_str());
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
  return std::nullopt;
}

std::shared_ptr<AndroidEngineGroupProvider> AndroidEngineGroup::GetProvider()
    const {
  std::scoped_lock lock(mutex_);
  return provider_;
}

void AndroidEngineGroup::SetProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  TRACE_EVENT0("flutter", "AndroidEngineGroup::SetProvider");
  std::scoped_lock lock(mutex_);
  if (provider) {
    provider_ = std::move(provider);
  } else {
    provider_ = std::make_shared<DefaultAndroidEngineGroupProvider>();
  }
}

std::shared_ptr<JvmInvoker> AndroidEngineGroup::GetJvmInvoker() const {
  std::scoped_lock lock(mutex_);
  return jvm_invoker_;
}

}  // namespace android
}  // namespace flutter
