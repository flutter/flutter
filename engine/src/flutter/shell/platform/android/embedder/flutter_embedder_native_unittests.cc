// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/flutter_embedder_native.h"

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

const char* GetFixturesPath() {
  return "";
}

namespace {

class MockJniDelegate : public JniDelegate {
 public:
  void HandlePlatformMessage(const std::string& channel,
                             const uint8_t* message,
                             size_t message_size,
                             int32_t response_id,
                             int64_t message_data) override {
    last_channel = channel;
    if (message != nullptr && message_size > 0) {
      last_message.assign(message, message + message_size);
    } else {
      last_message.clear();
    }
    last_response_id = response_id;
    platform_message_count++;
  }

  void HandlePlatformMessageResponse(int32_t response_id,
                                     const uint8_t* response,
                                     size_t response_size) override {
    last_completed_response_id = response_id;
    if (response != nullptr && response_size > 0) {
      last_response_payload.assign(response, response + response_size);
    } else {
      last_response_payload.clear();
    }
    response_callback_count++;
  }

  void OnFirstFrame() override { first_frame_count++; }

  void OnEngineRestart() override { engine_restart_count++; }

  void RequestDartDeferredLibrary(intptr_t loading_unit_id) override {
    requested_loading_unit_id = loading_unit_id;
  }

  uintptr_t CreateSurfaceControl(const std::string& /*debug_name*/,
                                 int32_t /*width*/,
                                 int32_t /*height*/) override {
    return 0x1001;
  }

  void ReleaseSurfaceControl(uintptr_t /*surface_control_handle*/) override {}

  bool SetBufferWithFence(uintptr_t /*surface_control_handle*/,
                          uintptr_t /*hardware_buffer_handle*/,
                          int /*fence_fd*/) override {
    return true;
  }

  bool ApplyTransaction() override { return true; }

  uintptr_t AcquireLatestHardwareBuffer(int64_t /*texture_id*/,
                                        uint32_t* out_width,
                                        uint32_t* out_height) override {
    if (out_width != nullptr) {
      *out_width = 100;
    }
    if (out_height != nullptr) {
      *out_height = 100;
    }
    return 0x2002;
  }

  void ReleaseHardwareBuffer(uintptr_t /*hardware_buffer_handle*/) override {}

  void RequestVsync(intptr_t baton) override { last_vsync_baton = baton; }

  std::string last_channel;
  std::vector<uint8_t> last_message;
  int32_t last_response_id = 0;
  int platform_message_count = 0;

  int32_t last_completed_response_id = 0;
  std::vector<uint8_t> last_response_payload;
  int response_callback_count = 0;

  int first_frame_count = 0;
  int engine_restart_count = 0;
  intptr_t requested_loading_unit_id = -1;
  intptr_t last_vsync_baton = 0;
};

struct FakeProcTableState {
  int initialize_calls = 0;
  int run_initialized_calls = 0;
  int deinitialize_calls = 0;
  int shutdown_calls = 0;
  int notify_created_calls = 0;
  int notify_destroyed_calls = 0;
  int set_gpu_availability_calls = 0;
  int spawn_calls = 0;
  int send_platform_message_calls = 0;
  int send_platform_message_response_calls = 0;
  int load_deferred_library_calls = 0;
  int runs_aot_compiled_calls = 0;
  int create_aot_data_calls = 0;
  int collect_aot_data_calls = 0;

  bool runs_aot_compiled_return = false;
  FlutterEngineAOTData last_created_aot_data = nullptr;
  FlutterEngineAOTData last_collected_aot_data = nullptr;
  FlutterEngineAOTData passed_aot_data = nullptr;

  FlutterGpuAvailability last_gpu_availability =
      kFlutterGpuAvailabilityAvailable;
  bool last_does_handle_on_platform_thread = true;
  FlutterPlatformMessageCallback2 saved_message_callback2 = nullptr;
  FlutterRequestDartDeferredLibraryCallback saved_deferred_callback = nullptr;
  void* saved_user_data = nullptr;
  std::string last_spawn_entrypoint;
  std::string last_spawn_route;
};

FakeProcTableState* g_fake_state = nullptr;

FlutterEngineProcTable CreateFakeProcTable(FakeProcTableState* state) {
  g_fake_state = state;
  FlutterEngineProcTable table = {};
  table.struct_size = sizeof(FlutterEngineProcTable);

  table.Initialize = [](size_t /*version*/,
                        const FlutterRendererConfig* /*config*/,
                        const FlutterProjectArgs* args, void* user_data,
                        FLUTTER_API_SYMBOL(FlutterEngine)* engine_out) {
    g_fake_state->initialize_calls++;
    g_fake_state->last_does_handle_on_platform_thread =
        args->does_handle_platform_messages_on_platform_thread;
    g_fake_state->saved_message_callback2 = args->platform_message_callback2;
    g_fake_state->saved_deferred_callback =
        args->request_dart_deferred_library_callback;
    g_fake_state->saved_user_data = user_data;
    g_fake_state->passed_aot_data = args->aot_data;
    *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);
    return kSuccess;
  };

  table.RunInitialized = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->run_initialized_calls++;
    return kSuccess;
  };

  table.Deinitialize = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->deinitialize_calls++;
    return kSuccess;
  };

  table.Shutdown = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->shutdown_calls++;
    return kSuccess;
  };

  table.NotifyCreated = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->notify_created_calls++;
    return kSuccess;
  };

  table.NotifyDestroyed = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->notify_destroyed_calls++;
    return kSuccess;
  };

  table.SetGpuAvailability = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                                FlutterGpuAvailability availability) {
    g_fake_state->set_gpu_availability_calls++;
    g_fake_state->last_gpu_availability = availability;
    return kSuccess;
  };

  table.Spawn = [](FLUTTER_API_SYMBOL(FlutterEngine) /*parent*/,
                   const FlutterEngineSpawnConfig* config,
                   FLUTTER_API_SYMBOL(FlutterEngine)* child_out) {
    g_fake_state->spawn_calls++;
    if (config->entrypoint != nullptr) {
      g_fake_state->last_spawn_entrypoint = config->entrypoint;
    }
    if (config->initial_route != nullptr) {
      g_fake_state->last_spawn_route = config->initial_route;
    }
    *child_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE02);
    return kSuccess;
  };

  table.SendPlatformMessage = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                                 const FlutterPlatformMessage* /*message*/) {
    g_fake_state->send_platform_message_calls++;
    return kSuccess;
  };

  table.SendPlatformMessageResponse =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         const FlutterPlatformMessageResponseHandle* /*handle*/,
         const uint8_t* /*data*/, size_t /*data_length*/) {
        g_fake_state->send_platform_message_response_calls++;
        return kSuccess;
      };

  table.LoadDartDeferredLibrary =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         const FlutterDartDeferredLibrary* /*library*/) {
        g_fake_state->load_deferred_library_calls++;
        return kSuccess;
      };

  table.RunsAOTCompiledDartCode = []() -> bool {
    g_fake_state->runs_aot_compiled_calls++;
    return g_fake_state->runs_aot_compiled_return;
  };

  table.CreateAOTData = [](const FlutterEngineAOTDataSource* /*source*/,
                           FlutterEngineAOTData* data_out) {
    g_fake_state->create_aot_data_calls++;
    *data_out = reinterpret_cast<FlutterEngineAOTData>(0xDEADBEEF);
    g_fake_state->last_created_aot_data = *data_out;
    return kSuccess;
  };

  table.CollectAOTData = [](FlutterEngineAOTData data) {
    g_fake_state->collect_aot_data_calls++;
    g_fake_state->last_collected_aot_data = data;
    return kSuccess;
  };

  return table;
}

}  // namespace

TEST(FlutterEmbedderNativeTest, ResolvesDefaultProcTableViaProcAddresses) {
  FlutterEngineProcTable proc_table = {};
  ASSERT_TRUE(FlutterEmbedderNative::ResolveDefaultProcTable(&proc_table));
  EXPECT_NE(proc_table.Initialize, nullptr);
  EXPECT_NE(proc_table.RunInitialized, nullptr);
  EXPECT_NE(proc_table.Deinitialize, nullptr);
  EXPECT_NE(proc_table.Shutdown, nullptr);
  EXPECT_NE(proc_table.NotifyCreated, nullptr);
  EXPECT_NE(proc_table.NotifyDestroyed, nullptr);
  EXPECT_NE(proc_table.SetGpuAvailability, nullptr);
  EXPECT_NE(proc_table.Spawn, nullptr);
  EXPECT_NE(proc_table.LoadDartDeferredLibrary, nullptr);
}

TEST(FlutterEmbedderNativeTest,
     InitializesAndRunsEngineStrictlyThroughProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  settings.enable_embedder_api = true;

  {
    FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
    ASSERT_TRUE(embedder.IsValid());
    EXPECT_FALSE(embedder.IsRunning());

    ASSERT_TRUE(embedder.Launch("/data/flutter_assets", "/data/icudtl.dat",
                                "main", "", {"--arg1"}, 42));
    EXPECT_TRUE(embedder.IsRunning());
    EXPECT_EQ(state.initialize_calls, 1);
    EXPECT_EQ(state.run_initialized_calls, 1);
    EXPECT_FALSE(state.last_does_handle_on_platform_thread);
    EXPECT_NE(state.saved_message_callback2, nullptr);
    EXPECT_NE(state.saved_deferred_callback, nullptr);
  }

  EXPECT_EQ(state.deinitialize_calls, 1);
  EXPECT_EQ(state.shutdown_calls, 1);
}

TEST(FlutterEmbedderNativeTest,
     ForwardsSurfaceLifecycleAndGpuAvailabilityToProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  EXPECT_TRUE(embedder.NotifySurfaceCreated());
  EXPECT_EQ(state.notify_created_calls, 1);

  EXPECT_TRUE(embedder.SetGpuAvailability(
      kFlutterGpuAvailabilityFlushAndMakeUnavailable));
  EXPECT_EQ(state.set_gpu_availability_calls, 1);
  EXPECT_EQ(state.last_gpu_availability,
            kFlutterGpuAvailabilityFlushAndMakeUnavailable);

  EXPECT_TRUE(embedder.NotifySurfaceDestroyed());
  EXPECT_EQ(state.notify_destroyed_calls, 1);
}

TEST(FlutterEmbedderNativeTest,
     RoutesPlatformMessagesAndResponsesViaMockJniDelegate) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  const uint8_t payload[] = {0x10, 0x20, 0x30};
  FlutterPlatformMessage incoming = {};
  incoming.struct_size = sizeof(FlutterPlatformMessage);
  incoming.channel = "flutter/platform_views";
  incoming.message = payload;
  incoming.message_size = sizeof(payload);
  incoming.response_handle =
      reinterpret_cast<const FlutterPlatformMessageResponseHandle*>(0x9999);

  ASSERT_NE(state.saved_message_callback2, nullptr);
  state.saved_message_callback2(&incoming, state.saved_user_data);

  EXPECT_EQ(jni_delegate->platform_message_count, 1);
  EXPECT_EQ(jni_delegate->last_channel, "flutter/platform_views");
  ASSERT_EQ(jni_delegate->last_message.size(), 3u);
  EXPECT_GT(jni_delegate->last_response_id, 0);

  const uint8_t reply[] = {0x01};
  EXPECT_TRUE(embedder.RespondToPlatformMessage(jni_delegate->last_response_id,
                                                reply, sizeof(reply)));
  EXPECT_EQ(state.send_platform_message_response_calls, 1);

  ASSERT_NE(state.saved_deferred_callback, nullptr);
  state.saved_deferred_callback(7, state.saved_user_data);
  EXPECT_EQ(jni_delegate->requested_loading_unit_id, 7);
}

TEST(FlutterEmbedderNativeTest, SpawnsChildEngineSharingParentVmViaProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto parent_jni = std::make_shared<MockJniDelegate>();
  auto child_jni = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative parent(settings, parent_jni, proc_table);
  ASSERT_TRUE(
      parent.Launch("/assets", "/icudtl.dat", "main", "", {}, /*engine_id=*/1));

  auto child = parent.Spawn(child_jni, "childMain", "package:app/child.dart",
                            "/home", {}, /*engine_id=*/2);
  ASSERT_NE(child, nullptr);
  EXPECT_TRUE(child->IsValid());
  EXPECT_TRUE(child->IsRunning());
  EXPECT_EQ(state.spawn_calls, 1);
  EXPECT_EQ(state.last_spawn_entrypoint, "childMain");
  EXPECT_EQ(state.last_spawn_route, "/home");
  EXPECT_EQ(FlutterEmbedderNative::FromHandle(child->ToHandle()), child.get());
}

TEST(FlutterEmbedderNativeTest,
     HandleRegistrySafelyResolvesLiveInstancesAndRejectsInvalidHandles) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  EXPECT_EQ(FlutterEmbedderNative::FromHandle(0), nullptr);
  EXPECT_EQ(FlutterEmbedderNative::FromHandle(0xDEADBEEF), nullptr);

  int64_t saved_handle = 0;
  {
    FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
    saved_handle = embedder.ToHandle();
    EXPECT_EQ(FlutterEmbedderNative::FromHandle(saved_handle), &embedder);
  }
  EXPECT_EQ(FlutterEmbedderNative::FromHandle(saved_handle), nullptr);
}

TEST(FlutterEmbedderNativeTest, CreatesAndCollectsAOTDataInReleaseMode) {
  FakeProcTableState state;
  state.runs_aot_compiled_return = true;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  settings.application_library_paths.push_back("/fake/libapp.so");

  {
    FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
    ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                                /*engine_id=*/1));
    EXPECT_EQ(state.runs_aot_compiled_calls, 1);
    EXPECT_EQ(state.create_aot_data_calls, 1);
    EXPECT_EQ(state.passed_aot_data,
              reinterpret_cast<FlutterEngineAOTData>(0xDEADBEEF));
    EXPECT_EQ(state.collect_aot_data_calls, 0);
  }

  EXPECT_EQ(state.collect_aot_data_calls, 1);
  EXPECT_EQ(state.last_collected_aot_data,
            reinterpret_cast<FlutterEngineAOTData>(0xDEADBEEF));
}

}  // namespace testing
}  // namespace flutter
