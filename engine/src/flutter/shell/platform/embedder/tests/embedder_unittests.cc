// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <string>
#include <utility>
#include <vector>

#include "embedder.h"
#include "embedder_engine.h"
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
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/assertions_skia.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/tonic/converter/dart_converter.h"

#if defined(FML_OS_MACOSX)
#include <pthread.h>
#endif

// CREATE_NATIVE_ENTRY is leaky by design
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
}

// TODO(41999): Disabled because flaky.
TEST_F(EmbedderTest, DISABLED_CanLaunchAndShutdownMultipleTimes) {
  EmbedderConfigBuilder builder(
      GetEmbedderContext(EmbedderTestContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
  for (size_t i = 0; i < 3; ++i) {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
    FML_LOG(INFO) << "Engine launch count: " << i + 1;
  }
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypoint) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  static fml::AutoResetWaitableEvent latch;
  Dart_NativeFunction entrypoint = [](Dart_NativeArguments args) {
    latch.Signal();
  };
  context.AddNativeCallback("SayHiFromCustomEntrypoint", entrypoint);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("customEntrypoint");
  auto engine = builder.LaunchEngine();
  latch.Wait();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypointMacro) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent latch3;

  // Can be defined separately.
  auto entry1 = [&latch1](Dart_NativeArguments args) {
    FML_LOG(INFO) << "In Callback 1";
    latch1.Signal();
  };
  auto native_entry1 = CREATE_NATIVE_ENTRY(entry1);
  context.AddNativeCallback("SayHiFromCustomEntrypoint1", native_entry1);

  // Can be wrapped in the args.
  auto entry2 = [&latch2](Dart_NativeArguments args) {
    FML_LOG(INFO) << "In Callback 2";
    latch2.Signal();
  };
  context.AddNativeCallback("SayHiFromCustomEntrypoint2",
                            CREATE_NATIVE_ENTRY(entry2));

  // Everything can be inline.
  context.AddNativeCallback(
      "SayHiFromCustomEntrypoint3",
      CREATE_NATIVE_ENTRY([&latch3](Dart_NativeArguments args) {
        FML_LOG(INFO) << "In Callback 3";
        latch3.Signal();
      }));

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("customEntrypoint1");
  auto engine = builder.LaunchEngine();
  latch1.Wait();
  latch2.Wait();
  latch3.Wait();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanTerminateCleanly) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("terminateExitCodeHandler");
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, ExecutableNameNotNull) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  // Supply a callback to Dart for the test fixture to pass Platform.executable
  // back to us.
  fml::AutoResetWaitableEvent latch;
  context.AddNativeCallback(
      "NotifyStringValue", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
        const auto dart_string = tonic::DartConverter<std::string>::FromDart(
            Dart_GetNativeArgument(args, 0));
        EXPECT_EQ("/path/to/binary", dart_string);
        latch.Signal();
      }));

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("executableNameNotNull");
  builder.SetExecutableName("/path/to/binary");
  auto engine = builder.LaunchEngine();
  latch.Wait();
}

TEST_F(EmbedderTest, ImplicitViewNotNull) {
  // TODO(loicsharma): Update this test when embedders can opt-out
  // of the implicit view.
  // See: https://github.com/flutter/flutter/issues/120306
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  bool implicitViewNotNull = false;
  fml::AutoResetWaitableEvent latch;
  context.AddNativeCallback(
      "NotifyBoolValue", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
        implicitViewNotNull = tonic::DartConverter<bool>::FromDart(
            Dart_GetNativeArgument(args, 0));
        latch.Signal();
      }));

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("implicitViewNotNull");
  auto engine = builder.LaunchEngine();
  latch.Wait();

  EXPECT_TRUE(implicitViewNotNull);
}

std::atomic_size_t EmbedderTestTaskRunner::sEmbedderTaskRunnerIdentifiers = {};

TEST_F(EmbedderTest, CanSpecifyCustomPlatformTaskRunner) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  fml::AutoResetWaitableEvent latch;

  // Run the test on its own thread with a message loop so that it can safely
  // pump its event loop while we wait for all the conditions to be checked.
  auto platform_task_runner = CreateNewThread("test_platform_thread");
  static std::mutex engine_mutex;
  static bool signaled_once = false;
  UniqueEngine engine;

  EmbedderTestTaskRunner test_task_runner(
      platform_task_runner, [&](FlutterTask task) {
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
      });

  platform_task_runner->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    const auto task_runner_description =
        test_task_runner.GetFlutterTaskRunnerDescription();
    builder.SetSoftwareRendererConfig();
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
}

TEST(EmbedderTestNoFixture, CanGetCurrentTimeInNanoseconds) {
  auto point1 = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(FlutterEngineGetCurrentTime()));
  auto point2 = fml::TimePoint::Now();

  ASSERT_LT((point2 - point1), fml::TimeDelta::FromMilliseconds(1));
}

TEST_F(EmbedderTest, CanReloadSystemFonts) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  auto result = FlutterEngineReloadSystemFonts(engine.get());
  ASSERT_EQ(result, kSuccess);
}

TEST_F(EmbedderTest, IsolateServiceIdSent) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  fml::AutoResetWaitableEvent latch;

  fml::Thread thread;
  UniqueEngine engine;
  std::string isolate_message;

  thread.GetTaskRunner()->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("platform_messages_response");
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY([](Dart_NativeArguments args) {}));

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
    auto& context =
        GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();
    builder.SetDartEntrypoint("platform_messages_response");

    fml::AutoResetWaitableEvent ready;
    context.AddNativeCallback(
        "SignalNativeTest",
        CREATE_NATIVE_ENTRY(
            [&ready](Dart_NativeArguments args) { ready.Signal(); }));

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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("platform_messages_no_response");

  const std::string message_data = "Hello but don't call me back.";

  fml::AutoResetWaitableEvent ready, message;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&ready](Dart_NativeArguments args) { ready.Signal(); }));
  context.AddNativeCallback(
      "SignalNativeMessage",
      CREATE_NATIVE_ENTRY(
          ([&message, &message_data](Dart_NativeArguments args) {
            auto received_message = tonic::DartConverter<std::string>::FromDart(
                Dart_GetNativeArgument(args, 0));
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("null_platform_messages");

  fml::AutoResetWaitableEvent ready, message;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&ready](Dart_NativeArguments args) { ready.Signal(); }));
  context.AddNativeCallback(
      "SignalNativeMessage",
      CREATE_NATIVE_ENTRY(([&message](Dart_NativeArguments args) {
        auto received_message = tonic::DartConverter<std::string>::FromDart(
            Dart_GetNativeArgument(args, 0));
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("custom_logger");
  builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("custom_logger");
  builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.AddDartEntrypointArgument("foo");
  builder.AddDartEntrypointArgument("bar");
  builder.SetDartEntrypoint("dart_entrypoint_args");
  fml::AutoResetWaitableEvent callback_latch;
  std::vector<std::string> callback_args;
  auto nativeArgumentsCallback = [&callback_args,
                                  &callback_latch](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    callback_args =
        tonic::DartConverter<std::vector<std::string>>::FromArguments(
            args, 0, exception);
    callback_latch.Signal();
  };
  context.AddNativeCallback("NativeArgumentsCallback",
                            CREATE_NATIVE_ENTRY(nativeArgumentsCallback));
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

  // The fixture sets this up correctly. Intentionally mess up the args.
  builder.GetProjectArgs().vm_snapshot_data_size = 0;
  builder.GetProjectArgs().vm_snapshot_instructions_size = 0;
  builder.GetProjectArgs().isolate_snapshot_data_size = 0;
  builder.GetProjectArgs().isolate_snapshot_instructions_size = 0;

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

//------------------------------------------------------------------------------
/// Test the layer structure and pixels rendered when using a custom software
/// compositor.
///
TEST_F(EmbedderTest,
       CompositorMustBeAbleToRenderKnownSceneWithSoftwareCompositor) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig(SkISize::Make(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_with_known_scene");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(5);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](const FlutterLayer** layers, size_t layers_count) {
        ASSERT_EQ(layers_count, 5u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&latch](Dart_NativeArguments args) { latch.CountDown(); }));

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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig(SkISize::Make(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_transparent_overlay");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(4);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](const FlutterLayer** layers, size_t layers_count) {
        ASSERT_EQ(layers_count, 2u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&latch](Dart_NativeArguments args) { latch.CountDown(); }));

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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig(SkISize::Make(800, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("can_composite_platform_views_no_overlay");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  fml::CountDownLatch latch(4);

  auto scene_image = context.GetNextSceneImage();

  context.GetCompositor().SetNextPresentCallback(
      [&](const FlutterLayer** layers, size_t layers_count) {
        ASSERT_EQ(layers_count, 2u);

        // Layer Root
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;
          backing_store.software.height = 600;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(800.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&latch](Dart_NativeArguments args) { latch.CountDown(); }));

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
  EmbedderConfigBuilder builder(
      GetEmbedderContext(EmbedderTestContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());
  engine.reset();
}

//------------------------------------------------------------------------------
/// Test that an initialized engine can be run exactly once.
///
TEST_F(EmbedderTest, CanRunInitializedEngine) {
  EmbedderConfigBuilder builder(
      GetEmbedderContext(EmbedderTestContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
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
  EmbedderConfigBuilder builder(
      GetEmbedderContext(EmbedderTestContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
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

TEST_F(EmbedderTest, CanUpdateLocales) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("can_receive_locale_updates");
  fml::AutoResetWaitableEvent latch;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&latch](Dart_NativeArguments args) { latch.Signal(); }));

  fml::AutoResetWaitableEvent check_latch;
  context.AddNativeCallback(
      "SignalNativeCount",
      CREATE_NATIVE_ENTRY([&check_latch](Dart_NativeArguments args) {
        ASSERT_EQ(tonic::DartConverter<int>::FromDart(
                      Dart_GetNativeArgument(args, 0)),
                  2);
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig(SkISize::Make(1024, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("verify_b143464703");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

  // setup the screenshot promise.
  auto rendered_scene = context.GetNextSceneImage();

  fml::CountDownLatch latch(1);
  context.GetCompositor().SetNextPresentCallback(
      [&](const FlutterLayer** layers, size_t layers_count) {
        ASSERT_EQ(layers_count, 3u);

        // Layer 0 (Root)
        {
          FlutterBackingStore backing_store = *layers[0]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(1024.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

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

        // Layer 2
        {
          FlutterBackingStore backing_store = *layers[2]->backing_store;
          backing_store.type = kFlutterBackingStoreTypeSoftware;
          backing_store.did_update = true;

          FlutterLayer layer = {};
          layer.struct_size = sizeof(layer);
          layer.type = kFlutterLayerContentTypeBackingStore;
          layer.backing_store = &backing_store;
          layer.size = FlutterSizeMake(1024.0, 600.0);
          layer.offset = FlutterPointMake(0.0, 0.0);

          ASSERT_EQ(*layers[2], layer);
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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
    auto& context =
        GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();

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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(
      context,
      EmbedderConfigBuilder::InitializationPreference::kMultiAOTInitialize);

  builder.SetSoftwareRendererConfig();

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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });

  EmbedderConfigBuilder builder(
      context,
      EmbedderConfigBuilder::InitializationPreference::kAOTDataInitialize);

  builder.SetSoftwareRendererConfig();

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
}

#if defined(__clang_analyzer__)
#define TEST_VM_SNAPSHOT_DATA nullptr
#define TEST_VM_SNAPSHOT_INSTRUCTIONS nullptr
#define TEST_ISOLATE_SNAPSHOT_DATA nullptr
#define TEST_ISOLATE_SNAPSHOT_INSTRUCTIONS nullptr
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
#endif  // OS_FUCHSIA

  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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
#endif  // OS_FUCHSIA

  // This test is only relevant in JIT mode.
  if (DartVM::IsRunningPrecompiledCode()) {
    GTEST_SKIP();
    return;
  }

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

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

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();

  ASSERT_EQ(builder.GetProjectArgs().vm_snapshot_data, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().vm_snapshot_instructions, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().isolate_snapshot_data, nullptr);
  ASSERT_EQ(builder.GetProjectArgs().isolate_snapshot_instructions, nullptr);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, InvalidFlutterWindowMetricsEvent) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
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

static void expectSoftwareRenderingOutputMatches(
    EmbedderTest& test,
    std::string entrypoint,
    FlutterSoftwarePixelFormat pixfmt,
    const std::vector<uint8_t>& bytes) {
  auto& context =
      test.GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  bool matches = false;

  builder.SetSoftwareRendererConfig();
  builder.SetCompositor();
  builder.SetDartEntrypoint(std::move(entrypoint));
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer2,
      pixfmt);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  context.GetCompositor().SetNextPresentCallback(
      [&matches, &bytes, &latch](const FlutterLayer** layers,
                                 size_t layers_count) {
        ASSERT_EQ(layers[0]->type, kFlutterLayerContentTypeBackingStore);
        ASSERT_EQ(layers[0]->backing_store->type,
                  kFlutterBackingStoreTypeSoftware2);
        matches = SurfacePixelDataMatchesBytes(
            static_cast<SkSurface*>(
                layers[0]->backing_store->software2.user_data),
            bytes);
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
FlutterKeyEventType UnserializeKeyEventKind(uint64_t kind) {
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

// Checks the equality of two `FlutterKeyEvent` by each of their members except
// for `character`. The `character` must be checked separately.
void ExpectKeyEventEq(const FlutterKeyEvent& subject,
                      const FlutterKeyEvent& baseline) {
  EXPECT_EQ(subject.timestamp, baseline.timestamp);
  EXPECT_EQ(subject.type, baseline.type);
  EXPECT_EQ(subject.physical, baseline.physical);
  EXPECT_EQ(subject.logical, baseline.logical);
  EXPECT_EQ(subject.synthesized, baseline.synthesized);
}

TEST_F(EmbedderTest, KeyDataIsCorrectlySerialized) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  uint64_t echoed_char;
  FlutterKeyEvent echoed_event;

  auto native_echo_event = [&](Dart_NativeArguments args) {
    echoed_event.type =
        UnserializeKeyEventKind(tonic::DartConverter<uint64_t>::FromDart(
            Dart_GetNativeArgument(args, 0)));
    echoed_event.timestamp =
        static_cast<double>(tonic::DartConverter<uint64_t>::FromDart(
            Dart_GetNativeArgument(args, 1)));
    echoed_event.physical = tonic::DartConverter<uint64_t>::FromDart(
        Dart_GetNativeArgument(args, 2));
    echoed_event.logical = tonic::DartConverter<uint64_t>::FromDart(
        Dart_GetNativeArgument(args, 3));
    echoed_char = tonic::DartConverter<uint64_t>::FromDart(
        Dart_GetNativeArgument(args, 4));
    echoed_event.synthesized =
        tonic::DartConverter<bool>::FromDart(Dart_GetNativeArgument(args, 5));

    message_latch->Signal();
  };

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("key_data_echo");
  fml::AutoResetWaitableEvent ready;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&ready](Dart_NativeArguments args) { ready.Signal(); }));

  context.AddNativeCallback("EchoKeyEvent",
                            CREATE_NATIVE_ENTRY(native_echo_event));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
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
  };
  FlutterEngineSendKeyEvent(engine.get(), &down_event_upper_a, nullptr,
                            nullptr);
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
  };
  FlutterEngineSendKeyEvent(engine.get(), &repeat_event_wide_char, nullptr,
                            nullptr);
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
  };
  FlutterEngineSendKeyEvent(engine.get(), &up_event, nullptr, nullptr);
  message_latch->Wait();

  ExpectKeyEventEq(echoed_event, up_event);
  EXPECT_EQ(echoed_char, 0llu);
}

TEST_F(EmbedderTest, KeyDataAreBuffered) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  std::vector<FlutterKeyEvent> echoed_events;

  auto native_echo_event = [&](Dart_NativeArguments args) {
    echoed_events.push_back(FlutterKeyEvent{
        .timestamp =
            static_cast<double>(tonic::DartConverter<uint64_t>::FromDart(
                Dart_GetNativeArgument(args, 1))),
        .type =
            UnserializeKeyEventKind(tonic::DartConverter<uint64_t>::FromDart(
                Dart_GetNativeArgument(args, 0))),
        .physical = tonic::DartConverter<uint64_t>::FromDart(
            Dart_GetNativeArgument(args, 2)),
        .logical = tonic::DartConverter<uint64_t>::FromDart(
            Dart_GetNativeArgument(args, 3)),
        .synthesized = tonic::DartConverter<bool>::FromDart(
            Dart_GetNativeArgument(args, 5)),
    });

    message_latch->Signal();
  };

  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("key_data_late_echo");
  fml::AutoResetWaitableEvent ready;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&ready](Dart_NativeArguments args) { ready.Signal(); }));

  context.AddNativeCallback("EchoKeyEvent",
                            CREATE_NATIVE_ENTRY(native_echo_event));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  ready.Wait();

  FlutterKeyEvent sample_event{
      .struct_size = sizeof(FlutterKeyEvent),
      .type = kFlutterKeyEventTypeDown,
      .physical = 0x00070004,
      .logical = 0x00000000061,
      .character = "A",
      .synthesized = false,
  };

  // Send an event.
  sample_event.timestamp = 1.0l;
  FlutterEngineSendKeyEvent(engine.get(), &sample_event, nullptr, nullptr);

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

  FlutterEngineResult result =
      FlutterEngineSendPlatformMessage(engine.get(), &message);
  ASSERT_EQ(result, kSuccess);

  FlutterPlatformMessageReleaseResponseHandle(engine.get(), response_handle);

  // message_latch->Wait();
  message_latch->Wait();
  // All previous events should be received now.
  EXPECT_EQ(echoed_events.size(), 1u);

  // Send a second event.
  sample_event.timestamp = 10.0l;
  FlutterEngineSendKeyEvent(engine.get(), &sample_event, nullptr, nullptr);
  message_latch->Wait();

  // The event should be echoed, too.
  EXPECT_EQ(echoed_events.size(), 2u);
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
    auto& context =
        GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();
    builder.SetDartEntrypoint("key_data_echo");
    context.AddNativeCallback(
        "SignalNativeTest",
        CREATE_NATIVE_ENTRY(
            [&ready](Dart_NativeArguments args) { ready.Signal(); }));
    context.AddNativeCallback(
        "EchoKeyEvent", CREATE_NATIVE_ENTRY([](Dart_NativeArguments args) {}));

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
    auto& context =
        GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();
    builder.SetDartEntrypoint("key_data_echo");
    context.AddNativeCallback(
        "SignalNativeTest",
        CREATE_NATIVE_ENTRY(
            [&ready](Dart_NativeArguments args) { ready.Signal(); }));

    context.AddNativeCallback(
        "EchoKeyEvent", CREATE_NATIVE_ENTRY([](Dart_NativeArguments args) {}));

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
    auto& context =
        GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);

    context.SetVsyncCallback([&](intptr_t baton) {
      platform_task_runner->PostTask([baton = baton, &engine, &vsync_latch]() {
        FlutterEngineOnVsync(engine.get(), baton, NanosFromEpoch(16),
                             NanosFromEpoch(32));
        vsync_latch.Signal();
      });
    });
    context.AddNativeCallback(
        "SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
          present_latch.Signal();
        }));

    EmbedderConfigBuilder builder(context);
    builder.SetSoftwareRendererConfig();
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
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  builder.SetDartEntrypoint("can_schedule_frame");
  fml::AutoResetWaitableEvent latch;
  context.AddNativeCallback(
      "SignalNativeTest",
      CREATE_NATIVE_ENTRY(
          [&latch](Dart_NativeArguments args) { latch.Signal(); }));

  fml::AutoResetWaitableEvent check_latch;
  context.AddNativeCallback(
      "SignalNativeCount",
      CREATE_NATIVE_ENTRY(
          [&check_latch](Dart_NativeArguments args) { check_latch.Signal(); }));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Wait for the application to attach the listener.
  latch.Wait();

  ASSERT_EQ(FlutterEngineScheduleFrame(engine.get()), kSuccess);

  check_latch.Wait();
}

TEST_F(EmbedderTest, CanSetNextFrameCallback) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
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
    case fml::Thread::ThreadPriority::DISPLAY:
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

  int ui_policy;
  struct sched_param ui_param;

  thread_host->GetTaskRunners().GetUITaskRunner()->PostTask([&] {
    pthread_t current_thread = pthread_self();
    pthread_getschedparam(current_thread, &ui_policy, &ui_param);
    ASSERT_EQ(ui_param.sched_priority, 10);
  });

  int io_policy;
  struct sched_param io_param;
  thread_host->GetTaskRunners().GetIOTaskRunner()->PostTask([&] {
    pthread_t current_thread = pthread_self();
    pthread_getschedparam(current_thread, &io_policy, &io_param);
    ASSERT_EQ(io_param.sched_priority, 1);
  });
}
#endif

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
