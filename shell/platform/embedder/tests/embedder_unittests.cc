// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <string>
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
#include "flutter/fml/thread.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/assertions_skia.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/tonic/converter/dart_converter.h"

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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
      GetEmbedderContext(ContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
  for (size_t i = 0; i < 3; ++i) {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
    FML_LOG(INFO) << "Engine launch count: " << i + 1;
  }
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypoint) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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

  // Can be wrapped in in the args.
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

std::atomic_size_t EmbedderTestTaskRunner::sEmbedderTaskRunnerIdentifiers = {};

TEST_F(EmbedderTest, CanSpecifyCustomPlatformTaskRunner) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig();
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  auto result = FlutterEngineReloadSystemFonts(engine.get());
  ASSERT_EQ(result, kSuccess);
}

TEST_F(EmbedderTest, IsolateServiceIdSent) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
    auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
/// Asserts behavior of FlutterProjectArgs::shutdown_dart_vm_when_done (which is
/// set to true by default in these unit-tests).
///
TEST_F(EmbedderTest, VMShutsDownWhenNoEnginesInProcess) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  latch.Wait();

  ASSERT_TRUE(ImageMatchesFixture("compositor_software.png", scene_image));

  // There should no present calls on the root surface.
  ASSERT_EQ(context.GetSurfacePresentCount(), 0u);
}

//------------------------------------------------------------------------------
/// Test that an engine can be initialized but not run.
///
TEST_F(EmbedderTest, CanCreateInitializedEngine) {
  EmbedderConfigBuilder builder(
      GetEmbedderContext(ContextType::kSoftwareContext));
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
      GetEmbedderContext(ContextType::kSoftwareContext));
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
TEST_F(EmbedderTest, CaDeinitializeAnEngine) {
  EmbedderConfigBuilder builder(
      GetEmbedderContext(ContextType::kSoftwareContext));
  builder.SetSoftwareRendererConfig();
  auto engine = builder.InitializeEngine();
  ASSERT_TRUE(engine.is_valid());
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kSuccess);
  // Cannot re-run an already running engine.
  ASSERT_EQ(FlutterEngineRunInitialized(engine.get()), kInvalidArguments);
  ASSERT_EQ(FlutterEngineDeinitialize(engine.get()), kSuccess);
  // It is ok to deinitialize an engine multiple times.
  ASSERT_EQ(FlutterEngineDeinitialize(engine.get()), kSuccess);

  // Sending events to a deinitalized engine fails.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kInvalidArguments);
  engine.reset();
}

TEST_F(EmbedderTest, CanUpdateLocales) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

  EmbedderConfigBuilder builder(context);
  builder.SetSoftwareRendererConfig(SkISize::Make(1024, 600));
  builder.SetCompositor();
  builder.SetDartEntrypoint("verify_b143464703");

  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kSoftwareBuffer);

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
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  ASSERT_TRUE(engine.is_valid());

  auto renderered_scene = context.GetNextSceneImage();

  latch.Wait();

  // TODO(https://github.com/flutter/flutter/issues/53784): enable this on all
  // platforms.
#if !defined(OS_LINUX)
  GTEST_SKIP() << "Skipping golden tests on non-Linux OSes";
#endif  // OS_LINUX
  ASSERT_TRUE(ImageMatchesFixture("verifyb143464703_soft_noxform.png",
                                  renderered_scene));
}

TEST_F(EmbedderTest, CanSendLowMemoryNotification) {
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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
    auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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

    Captures(size_t count) : latch(count) {}
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
  data_in.type = FlutterEngineAOTDataSourceType(-1);
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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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
      fml::paths::JoinPaths({GetFixturesPath(), kAOTAppELFFileName});

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
  auto& context = GetEmbedderContext(ContextType::kSoftwareContext);

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

}  // namespace testing
}  // namespace flutter
