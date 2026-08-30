// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_GROUP_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_GROUP_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Arguments for spawning a child FlutterEngine instance in an engine
/// group.
struct AndroidEngineSpawnArgs {
  /// Custom Dart entrypoint function name (e.g., "main").
  std::string entrypoint = "main";

  /// Custom library URI / path containing the entrypoint function.
  std::string library_url;

  /// Initial route for the spawned isolate (defaults to "/").
  std::string initial_route = "/";

  /// Command-line argument strings passed to the spawned Dart entrypoint.
  std::vector<std::string> entrypoint_args;

  /// Engine identifier assigned to this engine instance.
  int64_t engine_id = 0;

  /// User data baton passed back to callbacks.
  void* user_data = nullptr;

  bool operator==(const AndroidEngineSpawnArgs& other) const {
    return entrypoint == other.entrypoint && library_url == other.library_url &&
           initial_route == other.initial_route &&
           entrypoint_args == other.entrypoint_args &&
           engine_id == other.engine_id && user_data == other.user_data;
  }

  bool operator!=(const AndroidEngineSpawnArgs& other) const {
    return !(*this == other);
  }
};

/// @brief Configuration for initializing an engine group.
struct AndroidEngineGroupConfig {
  /// Dart VM flags / command line arguments for group VM configuration.
  std::vector<std::string> dart_vm_args;

  bool operator==(const AndroidEngineGroupConfig& other) const {
    return dart_vm_args == other.dart_vm_args;
  }

  bool operator!=(const AndroidEngineGroupConfig& other) const {
    return !(*this == other);
  }
};

/// @brief Record tracking an active engine instance managed by an
/// AndroidEngineGroup.
struct AndroidEngineRecord {
  /// Engine identifier.
  int64_t engine_id = 0;

  /// Underlying C-API FlutterEngine handle.
  FLUTTER_API_SYMBOL(FlutterEngine) engine_handle = nullptr;

  /// Arguments used to spawn or register this engine.
  AndroidEngineSpawnArgs spawn_args;

  /// Whether this engine instance is currently running.
  bool is_running = false;

  /// Whether this engine was cleaned up via JVM GC cleaner / PhantomReference.
  bool is_garbage_collected = false;

  /// Spawn timestamp in nanoseconds.
  int64_t spawned_time_nanos = 0;

  bool operator==(const AndroidEngineRecord& other) const {
    return engine_id == other.engine_id &&
           engine_handle == other.engine_handle &&
           spawn_args == other.spawn_args && is_running == other.is_running &&
           is_garbage_collected == other.is_garbage_collected &&
           spawned_time_nanos == other.spawned_time_nanos;
  }

  bool operator!=(const AndroidEngineRecord& other) const {
    return !(*this == other);
  }
};

/// @brief Helper class to assemble and own memory for FlutterEngineSpawnConfig
/// and FlutterProjectArgs during C-API engine spawning.
class AndroidEngineGroupSpawnConfigHolder {
 public:
  AndroidEngineGroupSpawnConfigHolder();
  ~AndroidEngineGroupSpawnConfigHolder();

  /// @brief Builds FlutterEngineSpawnConfig and FlutterProjectArgs from
  /// AndroidEngineSpawnArgs.
  void Build(const AndroidEngineSpawnArgs& args, void* user_data = nullptr);

  /// @brief Returns pointer to populated FlutterEngineSpawnConfig.
  const FlutterEngineSpawnConfig* GetSpawnConfig() const;

  /// @brief Returns pointer to populated FlutterProjectArgs.
  const FlutterProjectArgs* GetProjectArgs() const;

  /// @brief Returns stored entrypoint name.
  const std::string& GetEntrypoint() const;

  /// @brief Returns stored initial route.
  const std::string& GetInitialRoute() const;

  /// @brief Returns stored entrypoint args.
  const std::vector<std::string>& GetEntrypointArgs() const;

 private:
  FlutterEngineSpawnConfig spawn_config_{};
  FlutterProjectArgs project_args_{};
  std::string entrypoint_;
  std::string initial_route_;
  std::vector<std::string> entrypoint_args_;
  std::vector<const char*> argv_ptrs_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEngineGroupSpawnConfigHolder);
};

/// @brief Abstract provider interface for engine spawning and shutdown
/// operations.
///
/// Decouples AndroidEngineGroup from direct C-API symbols, enabling full host
/// testability.
class AndroidEngineGroupProvider {
 public:
  virtual ~AndroidEngineGroupProvider() = default;

  /// @brief Spawns a new engine sharing VM and resources with the parent
  /// engine.
  virtual FlutterEngineResult SpawnEngine(
      FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
      const FlutterEngineSpawnConfig* config,
      FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) = 0;

  /// @brief Shuts down a running engine instance and releases associated
  /// resources.
  virtual FlutterEngineResult ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                                 engine) = 0;

  /// @brief Initializes a top-level FlutterEngine instance.
  virtual FlutterEngineResult InitializeEngine(
      const FlutterRendererConfig* config,
      const FlutterProjectArgs* args,
      void* user_data,
      FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) = 0;

  /// @brief Deinitializes a FlutterEngine instance without freeing container
  /// memory.
  virtual FlutterEngineResult DeinitializeEngine(
      FLUTTER_API_SYMBOL(FlutterEngine) engine) = 0;
};

/// @brief Default production engine group provider dispatching directly to
/// C-API embedder.
class DefaultAndroidEngineGroupProvider : public AndroidEngineGroupProvider {
 public:
  DefaultAndroidEngineGroupProvider();
  ~DefaultAndroidEngineGroupProvider() override;

  FlutterEngineResult SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                      parent_engine,
                                  const FlutterEngineSpawnConfig* config,
                                  FLUTTER_API_SYMBOL(FlutterEngine) *
                                      engine_out) override;

  FlutterEngineResult ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                         engine) override;

  FlutterEngineResult InitializeEngine(const FlutterRendererConfig* config,
                                       const FlutterProjectArgs* args,
                                       void* user_data,
                                       FLUTTER_API_SYMBOL(FlutterEngine) *
                                           engine_out) override;

  FlutterEngineResult DeinitializeEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine) override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidEngineGroupProvider);
};

/// @brief In-memory mock engine group provider for host unit testing.
class InMemoryAndroidEngineGroupProvider : public AndroidEngineGroupProvider {
 public:
  InMemoryAndroidEngineGroupProvider();
  ~InMemoryAndroidEngineGroupProvider() override;

  void SetSpawnResult(FlutterEngineResult result);
  void SetShutdownResult(FlutterEngineResult result);
  void SetInitializeResult(FlutterEngineResult result);
  void SetDeinitializeResult(FlutterEngineResult result);

  size_t GetSpawnCallCount() const;
  size_t GetShutdownCallCount() const;
  size_t GetInitializeCallCount() const;
  size_t GetDeinitializeCallCount() const;
  size_t GetActiveHandleCount() const;
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> GetShutdownHandles() const;
  std::optional<AndroidEngineSpawnArgs> GetLastSpawnArgs() const;
  void SetMockEngineHandle(FLUTTER_API_SYMBOL(FlutterEngine) handle);
  void Reset();

  FlutterEngineResult SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                      parent_engine,
                                  const FlutterEngineSpawnConfig* config,
                                  FLUTTER_API_SYMBOL(FlutterEngine) *
                                      engine_out) override;

  FlutterEngineResult ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                         engine) override;

  FlutterEngineResult InitializeEngine(const FlutterRendererConfig* config,
                                       const FlutterProjectArgs* args,
                                       void* user_data,
                                       FLUTTER_API_SYMBOL(FlutterEngine) *
                                           engine_out) override;

  FlutterEngineResult DeinitializeEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine) override;

 private:
  mutable std::mutex mutex_;
  FlutterEngineResult spawn_result_ = kSuccess;
  FlutterEngineResult shutdown_result_ = kSuccess;
  FlutterEngineResult initialize_result_ = kSuccess;
  FlutterEngineResult deinitialize_result_ = kSuccess;

  size_t spawn_call_count_ = 0;
  size_t shutdown_call_count_ = 0;
  size_t initialize_call_count_ = 0;
  size_t deinitialize_call_count_ = 0;

  uintptr_t next_mock_handle_ = 0x2000;
  FLUTTER_API_SYMBOL(FlutterEngine) custom_mock_handle_ = nullptr;
  std::unordered_set<FLUTTER_API_SYMBOL(FlutterEngine)> active_handles_;
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> shutdown_handles_;
  std::optional<AndroidEngineSpawnArgs> last_spawn_args_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidEngineGroupProvider);
};

/// @brief Coordinates multi-engine Add-to-App lifecycle, engine spawning, and
/// GC Cleaner / PhantomReference cleanup registry.
class AndroidEngineGroup {
 public:
  explicit AndroidEngineGroup(
      std::shared_ptr<AndroidEngineGroupProvider> provider = nullptr,
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  virtual ~AndroidEngineGroup();

  /// @brief Initializes group settings and configurations.
  bool InitializeGroup(const AndroidEngineGroupConfig& config = {});

  /// @brief Returns whether the group has been initialized.
  bool IsInitialized() const;

  /// @brief Returns group configuration.
  const AndroidEngineGroupConfig& GetConfig() const;

  /// @brief Sets the primary / root FlutterEngine handle in this group.
  void SetPrimaryEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                        int64_t engine_id = 0);

  /// @brief Returns the primary / root FlutterEngine handle in this group.
  FLUTTER_API_SYMBOL(FlutterEngine) GetPrimaryEngine() const;

  /// @brief Returns the primary / root FlutterEngine ID in this group.
  int64_t GetPrimaryEngineId() const;

  /// @brief Spawns a new engine from a parent engine handle with spawn args.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
              const AndroidEngineSpawnArgs& args);

  /// @brief Spawns a new engine from a parent engine ID with spawn args.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(int64_t parent_engine_id, const AndroidEngineSpawnArgs& args);

  /// @brief Spawns a new engine using a raw FlutterEngineSpawnConfig struct.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngineWithConfig(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
                        const FlutterEngineSpawnConfig* config,
                        int64_t engine_id = 0);

  /// @brief Shuts down an engine by ID, releasing its resources via provider.
  bool ShutdownEngine(int64_t engine_id);

  /// @brief Shuts down an engine by handle, releasing its resources via
  /// provider.
  bool ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine_handle);

  /// @brief Shuts down all active engines in the group.
  bool ShutdownAllEngines();

  /// @brief Callback invoked by Java Cleaner / PhantomReference when an engine
  /// is GC'd.
  bool OnEngineGarbageCollected(int64_t engine_id);

  /// @brief Registers an externally created or existing engine handle into the
  /// tracking registry.
  bool RegisterEngine(int64_t engine_id,
                      FLUTTER_API_SYMBOL(FlutterEngine) engine_handle,
                      const AndroidEngineSpawnArgs& args = {});

  /// @brief De-registers an engine handle from the tracking registry without
  /// shutting it down.
  bool UnregisterEngine(int64_t engine_id);

  /// @brief Returns the count of active, running engines in the group.
  size_t GetActiveEngineCount() const;

  /// @brief Returns true if an engine with the specified ID is currently
  /// active.
  bool IsEngineActive(int64_t engine_id) const;

  /// @brief Returns true if the specified engine handle is currently active.
  bool IsEngineActive(FLUTTER_API_SYMBOL(FlutterEngine) engine_handle) const;

  /// @brief Returns the engine handle for an engine ID.
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngineHandle(int64_t engine_id) const;

  /// @brief Returns the engine ID for an engine handle.
  std::optional<int64_t> GetEngineId(FLUTTER_API_SYMBOL(FlutterEngine)
                                         engine_handle) const;

  /// @brief Returns the spawn args for an engine ID.
  std::optional<AndroidEngineSpawnArgs> GetSpawnArgs(int64_t engine_id) const;

  /// @brief Returns the list of all active engine IDs.
  std::vector<int64_t> GetActiveEngineIds() const;

  /// @brief Returns the list of all active engine handles.
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> GetActiveEngineHandles() const;

  /// @brief Returns the engine record for an engine ID.
  std::optional<AndroidEngineRecord> GetEngineRecord(int64_t engine_id) const;

  /// @brief Returns the underlying engine group provider.
  std::shared_ptr<AndroidEngineGroupProvider> GetProvider() const;

  /// @brief Sets or replaces the engine group provider.
  void SetProvider(std::shared_ptr<AndroidEngineGroupProvider> provider);

  /// @brief Returns the underlying JvmInvoker.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<AndroidEngineGroupProvider> provider_;
  std::shared_ptr<JvmInvoker> jvm_invoker_;

  mutable std::mutex mutex_;
  bool initialized_ = false;
  AndroidEngineGroupConfig config_;

  FLUTTER_API_SYMBOL(FlutterEngine) primary_engine_ = nullptr;
  int64_t primary_engine_id_ = 0;
  int64_t next_auto_engine_id_ = 1000;

  std::map<int64_t, AndroidEngineRecord> active_engines_;
  std::map<FLUTTER_API_SYMBOL(FlutterEngine), int64_t> handle_to_id_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEngineGroup);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_GROUP_H_
