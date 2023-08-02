// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_win.h"
#include "fml/synchronization/waitable_event.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

// winbase.h defines GetCurrentTime as a macro.
#undef GetCurrentTime

namespace flutter {
namespace testing {

class FlutterWindowsEngineTest : public WindowsTest {};

TEST_F(FlutterWindowsEngineTest, RunDoesExpectedInitialization) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.AddDartEntrypointArgument("arg1");
  builder.AddDartEntrypointArgument("arg2");

  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  // The engine should be run with expected configuration values.
  bool run_called = false;
  modifier.embedder_api().Run = MOCK_ENGINE_PROC(
      Run, ([&run_called, engine_instance = engine.get()](
                size_t version, const FlutterRendererConfig* config,
                const FlutterProjectArgs* args, void* user_data,
                FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        run_called = true;
        *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(1);

        EXPECT_EQ(version, FLUTTER_ENGINE_VERSION);
        EXPECT_NE(config, nullptr);
        // We have an AngleSurfaceManager, so this should be using OpenGL.
        EXPECT_EQ(config->type, kOpenGL);
        EXPECT_EQ(user_data, engine_instance);
        // Spot-check arguments.
        EXPECT_NE(args->assets_path, nullptr);
        EXPECT_NE(args->icu_data_path, nullptr);
        EXPECT_EQ(args->dart_entrypoint_argc, 2U);
        EXPECT_EQ(strcmp(args->dart_entrypoint_argv[0], "arg1"), 0);
        EXPECT_EQ(strcmp(args->dart_entrypoint_argv[1], "arg2"), 0);
        EXPECT_NE(args->platform_message_callback, nullptr);
        EXPECT_NE(args->custom_task_runners, nullptr);
        EXPECT_NE(args->custom_task_runners->thread_priority_setter, nullptr);
        EXPECT_EQ(args->custom_dart_entrypoint, nullptr);
        EXPECT_NE(args->vsync_callback, nullptr);
        EXPECT_EQ(args->update_semantics_callback, nullptr);
        EXPECT_NE(args->update_semantics_callback2, nullptr);
        EXPECT_EQ(args->update_semantics_node_callback, nullptr);
        EXPECT_EQ(args->update_semantics_custom_action_callback, nullptr);

        args->custom_task_runners->thread_priority_setter(
            FlutterThreadPriority::kRaster);
        EXPECT_EQ(GetThreadPriority(GetCurrentThread()),
                  THREAD_PRIORITY_ABOVE_NORMAL);
        return kSuccess;
      }));
  // Accessibility updates must do nothing when the embedder engine is mocked
  modifier.embedder_api().UpdateAccessibilityFeatures = MOCK_ENGINE_PROC(
      UpdateAccessibilityFeatures,
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterAccessibilityFeature flags) { return kSuccess; });

  // It should send locale info.
  bool update_locales_called = false;
  modifier.embedder_api().UpdateLocales = MOCK_ENGINE_PROC(
      UpdateLocales,
      ([&update_locales_called](auto engine, const FlutterLocale** locales,
                                size_t locales_count) {
        update_locales_called = true;

        EXPECT_GT(locales_count, 0);
        EXPECT_NE(locales, nullptr);

        return kSuccess;
      }));

  // And it should send initial settings info.
  bool settings_message_sent = false;
  modifier.embedder_api().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage,
      ([&settings_message_sent](auto engine, auto message) {
        if (std::string(message->channel) == std::string("flutter/settings")) {
          settings_message_sent = true;
        }

        return kSuccess;
      }));

  // And it should send display info.
  bool notify_display_update_called = false;
  modifier.SetFrameInterval(16600000);  // 60 fps.
  modifier.embedder_api().NotifyDisplayUpdate = MOCK_ENGINE_PROC(
      NotifyDisplayUpdate,
      ([&notify_display_update_called, engine_instance = engine.get()](
           FLUTTER_API_SYMBOL(FlutterEngine) raw_engine,
           const FlutterEngineDisplaysUpdateType update_type,
           const FlutterEngineDisplay* embedder_displays,
           size_t display_count) {
        EXPECT_EQ(update_type, kFlutterEngineDisplaysUpdateTypeStartup);
        EXPECT_EQ(display_count, 1);

        FlutterEngineDisplay display = embedder_displays[0];

        EXPECT_EQ(display.display_id, 0);
        EXPECT_EQ(display.single_display, true);
        EXPECT_EQ(std::floor(display.refresh_rate), 60.0);

        notify_display_update_called = true;
        return kSuccess;
      }));

  // Set the AngleSurfaceManager to !nullptr to test ANGLE rendering.
  modifier.SetSurfaceManager(reinterpret_cast<AngleSurfaceManager*>(1));

  engine->Run();

  EXPECT_TRUE(run_called);
  EXPECT_TRUE(update_locales_called);
  EXPECT_TRUE(settings_message_sent);
  EXPECT_TRUE(notify_display_update_called);

  // Ensure that deallocation doesn't call the actual Shutdown with the bogus
  // engine pointer that the overridden Run returned.
  modifier.embedder_api().Shutdown = [](auto engine) { return kSuccess; };
  modifier.ReleaseSurfaceManager();
}

TEST_F(FlutterWindowsEngineTest, ConfiguresFrameVsync) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());
  bool on_vsync_called = false;

  modifier.embedder_api().GetCurrentTime =
      MOCK_ENGINE_PROC(GetCurrentTime, ([]() -> uint64_t { return 1; }));
  modifier.embedder_api().OnVsync = MOCK_ENGINE_PROC(
      OnVsync,
      ([&on_vsync_called, engine_instance = engine.get()](
           FLUTTER_API_SYMBOL(FlutterEngine) engine, intptr_t baton,
           uint64_t frame_start_time_nanos, uint64_t frame_target_time_nanos) {
        EXPECT_EQ(baton, 1);
        EXPECT_EQ(frame_start_time_nanos, 16600000);
        EXPECT_EQ(frame_target_time_nanos, 33200000);
        on_vsync_called = true;
        return kSuccess;
      }));
  modifier.SetStartTime(0);
  modifier.SetFrameInterval(16600000);

  engine->OnVsync(1);

  EXPECT_TRUE(on_vsync_called);
}

TEST_F(FlutterWindowsEngineTest, RunWithoutANGLEUsesSoftware) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  modifier.embedder_api().NotifyDisplayUpdate =
      MOCK_ENGINE_PROC(NotifyDisplayUpdate,
                       ([engine_instance = engine.get()](
                            FLUTTER_API_SYMBOL(FlutterEngine) raw_engine,
                            const FlutterEngineDisplaysUpdateType update_type,
                            const FlutterEngineDisplay* embedder_displays,
                            size_t display_count) { return kSuccess; }));

  // The engine should be run with expected configuration values.
  bool run_called = false;
  modifier.embedder_api().Run = MOCK_ENGINE_PROC(
      Run, ([&run_called, engine_instance = engine.get()](
                size_t version, const FlutterRendererConfig* config,
                const FlutterProjectArgs* args, void* user_data,
                FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        run_called = true;
        *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(1);
        // We don't have an AngleSurfaceManager, so we should be using software.
        EXPECT_EQ(config->type, kSoftware);
        return kSuccess;
      }));
  // Accessibility updates must do nothing when the embedder engine is mocked
  modifier.embedder_api().UpdateAccessibilityFeatures = MOCK_ENGINE_PROC(
      UpdateAccessibilityFeatures,
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterAccessibilityFeature flags) { return kSuccess; });

  // Stub out UpdateLocales and SendPlatformMessage as we don't have a fully
  // initialized engine instance.
  modifier.embedder_api().UpdateLocales = MOCK_ENGINE_PROC(
      UpdateLocales, ([](auto engine, const FlutterLocale** locales,
                         size_t locales_count) { return kSuccess; }));
  modifier.embedder_api().SendPlatformMessage =
      MOCK_ENGINE_PROC(SendPlatformMessage,
                       ([](auto engine, auto message) { return kSuccess; }));

  // Set the AngleSurfaceManager to nullptr to test software fallback path.
  modifier.SetSurfaceManager(nullptr);

  engine->Run();

  EXPECT_TRUE(run_called);

  // Ensure that deallocation doesn't call the actual Shutdown with the bogus
  // engine pointer that the overridden Run returned.
  modifier.embedder_api().Shutdown = [](auto engine) { return kSuccess; };
}

TEST_F(FlutterWindowsEngineTest, RunWithoutANGLEOnImpellerFailsToStart) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetSwitches({"--enable-impeller=true"});
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  modifier.embedder_api().NotifyDisplayUpdate =
      MOCK_ENGINE_PROC(NotifyDisplayUpdate,
                       ([engine_instance = engine.get()](
                            FLUTTER_API_SYMBOL(FlutterEngine) raw_engine,
                            const FlutterEngineDisplaysUpdateType update_type,
                            const FlutterEngineDisplay* embedder_displays,
                            size_t display_count) { return kSuccess; }));

  // Accessibility updates must do nothing when the embedder engine is mocked
  modifier.embedder_api().UpdateAccessibilityFeatures = MOCK_ENGINE_PROC(
      UpdateAccessibilityFeatures,
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterAccessibilityFeature flags) { return kSuccess; });

  // Stub out UpdateLocales and SendPlatformMessage as we don't have a fully
  // initialized engine instance.
  modifier.embedder_api().UpdateLocales = MOCK_ENGINE_PROC(
      UpdateLocales, ([](auto engine, const FlutterLocale** locales,
                         size_t locales_count) { return kSuccess; }));
  modifier.embedder_api().SendPlatformMessage =
      MOCK_ENGINE_PROC(SendPlatformMessage,
                       ([](auto engine, auto message) { return kSuccess; }));

  // Set the AngleSurfaceManager to nullptr to test software fallback path.
  modifier.SetSurfaceManager(nullptr);

  EXPECT_FALSE(engine->Run());
}

TEST_F(FlutterWindowsEngineTest, SendPlatformMessageWithoutResponse) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  const char* channel = "test";
  const std::vector<uint8_t> test_message = {1, 2, 3, 4};

  // Without a response, SendPlatformMessage should be a simple pass-through.
  bool called = false;
  modifier.embedder_api().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&called, test_message](auto engine, auto message) {
        called = true;
        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(message->message_size, test_message.size());
        EXPECT_EQ(memcmp(message->message, test_message.data(),
                         message->message_size),
                  0);
        EXPECT_EQ(message->response_handle, nullptr);
        return kSuccess;
      }));

  engine->SendPlatformMessage(channel, test_message.data(), test_message.size(),
                              nullptr, nullptr);
  EXPECT_TRUE(called);
}

TEST_F(FlutterWindowsEngineTest, PlatformMessageRoundTrip) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("hiPlatformChannels");

  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };

  auto binary_messenger =
      std::make_unique<BinaryMessengerImpl>(engine->messenger());

  engine->Run();
  bool did_call_callback = false;
  bool did_call_reply = false;
  bool did_call_dart_reply = false;
  std::string channel = "hi";
  binary_messenger->SetMessageHandler(
      channel,
      [&did_call_callback, &did_call_dart_reply](
          const uint8_t* message, size_t message_size, BinaryReply reply) {
        if (message_size == 5) {
          EXPECT_EQ(message[0], static_cast<uint8_t>('h'));
          char response[] = {'b', 'y', 'e'};
          reply(reinterpret_cast<uint8_t*>(response), 3);
          did_call_callback = true;
        } else {
          EXPECT_EQ(message_size, 3);
          EXPECT_EQ(message[0], static_cast<uint8_t>('b'));
          did_call_dart_reply = true;
        }
      });
  char payload[] = {'h', 'e', 'l', 'l', 'o'};
  binary_messenger->Send(
      channel, reinterpret_cast<uint8_t*>(payload), 5,
      [&did_call_reply](const uint8_t* reply, size_t reply_size) {
        EXPECT_EQ(reply_size, 5);
        EXPECT_EQ(reply[0], static_cast<uint8_t>('h'));
        did_call_reply = true;
      });
  // Rely on timeout mechanism in CI.
  while (!did_call_callback || !did_call_reply || !did_call_dart_reply) {
    engine->task_runner()->ProcessTasks();
  }
}

TEST_F(FlutterWindowsEngineTest, PlatformMessageRespondOnDifferentThread) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("hiPlatformChannels");

  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  EngineModifier modifier(engine.get());
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };

  auto binary_messenger =
      std::make_unique<BinaryMessengerImpl>(engine->messenger());

  engine->Run();
  bool did_call_callback = false;
  bool did_call_reply = false;
  bool did_call_dart_reply = false;
  std::string channel = "hi";
  std::unique_ptr<std::thread> reply_thread;
  binary_messenger->SetMessageHandler(
      channel,
      [&did_call_callback, &did_call_dart_reply, &reply_thread](
          const uint8_t* message, size_t message_size, BinaryReply reply) {
        if (message_size == 5) {
          EXPECT_EQ(message[0], static_cast<uint8_t>('h'));
          reply_thread.reset(new std::thread([reply = std::move(reply)]() {
            char response[] = {'b', 'y', 'e'};
            reply(reinterpret_cast<uint8_t*>(response), 3);
          }));
          did_call_callback = true;
        } else {
          EXPECT_EQ(message_size, 3);
          EXPECT_EQ(message[0], static_cast<uint8_t>('b'));
          did_call_dart_reply = true;
        }
      });
  char payload[] = {'h', 'e', 'l', 'l', 'o'};
  binary_messenger->Send(
      channel, reinterpret_cast<uint8_t*>(payload), 5,
      [&did_call_reply](const uint8_t* reply, size_t reply_size) {
        EXPECT_EQ(reply_size, 5);
        EXPECT_EQ(reply[0], static_cast<uint8_t>('h'));
        did_call_reply = true;
      });
  // Rely on timeout mechanism in CI.
  while (!did_call_callback || !did_call_reply || !did_call_dart_reply) {
    engine->task_runner()->ProcessTasks();
  }
  ASSERT_TRUE(reply_thread);
  reply_thread->join();
}

TEST_F(FlutterWindowsEngineTest, SendPlatformMessageWithResponse) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  const char* channel = "test";
  const std::vector<uint8_t> test_message = {1, 2, 3, 4};
  auto* dummy_response_handle =
      reinterpret_cast<FlutterPlatformMessageResponseHandle*>(5);
  const FlutterDesktopBinaryReply reply_handler = [](auto... args) {};
  void* reply_user_data = reinterpret_cast<void*>(6);

  // When a response is requested, a handle should be created, passed as part
  // of the message, and then released.
  bool create_response_handle_called = false;
  modifier.embedder_api().PlatformMessageCreateResponseHandle =
      MOCK_ENGINE_PROC(
          PlatformMessageCreateResponseHandle,
          ([&create_response_handle_called, &reply_handler, reply_user_data,
            dummy_response_handle](auto engine, auto reply, auto user_data,
                                   auto response_handle) {
            create_response_handle_called = true;
            EXPECT_EQ(reply, reply_handler);
            EXPECT_EQ(user_data, reply_user_data);
            EXPECT_NE(response_handle, nullptr);
            *response_handle = dummy_response_handle;
            return kSuccess;
          }));
  bool release_response_handle_called = false;
  modifier.embedder_api().PlatformMessageReleaseResponseHandle =
      MOCK_ENGINE_PROC(
          PlatformMessageReleaseResponseHandle,
          ([&release_response_handle_called, dummy_response_handle](
               auto engine, auto response_handle) {
            release_response_handle_called = true;
            EXPECT_EQ(response_handle, dummy_response_handle);
            return kSuccess;
          }));
  bool send_message_called = false;
  modifier.embedder_api().SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&send_message_called, test_message,
                             dummy_response_handle](auto engine, auto message) {
        send_message_called = true;
        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(message->message_size, test_message.size());
        EXPECT_EQ(memcmp(message->message, test_message.data(),
                         message->message_size),
                  0);
        EXPECT_EQ(message->response_handle, dummy_response_handle);
        return kSuccess;
      }));

  engine->SendPlatformMessage(channel, test_message.data(), test_message.size(),
                              reply_handler, reply_user_data);
  EXPECT_TRUE(create_response_handle_called);
  EXPECT_TRUE(release_response_handle_called);
  EXPECT_TRUE(send_message_called);
}

TEST_F(FlutterWindowsEngineTest, DispatchSemanticsAction) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  bool called = false;
  std::string message = "Hello";
  modifier.embedder_api().DispatchSemanticsAction = MOCK_ENGINE_PROC(
      DispatchSemanticsAction,
      ([&called, &message](auto engine, auto target, auto action, auto data,
                           auto data_length) {
        called = true;
        EXPECT_EQ(target, 42);
        EXPECT_EQ(action, kFlutterSemanticsActionDismiss);
        EXPECT_EQ(memcmp(data, message.c_str(), message.size()), 0);
        EXPECT_EQ(data_length, message.size());
        return kSuccess;
      }));

  auto data = fml::MallocMapping::Copy(message.c_str(), message.size());
  engine->DispatchSemanticsAction(42, kFlutterSemanticsActionDismiss,
                                  std::move(data));
  EXPECT_TRUE(called);
}

TEST_F(FlutterWindowsEngineTest, SetsThreadPriority) {
  WindowsPlatformThreadPrioritySetter(FlutterThreadPriority::kBackground);
  EXPECT_EQ(GetThreadPriority(GetCurrentThread()),
            THREAD_PRIORITY_BELOW_NORMAL);

  WindowsPlatformThreadPrioritySetter(FlutterThreadPriority::kDisplay);
  EXPECT_EQ(GetThreadPriority(GetCurrentThread()),
            THREAD_PRIORITY_ABOVE_NORMAL);

  WindowsPlatformThreadPrioritySetter(FlutterThreadPriority::kRaster);
  EXPECT_EQ(GetThreadPriority(GetCurrentThread()),
            THREAD_PRIORITY_ABOVE_NORMAL);

  // FlutterThreadPriority::kNormal does not change thread priority, reset to 0
  // here.
  SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_NORMAL);

  WindowsPlatformThreadPrioritySetter(FlutterThreadPriority::kNormal);
  EXPECT_EQ(GetThreadPriority(GetCurrentThread()), THREAD_PRIORITY_NORMAL);
}

TEST_F(FlutterWindowsEngineTest, AddPluginRegistrarDestructionCallback) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  MockEmbedderApiForKeyboard(modifier,
                             std::make_shared<MockKeyResponseController>());

  engine->Run();

  // Verify that destruction handlers don't overwrite each other.
  int result1 = 0;
  int result2 = 0;
  engine->AddPluginRegistrarDestructionCallback(
      [](FlutterDesktopPluginRegistrarRef ref) {
        auto result = reinterpret_cast<int*>(ref);
        *result = 1;
      },
      reinterpret_cast<FlutterDesktopPluginRegistrarRef>(&result1));
  engine->AddPluginRegistrarDestructionCallback(
      [](FlutterDesktopPluginRegistrarRef ref) {
        auto result = reinterpret_cast<int*>(ref);
        *result = 2;
      },
      reinterpret_cast<FlutterDesktopPluginRegistrarRef>(&result2));

  engine->Stop();
  EXPECT_EQ(result1, 1);
  EXPECT_EQ(result2, 2);
}

TEST_F(FlutterWindowsEngineTest, ScheduleFrame) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  bool called = false;
  modifier.embedder_api().ScheduleFrame =
      MOCK_ENGINE_PROC(ScheduleFrame, ([&called](auto engine) {
                         called = true;
                         return kSuccess;
                       }));

  engine->ScheduleFrame();
  EXPECT_TRUE(called);
}

TEST_F(FlutterWindowsEngineTest, SetNextFrameCallback) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  bool called = false;
  modifier.embedder_api().SetNextFrameCallback = MOCK_ENGINE_PROC(
      SetNextFrameCallback, ([&called](auto engine, auto callback, auto data) {
        called = true;
        return kSuccess;
      }));

  engine->SetNextFrameCallback([]() {});
  EXPECT_TRUE(called);
}

TEST_F(FlutterWindowsEngineTest, GetExecutableName) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EXPECT_EQ(engine->GetExecutableName(), "flutter_windows_unittests.exe");
}

// Ensure that after setting or resetting the high contrast feature,
// the corresponding status flag can be retrieved from the engine.
TEST_F(FlutterWindowsEngineTest, UpdateHighContrastFeature) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  bool called = false;
  modifier.embedder_api().UpdateAccessibilityFeatures = MOCK_ENGINE_PROC(
      UpdateAccessibilityFeatures, ([&called](auto engine, auto flags) {
        called = true;
        return kSuccess;
      }));

  engine->UpdateHighContrastEnabled(true);
  EXPECT_TRUE(
      engine->EnabledAccessibilityFeatures() &
      FlutterAccessibilityFeature::kFlutterAccessibilityFeatureHighContrast);
  EXPECT_TRUE(engine->high_contrast_enabled());
  EXPECT_TRUE(called);

  engine->UpdateHighContrastEnabled(false);
  EXPECT_FALSE(
      engine->EnabledAccessibilityFeatures() &
      FlutterAccessibilityFeature::kFlutterAccessibilityFeatureHighContrast);
  EXPECT_FALSE(engine->high_contrast_enabled());
}

TEST_F(FlutterWindowsEngineTest, PostRasterThreadTask) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();
  EngineModifier modifier(engine.get());

  modifier.embedder_api().PostRenderThreadTask = MOCK_ENGINE_PROC(
      PostRenderThreadTask, ([](auto engine, auto callback, auto context) {
        callback(context);
        return kSuccess;
      }));

  bool called = false;
  engine->PostRasterThreadTask([&called]() { called = true; });

  EXPECT_TRUE(called);
}

class MockFlutterWindowsView : public FlutterWindowsView {
 public:
  MockFlutterWindowsView(std::unique_ptr<WindowBindingHandler> wbh)
      : FlutterWindowsView(std::move(wbh)) {}
  ~MockFlutterWindowsView() {}

  MOCK_METHOD2(NotifyWinEventWrapper,
               void(ui::AXPlatformNodeWin*, ax::mojom::Event));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockFlutterWindowsView);
};

TEST_F(FlutterWindowsEngineTest, AlertPlatformMessage) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("alertPlatformChannel");

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  ui::AXPlatformNodeDelegateBase parent_delegate;
  AlertPlatformNodeDelegate delegate(parent_delegate);
  ON_CALL(*window_binding_handler, GetAlertDelegate).WillByDefault([&delegate] {
    return &delegate;
  });
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };

  auto binary_messenger =
      std::make_unique<BinaryMessengerImpl>(engine->messenger());
  binary_messenger->SetMessageHandler(
      "semantics", [&engine](const uint8_t* message, size_t message_size,
                             BinaryReply reply) {
        engine->UpdateSemanticsEnabled(true);
        char response[] = "";
        reply(reinterpret_cast<uint8_t*>(response), 0);
      });

  bool did_call = false;
  ON_CALL(view, NotifyWinEventWrapper)
      .WillByDefault([&did_call](ui::AXPlatformNodeWin* node,
                                 ax::mojom::Event event) { did_call = true; });

  engine->UpdateSemanticsEnabled(true);
  engine->Run();

  // Rely on timeout mechanism in CI.
  while (!did_call) {
    engine->task_runner()->ProcessTasks();
  }
}

class MockWindowsLifecycleManager : public WindowsLifecycleManager {
 public:
  MockWindowsLifecycleManager(FlutterWindowsEngine* engine)
      : WindowsLifecycleManager(engine) {}
  virtual ~MockWindowsLifecycleManager() {}

  MOCK_METHOD4(Quit,
               void(std::optional<HWND>,
                    std::optional<WPARAM>,
                    std::optional<LPARAM>,
                    UINT));
  MOCK_METHOD4(DispatchMessage, void(HWND, UINT, WPARAM, LPARAM));
  MOCK_METHOD0(IsLastWindowOfProcess, bool(void));
};

TEST_F(FlutterWindowsEngineTest, TestExit) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("exitTestExit");
  bool finished = false;

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  ON_CALL(*handler, Quit)
      .WillByDefault(
          [&finished](std::optional<HWND> hwnd, std::optional<WPARAM> wparam,
                      std::optional<LPARAM> lparam,
                      UINT exit_code) { finished = exit_code == 0; });
  ON_CALL(*handler, IsLastWindowOfProcess).WillByDefault([]() { return true; });
  EXPECT_CALL(*handler, Quit).Times(1);
  modifier.SetLifecycleManager(std::move(handler));
  engine->OnApplicationLifecycleEnabled();

  engine->Run();

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);

  // The test will only succeed when this while loop exits. Otherwise it will
  // timeout.
  while (!finished) {
    engine->task_runner()->ProcessTasks();
  }
}

TEST_F(FlutterWindowsEngineTest, TestExitCancel) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("exitTestCancel");
  bool finished = false;
  bool did_call = false;

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  ON_CALL(*handler, Quit)
      .WillByDefault([&finished](std::optional<HWND> hwnd,
                                 std::optional<WPARAM> wparam,
                                 std::optional<LPARAM> lparam,
                                 UINT exit_code) { finished = true; });
  ON_CALL(*handler, IsLastWindowOfProcess).WillByDefault([]() { return true; });
  EXPECT_CALL(*handler, Quit).Times(0);
  modifier.SetLifecycleManager(std::move(handler));
  engine->OnApplicationLifecycleEnabled();

  auto binary_messenger =
      std::make_unique<BinaryMessengerImpl>(engine->messenger());
  binary_messenger->SetMessageHandler(
      "flutter/platform", [&did_call](const uint8_t* message,
                                      size_t message_size, BinaryReply reply) {
        std::string contents(message, message + message_size);
        EXPECT_NE(contents.find("\"method\":\"System.exitApplication\""),
                  std::string::npos);
        EXPECT_NE(contents.find("\"type\":\"required\""), std::string::npos);
        EXPECT_NE(contents.find("\"exitCode\":0"), std::string::npos);
        did_call = true;
        char response[] = "";
        reply(reinterpret_cast<uint8_t*>(response), 0);
      });

  engine->Run();

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);

  while (!did_call) {
    engine->task_runner()->ProcessTasks();
  }

  EXPECT_FALSE(finished);
}

TEST_F(FlutterWindowsEngineTest, TestExitSecondCloseMessage) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("exitTestExit");
  bool second_close = false;

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  auto& handler_obj = *handler;
  ON_CALL(handler_obj, IsLastWindowOfProcess).WillByDefault([]() {
    return true;
  });
  ON_CALL(handler_obj, Quit)
      .WillByDefault(
          [&handler_obj](std::optional<HWND> hwnd, std::optional<WPARAM> wparam,
                         std::optional<LPARAM> lparam, UINT exit_code) {
            handler_obj.WindowsLifecycleManager::Quit(hwnd, wparam, lparam,
                                                      exit_code);
          });
  ON_CALL(handler_obj, DispatchMessage)
      .WillByDefault(
          [&engine](HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
            engine->window_proc_delegate_manager()->OnTopLevelWindowProc(
                hwnd, msg, wparam, lparam);
          });
  modifier.SetLifecycleManager(std::move(handler));
  engine->OnApplicationLifecycleEnabled();

  engine->Run();

  // This delegate will be registered after the lifecycle manager, so it will be
  // called only when a message is not consumed by the lifecycle manager. This
  // should be called on the second, synthesized WM_CLOSE message that the
  // lifecycle manager posts.
  engine->window_proc_delegate_manager()->RegisterTopLevelWindowProcDelegate(
      [](HWND hwnd, UINT message, WPARAM wpar, LPARAM lpar, void* user_data,
         LRESULT* result) {
        switch (message) {
          case WM_CLOSE: {
            bool* called = reinterpret_cast<bool*>(user_data);
            *called = true;
            return true;
          }
        }
        return false;
      },
      reinterpret_cast<void*>(&second_close));

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);

  while (!second_close) {
    engine->task_runner()->ProcessTasks();
  }
}

TEST_F(FlutterWindowsEngineTest, TestExitCloseMultiWindow) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  builder.SetDartEntrypoint("exitTestExit");
  bool finished = false;

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  ON_CALL(*handler, IsLastWindowOfProcess).WillByDefault([&finished]() {
    finished = true;
    return false;
  });
  // Quit should not be called when there is more than one window.
  EXPECT_CALL(*handler, Quit).Times(0);
  modifier.SetLifecycleManager(std::move(handler));
  engine->OnApplicationLifecycleEnabled();

  engine->Run();

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);

  while (!finished) {
    engine->task_runner()->ProcessTasks();
  }
}

TEST_F(FlutterWindowsEngineTest, LifecycleManagerDisabledByDefault) {
  FlutterWindowsEngineBuilder builder{GetContext()};

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  EXPECT_CALL(*handler, IsLastWindowOfProcess).Times(0);
  modifier.SetLifecycleManager(std::move(handler));

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);
}

TEST_F(FlutterWindowsEngineTest, EnableApplicationLifecycle) {
  FlutterWindowsEngineBuilder builder{GetContext()};

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  MockFlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(builder.Build());
  FlutterWindowsEngine* engine = view.GetEngine();

  EngineModifier modifier(engine);
  modifier.embedder_api().RunsAOTCompiledDartCode = []() { return false; };
  auto handler = std::make_unique<MockWindowsLifecycleManager>(engine);
  ON_CALL(*handler, IsLastWindowOfProcess).WillByDefault([]() {
    return false;
  });
  EXPECT_CALL(*handler, IsLastWindowOfProcess).Times(1);
  modifier.SetLifecycleManager(std::move(handler));
  engine->OnApplicationLifecycleEnabled();

  engine->window_proc_delegate_manager()->OnTopLevelWindowProc(0, WM_CLOSE, 0,
                                                               0);
}

}  // namespace testing
}  // namespace flutter
