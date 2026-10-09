// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <limits>
#include <string>
#include <utility>
#include <vector>

#include "embedder.h"
#include "embedder_asset_resolver.h"
#include "embedder_engine.h"
#include "embedder_image_generator.h"
#include "embedder_layers.h"
#include "embedder_semantics_update.h"
#include "flutter/common/constants.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_backingstore_producer_software.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/assertions_skia.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/tonic/converter/dart_converter.h"

#if defined(FML_OS_MACOSX)
#include <pthread.h>
#endif

// CREATE_FFI_LAMBDA is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace {

static uint64_t NanosFromEpoch(int millis_from_now) {
  const auto now = fml::TimePoint::Now();
  const auto delta = fml::TimeDelta::FromMilliseconds(millis_from_now);
  return (now + delta).ToEpochDelta().ToNanoseconds();
}

}  // namespace

namespace flutter {
namespace testing {

using EmbedderTest = testing::EmbedderTest;

TEST(EmbedderTestNoFixture, MustNotRunWithInvalidArgs) {
  EmbedderTestContextSoftware context;
  EmbedderConfigBuilder builder(
      context, EmbedderConfigBuilder::InitializationPreference::kNoInitialize);
  auto engine = builder.LaunchEngine();
  ASSERT_FALSE(engine.is_valid());
}

TEST_F(EmbedderTest, CanLaunchAndShutdownWithValidProjectArgs) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
}

// TODO(41999): Disabled because flaky.
TEST_F(EmbedderTest, DISABLED_CanLaunchAndShutdownMultipleTimes) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  for (size_t i = 0; i < 3; ++i) {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
    FML_LOG(INFO) << "Engine launch count: " << i + 1;
  }
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypoint) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  static fml::AutoResetWaitableEvent latch;
  auto entrypoint = []() { latch.Signal(); };
  context.AddFfiNativeCallback("SayHiFromCustomEntrypoint",
                               reinterpret_cast<void*>(+entrypoint));
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("customEntrypoint");
  auto engine = builder.LaunchEngine();
  latch.Wait();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypointMacro) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent latch3;

  // Can be defined separately.
  auto entry1 = [&latch1]() {
    FML_LOG(INFO) << "In Callback 1";
    latch1.Signal();
  };
  auto native_entry1 = CREATE_FFI_LAMBDA(entry1);
  context.AddFfiNativeCallback("SayHiFromCustomEntrypoint1", native_entry1);

  // Can be wrapped in the args.
  auto entry2 = [&latch2]() {
    FML_LOG(INFO) << "In Callback 2";
    latch2.Signal();
  };
  context.AddFfiNativeCallback("SayHiFromCustomEntrypoint2",
                               CREATE_FFI_LAMBDA(entry2));

  // Everything can be inline.
  context.AddFfiNativeCallback("SayHiFromCustomEntrypoint3",
                               CREATE_FFI_LAMBDA([&latch3]() {
                                 FML_LOG(INFO) << "In Callback 3";
                                 latch3.Signal();
                               }));

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("customEntrypoint1");
  auto engine = builder.LaunchEngine();
  latch1.Wait();
  latch2.Wait();
  latch3.Wait();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanTerminateCleanly) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("terminateExitCodeHandler");
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, ExecutableNameNotNull) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  // Supply a callback to Dart for the test fixture to pass Platform.executable
  // back to us.
  fml::AutoResetWaitableEvent latch;
  context.AddFfiNativeCallback(
      "NotifyStringValue", CREATE_FFI_LAMBDA([&](Dart_Handle value) {
        const auto dart_string =
            tonic::DartConverter<std::string>::FromDart(value);
        EXPECT_EQ("/path/to/binary", dart_string);
        latch.Signal();
      }));

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("executableNameNotNull");
  builder.SetExecutableName("/path/to/binary");
  auto engine = builder.LaunchEngine();
  latch.Wait();
}

TEST_F(EmbedderTest, ImplicitViewNotNull) {
  // TODO(loicsharma): Update this test when embedders can opt-out
  // of the implicit view.
  // See: https://github.com/flutter/flutter/issues/120306
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  bool implicitViewNotNull = false;
  fml::AutoResetWaitableEvent latch;
  context.AddFfiNativeCallback("NotifyBoolValue",
                               CREATE_FFI_LAMBDA([&](bool value) {
                                 implicitViewNotNull = value;
                                 latch.Signal();
                               }));

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("implicitViewNotNull");
  auto engine = builder.LaunchEngine();
  latch.Wait();

  EXPECT_TRUE(implicitViewNotNull);
}

std::atomic_size_t EmbedderTestTaskRunner::sEmbedderTaskRunnerIdentifiers = {};

TEST_F(EmbedderTest, CanSpecifyCustomUITaskRunner) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  auto ui_thread = std::make_unique<fml::Thread>("test_ui_thread");
  auto ui_task_runner = ui_thread->GetTaskRunner();
  std::mutex ui_task_runner_mutex;
  bool ui_task_runner_destroyed = false;
  auto platform_thread = std::make_unique<fml::Thread>("test_platform_thread");
  auto platform_task_runner = platform_thread->GetTaskRunner();
  UniqueEngine engine;

  EmbedderTestTaskRunner test_ui_task_runner =
      EmbedderTestTaskRunnerBuilder()
          .SetRealTaskRunner(ui_task_runner)
          .SetTaskExpiryCallback([&](FlutterTask task) {
            // The UI task runner will be destroyed during engine shutdown.  It
            // should continue dispatching tasks until the engine invokes the
            // destruction callback.  After that it must stop using the engine.
            std::scoped_lock lock(ui_task_runner_mutex);
            if (ui_task_runner_destroyed) {
              return;
            }
            FlutterEngineRunTask(engine.get(), &task);
          })
          .SetDestructionCallback([&]() {
            std::scoped_lock lock(ui_task_runner_mutex);
            ui_task_runner_destroyed = true;
          })
          .Build();

  EmbedderTestTaskRunner test_platform_task_runner =
      EmbedderTestTaskRunnerBuilder()
          .SetRealTaskRunner(platform_task_runner)
          .SetTaskExpiryCallback([&](FlutterTask task) {
            if (!engine.is_valid()) {
              return;
            }
            FlutterEngineRunTask(engine.get(), &task);
          })
          .Build();

  fml::AutoResetWaitableEvent signal_latch_ui;
  fml::AutoResetWaitableEvent signal_latch_platform;

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
        // Assert that the UI isolate is running on platform thread.
        ASSERT_TRUE(ui_task_runner->RunsTasksOnCurrentThread());
        signal_latch_ui.Signal();
      }));

  platform_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto ui_task_runner_description =
        test_ui_task_runner.GetFlutterTaskRunnerDescription();
    const auto platform_task_runner_description =
        test_platform_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSurface(DlISize(1, 1));
    builder.SetUITaskRunner(&ui_task_runner_description);
    builder.SetPlatformTaskRunner(&platform_task_runner_description);
    builder.SetDartEntrypoint("canSpecifyCustomUITaskRunner");
    builder.SetPlatformMessageCallback(
        [&](const FlutterPlatformMessage* message) {
          ASSERT_TRUE(platform_task_runner->RunsTasksOnCurrentThread());
          signal_latch_platform.Signal();
        });
    engine = builder.InitializeEngine();
    ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
    ASSERT_TRUE(engine.is_valid());
  });
  signal_latch_ui.Wait();
  signal_latch_platform.Wait();

  fml::AutoResetWaitableEvent kill_latch;
  platform_task_runner->PostTask([&] {
    engine.reset();
    platform_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  });
  kill_latch.Wait();

  // Shut down the threads before exiting the test.  There may still be
  // pending tasks queued to the task runners, and they must not run
  // after the engine goes out of scope.
  ui_thread.reset();
  platform_thread.reset();
}

TEST_F(EmbedderTest, IgnoresStaleTasks) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  auto ui_task_runner = CreateNewThread("test_ui_thread");
  auto platform_task_runner = CreateNewThread("test_platform_thread");
  static std::mutex engine_mutex;
  UniqueEngine engine;
  FlutterEngine engine_ptr;

  EmbedderTestTaskRunner test_ui_task_runner(
      ui_task_runner, [&](FlutterTask task) {
        // The check for engine.is_valid() is intentionally absent here.
        // FlutterEngineRunTask must be able to detect and ignore stale tasks
        // without crashing even if the engine pointer is not null.
        // Because the engine is destroyed on platform thread,
        // relying solely on engine.is_valid() in UI thread is not safe.
        FlutterEngineRunTask(engine_ptr, &task);
      });
  EmbedderTestTaskRunner test_platform_task_runner(
      platform_task_runner, [&](FlutterTask task) {
        std::scoped_lock lock(engine_mutex);
        if (!engine.is_valid()) {
          return;
        }
        FlutterEngineRunTask(engine.get(), &task);
      });

  fml::AutoResetWaitableEvent init_latch;

  platform_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto ui_task_runner_description =
        test_ui_task_runner.GetFlutterTaskRunnerDescription();
    const auto platform_task_runner_description =
        test_platform_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetUITaskRunner(&ui_task_runner_description);
    builder.SetPlatformTaskRunner(&platform_task_runner_description);
    {
      std::scoped_lock lock(engine_mutex);
      engine = builder.InitializeEngine();
    }
    init_latch.Signal();
  });

  init_latch.Wait();
  engine_ptr = engine.get();

  auto flutter_engine = reinterpret_cast<EmbedderEngine*>(engine.get());

  // Schedule task on UI thread that will likely run after the engine has shut
  // down.
  flutter_engine->GetTaskRunners().GetUITaskRunner()->PostDelayedTask(
      []() {}, fml::TimeDelta::FromMilliseconds(50));

  fml::AutoResetWaitableEvent kill_latch;
  platform_task_runner->PostTask([&] {
    engine.reset();
    platform_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  });
  kill_latch.Wait();

  // Ensure that the schedule task indeed runs.
  kill_latch.Reset();
  ui_task_runner->PostDelayedTask([&]() { kill_latch.Signal(); },
                                  fml::TimeDelta::FromMilliseconds(50));
  kill_latch.Wait();
}

TEST_F(EmbedderTest, MergedPlatformUIThread) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  auto task_runner = CreateNewThread("test_thread");
  UniqueEngine engine;

  EmbedderTestTaskRunner test_task_runner(task_runner, [&](FlutterTask task) {
    if (!engine.is_valid()) {
      return;
    }
    FlutterEngineRunTask(engine.get(), &task);
  });

  fml::AutoResetWaitableEvent signal_latch_ui;
  fml::AutoResetWaitableEvent signal_latch_platform;

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
        // Assert that the UI isolate is running on platform thread.
        ASSERT_TRUE(task_runner->RunsTasksOnCurrentThread());
        signal_latch_ui.Signal();
      }));

  task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto task_runner_description =
        test_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSurface(DlISize(1, 1));
    builder.SetUITaskRunner(&task_runner_description);
    builder.SetPlatformTaskRunner(&task_runner_description);
    builder.SetDartEntrypoint("mergedPlatformUIThread");
    builder.SetPlatformMessageCallback(
        [&](const FlutterPlatformMessage* message) {
          ASSERT_TRUE(task_runner->RunsTasksOnCurrentThread());
          signal_latch_platform.Signal();
        });
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });
  signal_latch_ui.Wait();
  signal_latch_platform.Wait();

  fml::AutoResetWaitableEvent kill_latch;
  task_runner->PostTask([&] {
    engine.reset();
    task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  });
  kill_latch.Wait();
}

TEST_F(EmbedderTest, UITaskRunnerFlushesMicrotasks) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  auto ui_task_runner = CreateNewThread("test_ui_thread");
  UniqueEngine engine;

  EmbedderTestTaskRunner test_task_runner(
      // Assert that the UI isolate is running on platform thread.
      ui_task_runner, [&](FlutterTask task) {
        if (!engine.is_valid()) {
          return;
        }
        FlutterEngineRunTask(engine.get(), &task);
      });

  fml::AutoResetWaitableEvent signal_latch;

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
        ASSERT_TRUE(ui_task_runner->RunsTasksOnCurrentThread());
        signal_latch.Signal();
      }));

  ui_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto task_runner_description =
        test_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSurface(DlISize(1, 1));
    builder.SetUITaskRunner(&task_runner_description);
    builder.SetDartEntrypoint("uiTaskRunnerFlushesMicrotasks");
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });
  signal_latch.Wait();

  fml::AutoResetWaitableEvent kill_latch;
  ui_task_runner->PostTask([&] {
    engine.reset();
    ui_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  });
  kill_latch.Wait();
}

TEST_F(EmbedderTest, CanSpecifyCustomPlatformTaskRunner) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  fml::AutoResetWaitableEvent latch;

  // Run the test on its own thread with a message loop so that it can safely
  // pump its event loop while we wait for all the conditions to be checked.
  auto platform_task_runner = CreateNewThread("test_platform_thread");
  static std::mutex engine_mutex;
  static bool signaled_once = false;
  std::atomic<bool> destruction_callback_called = false;
  UniqueEngine engine;

  EmbedderTestTaskRunner test_task_runner =
      EmbedderTestTaskRunnerBuilder()
          .SetRealTaskRunner(platform_task_runner)
          .SetTaskExpiryCallback([&](FlutterTask task) {
            std::scoped_lock lock(engine_mutex);
            if (!engine.is_valid()) {
              return;
            }
            // There may be multiple tasks posted but we only need to check
            // assertions once.
            if (signaled_once) {
              FlutterEngineRunTask(engine.get(), &task);
              return;
            }

            signaled_once = true;
            ASSERT_TRUE(engine.is_valid());
            ASSERT_EQ(FlutterEngineRunTask(engine.get(), &task), kSuccess);
            latch.Signal();
          })
          .SetDestructionCallback(
              [&]() { destruction_callback_called.store(true); })
          .Build();

  platform_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto task_runner_description =
        test_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSurface(DlISize(1, 1));
    builder.SetPlatformTaskRunner(&task_runner_description);
    builder.SetDartEntrypoint("invokePlatformTaskRunner");
    std::scoped_lock lock(engine_mutex);
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });

  // Signaled when all the assertions are checked.
  latch.Wait();
  ASSERT_TRUE(engine.is_valid());

  // Since the engine was started on its own thread, it must be killed there as
  // well.
  fml::AutoResetWaitableEvent kill_latch;
  platform_task_runner->PostTask(fml::MakeCopyable([&]() mutable {
    std::scoped_lock lock(engine_mutex);
    engine.reset();

    // There may still be pending tasks on the platform thread that were queued
    // by the test_task_runner.  Signal the latch after these tasks have been
    // consumed.
    platform_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  }));
  kill_latch.Wait();

  ASSERT_TRUE(signaled_once);
  signaled_once = false;

  ASSERT_TRUE(destruction_callback_called.load());
  destruction_callback_called = false;
}

TEST(EmbedderTestNoFixture, CanGetCurrentTimeInNanoseconds) {
  auto point1 = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(FlutterEngineGetCurrentTime()));
  auto point2 = fml::TimePoint::Now();

  ASSERT_LT((point2 - point1), fml::TimeDelta::FromMilliseconds(1));
}

TEST_F(EmbedderTest, CanReloadSystemFonts) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  auto result = FlutterEngineReloadSystemFonts(engine.get());
  ASSERT_EQ(result, kSuccess);
}

TEST_F(EmbedderTest, IsolateServiceIdSent) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  fml::AutoResetWaitableEvent latch;

  fml::Thread thread;
  UniqueEngine engine;
  std::string isolate_message;

  thread.GetTaskRunner()->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("main");
    builder.SetPlatformMessageCallback(
        [&](const FlutterPlatformMessage* message) {
          if (strcmp(message->channel, "flutter/isolate") == 0) {
            isolate_message = {reinterpret_cast<const char*>(message->message),
                               message->message_size};
            latch.Signal();
          }
        });
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });

  // Wait for the isolate ID message and check its format.
  latch.Wait();
  ASSERT_EQ(isolate_message.find("isolates/"), 0ul);

  // Since the engine was started on its own thread, it must be killed there as
  // well.
  fml::AutoResetWaitableEvent kill_latch;
  thread.GetTaskRunner()->PostTask(
      fml::MakeCopyable([&engine, &kill_latch]() mutable {
        engine.reset();
        kill_latch.Signal();
      }));
  kill_latch.Wait();
}

//------------------------------------------------------------------------------
/// Creates a platform message response callbacks, does NOT send them, and
/// immediately collects the same.
///
TEST_F(EmbedderTest, CanCreateAndCollectCallbacks) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("platform_messages_response");
  context.AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([]() {}));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  auto callback = [](const uint8_t* data, size_t size,
                     void* user_data) -> void {};
  auto result = FlutterPlatformMessageCreateResponseHandle(
      engine.get(), callback, nullptr, &response_handle);
  ASSERT_EQ(result, kSuccess);
  ASSERT_NE(response_handle, nullptr);

  result = FlutterPlatformMessageReleaseResponseHandle(engine.get(),
                                                       response_handle);
  ASSERT_EQ(result, kSuccess);
}

//------------------------------------------------------------------------------
/// Sends platform messages to Dart code than simply echoes the contents of the
/// message back to the embedder. The embedder registers a native callback to
/// intercept that message.
///
TEST_F(EmbedderTest, PlatformMessagesCanReceiveResponse) {
  struct Captures {
    fml::AutoResetWaitableEvent latch;
    std::thread::id thread_id;
  };
  Captures captures;

  CreateNewThread()->PostTask([&]() {
    captures.thread_id = std::this_thread::get_id();
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("platform_messages_response");

    fml::AutoResetWaitableEvent ready;
    context.AddFfiNativeCallback(
        "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));

    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    static std::string kMessageData = "Hello from embedder.";

    FlutterPlatformMessageResponseHandle* response_handle = nullptr;
    auto callback = [](const uint8_t* data, size_t size,
                       void* user_data) -> void {
      ASSERT_EQ(size, kMessageData.size());
      ASSERT_EQ(strncmp(reinterpret_cast<const char*>(kMessageData.data()),
                        reinterpret_cast<const char*>(data), size),
                0);
      auto captures = reinterpret_cast<Captures*>(user_data);
      ASSERT_EQ(captures->thread_id, std::this_thread::get_id());
      captures->latch.Signal();
    };
    auto result = FlutterPlatformMessageCreateResponseHandle(
        engine.get(), callback, &captures, &response_handle);
    ASSERT_EQ(result, kSuccess);

    FlutterPlatformMessage message = {};
    message.struct_size = sizeof(FlutterPlatformMessage);
    message.channel = "test_channel";
    message.message = reinterpret_cast<const uint8_t*>(kMessageData.data());
    message.message_size = kMessageData.size();
    message.response_handle = response_handle;

    ready.Wait();
    result = FlutterEngineSendPlatformMessage(engine.get(), &message);
    ASSERT_EQ(result, kSuccess);

    result = FlutterPlatformMessageReleaseResponseHandle(engine.get(),
                                                         response_handle);
    ASSERT_EQ(result, kSuccess);
  });

  captures.latch.Wait();
}

//------------------------------------------------------------------------------
/// Tests that a platform message can be sent with no response handle. Instead
/// of the platform message integrity checked via a response handle, a native
/// callback with the response is invoked to assert integrity.
///
TEST_F(EmbedderTest, PlatformMessagesCanBeSentWithoutResponseHandles) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("platform_messages_no_response");

  const std::string message_data = "Hello but don't call me back.";

  fml::AutoResetWaitableEvent ready, message;
  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA(([&message, &message_data](Dart_Handle message_handle) {
        auto received_message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        ASSERT_EQ(received_message, message_data);
        message.Signal();
      })));

  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());
  ready.Wait();

  FlutterPlatformMessage platform_message = {};
  platform_message.struct_size = sizeof(FlutterPlatformMessage);
  platform_message.channel = "test_channel";
  platform_message.message =
      reinterpret_cast<const uint8_t*>(message_data.data());
  platform_message.message_size = message_data.size();
  platform_message.response_handle = nullptr;  // No response needed.

  auto result =
      FlutterEngineSendPlatformMessage(engine.get(), &platform_message);
  ASSERT_EQ(result, kSuccess);
  message.Wait();
}

//------------------------------------------------------------------------------
/// Tests that a null platform message can be sent.
///
TEST_F(EmbedderTest, NullPlatformMessagesCanBeSent) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("null_platform_messages");

  fml::AutoResetWaitableEvent ready, message;
  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA(([&message](Dart_Handle message_handle) {
        auto received_message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        ASSERT_EQ("true", received_message);
        message.Signal();
      })));

  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());
  ready.Wait();

  FlutterPlatformMessage platform_message = {};
  platform_message.struct_size = sizeof(FlutterPlatformMessage);
  platform_message.channel = "test_channel";
  platform_message.message = nullptr;
  platform_message.message_size = 0;
  platform_message.response_handle = nullptr;  // No response needed.

  auto result =
      FlutterEngineSendPlatformMessage(engine.get(), &platform_message);
  ASSERT_EQ(result, kSuccess);
  message.Wait();
}

//------------------------------------------------------------------------------
/// Tests that a null platform message cannot be send if the message_size
/// isn't equals to 0.
///
TEST_F(EmbedderTest, InvalidPlatformMessages) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());

  FlutterPlatformMessage platform_message = {};
  platform_message.struct_size = sizeof(FlutterPlatformMessage);
  platform_message.channel = "test_channel";
  platform_message.message = nullptr;
  platform_message.message_size = 1;
  platform_message.response_handle = nullptr;  // No response needed.

  auto result =
      FlutterEngineSendPlatformMessage(engine.get(), &platform_message);
  ASSERT_EQ(result, kInvalidArguments);
}

//------------------------------------------------------------------------------
/// Tests that setting a custom log callback works as expected and defaults to
/// using tag "flutter".
TEST_F(EmbedderTest, CanSetCustomLogMessageCallback) {
  fml::AutoResetWaitableEvent callback_latch;
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("custom_logger");
  builder.SetSurface(DlISize(1, 1));
  context.SetLogMessageCallback(
      [&callback_latch](const char* tag, const char* message) {
        EXPECT_EQ(std::string(tag), "flutter");
        EXPECT_EQ(std::string(message), "hello world");
        callback_latch.Signal();
      });
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  callback_latch.Wait();
}

//------------------------------------------------------------------------------
/// Tests that setting a custom log tag works.
TEST_F(EmbedderTest, CanSetCustomLogTag) {
  fml::AutoResetWaitableEvent callback_latch;
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("custom_logger");
  builder.SetSurface(DlISize(1, 1));
  builder.SetLogTag("butterfly");
  context.SetLogMessageCallback(
      [&callback_latch](const char* tag, const char* message) {
        EXPECT_EQ(std::string(tag), "butterfly");
        EXPECT_EQ(std::string(message), "hello world");
        callback_latch.Signal();
      });
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  callback_latch.Wait();
}

//------------------------------------------------------------------------------
/// Asserts behavior of FlutterProjectArgs::shutdown_dart_vm_when_done (which is
/// set to true by default in these unit-tests).
///
TEST_F(EmbedderTest, VMShutsDownWhenNoEnginesInProcess) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  const auto launch_count = DartVM::GetVMLaunchCount();

  {
    auto engine = builder.LaunchEngine();
    ASSERT_EQ(launch_count + 1u, DartVM::GetVMLaunchCount());
  }

  {
    auto engine = builder.LaunchEngine();
    ASSERT_EQ(launch_count + 2u, DartVM::GetVMLaunchCount());
  }
}

//------------------------------------------------------------------------------
///
TEST_F(EmbedderTest, DartEntrypointArgs) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.AddDartEntrypointArgument("foo");
  builder.AddDartEntrypointArgument("bar");
  builder.SetDartEntrypoint("dart_entrypoint_args");
  fml::AutoResetWaitableEvent callback_latch;
  std::vector<std::string> callback_args;
  auto nativeArgumentsCallback = [&callback_args,
                                  &callback_latch](Dart_Handle args) {
    callback_args =
        tonic::DartConverter<std::vector<std::string>>::FromDart(args);
    callback_latch.Signal();
  };
  context.AddFfiNativeCallback("NativeArgumentsCallback",
                               CREATE_FFI_LAMBDA(nativeArgumentsCallback));
  auto engine = builder.LaunchEngine();
  callback_latch.Wait();
  ASSERT_EQ(callback_args[0], "foo");
  ASSERT_EQ(callback_args[1], "bar");
}

//------------------------------------------------------------------------------
/// These snapshots may be materialized from symbols and the size field may not
/// be relevant. Since this information is redundant, engine launch should not
/// be gated on a non-zero buffer size.
///
TEST_F(EmbedderTest, VMAndIsolateSnapshotSizesAreRedundantInAOTMode) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // The fixture sets this up correctly. Intentionally mess up the args.
  builder.GetProjectArgs().vm_snapshot_data_size = 0;
  builder.GetProjectArgs().vm_snapshot_instructions_size = 0;
  builder.GetProjectArgs().isolate_snapshot_data_size = 0;
  builder.GetProjectArgs().isolate_snapshot_instructions_size = 0;

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanRenderImplicitView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("render_implicit_view");
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::AutoResetWaitableEvent latch;

  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(view_id, kFlutterImplicitViewId);
        latch.Signal();
      });

  auto engine = builder.LaunchEngine();

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 300;
  event.height = 200;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());
  latch.Wait();
}

TEST_F(EmbedderTest, CanRenderImplicitViewUsingPresentLayersCallback) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor(/* avoid_backing_store_cache = */ false,
                        /* use_present_layers_callback = */ true);
  builder.SetDartEntrypoint("render_implicit_view");
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::AutoResetWaitableEvent latch;

  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(view_id, kFlutterImplicitViewId);
        latch.Signal();
      });

  auto engine = builder.LaunchEngine();

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 300;
  event.height = 200;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());
  latch.Wait();
}

//------------------------------------------------------------------------------
/// Test the layer structure and pixels rendered when using a custom software
/// compositor.
///
// TODO(143940): Convert this test to use SkiaGold.
#if FML_OS_MACOSX && FML_ARCH_CPU_ARM64
TEST_F(EmbedderTest,
       DISABLED_CompositorMustBeAbleToRenderKnownSceneWithSoftwareCompositor) {
#else
TEST_F(EmbedderTest,
       CompositorMustBeAbleToRenderKnownSceneWithSoftwareCompositor) {
#endif  // FML_OS_MACOSX && FML_ARCH_CPU_ARM64

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_with_known_scene");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(5);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(layers_count, 5u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(0, 0, 800, 600),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[0], layer);
        }

        // Layer 1
        {
          FlutterPlatformView platform_view = *layers[1]->platform_view;
          platform_view.struct_size = sizeof(platform_view);
          platform_view.identifier = 1;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypePlatformView;
          layer.platform_view = &platform_view;
          layer.size = FlutterSizeMake(50.0, 150.0);
          layer.offset = FlutterPointMake(20.0, 20.0);

          ASSERT_EQ(*layers[1], layer);
        }

        // Layer 2
        {
          FlutterBackingStore backing_store = *layers[2]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(30, 30, 80, 180),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[2], layer);
        }

        // Layer 3
        {
          FlutterPlatformView platform_view = *layers[3]->platform_view;
          platform_view.struct_size = sizeof(platform_view);
          platform_view.identifier = 2;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypePlatformView;
          layer.platform_view = &platform_view;
          layer.size = FlutterSizeMake(50.0, 150.0);
          layer.offset = FlutterPointMake(40.0, 40.0);

          ASSERT_EQ(*layers[3], layer);
        }

        // Layer 4
        {
          FlutterBackingStore backing_store = *layers[4]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(50, 50, 100, 200),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[4], layer);
        }

        latch.CountDown();
      });

  context.GetCompositor().SetPlatformViewRendererCallback(
      [&](const FlutterLayer& layer, GrDirectContext*
          /* don't use because software compositor */) -> sk_sp<SkImage> {
        auto surface = CreateRenderSurface(
            layer, nullptr /* null because software compositor */);
        auto canvas = surface->getCanvas();
        FML_CHECK(canvas != nullptr);

        switch (layer.platform_view->identifier) {
          case 1: {
            SkPaint paint;
            // See dart test for total order.
            paint.setColor(SK_ColorGREEN);
            paint.setAlpha(127);
            const auto& rect =
                SkRect::MakeWH(layer.size.width, layer.size.height);
            canvas->drawRect(rect, paint);
            latch.CountDown();
          } break;
          case 2: {
            SkPaint paint;
            // See dart test for total order.
            paint.setColor(SK_ColorMAGENTA);
            paint.setAlpha(127);
            const auto& rect =
                SkRect::MakeWH(layer.size.width, layer.size.height);
            canvas->drawRect(rect, paint);
            latch.CountDown();
          } break;
          default:
            // Asked to render an unknown platform view.
            FML_CHECK(false)
                << "Test was asked to composite an unknown platform view.";
        }

        return surface->makeImageSnapshot();
      });

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.CountDown(); }));

  auto engine = builder.LaunchEngine();

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  latch.Wait();

  ASSERT_TRUE(ImageMatchesFixture("compositor_software.png", scene_image));

  // There should no present calls on the root surface.
  ASSERT_EQ(context.GetSurfacePresentCount(), 0u);
}

//------------------------------------------------------------------------------
/// Test the layer structure and pixels rendered when using a custom software
/// compositor, with a transparent overlay
///
TEST_F(EmbedderTest, NoLayerCreatedForTransparentOverlayOnTopOfPlatformLayer) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_transparent_overlay");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(4);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(layers_count, 2u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(0, 0, 800, 600),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[0], layer);
        }

        // Layer 1
        {
          FlutterPlatformView platform_view = *layers[1]->platform_view;
          platform_view.struct_size = sizeof(platform_view);
          platform_view.identifier = 1;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypePlatformView;
          layer.platform_view = &platform_view;
          layer.size = FlutterSizeMake(50.0, 150.0);
          layer.offset = FlutterPointMake(20.0, 20.0);

          ASSERT_EQ(*layers[1], layer);
        }

        latch.CountDown();
      });

  context.GetCompositor().SetPlatformViewRendererCallback(
      [&](const FlutterLayer& layer, GrDirectContext*
          /* don't use because software compositor */) -> sk_sp<SkImage> {
        auto surface = CreateRenderSurface(
            layer, nullptr /* null because software compositor */);
        auto canvas = surface->getCanvas();
        FML_CHECK(canvas != nullptr);

        switch (layer.platform_view->identifier) {
          case 1: {
            SkPaint paint;
            // See dart test for total order.
            paint.setColor(SK_ColorGREEN);
            paint.setAlpha(127);
            const auto& rect =
                SkRect::MakeWH(layer.size.width, layer.size.height);
            canvas->drawRect(rect, paint);
            latch.CountDown();
          } break;
          default:
            // Asked to render an unknown platform view.
            FML_CHECK(false)
                << "Test was asked to composite an unknown platform view.";
        }

        return surface->makeImageSnapshot();
      });

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.CountDown(); }));

  auto engine = builder.LaunchEngine();

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  latch.Wait();

  // TODO(https://github.com/flutter/flutter/issues/53784): enable this on all
  // platforms.
#if !defined(FML_OS_LINUX)
  GTEST_SKIP() << "Skipping golden tests on non-Linux OSes";
#endif  // FML_OS_LINUX
  ASSERT_TRUE(ImageMatchesFixture(
      "compositor_platform_layer_with_no_overlay.png", scene_image));

  // There should no present calls on the root surface.
  ASSERT_EQ(context.GetSurfacePresentCount(), 0u);
}

//------------------------------------------------------------------------------
/// Test the layer structure and pixels rendered when using a custom software
/// compositor, with a no overlay
///
TEST_F(EmbedderTest, NoLayerCreatedForNoOverlayOnTopOfPlatformLayer) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_no_overlay");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(4);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(layers_count, 2u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(0, 0, 800, 600),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[0], layer);
        }

        // Layer 1
        {
          FlutterPlatformView platform_view = *layers[1]->platform_view;
          platform_view.struct_size = sizeof(platform_view);
          platform_view.identifier = 1;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypePlatformView;
          layer.platform_view = &platform_view;
          layer.size = FlutterSizeMake(50.0, 150.0);
          layer.offset = FlutterPointMake(20.0, 20.0);

          ASSERT_EQ(*layers[1], layer);
        }

        latch.CountDown();
      });

  context.GetCompositor().SetPlatformViewRendererCallback(
      [&](const FlutterLayer& layer, GrDirectContext*
          /* don't use because software compositor */) -> sk_sp<SkImage> {
        auto surface = CreateRenderSurface(
            layer, nullptr /* null because software compositor */);
        auto canvas = surface->getCanvas();
        FML_CHECK(canvas != nullptr);

        switch (layer.platform_view->identifier) {
          case 1: {
            SkPaint paint;
            // See dart test for total order.
            paint.setColor(SK_ColorGREEN);
            paint.setAlpha(127);
            const auto& rect =
                SkRect::MakeWH(layer.size.width, layer.size.height);
            canvas->drawRect(rect, paint);
            latch.CountDown();
          } break;
          default:
            // Asked to render an unknown platform view.
            FML_CHECK(false)
                << "Test was asked to composite an unknown platform view.";
        }

        return surface->makeImageSnapshot();
      });

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.CountDown(); }));

  auto engine = builder.LaunchEngine();

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  latch.Wait();

  // TODO(https://github.com/flutter/flutter/issues/53784): enable this on all
  // platforms.
#if !defined(FML_OS_LINUX)
  GTEST_SKIP() << "Skipping golden tests on non-Linux OSes";
#endif  // FML_OS_LINUX
  ASSERT_TRUE(ImageMatchesFixture(
      "compositor_platform_layer_with_no_overlay.png", scene_image));

  // There should no present calls on the root surface.
  ASSERT_EQ(context.GetSurfacePresentCount(), 0u);
}

//------------------------------------------------------------------------------
/// Test that an engine can be initialized but not run.
///
TEST_F(EmbedderTest, CanCreateInitializedEngine) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());
  engine.reset();
}

//------------------------------------------------------------------------------
/// Test that an initialized engine can be run exactly once.
///
TEST_F(EmbedderTest, CanRunInitializedEngine) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
  // Cannot re-run an already running engine.
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kInvalidArguments);
  engine.reset();
}

//------------------------------------------------------------------------------
/// Test that an engine can be deinitialized.
///
TEST_F(EmbedderTest, CanDeinitializeAnEngine) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
  // Cannot re-run an already running engine.
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kInvalidArguments);
  ASSERT_EQ(FlutterEngineDeinitialize(engine.get()), kSuccess);
  // It is ok to deinitialize an engine multiple times.
  ASSERT_EQ(FlutterEngineDeinitialize(engine.get()), kSuccess);

  // Sending events to a deinitialized engine fails.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kInvalidArguments);
  engine.reset();
}

//------------------------------------------------------------------------------
/// Test that a view can be added to a running engine.
///
TEST_F(EmbedderTest, CanAddView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_all_view_ids");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  std::string message;
  context.AddFfiNativeCallback(
      "SignalNativeMessage", CREATE_FFI_LAMBDA([&](Dart_Handle message_handle) {
        message = tonic::DartConverter<std::string>::FromDart(message_handle);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo info = {};
  info.struct_size = sizeof(FlutterAddViewInfo);
  info.view_id = 123;
  info.view_metrics = &metrics;
  info.add_view_callback = [](const FlutterAddViewResult* result) {
    EXPECT_TRUE(result->added);
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ("View IDs: [0, 123]", message);
}

//------------------------------------------------------------------------------
/// Test that adding a view schedules a frame.
///
TEST_F(EmbedderTest, AddViewSchedulesFrame) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("add_view_schedules_frame");
  fml::AutoResetWaitableEvent latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.Signal(); }));

  fml::AutoResetWaitableEvent check_latch;
  context.AddFfiNativeCallback(
      "SignalNativeCount",
      CREATE_FFI_LAMBDA([&check_latch](int count) { check_latch.Signal(); }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the application to attach the listener.
  latch.Wait();

  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo info = {};
  info.struct_size = sizeof(FlutterAddViewInfo);
  info.view_id = 123;
  info.view_metrics = &metrics;
  info.add_view_callback = [](const FlutterAddViewResult* result) {
    EXPECT_TRUE(result->added);
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &info), kSuccess);

  check_latch.Wait();
}

//------------------------------------------------------------------------------
/// Test that a view that was added can be removed.
///
TEST_F(EmbedderTest, CanRemoveView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_all_view_ids");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  std::string message;
  context.AddFfiNativeCallback(
      "SignalNativeMessage", CREATE_FFI_LAMBDA([&](Dart_Handle message_handle) {
        message = tonic::DartConverter<std::string>::FromDart(message_handle);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  // Add view 123.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo add_info = {};
  add_info.struct_size = sizeof(FlutterAddViewInfo);
  add_info.view_id = 123;
  add_info.view_metrics = &metrics;
  add_info.add_view_callback = [](const FlutterAddViewResult* result) {
    ASSERT_TRUE(result->added);
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0, 123]");

  // Remove view 123.
  FlutterRemoveViewInfo remove_info = {};
  remove_info.struct_size = sizeof(FlutterAddViewInfo);
  remove_info.view_id = 123;
  remove_info.remove_view_callback = [](const FlutterRemoveViewResult* result) {
    EXPECT_TRUE(result->removed);
  };
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &remove_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0]");
}

// Regression test for:
// https://github.com/flutter/flutter/issues/164564
TEST_F(EmbedderTest, RemoveViewCallbackIsInvokedAfterRasterThreadIsDone) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  std::mutex engine_mutex;
  UniqueEngine engine;
  auto render_thread = CreateNewThread("custom_render_thread");
  EmbedderTestTaskRunner render_task_runner(
      render_thread, [&](FlutterTask task) {
        std::scoped_lock engine_lock(engine_mutex);
        if (engine.is_valid()) {
          ASSERT_EQ(FlutterEngineRunTask(engine.get(), &task), kSuccess);
        }
      });

  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("remove_view_callback_too_early");
  builder.SetRenderTaskRunner(
      &render_task_runner.GetFlutterTaskRunnerDescription());

  fml::AutoResetWaitableEvent ready_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  {
    std::scoped_lock lock(engine_mutex);
    engine = builder.InitializeEngine();
  }
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  fml::AutoResetWaitableEvent add_view_latch;
  // Add view 123.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo add_info = {};
  add_info.struct_size = sizeof(FlutterAddViewInfo);
  add_info.view_id = 123;
  add_info.view_metrics = &metrics;
  add_info.user_data = &add_view_latch;
  add_info.add_view_callback = [](const FlutterAddViewResult* result) {
    ASSERT_TRUE(result->added);
    auto add_view_latch =
        reinterpret_cast<fml::AutoResetWaitableEvent*>(result->user_data);
    add_view_latch->Signal();
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  add_view_latch.Wait();

  std::atomic_bool view_available = true;

  // Simulate pending rasterization task scheduled before view removal request
  // that accesses view resources.
  fml::AutoResetWaitableEvent raster_thread_latch;
  render_thread->PostTask([&] {
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    // View must be available.
    EXPECT_TRUE(view_available);
    raster_thread_latch.Signal();
  });

  fml::AutoResetWaitableEvent remove_view_latch;
  FlutterRemoveViewInfo remove_view_info = {};
  remove_view_info.struct_size = sizeof(FlutterRemoveViewInfo);
  remove_view_info.view_id = 123;
  remove_view_info.user_data = &remove_view_latch;
  remove_view_info.remove_view_callback =
      [](const FlutterRemoveViewResult* result) {
        ASSERT_TRUE(result->removed);
        auto remove_view_latch =
            reinterpret_cast<fml::AutoResetWaitableEvent*>(result->user_data);
        remove_view_latch->Signal();
      };

  // Remove the view and wait until the callback is called.
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &remove_view_info), kSuccess);
  remove_view_latch.Wait();

  // After FlutterEngineRemoveViewCallback is called it should be safe to
  // remove view - raster thread must not be accessing any view resources.
  view_available = false;
  raster_thread_latch.Wait();

  FlutterEngineDeinitialize(engine.get());
}

//------------------------------------------------------------------------------
/// The implicit view is a special view that the engine and framework assume
/// can *always* be rendered to. Test that this view cannot be removed.
///
TEST_F(EmbedderTest, CannotRemoveImplicitView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterRemoveViewInfo info = {};
  info.struct_size = sizeof(FlutterRemoveViewInfo);
  info.view_id = kFlutterImplicitViewId;
  info.remove_view_callback = [](const FlutterRemoveViewResult* result) {
    FAIL();
  };
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &info), kInvalidArguments);
}

//------------------------------------------------------------------------------
/// Test that a view cannot be added if its ID already exists.
///
TEST_F(EmbedderTest, CannotAddDuplicateViews) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_all_view_ids");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  std::string message;
  context.AddFfiNativeCallback(
      "SignalNativeMessage", CREATE_FFI_LAMBDA([&](Dart_Handle message_handle) {
        message = tonic::DartConverter<std::string>::FromDart(message_handle);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  // Add view 123.
  struct Captures {
    std::atomic<int> count = 0;
    fml::AutoResetWaitableEvent failure_latch;
  };
  Captures captures;

  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo add_info = {};
  add_info.struct_size = sizeof(FlutterAddViewInfo);
  add_info.view_id = 123;
  add_info.view_metrics = &metrics;
  add_info.user_data = &captures;
  add_info.add_view_callback = [](const FlutterAddViewResult* result) {
    auto captures = reinterpret_cast<Captures*>(result->user_data);

    int count = captures->count.fetch_add(1);

    if (count == 0) {
      ASSERT_TRUE(result->added);
    } else {
      EXPECT_FALSE(result->added);
      captures->failure_latch.Signal();
    }
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0, 123]");
  ASSERT_FALSE(captures.failure_latch.IsSignaledForTest());

  // Add view 123 a second time.
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  captures.failure_latch.Wait();
  ASSERT_EQ(captures.count, 2);
  ASSERT_FALSE(message_latch.IsSignaledForTest());
}

//------------------------------------------------------------------------------
/// Test that a removed view's ID can be reused to add a new view.
///
TEST_F(EmbedderTest, CanReuseViewIds) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_all_view_ids");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  std::string message;
  context.AddFfiNativeCallback(
      "SignalNativeMessage", CREATE_FFI_LAMBDA([&](Dart_Handle message_handle) {
        message = tonic::DartConverter<std::string>::FromDart(message_handle);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  // Add view 123.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 123;

  FlutterAddViewInfo add_info = {};
  add_info.struct_size = sizeof(FlutterAddViewInfo);
  add_info.view_id = 123;
  add_info.view_metrics = &metrics;
  add_info.add_view_callback = [](const FlutterAddViewResult* result) {
    ASSERT_TRUE(result->added);
  };
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0, 123]");

  // Remove view 123.
  FlutterRemoveViewInfo remove_info = {};
  remove_info.struct_size = sizeof(FlutterAddViewInfo);
  remove_info.view_id = 123;
  remove_info.remove_view_callback = [](const FlutterRemoveViewResult* result) {
    ASSERT_TRUE(result->removed);
  };
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &remove_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0]");

  // Re-add view 123.
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_info), kSuccess);
  message_latch.Wait();
  ASSERT_EQ(message, "View IDs: [0, 123]");
}

//------------------------------------------------------------------------------
/// Test that attempting to remove a view that does not exist fails as expected.
///
TEST_F(EmbedderTest, CannotRemoveUnknownView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  fml::AutoResetWaitableEvent latch;
  FlutterRemoveViewInfo info = {};
  info.struct_size = sizeof(FlutterRemoveViewInfo);
  info.view_id = 123;
  info.user_data = &latch;
  info.remove_view_callback = [](const FlutterRemoveViewResult* result) {
    EXPECT_FALSE(result->removed);
    reinterpret_cast<fml::AutoResetWaitableEvent*>(result->user_data)->Signal();
  };
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &info), kSuccess);
  latch.Wait();
}

//------------------------------------------------------------------------------
/// View operations - adding, removing, sending window metrics - must execute in
/// order even though they are asynchronous. This is necessary to ensure the
/// embedder's and engine's states remain synchronized.
///
TEST_F(EmbedderTest, ViewOperationsOrdered) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_all_view_ids");

  fml::AutoResetWaitableEvent ready_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  std::atomic<int> message_count = 0;
  context.AddFfiNativeCallback(
      "SignalNativeMessage", CREATE_FFI_LAMBDA([&](Dart_Handle message_handle) {
        message_count.fetch_add(1);
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  // Enqueue multiple view operations at once:
  //
  // 1. Add view 123 - This must succeed.
  // 2. Add duplicate view 123 - This must fail asynchronously.
  // 3. Add second view 456 - This must succeed.
  // 4. Remove second view 456 - This must succeed.
  //
  // The engine must execute view operations asynchronously in serial order.
  // If step 2 succeeds instead of step 1, this indicates the engine did not
  // execute the view operations in the correct order. If step 4 fails,
  // this indicates the engine did not wait until the add second view completed.
  FlutterWindowMetricsEvent metrics123 = {};
  metrics123.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics123.width = 800;
  metrics123.height = 600;
  metrics123.pixel_ratio = 1.0;
  metrics123.view_id = 123;

  FlutterWindowMetricsEvent metrics456 = {};
  metrics456.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics456.width = 800;
  metrics456.height = 600;
  metrics456.pixel_ratio = 1.0;
  metrics456.view_id = 456;

  struct Captures {
    fml::AutoResetWaitableEvent add_first_view;
    fml::AutoResetWaitableEvent add_duplicate_view;
    fml::AutoResetWaitableEvent add_second_view;
    fml::AutoResetWaitableEvent remove_second_view;
  };
  Captures captures;

  // Add view 123.
  FlutterAddViewInfo add_view_info = {};
  add_view_info.struct_size = sizeof(FlutterAddViewInfo);
  add_view_info.view_id = 123;
  add_view_info.view_metrics = &metrics123;
  add_view_info.user_data = &captures;
  add_view_info.add_view_callback = [](const FlutterAddViewResult* result) {
    auto captures = reinterpret_cast<Captures*>(result->user_data);

    ASSERT_TRUE(result->added);
    ASSERT_FALSE(captures->add_first_view.IsSignaledForTest());
    ASSERT_FALSE(captures->add_duplicate_view.IsSignaledForTest());
    ASSERT_FALSE(captures->add_second_view.IsSignaledForTest());
    ASSERT_FALSE(captures->remove_second_view.IsSignaledForTest());

    captures->add_first_view.Signal();
  };

  // Add duplicate view 123.
  FlutterAddViewInfo add_duplicate_view_info = {};
  add_duplicate_view_info.struct_size = sizeof(FlutterAddViewInfo);
  add_duplicate_view_info.view_id = 123;
  add_duplicate_view_info.view_metrics = &metrics123;
  add_duplicate_view_info.user_data = &captures;
  add_duplicate_view_info.add_view_callback =
      [](const FlutterAddViewResult* result) {
        auto captures = reinterpret_cast<Captures*>(result->user_data);

        ASSERT_FALSE(result->added);
        ASSERT_TRUE(captures->add_first_view.IsSignaledForTest());
        ASSERT_FALSE(captures->add_duplicate_view.IsSignaledForTest());
        ASSERT_FALSE(captures->add_second_view.IsSignaledForTest());
        ASSERT_FALSE(captures->remove_second_view.IsSignaledForTest());

        captures->add_duplicate_view.Signal();
      };

  // Add view 456.
  FlutterAddViewInfo add_second_view_info = {};
  add_second_view_info.struct_size = sizeof(FlutterAddViewInfo);
  add_second_view_info.view_id = 456;
  add_second_view_info.view_metrics = &metrics456;
  add_second_view_info.user_data = &captures;
  add_second_view_info.add_view_callback =
      [](const FlutterAddViewResult* result) {
        auto captures = reinterpret_cast<Captures*>(result->user_data);

        ASSERT_TRUE(result->added);
        ASSERT_TRUE(captures->add_first_view.IsSignaledForTest());
        ASSERT_TRUE(captures->add_duplicate_view.IsSignaledForTest());
        ASSERT_FALSE(captures->add_second_view.IsSignaledForTest());
        ASSERT_FALSE(captures->remove_second_view.IsSignaledForTest());

        captures->add_second_view.Signal();
      };

  // Remove view 456.
  FlutterRemoveViewInfo remove_second_view_info = {};
  remove_second_view_info.struct_size = sizeof(FlutterRemoveViewInfo);
  remove_second_view_info.view_id = 456;
  remove_second_view_info.user_data = &captures;
  remove_second_view_info.remove_view_callback =
      [](const FlutterRemoveViewResult* result) {
        auto captures = reinterpret_cast<Captures*>(result->user_data);

        ASSERT_TRUE(result->removed);
        ASSERT_TRUE(captures->add_first_view.IsSignaledForTest());
        ASSERT_TRUE(captures->add_duplicate_view.IsSignaledForTest());
        ASSERT_TRUE(captures->add_second_view.IsSignaledForTest());
        ASSERT_FALSE(captures->remove_second_view.IsSignaledForTest());

        captures->remove_second_view.Signal();
      };

  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_view_info), kSuccess);
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_duplicate_view_info),
            kSuccess);
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_second_view_info),
            kSuccess);
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &remove_second_view_info),
            kSuccess);
  captures.remove_second_view.Wait();
  captures.add_second_view.Wait();
  captures.add_duplicate_view.Wait();
  captures.add_first_view.Wait();
  ASSERT_EQ(message_count, 3);
}

//------------------------------------------------------------------------------
/// Test the engine can present to multiple views.
///
TEST_F(EmbedderTest, CanRenderMultipleViews) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetCompositor();
  builder.SetDartEntrypoint("render_all_views");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::AutoResetWaitableEvent latch0, latch123;
  context.GetCompositor().SetPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        switch (view_id) {
          case 0:
            latch0.Signal();
            break;
          case 123:
            latch123.Signal();
            break;
          default:
            FML_UNREACHABLE();
        }
      },
      /* one_shot= */ false);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Give the implicit view a non-zero size so that it renders something.
  FlutterWindowMetricsEvent metrics0 = {};
  metrics0.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics0.width = 800;
  metrics0.height = 600;
  metrics0.pixel_ratio = 1.0;
  metrics0.view_id = 0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &metrics0),
            kSuccess);

  // Add view 123.
  FlutterWindowMetricsEvent metrics123 = {};
  metrics123.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics123.width = 800;
  metrics123.height = 600;
  metrics123.pixel_ratio = 1.0;
  metrics123.view_id = 123;

  FlutterAddViewInfo add_view_info = {};
  add_view_info.struct_size = sizeof(FlutterAddViewInfo);
  add_view_info.view_id = 123;
  add_view_info.view_metrics = &metrics123;
  add_view_info.add_view_callback = [](const FlutterAddViewResult* result) {
    ASSERT_TRUE(result->added);
  };

  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_view_info), kSuccess);

  latch0.Wait();
  latch123.Wait();
}

bool operator==(const FlutterViewFocusChangeRequest& lhs,
                const FlutterViewFocusChangeRequest& rhs) {
  return lhs.view_id == rhs.view_id && lhs.state == rhs.state &&
         lhs.direction == rhs.direction;
}

TEST_F(EmbedderTest, SendsViewFocusChangeRequest) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  auto platform_task_runner = CreateNewThread("test_platform_thread");
  UniqueEngine engine;
  static std::mutex engine_mutex;
  EmbedderTestTaskRunner test_platform_task_runner(
      platform_task_runner, [&](FlutterTask task) {
        std::scoped_lock lock(engine_mutex);
        if (!engine.is_valid()) {
          return;
        }
        FlutterEngineRunTask(engine.get(), &task);
      });
  fml::CountDownLatch latch(3);
  std::vector<FlutterViewFocusChangeRequest> received_requests;
  platform_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("testSendViewFocusChangeRequest");
    const auto platform_task_runner_description =
        test_platform_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetPlatformTaskRunner(&platform_task_runner_description);
    builder.SetViewFocusChangeRequestCallback(
        [&](const FlutterViewFocusChangeRequest* request) {
          EXPECT_TRUE(platform_task_runner->RunsTasksOnCurrentThread());
          received_requests.push_back(*request);
          latch.CountDown();
        });
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });
  latch.Wait();

  std::vector<FlutterViewFocusChangeRequest> expected_requests{
      {.view_id = 1, .state = kUnfocused, .direction = kUndefined},
      {.view_id = 2, .state = kFocused, .direction = kForward},
      {.view_id = 3, .state = kFocused, .direction = kBackward},
  };

  ASSERT_EQ(received_requests.size(), expected_requests.size());
  for (size_t i = 0; i < received_requests.size(); ++i) {
    ASSERT_TRUE(received_requests[i] == expected_requests[i]);
  }

  fml::AutoResetWaitableEvent kill_latch;
  platform_task_runner->PostTask(fml::MakeCopyable([&]() mutable {
    std::scoped_lock lock(engine_mutex);
    engine.reset();

    // There may still be pending tasks on the platform thread that were queued
    // by the test_task_runner.  Signal the latch after these tasks have been
    // consumed.
    platform_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  }));
  kill_latch.Wait();
}

TEST_F(EmbedderTest, ExtendedWindowMetricsReachTheFrameworkIntact) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("reportViewportMetricsDetails");

  fml::AutoResetWaitableEvent latch;
  std::string last_report;

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.Signal(); }));
  context.AddFfiNativeCallback(
      "NotifyStringValue", CREATE_FFI_LAMBDA([&](Dart_Handle value) {
        last_report = tonic::DartConverter<std::string>::FromDart(value);
        latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait until the metrics handler is attached.
  latch.Wait();
  latch.Reset();

  // A state the engine does not know about, to prove it degrades rather than
  // being rejected at the boundary.
  const double kBounds[4] = {0.0, 0.0, 10.0, 600.0};
  const int32_t kType[1] = {kFlutterDisplayFeatureTypeHinge};
  const int32_t kState[1] = {kFlutterDisplayFeatureStatePostureHalfOpened + 1};

  // Deliberately zero-initialized and then only partially populated, which is
  // exactly what the header tells embedders to do.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.has_extended_metrics = true;
  event.physical_padding_left = 4.0;
  event.physical_padding_top = 8.0;
  event.display_features_count = 1;
  event.display_features_bounds = kBounds;
  event.display_features_type = kType;
  event.display_features_state = kState;

  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();

  // `physical_touch_slop` was left at zero by the zero-initialization. The
  // framework must see the platform default (null), not a touch slop of zero,
  // which would turn every touch into an immediate drag.
  EXPECT_EQ(last_report,
            "touchSlop=null padding=4.0,8.0 features=1 "
            "DisplayFeatureType.hinge/DisplayFeatureState.unknown");
}

TEST_F(EmbedderTest, CanSendViewFocusEvent) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("testSendViewFocusEvent");

  fml::AutoResetWaitableEvent latch;
  std::string last_event;

  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.Signal(); }));
  context.AddFfiNativeCallback(
      "NotifyStringValue", CREATE_FFI_LAMBDA([&](Dart_Handle value) {
        const auto message_from_dart =
            tonic::DartConverter<std::string>::FromDart(value);
        last_event = message_from_dart;
        latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait until the focus change handler is attached.
  latch.Wait();
  latch.Reset();

  FlutterViewFocusEvent event1{
      .struct_size = sizeof(FlutterViewFocusEvent),
      .view_id = 1,
      .state = kFocused,
      .direction = kUndefined,
  };
  FlutterEngineResult result =
      FlutterEngineSendViewFocusEvent(engine.get(), &event1);
  ASSERT_EQ(result, kSuccess);
  latch.Wait();
  ASSERT_EQ(last_event,
            "1 ViewFocusState.focused ViewFocusDirection.undefined");

  FlutterViewFocusEvent event2{
      .struct_size = sizeof(FlutterViewFocusEvent),
      .view_id = 2,
      .state = kUnfocused,
      .direction = kBackward,
  };
  latch.Reset();
  result = FlutterEngineSendViewFocusEvent(engine.get(), &event2);
  ASSERT_EQ(result, kSuccess);
  latch.Wait();
  ASSERT_EQ(last_event,
            "2 ViewFocusState.unfocused ViewFocusDirection.backward");
}

//------------------------------------------------------------------------------
/// Test that the backing store is created with the correct view ID, is used
/// for the correct view, and is cached according to their views.
///
/// The test involves two frames:
/// 1. The first frame renders the implicit view and the second view.
/// 2. The second frame renders the implicit view and the third view.
///
/// The test verifies that:
/// - Each backing store is created with a valid view ID.
/// - Each backing store is presented for the view that it was created for.
/// - Both frames render the expected sets of views.
/// - By the end of frame 1, only 2 backing stores were created.
/// - By the end of frame 2, only 3 backing stores were created. This ensures
/// that the backing store for the 2nd view is not reused for the 3rd view.
TEST_F(EmbedderTest, BackingStoresCorrespondToTheirViews) {
  constexpr FlutterViewId kSecondViewId = 123;
  constexpr FlutterViewId kThirdViewId = 456;
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("render_all_views");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();

  EmbedderTestBackingStoreProducerSoftware producer(
      context.GetCompositor().GetGrContext(),
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  // The variables needed by the callbacks of the compositor.
  struct CompositorUserData {
    EmbedderTestBackingStoreProducer* producer;
    // Each latch is signaled when its corresponding view is presented.
    fml::AutoResetWaitableEvent latch_implicit;
    fml::AutoResetWaitableEvent latch_second;
    fml::AutoResetWaitableEvent latch_third;
    // Whether the respective view should be rendered in the frame.
    bool second_expected;
    bool third_expected;
    // The total number of backing stores created to verify caching.
    int backing_stores_created;
  };
  CompositorUserData compositor_user_data{
      .producer = &producer,
      .backing_stores_created = 0,
  };

  builder.GetCompositor() = FlutterCompositor{
      .struct_size = sizeof(FlutterCompositor),
      .user_data = reinterpret_cast<void*>(&compositor_user_data),
      .create_backing_store_callback =
          [](const FlutterBackingStoreConfig* config,
             FlutterBackingStore* backing_store_out, void* user_data) {
            // Verify that the backing store comes with the correct view ID.
            EXPECT_TRUE(config->view_id == 0 ||
                        config->view_id == kSecondViewId ||
                        config->view_id == kThirdViewId);
            auto compositor_user_data =
                reinterpret_cast<CompositorUserData*>(user_data);
            compositor_user_data->backing_stores_created += 1;
            bool result = compositor_user_data->producer->Create(
                config, backing_store_out);
            // The created backing store has a user_data that records the view
            // that the store is created for.
            backing_store_out->user_data =
                reinterpret_cast<void*>(config->view_id);
            return result;
          },
      .collect_backing_store_callback = [](const FlutterBackingStore* renderer,
                                           void* user_data) { return true; },
      .present_layers_callback = nullptr,
      .avoid_backing_store_cache = false,
      .present_view_callback =
          [](const FlutterPresentViewInfo* info) {
            EXPECT_EQ(info->layers_count, 1u);
            // Verify that the given layer's backing store has the same view ID
            // as the target view.
            int64_t store_view_id = reinterpret_cast<int64_t>(
                info->layers[0]->backing_store->user_data);
            EXPECT_EQ(store_view_id, info->view_id);
            auto compositor_user_data =
                reinterpret_cast<CompositorUserData*>(info->user_data);
            // Verify that the respective views are rendered.
            switch (info->view_id) {
              case 0:
                compositor_user_data->latch_implicit.Signal();
                break;
              case kSecondViewId:
                EXPECT_TRUE(compositor_user_data->second_expected);
                compositor_user_data->latch_second.Signal();
                break;
              case kThirdViewId:
                EXPECT_TRUE(compositor_user_data->third_expected);
                compositor_user_data->latch_third.Signal();
                break;
              default:
                FML_UNREACHABLE();
            }
            return true;
          },
  };

  compositor_user_data.second_expected = true;
  compositor_user_data.third_expected = false;

  /*=== First frame ===*/

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Give the implicit view a non-zero size so that it renders something.
  FlutterWindowMetricsEvent metrics_implicit = {
      .struct_size = sizeof(FlutterWindowMetricsEvent),
      .width = 800,
      .height = 600,
      .pixel_ratio = 1.0,
      .view_id = 0,
  };
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &metrics_implicit),
      kSuccess);

  // Add the second view.
  FlutterWindowMetricsEvent metrics_add = {
      .struct_size = sizeof(FlutterWindowMetricsEvent),
      .width = 800,
      .height = 600,
      .pixel_ratio = 1.0,
      .view_id = kSecondViewId,
  };

  FlutterAddViewInfo add_view_info = {};
  add_view_info.struct_size = sizeof(FlutterAddViewInfo);
  add_view_info.view_id = kSecondViewId;
  add_view_info.view_metrics = &metrics_add;
  add_view_info.add_view_callback = [](const FlutterAddViewResult* result) {
    ASSERT_TRUE(result->added);
  };

  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_view_info), kSuccess);

  compositor_user_data.latch_implicit.Wait();
  compositor_user_data.latch_second.Wait();

  /*=== Second frame ===*/

  compositor_user_data.second_expected = false;
  compositor_user_data.third_expected = true;
  EXPECT_EQ(compositor_user_data.backing_stores_created, 2);

  // Remove the second view
  FlutterRemoveViewInfo remove_view_info = {};
  remove_view_info.struct_size = sizeof(FlutterRemoveViewInfo);
  remove_view_info.view_id = kSecondViewId;
  remove_view_info.remove_view_callback =
      [](const FlutterRemoveViewResult* result) {
        ASSERT_TRUE(result->removed);
      };
  ASSERT_EQ(FlutterEngineRemoveView(engine.get(), &remove_view_info), kSuccess);

  // Add the third view.
  add_view_info.view_id = kThirdViewId;
  metrics_add.view_id = kThirdViewId;
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &add_view_info), kSuccess);
  // Adding the view should have scheduled a frame.

  compositor_user_data.latch_implicit.Wait();
  compositor_user_data.latch_third.Wait();
  EXPECT_EQ(compositor_user_data.backing_stores_created, 3);
}

TEST_F(EmbedderTest, CanUpdateLocales) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("can_receive_locale_updates");
  fml::AutoResetWaitableEvent latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.Signal(); }));

  fml::AutoResetWaitableEvent check_latch;
  context.AddFfiNativeCallback("SignalNativeCount",
                               CREATE_FFI_LAMBDA([&check_latch](int count) {
                                 ASSERT_EQ(count, 2);
                                 check_latch.Signal();
                               }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the application to attach the listener.
  latch.Wait();

  FlutterLocale locale1 = {};
  locale1.struct_size = sizeof(locale1);
  locale1.language_code = "";  // invalid
  locale1.country_code = "US";
  locale1.script_code = "";
  locale1.variant_code = nullptr;

  FlutterLocale locale2 = {};
  locale2.struct_size = sizeof(locale2);
  locale2.language_code = "zh";
  locale2.country_code = "CN";
  locale2.script_code = "Hans";
  locale2.variant_code = nullptr;

  std::vector<const FlutterLocale*> locales;
  locales.push_back(&locale1);
  locales.push_back(&locale2);

  ASSERT_EQ(
      FlutterEngineUpdateLocales(engine.get(), locales.data(), locales.size()),
      kInvalidArguments);

  // Fix the invalid code.
  locale1.language_code = "en";

  ASSERT_EQ(
      FlutterEngineUpdateLocales(engine.get(), locales.data(), locales.size()),
      kSuccess);

  check_latch.Wait();
}

TEST_F(EmbedderTest, LocalizationCallbacksCalled) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();

  flutter::Shell& shell = ToEmbedderEngine(engine.get())->GetShell();
  std::vector<std::string> supported_locales;
  supported_locales.push_back("es");
  supported_locales.push_back("MX");
  supported_locales.push_back("");
  auto result = shell.GetPlatformView()->ComputePlatformResolvedLocales(
      supported_locales);

  ASSERT_EQ((*result).size(), supported_locales.size());  // 3
  ASSERT_EQ((*result)[0], supported_locales[0]);
  ASSERT_EQ((*result)[1], supported_locales[1]);
  ASSERT_EQ((*result)[2], supported_locales[2]);

  engine.reset();
}

TEST_F(EmbedderTest, CanQueryDartAOTMode) {
  ASSERT_EQ(FlutterEngineRunsAOTCompiledDartCode(),
            flutter::DartVM::IsRunningPrecompiledCode());
}

TEST_F(EmbedderTest, VerifyB143464703WithSoftwareBackend) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1024, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("verify_b143464703");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  // setup the screenshot promise.
  auto rendered_scene = context.GetNextSceneImage();

  fml::CountDownLatch latch(1);
  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        ASSERT_EQ(layers_count, 2u);

        // Layer 0 (Root)
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;

          FlutterRect paint_region_rects[] = {
              FlutterRectMakeLTRB(0, 0, 1024, 600),
          };
          FlutterRegion paint_region = {
              .struct_size = sizeof(FlutterRegion),
              .rects_count = 1,
              .rects = paint_region_rects,
          };
          FlutterBackingStorePresentInfo present_info = {
              .struct_size = sizeof(FlutterBackingStorePresentInfo),
              .paint_region = &paint_region,
          };

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(1024.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);
          layer.backing_store_present_info = &present_info;

          ASSERT_EQ(*layers[0], layer);
        }

        // Layer 1
        {
          FlutterPlatformView platform_view = *layers[1]->platform_view;
          platform_view.struct_size = sizeof(platform_view);
          platform_view.identifier = 42;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypePlatformView;
          layer.platform_view = &platform_view;
          layer.size = FlutterSizeMake(1024.0, 540.0);
          layer.offset = FlutterPointMake(135.0, 60.0);

          ASSERT_EQ(*layers[1], layer);
        }

        latch.CountDown();
      });

  context.GetCompositor().SetPlatformViewRendererCallback(
      [](const FlutterLayer& layer,
         GrDirectContext* context) -> sk_sp<SkImage> {
        auto surface = CreateRenderSurface(
            layer, nullptr /* null because software compositor */);
        auto canvas = surface->getCanvas();
        FML_CHECK(canvas != nullptr);

        switch (layer.platform_view->identifier) {
          case 42: {
            SkPaint paint;
            // See dart test for total order.
            paint.setColor(SK_ColorGREEN);
            paint.setAlpha(127);
            const auto& rect =
                SkRect::MakeWH(layer.size.width, layer.size.height);
            canvas->drawRect(rect, paint);
          } break;
          default:
            // Asked to render an unknown platform view.
            FML_CHECK(false)
                << "Test was asked to composite an unknown platform view.";
        }

        return surface->makeImageSnapshot();
      });

  auto engine = builder.LaunchEngine();

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 1024;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  // wait for scene to be rendered.
  latch.Wait();

  // TODO(https://github.com/flutter/flutter/issues/53784): enable this on all
  // platforms.
#if !defined(FML_OS_LINUX)
  GTEST_SKIP() << "Skipping golden tests on non-Linux OSes";
#endif  // FML_OS_LINUX
  ASSERT_TRUE(
      ImageMatchesFixture("verifyb143464703_soft_noxform.png", rendered_scene));
}

TEST_F(EmbedderTest, CanSendLowMemoryNotification) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());

  // TODO(chinmaygarde): The shell ought to have a mechanism for notification
  // dispatch that engine subsystems can register handlers to. This would allow
  // the raster cache and the secondary context caches to respond to
  // notifications. Once that is in place, this test can be updated to actually
  // ensure that the dispatched message is visible to engine subsystems.
  ASSERT_EQ(FlutterEngineNotifyLowMemoryWarning(engine.get()), kSuccess);
}

TEST_F(EmbedderTest, CanPostTaskToAllNativeThreads) {
  UniqueEngine engine;
  size_t worker_count = 0;
  fml::AutoResetWaitableEvent sync_latch;

  // One of the threads that the callback will be posted to is the platform
  // thread. So we cannot wait for assertions to complete on the platform
  // thread. Create a new thread to manage the engine instance and wait for
  // assertions on the test thread.
  auto platform_task_runner = CreateNewThread("platform_thread");

  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));

    engine = builder.LaunchEngine();

    ASSERT_TRUE(engine.is_valid());

    worker_count = ToEmbedderEngine(engine.get())
                       ->GetShell()
                       .GetDartVM()
                       ->GetConcurrentMessageLoop()
                       ->GetWorkerCount();

    sync_latch.Signal();
  });

  sync_latch.Wait();

  const auto engine_threads_count = worker_count + 4u;

  struct Captures {
    // Waits the adequate number of callbacks to fire.
    fml::CountDownLatch latch;

    // This class will be accessed from multiple threads concurrently to track
    // thread specific information that is later checked. All updates to fields
    // in this struct must be made with this mutex acquired.

    std::mutex captures_mutex;
    // Ensures that the expect number of distinct threads were serviced.
    std::set<std::thread::id> thread_ids;

    size_t platform_threads_count = 0;
    size_t render_threads_count = 0;
    size_t ui_threads_count = 0;
    size_t worker_threads_count = 0;

    explicit Captures(size_t count) : latch(count) {}
  };

  Captures captures(engine_threads_count);

  platform_task_runner->PostTask([&]() {
    ASSERT_EQ(FlutterEnginePostCallbackOnAllNativeThreads(
                  engine.get(),
                  [](FlutterNativeThreadType type, void* baton) {
                    auto captures = reinterpret_cast<Captures*>(baton);
                    {
                      std::scoped_lock lock(captures->captures_mutex);
                      switch (type) {
                        case kFlutterNativeThreadTypeRender:
                          captures->render_threads_count++;
                          break;
                        case kFlutterNativeThreadTypeWorker:
                          captures->worker_threads_count++;
                          break;
                        case kFlutterNativeThreadTypeUI:
                          captures->ui_threads_count++;
                          break;
                        case kFlutterNativeThreadTypePlatform:
                          captures->platform_threads_count++;
                          break;
                      }
                      captures->thread_ids.insert(std::this_thread::get_id());
                    }
                    captures->latch.CountDown();
                  },
                  &captures),
              kSuccess);
  });

  captures.latch.Wait();
  ASSERT_EQ(captures.thread_ids.size(), engine_threads_count);
  ASSERT_EQ(captures.platform_threads_count, 1u);
  ASSERT_EQ(captures.render_threads_count, 1u);
  ASSERT_EQ(captures.ui_threads_count, 1u);
  ASSERT_EQ(captures.worker_threads_count, worker_count + 1u /* for IO */);
  EXPECT_GE(captures.worker_threads_count - 1, 2u);
  EXPECT_LE(captures.worker_threads_count - 1, 4u);

  platform_task_runner->PostTask([&]() {
    engine.reset();
    sync_latch.Signal();
  });
  sync_latch.Wait();

  // The engine should have already been destroyed on the platform task runner.
  ASSERT_FALSE(engine.is_valid());
}

TEST_F(EmbedderTest, InvalidAOTDataSourcesMustReturnError) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }
  FlutterEngineAOTDataSource data_in = {};
  FlutterEngineAOTData data_out = nullptr;

  // Null source specified.
  ASSERT_EQ(FlutterEngineCreateAOTData(nullptr, &data_out), kInvalidArguments);
  ASSERT_EQ(data_out, nullptr);

  // Null data_out specified.
  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, nullptr), kInvalidArguments);

  // Invalid FlutterEngineAOTDataSourceType type specified.
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  data_in.type = static_cast<FlutterEngineAOTDataSourceType>(-1);
  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, &data_out), kInvalidArguments);
  ASSERT_EQ(data_out, nullptr);

  // Invalid ELF path specified.
  data_in.type = kFlutterEngineAOTDataSourceTypeElfPath;
  data_in.elf_path = nullptr;
  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, &data_out), kInvalidArguments);
  ASSERT_EQ(data_in.type, kFlutterEngineAOTDataSourceTypeElfPath);
  ASSERT_EQ(data_in.elf_path, nullptr);
  ASSERT_EQ(data_out, nullptr);

  // Invalid ELF path specified.
  data_in.elf_path = "";
  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, &data_out), kInvalidArguments);
  ASSERT_EQ(data_in.type, kFlutterEngineAOTDataSourceTypeElfPath);
  ASSERT_EQ(data_in.elf_path, "");
  ASSERT_EQ(data_out, nullptr);

  // Could not find VM snapshot data.
  data_in.elf_path = "/bin/true";
  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, &data_out), kInvalidArguments);
  ASSERT_EQ(data_in.type, kFlutterEngineAOTDataSourceTypeElfPath);
  ASSERT_EQ(data_in.elf_path, "/bin/true");
  ASSERT_EQ(data_out, nullptr);
}

TEST_F(EmbedderTest, MustNotRunWithMultipleAOTSources) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(
      context,
      EmbedderConfigBuilder::InitializationPreference::kMultiAOTInitialize);

  builder.SetSurface(DlISize(1, 1));

  auto engine = builder.LaunchEngine();
  ASSERT_FALSE(engine.is_valid());
}

TEST_F(EmbedderTest, CanCreateAndCollectAValidElfSource) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }
  FlutterEngineAOTDataSource data_in = {};
  FlutterEngineAOTData data_out = nullptr;

  // Collecting a null object should be allowed
  ASSERT_EQ(FlutterEngineCollectAOTData(data_out), kSuccess);

  const auto elf_path =
      fml::paths::JoinPaths({GetFixturesPath(), kDefaultAOTAppELFFileName});

  data_in.type = kFlutterEngineAOTDataSourceTypeElfPath;
  data_in.elf_path = elf_path.c_str();

  ASSERT_EQ(FlutterEngineCreateAOTData(&data_in, &data_out), kSuccess);
  ASSERT_EQ(data_in.type, kFlutterEngineAOTDataSourceTypeElfPath);
  ASSERT_EQ(data_in.elf_path, elf_path.c_str());
  ASSERT_NE(data_out, nullptr);

  ASSERT_EQ(FlutterEngineCollectAOTData(data_out), kSuccess);
}

TEST_F(EmbedderTest, CanLaunchAndShutdownWithAValidElfSource) {
  if (!DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });

  EmbedderConfigBuilder builder(
      context,
      EmbedderConfigBuilder::InitializationPreference::kAOTDataInitialize);

  builder.SetSurface(DlISize(1, 1));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
}

#if defined(__clang_analyzer__)
#define TEST_VM_SNAPSHOT_DATA "vm_data"
#define TEST_VM_SNAPSHOT_INSTRUCTIONS "vm_instructions"
#define TEST_ISOLATE_SNAPSHOT_DATA "isolate_data"
#define TEST_ISOLATE_SNAPSHOT_INSTRUCTIONS "isolate_instructions"
#endif

//------------------------------------------------------------------------------
/// PopulateJITSnapshotMappingCallbacks should successfully change the callbacks
/// of the snapshots in the engine's settings when JIT snapshots are explicitly
/// defined.
///
TEST_F(EmbedderTest, CanSuccessfullyPopulateSpecificJITSnapshotCallbacks) {
// TODO(#107263): Inconsistent snapshot paths in the Linux Fuchsia FEMU test.
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Inconsistent paths in Fuchsia.";
#else

  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // Construct the location of valid JIT snapshots.
  const std::string src_path = GetSourcePath();
  const std::string vm_snapshot_data =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_DATA});
  const std::string vm_snapshot_instructions =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_INSTRUCTIONS});
  const std::string isolate_snapshot_data =
      fml::paths::JoinPaths({src_path, TEST_ISOLATE_SNAPSHOT_DATA});
  const std::string isolate_snapshot_instructions =
      fml::paths::JoinPaths({src_path, TEST_ISOLATE_SNAPSHOT_INSTRUCTIONS});

  // Explicitly define the locations of the JIT snapshots
  builder.GetProjectArgs().vm_snapshot_data =
      reinterpret_cast<const uint8_t*>(vm_snapshot_data.c_str());
  builder.GetProjectArgs().vm_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(vm_snapshot_instructions.c_str());
  builder.GetProjectArgs().isolate_snapshot_data =
      reinterpret_cast<const uint8_t*>(isolate_snapshot_data.c_str());
  builder.GetProjectArgs().isolate_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(isolate_snapshot_instructions.c_str());

  auto engine = builder.LaunchEngine();

  flutter::Shell& shell = ToEmbedderEngine(engine.get())->GetShell();
  const Settings settings = shell.GetSettings();

  ASSERT_NE(settings.vm_snapshot_data(), nullptr);
  ASSERT_NE(settings.vm_snapshot_instr(), nullptr);
  ASSERT_NE(settings.isolate_snapshot_data(), nullptr);
  ASSERT_NE(settings.isolate_snapshot_instr(), nullptr);
  ASSERT_NE(settings.dart_library_sources_kernel(), nullptr);
#endif  // OS_FUCHSIA
}

//------------------------------------------------------------------------------
/// PopulateJITSnapshotMappingCallbacks should still be able to successfully
/// change the callbacks of the snapshots in the engine's settings when JIT
/// snapshots are explicitly defined. However, if those snapshot locations are
/// invalid, the callbacks should return a nullptr.
///
TEST_F(EmbedderTest, JITSnapshotCallbacksFailWithInvalidLocation) {
// TODO(#107263): Inconsistent snapshot paths in the Linux Fuchsia FEMU test.
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Inconsistent paths in Fuchsia.";
#else

  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // Explicitly define the locations of the invalid JIT snapshots
  builder.GetProjectArgs().vm_snapshot_data =
      reinterpret_cast<const uint8_t*>("invalid_vm_data");
  builder.GetProjectArgs().vm_snapshot_instructions =
      reinterpret_cast<const uint8_t*>("invalid_vm_instructions");
  builder.GetProjectArgs().isolate_snapshot_data =
      reinterpret_cast<const uint8_t*>("invalid_snapshot_data");
  builder.GetProjectArgs().isolate_snapshot_instructions =
      reinterpret_cast<const uint8_t*>("invalid_snapshot_instructions");

  auto engine = builder.LaunchEngine();

  flutter::Shell& shell = ToEmbedderEngine(engine.get())->GetShell();
  const Settings settings = shell.GetSettings();

  ASSERT_EQ(settings.vm_snapshot_data(), nullptr);
  ASSERT_EQ(settings.vm_snapshot_instr(), nullptr);
  ASSERT_EQ(settings.isolate_snapshot_data(), nullptr);
  ASSERT_EQ(settings.isolate_snapshot_instr(), nullptr);
#endif  // OS_FUCHSIA
}

//------------------------------------------------------------------------------
/// The embedder must be able to run explicitly specified snapshots in JIT mode
/// (i.e. when those are present in known locations).
///
TEST_F(EmbedderTest, CanLaunchEngineWithSpecifiedJITSnapshots) {
  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // Construct the location of valid JIT snapshots.
  const std::string src_path = GetSourcePath();
  const std::string vm_snapshot_data =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_DATA});
  const std::string vm_snapshot_instructions =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_INSTRUCTIONS});
  const std::string isolate_snapshot_data =
      fml::paths::JoinPaths({src_path, TEST_ISOLATE_SNAPSHOT_DATA});
  const std::string isolate_snapshot_instructions =
      fml::paths::JoinPaths({src_path, TEST_ISOLATE_SNAPSHOT_INSTRUCTIONS});

  // Explicitly define the locations of the JIT snapshots
  builder.GetProjectArgs().vm_snapshot_data =
      reinterpret_cast<const uint8_t*>(vm_snapshot_data.c_str());
  builder.GetProjectArgs().vm_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(vm_snapshot_instructions.c_str());
  builder.GetProjectArgs().isolate_snapshot_data =
      reinterpret_cast<const uint8_t*>(isolate_snapshot_data.c_str());
  builder.GetProjectArgs().isolate_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(isolate_snapshot_instructions.c_str());

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

//------------------------------------------------------------------------------
/// The embedder must be able to run in JIT mode when only some snapshots are
/// specified.
///
TEST_F(EmbedderTest, CanLaunchEngineWithSomeSpecifiedJITSnapshots) {
  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // Construct the location of valid JIT snapshots.
  const std::string src_path = GetSourcePath();
  const std::string vm_snapshot_data =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_DATA});
  const std::string vm_snapshot_instructions =
      fml::paths::JoinPaths({src_path, TEST_VM_SNAPSHOT_INSTRUCTIONS});

  // Explicitly define the locations of the JIT snapshots
  builder.GetProjectArgs().vm_snapshot_data =
      reinterpret_cast<const uint8_t*>(vm_snapshot_data.c_str());
  builder.GetProjectArgs().vm_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(vm_snapshot_instructions.c_str());

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

//------------------------------------------------------------------------------
/// The embedder must be able to run in JIT mode even when the specfied
/// snapshots are invalid. It should be able to resolve them as it would when
/// the snapshots are not specified.
///
TEST_F(EmbedderTest, CanLaunchEngineWithInvalidJITSnapshots) {
  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  // Explicitly define the locations of the JIT snapshots
  builder.GetProjectArgs().isolate_snapshot_data =
      reinterpret_cast<const uint8_t*>("invalid_snapshot_data");
  builder.GetProjectArgs().isolate_snapshot_instructions =
      reinterpret_cast<const uint8_t*>("invalid_snapshot_instructions");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kInvalidArguments);
}

//------------------------------------------------------------------------------
/// The embedder must be able to launch even when the snapshots are not
/// explicitly defined in JIT mode. It must be able to resolve those snapshots.
///
TEST_F(EmbedderTest, CanLaunchEngineWithUnspecifiedJITSnapshots) {
  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  ASSERT_EQ(builder.GetProjectArgs().vm_snapshot_data, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().vm_snapshot_instructions, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().isolate_snapshot_data, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().isolate_snapshot_instructions, nullptr);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, InvalidFlutterWindowMetricsEvent) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 0.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;

  // Pixel ratio must be positive.
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kInvalidArguments);

  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = -1.0;
  event.physical_view_inset_right = -1.0;
  event.physical_view_inset_bottom = -1.0;
  event.physical_view_inset_left = -1.0;

  // Physical view insets must be non-negative.
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kInvalidArguments);

  event.physical_view_inset_top = 700;
  event.physical_view_inset_right = 900;
  event.physical_view_inset_bottom = 700;
  event.physical_view_inset_left = 900;

  // Top/bottom insets cannot be greater than height.
  // Left/right insets cannot be greater than width.
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kInvalidArguments);
}

TEST_F(EmbedderTest, InvalidFlutterWindowMetricsEventExtendedMetrics) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());

  // A well formed event that the mutations below are applied to. Note the
  // zero-initialization: every field of an extended metrics event must be
  // initialized because the engine reads all of them once `struct_size` says
  // they are present.
  const double kBounds[4] = {0.0, 0.0, 10.0, 600.0};
  const int32_t kType[1] = {kFlutterDisplayFeatureTypeHinge};
  const int32_t kState[1] = {kFlutterDisplayFeatureStatePostureFlat};

  FlutterWindowMetricsEvent valid = {};
  valid.struct_size = sizeof(valid);
  valid.width = 800;
  valid.height = 600;
  valid.pixel_ratio = 1.0;
  valid.has_extended_metrics = true;
  valid.display_features_count = 1;
  valid.display_features_bounds = kBounds;
  valid.display_features_type = kType;
  valid.display_features_state = kState;

  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &valid),
            kSuccess);

  // Padding must be non-negative.
  FlutterWindowMetricsEvent negative_padding = valid;
  negative_padding.physical_padding_left = -1.0;
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &negative_padding),
      kInvalidArguments);

  // System gesture insets must be non-negative.
  FlutterWindowMetricsEvent negative_inset = valid;
  negative_inset.physical_system_gesture_inset_bottom = -1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &negative_inset),
            kInvalidArguments);

  // The display feature count is capped so that it can never be used to size
  // an allocation or overflow `count * 4`.
  FlutterWindowMetricsEvent too_many_features = valid;
  too_many_features.display_features_count = kFlutterMaxDisplayFeatures + 1;
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &too_many_features),
      kInvalidArguments);

  FlutterWindowMetricsEvent overflowing_features = valid;
  overflowing_features.display_features_count =
      std::numeric_limits<size_t>::max();
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &overflowing_features),
      kInvalidArguments);

  // All three arrays must be supplied when the count is non-zero.
  FlutterWindowMetricsEvent missing_bounds = valid;
  missing_bounds.display_features_bounds = nullptr;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &missing_bounds),
            kInvalidArguments);

  FlutterWindowMetricsEvent missing_type = valid;
  missing_type.display_features_type = nullptr;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &missing_type),
            kInvalidArguments);

  FlutterWindowMetricsEvent missing_state = valid;
  missing_state.display_features_state = nullptr;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &missing_state),
            kInvalidArguments);

  // Types are indices into a Dart enum that `hooks.dart` reads unchecked, so
  // they must be in range.
  const int32_t kOutOfRangeType[1] = {kFlutterDisplayFeatureTypeCutout + 1};
  FlutterWindowMetricsEvent bad_type = valid;
  bad_type.display_features_type = kOutOfRangeType;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &bad_type),
            kInvalidArguments);

  const int32_t kNegativeType[1] = {-1};
  FlutterWindowMetricsEvent negative_type = valid;
  negative_type.display_features_type = kNegativeType;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &negative_type),
            kInvalidArguments);

  // A state the engine does not know is forward compatible: `hooks.dart`
  // bounds checks it and falls back to `DisplayFeatureState.unknown`, so a
  // newer embedder must keep working against this engine.
  const int32_t kUnknownState[1] = {
      kFlutterDisplayFeatureStatePostureHalfOpened + 1};
  FlutterWindowMetricsEvent newer_state = valid;
  newer_state.display_features_state = kUnknownState;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &newer_state),
            kSuccess);

  // A negative state is not: that same guard is upper bound only, so Dart
  // would index the enum with it and throw.
  const int32_t kNegativeState[1] = {-1};
  FlutterWindowMetricsEvent negative_state = valid;
  negative_state.display_features_state = kNegativeState;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &negative_state),
            kInvalidArguments);

  // Zero display features with null arrays remains valid.
  FlutterWindowMetricsEvent no_features = valid;
  no_features.display_features_count = 0;
  no_features.display_features_bounds = nullptr;
  no_features.display_features_type = nullptr;
  no_features.display_features_state = nullptr;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &no_features),
            kSuccess);
}

TEST_F(EmbedderTest, WindowMetricsEventWithConstraints) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();

  ASSERT_TRUE(engine.is_valid());

  // Test with has_constraints = true and valid constraints
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.has_constraints = true;
  event.min_width_constraint = 400;
  event.max_width_constraint = 1200;
  event.min_height_constraint = 300;
  event.max_height_constraint = 900;

  // Should succeed with valid constraints
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  // Test with has_constraints = false
  // Constraints should be ignored and set to current width/height
  FlutterWindowMetricsEvent event_no_constraints = {};
  event_no_constraints.struct_size = sizeof(event_no_constraints);
  event_no_constraints.width = 1024;
  event_no_constraints.height = 768;
  event_no_constraints.pixel_ratio = 1.0;
  event_no_constraints.has_constraints = false;
  // These constraint values should be ignored
  event_no_constraints.min_width_constraint = 0;
  event_no_constraints.max_width_constraint = 0;
  event_no_constraints.min_height_constraint = 0;
  event_no_constraints.max_height_constraint = 0;

  // Should succeed even with invalid constraint values because has_constraints
  // is false
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &event_no_constraints),
      kSuccess);

  // Test with has_constraints = true but width violates min constraint
  FlutterWindowMetricsEvent event_invalid_min = {};
  event_invalid_min.struct_size = sizeof(event_invalid_min);
  event_invalid_min.width = 300;  // Less than min_width_constraint
  event_invalid_min.height = 600;
  event_invalid_min.pixel_ratio = 1.0;
  event_invalid_min.has_constraints = true;
  event_invalid_min.min_width_constraint = 400;
  event_invalid_min.max_width_constraint = 1200;
  event_invalid_min.min_height_constraint = 300;
  event_invalid_min.max_height_constraint = 900;

  // Should fail because width < min_width_constraint
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &event_invalid_min),
      kInvalidArguments);

  // Test with has_constraints = true but width violates max constraint
  FlutterWindowMetricsEvent event_invalid_max = {};
  event_invalid_max.struct_size = sizeof(event_invalid_max);
  event_invalid_max.width = 1300;  // Greater than max_width_constraint
  event_invalid_max.height = 600;
  event_invalid_max.pixel_ratio = 1.0;
  event_invalid_max.has_constraints = true;
  event_invalid_max.min_width_constraint = 400;
  event_invalid_max.max_width_constraint = 1200;
  event_invalid_max.min_height_constraint = 300;
  event_invalid_max.max_height_constraint = 900;

  // Should fail because width > max_width_constraint
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &event_invalid_max),
      kInvalidArguments);

  // Test with has_constraints = true but height violates constraints
  FlutterWindowMetricsEvent event_invalid_height = {};
  event_invalid_height.struct_size = sizeof(event_invalid_height);
  event_invalid_height.width = 800;
  event_invalid_height.height = 200;  // Less than min_height_constraint
  event_invalid_height.pixel_ratio = 1.0;
  event_invalid_height.has_constraints = true;
  event_invalid_height.min_width_constraint = 400;
  event_invalid_height.max_width_constraint = 1200;
  event_invalid_height.min_height_constraint = 300;
  event_invalid_height.max_height_constraint = 900;

  // Should fail because height < min_height_constraint
  ASSERT_EQ(
      FlutterEngineSendWindowMetricsEvent(engine.get(), &event_invalid_height),
      kInvalidArguments);
}

static void expectSoftwareRenderingOutputMatches(
    EmbedderTest& test,
    std::string entrypoint,
    FlutterSoftwarePixelFormat pixfmt,
    const std::vector<uint8_t>& bytes) {
  auto& context = test.GetEmbedderContext<EmbedderTestContextSoftware>();

  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  bool matches = false;

  builder.SetSurface(DlISize(1, 1));
  builder.SetCompositor();
  builder.SetDartEntrypoint(std::move(entrypoint));
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer2,
      pixfmt);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  context.GetCompositor().SetNextPresentCallback(
      [&context, &matches, &bytes, &latch](FlutterViewId view_id,
                                           const FlutterLayer** layers,
                                           size_t layers_count) {
        ASSERT_EQ(layers[0]->type, kFlutterLayerContentTypeBackingStore);
        ASSERT_EQ(layers[0]->backing_store->type,
                  kFlutterBackingStoreTypeSoftware2);
        sk_sp<SkSurface> surface =
            context.GetCompositor().GetSurface(layers[0]->backing_store);
        matches = SurfacePixelDataMatchesBytes(surface.get(), bytes);
        latch.Signal();
      });

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 1;
  event.height = 1;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  latch.Wait();
  ASSERT_TRUE(matches);

  engine.reset();
}

template <typename T>
static void expectSoftwareRenderingOutputMatches(
    EmbedderTest& test,
    std::string entrypoint,
    FlutterSoftwarePixelFormat pixfmt,
    T pixelvalue) {
  uint8_t* bytes = reinterpret_cast<uint8_t*>(&pixelvalue);
  return expectSoftwareRenderingOutputMatches(
      test, std::move(entrypoint), pixfmt,
      std::vector<uint8_t>(bytes, bytes + sizeof(T)));
}

#define SW_PIXFMT_TEST_F(test_name, dart_entrypoint, pixfmt, matcher)     \
  TEST_F(EmbedderTest, SoftwareRenderingPixelFormats##test_name) {        \
    expectSoftwareRenderingOutputMatches(*this, #dart_entrypoint, pixfmt, \
                                         matcher);                        \
  }

// Don't test the pixel formats that contain padding (so an X) and the
// kFlutterSoftwarePixelFormatNative32 pixel format here, so we don't add any
// flakiness.
SW_PIXFMT_TEST_F(RedRGBA565xF800,
                 draw_solid_red,
                 kFlutterSoftwarePixelFormatRGB565,
                 (uint16_t)0xF800);
SW_PIXFMT_TEST_F(RedRGBA4444xF00F,
                 draw_solid_red,
                 kFlutterSoftwarePixelFormatRGBA4444,
                 (uint16_t)0xF00F);
SW_PIXFMT_TEST_F(RedRGBA8888xFFx00x00xFF,
                 draw_solid_red,
                 kFlutterSoftwarePixelFormatRGBA8888,
                 (std::vector<uint8_t>{0xFF, 0x00, 0x00, 0xFF}));
SW_PIXFMT_TEST_F(RedBGRA8888x00x00xFFxFF,
                 draw_solid_red,
                 kFlutterSoftwarePixelFormatBGRA8888,
                 (std::vector<uint8_t>{0x00, 0x00, 0xFF, 0xFF}));
SW_PIXFMT_TEST_F(RedGray8x36,
                 draw_solid_red,
                 kFlutterSoftwarePixelFormatGray8,
                 (uint8_t)0x36);

SW_PIXFMT_TEST_F(GreenRGB565x07E0,
                 draw_solid_green,
                 kFlutterSoftwarePixelFormatRGB565,
                 (uint16_t)0x07E0);
SW_PIXFMT_TEST_F(GreenRGBA4444x0F0F,
                 draw_solid_green,
                 kFlutterSoftwarePixelFormatRGBA4444,
                 (uint16_t)0x0F0F);
SW_PIXFMT_TEST_F(GreenRGBA8888x00xFFx00xFF,
                 draw_solid_green,
                 kFlutterSoftwarePixelFormatRGBA8888,
                 (std::vector<uint8_t>{0x00, 0xFF, 0x00, 0xFF}));
SW_PIXFMT_TEST_F(GreenBGRA8888x00xFFx00xFF,
                 draw_solid_green,
                 kFlutterSoftwarePixelFormatBGRA8888,
                 (std::vector<uint8_t>{0x00, 0xFF, 0x00, 0xFF}));
SW_PIXFMT_TEST_F(GreenGray8xB6,
                 draw_solid_green,
                 kFlutterSoftwarePixelFormatGray8,
                 (uint8_t)0xB6);

SW_PIXFMT_TEST_F(BlueRGB565x001F,
                 draw_solid_blue,
                 kFlutterSoftwarePixelFormatRGB565,
                 (uint16_t)0x001F);
SW_PIXFMT_TEST_F(BlueRGBA4444x00FF,
                 draw_solid_blue,
                 kFlutterSoftwarePixelFormatRGBA4444,
                 (uint16_t)0x00FF);
SW_PIXFMT_TEST_F(BlueRGBA8888x00x00xFFxFF,
                 draw_solid_blue,
                 kFlutterSoftwarePixelFormatRGBA8888,
                 (std::vector<uint8_t>{0x00, 0x00, 0xFF, 0xFF}));
SW_PIXFMT_TEST_F(BlueBGRA8888xFFx00x00xFF,
                 draw_solid_blue,
                 kFlutterSoftwarePixelFormatBGRA8888,
                 (std::vector<uint8_t>{0xFF, 0x00, 0x00, 0xFF}));
SW_PIXFMT_TEST_F(BlueGray8x12,
                 draw_solid_blue,
                 kFlutterSoftwarePixelFormatGray8,
                 (uint8_t)0x12);

//------------------------------------------------------------------------------
// Key Data
//------------------------------------------------------------------------------

typedef struct {
  std::shared_ptr<fml::AutoResetWaitableEvent> latch;
  bool returned;
} KeyEventUserData;

// Convert `kind` in integer form to its enum form.
//
// It performs a revesed mapping from `_serializeKeyEventType`
// in shell/platform/embedder/fixtures/main.dart.
FlutterKeyEventType UnserializeKeyEventType(uint64_t kind) {
  switch (kind) {
    case 1:
      return kFlutterKeyEventTypeUp;
    case 2:
      return kFlutterKeyEventTypeDown;
    case 3:
      return kFlutterKeyEventTypeRepeat;
    default:
      FML_UNREACHABLE();
      return kFlutterKeyEventTypeUp;
  }
}

// Convert `source` in integer form to its enum form.
//
// It performs a revesed mapping from `_serializeKeyEventDeviceType`
// in shell/platform/embedder/fixtures/main.dart.
FlutterKeyEventDeviceType UnserializeKeyEventDeviceType(uint64_t source) {
  switch (source) {
    case 1:
      return kFlutterKeyEventDeviceTypeKeyboard;
    case 2:
      return kFlutterKeyEventDeviceTypeDirectionalPad;
    case 3:
      return kFlutterKeyEventDeviceTypeGamepad;
    case 4:
      return kFlutterKeyEventDeviceTypeJoystick;
    case 5:
      return kFlutterKeyEventDeviceTypeHdmi;
    default:
      FML_UNREACHABLE();
      return kFlutterKeyEventDeviceTypeKeyboard;
  }
}

// Checks the equality of two `FlutterKeyEvent` by each of their members except
// for `character`. The `character` must be checked separately.
void ExpectKeyEventEq(const FlutterKeyEvent& subject,
                      const FlutterKeyEvent& baseline) {
  EXPECT_EQ(subject.timestamp, baseline.timestamp);
  EXPECT_EQ(subject.type, baseline.type);
  EXPECT_EQ(subject.physical, baseline.physical);
  EXPECT_EQ(subject.logical, baseline.logical);
  EXPECT_EQ(subject.synthesized, baseline.synthesized);
  EXPECT_EQ(subject.device_type, baseline.device_type);
}

TEST_F(EmbedderTest, KeyDataIsCorrectlySerialized) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  uint64_t echoed_char;
  FlutterKeyEvent echoed_event;
  echoed_event.struct_size = sizeof(FlutterKeyEvent);

  auto native_echo_event = [&](uint64_t change, uint64_t timestamp,
                               uint64_t physical, uint64_t logical,
                               uint64_t char_code, bool synthesized,
                               uint64_t device_type) {
    echoed_event.type = UnserializeKeyEventType(change);
    echoed_event.timestamp = static_cast<double>(timestamp);
    echoed_event.physical = physical;
    echoed_event.logical = logical;
    echoed_char = char_code;
    echoed_event.synthesized = synthesized;
    echoed_event.device_type = UnserializeKeyEventDeviceType(device_type);

    message_latch->Signal();
  };

  auto platform_task_runner = CreateNewThread("platform_thread");

  UniqueEngine engine;
  fml::AutoResetWaitableEvent ready;
  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("key_data_echo");
    builder.SetPlatformMessageCallback(
        [&](const FlutterPlatformMessage* message) {
          FlutterEngineSendPlatformMessageResponse(
              engine.get(), message->response_handle, nullptr, 0);
        });
    context.AddFfiNativeCallback(
        "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));

    context.AddFfiNativeCallback("EchoKeyEvent",
                                 CREATE_FFI_LAMBDA(native_echo_event));

    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });

  ready.Wait();

  // A normal down event
  const FlutterKeyEvent down_event_upper_a{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = 1,
      .type = kFlutterKeyEventTypeDown,
      .physical = 0x00070004,
      .logical = 0x00000000061,
      .character = "A",
      .synthesized = false,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &down_event_upper_a, nullptr,
                              nullptr);
  });
  message_latch->Wait();

  ExpectKeyEventEq(echoed_event, down_event_upper_a);
  EXPECT_EQ(echoed_char, 0x41llu);

  // A repeat event with multi-byte character
  const FlutterKeyEvent repeat_event_wide_char{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = 1000,
      .type = kFlutterKeyEventTypeRepeat,
      .physical = 0x00070005,
      .logical = 0x00000000062,
      .character = "∆",
      .synthesized = false,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &repeat_event_wide_char, nullptr,
                              nullptr);
  });
  message_latch->Wait();

  ExpectKeyEventEq(echoed_event, repeat_event_wide_char);
  EXPECT_EQ(echoed_char, 0x2206llu);

  // An up event with no character, synthesized
  const FlutterKeyEvent up_event{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = 1000000,
      .type = kFlutterKeyEventTypeUp,
      .physical = 0x00070006,
      .logical = 0x00000000063,
      .character = nullptr,
      .synthesized = true,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &up_event, nullptr, nullptr);
  });
  message_latch->Wait();

  ExpectKeyEventEq(echoed_event, up_event);
  EXPECT_EQ(echoed_char, 0llu);

  fml::AutoResetWaitableEvent shutdown_latch;
  platform_task_runner->PostTask([&]() {
    engine.reset();
    shutdown_latch.Signal();
  });
  shutdown_latch.Wait();
}

TEST_F(EmbedderTest, KeyDataAreBuffered) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  std::vector<FlutterKeyEvent> echoed_events;

  auto native_echo_event = [&](uint64_t change, uint64_t timestamp,
                               uint64_t physical, uint64_t logical,
                               uint64_t char_code, bool synthesized,
                               uint64_t device_type) {
    echoed_events.push_back(FlutterKeyEvent{
        .timestamp = static_cast<double>(timestamp),
        .type = UnserializeKeyEventType(change),
        .physical = physical,
        .logical = logical,
        .synthesized = synthesized,
        .device_type = UnserializeKeyEventDeviceType(device_type),
    });

    message_latch->Signal();
  };

  auto platform_task_runner = CreateNewThread("platform_thread");

  UniqueEngine engine;
  fml::AutoResetWaitableEvent ready;
  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("key_data_late_echo");
    builder.SetPlatformMessageCallback(
        [&](const FlutterPlatformMessage* message) {
          FlutterEngineSendPlatformMessageResponse(
              engine.get(), message->response_handle, nullptr, 0);
        });
    context.AddFfiNativeCallback(
        "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));

    context.AddFfiNativeCallback("EchoKeyEvent",
                                 CREATE_FFI_LAMBDA(native_echo_event));

    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });
  ready.Wait();

  FlutterKeyEvent sample_event{
      .struct_size = sizeof(FlutterKeyEvent),
      .type = kFlutterKeyEventTypeDown,
      .physical = 0x00070004,
      .logical = 0x00000000061,
      .character = "A",
      .synthesized = false,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };

  // Send an event.
  sample_event.timestamp = 1.0;
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &sample_event, nullptr, nullptr);
    message_latch->Signal();
  });
  message_latch->Wait();

  // Should not receive echos because the callback is not set yet.
  EXPECT_EQ(echoed_events.size(), 0u);

  // Send an empty message to 'test/starts_echo' to start echoing.
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  FlutterPlatformMessageCreateResponseHandle(
      engine.get(), [](const uint8_t* data, size_t size, void* user_data) {},
      nullptr, &response_handle);

  FlutterPlatformMessage message{
      .struct_size = sizeof(FlutterPlatformMessage),
      .channel = "test/starts_echo",
      .message = nullptr,
      .message_size = 0,
      .response_handle = response_handle,
  };

  platform_task_runner->PostTask([&]() {
    FlutterEngineResult result =
        FlutterEngineSendPlatformMessage(engine.get(), &message);
    ASSERT_EQ(result, kSuccess);

    FlutterPlatformMessageReleaseResponseHandle(engine.get(), response_handle);
  });

  // message_latch->Wait();
  message_latch->Wait();
  // All previous events should be received now.
  EXPECT_EQ(echoed_events.size(), 1u);

  // Send a second event.
  sample_event.timestamp = 10.0;
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &sample_event, nullptr, nullptr);
  });
  message_latch->Wait();

  // The event should be echoed, too.
  EXPECT_EQ(echoed_events.size(), 2u);

  fml::AutoResetWaitableEvent shutdown_latch;
  platform_task_runner->PostTask([&]() {
    engine.reset();
    shutdown_latch.Signal();
  });
  shutdown_latch.Wait();
}

TEST_F(EmbedderTest, KeyDataResponseIsCorrectlyInvoked) {
  UniqueEngine engine;
  fml::AutoResetWaitableEvent sync_latch;
  fml::AutoResetWaitableEvent ready;

  // One of the threads that the key data callback will be posted to is the
  // platform thread. So we cannot wait for assertions to complete on the
  // platform thread. Create a new thread to manage the engine instance and wait
  // for assertions on the test thread.
  auto platform_task_runner = CreateNewThread("platform_thread");

  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("key_data_echo");
    context.AddFfiNativeCallback(
        "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));
    context.AddFfiNativeCallback(
        "EchoKeyEvent",
        CREATE_FFI_LAMBDA([](uint64_t change, uint64_t timestamp,
                             uint64_t physical, uint64_t logical,
                             uint64_t char_code, bool synthesized,
                             uint64_t device_type) {}));

    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    sync_latch.Signal();
  });
  sync_latch.Wait();
  ready.Wait();

  // Dispatch a single event
  FlutterKeyEvent event{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = 1000,
      .type = kFlutterKeyEventTypeDown,
      .physical = 0x00070005,
      .logical = 0x00000000062,
      .character = nullptr,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };

  KeyEventUserData user_data1{
      .latch = std::make_shared<fml::AutoResetWaitableEvent>(),
  };
  // Entrypoint `key_data_echo` returns `event.synthesized` as `handled`.
  event.synthesized = true;
  platform_task_runner->PostTask([&]() {
    // Test when the response callback is empty.
    // It should not cause a crash.
    FlutterEngineSendKeyEvent(engine.get(), &event, nullptr, nullptr);

    // Test when the response callback is non-empty.
    // It should be invoked (so that the latch can be unlocked.)
    FlutterEngineSendKeyEvent(
        engine.get(), &event,
        [](bool handled, void* untyped_user_data) {
          KeyEventUserData* user_data =
              reinterpret_cast<KeyEventUserData*>(untyped_user_data);
          EXPECT_EQ(handled, true);
          user_data->latch->Signal();
        },
        &user_data1);
  });
  user_data1.latch->Wait();
  fml::AutoResetWaitableEvent shutdown_latch;
  platform_task_runner->PostTask([&]() {
    engine.reset();
    shutdown_latch.Signal();
  });
  shutdown_latch.Wait();
}

TEST_F(EmbedderTest, BackToBackKeyEventResponsesCorrectlyInvoked) {
  UniqueEngine engine;
  fml::AutoResetWaitableEvent sync_latch;
  fml::AutoResetWaitableEvent ready;

  // One of the threads that the callback will be posted to is the platform
  // thread. So we cannot wait for assertions to complete on the platform
  // thread. Create a new thread to manage the engine instance and wait for
  // assertions on the test thread.
  auto platform_task_runner = CreateNewThread("platform_thread");

  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetDartEntrypoint("key_data_echo");
    context.AddFfiNativeCallback(
        "SignalNativeTest", CREATE_FFI_LAMBDA([&ready]() { ready.Signal(); }));

    context.AddFfiNativeCallback(
        "EchoKeyEvent",
        CREATE_FFI_LAMBDA([](uint64_t change, uint64_t timestamp,
                             uint64_t physical, uint64_t logical,
                             uint64_t char_code, bool synthesized,
                             uint64_t device_type) {}));

    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    sync_latch.Signal();
  });
  sync_latch.Wait();
  ready.Wait();

  // Dispatch a single event
  FlutterKeyEvent event{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = 1000,
      .type = kFlutterKeyEventTypeDown,
      .physical = 0x00070005,
      .logical = 0x00000000062,
      .character = nullptr,
      .synthesized = false,
      .device_type = kFlutterKeyEventDeviceTypeKeyboard,
  };

  // Dispatch two events back to back, using the same callback on different
  // user_data
  KeyEventUserData user_data2{
      .latch = std::make_shared<fml::AutoResetWaitableEvent>(),
      .returned = false,
  };
  KeyEventUserData user_data3{
      .latch = std::make_shared<fml::AutoResetWaitableEvent>(),
      .returned = false,
  };
  auto callback23 = [](bool handled, void* untyped_user_data) {
    KeyEventUserData* user_data =
        reinterpret_cast<KeyEventUserData*>(untyped_user_data);
    EXPECT_EQ(handled, false);
    user_data->returned = true;
    user_data->latch->Signal();
  };
  platform_task_runner->PostTask([&]() {
    FlutterEngineSendKeyEvent(engine.get(), &event, callback23, &user_data2);
    FlutterEngineSendKeyEvent(engine.get(), &event, callback23, &user_data3);
  });
  user_data2.latch->Wait();
  user_data3.latch->Wait();

  EXPECT_TRUE(user_data2.returned);
  EXPECT_TRUE(user_data3.returned);

  fml::AutoResetWaitableEvent shutdown_latch;
  platform_task_runner->PostTask([&]() {
    engine.reset();
    shutdown_latch.Signal();
  });
  shutdown_latch.Wait();
}

//------------------------------------------------------------------------------
// Vsync waiter
//------------------------------------------------------------------------------

// This test schedules a frame for the future and asserts that vsync waiter
// posts the event at the right frame start time (which is in the future).
TEST_F(EmbedderTest, VsyncCallbackPostedIntoFuture) {
  UniqueEngine engine;
  fml::AutoResetWaitableEvent present_latch;
  fml::AutoResetWaitableEvent vsync_latch;

  // One of the threads that the callback (FlutterEngineOnVsync) will be posted
  // to is the platform thread. So we cannot wait for assertions to complete on
  // the platform thread. Create a new thread to manage the engine instance and
  // wait for assertions on the test thread.
  auto platform_task_runner = CreateNewThread("platform_thread");

  platform_task_runner->PostTask([&]() {
    auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
    context.SetVsyncCallback([&](intptr_t baton) {
      platform_task_runner->PostTask([baton = baton, &engine, &vsync_latch]() {
        FlutterEngineOnVsync(engine.get(), baton, NanosFromEpoch(16),
                             NanosFromEpoch(32));
        vsync_latch.Signal();
      });
    });
    context.AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
                                   present_latch.Signal();
                                 }));

    EmbedderConfigBuilder builder(context);
    builder.SetSurface(DlISize(1, 1));
    builder.SetupVsyncCallback();
    builder.SetDartEntrypoint("empty_scene");
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    // Send a window metrics events so frames may be scheduled.
    FlutterWindowMetricsEvent event = {};
    event.struct_size = sizeof(event);
    event.width = 800;
    event.height = 600;
    event.pixel_ratio = 1.0;

    ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
              kSuccess);
  });

  vsync_latch.Wait();
  present_latch.Wait();

  fml::AutoResetWaitableEvent shutdown_latch;
  platform_task_runner->PostTask([&]() {
    engine.reset();
    shutdown_latch.Signal();
  });
  shutdown_latch.Wait();
}

TEST_F(EmbedderTest, CanScheduleFrame) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("can_schedule_frame");
  fml::AutoResetWaitableEvent latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest", CREATE_FFI_LAMBDA([&latch]() { latch.Signal(); }));

  fml::AutoResetWaitableEvent check_latch;
  context.AddFfiNativeCallback(
      "SignalNativeCount",
      CREATE_FFI_LAMBDA([&check_latch](int count) { check_latch.Signal(); }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the application to attach the listener.
  latch.Wait();

  ASSERT_EQ(FlutterEngineScheduleFrame(engine.get()), kSuccess);

  check_latch.Wait();
}

TEST_F(EmbedderTest, CanSetNextFrameCallback) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("draw_solid_red");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Register the callback that is executed once the next frame is drawn.
  fml::AutoResetWaitableEvent callback_latch;
  VoidCallback callback = [](void* user_data) {
    fml::AutoResetWaitableEvent* callback_latch =
        static_cast<fml::AutoResetWaitableEvent*>(user_data);

    callback_latch->Signal();
  };

  auto result = FlutterEngineSetNextFrameCallback(engine.get(), callback,
                                                  &callback_latch);
  ASSERT_EQ(result, kSuccess);

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  event.physical_view_inset_top = 0.0;
  event.physical_view_inset_right = 0.0;
  event.physical_view_inset_bottom = 0.0;
  event.physical_view_inset_left = 0.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  callback_latch.Wait();
}

#if defined(FML_OS_MACOSX)

static void MockThreadConfigSetter(const fml::Thread::ThreadConfig& config) {
  pthread_t tid = pthread_self();
  struct sched_param param;
  int policy = SCHED_OTHER;
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kDisplay:
      param.sched_priority = 10;
      break;
    default:
      param.sched_priority = 1;
  }
  pthread_setschedparam(tid, policy, &param);
}

TEST_F(EmbedderTest, EmbedderThreadHostUseCustomThreadConfig) {
  auto thread_host =
      flutter::EmbedderThreadHost::CreateEmbedderOrEngineManagedThreadHost(
          nullptr, MockThreadConfigSetter);

  fml::AutoResetWaitableEvent ui_latch;
  int ui_policy;
  struct sched_param ui_param;

  thread_host->GetTaskRunners().GetUITaskRunner()->PostTask([&] {
    pthread_t current_thread = pthread_self();
    pthread_getschedparam(current_thread, &ui_policy, &ui_param);
    ASSERT_EQ(ui_param.sched_priority, 10);
    ui_latch.Signal();
  });

  fml::AutoResetWaitableEvent io_latch;
  int io_policy;
  struct sched_param io_param;
  thread_host->GetTaskRunners().GetIOTaskRunner()->PostTask([&] {
    pthread_t current_thread = pthread_self();
    pthread_getschedparam(current_thread, &io_policy, &io_param);
    ASSERT_EQ(io_param.sched_priority, 1);
    io_latch.Signal();
  });

  ui_latch.Wait();
  io_latch.Wait();
}
#endif

/// Send a pointer event to Dart and wait until the Dart code signals
/// it received the event.
TEST_F(EmbedderTest, CanSendPointer) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("pointer_data_packet");

  fml::AutoResetWaitableEvent ready_latch, count_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));
  context.AddFfiNativeCallback("SignalNativeCount",
                               CREATE_FFI_LAMBDA([&count_latch](int count) {
                                 ASSERT_EQ(count, 1);
                                 count_latch.Signal();
                               }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA([&message_latch](Dart_Handle message_handle) {
        auto message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        ASSERT_EQ("PointerData(viewId: 0, x: 123.0, y: 456.0)", message);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  FlutterPointerEvent pointer_event = {};
  pointer_event.struct_size = sizeof(FlutterPointerEvent);
  pointer_event.phase = FlutterPointerPhase::kAdd;
  pointer_event.x = 123;
  pointer_event.y = 456;
  pointer_event.timestamp = static_cast<size_t>(1234567890);
  pointer_event.view_id = 0;

  FlutterEngineResult result =
      FlutterEngineSendPointerEvent(engine.get(), &pointer_event, 1);
  ASSERT_EQ(result, kSuccess);

  count_latch.Wait();
  message_latch.Wait();
}

/// Send a stylus pointer event to Dart and verify the buttons mask.
TEST_F(EmbedderTest, CanSendStylusPointerButtons) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("pointer_data_packet_stylus_buttons");

  fml::AutoResetWaitableEvent ready_latch, count_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));
  context.AddFfiNativeCallback("SignalNativeCount",
                               CREATE_FFI_LAMBDA([&count_latch](int count) {
                                 EXPECT_EQ(count, 1);
                                 count_latch.Signal();
                               }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA([&message_latch](Dart_Handle message_handle) {
        auto message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        EXPECT_EQ("buttons: 3", message);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  FlutterPointerEvent pointer_event = {};
  pointer_event.struct_size = sizeof(FlutterPointerEvent);
  pointer_event.phase = FlutterPointerPhase::kAdd;
  pointer_event.device_kind = kFlutterPointerDeviceKindStylus;
  pointer_event.buttons =
      kFlutterPointerButtonStylusContact | kFlutterPointerButtonStylusPrimary;
  pointer_event.x = 123;
  pointer_event.y = 456;
  pointer_event.timestamp = static_cast<size_t>(1234567890);
  pointer_event.view_id = 0;

  FlutterEngineResult result =
      FlutterEngineSendPointerEvent(engine.get(), &pointer_event, 1);
  ASSERT_EQ(result, kSuccess);

  count_latch.Wait();
  message_latch.Wait();
}

/// Send a pointer event to Dart and wait until the Dart code echos with the
/// view ID.
TEST_F(EmbedderTest, CanSendPointerEventWithViewId) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("pointer_data_packet_view_id");

  fml::AutoResetWaitableEvent ready_latch, add_view_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA([&message_latch](Dart_Handle message_handle) {
        auto message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        ASSERT_EQ("ViewID: 2", message);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  ready_latch.Wait();

  // Add view 2
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 800;
  metrics.height = 600;
  metrics.pixel_ratio = 1.0;
  metrics.view_id = 2;

  FlutterAddViewInfo info = {};
  info.struct_size = sizeof(FlutterAddViewInfo);
  info.view_id = 2;
  info.view_metrics = &metrics;
  info.add_view_callback = [](const FlutterAddViewResult* result) {
    EXPECT_TRUE(result->added);
    fml::AutoResetWaitableEvent* add_view_latch =
        reinterpret_cast<fml::AutoResetWaitableEvent*>(result->user_data);
    add_view_latch->Signal();
  };
  info.user_data = &add_view_latch;
  ASSERT_EQ(FlutterEngineAddView(engine.get(), &info), kSuccess);
  add_view_latch.Wait();

  // Send a pointer event for view 2
  FlutterPointerEvent pointer_event = {};
  pointer_event.struct_size = sizeof(FlutterPointerEvent);
  pointer_event.phase = FlutterPointerPhase::kAdd;
  pointer_event.x = 123;
  pointer_event.y = 456;
  pointer_event.timestamp = static_cast<size_t>(1234567890);
  pointer_event.view_id = 2;

  FlutterEngineResult result =
      FlutterEngineSendPointerEvent(engine.get(), &pointer_event, 1);
  ASSERT_EQ(result, kSuccess);

  message_latch.Wait();
}

TEST_F(EmbedderTest, WindowMetricsEventDefaultsToImplicitView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_view_id");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));
  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA([&message_latch](Dart_Handle message_handle) {
        auto message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        ASSERT_EQ("Changed: [0]", message);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  FlutterWindowMetricsEvent event = {};
  // Simulate an event that comes from an old version of embedder.h that doesn't
  // have the view_id field.
  event.struct_size = offsetof(FlutterWindowMetricsEvent, view_id);
  event.width = 200;
  event.height = 300;
  event.pixel_ratio = 1.5;
  // Skip assigning event.view_id here to test the default behavior.

  FlutterEngineResult result =
      FlutterEngineSendWindowMetricsEvent(engine.get(), &event);
  ASSERT_EQ(result, kSuccess);

  message_latch.Wait();
}

TEST_F(EmbedderTest, IgnoresWindowMetricsEventForUnknownView) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("window_metrics_event_view_id");

  fml::AutoResetWaitableEvent ready_latch, message_latch;
  context.AddFfiNativeCallback(
      "SignalNativeTest",
      CREATE_FFI_LAMBDA([&ready_latch]() { ready_latch.Signal(); }));

  context.AddFfiNativeCallback(
      "SignalNativeMessage",
      CREATE_FFI_LAMBDA([&message_latch](Dart_Handle message_handle) {
        auto message =
            tonic::DartConverter<std::string>::FromDart(message_handle);
        // Message latch should only be signaled once as the bad
        // view metric should be dropped by the engine.
        ASSERT_FALSE(message_latch.IsSignaledForTest());
        ASSERT_EQ("Changed: [0]", message);
        message_latch.Signal();
      }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ready_latch.Wait();

  // Send a window metric for a nonexistent view, which should be dropped by the
  // engine.
  FlutterWindowMetricsEvent bad_event = {};
  bad_event.struct_size = sizeof(FlutterWindowMetricsEvent);
  bad_event.width = 200;
  bad_event.height = 300;
  bad_event.pixel_ratio = 1.5;
  bad_event.view_id = 100;

  FlutterEngineResult result =
      FlutterEngineSendWindowMetricsEvent(engine.get(), &bad_event);
  ASSERT_EQ(result, kSuccess);

  // Send a window metric for a valid view. The engine notifies the Dart app.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = 200;
  event.height = 300;
  event.pixel_ratio = 1.5;
  event.view_id = 0;

  result = FlutterEngineSendWindowMetricsEvent(engine.get(), &event);
  ASSERT_EQ(result, kSuccess);

  message_latch.Wait();
}

TEST_F(EmbedderTest, RegisterChannelListener) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();

  fml::AutoResetWaitableEvent latch;
  fml::AutoResetWaitableEvent latch2;
  bool listening = false;
  context.AddFfiNativeCallback("SignalNativeTest",
                               CREATE_FFI_LAMBDA([&]() { latch.Signal(); }));
  context.SetChannelUpdateCallback([&](const FlutterChannelUpdate* update) {
    EXPECT_STREQ(update->channel, "test/listen");
    EXPECT_TRUE(update->listening);
    listening = true;
    latch2.Signal();
  });

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("channel_listener_response");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  latch.Wait();
  // Drain tasks posted to platform thread task runner.
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  latch2.Wait();

  ASSERT_TRUE(listening);
}

TEST_F(EmbedderTest, PlatformThreadIsolatesWithCustomPlatformTaskRunner) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  static fml::AutoResetWaitableEvent latch;

  static std::thread::id ffi_call_thread_id;
  static void (*ffi_signal_native_test)() = []() -> void {
    ffi_call_thread_id = std::this_thread::get_id();
    latch.Signal();
  };

  Dart_FfiNativeResolver ffi_resolver = [](const char* name,
                                           uintptr_t args_n) -> void* {
    if (std::string_view(name) == "FFISignalNativeTest") {
      return reinterpret_cast<void*>(ffi_signal_native_test);
    }
    return nullptr;
  };

  // The test's Dart code will call this native function which overrides the
  // FFI resolver.  After that, the Dart code will invoke the FFI function
  // using runOnPlatformThread.
  context.AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
                                 Dart_SetFfiNativeResolver(Dart_RootLibrary(),
                                                           ffi_resolver);
                               }));

  auto platform_task_runner = CreateNewThread("test_platform_thread");

  UniqueEngine engine;

  EmbedderTestTaskRunner test_task_runner(
      platform_task_runner, [&](FlutterTask task) {
        if (!engine.is_valid()) {
          return;
        }
        FlutterEngineRunTask(engine.get(), &task);
      });

  std::thread::id platform_thread_id;
  platform_task_runner->PostTask([&]() {
    platform_thread_id = std::this_thread::get_id();

    EmbedderConfigBuilder builder(context);
    const auto task_runner_description =
        test_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSurface(DlISize(1, 1));
    builder.SetPlatformTaskRunner(&task_runner_description);
    builder.SetDartEntrypoint("invokePlatformThreadIsolate");
    builder.AddCommandLineArgument("--enable-platform-isolates");
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });

  latch.Wait();

  fml::AutoResetWaitableEvent kill_latch;
  platform_task_runner->PostTask(fml::MakeCopyable([&]() mutable {
    engine.reset();

    platform_task_runner->PostTask([&kill_latch] { kill_latch.Signal(); });
  }));
  kill_latch.Wait();

  // Check that the FFI call was executed on the platform thread.
  ASSERT_EQ(platform_thread_id, ffi_call_thread_id);
}

TEST_F(EmbedderTest, EmbedderAssetResolverDirect) {
  std::string test_data = "Hello Flutter Assets!";

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = &test_data;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    auto* str = static_cast<std::string*>(user_data);
    if (std::string(name) == "test_asset.txt") {
      asset_out->struct_size = sizeof(FlutterAsset);
      asset_out->data = reinterpret_cast<const uint8_t*>(str->data());
      asset_out->size = str->size();
      asset_out->user_data = nullptr;
      asset_out->asset_free_callback = nullptr;
      return true;
    }
    return false;
  };
  resolver.is_valid_callback = [](void* user_data) { return true; };
  resolver.is_valid_after_change_callback = [](void* user_data) {
    return true;
  };
  resolver.destruction_callback = [](void* user_data) {};

  {
    EmbedderAssetResolver embedder_resolver(resolver);
    EXPECT_TRUE(embedder_resolver.IsValid());
    EXPECT_TRUE(embedder_resolver.IsValidAfterAssetManagerChange());
    EXPECT_EQ(embedder_resolver.GetType(),
              AssetResolver::AssetResolverType::kCustomResolver);

    auto mapping = embedder_resolver.GetAsMapping("test_asset.txt");
    ASSERT_NE(mapping, nullptr);
    EXPECT_EQ(mapping->GetSize(), test_data.size());
    EXPECT_EQ(std::string(reinterpret_cast<const char*>(mapping->GetMapping()),
                          mapping->GetSize()),
              test_data);

    auto missing_mapping = embedder_resolver.GetAsMapping("missing.txt");
    EXPECT_EQ(missing_mapping, nullptr);

    EmbedderAssetResolver identical_resolver(resolver);
    EXPECT_TRUE(embedder_resolver == identical_resolver);

    // Differing by `user_data` is compared as data, so no linker optimization
    // can make these two look alike.
    std::string other_data = test_data;
    FlutterAssetResolver different_user_data_resolver = resolver;
    different_user_data_resolver.user_data = &other_data;
    EmbedderAssetResolver different_user_data(different_user_data_resolver);
    EXPECT_FALSE(embedder_resolver == different_user_data);

    // Differing by a callback has to be done with a body that is not merely
    // another empty function: two identical captureless lambdas may be folded
    // into a single function by the linker (MSVC's identical COMDAT folding
    // does exactly that), which would give them the same address and make the
    // two resolvers compare equal. The body must stay inert and must not
    // dereference `user_data`, which still points at the `std::string` the
    // original resolver was built with, not at anything this callback owns.
    FlutterAssetResolver different_destructor_resolver = resolver;
    different_destructor_resolver.destruction_callback = [](void* user_data) {
      static int destruction_count = 0;
      destruction_count++;
    };
    EmbedderAssetResolver different_resolver(different_destructor_resolver);
    EXPECT_FALSE(embedder_resolver == different_resolver);
  }
}

TEST_F(EmbedderTest, EmbedderAssetResolverFreeCallback) {
  bool asset_freed = false;

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = &asset_freed;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    static const char kStaticData[] = "Resource To Free";
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = reinterpret_cast<const uint8_t*>(kStaticData);
    asset_out->size = sizeof(kStaticData);
    asset_out->user_data = user_data;
    asset_out->asset_free_callback = [](void* baton) {
      *static_cast<bool*>(baton) = true;
    };
    return true;
  };

  {
    EmbedderAssetResolver embedder_resolver(resolver);
    auto mapping = embedder_resolver.GetAsMapping("test.txt");
    ASSERT_NE(mapping, nullptr);
    EXPECT_FALSE(asset_freed);
  }
  EXPECT_TRUE(asset_freed);
}

TEST_F(EmbedderTest, EmbedderAssetResolverNullDataFreeCallback) {
  bool asset_freed = false;

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = &asset_freed;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    asset_out->struct_size = sizeof(FlutterAsset);
    asset_out->data = nullptr;
    asset_out->size = 0;
    asset_out->user_data = user_data;
    asset_out->asset_free_callback = [](void* baton) {
      *static_cast<bool*>(baton) = true;
    };
    return true;
  };

  {
    EmbedderAssetResolver embedder_resolver(resolver);
    auto mapping = embedder_resolver.GetAsMapping("test.txt");
    // An asset that resolves successfully with no bytes is a valid, empty
    // asset. This matches `fml::FileMapping`, which reports a zero-length file
    // as a valid mapping with a null pointer and a size of zero, so
    // `DirectoryAssetBundle` returns a mapping for an empty asset too.
    ASSERT_NE(mapping, nullptr);
    EXPECT_EQ(mapping->GetSize(), 0u);
    EXPECT_EQ(mapping->GetMapping(), nullptr);
    // The asset is only released once the mapping that owns it is destroyed.
    EXPECT_FALSE(asset_freed);
  }
  EXPECT_TRUE(asset_freed);
}

TEST_F(EmbedderTest, EmbedderAssetResolverDestructionCallback) {
  bool resolver_destroyed = false;

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = &resolver_destroyed;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    return false;
  };
  resolver.destruction_callback = [](void* user_data) {
    *static_cast<bool*>(user_data) = true;
  };

  {
    EmbedderAssetResolver embedder_resolver(resolver);
    EXPECT_FALSE(resolver_destroyed);
  }
  EXPECT_TRUE(resolver_destroyed);
}

TEST_F(EmbedderTest, EmbedderCustomAssetResolversInProjectArgs) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));

  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = nullptr;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    return false;
  };

  const FlutterAssetResolver* resolvers[] = {&resolver};
  builder.GetProjectArgs().asset_resolvers = resolvers;
  builder.GetProjectArgs().asset_resolvers_count = 1;

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, EmbedderUpdateAssetResolver) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Test invalid arguments.
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(nullptr, nullptr),
            kInvalidArguments);
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), nullptr),
            kInvalidArguments);

  FlutterAssetResolverRegistrationInfo invalid_info = {};
  invalid_info.struct_size = sizeof(FlutterAssetResolverRegistrationInfo) - 1;
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), &invalid_info),
            kInvalidArguments);

  FlutterAssetResolverRegistrationInfo info = {};
  info.struct_size = sizeof(FlutterAssetResolverRegistrationInfo);
  info.resolver = nullptr;
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), &info),
            kInvalidArguments);

  FlutterAssetResolver invalid_resolver = {};
  invalid_resolver.struct_size = sizeof(FlutterAssetResolver) - 1;
  info.resolver = &invalid_resolver;
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), &info),
            kInvalidArguments);

  FlutterAssetResolver missing_callback_resolver = {};
  missing_callback_resolver.struct_size = sizeof(FlutterAssetResolver);
  missing_callback_resolver.find_asset_callback = nullptr;
  info.resolver = &missing_callback_resolver;
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), &info),
            kInvalidArguments);

  // Test valid update.
  FlutterAssetResolver valid_resolver = {};
  valid_resolver.struct_size = sizeof(FlutterAssetResolver);
  valid_resolver.user_data = nullptr;
  valid_resolver.find_asset_callback = [](void* user_data, const char* name,
                                          FlutterAsset* asset_out) -> bool {
    return false;
  };
  info.resolver = &valid_resolver;
  EXPECT_EQ(FlutterEngineUpdateAssetResolver(engine.get(), &info), kSuccess);
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesUpdateAssetResolver) {
  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  EXPECT_EQ(FlutterEngineGetProcAddresses(&procs), kSuccess);
  EXPECT_EQ(procs.UpdateAssetResolver, &FlutterEngineUpdateAssetResolver);
}

TEST_F(EmbedderTest, EmbedderSpawnInvalidArguments) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterEngine spawned_engine = nullptr;

  // Null parent engine.
  EXPECT_EQ(FlutterEngineSpawn(nullptr, nullptr, &spawned_engine),
            kInvalidArguments);

  // Null config.
  EXPECT_EQ(FlutterEngineSpawn(engine.get(), nullptr, &spawned_engine),
            kInvalidArguments);

  // Null out pointer.
  FlutterEngineSpawnConfig valid_config = {};
  valid_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  valid_config.renderer_config = &context.GetRendererConfig();
  EXPECT_EQ(FlutterEngineSpawn(engine.get(), &valid_config, nullptr),
            kInvalidArguments);

  // Invalid struct_size.
  FlutterEngineSpawnConfig invalid_size_config = {};
  invalid_size_config.struct_size = sizeof(FlutterEngineSpawnConfig) - 1;
  invalid_size_config.renderer_config = &context.GetRendererConfig();
  EXPECT_EQ(
      FlutterEngineSpawn(engine.get(), &invalid_size_config, &spawned_engine),
      kInvalidArguments);

  // Invalid renderer config type. The out-of-range cast is intentional: this
  // test exercises the engine's validation of a renderer type it does not know
  // about.
  FlutterRendererConfig invalid_renderer = {};
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  invalid_renderer.type = static_cast<FlutterRendererType>(999);
  FlutterEngineSpawnConfig invalid_renderer_config = {};
  invalid_renderer_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  invalid_renderer_config.renderer_config = &invalid_renderer;
  EXPECT_EQ(FlutterEngineSpawn(engine.get(), &invalid_renderer_config,
                               &spawned_engine),
            kInvalidArguments);

  // Invalid project_args struct_size.
  FlutterProjectArgs invalid_project_args = {};
  invalid_project_args.struct_size = sizeof(size_t) - 1;
  FlutterEngineSpawnConfig invalid_args_config = {};
  invalid_args_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  invalid_args_config.renderer_config = &context.GetRendererConfig();
  invalid_args_config.project_args = &invalid_project_args;
  EXPECT_EQ(
      FlutterEngineSpawn(engine.get(), &invalid_args_config, &spawned_engine),
      kInvalidArguments);

  // Custom task runners in project_args are rejected.
  FlutterCustomTaskRunners custom_runners = {};
  custom_runners.struct_size = sizeof(FlutterCustomTaskRunners);
  FlutterProjectArgs custom_runners_args = {};
  custom_runners_args.struct_size = sizeof(FlutterProjectArgs);
  custom_runners_args.custom_task_runners = &custom_runners;
  FlutterEngineSpawnConfig custom_runners_config = {};
  custom_runners_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  custom_runners_config.renderer_config = &context.GetRendererConfig();
  custom_runners_config.project_args = &custom_runners_args;
  EXPECT_EQ(
      FlutterEngineSpawn(engine.get(), &custom_runners_config, &spawned_engine),
      kInvalidArguments);

  // Entrypoint argc > 0 with null argv.
  FlutterEngineSpawnConfig null_argv_config = {};
  null_argv_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  null_argv_config.renderer_config = &context.GetRendererConfig();
  null_argv_config.entrypoint_argc = 1;
  null_argv_config.entrypoint_argv = nullptr;
  EXPECT_EQ(
      FlutterEngineSpawn(engine.get(), &null_argv_config, &spawned_engine),
      kInvalidArguments);

  // Entrypoint argc > 0 with null element in argv.
  const char* null_elem_argv[] = {nullptr};
  FlutterEngineSpawnConfig null_elem_argv_config = {};
  null_elem_argv_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  null_elem_argv_config.renderer_config = &context.GetRendererConfig();
  null_elem_argv_config.entrypoint_argc = 1;
  null_elem_argv_config.entrypoint_argv = null_elem_argv;
  EXPECT_EQ(
      FlutterEngineSpawn(engine.get(), &null_elem_argv_config, &spawned_engine),
      kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderSpawnInheritsParentRendererConfig) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // `FlutterEngineSpawnConfig::renderer_config` is documented as optional: a
  // null value means the spawned engine inherits the parent's renderer
  // configuration.
  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = nullptr;

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(FlutterEngineSpawn(engine.get(), &spawn_config, &spawned_engine),
            kSuccess);
  ASSERT_NE(spawned_engine, nullptr);

  UniqueEngine unique_spawned(spawned_engine);
}

TEST_F(EmbedderTest, EmbedderSpawnDirect) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  latch.Wait();

  EmbedderTestContextSoftware context_spawned;
  EmbedderConfigBuilder spawn_builder(context_spawned);
  spawn_builder.SetSurface(DlISize(1, 1));

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &context_spawned.GetRendererConfig();
  spawn_config.project_args = &spawn_builder.GetProjectArgs();

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(FlutterEngineSpawn(engine.get(), &spawn_config, &spawned_engine),
            kSuccess);
  ASSERT_NE(spawned_engine, nullptr);

  UniqueEngine unique_spawned(spawned_engine);

  // Send a window metrics event to the spawned engine.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 100;
  metrics.height = 100;
  metrics.pixel_ratio = 1.0;
  EXPECT_EQ(FlutterEngineSendWindowMetricsEvent(spawned_engine, &metrics),
            kSuccess);
}

TEST_F(EmbedderTest, EmbedderSpawnCustomEntrypointAndArgs) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  static fml::AutoResetWaitableEvent spawn_latch;
  auto entrypoint = []() { spawn_latch.Signal(); };
  context.AddFfiNativeCallback("SayHiFromCustomEntrypoint",
                               reinterpret_cast<void*>(+entrypoint));
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  EmbedderTestContextSoftware context_spawned;
  EmbedderConfigBuilder spawn_builder(context_spawned);
  spawn_builder.SetSurface(DlISize(1, 1));

  const char* argv[] = {"test_arg1"};
  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.entrypoint = "customEntrypoint";
  spawn_config.entrypoint_argc = 1;
  spawn_config.entrypoint_argv = argv;
  spawn_config.engine_id = 42;
  spawn_config.renderer_config = &context_spawned.GetRendererConfig();
  spawn_config.project_args = &spawn_builder.GetProjectArgs();

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(FlutterEngineSpawn(engine.get(), &spawn_config, &spawned_engine),
            kSuccess);
  ASSERT_NE(spawned_engine, nullptr);
  spawn_latch.Wait();

  UniqueEngine unique_spawned(spawned_engine);
}

TEST_F(EmbedderTest, EmbedderSpawnCustomAssetResolver) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  EmbedderTestContextSoftware context_spawned;
  EmbedderConfigBuilder spawn_builder(context_spawned);
  spawn_builder.SetSurface(DlISize(1, 1));

  bool find_asset_called = false;
  FlutterAssetResolver resolver = {};
  resolver.struct_size = sizeof(FlutterAssetResolver);
  resolver.user_data = &find_asset_called;
  resolver.find_asset_callback = [](void* user_data, const char* name,
                                    FlutterAsset* asset_out) -> bool {
    *reinterpret_cast<bool*>(user_data) = true;
    return false;
  };

  const FlutterAssetResolver* resolvers[] = {&resolver};
  spawn_builder.GetProjectArgs().asset_resolvers = resolvers;
  spawn_builder.GetProjectArgs().asset_resolvers_count = 1;

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &context_spawned.GetRendererConfig();
  spawn_config.project_args = &spawn_builder.GetProjectArgs();

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(FlutterEngineSpawn(engine.get(), &spawn_config, &spawned_engine),
            kSuccess);
  ASSERT_NE(spawned_engine, nullptr);

  UniqueEngine unique_spawned(spawned_engine);
}

TEST_F(EmbedderTest, EmbedderSpawnIndependentShutdown) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto parent_engine = builder.LaunchEngine();
  ASSERT_TRUE(parent_engine.is_valid());

  EmbedderTestContextSoftware context_spawned;
  EmbedderConfigBuilder spawn_builder(context_spawned);
  spawn_builder.SetSurface(DlISize(1, 1));

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &context_spawned.GetRendererConfig();
  spawn_config.project_args = &spawn_builder.GetProjectArgs();

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(
      FlutterEngineSpawn(parent_engine.get(), &spawn_config, &spawned_engine),
      kSuccess);
  ASSERT_NE(spawned_engine, nullptr);

  // Shutdown parent engine first while spawned engine remains running.
  parent_engine.reset();

  // Verify spawned engine can still handle events without crashing.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 200;
  metrics.height = 200;
  metrics.pixel_ratio = 1.0;
  EXPECT_EQ(FlutterEngineSendWindowMetricsEvent(spawned_engine, &metrics),
            kSuccess);

  // Shutdown spawned engine cleanly.
  EXPECT_EQ(FlutterEngineShutdown(spawned_engine), kSuccess);
}

TEST_F(EmbedderTest, EmbedderSpawnChildFirstShutdown) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto parent_engine = builder.LaunchEngine();
  ASSERT_TRUE(parent_engine.is_valid());

  EmbedderTestContextSoftware context_spawned;
  EmbedderConfigBuilder spawn_builder(context_spawned);
  spawn_builder.SetSurface(DlISize(1, 1));

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &context_spawned.GetRendererConfig();
  spawn_config.project_args = &spawn_builder.GetProjectArgs();

  FlutterEngine spawned_engine = nullptr;
  ASSERT_EQ(
      FlutterEngineSpawn(parent_engine.get(), &spawn_config, &spawned_engine),
      kSuccess);
  ASSERT_NE(spawned_engine, nullptr);

  // Shutdown spawned engine first while parent engine remains running.
  EXPECT_EQ(FlutterEngineShutdown(spawned_engine), kSuccess);

  // Verify parent engine can still handle events without crashing.
  FlutterWindowMetricsEvent metrics = {};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 200;
  metrics.height = 200;
  metrics.pixel_ratio = 1.0;
  EXPECT_EQ(FlutterEngineSendWindowMetricsEvent(parent_engine.get(), &metrics),
            kSuccess);

  // Shutdown parent engine cleanly.
  parent_engine.reset();
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesSpawn) {
  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  EXPECT_EQ(FlutterEngineGetProcAddresses(&procs), kSuccess);
  EXPECT_EQ(procs.Spawn, &FlutterEngineSpawn);
}

TEST_F(EmbedderTest, EmbedderLoadDartDeferredLibraryInvalidArguments) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Null engine.
  FlutterDartDeferredLibrary valid_lib = {};
  valid_lib.struct_size = sizeof(FlutterDartDeferredLibrary);
  const uint8_t dummy_data[] = {0x01, 0x02};
  valid_lib.data = dummy_data;
  valid_lib.data_size = sizeof(dummy_data);
  EXPECT_EQ(FlutterEngineLoadDartDeferredLibrary(nullptr, &valid_lib),
            kInvalidArguments);

  // Null deferred library.
  EXPECT_EQ(FlutterEngineLoadDartDeferredLibrary(engine.get(), nullptr),
            kInvalidArguments);

  // Invalid struct_size.
  FlutterDartDeferredLibrary invalid_size_lib = {};
  invalid_size_lib.struct_size = sizeof(FlutterDartDeferredLibrary) - 1;
  invalid_size_lib.data = dummy_data;
  invalid_size_lib.data_size = sizeof(dummy_data);
  EXPECT_EQ(
      FlutterEngineLoadDartDeferredLibrary(engine.get(), &invalid_size_lib),
      kInvalidArguments);

  // Missing data and instructions.
  FlutterDartDeferredLibrary empty_lib = {};
  empty_lib.struct_size = sizeof(FlutterDartDeferredLibrary);
  empty_lib.loading_unit_id = 1;
  empty_lib.data = nullptr;
  empty_lib.instructions = nullptr;
  EXPECT_EQ(FlutterEngineLoadDartDeferredLibrary(engine.get(), &empty_lib),
            kInvalidArguments);
}

TEST_F(EmbedderTest,
       EmbedderNotifyDartDeferredLibraryLoadErrorInvalidArguments) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterDartDeferredLibraryLoadError valid_error = {};
  valid_error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  valid_error.loading_unit_id = 1;
  valid_error.error_message = "Test error";
  valid_error.transient = true;

  // Null engine.
  EXPECT_EQ(
      FlutterEngineNotifyDartDeferredLibraryLoadError(nullptr, &valid_error),
      kInvalidArguments);

  // Null error.
  EXPECT_EQ(
      FlutterEngineNotifyDartDeferredLibraryLoadError(engine.get(), nullptr),
      kInvalidArguments);

  // Invalid struct_size.
  FlutterDartDeferredLibraryLoadError invalid_size_error = {};
  invalid_size_error.struct_size =
      sizeof(FlutterDartDeferredLibraryLoadError) - 1;
  invalid_size_error.loading_unit_id = 1;
  invalid_size_error.error_message = "Test error";
  EXPECT_EQ(FlutterEngineNotifyDartDeferredLibraryLoadError(
                engine.get(), &invalid_size_error),
            kInvalidArguments);

  // Null error message.
  FlutterDartDeferredLibraryLoadError null_msg_error = {};
  null_msg_error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  null_msg_error.loading_unit_id = 1;
  null_msg_error.error_message = nullptr;
  EXPECT_EQ(FlutterEngineNotifyDartDeferredLibraryLoadError(engine.get(),
                                                            &null_msg_error),
            kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderLoadDartDeferredLibraryDirect) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  bool destruction_called = false;
  const uint8_t dummy_data[] = {0x00, 0x01, 0x02, 0x03};
  const uint8_t dummy_instructions[] = {0x10, 0x11, 0x12, 0x13};

  FlutterDartDeferredLibrary deferred_library = {};
  deferred_library.struct_size = sizeof(FlutterDartDeferredLibrary);
  deferred_library.loading_unit_id = 42;
  deferred_library.data = dummy_data;
  deferred_library.data_size = sizeof(dummy_data);
  deferred_library.instructions = dummy_instructions;
  deferred_library.instructions_size = sizeof(dummy_instructions);
  deferred_library.user_data = &destruction_called;
  deferred_library.destruction_callback = [](void* user_data) {
    *reinterpret_cast<bool*>(user_data) = true;
  };

  EXPECT_EQ(
      FlutterEngineLoadDartDeferredLibrary(engine.get(), &deferred_library),
      kSuccess);

  // Mappings are retained while engine is running.
  EXPECT_FALSE(destruction_called);

  // Shutdown engine to release snapshot mappings and trigger destruction
  // callback.
  engine.reset();
  EXPECT_TRUE(destruction_called);
}

TEST_F(EmbedderTest, EmbedderNotifyDartDeferredLibraryLoadErrorDirect) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterDartDeferredLibraryLoadError error = {};
  error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  error.loading_unit_id = 99;
  error.error_message = "Module failed to download from network.";
  error.transient = true;

  EXPECT_EQ(
      FlutterEngineNotifyDartDeferredLibraryLoadError(engine.get(), &error),
      kSuccess);
}

TEST_F(EmbedderTest, EmbedderDartDeferredLibraryRequestCallback) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  struct CallbackPayload {
    int64_t loading_unit_id = -1;
    void* user_data = nullptr;
  };

  CallbackPayload payload;
  EmbedderConfigBuilder builder(
      context, EmbedderConfigBuilder::InitializationPreference::kNoInitialize);
  builder.SetAssetsPath();
  builder.SetSnapshots();
  builder.SetSurface(DlISize(1, 1));
  builder.GetProjectArgs().platform_message_callback = nullptr;
  builder.GetProjectArgs().dart_deferred_library_loader_callback =
      [](int64_t loading_unit_id, void* user_data) {
        auto* data = reinterpret_cast<CallbackPayload*>(user_data);
        data->loading_unit_id = loading_unit_id;
        data->user_data = user_data;
      };

  FlutterEngine engine = nullptr;
  auto renderer_config = context.GetRendererConfig();
  auto project_args = builder.GetProjectArgs();
  ASSERT_EQ(FlutterEngineInitialize(FLUTTER_ENGINE_VERSION, &renderer_config,
                                    &project_args, &payload, &engine),
            kSuccess);
  ASSERT_EQ(FlutterEngineRunInitialized(engine), kSuccess);

  flutter::Shell& shell = ToEmbedderEngine(engine)->GetShell();
  shell.GetPlatformView()->RequestDartDeferredLibrary(77);

  EXPECT_EQ(payload.loading_unit_id, 77);
  EXPECT_EQ(payload.user_data, &payload);

  EXPECT_EQ(FlutterEngineShutdown(engine), kSuccess);
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesDeferredLibrary) {
  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  EXPECT_EQ(FlutterEngineGetProcAddresses(&procs), kSuccess);
  EXPECT_EQ(procs.LoadDartDeferredLibrary,
            &FlutterEngineLoadDartDeferredLibrary);
  EXPECT_EQ(procs.NotifyDartDeferredLibraryLoadError,
            &FlutterEngineNotifyDartDeferredLibraryLoadError);
}

TEST_F(EmbedderTest, EmbedderNotifyCreatedInvalidArguments) {
  EXPECT_EQ(FlutterEngineNotifyCreated(nullptr), kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderNotifyDestroyedInvalidArguments) {
  EXPECT_EQ(FlutterEngineNotifyDestroyed(nullptr), kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderNotifyCreatedAndDestroyedDirect) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  EXPECT_EQ(FlutterEngineNotifyDestroyed(engine.get()), kSuccess);
  EXPECT_EQ(FlutterEngineNotifyCreated(engine.get()), kSuccess);
}

TEST_F(EmbedderTest, EmbedderRasterContextSetupAndTeardownCallbacks) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  struct RasterContextState {
    int setup_count = 0;
    int teardown_count = 0;
  };

  RasterContextState state;
  EmbedderConfigBuilder builder(
      context, EmbedderConfigBuilder::InitializationPreference::kNoInitialize);
  builder.SetAssetsPath();
  builder.SetSnapshots();
  builder.SetSurface(DlISize(1, 1));
  builder.GetProjectArgs().platform_message_callback = nullptr;
  builder.GetProjectArgs().raster_context_setup_callback = [](void* user_data) {
    auto* s = reinterpret_cast<RasterContextState*>(user_data);
    s->setup_count++;
  };
  builder.GetProjectArgs().raster_context_teardown_callback =
      [](void* user_data) {
        auto* s = reinterpret_cast<RasterContextState*>(user_data);
        s->teardown_count++;
      };

  FlutterEngine engine = nullptr;
  auto renderer_config = context.GetRendererConfig();
  auto project_args = builder.GetProjectArgs();
  ASSERT_EQ(FlutterEngineInitialize(FLUTTER_ENGINE_VERSION, &renderer_config,
                                    &project_args, &state, &engine),
            kSuccess);
  ASSERT_EQ(FlutterEngineRunInitialized(engine), kSuccess);

  // Initial engine start should have triggered setup callback once.
  EXPECT_EQ(state.setup_count, 1);
  EXPECT_EQ(state.teardown_count, 0);

  // Destroying surface should trigger teardown callback.
  EXPECT_EQ(FlutterEngineNotifyDestroyed(engine), kSuccess);
  EXPECT_EQ(state.setup_count, 1);
  EXPECT_EQ(state.teardown_count, 1);

  // Recreating surface should trigger setup callback.
  EXPECT_EQ(FlutterEngineNotifyCreated(engine), kSuccess);
  EXPECT_EQ(state.setup_count, 2);
  EXPECT_EQ(state.teardown_count, 1);

  // Engine shutdown triggers final teardown callback.
  EXPECT_EQ(FlutterEngineShutdown(engine), kSuccess);
  EXPECT_EQ(state.setup_count, 2);
  EXPECT_EQ(state.teardown_count, 2);
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesRasterContext) {
  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  EXPECT_EQ(FlutterEngineGetProcAddresses(&procs), kSuccess);
  EXPECT_EQ(procs.NotifyCreated, &FlutterEngineNotifyCreated);
  EXPECT_EQ(procs.NotifyDestroyed, &FlutterEngineNotifyDestroyed);
}

TEST_F(EmbedderTest, EmbedderSemanticsNode2ExtendedFieldsDirect) {
  SemanticsNode node;
  node.id = 42;
  node.label = "Submit Form";
  node.hint = "Double tap to submit";
  node.value = "Active";
  node.increasedValue = "More";
  node.decreasedValue = "Less";
  node.tooltip = "Submission Tooltip";
  node.identifier = "submit_button_unique_id";
  node.headingLevel = 2;
  node.textDirection = 2;  // LTR
  node.maxValueLength = 100;
  node.currentValueLength = 25;
  node.traversalParent = 10;
  node.minValue = "1.0";
  node.maxValue = "10.0";
  node.linkUrl = "https://flutter.dev";
  node.role = SemanticsRole::kTab;
  node.validationResult = SemanticsValidationResult::kValid;
  node.locale = "en-US";
  node.rect = SkRect::MakeXYWH(10.0f, 20.0f, 100.0f, 50.0f);
  node.transform = SkM44(1.0f, 0.0f, 0.0f, 15.0f,         //
                         0.0f, 1.0f, 0.0f, 25.0f,         //
                         0.0f, 0.0f, 1.0f, 0.0f,          //
                         0.0f, 0.0f, 0.0f, 1.0f);         //
  node.hitTestTransform = SkM44(2.0f, 0.0f, 0.0f, 30.0f,  //
                                0.0f, 2.0f, 0.0f, 50.0f,  //
                                0.0f, 0.0f, 1.0f, 0.0f,   //
                                0.0f, 0.0f, 0.0f, 1.0f);  //
  node.childrenInTraversalOrder = {43, 44};
  node.childrenInHitTestOrder = {44, 43};
  node.customAccessibilityActions = {101};

  CustomAccessibilityAction custom_action;
  custom_action.id = 101;
  custom_action.overrideId = -1;
  custom_action.label = "Custom Swipe";
  custom_action.hint = "Performs custom swipe";

  SemanticsNodeUpdates node_updates;
  node_updates[node.id] = node;

  CustomAccessibilityActionUpdates action_updates;
  action_updates[custom_action.id] = custom_action;

  const int64_t kTestViewId = 12345;
  EmbedderSemanticsUpdate2 update(kTestViewId, node_updates, action_updates);
  FlutterSemanticsUpdate2* raw_update = update.get();

  ASSERT_NE(raw_update, nullptr);
  EXPECT_EQ(raw_update->struct_size, sizeof(FlutterSemanticsUpdate2));
  EXPECT_EQ(raw_update->view_id, kTestViewId);
  EXPECT_EQ(raw_update->node_count, 1u);
  EXPECT_EQ(raw_update->custom_action_count, 1u);

  const FlutterSemanticsNode2* node2 = raw_update->nodes[0];
  ASSERT_NE(node2, nullptr);
  EXPECT_EQ(node2->struct_size, sizeof(FlutterSemanticsNode2));
  EXPECT_EQ(node2->id, 42);
  EXPECT_STREQ(node2->label, "Submit Form");
  EXPECT_STREQ(node2->hint, "Double tap to submit");
  EXPECT_STREQ(node2->value, "Active");
  EXPECT_STREQ(node2->increased_value, "More");
  EXPECT_STREQ(node2->decreased_value, "Less");
  EXPECT_STREQ(node2->tooltip, "Submission Tooltip");
  EXPECT_STREQ(node2->identifier, "submit_button_unique_id");
  EXPECT_EQ(node2->heading_level, 2);
  EXPECT_EQ(node2->text_direction, kFlutterTextDirectionLTR);
  EXPECT_EQ(node2->rect.left, 10.0);
  EXPECT_EQ(node2->rect.top, 20.0);
  EXPECT_EQ(node2->rect.right, 110.0);
  EXPECT_EQ(node2->rect.bottom, 70.0);

  // Extended semantics fields
  EXPECT_EQ(node2->max_value_length, 100);
  EXPECT_EQ(node2->current_value_length, 25);
  EXPECT_EQ(node2->traversal_parent, 10);
  EXPECT_STREQ(node2->min_value, "1.0");
  EXPECT_STREQ(node2->max_value, "10.0");
  EXPECT_STREQ(node2->link_url, "https://flutter.dev");
  EXPECT_EQ(node2->role, kFlutterSemanticsRoleTab);
  EXPECT_EQ(node2->validation_result, kFlutterSemanticsValidationResultValid);
  EXPECT_STREQ(node2->locale, "en-US");

  // Transform check
  EXPECT_DOUBLE_EQ(node2->transform.scaleX, 1.0);
  EXPECT_DOUBLE_EQ(node2->transform.transX, 15.0);
  EXPECT_DOUBLE_EQ(node2->transform.scaleY, 1.0);
  EXPECT_DOUBLE_EQ(node2->transform.transY, 25.0);

  // Hit test transform check
  EXPECT_DOUBLE_EQ(node2->hit_test_transform.scaleX, 2.0);
  EXPECT_DOUBLE_EQ(node2->hit_test_transform.transX, 30.0);
  EXPECT_DOUBLE_EQ(node2->hit_test_transform.scaleY, 2.0);
  EXPECT_DOUBLE_EQ(node2->hit_test_transform.transY, 50.0);

  // Children order
  EXPECT_EQ(node2->child_count, 2u);
  EXPECT_EQ(node2->children_in_traversal_order[0], 43);
  EXPECT_EQ(node2->children_in_traversal_order[1], 44);
  EXPECT_EQ(node2->children_in_hit_test_order[0], 44);
  EXPECT_EQ(node2->children_in_hit_test_order[1], 43);

  // Custom actions
  EXPECT_EQ(node2->custom_accessibility_actions_count, 1u);
  EXPECT_EQ(node2->custom_accessibility_actions[0], 101);

  const FlutterSemanticsCustomAction2* action2 = raw_update->custom_actions[0];
  ASSERT_NE(action2, nullptr);
  EXPECT_EQ(action2->struct_size, sizeof(FlutterSemanticsCustomAction2));
  EXPECT_EQ(action2->id, 101);
  // The engine forwards the framework's "no override action" sentinel (-1)
  // verbatim, so the expected value is deliberately out of the enum's range.
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  EXPECT_EQ(action2->override_action, static_cast<FlutterSemanticsAction>(-1));
  EXPECT_STREQ(action2->label, "Custom Swipe");
  EXPECT_STREQ(action2->hint, "Performs custom swipe");
}

TEST_F(EmbedderTest, EmbedderSemanticsNode2DefaultValues) {
  SemanticsNode node;
  node.id = 1;

  SemanticsNodeUpdates node_updates;
  node_updates[node.id] = node;

  CustomAccessibilityActionUpdates action_updates;

  EmbedderSemanticsUpdate2 update(0, node_updates, action_updates);
  FlutterSemanticsUpdate2* raw_update = update.get();

  ASSERT_NE(raw_update, nullptr);
  EXPECT_EQ(raw_update->node_count, 1u);
  const FlutterSemanticsNode2* node2 = raw_update->nodes[0];
  ASSERT_NE(node2, nullptr);
  EXPECT_EQ(node2->struct_size, sizeof(FlutterSemanticsNode2));
  EXPECT_EQ(node2->max_value_length, -1);
  EXPECT_EQ(node2->current_value_length, -1);
  EXPECT_EQ(node2->traversal_parent, 0);
  EXPECT_STREQ(node2->min_value, "");
  EXPECT_STREQ(node2->max_value, "");
  EXPECT_STREQ(node2->link_url, "");
  EXPECT_EQ(node2->role, kFlutterSemanticsRoleNone);
  EXPECT_EQ(node2->validation_result, kFlutterSemanticsValidationResultNone);
  EXPECT_STREQ(node2->locale, "");
}

TEST_F(EmbedderTest, EmbedderSemanticsNode2StringAttributes) {
  SemanticsNode node;
  node.id = 1;
  node.label = "Spell out this text";

  auto locale_attr = std::make_shared<LocaleStringAttribute>();
  locale_attr->start = 0;
  locale_attr->end = 5;
  locale_attr->type = StringAttributeType::kLocale;
  locale_attr->locale = "en-GB";

  auto spell_out_attr = std::make_shared<SpellOutStringAttribute>();
  spell_out_attr->start = 6;
  spell_out_attr->end = 9;
  spell_out_attr->type = StringAttributeType::kSpellOut;

  node.labelAttributes = {locale_attr, spell_out_attr};

  SemanticsNodeUpdates node_updates;
  node_updates[node.id] = node;
  CustomAccessibilityActionUpdates action_updates;

  EmbedderSemanticsUpdate2 update(0, node_updates, action_updates);
  FlutterSemanticsUpdate2* raw_update = update.get();

  ASSERT_NE(raw_update, nullptr);
  ASSERT_EQ(raw_update->node_count, 1u);
  const FlutterSemanticsNode2* node2 = raw_update->nodes[0];
  ASSERT_NE(node2, nullptr);
  EXPECT_EQ(node2->label_attribute_count, 2u);
  ASSERT_NE(node2->label_attributes, nullptr);

  const FlutterStringAttribute* attr0 = node2->label_attributes[0];
  ASSERT_NE(attr0, nullptr);
  EXPECT_EQ(attr0->struct_size, sizeof(FlutterStringAttribute));
  EXPECT_EQ(attr0->start, 0u);
  EXPECT_EQ(attr0->end, 5u);
  EXPECT_EQ(attr0->type, FlutterStringAttributeType::kLocale);
  ASSERT_NE(attr0->locale, nullptr);
  EXPECT_EQ(attr0->locale->struct_size, sizeof(FlutterLocaleStringAttribute));
  EXPECT_STREQ(attr0->locale->locale, "en-GB");

  const FlutterStringAttribute* attr1 = node2->label_attributes[1];
  ASSERT_NE(attr1, nullptr);
  EXPECT_EQ(attr1->struct_size, sizeof(FlutterStringAttribute));
  EXPECT_EQ(attr1->start, 6u);
  EXPECT_EQ(attr1->end, 9u);
  EXPECT_EQ(attr1->type, FlutterStringAttributeType::kSpellOut);
  ASSERT_NE(attr1->spell_out, nullptr);
  EXPECT_EQ(attr1->spell_out->struct_size,
            sizeof(FlutterSpellOutStringAttribute));
}

TEST_F(EmbedderTest, EmbedderSendSemanticsActionValidation) {
  EXPECT_EQ(FlutterEngineSendSemanticsAction(nullptr, nullptr),
            kInvalidArguments);

  FlutterSendSemanticsActionInfo info = {};
  info.struct_size = sizeof(FlutterSendSemanticsActionInfo);
  info.node_id = 0;
  info.action = kFlutterSemanticsActionTap;

  EXPECT_EQ(FlutterEngineSendSemanticsAction(nullptr, &info),
            kInvalidArguments);

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterSendSemanticsActionInfo invalid_size_info = {};
  invalid_size_info.struct_size = sizeof(FlutterSendSemanticsActionInfo) - 1;
  EXPECT_EQ(FlutterEngineSendSemanticsAction(engine.get(), &invalid_size_info),
            kInvalidArguments);

  FlutterSendSemanticsActionInfo null_data_with_length = {};
  null_data_with_length.struct_size = sizeof(FlutterSendSemanticsActionInfo);
  null_data_with_length.node_id = 0;
  null_data_with_length.action = kFlutterSemanticsActionTap;
  null_data_with_length.data = nullptr;
  null_data_with_length.data_length = 16;
  EXPECT_EQ(
      FlutterEngineSendSemanticsAction(engine.get(), &null_data_with_length),
      kInvalidArguments);

  EXPECT_EQ(FlutterEngineSendSemanticsAction(engine.get(), &info), kSuccess);

  uint8_t payload[] = {0x01, 0x02, 0x03, 0x04};
  FlutterSendSemanticsActionInfo data_info = {};
  data_info.struct_size = sizeof(FlutterSendSemanticsActionInfo);
  data_info.node_id = 0;
  data_info.action = kFlutterSemanticsActionSetSelection;
  data_info.data = payload;
  data_info.data_length = sizeof(payload);
  EXPECT_EQ(FlutterEngineSendSemanticsAction(engine.get(), &data_info),
            kSuccess);
}

TEST_F(EmbedderTest, EmbedderScreenshotInvalidArguments) {
  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = kFlutterScreenshotTypeUncompressedImage;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);

  EXPECT_EQ(FlutterEngineScreenshot(nullptr, &request, &screenshot),
            kInvalidArguments);
  EXPECT_EQ(FlutterEngineScreenshot(nullptr, nullptr, &screenshot),
            kInvalidArguments);

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  EXPECT_EQ(FlutterEngineScreenshot(engine.get(), nullptr, &screenshot),
            kInvalidArguments);

  FlutterScreenshotRequest invalid_request_size = {};
  invalid_request_size.struct_size = sizeof(FlutterScreenshotRequest) - 1;
  invalid_request_size.type = kFlutterScreenshotTypeUncompressedImage;
  EXPECT_EQ(
      FlutterEngineScreenshot(engine.get(), &invalid_request_size, &screenshot),
      kInvalidArguments);

  FlutterScreenshotRequest invalid_request_type = {};
  invalid_request_type.struct_size = sizeof(FlutterScreenshotRequest);
  // The out-of-range cast is intentional: this test exercises the engine's
  // validation of a screenshot type it does not know about.
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  invalid_request_type.type = static_cast<FlutterScreenshotType>(999);
  EXPECT_EQ(
      FlutterEngineScreenshot(engine.get(), &invalid_request_type, &screenshot),
      kInvalidArguments);

  EXPECT_EQ(FlutterEngineScreenshot(engine.get(), &request, nullptr),
            kInvalidArguments);

  FlutterScreenshot invalid_screenshot_size = {};
  invalid_screenshot_size.struct_size = sizeof(FlutterScreenshot) - 1;
  EXPECT_EQ(
      FlutterEngineScreenshot(engine.get(), &request, &invalid_screenshot_size),
      kInvalidArguments);

  EXPECT_EQ(FlutterEngineFreeScreenshot(nullptr), kInvalidArguments);

  FlutterScreenshot invalid_free_size = {};
  invalid_free_size.struct_size = sizeof(FlutterScreenshot) - 1;
  EXPECT_EQ(FlutterEngineFreeScreenshot(&invalid_free_size), kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderScreenshotBeforeRender) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = kFlutterScreenshotTypeUncompressedImage;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);

  EXPECT_EQ(FlutterEngineScreenshot(engine.get(), &request, &screenshot),
            kInternalInconsistency);
}

TEST_F(EmbedderTest, EmbedderScreenshotUncompressed) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("draw_solid_red");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  fml::AutoResetWaitableEvent callback_latch;
  VoidCallback callback = [](void* user_data) {
    auto* latch = static_cast<fml::AutoResetWaitableEvent*>(user_data);
    latch->Signal();
  };

  ASSERT_EQ(FlutterEngineSetNextFrameCallback(engine.get(), callback,
                                              &callback_latch),
            kSuccess);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  callback_latch.Wait();

  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = kFlutterScreenshotTypeUncompressedImage;
  request.base64_encode = false;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);

  ASSERT_EQ(FlutterEngineScreenshot(engine.get(), &request, &screenshot),
            kSuccess);
  EXPECT_NE(screenshot.data, nullptr);
  EXPECT_GT(screenshot.data_length, 0u);
  EXPECT_EQ(screenshot.width, 800u);
  EXPECT_EQ(screenshot.height, 600u);
  EXPECT_NE(screenshot.format_description, nullptr);
  EXPECT_NE(screenshot.destruction_callback, nullptr);

  EXPECT_EQ(FlutterEngineFreeScreenshot(&screenshot), kSuccess);
  EXPECT_EQ(screenshot.data, nullptr);
  EXPECT_EQ(screenshot.data_length, 0u);
  EXPECT_EQ(screenshot.format_description, nullptr);
  EXPECT_EQ(screenshot.destruction_callback, nullptr);

  // Calling free again safely no-ops.
  EXPECT_EQ(FlutterEngineFreeScreenshot(&screenshot), kSuccess);
}

TEST_F(EmbedderTest, EmbedderScreenshotCompressedPng) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("draw_solid_red");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  fml::AutoResetWaitableEvent callback_latch;
  VoidCallback callback = [](void* user_data) {
    auto* latch = static_cast<fml::AutoResetWaitableEvent*>(user_data);
    latch->Signal();
  };

  ASSERT_EQ(FlutterEngineSetNextFrameCallback(engine.get(), callback,
                                              &callback_latch),
            kSuccess);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 400;
  event.height = 300;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  callback_latch.Wait();

  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = kFlutterScreenshotTypeCompressedImage;
  request.base64_encode = false;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);

  ASSERT_EQ(FlutterEngineScreenshot(engine.get(), &request, &screenshot),
            kSuccess);
  ASSERT_NE(screenshot.data, nullptr);
  ASSERT_GT(screenshot.data_length, 8u);
  EXPECT_EQ(screenshot.width, 400u);
  EXPECT_EQ(screenshot.height, 300u);

  // Verify PNG magic header: 0x89 'P' 'N' 'G' 0x0D 0x0A 0x1A 0x0A
  EXPECT_EQ(screenshot.data[0], 0x89);
  EXPECT_EQ(screenshot.data[1], 'P');
  EXPECT_EQ(screenshot.data[2], 'N');
  EXPECT_EQ(screenshot.data[3], 'G');
  EXPECT_EQ(screenshot.data[4], 0x0D);
  EXPECT_EQ(screenshot.data[5], 0x0A);
  EXPECT_EQ(screenshot.data[6], 0x1A);
  EXPECT_EQ(screenshot.data[7], 0x0A);

  ASSERT_NE(screenshot.destruction_callback, nullptr);
  screenshot.destruction_callback(screenshot.user_data);
}

TEST_F(EmbedderTest, EmbedderScreenshotBase64Encoded) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.SetDartEntrypoint("draw_solid_red");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  fml::AutoResetWaitableEvent callback_latch;
  VoidCallback callback = [](void* user_data) {
    auto* latch = static_cast<fml::AutoResetWaitableEvent*>(user_data);
    latch->Signal();
  };

  ASSERT_EQ(FlutterEngineSetNextFrameCallback(engine.get(), callback,
                                              &callback_latch),
            kSuccess);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 100;
  event.height = 100;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  callback_latch.Wait();

  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = kFlutterScreenshotTypeCompressedImage;
  request.base64_encode = true;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);

  ASSERT_EQ(FlutterEngineScreenshot(engine.get(), &request, &screenshot),
            kSuccess);
  ASSERT_NE(screenshot.data, nullptr);
  EXPECT_GT(screenshot.data_length, 0u);

  EXPECT_EQ(FlutterEngineFreeScreenshot(&screenshot), kSuccess);
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesScreenshot) {
  FlutterEngineProcTable table = {};
  table.struct_size = sizeof(FlutterEngineProcTable);

  ASSERT_EQ(FlutterEngineGetProcAddresses(&table), kSuccess);
  EXPECT_EQ(table.Screenshot, &FlutterEngineScreenshot);
  EXPECT_EQ(table.FreeScreenshot, &FlutterEngineFreeScreenshot);
}

TEST_F(EmbedderTest, EmbedderCallbackInformationInvalidArguments) {
  EXPECT_EQ(FlutterEngineGetCallbackInformation(42, nullptr),
            kInvalidArguments);

  FlutterCallbackInformation invalid_size_info = {};
  invalid_size_info.struct_size = sizeof(FlutterCallbackInformation) - 1;
  EXPECT_EQ(FlutterEngineGetCallbackInformation(42, &invalid_size_info),
            kInvalidArguments);

  EXPECT_EQ(FlutterEngineSetCallbackCachePath(nullptr), kInvalidArguments);

  int64_t handle = 0;
  EXPECT_EQ(FlutterEngineGetCallbackHandle(nullptr, &handle),
            kInvalidArguments);

  FlutterCallbackInformation null_name_info = {};
  null_name_info.struct_size = sizeof(FlutterCallbackInformation);
  null_name_info.name = nullptr;
  null_name_info.library_path = "lib.dart";
  EXPECT_EQ(FlutterEngineGetCallbackHandle(&null_name_info, &handle),
            kInvalidArguments);

  FlutterCallbackInformation null_lib_info = {};
  null_lib_info.struct_size = sizeof(FlutterCallbackInformation);
  null_lib_info.name = "name";
  null_lib_info.library_path = nullptr;
  EXPECT_EQ(FlutterEngineGetCallbackHandle(&null_lib_info, &handle),
            kInvalidArguments);

  FlutterCallbackInformation valid_info = {};
  valid_info.struct_size = sizeof(FlutterCallbackInformation);
  valid_info.name = "name";
  valid_info.library_path = "lib.dart";
  EXPECT_EQ(FlutterEngineGetCallbackHandle(&valid_info, nullptr),
            kInvalidArguments);

  FlutterCallbackInformation invalid_get_handle_size = {};
  invalid_get_handle_size.struct_size = sizeof(FlutterCallbackInformation) - 1;
  invalid_get_handle_size.name = "name";
  invalid_get_handle_size.library_path = "lib.dart";
  EXPECT_EQ(FlutterEngineGetCallbackHandle(&invalid_get_handle_size, &handle),
            kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderCallbackInformationNotFound) {
  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);

  EXPECT_EQ(FlutterEngineGetCallbackInformation(999999999999LL, &info),
            kInternalInconsistency);
}

TEST_F(EmbedderTest, EmbedderCallbackInformationTopLevelFunction) {
  FlutterCallbackInformation reg_info = {};
  reg_info.struct_size = sizeof(FlutterCallbackInformation);
  reg_info.name = "myCallback";
  reg_info.class_name = nullptr;
  reg_info.library_path = "package:my_app/main.dart";

  int64_t handle = 0;
  ASSERT_EQ(FlutterEngineGetCallbackHandle(&reg_info, &handle), kSuccess);
  EXPECT_NE(handle, 0);

  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  ASSERT_EQ(FlutterEngineGetCallbackInformation(handle, &info), kSuccess);
  EXPECT_EQ(info.struct_size, sizeof(FlutterCallbackInformation));
  EXPECT_STREQ(info.name, "myCallback");
  EXPECT_EQ(info.class_name, nullptr);
  EXPECT_STREQ(info.library_path, "package:my_app/main.dart");
}

TEST_F(EmbedderTest, EmbedderCallbackInformationStaticMethod) {
  FlutterCallbackInformation reg_info = {};
  reg_info.struct_size = sizeof(FlutterCallbackInformation);
  reg_info.name = "onNotification";
  reg_info.class_name = "MyPlugin";
  reg_info.library_path = "package:my_plugin/my_plugin.dart";

  int64_t handle = 0;
  ASSERT_EQ(FlutterEngineGetCallbackHandle(&reg_info, &handle), kSuccess);
  EXPECT_NE(handle, 0);

  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  ASSERT_EQ(FlutterEngineGetCallbackInformation(handle, &info), kSuccess);
  EXPECT_EQ(info.struct_size, sizeof(FlutterCallbackInformation));
  EXPECT_STREQ(info.name, "onNotification");
  EXPECT_STREQ(info.class_name, "MyPlugin");
  EXPECT_STREQ(info.library_path, "package:my_plugin/my_plugin.dart");
}

TEST_F(EmbedderTest, EmbedderCallbackCacheDiskPersistence) {
  fml::ScopedTemporaryDirectory temp_dir;
  ASSERT_TRUE(temp_dir.fd().is_valid());

  ASSERT_EQ(FlutterEngineSetCallbackCachePath(temp_dir.path().c_str()),
            kSuccess);

  FlutterCallbackInformation reg_info = {};
  reg_info.struct_size = sizeof(FlutterCallbackInformation);
  reg_info.name = "persistedCallback";
  reg_info.class_name = "PersistedClass";
  reg_info.library_path = "package:test/test.dart";

  int64_t handle = 0;
  ASSERT_EQ(FlutterEngineGetCallbackHandle(&reg_info, &handle), kSuccess);
  EXPECT_NE(handle, 0);

  // Verify that the callback cache JSON was saved to the specified disk path.
  std::string cache_file =
      fml::paths::JoinPaths({temp_dir.path(), "flutter_callback_cache.json"});
  EXPECT_TRUE(fml::IsFile(cache_file));

  ASSERT_EQ(FlutterEngineLoadCallbackCache(), kSuccess);

  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  ASSERT_EQ(FlutterEngineGetCallbackInformation(handle, &info), kSuccess);
  EXPECT_STREQ(info.name, "persistedCallback");
  EXPECT_STREQ(info.class_name, "PersistedClass");
  EXPECT_STREQ(info.library_path, "package:test/test.dart");
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesCallbackInformation) {
  FlutterEngineProcTable table = {};
  table.struct_size = sizeof(FlutterEngineProcTable);

  ASSERT_EQ(FlutterEngineGetProcAddresses(&table), kSuccess);
  EXPECT_EQ(table.GetCallbackInformation, &FlutterEngineGetCallbackInformation);
  EXPECT_EQ(table.SetCallbackCachePath, &FlutterEngineSetCallbackCachePath);
  EXPECT_EQ(table.LoadCallbackCache, &FlutterEngineLoadCallbackCache);
  EXPECT_EQ(table.GetCallbackHandle, &FlutterEngineGetCallbackHandle);
}

TEST_F(EmbedderTest, EmbedderPlatformViewMutationsClipRoundSuperellipse) {
  MutatorsStack stack;
  stack.PushClipRSE(DlRoundSuperellipse::MakeRectXY(
      DlRect::MakeLTRB(10.0f, 20.0f, 110.0f, 120.0f), DlSize(8.0f, 12.0f)));

  EmbeddedViewParams params(DlMatrix(), DlSize(100.0f, 100.0f), stack);
  EmbedderLayers layers(DlISize(800, 600), 1.0, DlMatrix(), 0);
  layers.PushPlatformViewLayer(42, params);

  bool callback_invoked = false;
  layers.InvokePresentCallback(0, [&](FlutterViewId view_id,
                                      const std::vector<const FlutterLayer*>&
                                          presented_layers) {
    callback_invoked = true;
    EXPECT_EQ(view_id, 0);
    EXPECT_EQ(presented_layers.size(), 1u);
    const auto* layer = presented_layers[0];
    EXPECT_NE(layer, nullptr);
    EXPECT_EQ(layer->type, kFlutterLayerContentTypePlatformView);
    const auto* view = layer->platform_view;
    EXPECT_NE(view, nullptr);
    EXPECT_EQ(view->identifier, 42);
    EXPECT_EQ(view->mutations_count, 1u);
    const auto* mutation = view->mutations[0];
    EXPECT_NE(mutation, nullptr);
    EXPECT_EQ(mutation->type,
              kFlutterPlatformViewMutationTypeClipRoundSuperellipse);
    EXPECT_DOUBLE_EQ(mutation->clip_round_superellipse.rect.left, 10.0);
    EXPECT_DOUBLE_EQ(mutation->clip_round_superellipse.rect.top, 20.0);
    EXPECT_DOUBLE_EQ(mutation->clip_round_superellipse.rect.right, 110.0);
    EXPECT_DOUBLE_EQ(mutation->clip_round_superellipse.rect.bottom, 120.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.upper_left_corner_radius.width, 8.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.upper_left_corner_radius.height,
        12.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.upper_right_corner_radius.width, 8.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.upper_right_corner_radius.height,
        12.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.lower_right_corner_radius.width, 8.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.lower_right_corner_radius.height,
        12.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.lower_left_corner_radius.width, 8.0);
    EXPECT_DOUBLE_EQ(
        mutation->clip_round_superellipse.lower_left_corner_radius.height,
        12.0);
    return true;
  });
  EXPECT_TRUE(callback_invoked);
}

TEST_F(EmbedderTest, EmbedderPlatformViewMutationsClipPathLinearAndCurves) {
  SkPathBuilder builder;
  builder.moveTo(10.0f, 20.0f);
  builder.lineTo(30.0f, 40.0f);
  builder.quadTo(50.0f, 60.0f, 70.0f, 80.0f);
  builder.conicTo(90.0f, 100.0f, 110.0f, 120.0f, 0.75f);
  builder.cubicTo(130.0f, 140.0f, 150.0f, 160.0f, 170.0f, 180.0f);
  builder.close();
  DlPath dl_path(builder.detach());

  MutatorsStack stack;
  stack.PushClipPath(dl_path);

  EmbeddedViewParams params(DlMatrix(), DlSize(200.0f, 200.0f), stack);
  EmbedderLayers layers(DlISize(800, 600), 1.0, DlMatrix(), 0);
  layers.PushPlatformViewLayer(101, params);

  bool callback_invoked = false;
  layers.InvokePresentCallback(
      0, [&](FlutterViewId view_id,
             const std::vector<const FlutterLayer*>& presented_layers) {
        callback_invoked = true;
        EXPECT_EQ(view_id, 0);
        EXPECT_EQ(presented_layers.size(), 1u);
        const auto* layer = presented_layers[0];
        EXPECT_NE(layer, nullptr);
        EXPECT_EQ(layer->type, kFlutterLayerContentTypePlatformView);
        const auto* view = layer->platform_view;
        EXPECT_NE(view, nullptr);
        EXPECT_EQ(view->identifier, 101);
        EXPECT_EQ(view->mutations_count, 1u);
        const auto* mutation = view->mutations[0];
        EXPECT_NE(mutation, nullptr);
        EXPECT_EQ(mutation->type, kFlutterPlatformViewMutationTypeClipPath);
        EXPECT_EQ(mutation->clip_path.struct_size, sizeof(FlutterPath));
        EXPECT_EQ(mutation->clip_path.fill_type, kFlutterPathFillTypeNonZero);
        EXPECT_EQ(mutation->clip_path.segments_count, 7u);
        EXPECT_NE(mutation->clip_path.segments, nullptr);

        if (mutation->clip_path.segments_count >= 7) {
          // Segment 0: MoveTo (10, 20)
          EXPECT_EQ(mutation->clip_path.segments[0].verb, kFlutterPathVerbMove);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[0].points[0].x, 10.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[0].points[0].y, 20.0);

          // Segment 1: LineTo (30, 40)
          EXPECT_EQ(mutation->clip_path.segments[1].verb, kFlutterPathVerbLine);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[1].points[0].x, 30.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[1].points[0].y, 40.0);

          // Segment 2: QuadTo (50, 60, 70, 80)
          EXPECT_EQ(mutation->clip_path.segments[2].verb, kFlutterPathVerbQuad);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[2].points[0].x, 50.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[2].points[0].y, 60.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[2].points[1].x, 70.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[2].points[1].y, 80.0);

          // Segment 3: ConicTo (90, 100, 110, 120, weight=0.75)
          EXPECT_EQ(mutation->clip_path.segments[3].verb,
                    kFlutterPathVerbConic);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[3].points[0].x, 90.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[3].points[0].y, 100.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[3].points[1].x, 110.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[3].points[1].y, 120.0);
          EXPECT_NEAR(mutation->clip_path.segments[3].conic_weight, 0.75, 1e-4);

          // Segment 4: CubicTo (130, 140, 150, 160, 170, 180)
          EXPECT_EQ(mutation->clip_path.segments[4].verb,
                    kFlutterPathVerbCubic);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[0].x, 130.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[0].y, 140.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[1].x, 150.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[1].y, 160.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[2].x, 170.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[4].points[2].y, 180.0);

          // Segment 5: LineTo (10, 20) (closing line)
          EXPECT_EQ(mutation->clip_path.segments[5].verb, kFlutterPathVerbLine);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[5].points[0].x, 10.0);
          EXPECT_DOUBLE_EQ(mutation->clip_path.segments[5].points[0].y, 20.0);

          // Segment 6: Close
          EXPECT_EQ(mutation->clip_path.segments[6].verb,
                    kFlutterPathVerbClose);
        }
        return true;
      });
  EXPECT_TRUE(callback_invoked);
}

TEST_F(EmbedderTest, EmbedderPlatformViewMutationsClipPathEvenOddFillType) {
  SkPathBuilder builder;
  builder.setFillType(SkPathFillType::kEvenOdd);
  builder.addRect(SkRect::MakeLTRB(0, 0, 50, 50));
  builder.addRect(SkRect::MakeLTRB(25, 25, 75, 75));
  DlPath dl_path(builder.detach());

  MutatorsStack stack;
  stack.PushClipPath(dl_path);

  EmbeddedViewParams params(DlMatrix(), DlSize(100.0f, 100.0f), stack);
  EmbedderLayers layers(DlISize(800, 600), 1.0, DlMatrix(), 0);
  layers.PushPlatformViewLayer(102, params);

  bool callback_invoked = false;
  layers.InvokePresentCallback(
      0, [&](FlutterViewId view_id,
             const std::vector<const FlutterLayer*>& presented_layers) {
        callback_invoked = true;
        EXPECT_EQ(presented_layers.size(), 1u);
        const auto* view = presented_layers[0]->platform_view;
        EXPECT_NE(view, nullptr);
        EXPECT_EQ(view->mutations_count, 1u);
        const auto* mutation = view->mutations[0];
        EXPECT_NE(mutation, nullptr);
        EXPECT_EQ(mutation->type, kFlutterPlatformViewMutationTypeClipPath);
        EXPECT_EQ(mutation->clip_path.fill_type, kFlutterPathFillTypeEvenOdd);
        EXPECT_GT(mutation->clip_path.segments_count, 0u);
        return true;
      });
  EXPECT_TRUE(callback_invoked);
}

TEST_F(EmbedderTest, EmbedderPlatformViewMutationsClipPathEmpty) {
  DlPath dl_path;
  MutatorsStack stack;
  stack.PushClipPath(dl_path);

  EmbeddedViewParams params(DlMatrix(), DlSize(100.0f, 100.0f), stack);
  EmbedderLayers layers(DlISize(800, 600), 1.0, DlMatrix(), 0);
  layers.PushPlatformViewLayer(103, params);

  bool callback_invoked = false;
  layers.InvokePresentCallback(
      0, [&](FlutterViewId view_id,
             const std::vector<const FlutterLayer*>& presented_layers) {
        callback_invoked = true;
        EXPECT_EQ(presented_layers.size(), 1u);
        const auto* view = presented_layers[0]->platform_view;
        EXPECT_NE(view, nullptr);
        EXPECT_EQ(view->mutations_count, 1u);
        const auto* mutation = view->mutations[0];
        EXPECT_NE(mutation, nullptr);
        EXPECT_EQ(mutation->type, kFlutterPlatformViewMutationTypeClipPath);
        EXPECT_EQ(mutation->clip_path.struct_size, sizeof(FlutterPath));
        EXPECT_EQ(mutation->clip_path.segments_count, 0u);
        EXPECT_EQ(mutation->clip_path.segments, nullptr);
        return true;
      });
  EXPECT_TRUE(callback_invoked);
}

TEST_F(EmbedderTest, EmbedderPlatformViewMutationsComplexMixedStack) {
  MutatorsStack stack;
  stack.PushTransform(DlMatrix::MakeScale({2.0f, 2.0f, 1.0f}));
  stack.PushClipRect(DlRect::MakeLTRB(5.0f, 5.0f, 50.0f, 50.0f));
  stack.PushClipRRect(DlRoundRect::MakeRectXY(
      DlRect::MakeLTRB(10.0f, 10.0f, 40.0f, 40.0f), 4.0f, 4.0f));
  stack.PushClipRSE(DlRoundSuperellipse::MakeRectXY(
      DlRect::MakeLTRB(15.0f, 15.0f, 35.0f, 35.0f), DlSize(3.0f, 3.0f)));
  stack.PushClipPath(
      DlPath::MakeRect(DlRect::MakeLTRB(20.0f, 20.0f, 30.0f, 30.0f)));
  stack.PushOpacity(128);

  EmbeddedViewParams params(DlMatrix(), DlSize(100.0f, 100.0f), stack);
  EmbedderLayers layers(DlISize(800, 600), 1.0, DlMatrix(), 0);
  layers.PushPlatformViewLayer(200, params);

  bool callback_invoked = false;
  layers.InvokePresentCallback(
      0, [&](FlutterViewId view_id,
             const std::vector<const FlutterLayer*>& presented_layers) {
        callback_invoked = true;
        EXPECT_EQ(presented_layers.size(), 1u);
        const auto* view = presented_layers[0]->platform_view;
        EXPECT_NE(view, nullptr);
        EXPECT_EQ(view->identifier, 200);
        EXPECT_EQ(view->mutations_count, 6u);

        EXPECT_EQ(view->mutations[0]->type,
                  kFlutterPlatformViewMutationTypeTransformation);
        EXPECT_EQ(view->mutations[1]->type,
                  kFlutterPlatformViewMutationTypeClipRect);
        EXPECT_EQ(view->mutations[2]->type,
                  kFlutterPlatformViewMutationTypeClipRoundedRect);
        EXPECT_EQ(view->mutations[3]->type,
                  kFlutterPlatformViewMutationTypeClipRoundSuperellipse);
        EXPECT_EQ(view->mutations[4]->type,
                  kFlutterPlatformViewMutationTypeClipPath);
        EXPECT_EQ(view->mutations[5]->type,
                  kFlutterPlatformViewMutationTypeOpacity);
        return true;
      });
  EXPECT_TRUE(callback_invoked);
}

TEST_F(EmbedderTest, EmbedderRegisterImageGeneratorInvalidArguments) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterImageGeneratorRegistrationInfo info = {};
  info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
  info.create_generator = [](const uint8_t*, size_t, void*,
                             FlutterImageGenerator*) -> bool { return false; };

  // Null engine.
  EXPECT_EQ(FlutterEngineRegisterImageGenerator(nullptr, &info),
            kInvalidArguments);

  // Null info.
  EXPECT_EQ(FlutterEngineRegisterImageGenerator(engine.get(), nullptr),
            kInvalidArguments);

  // Invalid struct_size.
  FlutterImageGeneratorRegistrationInfo invalid_size_info = info;
  invalid_size_info.struct_size =
      sizeof(FlutterImageGeneratorRegistrationInfo) - 1;
  EXPECT_EQ(
      FlutterEngineRegisterImageGenerator(engine.get(), &invalid_size_info),
      kInvalidArguments);

  // Null create_generator callback.
  FlutterImageGeneratorRegistrationInfo null_callback_info = info;
  null_callback_info.create_generator = nullptr;
  EXPECT_EQ(
      FlutterEngineRegisterImageGenerator(engine.get(), &null_callback_info),
      kInvalidArguments);

  // Engine not in running state.
  EXPECT_EQ(FlutterEngineRegisterImageGenerator(engine.get(), &info),
            kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderImageGeneratorDirectSingleFrame) {
  struct TestContext {
    uint32_t width = 64;
    uint32_t height = 48;
    bool destruction_called = false;
  };

  TestContext ctx;
  FlutterImageGenerator generator = {};
  generator.struct_size = sizeof(FlutterImageGenerator);
  generator.user_data = &ctx;
  generator.destruction_callback = [](void* user_data) {
    static_cast<TestContext*>(user_data)->destruction_called = true;
  };
  generator.get_info = [](void* user_data,
                          FlutterImageGeneratorInfo* info_out) -> bool {
    auto* c = static_cast<TestContext*>(user_data);
    info_out->width = c->width;
    info_out->height = c->height;
    info_out->color_type = kFlutterImageGeneratorColorTypeRGBA8888;
    info_out->alpha_type = kFlutterImageGeneratorAlphaTypePremul;
    return true;
  };
  generator.get_pixels =
      [](void* user_data, const FlutterImageGeneratorInfo* info, void* pixels,
         size_t row_bytes, uint32_t frame_index, int64_t prior_frame) -> bool {
    auto* c = static_cast<TestContext*>(user_data);
    EXPECT_EQ(info->width, c->width);
    EXPECT_EQ(info->height, c->height);
    EXPECT_EQ(frame_index, 0u);
    EXPECT_EQ(prior_frame, -1);
    auto* byte_ptr = static_cast<uint8_t*>(pixels);
    for (size_t y = 0; y < info->height; ++y) {
      uint8_t* row = byte_ptr + (y * row_bytes);
      for (size_t x = 0; x < info->width; ++x) {
        row[x * 4 + 0] = 0x11;
        row[x * 4 + 1] = 0x22;
        row[x * 4 + 2] = 0x33;
        row[x * 4 + 3] = 0x44;
      }
    }
    return true;
  };
  generator.get_scaled_dimensions = [](void* user_data, float scale,
                                       uint32_t* scaled_width_out,
                                       uint32_t* scaled_height_out) -> bool {
    auto* c = static_cast<TestContext*>(user_data);
    *scaled_width_out = static_cast<uint32_t>(c->width * scale);
    *scaled_height_out = static_cast<uint32_t>(c->height * scale);
    return true;
  };

  {
    auto img_gen = MakeEmbedderImageGenerator(generator);
    ASSERT_NE(img_gen, nullptr);

    EXPECT_EQ(img_gen->GetInfo().width(), 64);
    EXPECT_EQ(img_gen->GetInfo().height(), 48);
    EXPECT_EQ(img_gen->GetInfo().colorType(), kRGBA_8888_SkColorType);
    EXPECT_EQ(img_gen->GetInfo().alphaType(), kPremul_SkAlphaType);

    EXPECT_EQ(img_gen->GetFrameCount(), 1u);
    EXPECT_EQ(img_gen->GetPlayCount(), 1u);

    auto frame_info = img_gen->GetFrameInfo(0);
    EXPECT_EQ(frame_info.duration, 0u);
    EXPECT_EQ(frame_info.disposal_method,
              SkCodecAnimation::DisposalMethod::kKeep);
    EXPECT_FALSE(frame_info.required_frame.has_value());
    EXPECT_FALSE(frame_info.disposal_rect.has_value());
    EXPECT_EQ(frame_info.blend_mode, SkCodecAnimation::Blend::kSrcOver);

    SkISize scaled = img_gen->GetScaledDimensions(0.5f);
    EXPECT_EQ(scaled.width(), 32);
    EXPECT_EQ(scaled.height(), 24);

    std::vector<uint8_t> pixel_buffer(64 * 48 * 4, 0);
    EXPECT_TRUE(img_gen->GetPixels(img_gen->GetInfo(), pixel_buffer.data(),
                                   64 * 4, 0, std::nullopt));
    EXPECT_EQ(pixel_buffer[0], 0x11);
    EXPECT_EQ(pixel_buffer[1], 0x22);
    EXPECT_EQ(pixel_buffer[2], 0x33);
    EXPECT_EQ(pixel_buffer[3], 0x44);

    EXPECT_FALSE(ctx.destruction_called);
  }

  EXPECT_TRUE(ctx.destruction_called);
}

TEST_F(EmbedderTest, EmbedderImageGeneratorAnimatedMultiFrame) {
  struct MultiFrameContext {
    uint32_t width = 32;
    uint32_t height = 32;
    uint32_t decoded_frame = 0;
  };

  MultiFrameContext ctx;
  FlutterImageGenerator generator = {};
  generator.struct_size = sizeof(FlutterImageGenerator);
  generator.user_data = &ctx;
  generator.get_info = [](void* user_data,
                          FlutterImageGeneratorInfo* info_out) -> bool {
    auto* c = static_cast<MultiFrameContext*>(user_data);
    info_out->width = c->width;
    info_out->height = c->height;
    info_out->color_type = kFlutterImageGeneratorColorTypeRGBA8888;
    info_out->alpha_type = kFlutterImageGeneratorAlphaTypePremul;
    return true;
  };
  generator.get_frame_count = [](void*) -> uint32_t { return 3; };
  generator.get_play_count = [](void*) -> uint32_t {
    return 0;
  };  // Infinite loop
  generator.get_frame_info =
      [](void*, uint32_t frame_index,
         FlutterImageGeneratorFrameInfo* frame_info_out) -> bool {
    if (frame_index == 0) {
      frame_info_out->required_frame = -1;
      frame_info_out->duration_ms = 100;
      frame_info_out->disposal_method =
          kFlutterImageGeneratorDisposalMethodKeep;
      frame_info_out->has_disposal_rect = false;
      frame_info_out->blend_mode = kFlutterImageGeneratorBlendModeSrcOver;
      return true;
    } else if (frame_index == 1) {
      frame_info_out->required_frame = 0;
      frame_info_out->duration_ms = 200;
      frame_info_out->disposal_method =
          kFlutterImageGeneratorDisposalMethodRestoreBackground;
      frame_info_out->has_disposal_rect = true;
      frame_info_out->disposal_rect = {
          .left = 5.0, .top = 5.0, .right = 25.0, .bottom = 25.0};
      frame_info_out->blend_mode = kFlutterImageGeneratorBlendModeSrc;
      return true;
    } else if (frame_index == 2) {
      frame_info_out->required_frame = 1;
      frame_info_out->duration_ms = 150;
      frame_info_out->disposal_method =
          kFlutterImageGeneratorDisposalMethodRestorePrevious;
      frame_info_out->has_disposal_rect = false;
      frame_info_out->blend_mode = kFlutterImageGeneratorBlendModeSrcOver;
      return true;
    }
    return false;
  };
  generator.get_pixels =
      [](void* user_data, const FlutterImageGeneratorInfo* info, void* pixels,
         size_t row_bytes, uint32_t frame_index, int64_t prior_frame) -> bool {
    auto* c = static_cast<MultiFrameContext*>(user_data);
    c->decoded_frame = frame_index;
    auto* byte_ptr = static_cast<uint8_t*>(pixels);
    std::memset(byte_ptr, static_cast<int>(frame_index + 1),
                info->height * row_bytes);
    return true;
  };

  auto img_gen = MakeEmbedderImageGenerator(generator);
  ASSERT_NE(img_gen, nullptr);

  EXPECT_EQ(img_gen->GetFrameCount(), 3u);
  EXPECT_EQ(img_gen->GetPlayCount(), ImageGenerator::kInfinitePlayCount);

  auto f0 = img_gen->GetFrameInfo(0);
  EXPECT_EQ(f0.duration, 100u);
  EXPECT_EQ(f0.disposal_method, SkCodecAnimation::DisposalMethod::kKeep);
  EXPECT_FALSE(f0.required_frame.has_value());
  EXPECT_FALSE(f0.disposal_rect.has_value());
  EXPECT_EQ(f0.blend_mode, SkCodecAnimation::Blend::kSrcOver);

  auto f1 = img_gen->GetFrameInfo(1);
  EXPECT_EQ(f1.duration, 200u);
  EXPECT_EQ(f1.disposal_method,
            SkCodecAnimation::DisposalMethod::kRestoreBGColor);
  ASSERT_TRUE(f1.required_frame.has_value());
  EXPECT_EQ(f1.required_frame.value(), 0u);
  ASSERT_TRUE(f1.disposal_rect.has_value());
  EXPECT_EQ(f1.disposal_rect.value(), SkIRect::MakeLTRB(5, 5, 25, 25));
  EXPECT_EQ(f1.blend_mode, SkCodecAnimation::Blend::kSrc);

  auto f2 = img_gen->GetFrameInfo(2);
  EXPECT_EQ(f2.duration, 150u);
  EXPECT_EQ(f2.disposal_method,
            SkCodecAnimation::DisposalMethod::kRestorePrevious);
  ASSERT_TRUE(f2.required_frame.has_value());
  EXPECT_EQ(f2.required_frame.value(), 1u);
  EXPECT_FALSE(f2.disposal_rect.has_value());
  EXPECT_EQ(f2.blend_mode, SkCodecAnimation::Blend::kSrcOver);

  std::vector<uint8_t> buffer(32 * 32 * 4);
  EXPECT_TRUE(
      img_gen->GetPixels(img_gen->GetInfo(), buffer.data(), 32 * 4, 1, 0));
  EXPECT_EQ(ctx.decoded_frame, 1u);
  EXPECT_EQ(buffer[0], 2);
}

TEST_F(EmbedderTest, EmbedderImageGeneratorDestructionCallbacks) {
  struct LifecycleContext {
    bool factory_destroyed = false;
    bool generator_destroyed = false;
  };

  LifecycleContext ctx;

  {
    FlutterImageGeneratorRegistrationInfo reg_info = {};
    reg_info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
    reg_info.user_data = &ctx;
    reg_info.destruction_callback = [](void* user_data) {
      static_cast<LifecycleContext*>(user_data)->factory_destroyed = true;
    };
    reg_info.create_generator =
        [](const uint8_t* buffer, size_t size, void* user_data,
           FlutterImageGenerator* generator_out) -> bool {
      generator_out->struct_size = sizeof(FlutterImageGenerator);
      generator_out->user_data = user_data;
      generator_out->destruction_callback = [](void* ud) {
        static_cast<LifecycleContext*>(ud)->generator_destroyed = true;
      };
      generator_out->get_info =
          [](void*, FlutterImageGeneratorInfo* info_out) -> bool {
        info_out->width = 16;
        info_out->height = 16;
        info_out->color_type = kFlutterImageGeneratorColorTypeRGBA8888;
        info_out->alpha_type = kFlutterImageGeneratorAlphaTypePremul;
        return true;
      };
      generator_out->get_pixels = [](void*, const FlutterImageGeneratorInfo*,
                                     void*, size_t, uint32_t,
                                     int64_t) -> bool { return true; };
      return true;
    };

    ImageGeneratorFactory factory =
        CreateEmbedderImageGeneratorFactory(reg_info);
    ASSERT_TRUE(factory);

    const uint8_t dummy_data[] = {0x01, 0x02, 0x03};
    sk_sp<SkData> data = SkData::MakeWithCopy(dummy_data, sizeof(dummy_data));

    {
      std::shared_ptr<ImageGenerator> gen = factory(data);
      ASSERT_NE(gen, nullptr);
      EXPECT_FALSE(ctx.generator_destroyed);
    }
    EXPECT_TRUE(ctx.generator_destroyed);
    EXPECT_FALSE(ctx.factory_destroyed);
  }

  EXPECT_TRUE(ctx.factory_destroyed);
}

TEST_F(EmbedderTest, EmbedderCustomImageGeneratorInProjectArgs) {
  FlutterImageGeneratorRegistrationInfo reg_info = {};
  reg_info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
  reg_info.priority = 10;
  reg_info.create_generator = [](const uint8_t*, size_t, void*,
                                 FlutterImageGenerator*) -> bool {
    return false;
  };

  const FlutterImageGeneratorRegistrationInfo* image_generators[] = {&reg_info};

  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  builder.GetProjectArgs().image_generators = image_generators;
  builder.GetProjectArgs().image_generators_count = 1;
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());

  EXPECT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
}

TEST_F(EmbedderTest, EmbedderRegisterImageGeneratorDynamic) {
  auto& context = GetEmbedderContext<EmbedderTestContextSoftware>();
  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1, 1));
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());

  EXPECT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);

  FlutterImageGeneratorRegistrationInfo reg_info = {};
  reg_info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
  reg_info.priority = 5;
  reg_info.create_generator = [](const uint8_t*, size_t, void*,
                                 FlutterImageGenerator*) -> bool {
    return false;
  };

  EXPECT_EQ(FlutterEngineRegisterImageGenerator(engine.get(), &reg_info),
            kSuccess);
}

TEST_F(EmbedderTest, EmbedderImageGeneratorDestructionCallbackNullUserData) {
  static bool g_factory_destroyed = false;
  static bool g_generator_destroyed = false;
  g_factory_destroyed = false;
  g_generator_destroyed = false;

  {
    FlutterImageGeneratorRegistrationInfo reg_info = {};
    reg_info.struct_size = sizeof(FlutterImageGeneratorRegistrationInfo);
    reg_info.user_data = nullptr;
    reg_info.destruction_callback = [](void* user_data) {
      EXPECT_EQ(user_data, nullptr);
      g_factory_destroyed = true;
    };
    reg_info.create_generator =
        [](const uint8_t* buffer, size_t size, void* user_data,
           FlutterImageGenerator* generator_out) -> bool {
      generator_out->struct_size = sizeof(FlutterImageGenerator);
      generator_out->user_data = nullptr;
      generator_out->destruction_callback = [](void* ud) {
        EXPECT_EQ(ud, nullptr);
        g_generator_destroyed = true;
      };
      generator_out->get_info =
          [](void*, FlutterImageGeneratorInfo* info_out) -> bool {
        info_out->width = 16;
        info_out->height = 16;
        info_out->color_type = kFlutterImageGeneratorColorTypeRGBA8888;
        info_out->alpha_type = kFlutterImageGeneratorAlphaTypePremul;
        return true;
      };
      generator_out->get_pixels = [](void*, const FlutterImageGeneratorInfo*,
                                     void*, size_t, uint32_t,
                                     int64_t) -> bool { return true; };
      return true;
    };

    ImageGeneratorFactory factory =
        CreateEmbedderImageGeneratorFactory(reg_info);
    ASSERT_TRUE(factory);

    const uint8_t dummy_data[] = {0x01, 0x02, 0x03};
    sk_sp<SkData> data = SkData::MakeWithCopy(dummy_data, sizeof(dummy_data));

    {
      std::shared_ptr<ImageGenerator> gen = factory(data);
      ASSERT_NE(gen, nullptr);
      EXPECT_FALSE(g_generator_destroyed);
    }
    EXPECT_TRUE(g_generator_destroyed);
    EXPECT_FALSE(g_factory_destroyed);
  }

  EXPECT_TRUE(g_factory_destroyed);
}

TEST_F(EmbedderTest, EmbedderImageGeneratorDimensionOverflow) {
  FlutterImageGenerator generator = {};
  generator.struct_size = sizeof(FlutterImageGenerator);
  generator.get_info = [](void*, FlutterImageGeneratorInfo* info_out) -> bool {
    info_out->width =
        static_cast<uint32_t>(std::numeric_limits<int32_t>::max()) + 100u;
    info_out->height = 100;
    info_out->color_type = kFlutterImageGeneratorColorTypeRGBA8888;
    info_out->alpha_type = kFlutterImageGeneratorAlphaTypePremul;
    return true;
  };
  generator.get_pixels = [](void*, const FlutterImageGeneratorInfo*, void*,
                            size_t, uint32_t,
                            int64_t) -> bool { return false; };

  auto img_gen = MakeEmbedderImageGenerator(generator);
  EXPECT_EQ(img_gen, nullptr);
}

TEST_F(EmbedderTest, EmbedderPrefetchDefaultFontManager) {
  EXPECT_EQ(FlutterEnginePrefetchDefaultFontManager(), kSuccess);
}

TEST_F(EmbedderTest, EmbedderVMServiceUriCallbackInvalidArguments) {
  intptr_t handle = 0;
  EXPECT_EQ(FlutterEngineRegisterVMServiceUriCallback(nullptr, &handle),
            kInvalidArguments);

  FlutterVMServiceUriCallbackConfig invalid_size_config = {};
  invalid_size_config.struct_size = sizeof(size_t) - 1;
  invalid_size_config.callback = [](const char*, void*) {};
  EXPECT_EQ(
      FlutterEngineRegisterVMServiceUriCallback(&invalid_size_config, &handle),
      kInvalidArguments);

  FlutterVMServiceUriCallbackConfig null_callback_config = {};
  null_callback_config.struct_size = sizeof(FlutterVMServiceUriCallbackConfig);
  null_callback_config.callback = nullptr;
  EXPECT_EQ(
      FlutterEngineRegisterVMServiceUriCallback(&null_callback_config, &handle),
      kInvalidArguments);

  EXPECT_EQ(FlutterEngineDeregisterVMServiceUriCallback(0), kInvalidArguments);
  EXPECT_EQ(FlutterEngineDeregisterVMServiceUriCallback(999999),
            kInvalidArguments);
}

TEST_F(EmbedderTest, EmbedderVMServiceUriCallbackLifecycle) {
  intptr_t handle = 0;
  int user_data_val = 42;
  FlutterVMServiceUriCallbackConfig config = {};
  config.struct_size = sizeof(FlutterVMServiceUriCallbackConfig);
  config.callback = [](const char* uri, void* user_data) {
    auto* val = static_cast<int*>(user_data);
    EXPECT_EQ(*val, 42);
  };
  config.user_data = &user_data_val;

  ASSERT_EQ(FlutterEngineRegisterVMServiceUriCallback(&config, &handle),
            kSuccess);
  EXPECT_NE(handle, 0);

  ASSERT_EQ(FlutterEngineDeregisterVMServiceUriCallback(handle), kSuccess);
  EXPECT_EQ(FlutterEngineDeregisterVMServiceUriCallback(handle),
            kInvalidArguments);

  // handle_out can be null if embedder doesn't need to deregister
  EXPECT_EQ(FlutterEngineRegisterVMServiceUriCallback(&config, nullptr),
            kSuccess);
}

TEST_F(EmbedderTest, EmbedderGetProcAddressesImageGenerator) {
  FlutterEngineProcTable table = {};
  table.struct_size = sizeof(FlutterEngineProcTable);

  ASSERT_EQ(FlutterEngineGetProcAddresses(&table), kSuccess);
  EXPECT_EQ(table.RegisterImageGenerator, &FlutterEngineRegisterImageGenerator);
  EXPECT_EQ(table.PrefetchDefaultFontManager,
            &FlutterEnginePrefetchDefaultFontManager);
  EXPECT_EQ(table.RegisterVMServiceUriCallback,
            &FlutterEngineRegisterVMServiceUriCallback);
  EXPECT_EQ(table.DeregisterVMServiceUriCallback,
            &FlutterEngineDeregisterVMServiceUriCallback);
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
