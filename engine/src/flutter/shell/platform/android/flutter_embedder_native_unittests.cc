// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <atomic>
#include <cstring>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "flutter/common/vulkan_driver_info.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Synthetic non-null engine handles for unit tests.
constexpr uintptr_t kFakeEngineAddress = 0x12345678;
constexpr uintptr_t kFakeSpawnedEngineAddress = 0x87654321;
// Synthetic response handle address for unit tests.
constexpr uintptr_t kFakeResponseHandleAddress = 0xABCDEF01;
// Synthetic baton value for VSync tests.
constexpr intptr_t kTestVsyncBaton = 0x42;
// Synthetic engine IDs for tests.
constexpr int64_t kTestPrimaryEngineId = 101;
constexpr int64_t kTestSpawnedEngineId = 202;
// Expected count of native methods registered on FlutterJNI (41 FlutterJNI
// native declarations plus nativeShouldDisableAHB).
constexpr size_t kExpectedFlutterJniNativeMethodCount = 42;
// Android API levels for testing.
constexpr int32_t kTestApiLevel27 = 27;
constexpr int32_t kTestApiLevel33 = 33;
constexpr int32_t kTestApiLevel34 = 34;
// Refresh rates for frame pacing tests.
constexpr double kRefreshRate60Hz = 60.0;
constexpr double kRefreshRate90Hz = 90.0;
constexpr double kRefreshRate120Hz = 120.0;
// Expected refresh periods in nanoseconds.
constexpr int64_t kPeriod60HzNanos = 16666666;
constexpr int64_t kPeriod90HzNanos = 11111111;
constexpr int64_t kPeriod120HzNanos = 8333333;
// Sample start timestamp in nanoseconds.
constexpr int64_t kSampleFrameStartNanos = 1000000000LL;
// Sample surface dimensions.
constexpr size_t kTestSurfaceWidth = 1080;
constexpr size_t kTestSurfaceHeight = 2400;
// Sample viewport pixel ratio and dimensions.
constexpr float kTestPixelRatio = 3.0f;
constexpr int32_t kTestPhysicalWidth = 1080;
constexpr int32_t kTestPhysicalHeight = 2400;
constexpr int32_t kTestTouchSlop = 24;
constexpr int32_t kTestDisplayId = 0;
// Sample texture ID.
constexpr int64_t kTestTextureId = 7;
// Sample deferred loading unit ID.
constexpr int32_t kTestLoadingUnitId = 3;
// Sample response ID.
constexpr int32_t kTestResponseId = 55;
// Sample semantics node ID and action.
constexpr int32_t kTestSemanticsNodeId = 12;
constexpr int32_t kTestSemanticsAction = 1;
// Sample accessibility flags.
constexpr int32_t kTestAccessibilityFlags = 0x04;
// Sample Vulkan API version (1.3.0).
constexpr uint32_t kTestVulkanApiVersion = (1U << 22) | (3U << 12);
// Sample non-blocklisted vendor ID (Google/SwiftShader/Generic).
constexpr uint32_t kNonBlocklistedVendorId = 0x9999;
// Sample Qualcomm vendor ID and blocklisted driver version.
constexpr uint32_t kQualcommVendorId = 0x5143;
constexpr uint32_t kBlocklistedQualcommDriverVersion = (512U << 22);

// Captures calls dispatched through a mock FlutterEngineProcTable.
struct MockProcTableState {
  size_t initialize_count = 0;
  size_t run_initialized_count = 0;
  size_t deinitialize_count = 0;
  size_t shutdown_count = 0;
  size_t spawn_count = 0;
  size_t send_window_metrics_count = 0;
  size_t notify_display_update_count = 0;
  size_t send_platform_message_count = 0;
  size_t send_platform_message_response_count = 0;
  size_t create_response_handle_count = 0;
  size_t release_response_handle_count = 0;
  size_t send_pointer_event_count = 0;
  size_t dispatch_semantics_action_count = 0;
  size_t update_semantics_enabled_count = 0;
  size_t update_accessibility_features_count = 0;
  size_t register_external_texture_count = 0;
  size_t mark_external_texture_frame_available_count = 0;
  size_t unregister_external_texture_count = 0;
  size_t schedule_frame_count = 0;
  size_t notify_low_memory_warning_count = 0;
  size_t load_dart_deferred_library_count = 0;
  size_t notify_dart_deferred_library_error_count = 0;
  size_t update_locales_count = 0;
  size_t on_vsync_count = 0;

  // Captured arguments from Initialize.
  FlutterRendererType last_renderer_type = kOpenGL;
  FlutterRendererConfigResolveCallback last_resolve_callback = nullptr;
  bool last_avoid_backing_store_cache = false;
  bool last_enable_direct_platform_message_dispatch = false;
  bool has_custom_task_runners = false;
  bool platform_task_runner_is_null = false;
  bool render_task_runner_is_null = false;
  size_t custom_asset_resolvers_count = 0;
  size_t image_decoders_count = 0;
  int32_t first_image_decoder_priority = 0;
  void* last_user_data = nullptr;

  // Captured platform message fields.
  std::string last_message_channel;
  const uint8_t* last_message_bytes_ptr = nullptr;
  size_t last_message_size = 0;
  std::vector<uint8_t> last_message_payload;

  // Captured platform message response fields.
  const uint8_t* last_response_bytes_ptr = nullptr;
  size_t last_response_size = 0;
  std::vector<uint8_t> last_response_payload;
  FlutterDataCallback last_response_data_callback = nullptr;
  void* last_response_user_data = nullptr;
  bool defer_response_callback = false;

  // Captured deferred library fields.
  intptr_t last_deferred_loading_unit_id = 0;
  std::string last_deferred_error_message;
  bool last_deferred_is_transient = false;

  // Captured Spawn fields.
  std::string last_spawn_entrypoint;
  std::string last_spawn_library_uri;
  std::string last_spawn_initial_route;
  std::vector<std::string> last_spawn_args;

  // Captured VSync fields.
  intptr_t last_vsync_baton = 0;
  uint64_t last_vsync_start_nanos = 0;
  uint64_t last_vsync_target_nanos = 0;

  // Captured Window metrics.
  FlutterWindowMetricsEvent last_window_metrics{};
};

MockProcTableState* g_mock_state = nullptr;

FlutterEngineProcTable BuildMockProcTable(MockProcTableState* state) {
  g_mock_state = state;
  FlutterEngineProcTable table{};
  table.struct_size = sizeof(FlutterEngineProcTable);

  table.Initialize = [](size_t version, const FlutterRendererConfig* config,
                        const FlutterProjectArgs* args, void* user_data,
                        FLUTTER_API_SYMBOL(FlutterEngine)* engine_out) {
    if (g_mock_state != nullptr) {
      g_mock_state->initialize_count++;
      g_mock_state->last_user_data = user_data;
      if (config != nullptr) {
        g_mock_state->last_renderer_type = config->type;
        if (config->type == kDeferred) {
          g_mock_state->last_resolve_callback =
              config->deferred.resolve_callback;
        }
      }
      if (args != nullptr) {
        g_mock_state->last_enable_direct_platform_message_dispatch =
            args->enable_direct_platform_message_dispatch;
        if (args->compositor != nullptr) {
          g_mock_state->last_avoid_backing_store_cache =
              args->compositor->avoid_backing_store_cache;
        }
        if (args->custom_task_runners != nullptr) {
          g_mock_state->has_custom_task_runners = true;
          g_mock_state->platform_task_runner_is_null =
              (args->custom_task_runners->platform_task_runner == nullptr);
          g_mock_state->render_task_runner_is_null =
              (args->custom_task_runners->render_task_runner == nullptr);
        }
        g_mock_state->custom_asset_resolvers_count =
            args->custom_asset_resolvers_count;
        if (args->custom_asset_resolvers != nullptr) {
          for (size_t i = 0; i < args->custom_asset_resolvers_count; ++i) {
            const FlutterCustomAssetResolver* resolver =
                args->custom_asset_resolvers[i];
            if (resolver != nullptr &&
                resolver->destruction_callback != nullptr) {
              resolver->destruction_callback(resolver->user_data);
            }
          }
        }
        g_mock_state->image_decoders_count = args->image_decoders_count;
        if (args->image_decoders_count > 0 && args->image_decoders != nullptr &&
            args->image_decoders[0] != nullptr) {
          g_mock_state->first_image_decoder_priority =
              args->image_decoders[0]->priority;
        }
      }
    }
    if (engine_out != nullptr) {
      *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(
          kFakeEngineAddress);
    }
    return kSuccess;
  };

  table.RunInitialized = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (g_mock_state != nullptr) {
      g_mock_state->run_initialized_count++;
    }
    return kSuccess;
  };

  table.Deinitialize = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (g_mock_state != nullptr) {
      g_mock_state->deinitialize_count++;
    }
    return kSuccess;
  };

  table.Shutdown = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (g_mock_state != nullptr) {
      g_mock_state->shutdown_count++;
    }
    return kSuccess;
  };

  table.Spawn = [](FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
                   const FlutterEngineSpawnInfo* spawn_info,
                   FLUTTER_API_SYMBOL(FlutterEngine)* engine_out) {
    if (g_mock_state != nullptr) {
      g_mock_state->spawn_count++;
      if (spawn_info != nullptr) {
        if (spawn_info->entrypoint != nullptr) {
          g_mock_state->last_spawn_entrypoint = spawn_info->entrypoint;
        }
        if (spawn_info->library_uri != nullptr) {
          g_mock_state->last_spawn_library_uri = spawn_info->library_uri;
        }
        if (spawn_info->initial_route != nullptr) {
          g_mock_state->last_spawn_initial_route = spawn_info->initial_route;
        }
        g_mock_state->last_spawn_args.clear();
        for (int i = 0; i < spawn_info->entrypoint_argc; ++i) {
          if (spawn_info->entrypoint_argv != nullptr &&
              spawn_info->entrypoint_argv[i] != nullptr) {
            g_mock_state->last_spawn_args.emplace_back(
                spawn_info->entrypoint_argv[i]);
          }
        }
      }
    }
    if (engine_out != nullptr) {
      *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(
          kFakeSpawnedEngineAddress);
    }
    return kSuccess;
  };

  table.SendWindowMetricsEvent = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                    const FlutterWindowMetricsEvent* event) {
    if (g_mock_state != nullptr && event != nullptr) {
      g_mock_state->send_window_metrics_count++;
      g_mock_state->last_window_metrics = *event;
    }
    return kSuccess;
  };

  table.NotifyDisplayUpdate = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 FlutterEngineDisplaysUpdateType update_type,
                                 const FlutterEngineDisplay* displays,
                                 size_t display_count) {
    if (g_mock_state != nullptr) {
      g_mock_state->notify_display_update_count++;
    }
    return kSuccess;
  };

  table.SendPlatformMessage = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 const FlutterPlatformMessage* message) {
    if (g_mock_state != nullptr && message != nullptr) {
      g_mock_state->send_platform_message_count++;
      g_mock_state->last_message_channel =
          message->channel != nullptr ? message->channel : "";
      g_mock_state->last_message_bytes_ptr = message->message;
      g_mock_state->last_message_size = message->message_size;
      if (message->message != nullptr && message->message_size > 0) {
        g_mock_state->last_message_payload.assign(
            message->message, message->message + message->message_size);
      } else {
        g_mock_state->last_message_payload.clear();
      }
    }
    return kSuccess;
  };

  table.PlatformMessageCreateResponseHandle =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterDataCallback data_callback, void* user_data,
         FlutterPlatformMessageResponseHandle** response_out) {
        if (g_mock_state != nullptr) {
          g_mock_state->create_response_handle_count++;
          g_mock_state->last_response_data_callback = data_callback;
          g_mock_state->last_response_user_data = user_data;
        }
        if (response_out != nullptr) {
          *response_out =
              reinterpret_cast<FlutterPlatformMessageResponseHandle*>(
                  kFakeResponseHandleAddress);
        }
        return kSuccess;
      };

  table.PlatformMessageReleaseResponseHandle =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterPlatformMessageResponseHandle* response) {
        if (g_mock_state != nullptr) {
          g_mock_state->release_response_handle_count++;
          if (!g_mock_state->defer_response_callback &&
              g_mock_state->last_response_data_callback != nullptr) {
            auto callback = g_mock_state->last_response_data_callback;
            void* callback_user_data = g_mock_state->last_response_user_data;
            g_mock_state->last_response_data_callback = nullptr;
            g_mock_state->last_response_user_data = nullptr;
            callback(nullptr, 0, callback_user_data);
          }
        }
        return kSuccess;
      };

  table.SendPlatformMessageResponse =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterPlatformMessageResponseHandle* handle,
         const uint8_t* data, size_t data_length) {
        if (g_mock_state != nullptr) {
          g_mock_state->send_platform_message_response_count++;
          g_mock_state->last_response_bytes_ptr = data;
          g_mock_state->last_response_size = data_length;
          if (data != nullptr && data_length > 0) {
            g_mock_state->last_response_payload.assign(data,
                                                       data + data_length);
          } else {
            g_mock_state->last_response_payload.clear();
          }
        }
        return kSuccess;
      };

  table.SendPointerEvent = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                              const FlutterPointerEvent* events,
                              size_t events_count) {
    if (g_mock_state != nullptr) {
      g_mock_state->send_pointer_event_count++;
    }
    return kSuccess;
  };

  table.SendSemanticsAction = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 const FlutterSendSemanticsActionInfo* info) {
    (void)engine;
    (void)info;
    if (g_mock_state != nullptr) {
      g_mock_state->dispatch_semantics_action_count++;
    }
    return kSuccess;
  };

  table.DispatchSemanticsAction = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                     uint64_t id, FlutterSemanticsAction action,
                                     const uint8_t* data, size_t data_length) {
    if (g_mock_state != nullptr) {
      g_mock_state->dispatch_semantics_action_count++;
    }
    return kSuccess;
  };

  table.UpdateSemanticsEnabled = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                    bool enabled) {
    if (g_mock_state != nullptr) {
      g_mock_state->update_semantics_enabled_count++;
    }
    return kSuccess;
  };

  table.UpdateAccessibilityFeatures = [](FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine,
                                         FlutterAccessibilityFeature features) {
    if (g_mock_state != nullptr) {
      g_mock_state->update_accessibility_features_count++;
    }
    return kSuccess;
  };

  table.RegisterExternalTexture = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                     int64_t texture_identifier) {
    if (g_mock_state != nullptr) {
      g_mock_state->register_external_texture_count++;
    }
    return kSuccess;
  };

  table.MarkExternalTextureFrameAvailable =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine, int64_t texture_identifier) {
        if (g_mock_state != nullptr) {
          g_mock_state->mark_external_texture_frame_available_count++;
        }
        return kSuccess;
      };

  table.UnregisterExternalTexture = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                       int64_t texture_identifier) {
    if (g_mock_state != nullptr) {
      g_mock_state->unregister_external_texture_count++;
    }
    return kSuccess;
  };

  table.ScheduleFrame = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (g_mock_state != nullptr) {
      g_mock_state->schedule_frame_count++;
    }
    return kSuccess;
  };

  table.NotifyLowMemoryWarning = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (g_mock_state != nullptr) {
      g_mock_state->notify_low_memory_warning_count++;
    }
    return kSuccess;
  };

  table.LoadDartDeferredLibrary =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterDartDeferredLibrary* library) {
        (void)engine;
        if (g_mock_state != nullptr && library != nullptr) {
          g_mock_state->load_dart_deferred_library_count++;
          g_mock_state->last_deferred_loading_unit_id =
              library->loading_unit_id;
          if (library->destruction_callback != nullptr) {
            library->destruction_callback(library->user_data);
          }
        }
        return kSuccess;
      };

  table.NotifyDartDeferredLibraryLoadError =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterDartDeferredLibraryLoadError* error) {
        (void)engine;
        if (g_mock_state != nullptr && error != nullptr) {
          g_mock_state->notify_dart_deferred_library_error_count++;
          g_mock_state->last_deferred_loading_unit_id = error->loading_unit_id;
          g_mock_state->last_deferred_error_message =
              error->error_message != nullptr ? error->error_message : "";
          g_mock_state->last_deferred_is_transient = error->transient;
        }
        return kSuccess;
      };

  table.UpdateLocales = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                           const FlutterLocale** locales,
                           size_t locales_count) {
    if (g_mock_state != nullptr) {
      g_mock_state->update_locales_count++;
    }
    return kSuccess;
  };

  table.OnVsync = [](FLUTTER_API_SYMBOL(FlutterEngine) engine, intptr_t baton,
                     uint64_t frame_start_time_nanos,
                     uint64_t frame_target_time_nanos) {
    if (g_mock_state != nullptr) {
      g_mock_state->on_vsync_count++;
      g_mock_state->last_vsync_baton = baton;
      g_mock_state->last_vsync_start_nanos = frame_start_time_nanos;
      g_mock_state->last_vsync_target_nanos = frame_target_time_nanos;
    }
    return kSuccess;
  };

  table.RunsAOTCompiledDartCode = []() { return false; };
  table.PrefetchDefaultFontManager = []() { return kSuccess; };

  return table;
}

}  // namespace

class FlutterEmbedderNativeTest : public ::testing::Test {
 protected:
  void SetUp() override {
    AndroidVMInit::ResetGlobalStateForTesting();
    mock_state_ = std::make_unique<MockProcTableState>();
    proc_table_ = BuildMockProcTable(mock_state_.get());
    FlutterEmbedderNative::SetGlobalProcTableForTesting(&proc_table_);
  }

  void TearDown() override {
    FlutterEmbedderNative::SetGlobalProcTableForTesting(nullptr);
    g_mock_state = nullptr;
    mock_state_.reset();
    AndroidVMInit::ResetGlobalStateForTesting();
  }

  std::unique_ptr<MockProcTableState> mock_state_;
  FlutterEngineProcTable proc_table_{};
};

// =============================================================================
// 1. JNI Method Table & Router Verification
// =============================================================================

TEST_F(FlutterEmbedderNativeTest, JniRouterRegistersAll76FlutterJniMethods) {
  size_t count = 0;
  const JNINativeMethod* methods = JniRouter::GetNativeMethods(&count);
  ASSERT_NE(methods, nullptr);
  EXPECT_EQ(count, kExpectedFlutterJniNativeMethodCount);

  bool found_update_refresh_rate = false;
  bool found_on_vsync = false;
  bool found_attach = false;
  bool found_spawn = false;

  for (size_t i = 0; i < count; ++i) {
    ASSERT_NE(methods[i].name, nullptr);
    ASSERT_NE(methods[i].signature, nullptr);
    ASSERT_NE(methods[i].fnPtr, nullptr);
    std::string name(methods[i].name);
    if (name == "nativeUpdateRefreshRate") {
      found_update_refresh_rate = true;
    } else if (name == "nativeOnVsync") {
      found_on_vsync = true;
    } else if (name == "nativeAttach") {
      found_attach = true;
    } else if (name == "nativeSpawn") {
      found_spawn = true;
    }
  }

  EXPECT_TRUE(found_update_refresh_rate);
  EXPECT_TRUE(found_on_vsync);
  EXPECT_TRUE(found_attach);
  EXPECT_TRUE(found_spawn);
}

// =============================================================================
// 2. FlutterEmbedderNative Initialization & Task Runner Invariants
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       InitializeUsesDeferredRendererAndAvoidsBackingStoreCache) {
  AndroidVMArgs vm_args;
  vm_args.api_level = kTestApiLevel34;
  vm_args.assets_path = "/data/app/flutter_assets";
  vm_args.icu_data_path = "/data/app/icudtl.dat";
  AndroidVMInit::SetGlobalVMArgs(vm_args);

  FlutterEmbedderNative embedder(&proc_table_,
                                 /*use_engine_owned_task_runners=*/true);
  EXPECT_TRUE(embedder.RunBundleAndSnapshotFromLibrary(
      nullptr, "/data/app/flutter_assets", "main", "package:app/main.dart",
      nullptr, {"--verbose-logging"}, kTestPrimaryEngineId));

  EXPECT_EQ(mock_state_->initialize_count, 1u);
  EXPECT_EQ(mock_state_->run_initialized_count, 1u);
  EXPECT_EQ(mock_state_->last_renderer_type, kDeferred);
  EXPECT_NE(mock_state_->last_resolve_callback, nullptr);
  EXPECT_TRUE(mock_state_->last_avoid_backing_store_cache);
  EXPECT_TRUE(mock_state_->last_enable_direct_platform_message_dispatch);
  EXPECT_TRUE(mock_state_->has_custom_task_runners);
  // RFC 410.0000: when use_engine_owned_task_runners is true, both platform
  // and render task runners on FlutterCustomTaskRunners are nullptr so the
  // engine creates and owns its unified UI/platform and raster threads.
  EXPECT_TRUE(mock_state_->platform_task_runner_is_null);
  EXPECT_TRUE(mock_state_->render_task_runner_is_null);
  EXPECT_EQ(mock_state_->custom_asset_resolvers_count, 1u);
  EXPECT_EQ(mock_state_->image_decoders_count, 1u);
  EXPECT_EQ(mock_state_->first_image_decoder_priority,
            kAndroidSdkImageDecoderPriority);
  EXPECT_TRUE(embedder.IsValid());
  EXPECT_EQ(embedder.GetEngineId(), kTestPrimaryEngineId);
}

TEST_F(FlutterEmbedderNativeTest,
       DoesNotRegisterNdkImageDecoderBelowApiLevel28) {
  AndroidVMArgs vm_args;
  vm_args.api_level = kTestApiLevel27;
  AndroidVMInit::SetGlobalVMArgs(vm_args);

  FlutterEmbedderNative embedder(&proc_table_,
                                 /*use_engine_owned_task_runners=*/true);
  EXPECT_TRUE(embedder.RunBundleAndSnapshotFromLibrary(
      nullptr, "/data/app/flutter_assets", "main", "", nullptr, {},
      kTestPrimaryEngineId));

  EXPECT_EQ(mock_state_->image_decoders_count, 0u);
}

TEST_F(FlutterEmbedderNativeTest,
       DeferredRendererConfigCallbackResolvesOpenGLESOrSoftware) {
  AndroidVMArgs vm_args;
  vm_args.api_level = kTestApiLevel33;
  vm_args.enable_software_rendering = true;
  AndroidVMInit::SetGlobalVMArgs(vm_args);

  FlutterEmbedderNative embedder(&proc_table_);
  FlutterRendererConfig resolved_config{};
  EXPECT_TRUE(FlutterEmbedderNative::OnResolveRendererConfigCallback(
      &embedder, &resolved_config));
  EXPECT_EQ(resolved_config.type, kSoftware);
  EXPECT_NE(resolved_config.software.surface_present_callback, nullptr);
}

// =============================================================================
// 3. Platform Message Dispatch & Non-Null Zero-Byte Payload Preservation
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       PreservesNonNullZeroBytePlatformMessageAndEmptyDispatch) {
  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  // 1. DispatchEmptyPlatformMessage sends nullptr bytes and 0 size.
  EXPECT_TRUE(embedder.DispatchEmptyPlatformMessage("flutter/lifecycle",
                                                    kTestResponseId));
  EXPECT_EQ(mock_state_->send_platform_message_count, 1u);
  EXPECT_EQ(mock_state_->last_message_channel, "flutter/lifecycle");
  EXPECT_EQ(mock_state_->last_message_bytes_ptr, nullptr);
  EXPECT_EQ(mock_state_->last_message_size, 0u);
  EXPECT_EQ(mock_state_->create_response_handle_count, 1u);
  EXPECT_EQ(mock_state_->release_response_handle_count, 1u);

  // 2. DispatchPlatformMessage with non-null 0-byte pointer (&kEmptyByte)
  // preserves non-null pointer in FlutterPlatformMessage.
  const uint8_t kEmptyByte = 0;
  EXPECT_TRUE(embedder.DispatchPlatformMessage("flutter/navigation",
                                               &kEmptyByte, 0, 0));
  EXPECT_EQ(mock_state_->send_platform_message_count, 2u);
  EXPECT_EQ(mock_state_->last_message_channel, "flutter/navigation");
  EXPECT_EQ(mock_state_->last_message_bytes_ptr, &kEmptyByte);
  EXPECT_EQ(mock_state_->last_message_size, 0u);
}

TEST_F(FlutterEmbedderNativeTest,
       HandlesDartToJavaPlatformMessageAndResponseRoundTrip) {
  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  const auto* fake_handle =
      reinterpret_cast<const FlutterPlatformMessageResponseHandle*>(
          kFakeResponseHandleAddress);
  const uint8_t kEmptyByte = 0;

  FlutterPlatformMessage incoming_msg{};
  incoming_msg.struct_size = sizeof(FlutterPlatformMessage);
  incoming_msg.channel = "flutter/platform";
  incoming_msg.message = &kEmptyByte;
  incoming_msg.message_size = 0;
  incoming_msg.response_handle = fake_handle;

  FlutterEmbedderNative::OnPlatformMessageCallback(&incoming_msg, &embedder);

  // Respond to the first pending engine response ID (1).
  const std::vector<uint8_t> reply = {0x01, 0x02, 0x03};
  EXPECT_TRUE(embedder.InvokePlatformMessageResponseCallback(1, reply.data(),
                                                             reply.size()));
  EXPECT_EQ(mock_state_->send_platform_message_response_count, 1u);
  EXPECT_EQ(mock_state_->last_response_size, reply.size());
  EXPECT_EQ(mock_state_->last_response_payload, reply);
}

// =============================================================================
// 4. Deferred Component Loading & Error Notification via ProcTable
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       DispatchesDeferredLibraryLoadAndErrorThroughProcTable) {
  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  std::vector<std::string> search_paths = {
      "/data/app/split_feature.apk!lib/arm64-v8a"};
  EXPECT_TRUE(
      embedder.LoadDartDeferredLibrary(kTestLoadingUnitId, search_paths));
  EXPECT_EQ(mock_state_->load_dart_deferred_library_count, 1u);
  EXPECT_EQ(mock_state_->last_deferred_loading_unit_id, kTestLoadingUnitId);

  EXPECT_TRUE(embedder.NotifyDartDeferredLibraryLoadError(
      kTestLoadingUnitId, "Network failure", /*is_transient=*/true));
  EXPECT_EQ(mock_state_->notify_dart_deferred_library_error_count, 1u);
  EXPECT_EQ(mock_state_->last_deferred_loading_unit_id, kTestLoadingUnitId);
  EXPECT_EQ(mock_state_->last_deferred_error_message, "Network failure");
  EXPECT_TRUE(mock_state_->last_deferred_is_transient);
}

// =============================================================================
// 5. AndroidVMInit Flag Parsing, Vulkan Blocklist, and AOT Providers
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       AndroidVMInitParsesFlagsAndSelectsRenderingBackendWithVulkanDriverInfo) {
  EXPECT_EQ(android::ParseHcppFlag("--enable-surface-control"),
            std::optional<bool>(true));
  EXPECT_EQ(android::ParseHcppFlag("enable-hcpp-and-surface-control"),
            std::optional<bool>(true));
  EXPECT_EQ(android::ParseHcppFlag("enable-hcpp-and-surface-control=true"),
            std::optional<bool>(true));
  EXPECT_EQ(android::ParseHcppFlag("--enable-surface-control=false"),
            std::optional<bool>(false));
  EXPECT_EQ(android::ParseHcppFlag("enable-hcpp-and-surface-control=false"),
            std::optional<bool>(false));
  EXPECT_EQ(android::ParseHcppFlag("no-enable-hcpp-and-surface-control"),
            std::optional<bool>(false));
  EXPECT_EQ(android::ParseMergedPlatformUIThreadFlag(
                "--no-merged-platform-ui-thread"),
            std::optional<bool>(false));

  AndroidVMArgs default_vm_args;
  default_vm_args.api_level = kTestApiLevel34;
  EXPECT_FALSE(android::ShouldEnableSurfaceControl(
      default_vm_args, AndroidRenderingAPI::kImpellerVulkan));

  std::vector<std::string> raw_args = {
      "--icu-symbol-prefix=_binary_icudtl_dat",
      "--dart-flags=--old_gen_heap_size=256",
      "--enable-impeller=true",
      "--enable-surface-control=true",
  };
  AndroidVMArgs vm_args = ParseCommandLineIntoVMArgs(
      raw_args, "/data/kernel.bin", "/data/app_storage", "/data/engine_cache",
      /*init_time_millis=*/1234, kTestApiLevel34);
  EXPECT_EQ(vm_args.api_level, kTestApiLevel34);
  EXPECT_TRUE(vm_args.enable_impeller);
  EXPECT_TRUE(vm_args.enable_surface_control);
  EXPECT_EQ(vm_args.dart_old_gen_heap_size, 256);

  // Non-blocklisted Vulkan 1.3 driver selects Impeller Vulkan.
  VulkanDriverInfo good_driver(kNonBlocklistedVendorId, 1U,
                               kTestVulkanApiVersion, 1U,
                               kVkPhysicalDeviceTypeDiscreteGpu, "Test GPU");
  EXPECT_EQ(
      android::SelectRenderingAPI(vm_args, /*is_vivante=*/false, good_driver),
      AndroidRenderingAPI::kImpellerVulkan);

  // Blocklisted Qualcomm driver falls back to Impeller OpenGLES.
  VulkanDriverInfo bad_qualcomm_driver(
      kQualcommVendorId, 1U, kTestVulkanApiVersion,
      kBlocklistedQualcommDriverVersion, kVkPhysicalDeviceTypeIntegratedGpu,
      "Adreno (TM) 630");
  EXPECT_EQ(android::SelectRenderingAPI(vm_args, /*is_vivante=*/false,
                                        bad_qualcomm_driver),
            AndroidRenderingAPI::kImpellerOpenGLES);

  // SurfaceControl requires API 34+ and Impeller Vulkan or OpenGLES.
  EXPECT_TRUE(android::ShouldEnableSurfaceControl(
      vm_args, AndroidRenderingAPI::kImpellerVulkan));
  EXPECT_FALSE(android::ShouldEnableSurfaceControl(
      vm_args, AndroidRenderingAPI::kSkiaOpenGLES));
}

TEST_F(FlutterEmbedderNativeTest,
       AndroidVMInitCreatesAndCollectsAOTDataAndPrefetchesFonts) {
  auto font_provider = std::make_shared<InMemoryFontCollectionProvider>();
  auto aot_provider = std::make_shared<InMemoryAndroidAOTProvider>();
  AndroidVMInit vm_init(/*jvm_invoker=*/nullptr, font_provider, aot_provider,
                        &proc_table_);

  AndroidVMArgs args;
  args.api_level = kTestApiLevel34;
  args.aot_library_path = "/data/app/lib/arm64/libapp.so";
  args.assets_path = "/data/app/flutter_assets";

  EXPECT_TRUE(vm_init.Init(args));
  EXPECT_TRUE(vm_init.IsInitialized());
  EXPECT_EQ(aot_provider->GetCreateCount(), 1u);
  EXPECT_EQ(aot_provider->GetLastElfPath(), "/data/app/lib/arm64/libapp.so");

  EXPECT_TRUE(vm_init.PrefetchFontManager());
  EXPECT_TRUE(font_provider->IsPrefetched());
  EXPECT_EQ(font_provider->GetPrefetchCount(), 1u);
}

// =============================================================================
// 6. AndroidVsyncWaiter Frame Pacing & Detach Safety
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       AndroidVsyncWaiterComputesFramePacingAndHonorsDetachBeforeShutdown) {
  const auto info_60 = AndroidVsyncWaiter::ComputeFramePacing(
      kSampleFrameStartNanos, kRefreshRate60Hz);
  EXPECT_EQ(info_60.refresh_period_nanos, kPeriod60HzNanos);
  EXPECT_EQ(info_60.frame_target_time_nanos,
            kSampleFrameStartNanos + kPeriod60HzNanos);

  const auto info_90 = AndroidVsyncWaiter::ComputeFramePacing(
      kSampleFrameStartNanos, kRefreshRate90Hz);
  EXPECT_EQ(info_90.refresh_period_nanos, kPeriod90HzNanos);

  const auto info_120 = AndroidVsyncWaiter::ComputeFramePacing(
      kSampleFrameStartNanos, kRefreshRate120Hz);
  EXPECT_EQ(info_120.refresh_period_nanos, kPeriod120HzNanos);

  auto choreographer = std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(
      choreographer, /*jvm_invoker=*/nullptr, &proc_table_);
  waiter->SetEngine(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));
  waiter->SetRefreshRate(kRefreshRate120Hz);

  // Request VSync and fire choreographer frame while attached.
  EXPECT_TRUE(waiter->AsyncWaitForVsync(kTestVsyncBaton));
  EXPECT_TRUE(choreographer->HasPendingCallbacks());
  choreographer->FireFrame(kSampleFrameStartNanos);
  EXPECT_EQ(mock_state_->on_vsync_count, 1u);
  EXPECT_EQ(mock_state_->last_vsync_baton, kTestVsyncBaton);
  EXPECT_EQ(mock_state_->last_vsync_target_nanos,
            static_cast<uint64_t>(kSampleFrameStartNanos + kPeriod120HzNanos));

  // Request another VSync, then Detach() before the frame fires.
  // In-flight callbacks must NOT call OnVsync after Detach().
  EXPECT_TRUE(waiter->AsyncWaitForVsync(kTestVsyncBaton));
  waiter->Detach();
  EXPECT_TRUE(waiter->IsDetached());
  choreographer->FireFrame(kSampleFrameStartNanos + kPeriod120HzNanos);
  EXPECT_EQ(mock_state_->on_vsync_count, 1u);
}

// =============================================================================
// 7. AndroidEngineGroup & FlutterEmbedderNative::Spawn
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       SpawnsChildEngineViaFlutterEngineSpawnInfoAndSharesAssetResolver) {
  FlutterEmbedderNative parent(&proc_table_);
  EXPECT_TRUE(parent.RunBundleAndSnapshotFromLibrary(
      nullptr, "/data/app/flutter_assets", "main", "package:app/main.dart",
      nullptr, {}, kTestPrimaryEngineId));

  std::vector<std::string> child_args = {"--child-arg=1", "--mode=secondary"};
  std::unique_ptr<FlutterEmbedderNative> child = parent.Spawn(
      nullptr, nullptr, "secondaryMain", "package:app/secondary.dart",
      "/details", child_args, kTestSpawnedEngineId);

  ASSERT_NE(child, nullptr);
  EXPECT_TRUE(child->IsValid());
  EXPECT_EQ(child->GetEngineId(), kTestSpawnedEngineId);
  EXPECT_EQ(mock_state_->spawn_count, 1u);
  EXPECT_EQ(mock_state_->last_spawn_entrypoint, "secondaryMain");
  EXPECT_EQ(mock_state_->last_spawn_library_uri, "package:app/secondary.dart");
  EXPECT_EQ(mock_state_->last_spawn_initial_route, "/details");
  EXPECT_EQ(mock_state_->last_spawn_args, child_args);
  EXPECT_EQ(parent.GetEngineGroup()->GetActiveEngineCount(), 2u);
}

// =============================================================================
// 8. Surface Lifecycle, Metrics, Semantics, & External Textures
// =============================================================================

TEST_F(FlutterEmbedderNativeTest,
       SurfaceLifecycleAndMetricsAndTexturesDispatchThroughProcTable) {
  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  // SurfaceChanged updates window metrics.
  embedder.SurfaceChanged(kTestSurfaceWidth, kTestSurfaceHeight);
  embedder.SetViewportMetrics(kTestPixelRatio, kTestPhysicalWidth,
                              kTestPhysicalHeight, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, kTestTouchSlop, {}, {}, {}, kTestDisplayId);
  EXPECT_GE(mock_state_->send_window_metrics_count, 1u);
  EXPECT_EQ(mock_state_->last_window_metrics.width,
            static_cast<size_t>(kTestPhysicalWidth));
  EXPECT_EQ(mock_state_->last_window_metrics.height,
            static_cast<size_t>(kTestPhysicalHeight));
  EXPECT_DOUBLE_EQ(mock_state_->last_window_metrics.pixel_ratio,
                   static_cast<double>(kTestPixelRatio));

  // External textures.
  EXPECT_TRUE(embedder.RegisterTexture(kTestTextureId, nullptr, nullptr));
  EXPECT_EQ(mock_state_->register_external_texture_count, 1u);
  EXPECT_TRUE(embedder.MarkTextureFrameAvailable(kTestTextureId));
  EXPECT_EQ(mock_state_->mark_external_texture_frame_available_count, 1u);
  EXPECT_TRUE(embedder.UnregisterTexture(kTestTextureId));
  EXPECT_EQ(mock_state_->unregister_external_texture_count, 1u);

  // Semantics and accessibility.
  EXPECT_TRUE(embedder.SetSemanticsEnabled(true));
  EXPECT_EQ(mock_state_->update_semantics_enabled_count, 1u);
  EXPECT_TRUE(embedder.SetAccessibilityFeatures(kTestAccessibilityFlags));
  EXPECT_EQ(mock_state_->update_accessibility_features_count, 1u);
  EXPECT_TRUE(embedder.DispatchSemanticsAction(
      kTestSemanticsNodeId, kTestSemanticsAction, nullptr, 0));
  EXPECT_EQ(mock_state_->dispatch_semantics_action_count, 1u);

  // Frame scheduling & low memory warning.
  EXPECT_TRUE(embedder.ScheduleFrame());
  EXPECT_EQ(mock_state_->schedule_frame_count, 1u);
  EXPECT_TRUE(embedder.NotifyLowMemoryWarning());
  EXPECT_EQ(mock_state_->notify_low_memory_warning_count, 1u);
}

TEST_F(FlutterEmbedderNativeTest,
       SurfaceWindowChangedSchedulesFrameWithoutLowMemoryWarning) {
  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  // Arbitrary non-null synthetic JNI jobject handles representing two distinct
  // Android Surface instances during a surface window swap.
  constexpr uintptr_t kFakeSurfaceAddress1 = 0x1001;
  constexpr uintptr_t kFakeSurfaceAddress2 = 0x1002;
  // Expected call counts across the surface creation, swap, and teardown steps.
  constexpr size_t kNoLowMemoryWarnings = 0u;
  constexpr size_t kExpectedLowMemoryWarningsAfterDestroy = 1u;
  constexpr size_t kExpectedFrameCountAfterCreate = 1u;
  constexpr size_t kExpectedFrameCountAfterWindowSwap = 2u;

  auto fake_surface_1 = reinterpret_cast<jobject>(kFakeSurfaceAddress1);
  auto fake_surface_2 = reinterpret_cast<jobject>(kFakeSurfaceAddress2);

  embedder.SurfaceCreated(nullptr, fake_surface_1);
  EXPECT_EQ(mock_state_->schedule_frame_count, kExpectedFrameCountAfterCreate);
  EXPECT_EQ(mock_state_->notify_low_memory_warning_count, kNoLowMemoryWarnings);

  // Swapping the surface window mid-frame (e.g. convertToImageView() for
  // Hybrid Composition) must schedule a frame on the new window without
  // firing a low-memory warning or tearing down overlay surfaces.
  embedder.SurfaceWindowChanged(nullptr, fake_surface_2);
  EXPECT_EQ(mock_state_->schedule_frame_count,
            kExpectedFrameCountAfterWindowSwap);
  EXPECT_EQ(mock_state_->notify_low_memory_warning_count, kNoLowMemoryWarnings);

  // Full surface destruction must fire NotifyLowMemoryWarning.
  embedder.SurfaceDestroyed();
  EXPECT_EQ(mock_state_->notify_low_memory_warning_count,
            kExpectedLowMemoryWarningsAfterDestroy);
}

TEST_F(FlutterEmbedderNativeTest,
       PlatformMessageResponseCallbackAfterEmbedderDestroyedDoesNotCrash) {
  mock_state_->defer_response_callback = true;

  // Poison byte value used to overwrite freed FlutterEmbedderNative storage
  // so any dangling `this` dereference deterministically faults.
  constexpr int kFreedMemoryPoisonByte = 0xA5;

  alignas(FlutterEmbedderNative)
      uint8_t storage[sizeof(FlutterEmbedderNative)]{};
  auto* embedder = new (storage) FlutterEmbedderNative(&proc_table_);
  embedder->SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  const std::vector<uint8_t> request = {0x10, 0x20};
  EXPECT_TRUE(embedder->DispatchPlatformMessage(
      "flutter/platform", request.data(), request.size(), kTestResponseId));
  ASSERT_NE(mock_state_->last_response_data_callback, nullptr);
  ASSERT_NE(mock_state_->last_response_user_data, nullptr);

  FlutterDataCallback captured_callback =
      mock_state_->last_response_data_callback;
  void* captured_user_data = mock_state_->last_response_user_data;
  mock_state_->last_response_data_callback = nullptr;
  mock_state_->last_response_user_data = nullptr;

  // Destroy the embedder and poison its backing memory to simulate a response
  // callback queued on the main Looper running after nativeDestroy.
  embedder->~FlutterEmbedderNative();
  std::memset(storage, kFreedMemoryPoisonByte, sizeof(storage));

  const std::vector<uint8_t> response = {0x30, 0x40};
  captured_callback(response.data(), response.size(), captured_user_data);
}

TEST_F(FlutterEmbedderNativeTest,
       SoftwarePresentConcurrentWithSurfaceLifecycleIsThreadSafe) {
  AndroidVMArgs vm_args;
  vm_args.api_level = kTestApiLevel33;
  vm_args.enable_software_rendering = true;
  AndroidVMInit::SetGlobalVMArgs(vm_args);

  FlutterEmbedderNative embedder(&proc_table_);
  embedder.SetEngineForTesting(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kFakeEngineAddress));

  FlutterRendererConfig resolved_config{};
  ASSERT_TRUE(FlutterEmbedderNative::OnResolveRendererConfigCallback(
      &embedder, &resolved_config));
  ASSERT_EQ(resolved_config.type, kSoftware);
  ASSERT_NE(resolved_config.software.surface_present_callback, nullptr);

  // Dimensions and iteration count for concurrent software present stress test.
  constexpr size_t kSoftwareTestWidth = 16;
  constexpr size_t kSoftwareTestHeight = 16;
  constexpr size_t kBytesPerPixel = 4;
  constexpr size_t kSoftwareRowBytes = kSoftwareTestWidth * kBytesPerPixel;
  constexpr int kLifecycleIterations = 100;
  constexpr uintptr_t kFakeSurfaceAddress1 = 0x2001;
  constexpr uintptr_t kFakeSurfaceAddress2 = 0x2002;

  std::vector<uint8_t> pixels(kSoftwareRowBytes * kSoftwareTestHeight, 0xFF);
  std::atomic<bool> stop_raster{false};

  std::thread raster_thread([&]() {
    while (!stop_raster.load(std::memory_order_relaxed)) {
      EXPECT_TRUE(resolved_config.software.surface_present_callback(
          &embedder, pixels.data(), kSoftwareRowBytes, kSoftwareTestHeight));
    }
  });

  auto surface_1 = reinterpret_cast<jobject>(kFakeSurfaceAddress1);
  auto surface_2 = reinterpret_cast<jobject>(kFakeSurfaceAddress2);
  for (int i = 0; i < kLifecycleIterations; ++i) {
    embedder.SurfaceCreated(nullptr, surface_1);
    embedder.SurfaceChanged(kSoftwareTestWidth, kSoftwareTestHeight);
    embedder.SurfaceWindowChanged(nullptr, surface_2);
    embedder.SurfaceDestroyed();
  }

  stop_raster.store(true, std::memory_order_relaxed);
  raster_thread.join();
}

}  // namespace testing
}  // namespace flutter
