// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <string>

#include "embedder.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/testing/testing.h"

namespace shell {
namespace testing {

using EmbedderTest = testing::EmbedderTest;

TEST(EmbedderTestNoFixture, MustNotRunWithInvalidArgs) {
  EmbedderContext context;
  EmbedderConfigBuilder builder(
      context, EmbedderConfigBuilder::InitializationPreference::kNoInitialize);
  auto engine = builder.LaunchEngine();
  ASSERT_FALSE(engine.is_valid());
}

TEST_F(EmbedderTest, CanLaunchAndShutdownWithValidProjectArgs) {
  auto& context = GetEmbedderContext();
  fml::AutoResetWaitableEvent latch;
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  EmbedderConfigBuilder builder(context);
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
}

TEST_F(EmbedderTest, CanLaunchAndShutdownMultipleTimes) {
  EmbedderConfigBuilder builder(GetEmbedderContext());
  for (size_t i = 0; i < 3; ++i) {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
    FML_LOG(INFO) << "Engine launch count: " << i + 1;
  }
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypoint) {
  auto& context = GetEmbedderContext();
  static fml::AutoResetWaitableEvent latch;
  Dart_NativeFunction entrypoint = [](Dart_NativeArguments args) {
    latch.Signal();
  };
  context.AddNativeCallback("SayHiFromCustomEntrypoint", entrypoint);
  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("customEntrypoint");
  auto engine = builder.LaunchEngine();
  latch.Wait();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderTest, CanInvokeCustomEntrypointMacro) {
  auto& context = GetEmbedderContext();

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
  builder.SetDartEntrypoint("customEntrypoint1");
  auto engine = builder.LaunchEngine();
  latch1.Wait();
  latch2.Wait();
  latch3.Wait();
  ASSERT_TRUE(engine.is_valid());
}

class EmbedderTestTaskRunner {
 public:
  EmbedderTestTaskRunner(std::function<void(FlutterTask)> on_forward_task)
      : on_forward_task_(on_forward_task) {}

  void SetForwardingTaskRunner(fml::RefPtr<fml::TaskRunner> runner) {
    forwarding_target_ = std::move(runner);
  }

  FlutterTaskRunnerDescription GetEmbedderDescription() {
    FlutterTaskRunnerDescription desc;
    desc.struct_size = sizeof(desc);
    desc.user_data = this;
    desc.runs_task_on_current_thread_callback = [](void* user_data) -> bool {
      return reinterpret_cast<EmbedderTestTaskRunner*>(user_data)
          ->forwarding_target_->RunsTasksOnCurrentThread();
    };
    desc.post_task_callback = [](FlutterTask task, uint64_t target_time_nanos,
                                 void* user_data) -> void {
      auto runner = reinterpret_cast<EmbedderTestTaskRunner*>(user_data);

      auto target_time = fml::TimePoint::FromEpochDelta(
          fml::TimeDelta::FromNanoseconds(target_time_nanos));

      runner->forwarding_target_->PostTaskForTime(
          [task, forwarder = runner->on_forward_task_]() { forwarder(task); },
          target_time);
    };
    return desc;
  }

 private:
  fml::RefPtr<fml::TaskRunner> forwarding_target_;
  std::function<void(FlutterTask)> on_forward_task_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestTaskRunner);
};

TEST_F(EmbedderTest, CanSpecifyCustomTaskRunner) {
  auto& context = GetEmbedderContext();
  fml::AutoResetWaitableEvent latch;

  // Run the test on its own thread with a message loop so that it san safely
  // pump its event loop while we wait for all the conditions to be checked.
  fml::Thread thread;
  UniqueEngine engine;
  bool signalled = false;

  EmbedderTestTaskRunner runner([&](FlutterTask task) {
    // There may be multiple tasks posted but we only need to check assertions
    // once.
    if (signalled) {
      // Since we have the baton, return it back to the engine. We don't care
      // about the return value because the engine could be shutting down an it
      // may not actually be able to accept the same.
      FlutterEngineRunTask(engine.get(), &task);
      return;
    }

    signalled = true;
    FML_LOG(INFO) << "Checking assertions.";
    ASSERT_TRUE(engine.is_valid());
    ASSERT_EQ(FlutterEngineRunTask(engine.get(), &task), kSuccess);
    latch.Signal();
  });

  thread.GetTaskRunner()->PostTask([&]() {
    EmbedderConfigBuilder builder(context);
    builder.AddCommandLineArgument("--verbose-logging");
    const auto task_runner_description = runner.GetEmbedderDescription();
    runner.SetForwardingTaskRunner(
        fml::MessageLoop::GetCurrent().GetTaskRunner());
    builder.SetPlatformTaskRunner(&task_runner_description);
    builder.SetDartEntrypoint("invokePlatformTaskRunner");
    engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
  });

  // Signalled when all the assertions are checked.
  latch.Wait();
  FML_LOG(INFO) << "Assertions checked. Killing engine.";
  ASSERT_TRUE(engine.is_valid());

  // Since the engine was started on its own thread, it must be killed there as
  // well.
  fml::AutoResetWaitableEvent kill_latch;
  thread.GetTaskRunner()->PostTask(
      fml::MakeCopyable([&engine, &kill_latch]() mutable {
        engine.reset();
        FML_LOG(INFO) << "Engine killed.";
        kill_latch.Signal();
      }));
  kill_latch.Wait();

  ASSERT_TRUE(signalled);
}

TEST(EmbedderTestNoFixture, CanGetCurrentTimeInNanoseconds) {
  auto point1 = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(FlutterEngineGetCurrentTime()));
  auto point2 = fml::TimePoint::Now();

  ASSERT_LT((point2 - point1), fml::TimeDelta::FromMilliseconds(1));
}

}  // namespace testing
}  // namespace shell
