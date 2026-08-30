// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;

namespace {

class MockJvmInvokerForEngineGroup : public JvmInvoker {
 public:
  MOCK_METHOD(bool, EnsureAttachedToThread, (), (override));
  MOCK_METHOD(void, DetachFromThread, (), (override));
  MOCK_METHOD(bool, HasPendingException, (), (const, override));
  MOCK_METHOD(void, ClearPendingException, (), (override));

  MOCK_METHOD(bool,
              InvokeVoidMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool,
              InvokeBooleanMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(int64_t,
              InvokeIntMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(double,
              InvokeDoubleMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::string,
              InvokeStringMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::vector<uint8_t>,
              InvokeBytesMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

}  // namespace

// =============================================================================
// 1. Types & Data Structures Tests
// =============================================================================

TEST(AndroidEngineGroupTypesTest, SpawnArgsDefaultsAndEquality) {
  AndroidEngineSpawnArgs args1;
  EXPECT_EQ(args1.entrypoint, "main");
  EXPECT_TRUE(args1.library_url.empty());
  EXPECT_EQ(args1.initial_route, "/");
  EXPECT_TRUE(args1.entrypoint_args.empty());
  EXPECT_EQ(args1.engine_id, 0);
  EXPECT_EQ(args1.user_data, nullptr);

  AndroidEngineSpawnArgs args2;
  args2.entrypoint = "customEntrypoint";
  args2.library_url = "lib/custom.dart";
  args2.initial_route = "/settings";
  args2.entrypoint_args = {"--flag1", "--flag2=val"};
  args2.engine_id = 42;
  void* dummy_user_data = reinterpret_cast<void*>(0x1234);
  args2.user_data = dummy_user_data;

  AndroidEngineSpawnArgs args3 = args2;
  EXPECT_EQ(args2, args3);
  EXPECT_NE(args1, args2);

  args3.entrypoint = "otherEntrypoint";
  EXPECT_NE(args2, args3);
}

TEST(AndroidEngineGroupTypesTest, GroupConfigDefaultsAndEquality) {
  AndroidEngineGroupConfig config1;
  EXPECT_TRUE(config1.dart_vm_args.empty());

  AndroidEngineGroupConfig config2;
  config2.dart_vm_args = {"--enable-checked-mode", "--verify-entry-points"};

  AndroidEngineGroupConfig config3 = config2;
  EXPECT_EQ(config2, config3);
  EXPECT_NE(config1, config2);
}

TEST(AndroidEngineGroupTypesTest, RecordDefaultsAndEquality) {
  AndroidEngineRecord record1;
  EXPECT_EQ(record1.engine_id, 0);
  EXPECT_EQ(record1.engine_handle, nullptr);
  EXPECT_FALSE(record1.is_running);
  EXPECT_FALSE(record1.is_garbage_collected);
  EXPECT_EQ(record1.spawned_time_nanos, 0);

  AndroidEngineRecord record2;
  record2.engine_id = 100;
  record2.engine_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x5000);
  record2.spawn_args.entrypoint = "myMain";
  record2.is_running = true;
  record2.is_garbage_collected = false;
  record2.spawned_time_nanos = 1000000;

  AndroidEngineRecord record3 = record2;
  EXPECT_EQ(record2, record3);
  EXPECT_NE(record1, record2);

  record3.is_running = false;
  EXPECT_NE(record2, record3);
}

TEST(AndroidEngineGroupTypesTest, SpawnConfigHolderBuildAndLifetime) {
  AndroidEngineSpawnArgs args;
  args.entrypoint = "customMain";
  args.initial_route = "/profile";
  args.entrypoint_args = {"arg1", "arg2", "arg3"};
  args.engine_id = 999;
  void* custom_user_data = reinterpret_cast<void*>(0x8888);
  args.user_data = custom_user_data;

  AndroidEngineGroupSpawnConfigHolder holder;
  holder.Build(args);

  EXPECT_EQ(holder.GetEntrypoint(), "customMain");
  EXPECT_EQ(holder.GetInitialRoute(), "/profile");
  ASSERT_EQ(holder.GetEntrypointArgs().size(), 3u);
  EXPECT_EQ(holder.GetEntrypointArgs()[0], "arg1");

  const FlutterEngineSpawnConfig* config = holder.GetSpawnConfig();
  ASSERT_NE(config, nullptr);
  EXPECT_EQ(config->struct_size, sizeof(FlutterEngineSpawnConfig));
  EXPECT_STREQ(config->initial_route, "/profile");
  EXPECT_EQ(config->user_data, custom_user_data);

  const FlutterProjectArgs* project_args = holder.GetProjectArgs();
  ASSERT_NE(project_args, nullptr);
  EXPECT_EQ(project_args->struct_size, sizeof(FlutterProjectArgs));
  EXPECT_STREQ(project_args->custom_dart_entrypoint, "customMain");
  EXPECT_EQ(project_args->dart_entrypoint_argc, 3);
  ASSERT_NE(project_args->dart_entrypoint_argv, nullptr);
  EXPECT_STREQ(project_args->dart_entrypoint_argv[0], "arg1");
  EXPECT_STREQ(project_args->dart_entrypoint_argv[1], "arg2");
  EXPECT_STREQ(project_args->dart_entrypoint_argv[2], "arg3");
  EXPECT_EQ(project_args->engine_id, 999);
}

// =============================================================================
// 2. InMemoryAndroidEngineGroupProvider Tests
// =============================================================================

TEST(InMemoryAndroidEngineGroupProviderTest, SpawnAndShutdownLifecycle) {
  InMemoryAndroidEngineGroupProvider provider;
  EXPECT_EQ(provider.GetSpawnCallCount(), 0u);
  EXPECT_EQ(provider.GetShutdownCallCount(), 0u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 0u);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);

  AndroidEngineSpawnArgs args;
  args.entrypoint = "childEntry";
  args.initial_route = "/feed";
  args.entrypoint_args = {"--opt"};

  AndroidEngineGroupSpawnConfigHolder holder;
  holder.Build(args);

  FLUTTER_API_SYMBOL(FlutterEngine) spawned1 = nullptr;
  FlutterEngineResult result1 =
      provider.SpawnEngine(parent_handle, holder.GetSpawnConfig(), &spawned1);
  EXPECT_EQ(result1, kSuccess);
  ASSERT_NE(spawned1, nullptr);
  EXPECT_EQ(provider.GetSpawnCallCount(), 1u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 1u);

  auto last_args = provider.GetLastSpawnArgs();
  ASSERT_TRUE(last_args.has_value());
  if (last_args.has_value()) {
    EXPECT_EQ(last_args->entrypoint, "childEntry");
    EXPECT_EQ(last_args->initial_route, "/feed");
  }

  FLUTTER_API_SYMBOL(FlutterEngine) spawned2 = nullptr;
  FlutterEngineResult result2 =
      provider.SpawnEngine(parent_handle, holder.GetSpawnConfig(), &spawned2);
  EXPECT_EQ(result2, kSuccess);
  ASSERT_NE(spawned2, nullptr);
  EXPECT_NE(spawned1, spawned2);
  EXPECT_EQ(provider.GetSpawnCallCount(), 2u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 2u);

  EXPECT_EQ(provider.ShutdownEngine(spawned1), kSuccess);
  EXPECT_EQ(provider.GetShutdownCallCount(), 1u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 1u);

  EXPECT_EQ(provider.ShutdownEngine(spawned2), kSuccess);
  EXPECT_EQ(provider.GetShutdownCallCount(), 2u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 0u);

  const auto& shutdown_handles = provider.GetShutdownHandles();
  ASSERT_EQ(shutdown_handles.size(), 2u);
  EXPECT_EQ(shutdown_handles[0], spawned1);
  EXPECT_EQ(shutdown_handles[1], spawned2);
}

TEST(InMemoryAndroidEngineGroupProviderTest,
     InitializeAndDeinitializeLifecycle) {
  InMemoryAndroidEngineGroupProvider provider;
  FlutterRendererConfig renderer_config{};
  FlutterProjectArgs project_args{};
  project_args.struct_size = sizeof(FlutterProjectArgs);

  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  EXPECT_EQ(provider.InitializeEngine(&renderer_config, &project_args, nullptr,
                                      &engine),
            kSuccess);
  ASSERT_NE(engine, nullptr);
  EXPECT_EQ(provider.GetInitializeCallCount(), 1u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 1u);

  EXPECT_EQ(provider.DeinitializeEngine(engine), kSuccess);
  EXPECT_EQ(provider.GetDeinitializeCallCount(), 1u);
  EXPECT_EQ(provider.GetActiveHandleCount(), 0u);
}

TEST(InMemoryAndroidEngineGroupProviderTest, FailureInjectionAndReset) {
  InMemoryAndroidEngineGroupProvider provider;
  provider.SetSpawnResult(kInvalidArguments);
  provider.SetShutdownResult(kInternalInconsistency);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  FlutterEngineSpawnConfig config{};
  config.struct_size = sizeof(FlutterEngineSpawnConfig);

  FLUTTER_API_SYMBOL(FlutterEngine) spawned = nullptr;
  EXPECT_EQ(provider.SpawnEngine(parent_handle, &config, &spawned),
            kInvalidArguments);
  EXPECT_EQ(spawned, nullptr);

  auto dummy_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x2000);
  EXPECT_EQ(provider.ShutdownEngine(dummy_handle), kInternalInconsistency);

  provider.Reset();
  EXPECT_EQ(provider.GetSpawnCallCount(), 0u);
  EXPECT_EQ(provider.GetShutdownCallCount(), 0u);
  EXPECT_EQ(provider.SpawnEngine(parent_handle, &config, &spawned), kSuccess);
  ASSERT_NE(spawned, nullptr);
  EXPECT_EQ(provider.ShutdownEngine(spawned), kSuccess);
}

TEST(InMemoryAndroidEngineGroupProviderTest, CustomMockHandle) {
  InMemoryAndroidEngineGroupProvider provider;
  auto custom_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xDEADBEEF);
  provider.SetMockEngineHandle(custom_handle);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  FlutterEngineSpawnConfig config{};
  config.struct_size = sizeof(FlutterEngineSpawnConfig);

  FLUTTER_API_SYMBOL(FlutterEngine) spawned = nullptr;
  EXPECT_EQ(provider.SpawnEngine(parent_handle, &config, &spawned), kSuccess);
  EXPECT_EQ(spawned, custom_handle);
}

// =============================================================================
// 3. DefaultAndroidEngineGroupProvider Tests
// =============================================================================

TEST(DefaultAndroidEngineGroupProviderTest, NullArgumentSafety) {
  DefaultAndroidEngineGroupProvider provider;
  FLUTTER_API_SYMBOL(FlutterEngine) out_engine = nullptr;

  EXPECT_EQ(provider.SpawnEngine(nullptr, nullptr, &out_engine),
            kInvalidArguments);
  EXPECT_EQ(provider.ShutdownEngine(nullptr), kInvalidArguments);
  EXPECT_EQ(provider.DeinitializeEngine(nullptr), kInvalidArguments);
  EXPECT_EQ(out_engine, nullptr);
}

// =============================================================================
// 4. AndroidEngineGroup Spawning Tests
// =============================================================================

TEST(AndroidEngineGroupSpawningTest, InitialStateAndInitialization) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  EXPECT_FALSE(group.IsInitialized());
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
  EXPECT_EQ(group.GetPrimaryEngine(), nullptr);
  EXPECT_EQ(group.GetPrimaryEngineId(), 0);

  AndroidEngineGroupConfig config;
  config.dart_vm_args = {"--enable-asserts"};
  EXPECT_TRUE(group.InitializeGroup(config));
  EXPECT_TRUE(group.IsInitialized());
  EXPECT_EQ(group.GetConfig().dart_vm_args.size(), 1u);
}

TEST(AndroidEngineGroupSpawningTest, SetProviderFallbackAndGetter) {
  AndroidEngineGroup group(nullptr);
  EXPECT_NE(group.GetProvider(), nullptr);

  auto in_mem = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  group.SetProvider(in_mem);
  EXPECT_EQ(group.GetProvider(), in_mem);

  group.SetProvider(nullptr);
  EXPECT_NE(group.GetProvider(), nullptr);
  EXPECT_NE(group.GetProvider(), in_mem);
}

TEST(AndroidEngineGroupSpawningTest, SpawnEngineFromParentHandle) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto mock_invoker = std::make_shared<MockJvmInvokerForEngineGroup>();
  EXPECT_CALL(*mock_invoker, InvokeBooleanMethod("onEngineSpawned", "(J)Z", _))
      .Times(2)
      .WillRepeatedly(Return(true));
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onEngineDestroyed", "(J)Z", _))
      .Times(3)
      .WillRepeatedly(Return(true));

  AndroidEngineGroup group(provider, mock_invoker);
  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.SetPrimaryEngine(parent_handle, 1);

  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_TRUE(group.IsEngineActive(1));
  EXPECT_TRUE(group.IsEngineActive(parent_handle));

  AndroidEngineSpawnArgs spawn1;
  spawn1.entrypoint = "spawnedMain";
  spawn1.initial_route = "/dashboard";
  spawn1.entrypoint_args = {"--mode=embedded"};
  spawn1.engine_id = 10;

  auto child_handle1 = group.SpawnEngine(parent_handle, spawn1);
  ASSERT_NE(child_handle1, nullptr);
  EXPECT_NE(child_handle1, parent_handle);
  EXPECT_EQ(group.GetActiveEngineCount(), 2u);
  EXPECT_TRUE(group.IsEngineActive(10));
  EXPECT_TRUE(group.IsEngineActive(child_handle1));
  EXPECT_EQ(group.GetEngineHandle(10), child_handle1);
  EXPECT_EQ(group.GetEngineId(child_handle1).value_or(0), 10);

  auto spawn_args_opt = group.GetSpawnArgs(10);
  ASSERT_TRUE(spawn_args_opt.has_value());
  if (spawn_args_opt.has_value()) {
    EXPECT_EQ(spawn_args_opt->entrypoint, "spawnedMain");
    EXPECT_EQ(spawn_args_opt->initial_route, "/dashboard");
  }

  // Spawn second child with auto-generated ID (engine_id = 0)
  AndroidEngineSpawnArgs spawn2;
  spawn2.entrypoint = "secondChild";
  auto child_handle2 = group.SpawnEngine(parent_handle, spawn2);
  ASSERT_NE(child_handle2, nullptr);
  EXPECT_EQ(group.GetActiveEngineCount(), 3u);
  EXPECT_TRUE(group.IsEngineActive(child_handle2));

  auto child2_id = group.GetEngineId(child_handle2);
  ASSERT_TRUE(child2_id.has_value());
  if (child2_id.has_value()) {
    EXPECT_GE(child2_id.value(), 1000);
  }
}

TEST(AndroidEngineGroupSpawningTest, SpawnEngineFromParentEngineId) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.SetPrimaryEngine(parent_handle, 1);

  AndroidEngineSpawnArgs spawn_args;
  spawn_args.entrypoint = "childViaParentId";
  spawn_args.engine_id = 20;

  auto child_handle = group.SpawnEngine(1, spawn_args);
  ASSERT_NE(child_handle, nullptr);
  EXPECT_EQ(group.GetActiveEngineCount(), 2u);
  EXPECT_TRUE(group.IsEngineActive(20));

  // Attempt spawning from non-existent parent ID
  auto invalid_child = group.SpawnEngine(9999, spawn_args);
  EXPECT_EQ(invalid_child, nullptr);
}

TEST(AndroidEngineGroupSpawningTest, SpawnEngineWithRawConfig) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);

  FlutterProjectArgs project_args{};
  project_args.struct_size = sizeof(FlutterProjectArgs);
  project_args.custom_dart_entrypoint = "rawEntrypoint";
  project_args.engine_id = 77;

  FlutterEngineSpawnConfig spawn_config{};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.custom_args = &project_args;
  spawn_config.initial_route = "/raw_route";

  auto child_handle =
      group.SpawnEngineWithConfig(parent_handle, &spawn_config, 77);
  ASSERT_NE(child_handle, nullptr);
  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_TRUE(group.IsEngineActive(77));
  EXPECT_EQ(group.GetEngineId(child_handle).value_or(0), 77);

  auto record = group.GetEngineRecord(77);
  ASSERT_TRUE(record.has_value());
  if (record.has_value()) {
    EXPECT_EQ(record->spawn_args.entrypoint, "rawEntrypoint");
    EXPECT_EQ(record->spawn_args.initial_route, "/raw_route");
  }
}

TEST(AndroidEngineGroupSpawningTest, RegisterAndUnregisterEngine) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto handle = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x3000);
  AndroidEngineSpawnArgs args;
  args.entrypoint = "manualEngine";

  EXPECT_FALSE(group.RegisterEngine(0, handle, args));
  EXPECT_FALSE(group.RegisterEngine(55, nullptr, args));
  EXPECT_TRUE(group.RegisterEngine(55, handle, args));
  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_TRUE(group.IsEngineActive(55));
  EXPECT_TRUE(group.IsEngineActive(handle));

  EXPECT_FALSE(group.UnregisterEngine(9999));
  EXPECT_TRUE(group.UnregisterEngine(55));
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
  EXPECT_FALSE(group.IsEngineActive(55));
}

TEST(AndroidEngineGroupSpawningTest, ActiveEngineListsAndRecords) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(1, parent_handle);

  AndroidEngineSpawnArgs args1;
  args1.engine_id = 2;
  group.SpawnEngine(parent_handle, args1);

  AndroidEngineSpawnArgs args2;
  args2.engine_id = 3;
  group.SpawnEngine(parent_handle, args2);

  auto active_ids = group.GetActiveEngineIds();
  EXPECT_EQ(active_ids.size(), 3u);

  auto active_handles = group.GetActiveEngineHandles();
  EXPECT_EQ(active_handles.size(), 3u);
}

// =============================================================================
// 5. Out-of-Order Shutdown & GC Cleaner Tests
// =============================================================================

TEST(AndroidEngineGroupShutdownAndGCTest, ChildEngineShutdownBeforeParent) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(1, parent_handle);

  AndroidEngineSpawnArgs spawn_args;
  spawn_args.engine_id = 2;
  auto child_handle = group.SpawnEngine(parent_handle, spawn_args);
  ASSERT_NE(child_handle, nullptr);
  EXPECT_EQ(group.GetActiveEngineCount(), 2u);

  // Shutdown child first
  EXPECT_TRUE(group.ShutdownEngine(2));
  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_FALSE(group.IsEngineActive(2));
  EXPECT_TRUE(group.IsEngineActive(1));

  // Parent shutdown
  EXPECT_TRUE(group.ShutdownEngine(1));
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
}

TEST(AndroidEngineGroupShutdownAndGCTest, ParentEngineShutdownBeforeChild) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto parent_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(1, parent_handle);

  AndroidEngineSpawnArgs spawn_args;
  spawn_args.engine_id = 2;
  auto child_handle = group.SpawnEngine(parent_handle, spawn_args);
  ASSERT_NE(child_handle, nullptr);
  EXPECT_EQ(group.GetActiveEngineCount(), 2u);

  // Shutdown parent first
  EXPECT_TRUE(group.ShutdownEngine(1));
  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_FALSE(group.IsEngineActive(1));
  EXPECT_TRUE(group.IsEngineActive(2));
  EXPECT_TRUE(group.IsEngineActive(child_handle));

  // Child continues running and can shut down cleanly
  EXPECT_TRUE(group.ShutdownEngine(child_handle));
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
}

TEST(AndroidEngineGroupShutdownAndGCTest, ArbitraryOrderShutdown) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto root = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(10, root);

  std::vector<int64_t> ids = {10};
  for (int i = 1; i <= 4; ++i) {
    AndroidEngineSpawnArgs args;
    args.engine_id = 10 + i;
    auto spawned = group.SpawnEngine(root, args);
    ASSERT_NE(spawned, nullptr);
    ids.push_back(10 + i);
  }
  EXPECT_EQ(group.GetActiveEngineCount(), 5u);

  // Shuffle / arbitrary shutdown order: 12, 10, 14, 11, 13
  std::vector<int64_t> shutdown_order = {12, 10, 14, 11, 13};
  size_t expected_count = 5u;
  for (int64_t id : shutdown_order) {
    EXPECT_TRUE(group.ShutdownEngine(id));
    expected_count--;
    EXPECT_EQ(group.GetActiveEngineCount(), expected_count);
    EXPECT_FALSE(group.IsEngineActive(id));
  }
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
}

TEST(AndroidEngineGroupShutdownAndGCTest, ShutdownAllEngines) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto root = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(1, root);

  for (int i = 2; i <= 5; ++i) {
    AndroidEngineSpawnArgs args;
    args.engine_id = i;
    group.SpawnEngine(root, args);
  }
  EXPECT_EQ(group.GetActiveEngineCount(), 5u);

  EXPECT_TRUE(group.ShutdownAllEngines());
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
  auto shutdown_handles = provider->GetShutdownHandles();
  EXPECT_EQ(shutdown_handles.size(), 5u);
  EXPECT_EQ(shutdown_handles.back(), root);
}

TEST(AndroidEngineGroupShutdownAndGCTest, GCRegistryCleanerCallback) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto mock_invoker = std::make_shared<MockJvmInvokerForEngineGroup>();
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("onEngineCleanerTriggered", "(J)Z", _))
      .Times(1)
      .WillOnce(Return(true));

  AndroidEngineGroup group(provider, mock_invoker);
  auto root = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(100, root);

  EXPECT_EQ(group.GetActiveEngineCount(), 1u);
  EXPECT_TRUE(group.OnEngineGarbageCollected(100));
  EXPECT_EQ(group.GetActiveEngineCount(), 0u);
  EXPECT_FALSE(group.IsEngineActive(100));

  // Second GC trigger should safely return false (no double shutdown)
  EXPECT_FALSE(group.OnEngineGarbageCollected(100));
  EXPECT_FALSE(group.ShutdownEngine(100));
}

TEST(AndroidEngineGroupShutdownAndGCTest, DoubleShutdownProtection) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  AndroidEngineGroup group(provider);

  auto root = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group.RegisterEngine(500, root);

  EXPECT_TRUE(group.ShutdownEngine(500));
  EXPECT_FALSE(group.ShutdownEngine(500));
  EXPECT_FALSE(group.ShutdownEngine(root));
  EXPECT_FALSE(group.OnEngineGarbageCollected(500));

  EXPECT_EQ(provider->GetShutdownCallCount(), 1u);
}

// =============================================================================
// 6. Multi-Threaded Concurrent Engine Spawning & Shutdown Tests
// =============================================================================

TEST(AndroidEngineGroupConcurrentTest,
     ThreadSafeConcurrentSpawningAndShutdown) {
  auto provider = std::make_shared<InMemoryAndroidEngineGroupProvider>();
  auto group = std::make_shared<AndroidEngineGroup>(provider);

  auto root_handle =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1000);
  group->RegisterEngine(1, root_handle);

  constexpr int kThreads = 8;
  constexpr int kSpawnsPerThread = 20;

  std::vector<std::thread> workers;
  workers.reserve(kThreads);
  std::vector<int64_t> spawned_ids[kThreads];
  for (int t = 0; t < kThreads; ++t) {
    spawned_ids[t].reserve(kSpawnsPerThread);
  }

  for (int t = 0; t < kThreads; ++t) {
    workers.emplace_back([&group, &root_handle, &spawned_ids, t]() {
      for (int i = 0; i < kSpawnsPerThread; ++i) {
        int64_t engine_id = 1000 + (t * 100) + i;
        AndroidEngineSpawnArgs args;
        args.engine_id = engine_id;
        args.entrypoint = "concurrentEntrypoint";
        auto handle = group->SpawnEngine(root_handle, args);
        if (handle) {
          spawned_ids[t].push_back(engine_id);
        }
      }
    });
  }

  for (auto& w : workers) {
    w.join();
  }
  workers.clear();
  workers.reserve(kThreads);

  size_t total_spawned = 0;
  for (int t = 0; t < kThreads; ++t) {
    total_spawned += spawned_ids[t].size();
  }
  EXPECT_EQ(total_spawned, static_cast<size_t>(kThreads * kSpawnsPerThread));
  EXPECT_EQ(group->GetActiveEngineCount(), total_spawned + 1);

  // Concurrently shut down all spawned engines
  for (int t = 0; t < kThreads; ++t) {
    workers.emplace_back([&group, &spawned_ids, t]() {
      for (int64_t id : spawned_ids[t]) {
        group->ShutdownEngine(id);
      }
    });
  }

  for (auto& w : workers) {
    w.join();
  }

  EXPECT_EQ(group->GetActiveEngineCount(), 1u);
  EXPECT_TRUE(group->ShutdownEngine(1));
  EXPECT_EQ(group->GetActiveEngineCount(), 0u);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
