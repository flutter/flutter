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
  VsyncCallback saved_vsync_callback = nullptr;
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
    g_fake_state->saved_vsync_callback = args->vsync_callback;
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

}  // namespace testing
}  // namespace flutter
