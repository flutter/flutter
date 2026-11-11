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

// Starting auto-assigned identifier for spawned engines when engine_id is 0.
constexpr int64_t kInitialAutoEngineId = 1000;
// Base synthetic pointer address for mock spawned engines in host tests.
constexpr uintptr_t kInitialMockEngineAddress = 0x2000;
// Address stride between consecutive synthetic engine handles in host tests.
constexpr uintptr_t kMockEngineAddressStride = 0x100;

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

  /// User data baton passed back to callbacks for the spawned child engine.
  void* user_data = nullptr;

  /// Optional per-engine compositor for the spawned child engine.
  const FlutterCompositor* compositor = nullptr;

  bool operator==(const AndroidEngineSpawnArgs& other) const {
    return entrypoint == other.entrypoint && library_url == other.library_url &&
           initial_route == other.initial_route &&
           entrypoint_args == other.entrypoint_args &&
           engine_id == other.engine_id && user_data == other.user_data &&
           compositor == other.compositor;
  }

  bool operator!=(const AndroidEngineSpawnArgs& other) const {
    return !(*this == other);
  }
};

/// @brief Configuration for initializing an engine group.
struct AndroidEngineGroupConfig {
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
  int64_t engine_id = 0;
  FLUTTER_API_SYMBOL(FlutterEngine) engine_handle = nullptr;
  AndroidEngineSpawnArgs spawn_args;
  bool is_running = false;
  bool is_garbage_collected = false;
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

/// @brief Helper class to assemble and own memory for FlutterEngineSpawnInfo
/// during C-API engine spawning.
class AndroidEngineGroupSpawnInfoHolder {
 public:
  AndroidEngineGroupSpawnInfoHolder();
  ~AndroidEngineGroupSpawnInfoHolder();

  /// @brief Builds FlutterEngineSpawnInfo from AndroidEngineSpawnArgs.
  void Build(const AndroidEngineSpawnArgs& args,
             void* user_data = nullptr,
             const FlutterCompositor* compositor = nullptr);

  /// @brief Returns pointer to populated FlutterEngineSpawnInfo.
  const FlutterEngineSpawnInfo* GetSpawnInfo() const;

  const std::string& GetEntrypoint() const;
  const std::string& GetLibraryUrl() const;
  const std::string& GetInitialRoute() const;
  const std::vector<std::string>& GetEntrypointArgs() const;

 private:
  FlutterEngineSpawnInfo spawn_info_{};
  std::string entrypoint_;
  std::string library_url_;
  std::string initial_route_;
  std::vector<std::string> entrypoint_args_;
  std::vector<const char*> argv_ptrs_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEngineGroupSpawnInfoHolder);
};

/// @brief Abstract provider interface for engine spawning and shutdown
/// operations via FlutterEngineProcTable.
class AndroidEngineGroupProvider {
 public:
  virtual ~AndroidEngineGroupProvider() = default;

  virtual FlutterEngineResult SpawnEngine(
      FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
      const FlutterEngineSpawnInfo* spawn_info,
      FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) = 0;

  virtual FlutterEngineResult ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                                 engine) = 0;

  virtual FlutterEngineResult InitializeEngine(
      const FlutterRendererConfig* config,
      const FlutterProjectArgs* args,
      void* user_data,
      FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) = 0;

  virtual FlutterEngineResult DeinitializeEngine(
      FLUTTER_API_SYMBOL(FlutterEngine) engine) = 0;
};

/// @brief Default production engine group provider dispatching through
/// FlutterEngineProcTable.
class DefaultAndroidEngineGroupProvider : public AndroidEngineGroupProvider {
 public:
  explicit DefaultAndroidEngineGroupProvider(
      const FlutterEngineProcTable* proc_table = nullptr);
  ~DefaultAndroidEngineGroupProvider() override;

  FlutterEngineResult SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                      parent_engine,
                                  const FlutterEngineSpawnInfo* spawn_info,
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
  FlutterEngineProcTable proc_table_{};

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
                                  const FlutterEngineSpawnInfo* spawn_info,
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

  uintptr_t next_mock_handle_ = kInitialMockEngineAddress;
  FLUTTER_API_SYMBOL(FlutterEngine) custom_mock_handle_ = nullptr;
  std::unordered_set<FLUTTER_API_SYMBOL(FlutterEngine)> active_handles_;
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> shutdown_handles_;
  std::optional<AndroidEngineSpawnArgs> last_spawn_args_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidEngineGroupProvider);
};

/// @brief Coordinates multi-engine Add-to-App lifecycle, engine spawning via
/// FlutterEngineSpawnInfo, and GC Cleaner / PhantomReference cleanup registry.
class AndroidEngineGroup {
 public:
  explicit AndroidEngineGroup(
      std::shared_ptr<AndroidEngineGroupProvider> provider = nullptr,
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr,
      const FlutterEngineProcTable* proc_table = nullptr);
  virtual ~AndroidEngineGroup();

  bool InitializeGroup(const AndroidEngineGroupConfig& config = {});
  bool IsInitialized() const;
  AndroidEngineGroupConfig GetConfig() const;

  void SetPrimaryEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                        int64_t engine_id = 0);
  FLUTTER_API_SYMBOL(FlutterEngine) GetPrimaryEngine() const;
  int64_t GetPrimaryEngineId() const;

  /// @brief Spawns a new engine from a parent engine handle with spawn args.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
              const AndroidEngineSpawnArgs& args);

  /// @brief Spawns a new engine from a parent engine ID with spawn args.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(int64_t parent_engine_id, const AndroidEngineSpawnArgs& args);

  /// @brief Spawns a new engine using a raw FlutterEngineSpawnInfo struct.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngineWithInfo(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
                      const FlutterEngineSpawnInfo* spawn_info,
                      int64_t engine_id = 0);

  bool ShutdownEngine(int64_t engine_id);
  bool ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine_handle);
  bool ShutdownAllEngines();
  bool OnEngineGarbageCollected(int64_t engine_id);

  bool RegisterEngine(int64_t engine_id,
                      FLUTTER_API_SYMBOL(FlutterEngine) engine_handle,
                      const AndroidEngineSpawnArgs& args = {});
  bool UnregisterEngine(int64_t engine_id);

  size_t GetActiveEngineCount() const;
  bool IsEngineActive(int64_t engine_id) const;
  bool IsEngineActive(FLUTTER_API_SYMBOL(FlutterEngine) engine_handle) const;

  FLUTTER_API_SYMBOL(FlutterEngine) GetEngineHandle(int64_t engine_id) const;
  std::optional<int64_t> GetEngineId(FLUTTER_API_SYMBOL(FlutterEngine)
                                         engine_handle) const;
  std::optional<AndroidEngineSpawnArgs> GetSpawnArgs(int64_t engine_id) const;
  std::vector<int64_t> GetActiveEngineIds() const;
  std::vector<FLUTTER_API_SYMBOL(FlutterEngine)> GetActiveEngineHandles() const;
  std::optional<AndroidEngineRecord> GetEngineRecord(int64_t engine_id) const;

  std::shared_ptr<AndroidEngineGroupProvider> GetProvider() const;
  void SetProvider(std::shared_ptr<AndroidEngineGroupProvider> provider);
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  FlutterEngineProcTable proc_table_{};
  std::shared_ptr<AndroidEngineGroupProvider> provider_;
  std::shared_ptr<JvmInvoker> jvm_invoker_;

  mutable std::mutex mutex_;
  bool initialized_ = false;
  AndroidEngineGroupConfig config_;

  FLUTTER_API_SYMBOL(FlutterEngine) primary_engine_ = nullptr;
  int64_t primary_engine_id_ = 0;
  int64_t next_auto_engine_id_ = kInitialAutoEngineId;

  std::map<int64_t, AndroidEngineRecord> active_engines_;
  std::map<FLUTTER_API_SYMBOL(FlutterEngine), int64_t> handle_to_id_;
  std::map<int64_t, AndroidEngineRecord> retired_engines_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEngineGroup);
};

}  // namespace android

using AndroidEngineSpawnArgs = android::AndroidEngineSpawnArgs;
using AndroidEngineGroupConfig = android::AndroidEngineGroupConfig;
using AndroidEngineRecord = android::AndroidEngineRecord;
using AndroidEngineGroupSpawnInfoHolder =
    android::AndroidEngineGroupSpawnInfoHolder;
using AndroidEngineGroupProvider = android::AndroidEngineGroupProvider;
using DefaultAndroidEngineGroupProvider =
    android::DefaultAndroidEngineGroupProvider;
using InMemoryAndroidEngineGroupProvider =
    android::InMemoryAndroidEngineGroupProvider;
using AndroidEngineGroup = android::AndroidEngineGroup;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_GROUP_H_
