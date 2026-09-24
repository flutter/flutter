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

  uintptr_t CreateSurfaceControl(const std::string& debug_name,
                                 int32_t /*width*/,
                                 int32_t /*height*/) override {
    created_surface_controls.push_back(debug_name);
    return next_surface_control_handle++;
  }

  void ReleaseSurfaceControl(uintptr_t surface_control_handle) override {
    released_surface_controls.push_back(surface_control_handle);
  }

  bool SetBufferWithFence(uintptr_t surface_control_handle,
                          uintptr_t hardware_buffer_handle,
                          int fence_fd) override {
    if (!allow_set_buffer) {
      return false;
    }
    last_set_buffer_surface_control = surface_control_handle;
    last_set_buffer_hardware_buffer = hardware_buffer_handle;
    handed_off_fences.push_back(fence_fd);
    return true;
  }

  bool ApplyTransaction() override {
    apply_transaction_calls++;
    return true;
  }

  uintptr_t AcquireLatestHardwareBuffer(int64_t /*texture_id*/,
                                        uint32_t* out_width,
                                        uint32_t* out_height) override {
    if (out_width != nullptr) {
      *out_width = 1920;
    }
    if (out_height != nullptr) {
      *out_height = 1080;
    }
    return next_hardware_buffer_handle++;
  }

  void ReleaseHardwareBuffer(uintptr_t hardware_buffer_handle) override {
    released_hardware_buffers.push_back(hardware_buffer_handle);
  }

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

  uintptr_t next_surface_control_handle = 0x1001;
  uintptr_t next_hardware_buffer_handle = 0x2002;
  bool allow_set_buffer = true;
  uintptr_t last_set_buffer_surface_control = 0;
  uintptr_t last_set_buffer_hardware_buffer = 0;
  std::vector<std::string> created_surface_controls;
  std::vector<uintptr_t> released_surface_controls;
  std::vector<uintptr_t> released_hardware_buffers;
  std::vector<int> handed_off_fences;
  int apply_transaction_calls = 0;
};

struct FakeProcTableState {
  int initialize_calls = 0;
  int run_initialized_calls = 0;
  int deinitialize_calls = 0;
  int shutdown_calls = 0;
  int notify_created_calls = 0;
  int notify_destroyed_calls = 0;
  int set_gpu_availability_calls = 0;
  int send_window_metrics_calls = 0;
  int add_view_calls = 0;
  int remove_view_calls = 0;
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

  int on_vsync_calls = 0;
  int register_external_texture_calls = 0;
  int unregister_external_texture_calls = 0;
  int mark_external_texture_frame_available_calls = 0;
  int update_semantics_enabled_calls = 0;
  int dispatch_semantics_action_calls = 0;
  int update_asset_resolver_calls = 0;
  size_t last_asset_resolvers_count = 0;
  const FlutterAssetResolver* last_asset_resolver = nullptr;
  int send_pointer_event_calls = 0;
  int update_accessibility_features_calls = 0;
  int schedule_frame_calls = 0;
  size_t last_pointer_event_count = 0;
  FlutterPointerPhase last_pointer_phase = kCancel;
  std::vector<FlutterPointerEvent> last_pointer_events;
  FlutterAccessibilityFeature last_accessibility_flags =
      static_cast<FlutterAccessibilityFeature>(0);
  bool fail_load_deferred_library = false;

  intptr_t last_on_vsync_baton = 0;
  uint64_t last_on_vsync_start_nanos = 0;
  uint64_t last_on_vsync_target_nanos = 0;
  FlutterViewId last_added_view_id = 0;
  FlutterViewId last_removed_view_id = 0;
  FlutterGpuAvailability last_gpu_availability =
      kFlutterGpuAvailabilityAvailable;
  bool last_does_handle_on_platform_thread = true;
  FlutterPlatformMessageCallback2 saved_message_callback2 = nullptr;
  FlutterRequestDartDeferredLibraryCallback saved_deferred_callback = nullptr;
  FlutterUpdateSemanticsCallback2 saved_semantics_callback2 = nullptr;
  VsyncCallback saved_vsync_callback = nullptr;
  VoidCallback saved_deferred_destruction_callback = nullptr;
  void* saved_deferred_destruction_user_data = nullptr;
  void* saved_user_data = nullptr;
  std::string last_spawn_entrypoint;
  std::string last_spawn_route;
};

FakeProcTableState* g_fake_state = nullptr;

FlutterEngineProcTable CreateFakeProcTable(FakeProcTableState* state) {
  g_fake_state = state;
  FlutterEngineProcTable table = {};
  static std::unordered_map<FLUTTER_API_SYMBOL(FlutterEngine),
                            FlutterAssetResolver>
      engine_asset_resolvers;

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
    g_fake_state->saved_semantics_callback2 = args->update_semantics_callback2;
    g_fake_state->saved_vsync_callback = args->vsync_callback;
    g_fake_state->saved_user_data = user_data;
    g_fake_state->passed_aot_data = args->aot_data;
    g_fake_state->last_asset_resolvers_count = args->asset_resolvers_count;
    *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);
    if (args->asset_resolvers != nullptr && args->asset_resolvers_count > 0 &&
        args->asset_resolvers[0] != nullptr) {
      g_fake_state->last_asset_resolver = args->asset_resolvers[0];
      engine_asset_resolvers[*engine_out] = *args->asset_resolvers[0];
    }
    return kSuccess;
  };

  table.RunInitialized = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->run_initialized_calls++;
    return kSuccess;
  };

  table.Deinitialize = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    g_fake_state->deinitialize_calls++;
    auto it = engine_asset_resolvers.find(engine);
    if (it != engine_asset_resolvers.end()) {
      if (it->second.destruction_callback != nullptr) {
        it->second.destruction_callback(it->second.user_data);
      }
      engine_asset_resolvers.erase(it);
    }
    if (g_fake_state != nullptr) {
      g_fake_state->last_asset_resolver = nullptr;
    }
    return kSuccess;
  };

  table.Shutdown = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    g_fake_state->shutdown_calls++;
    auto it = engine_asset_resolvers.find(engine);
    if (it != engine_asset_resolvers.end()) {
      if (it->second.destruction_callback != nullptr) {
        it->second.destruction_callback(it->second.user_data);
      }
      engine_asset_resolvers.erase(it);
    }
    if (g_fake_state != nullptr) {
      g_fake_state->last_asset_resolver = nullptr;
    }
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
    if (config->project_args != nullptr) {
      g_fake_state->last_asset_resolvers_count =
          config->project_args->asset_resolvers_count;
      if (config->project_args->asset_resolvers != nullptr &&
          config->project_args->asset_resolvers_count > 0 &&
          config->project_args->asset_resolvers[0] != nullptr) {
        g_fake_state->last_asset_resolver =
            config->project_args->asset_resolvers[0];
        engine_asset_resolvers[*child_out] =
            *config->project_args->asset_resolvers[0];
      }
    }
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
         const FlutterDartDeferredLibrary* library) {
        g_fake_state->load_deferred_library_calls++;
        if (g_fake_state->fail_load_deferred_library) {
          return kInvalidArguments;
        }
        if (library != nullptr) {
          g_fake_state->saved_deferred_destruction_callback =
              library->destruction_callback;
          g_fake_state->saved_deferred_destruction_user_data =
              library->user_data;
        }
        return kSuccess;
      };

  table.UpdateSemanticsEnabled =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/, bool /*enabled*/) {
        g_fake_state->update_semantics_enabled_calls++;
        return kSuccess;
      };

  table.DispatchSemanticsAction =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/, uint64_t /*id*/,
         FlutterSemanticsAction /*action*/, const uint8_t* /*data*/,
         size_t /*data_length*/) {
        g_fake_state->dispatch_semantics_action_calls++;
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

  table.SendWindowMetricsEvent =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         const FlutterWindowMetricsEvent* /*event*/) {
        g_fake_state->send_window_metrics_calls++;
        return kSuccess;
      };

  table.AddView = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                     const FlutterAddViewInfo* info) {
    g_fake_state->add_view_calls++;
    g_fake_state->last_added_view_id = info->view_id;
    if (info->add_view_callback != nullptr) {
      FlutterAddViewResult res = {};
      res.struct_size = sizeof(FlutterAddViewResult);
      res.added = true;
      res.user_data = info->user_data;
      info->add_view_callback(&res);
    }
    return kSuccess;
  };

  table.RemoveView = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                        const FlutterRemoveViewInfo* info) {
    g_fake_state->remove_view_calls++;
    g_fake_state->last_removed_view_id = info->view_id;
    if (info->remove_view_callback != nullptr) {
      FlutterRemoveViewResult res = {};
      res.struct_size = sizeof(FlutterRemoveViewResult);
      res.removed = true;
      res.user_data = info->user_data;
      info->remove_view_callback(&res);
    }
    return kSuccess;
  };

  table.OnVsync = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                     intptr_t baton, uint64_t frame_start_time_nanos,
                     uint64_t frame_target_time_nanos) {
    g_fake_state->on_vsync_calls++;
    g_fake_state->last_on_vsync_baton = baton;
    g_fake_state->last_on_vsync_start_nanos = frame_start_time_nanos;
    g_fake_state->last_on_vsync_target_nanos = frame_target_time_nanos;
    return kSuccess;
  };

  table.RegisterExternalTexture =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         int64_t /*texture_identifier*/) {
        g_fake_state->register_external_texture_calls++;
        return kSuccess;
      };

  table.UnregisterExternalTexture =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         int64_t /*texture_identifier*/) {
        g_fake_state->unregister_external_texture_calls++;
        return kSuccess;
      };

  table.MarkExternalTextureFrameAvailable =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         int64_t /*texture_identifier*/) {
        g_fake_state->mark_external_texture_frame_available_calls++;
        return kSuccess;
      };

  table.UpdateAssetResolver =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterAssetResolverRegistrationInfo* info) {
        g_fake_state->update_asset_resolver_calls++;
        auto it = engine_asset_resolvers.find(engine);
        if (it != engine_asset_resolvers.end()) {
          if (it->second.destruction_callback != nullptr) {
            it->second.destruction_callback(it->second.user_data);
          }
          engine_asset_resolvers.erase(it);
        }
        if (info != nullptr && info->resolver != nullptr) {
          g_fake_state->last_asset_resolver = info->resolver;
          engine_asset_resolvers[engine] = *info->resolver;
        } else {
          g_fake_state->last_asset_resolver = nullptr;
        }
        return kSuccess;
      };

  table.SendPointerEvent = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
                              const FlutterPointerEvent* events, size_t count) {
    g_fake_state->send_pointer_event_calls++;
    g_fake_state->last_pointer_event_count = count;
    g_fake_state->last_pointer_events.clear();
    if (events != nullptr && count > 0) {
      g_fake_state->last_pointer_phase = events[0].phase;
      g_fake_state->last_pointer_events.assign(events, events + count);
    }
    return kSuccess;
  };

  table.UpdateAccessibilityFeatures =
      [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/,
         FlutterAccessibilityFeature flags) {
        g_fake_state->update_accessibility_features_calls++;
        g_fake_state->last_accessibility_flags = flags;
        return kSuccess;
      };

  table.ScheduleFrame = [](FLUTTER_API_SYMBOL(FlutterEngine) /*engine*/) {
    g_fake_state->schedule_frame_calls++;
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
    EXPECT_NE(state.saved_semantics_callback2, nullptr);
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
     NotifySurfaceCreatedPassesNativeWindowHandleToSurfaceControl) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  EXPECT_TRUE(embedder.NotifySurfaceCreated(/*native_window_handle=*/0x5555));
  EXPECT_EQ(state.notify_created_calls, 1);
  ASSERT_NE(embedder.GetSurfaceControl(), nullptr);
  EXPECT_EQ(embedder.GetSurfaceControl()->GetNativeWindowHandle(0),
            static_cast<uintptr_t>(0x5555));
  EXPECT_TRUE(embedder.NotifySurfaceDestroyed());
  EXPECT_EQ(state.notify_destroyed_calls, 1);
  EXPECT_EQ(embedder.GetSurfaceControl()->GetNativeWindowHandle(0),
            static_cast<uintptr_t>(0));
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

TEST(FlutterEmbedderNativeTest,
     RoutesSemanticsUpdate2CallbackToSemanticsBridge) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));
  ASSERT_NE(state.saved_semantics_callback2, nullptr);

  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 123;
  FlutterSemanticsNode2* nodes[] = {&node};

  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.view_id = 0;
  update.node_count = 1;
  update.nodes = nodes;

  state.saved_semantics_callback2(&update, state.saved_user_data);

  AndroidSemanticsBridge::SerializedSemanticsBatch batch;
  ASSERT_TRUE(embedder.GetSemanticsBridge()->GetLastBatchForView(0, &batch));
  EXPECT_EQ(batch.node_count, 1u);
  ASSERT_EQ(batch.node_ids.size(), 1u);
  EXPECT_EQ(batch.node_ids[0], 123);
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

TEST(FlutterEmbedderNativeTest, SpawnPropagatesAssetResolversFromParent) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto parent_jni = std::make_shared<MockJniDelegate>();
  auto child_jni = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative parent(settings, parent_jni, proc_table);
  auto fake_asset_manager = reinterpret_cast<AAssetManager*>(0x1234);
  ASSERT_TRUE(parent.Launch("/assets", "/icudtl.dat", "main", "", {},
                            /*engine_id=*/1, fake_asset_manager));
  EXPECT_EQ(state.last_asset_resolvers_count, 1u);

  state.last_asset_resolvers_count = 0;
  state.last_asset_resolver = nullptr;

  auto child = parent.Spawn(child_jni, "childMain", "package:app/child.dart",
                            "/home", {}, /*engine_id=*/2);
  ASSERT_NE(child, nullptr);
  EXPECT_TRUE(child->IsValid());
  EXPECT_EQ(state.spawn_calls, 1);
  EXPECT_EQ(state.last_asset_resolvers_count, 1u);
  ASSERT_NE(state.last_asset_resolver, nullptr);
  EXPECT_EQ(state.last_asset_resolver->struct_size,
            sizeof(FlutterAssetResolver));
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

TEST(FlutterEmbedderNativeTest,
     ForwardsPointerEventsAndSemanticsAndScheduleFrameToProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  // Synthesize a packed RawAndroidPointerData packet.
  RawAndroidPointerData packet = {};
  packet.time_stamp = 123456789;
  packet.change = RawAndroidPointerData::Change::kDown;
  packet.kind = RawAndroidPointerData::DeviceKind::kTouch;
  packet.physical_x = 540.0;
  packet.physical_y = 960.0;
  packet.device = 1;
  packet.view_id = 0;

  EXPECT_TRUE(embedder.DispatchPointerDataPacket(
      reinterpret_cast<const uint8_t*>(&packet), sizeof(packet)));
  EXPECT_EQ(state.send_pointer_event_calls, 1);
  EXPECT_EQ(state.last_pointer_event_count, 1u);
  EXPECT_EQ(state.last_pointer_phase, kDown);

  // Semantics & accessibility features.
  uint8_t action_data[] = {1, 2, 3};
  EXPECT_TRUE(embedder.DispatchSemanticsAction(
      /*id=*/42, /*action=*/static_cast<int32_t>(kFlutterSemanticsActionTap),
      action_data, sizeof(action_data)));
  EXPECT_EQ(state.dispatch_semantics_action_calls, 1);

  EXPECT_TRUE(embedder.SetSemanticsEnabled(true));
  EXPECT_EQ(state.update_semantics_enabled_calls, 1);

  EXPECT_TRUE(embedder.SetAccessibilityFeatures(
      kFlutterAccessibilityFeatureAccessibleNavigation));
  EXPECT_EQ(state.update_accessibility_features_calls, 1);
  EXPECT_EQ(state.last_accessibility_flags,
            kFlutterAccessibilityFeatureAccessibleNavigation);

  // Frame scheduling.
  EXPECT_TRUE(embedder.ScheduleFrame());
  EXPECT_EQ(state.schedule_frame_calls, 1);
}

TEST(FlutterEmbedderNativeTest,
     RegistersAndUnregistersExternalTexturesViaProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  EXPECT_TRUE(embedder.RegisterExternalTexture(/*texture_id=*/101));
  EXPECT_EQ(state.register_external_texture_calls, 1);

  EXPECT_TRUE(embedder.MarkExternalTextureFrameAvailable(/*texture_id=*/101));
  EXPECT_EQ(state.mark_external_texture_frame_available_calls, 1);

  EXPECT_TRUE(embedder.UnregisterExternalTexture(/*texture_id=*/101));
  EXPECT_EQ(state.unregister_external_texture_calls, 1);
}

TEST(AndroidSurfaceControlTest,
     CreatesAndDestroysPrimaryAndSecondaryViewSurfacesSynchronously) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidSurfaceControl surface_control(jni_delegate, proc_table);

  // Primary view (view_id == 0) uses NotifyCreated / NotifyDestroyed.
  EXPECT_TRUE(surface_control.NotifySurfaceCreated(
      engine, /*view_id=*/0, /*native_window_handle=*/0x1111, /*width=*/1080,
      /*height=*/2400, /*pixel_ratio=*/3.0));
  EXPECT_TRUE(surface_control.HasAttachedSurface(0));
  EXPECT_EQ(state.notify_created_calls, 1);
  EXPECT_EQ(state.send_window_metrics_calls, 1);

  // Secondary presentation view (view_id == 7) uses AddView / RemoveView.
  EXPECT_TRUE(surface_control.NotifySurfaceCreated(
      engine, /*view_id=*/7, /*native_window_handle=*/0x2222, /*width=*/1920,
      /*height=*/1080, /*pixel_ratio=*/2.0));
  EXPECT_TRUE(surface_control.HasAttachedSurface(7));
  EXPECT_EQ(state.add_view_calls, 1);
  EXPECT_EQ(state.last_added_view_id, 7);

  // Synchronous destruction of both views.
  EXPECT_TRUE(surface_control.NotifySurfaceDestroyed(engine, /*view_id=*/7));
  EXPECT_FALSE(surface_control.HasAttachedSurface(7));
  EXPECT_EQ(state.remove_view_calls, 1);
  EXPECT_EQ(state.last_removed_view_id, 7);

  EXPECT_TRUE(surface_control.NotifySurfaceDestroyed(engine, /*view_id=*/0));
  EXPECT_FALSE(surface_control.HasAttachedSurface(0));
  EXPECT_EQ(state.notify_destroyed_calls, 1);
}

TEST(AndroidSurfaceControlTest,
     TransfersFenceOwnershipOnValidHcppPresentationAndResetsFdToNegativeOne) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<int> closed_fds;
  AndroidSurfaceControl surface_control(jni_delegate, proc_table,
                                        [&closed_fds](int fd) {
                                          closed_fds.push_back(fd);
                                          return 0;
                                        });

  ASSERT_TRUE(
      surface_control.NotifySurfaceCreated(engine, 0, 0x1111, 1080, 2400, 3.0));

  FlutterBackingStorePresentInfo present_info = {};
  present_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  present_info.synchronization_fence_fd = 42;

  EXPECT_TRUE(surface_control.PresentBackingStore(
      /*view_id=*/0, /*layer_id=*/10, /*hardware_buffer_handle=*/0xABCD, 1080,
      2400, &present_info));

  // Invariant 3: `synchronization_fence_fd` is reset to -1 immediately, handed
  // off to `SetBufferWithFence`, and NOT double-closed by the embedder.
  EXPECT_EQ(present_info.synchronization_fence_fd, -1);
  ASSERT_EQ(jni_delegate->handed_off_fences.size(), 1u);
  EXPECT_EQ(jni_delegate->handed_off_fences[0], 42);
  EXPECT_TRUE(closed_fds.empty());
}

TEST(AndroidSurfaceControlTest,
     ClosesSyncFenceFdOnErrorOrDestroyedSurfaceWithoutLeakingOrDoubleClosing) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<int> closed_fds;
  AndroidSurfaceControl surface_control(jni_delegate, proc_table,
                                        [&closed_fds](int fd) {
                                          closed_fds.push_back(fd);
                                          return 0;
                                        });

  // Case 1: Presenting to an unattached/destroyed view closes fence_fd = 55.
  FlutterBackingStorePresentInfo unattached_info = {};
  unattached_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  unattached_info.synchronization_fence_fd = 55;
  EXPECT_FALSE(surface_control.PresentBackingStore(
      /*view_id=*/99, /*layer_id=*/1, /*hardware_buffer_handle=*/0xABCD, 500,
      500, &unattached_info));
  EXPECT_EQ(unattached_info.synchronization_fence_fd, -1);
  ASSERT_EQ(closed_fds.size(), 1u);
  EXPECT_EQ(closed_fds[0], 55);

  // Case 2: Presenting when SetBufferWithFence fails closes fence_fd = 77.
  ASSERT_TRUE(
      surface_control.NotifySurfaceCreated(engine, 0, 0x1111, 1080, 2400, 3.0));
  jni_delegate->allow_set_buffer = false;

  FlutterBackingStorePresentInfo failed_tx_info = {};
  failed_tx_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  failed_tx_info.synchronization_fence_fd = 77;
  EXPECT_FALSE(surface_control.PresentBackingStore(
      /*view_id=*/0, /*layer_id=*/1, /*hardware_buffer_handle=*/0xABCD, 500,
      500, &failed_tx_info));
  EXPECT_EQ(failed_tx_info.synchronization_fence_fd, -1);
  ASSERT_EQ(closed_fds.size(), 2u);
  EXPECT_EQ(closed_fds[1], 77);
}

TEST(AndroidSurfaceControlTest,
     RecyclesSurfaceControlsAcrossConsecutiveFrames) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidSurfaceControl surface_control(jni_delegate, proc_table);
  ASSERT_TRUE(
      surface_control.NotifySurfaceCreated(engine, 0, 0x1111, 1080, 2400, 3.0));

  FlutterBackingStorePresentInfo info = {};
  info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  info.synchronization_fence_fd = -1;

  // Frame 1 presents layers 1 and 2 -> allocates 2 SurfaceControls.
  EXPECT_TRUE(surface_control.PresentBackingStore(0, /*layer_id=*/1, 0xA1, 400,
                                                  400, &info));
  EXPECT_TRUE(surface_control.PresentBackingStore(0, /*layer_id=*/2, 0xA2, 400,
                                                  400, &info));
  EXPECT_TRUE(surface_control.CommitTransaction(0));
  EXPECT_EQ(surface_control.GetActiveLayerCount(0), 2u);
  EXPECT_EQ(surface_control.GetPooledLayerCount(0), 0u);
  EXPECT_EQ(jni_delegate->created_surface_controls.size(), 2u);

  // Frame 2 presents only layer 1 -> layer 2 is recycled into free_layer_pool.
  EXPECT_TRUE(surface_control.PresentBackingStore(0, /*layer_id=*/1, 0xA1, 400,
                                                  400, &info));
  EXPECT_TRUE(surface_control.CommitTransaction(0));
  EXPECT_EQ(surface_control.GetActiveLayerCount(0), 1u);
  EXPECT_EQ(surface_control.GetPooledLayerCount(0), 1u);

  // Frame 3 presents layer 1 and new layer 3 -> layer 3 reuses pooled
  // SurfaceControl without allocating a new one!
  EXPECT_TRUE(surface_control.PresentBackingStore(0, /*layer_id=*/1, 0xA1, 400,
                                                  400, &info));
  EXPECT_TRUE(surface_control.PresentBackingStore(0, /*layer_id=*/3, 0xA3, 400,
                                                  400, &info));
  EXPECT_TRUE(surface_control.CommitTransaction(0));
  EXPECT_EQ(surface_control.GetActiveLayerCount(0), 2u);
  EXPECT_EQ(surface_control.GetPooledLayerCount(0), 0u);
  EXPECT_EQ(jni_delegate->created_surface_controls.size(), 2u);
}

TEST(AndroidSurfaceControlTest, ReleasesNativeWindowOnSurfaceDestroyed) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<uintptr_t> released_windows;
  AndroidSurfaceControl surface_control(jni_delegate, proc_table,
                                        /*fence_closer=*/nullptr,
                                        [&released_windows](uintptr_t handle) {
                                          released_windows.push_back(handle);
                                        });

  EXPECT_TRUE(surface_control.NotifySurfaceCreated(
      engine, /*view_id=*/0, /*native_window_handle=*/0x3333, /*width=*/1080,
      /*height=*/2400, /*pixel_ratio=*/3.0));
  EXPECT_TRUE(released_windows.empty());

  EXPECT_TRUE(surface_control.NotifySurfaceDestroyed(engine, /*view_id=*/0));
  ASSERT_EQ(released_windows.size(), 1u);
  EXPECT_EQ(released_windows[0], static_cast<uintptr_t>(0x3333));
  EXPECT_EQ(surface_control.GetNativeWindowHandle(0),
            static_cast<uintptr_t>(0));
}

TEST(AndroidSurfaceControlTest, DispatchesOnFirstFrameOnceUponPresentation) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidSurfaceControl surface_control(jni_delegate, proc_table);
  EXPECT_TRUE(surface_control.NotifySurfaceCreated(
      engine, /*view_id=*/0, /*native_window_handle=*/0x1111, /*width=*/1080,
      /*height=*/2400, /*pixel_ratio=*/3.0));

  EXPECT_EQ(jni_delegate->first_frame_count, 0);

  FlutterBackingStorePresentInfo present_info1 = {};
  present_info1.struct_size = sizeof(FlutterBackingStorePresentInfo);
  present_info1.synchronization_fence_fd = -1;
  EXPECT_TRUE(surface_control.PresentBackingStore(
      /*view_id=*/0, /*layer_id=*/1, /*hardware_buffer_handle=*/0x2222,
      /*width=*/1080, /*height=*/2400, &present_info1));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);

  FlutterBackingStorePresentInfo present_info2 = {};
  present_info2.struct_size = sizeof(FlutterBackingStorePresentInfo);
  present_info2.synchronization_fence_fd = -1;
  EXPECT_TRUE(surface_control.PresentBackingStore(
      /*view_id=*/0, /*layer_id=*/1, /*hardware_buffer_handle=*/0x2222,
      /*width=*/1080, /*height=*/2400, &present_info2));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);
}

TEST(AndroidChoreographerVsyncTest,
     RoutesEngineVsyncCallbackToChoreographerProviderAndReturnsFrameTimes) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));
  ASSERT_NE(state.saved_vsync_callback, nullptr);

  // Engine requests vsync with baton 0x55AA.
  state.saved_vsync_callback(state.saved_user_data, 0x55AA);
  EXPECT_EQ(jni_delegate->last_vsync_baton, 0x55AA);
  EXPECT_EQ(embedder.GetVsyncWaiter()->GetPendingBatonCount(), 1u);

  // Choreographer fires frame callback.
  EXPECT_TRUE(embedder.OnVsync(0x55AA, 100000000ULL, 116666666ULL));
  EXPECT_EQ(state.on_vsync_calls, 1);
  EXPECT_EQ(state.last_on_vsync_baton, 0x55AA);
  EXPECT_EQ(state.last_on_vsync_start_nanos, 100000000ULL);
  EXPECT_EQ(state.last_on_vsync_target_nanos, 116666666ULL);
  EXPECT_EQ(embedder.GetVsyncWaiter()->GetPendingBatonCount(), 0u);
}

TEST(AndroidChoreographerVsyncTest,
     ComputesTargetDeadlineFromVariableRefreshRateWhenZeroTargetProvided) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);
  AndroidChoreographerVsync vsync(jni_delegate, proc_table,
                                  /*initial_refresh_rate_fps=*/120.0);
  EXPECT_EQ(vsync.GetRefreshPeriodNanos(), 8333333ULL);

  vsync.RequestVsync(0x77);
  EXPECT_TRUE(vsync.OnChoreographerFrame(engine, 0x77, 50000000ULL, 0ULL));
  EXPECT_EQ(state.on_vsync_calls, 1);
  EXPECT_EQ(state.last_on_vsync_start_nanos, 50000000ULL);
  EXPECT_EQ(state.last_on_vsync_target_nanos, 50000000ULL + 8333333ULL);
}

TEST(AndroidChoreographerVsyncTest,
     RejectsDuplicateOrCancelledVsyncBatonsWithoutInvokingProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidChoreographerVsync vsync(jni_delegate, proc_table, 60.0);
  vsync.RequestVsync(0x88);
  EXPECT_TRUE(
      vsync.OnChoreographerFrame(engine, 0x88, 1000000ULL, 17666666ULL));
  EXPECT_EQ(state.on_vsync_calls, 1);

  // Duplicate firing of the same baton 0x88 must be rejected.
  EXPECT_FALSE(
      vsync.OnChoreographerFrame(engine, 0x88, 2000000ULL, 18666666ULL));
  EXPECT_EQ(state.on_vsync_calls, 1);

  // Cancelled baton before firing must also be rejected.
  vsync.RequestVsync(0x99);
  vsync.CancelPendingBatons();
  EXPECT_FALSE(
      vsync.OnChoreographerFrame(engine, 0x99, 3000000ULL, 19666666ULL));
  EXPECT_EQ(state.on_vsync_calls, 1);
}

TEST(
    AndroidHardwareBufferExternalTextureTest,
    AcquiresZeroCopyVulkanHardwareBufferWithYcbcrInfoAndReleasesViaDestructionCallback) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;

  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(embedder.Launch("/assets", "/icudtl.dat", "main", "", {},
                              /*engine_id=*/1));

  constexpr int64_t kCameraTextureId = 101;
  EXPECT_TRUE(embedder.RegisterExternalTexture(kCameraTextureId));
  EXPECT_EQ(state.register_external_texture_calls, 1);

  FlutterVulkanYcbcrConversionInfo ycbcr = {};
  ycbcr.struct_size = sizeof(FlutterVulkanYcbcrConversionInfo);
  ycbcr.external_format = 0x506;  // Vendor NV12 / YUV420 external format
  ycbcr.ycbcr_model = 2;
  ycbcr.ycbcr_range = 1;
  embedder.GetExternalTextureManager()->SetTextureYcbcrConversionInfo(
      kCameraTextureId, ycbcr);

  FlutterTransformation uv_transform = {1.0, 0.0, 0.0, 0.0, -1.0,
                                        1.0, 0.0, 0.0, 1.0};
  embedder.GetExternalTextureManager()->SetTextureUvTransform(kCameraTextureId,
                                                              uv_transform);

  EXPECT_TRUE(embedder.MarkExternalTextureFrameAvailable(kCameraTextureId));
  EXPECT_EQ(state.mark_external_texture_frame_available_calls, 1);

  FlutterVulkanExternalTexture vk_texture = {};
  ASSERT_TRUE(
      embedder.GetExternalTextureManager()->AcquireVulkanExternalTextureFrame(
          kCameraTextureId, 1920, 1080, &vk_texture));

  EXPECT_EQ(vk_texture.type, kFlutterVulkanExternalTextureTypeAHardwareBuffer);
  EXPECT_EQ(reinterpret_cast<uintptr_t>(vk_texture.hardware_buffer), 0x2002u);
  EXPECT_EQ(vk_texture.width, 1920u);
  EXPECT_EQ(vk_texture.height, 1080u);
  ASSERT_NE(vk_texture.ycbcr_conversion_info, nullptr);
  EXPECT_EQ(vk_texture.ycbcr_conversion_info->external_format, 0x506u);
  EXPECT_DOUBLE_EQ(vk_texture.uv_transform.scaleY, -1.0);
  EXPECT_DOUBLE_EQ(vk_texture.uv_transform.transY, 1.0);
  EXPECT_EQ(embedder.GetExternalTextureManager()->GetActiveBufferLeaseCount(),
            1u);
  EXPECT_TRUE(jni_delegate->released_hardware_buffers.empty());

  // Invoking the destruction callback releases the AHardwareBuffer lease.
  ASSERT_NE(vk_texture.destruction_callback, nullptr);
  vk_texture.destruction_callback(vk_texture.user_data);
  EXPECT_EQ(embedder.GetExternalTextureManager()->GetActiveBufferLeaseCount(),
            0u);
  ASSERT_EQ(jni_delegate->released_hardware_buffers.size(), 1u);
  EXPECT_EQ(jni_delegate->released_hardware_buffers[0], 0x2002u);

  EXPECT_TRUE(embedder.UnregisterExternalTexture(kCameraTextureId));
  EXPECT_EQ(state.unregister_external_texture_calls, 1);
}

TEST(AndroidHardwareBufferExternalTextureTest,
     PopulatesOpenGLTexture2WithUvTransformationMatrix) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidHardwareBufferExternalTexture manager(jni_delegate, proc_table);
  ASSERT_TRUE(manager.RegisterTexture(engine, /*texture_id=*/202));
  manager.SetOpenGLTextureName(202, 0x8D65, /*gl_texture_name=*/42);
  FlutterTransformation uv = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 0.0, 1.0};
  manager.SetTextureUvTransform(202, uv);

  FlutterOpenGLTexture2 gl_texture = {};
  ASSERT_TRUE(
      manager.AcquireOpenGLExternalTextureFrame(202, 1280, 720, &gl_texture));
  EXPECT_EQ(gl_texture.target, 0x8D65u);
  EXPECT_EQ(gl_texture.name, 42u);
  EXPECT_EQ(gl_texture.width, 1280u);
  EXPECT_EQ(gl_texture.height, 720u);
  EXPECT_DOUBLE_EQ(gl_texture.uv_transform.skewX, 1.0);
  EXPECT_DOUBLE_EQ(gl_texture.uv_transform.skewY, -1.0);
}

TEST(AndroidHardwareBufferExternalTextureTest,
     ImmediatelyReleasesHardwareBufferIfTextureWasUnregisteredBeforePull) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();

  AndroidHardwareBufferExternalTexture manager(jni_delegate, proc_table);
  FlutterVulkanExternalTexture vk_texture = {};
  EXPECT_FALSE(manager.AcquireVulkanExternalTextureFrame(
      /*texture_id=*/999, 640, 480, &vk_texture));
  ASSERT_EQ(jni_delegate->released_hardware_buffers.size(), 1u);
  EXPECT_EQ(jni_delegate->released_hardware_buffers[0], 0x2002u);
  EXPECT_EQ(manager.GetActiveBufferLeaseCount(), 0u);
}

TEST(AndroidPlatformViewsControllerTest,
     CapturesLayersAndMutatorsByValueAcrossConcurrentMultiViewPresentations) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<int> closed_fds;
  AndroidSurfaceControl surface_control(jni_delegate, proc_table,
                                        [&closed_fds](int fd) {
                                          closed_fds.push_back(fd);
                                          return 0;
                                        });
  ASSERT_TRUE(surface_control.NotifySurfaceCreated(engine, /*view_id=*/0,
                                                   0x1111, 1080, 2400, 3.0));
  ASSERT_TRUE(surface_control.NotifySurfaceCreated(engine, /*view_id=*/7,
                                                   0x2222, 1920, 1080, 2.0));

  std::vector<std::function<void()>> queued_platform_tasks;
  AndroidPlatformViewsController controller(
      jni_delegate, &surface_control,
      [&queued_platform_tasks](std::function<void()> task) {
        queued_platform_tasks.push_back(std::move(task));
      });

  // Reusable stack structures that the raster thread mutates between View A and
  // View B BEFORE the platform thread executes either queued task.
  FlutterBackingStore backing_store = {};
  backing_store.struct_size = sizeof(FlutterBackingStore);
  backing_store.user_data = reinterpret_cast<void*>(0xB001);

  FlutterBackingStorePresentInfo present_info = {};
  present_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  present_info.synchronization_fence_fd = 81;

  FlutterPlatformViewMutation mut1 = {};
  mut1.type = kFlutterPlatformViewMutationTypeOpacity;
  mut1.opacity = 0.5;
  FlutterPlatformViewMutation mut2 = {};
  mut2.type = kFlutterPlatformViewMutationTypeClipRect;
  mut2.clip_rect = {0, 0, 100, 100};
  const FlutterPlatformViewMutation* view_a_muts[] = {&mut1, &mut2};

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = 42;
  pv.mutations_count = 2;
  pv.mutations = view_a_muts;

  FlutterLayer bs_layer = {};
  bs_layer.struct_size = sizeof(FlutterLayer);
  bs_layer.type = kFlutterLayerContentTypeBackingStore;
  bs_layer.size = {1080, 2400};
  bs_layer.backing_store = &backing_store;
  bs_layer.backing_store_present_info = &present_info;

  FlutterLayer pv_layer = {};
  pv_layer.struct_size = sizeof(FlutterLayer);
  pv_layer.type = kFlutterLayerContentTypePlatformView;
  pv_layer.size = {400, 300};
  pv_layer.platform_view = &pv;

  const FlutterLayer* layers[] = {&bs_layer, &pv_layer};

  // 1. Raster thread presents View A (view_id = 0).
  FlutterPresentViewInfo info_a = {};
  info_a.struct_size = sizeof(FlutterPresentViewInfo);
  info_a.view_id = 0;
  info_a.layers = layers;
  info_a.layers_count = 2;
  info_a.user_data = &controller;
  ASSERT_TRUE(AndroidPlatformViewsController::OnPresentViewCallback(&info_a));
  EXPECT_EQ(present_info.synchronization_fence_fd, -1);

  // 2. Raster thread immediately overwrites the SAME stack structs for View B
  // (view_id = 7) while View A's task is still sitting in
  // `queued_platform_tasks`.
  present_info.synchronization_fence_fd = 82;
  pv.identifier = 99;
  pv.mutations_count = 1;

  FlutterPresentViewInfo info_b = {};
  info_b.struct_size = sizeof(FlutterPresentViewInfo);
  info_b.view_id = 7;
  info_b.layers = layers;
  info_b.layers_count = 2;
  info_b.user_data = &controller;
  ASSERT_TRUE(AndroidPlatformViewsController::OnPresentViewCallback(&info_b));
  EXPECT_EQ(present_info.synchronization_fence_fd, -1);

  ASSERT_EQ(queued_platform_tasks.size(), 2u);

  // 3. Platform thread drains both tasks; verify zero cross-view state
  // corruption.
  for (auto& task : queued_platform_tasks) {
    task();
  }

  AndroidPlatformViewsController::CommittedViewSummary summary_a;
  ASSERT_TRUE(controller.GetCommittedViewSummary(0, &summary_a));
  EXPECT_EQ(summary_a.backing_store_layer_count, 1u);
  EXPECT_EQ(summary_a.platform_view_layer_count, 1u);
  ASSERT_EQ(summary_a.platform_view_ids.size(), 1u);
  EXPECT_EQ(summary_a.platform_view_ids[0], 42);
  EXPECT_EQ(summary_a.mutation_counts_per_view[0], 2u);

  AndroidPlatformViewsController::CommittedViewSummary summary_b;
  ASSERT_TRUE(controller.GetCommittedViewSummary(7, &summary_b));
  EXPECT_EQ(summary_b.backing_store_layer_count, 1u);
  EXPECT_EQ(summary_b.platform_view_layer_count, 1u);
  ASSERT_EQ(summary_b.platform_view_ids.size(), 1u);
  EXPECT_EQ(summary_b.platform_view_ids[0], 99);
  EXPECT_EQ(summary_b.mutation_counts_per_view[0], 1u);

  ASSERT_EQ(jni_delegate->handed_off_fences.size(), 2u);
  EXPECT_EQ(jni_delegate->handed_off_fences[0], 81);
  EXPECT_EQ(jni_delegate->handed_off_fences[1], 82);
  EXPECT_TRUE(closed_fds.empty());
  EXPECT_EQ(jni_delegate->first_frame_count, 1);
}

TEST(
    AndroidPlatformViewsControllerTest,
    ClosesCapturedSyncFenceWhenTargetViewSurfaceIsDestroyedBeforePlatformTask) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();

  std::vector<int> closed_fds;
  AndroidSurfaceControl surface_control(jni_delegate, proc_table,
                                        [&closed_fds](int fd) {
                                          closed_fds.push_back(fd);
                                          return 0;
                                        });

  AndroidPlatformViewsController controller(jni_delegate, &surface_control);

  FlutterBackingStore backing_store = {};
  backing_store.struct_size = sizeof(FlutterBackingStore);
  backing_store.user_data = reinterpret_cast<void*>(0xB002);

  FlutterBackingStorePresentInfo present_info = {};
  present_info.struct_size = sizeof(FlutterBackingStorePresentInfo);
  present_info.synchronization_fence_fd = 95;

  FlutterLayer bs_layer = {};
  bs_layer.struct_size = sizeof(FlutterLayer);
  bs_layer.type = kFlutterLayerContentTypeBackingStore;
  bs_layer.size = {800, 600};
  bs_layer.backing_store = &backing_store;
  bs_layer.backing_store_present_info = &present_info;
  const FlutterLayer* layers[] = {&bs_layer};

  // Presenting to view_id = 404 (which has no attached surface) must still
  // reset `synchronization_fence_fd = -1` and close `fd = 95`.
  FlutterPresentViewInfo info = {};
  info.struct_size = sizeof(FlutterPresentViewInfo);
  info.view_id = 404;
  info.layers = layers;
  info.layers_count = 1;
  EXPECT_TRUE(controller.PresentView(&info));
  EXPECT_EQ(present_info.synchronization_fence_fd, -1);
  ASSERT_EQ(closed_fds.size(), 1u);
  EXPECT_EQ(closed_fds[0], 95);
}

#if !defined(_WIN32)
TEST(CapturedLayerTest, ClosesSyncFenceFdOnDestructionWhenPlatformTaskDropped) {
  int fds[2];
  ASSERT_EQ(pipe(fds), 0);
  int read_fd = fds[0];
  int write_fd = fds[1];

  {
    CapturedLayer layer;
    layer.synchronization_fence_fd = write_fd;
  }

  // Reading from read_fd returns 0 (EOF) because write_fd was closed by
  // ~CapturedLayer().
  char buf[1];
  EXPECT_EQ(read(read_fd, buf, 1), 0);
  close(read_fd);
}
#endif

TEST(AndroidPlatformViewsControllerTest,
     CreatesAndCollectsSoftwareBackingStore) {
  FlutterBackingStoreConfig config = {};
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size = {640, 480};

  FlutterBackingStore backing_store = {};
  EXPECT_TRUE(AndroidPlatformViewsController::OnCreateBackingStoreCallback(
      &config, &backing_store, nullptr));
  EXPECT_EQ(backing_store.type, kFlutterBackingStoreTypeSoftware);
  EXPECT_NE(backing_store.software.allocation, nullptr);
  EXPECT_EQ(backing_store.software.height, 480u);
  EXPECT_EQ(backing_store.software.row_bytes, 640u * 4);

  EXPECT_TRUE(AndroidPlatformViewsController::OnCollectBackingStoreCallback(
      &backing_store, nullptr));
}

TEST(AndroidPlatformViewsControllerTest,
     DispatchesOnFirstFrameOnceUponSoftwarePresentation) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();

  AndroidSurfaceControl surface_control(jni_delegate, proc_table);
  AndroidPlatformViewsController controller(jni_delegate, &surface_control);

  std::vector<uint8_t> pixels(640 * 480 * 4, 0xAA);
  FlutterBackingStore backing_store = {};
  backing_store.struct_size = sizeof(FlutterBackingStore);
  backing_store.type = kFlutterBackingStoreTypeSoftware;
  backing_store.software.allocation = pixels.data();
  backing_store.software.row_bytes = 640 * 4;
  backing_store.software.height = 480;

  FlutterLayer bs_layer = {};
  bs_layer.struct_size = sizeof(FlutterLayer);
  bs_layer.type = kFlutterLayerContentTypeBackingStore;
  bs_layer.size = {640, 480};
  bs_layer.backing_store = &backing_store;
  const FlutterLayer* layers[] = {&bs_layer};

  FlutterPresentViewInfo info = {};
  info.struct_size = sizeof(FlutterPresentViewInfo);
  info.view_id = 0;
  info.layers = layers;
  info.layers_count = 1;

  EXPECT_EQ(jni_delegate->first_frame_count, 0);
  EXPECT_TRUE(controller.PresentView(&info));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);

  // Subsequent frame presentation should not fire OnFirstFrame again.
  EXPECT_TRUE(controller.PresentView(&info));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);
}

TEST(FlutterEmbedderNativeTest, PresentSoftwareDispatchesOnFirstFrameOnce) {
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  FlutterEngineProcTable proc_table = {};
  FlutterEmbedderNative embedder(Settings{}, jni_delegate, proc_table);

  std::vector<uint8_t> pixels(100 * 100 * 4, 0xFF);
  EXPECT_EQ(jni_delegate->first_frame_count, 0);

  EXPECT_TRUE(embedder.PresentSoftware(pixels.data(), 100 * 4, 100));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);

  // Subsequent frame presentation should not fire OnFirstFrame again.
  EXPECT_TRUE(embedder.PresentSoftware(pixels.data(), 100 * 4, 100));
  EXPECT_EQ(jni_delegate->first_frame_count, 1);
}

TEST(FlutterEmbedderNativeTest, CopySoftwarePixelsHandlesRgba8888Buffer) {
  // 4x4 RGBA_8888 source image.
  const size_t width = 4;
  const size_t height = 4;
  const size_t src_row_bytes = width * 4;
  std::vector<uint8_t> src(src_row_bytes * height, 0xAB);

  // 6x4 RGBA_8888 destination buffer (stride = 6).
  const int32_t dst_stride = 6;
  std::vector<uint8_t> dst(dst_stride * 4 * height, 0x00);
  FlutterEmbedderNative::SoftwareBufferView view;
  view.bits = dst.data();
  view.format = 1;  // WINDOW_FORMAT_RGBA_8888
  view.stride = dst_stride;
  view.height = height;

  EXPECT_TRUE(FlutterEmbedderNative::CopySoftwarePixels(
      src.data(), src_row_bytes, height, view));

  // Verify first row contains 0xAB for first 4 pixels (16 bytes) and 0x00 for
  // padding.
  for (size_t y = 0; y < height; ++y) {
    for (size_t x = 0; x < 16; ++x) {
      EXPECT_EQ(dst[y * dst_stride * 4 + x], 0xAB);
    }
    for (size_t x = 16; x < dst_stride * 4; ++x) {
      EXPECT_EQ(dst[y * dst_stride * 4 + x], 0x00);
    }
  }
}

TEST(FlutterEmbedderNativeTest,
     CopySoftwarePixelsHandlesRgb565BufferWithoutOverrunning) {
  // 4x4 RGBA_8888 source image.
  const size_t width = 4;
  const size_t height = 4;
  const size_t src_row_bytes = width * 4;
  std::vector<uint8_t> src(src_row_bytes * height, 0xCD);

  // 4x4 RGB_565 destination buffer (format = 4, 2 bpp, stride = 4, total bytes
  // = 4 * 2 * 4 = 32).
  const int32_t dst_stride = 4;
  const size_t dst_total_bytes = dst_stride * 2 * height;
  std::vector<uint8_t> dst(dst_total_bytes, 0x00);
  FlutterEmbedderNative::SoftwareBufferView view;
  view.bits = dst.data();
  view.format = 4;  // WINDOW_FORMAT_RGB_565
  view.stride = dst_stride;
  view.height = height;

  EXPECT_TRUE(FlutterEmbedderNative::CopySoftwarePixels(
      src.data(), src_row_bytes, height, view));

  // Ensure each row wrote exactly buffer_row_bytes (8 bytes) without exceeding
  // total bytes.
  for (size_t i = 0; i < dst_total_bytes; ++i) {
    EXPECT_EQ(dst[i], 0xCD);
  }
}

TEST(FlutterEmbedderNativeTest, CopySoftwarePixelsRejectsInvalidBuffers) {
  std::vector<uint8_t> src(64, 0x11);
  std::vector<uint8_t> dst(64, 0x22);
  FlutterEmbedderNative::SoftwareBufferView view;
  view.bits = dst.data();
  view.format = 1;
  view.stride = 4;
  view.height = 4;

  // Null src
  EXPECT_FALSE(FlutterEmbedderNative::CopySoftwarePixels(nullptr, 16, 4, view));
  // Null dst bits
  view.bits = nullptr;
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 4, view));
  view.bits = dst.data();
  // Non-positive stride
  view.stride = 0;
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 4, view));
  view.stride = -1;
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 4, view));
  view.stride = 4;
  // Non-positive height
  view.height = 0;
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 4, view));
  view.height = -2;
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 4, view));
  view.height = 4;
  // Zero row_bytes or height
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 0, 4, view));
  EXPECT_FALSE(
      FlutterEmbedderNative::CopySoftwarePixels(src.data(), 16, 0, view));
}

TEST(AndroidSemanticsAndAssetsTest,
     SerializesSemanticsUpdate2BatchAndDispatchesActionsViaProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  AndroidSemanticsBridge bridge(jni_delegate, proc_table);
  EXPECT_TRUE(bridge.SetSemanticsEnabled(engine, true));
  EXPECT_EQ(state.update_semantics_enabled_calls, 1);

  EXPECT_TRUE(bridge.DispatchSemanticsAction(
      engine, /*node_id=*/12, kFlutterSemanticsActionTap, nullptr, 0));
  EXPECT_EQ(state.dispatch_semantics_action_calls, 1);

  FlutterSemanticsNode2 node0 = {};
  node0.struct_size = sizeof(FlutterSemanticsNode2);
  node0.id = 0;
  FlutterSemanticsNode2 node1 = {};
  node1.struct_size = sizeof(FlutterSemanticsNode2);
  node1.id = 12;
  FlutterSemanticsNode2* nodes[] = {&node0, &node1};

  FlutterSemanticsCustomAction2 action0 = {};
  action0.struct_size = sizeof(FlutterSemanticsCustomAction2);
  action0.id = 7;
  FlutterSemanticsCustomAction2* actions[] = {&action0};

  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.node_count = 2;
  update.nodes = nodes;
  update.custom_action_count = 1;
  update.custom_actions = actions;
  update.view_id = 0;

  AndroidSemanticsBridge::OnSemanticsUpdate2Callback(&update, &bridge);

  AndroidSemanticsBridge::SerializedSemanticsBatch batch;
  ASSERT_TRUE(bridge.GetLastBatchForView(0, &batch));
  EXPECT_EQ(batch.node_count, 2u);
  EXPECT_EQ(batch.custom_action_count, 1u);
  ASSERT_EQ(batch.node_ids.size(), 2u);
  EXPECT_EQ(batch.node_ids[0], 0);
  EXPECT_EQ(batch.node_ids[1], 12);
  ASSERT_EQ(batch.action_ids.size(), 1u);
  EXPECT_EQ(batch.action_ids[0], 7);
}

TEST(AndroidSemanticsAndAssetsTest,
     PinsMappedDeferredLibraryBuffersUntilDestructionCallbackIsInvoked) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<intptr_t> unmapped_units;
  AndroidDeferredLibraryLoader loader(
      proc_table,
      [&unmapped_units](intptr_t unit_id, const uint8_t* /*data*/,
                        size_t /*data_sz*/, const uint8_t* /*instr*/,
                        size_t /*instr_sz*/) {
        unmapped_units.push_back(unit_id);
      });

  const uint8_t fake_data[] = {0xDA, 0x7A};
  const uint8_t fake_instr[] = {0xC0, 0xDE};

  ASSERT_TRUE(loader.LoadMappedDeferredLibrary(engine, /*loading_unit_id=*/5,
                                               fake_data, sizeof(fake_data),
                                               fake_instr, sizeof(fake_instr)));
  EXPECT_EQ(state.load_deferred_library_calls, 1);

  // Invariant (ADR-0009): Buffers remain pinned while Dart VM holds the lease!
  EXPECT_EQ(loader.GetActiveMappedUnitCount(), 1u);
  EXPECT_TRUE(unmapped_units.empty());

  // When Dart VM finishes and invokes `destruction_callback`, `munmap`
  // triggers.
  ASSERT_NE(state.saved_deferred_destruction_callback, nullptr);
  state.saved_deferred_destruction_callback(
      state.saved_deferred_destruction_user_data);
  EXPECT_EQ(loader.GetActiveMappedUnitCount(), 0u);
  ASSERT_EQ(unmapped_units.size(), 1u);
  EXPECT_EQ(unmapped_units[0], 5);
}

TEST(AndroidSemanticsAndAssetsTest,
     UnmapsDeferredLibraryImmediatelyWhenProcTableLoadFails) {
  FakeProcTableState state;
  state.fail_load_deferred_library = true;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto engine = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xCAFE01);

  std::vector<intptr_t> unmapped_units;
  AndroidDeferredLibraryLoader loader(
      proc_table,
      [&unmapped_units](intptr_t unit_id, const uint8_t* /*data*/,
                        size_t /*data_sz*/, const uint8_t* /*instr*/,
                        size_t /*instr_sz*/) {
        unmapped_units.push_back(unit_id);
      });

  const uint8_t fake_data[] = {0x01};
  EXPECT_FALSE(loader.LoadMappedDeferredLibrary(
      engine, /*loading_unit_id=*/9, fake_data, sizeof(fake_data), nullptr, 0));
  EXPECT_EQ(loader.GetActiveMappedUnitCount(), 0u);
  ASSERT_EQ(unmapped_units.size(), 1u);
  EXPECT_EQ(unmapped_units[0], 9);
}

TEST(AndroidAssetResolverTest,
     NormalizesAssetPathsWithAndWithoutLeadingSlashes) {
  EXPECT_EQ(AndroidAssetResolver::NormalizeAssetPath(
                "flutter_assets", "shaders/ink_sparkle.frag"),
            "flutter_assets/shaders/ink_sparkle.frag");
  EXPECT_EQ(AndroidAssetResolver::NormalizeAssetPath(
                "flutter_assets/", "/shaders/ink_sparkle.frag"),
            "flutter_assets/shaders/ink_sparkle.frag");
  EXPECT_EQ(AndroidAssetResolver::NormalizeAssetPath(
                "flutter_assets", "flutter_assets/shaders/ink_sparkle.frag"),
            "flutter_assets/shaders/ink_sparkle.frag");
  EXPECT_EQ(AndroidAssetResolver::NormalizeAssetPath("", "fonts/Roboto.ttf"),
            "fonts/Roboto.ttf");
  EXPECT_EQ(AndroidAssetResolver::NormalizeAssetPath("", "/fonts/Roboto.ttf"),
            "fonts/Roboto.ttf");
}

TEST(AndroidAssetResolverTest, FindsAssetAndReturnsValidBufferMapping) {
  const uint8_t mock_bytes[] = {'H', 'E', 'L', 'L', 'O'};
  bool free_called = false;
  AndroidAssetResolver resolver(
      [&mock_bytes, &free_called](const std::string& name,
                                  const uint8_t** out_data, size_t* out_size,
                                  void** out_baton, VoidCallback* out_free) {
        if (name == "test_asset.txt") {
          *out_data = mock_bytes;
          *out_size = sizeof(mock_bytes);
          *out_baton = &free_called;
          *out_free = [](void* baton) { *static_cast<bool*>(baton) = true; };
          return true;
        }
        return false;
      });

  FlutterAssetResolver c_resolver = resolver.ToFlutterAssetResolver();
  EXPECT_EQ(c_resolver.struct_size, sizeof(FlutterAssetResolver));
  ASSERT_NE(c_resolver.find_asset_callback, nullptr);
  EXPECT_TRUE(c_resolver.is_valid_callback(c_resolver.user_data));
  EXPECT_TRUE(c_resolver.is_valid_after_change_callback(c_resolver.user_data));

  FlutterAsset asset = {};
  asset.struct_size = sizeof(FlutterAsset);
  EXPECT_FALSE(c_resolver.find_asset_callback(c_resolver.user_data,
                                              "nonexistent", &asset));

  EXPECT_TRUE(c_resolver.find_asset_callback(c_resolver.user_data,
                                             "test_asset.txt", &asset));
  EXPECT_EQ(asset.struct_size, sizeof(FlutterAsset));
  EXPECT_EQ(asset.size, sizeof(mock_bytes));
  EXPECT_EQ(asset.data, mock_bytes);
  ASSERT_NE(asset.asset_free_callback, nullptr);

  asset.asset_free_callback(asset.user_data);
  EXPECT_TRUE(free_called);

  c_resolver.destruction_callback(c_resolver.user_data);
}

TEST(AndroidAssetResolverTest, RejectsInvalidCallbacksGracefully) {
  FlutterAssetResolver resolver =
      AndroidAssetResolver::CreateFlutterAssetResolver(nullptr, "assets");
  EXPECT_EQ(resolver.struct_size, sizeof(FlutterAssetResolver));

  FlutterAsset asset = {};
  asset.struct_size = sizeof(FlutterAsset);
  EXPECT_FALSE(
      resolver.find_asset_callback(resolver.user_data, "shader.frag", &asset));
  EXPECT_FALSE(resolver.find_asset_callback(nullptr, "shader.frag", &asset));
  EXPECT_FALSE(
      resolver.find_asset_callback(resolver.user_data, nullptr, &asset));
  EXPECT_FALSE(
      resolver.find_asset_callback(resolver.user_data, "shader.frag", nullptr));

  resolver.destruction_callback(resolver.user_data);
}

TEST(FlutterEmbedderNativeTest,
     LaunchConfiguresAssetResolversWhenAssetManagerProvided) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);

  auto fake_asset_manager = reinterpret_cast<AAssetManager*>(0x1234);
  EXPECT_TRUE(embedder.Launch("assets", "icu", "main", "", {},
                              /*engine_id=*/1, fake_asset_manager));
  EXPECT_EQ(state.last_asset_resolvers_count, 1u);
  ASSERT_NE(state.last_asset_resolver, nullptr);
  EXPECT_EQ(state.last_asset_resolver->struct_size,
            sizeof(FlutterAssetResolver));
}

TEST(FlutterEmbedderNativeTest, UpdatesAssetResolverViaProcTable) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);

  EXPECT_TRUE(
      embedder.Launch("assets", "icu", "main", "", {}, /*engine_id=*/1));

  auto fake_asset_manager = reinterpret_cast<AAssetManager*>(0x5678);
  EXPECT_TRUE(embedder.UpdateAssetManager(fake_asset_manager, "new_bundle"));
  EXPECT_EQ(state.update_asset_resolver_calls, 1);
  ASSERT_NE(state.last_asset_resolver, nullptr);
  EXPECT_EQ(state.last_asset_resolver->struct_size,
            sizeof(FlutterAssetResolver));
}

TEST(FlutterEmbedderNativeTest,
     DoesNotDoubleFreeAssetResolverOnEngineDestruction) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  {
    FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
    auto fake_asset_manager = reinterpret_cast<AAssetManager*>(0x1234);
    EXPECT_TRUE(embedder.Launch("assets", "icu", "main", "", {},
                                /*engine_id=*/1, fake_asset_manager));
  }
  EXPECT_EQ(state.shutdown_calls, 1);
  EXPECT_EQ(state.last_asset_resolver, nullptr);
}

TEST(FlutterEmbedderNativeTest,
     DispatchPointerDataPacketPreservesEmbedderIdAndPlatformData) {
  FakeProcTableState state;
  FlutterEngineProcTable proc_table = CreateFakeProcTable(&state);
  auto jni_delegate = std::make_shared<MockJniDelegate>();
  Settings settings;
  FlutterEmbedderNative embedder(settings, jni_delegate, proc_table);
  ASSERT_TRUE(
      embedder.Launch("assets", "icu", "main", "", {}, /*engine_id=*/1));

  RawAndroidPointerData packet[2] = {};
  packet[0].embedder_id = 42;
  packet[0].time_stamp = 1000;
  packet[0].change = RawAndroidPointerData::Change::kMove;
  packet[0].kind = RawAndroidPointerData::DeviceKind::kTouch;
  packet[0].device = 0;
  packet[0].physical_x = 120.5;
  packet[0].physical_y = 240.25;
  packet[0].pressure = 0.8;
  packet[0].pressure_min = 0.0;
  packet[0].pressure_max = 1.0;
  packet[0].size = 0.25;
  packet[0].radius_major = 12.0;
  packet[0].radius_minor = 8.0;
  packet[0].orientation = 0.5;
  packet[0].tilt = 0.1;
  packet[0].platformData = 2 | (2 << 8);  // kPointerDataFlagMultiple | (2 << 8)

  packet[1] = packet[0];
  packet[1].device = 1;
  packet[1].physical_x = 300.0;
  packet[1].physical_y = 400.0;

  EXPECT_TRUE(embedder.DispatchPointerDataPacket(
      reinterpret_cast<const uint8_t*>(packet), sizeof(packet)));
  EXPECT_EQ(state.send_pointer_event_calls, 1);
  ASSERT_EQ(state.last_pointer_events.size(), 2u);
  EXPECT_EQ(state.last_pointer_events[0].embedder_id, 42);
  EXPECT_EQ(state.last_pointer_events[0].platform_data, 2 | (2 << 8));
  EXPECT_DOUBLE_EQ(state.last_pointer_events[0].size, 0.25);
  EXPECT_DOUBLE_EQ(state.last_pointer_events[0].radius_major, 12.0);
  EXPECT_DOUBLE_EQ(state.last_pointer_events[0].radius_minor, 8.0);
  EXPECT_DOUBLE_EQ(state.last_pointer_events[0].orientation, 0.5);
  EXPECT_DOUBLE_EQ(state.last_pointer_events[0].tilt, 0.1);
  EXPECT_EQ(state.last_pointer_events[1].embedder_id, 42);
  EXPECT_EQ(state.last_pointer_events[1].platform_data, 2 | (2 << 8));
}

}  // namespace testing
}  // namespace flutter
