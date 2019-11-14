// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <algorithm>
#include <functional>
#include <future>
#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"
#include "third_party/tonic/converter/dart_converter.h"

namespace flutter {
namespace testing {

static bool ValidateShell(Shell* shell) {
  if (!shell) {
    return false;
  }

  if (!shell->IsSetup()) {
    return false;
  }

  ShellTest::PlatformViewNotifyCreated(shell);

  {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        shell->GetTaskRunners().GetPlatformTaskRunner(), [shell, &latch]() {
          shell->GetPlatformView()->NotifyDestroyed();
          latch.Signal();
        });
    latch.Wait();
  }

  return true;
}

TEST_F(ShellTest, InitializeWithInvalidThreads) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test", nullptr, nullptr, nullptr, nullptr);
  auto shell = CreateShell(std::move(settings), std::move(task_runners));
  ASSERT_FALSE(shell);
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, InitializeWithDifferentThreads) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.gpu_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  auto shell = CreateShell(std::move(settings), std::move(task_runners));
  ASSERT_TRUE(ValidateShell(shell.get()));
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell), std::move(task_runners));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, InitializeWithSingleThread) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::Platform);
  auto task_runner = thread_host.platform_thread->GetTaskRunner();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  auto shell = CreateShell(std::move(settings), task_runners);
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  ASSERT_TRUE(ValidateShell(shell.get()));
  DestroyShell(std::move(shell), std::move(task_runners));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, InitializeWithSingleThreadWhichIsTheCallingThread) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  auto shell = CreateShell(std::move(settings), task_runners);
  ASSERT_TRUE(ValidateShell(shell.get()));
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell), std::move(task_runners));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest,
       InitializeWithMultipleThreadButCallingThreadAsPlatformThread) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::GPU | ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  TaskRunners task_runners("test",
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           thread_host.gpu_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        return std::make_unique<ShellTestPlatformView>(shell,
                                                       shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell, shell.GetTaskRunners());
      });
  ASSERT_TRUE(ValidateShell(shell.get()));
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell), std::move(task_runners));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, InitializeWithGPUAndPlatformThreadsTheSame) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  Settings settings = CreateSettingsForFixture();
  ThreadHost thread_host(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.platform_thread->GetTaskRunner(),  // gpu
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  auto shell = CreateShell(std::move(settings), std::move(task_runners));
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  ASSERT_TRUE(ValidateShell(shell.get()));
  DestroyShell(std::move(shell), std::move(task_runners));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, FixturesAreFunctional) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto settings = CreateSettingsForFixture();
  auto shell = CreateShell(settings);
  ASSERT_TRUE(ValidateShell(shell.get()));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("fixturesAreFunctionalMain");

  fml::AutoResetWaitableEvent main_latch;
  AddNativeCallback(
      "SayHiFromFixturesAreFunctionalMain",
      CREATE_NATIVE_ENTRY([&main_latch](auto args) { main_latch.Signal(); }));

  RunEngine(shell.get(), std::move(configuration));
  main_latch.Wait();
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, SecondaryIsolateBindingsAreSetupViaShellSettings) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto settings = CreateSettingsForFixture();
  auto shell = CreateShell(settings);
  ASSERT_TRUE(ValidateShell(shell.get()));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("testCanLaunchSecondaryIsolate");

  fml::CountDownLatch latch(2);
  AddNativeCallback("NotifyNative", CREATE_NATIVE_ENTRY([&latch](auto args) {
                      latch.CountDown();
                    }));

  RunEngine(shell.get(), std::move(configuration));

  latch.Wait();

  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, LastEntrypoint) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto settings = CreateSettingsForFixture();
  auto shell = CreateShell(settings);
  ASSERT_TRUE(ValidateShell(shell.get()));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  std::string entry_point = "fixturesAreFunctionalMain";
  configuration.SetEntrypoint(entry_point);

  fml::AutoResetWaitableEvent main_latch;
  std::string last_entry_point;
  AddNativeCallback(
      "SayHiFromFixturesAreFunctionalMain", CREATE_NATIVE_ENTRY([&](auto args) {
        last_entry_point = shell->GetEngine()->GetLastEntrypoint();
        main_latch.Signal();
      }));

  RunEngine(shell.get(), std::move(configuration));
  main_latch.Wait();
  EXPECT_EQ(entry_point, last_entry_point);
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST(ShellTestNoFixture, EnableMirrorsIsWhitelisted) {
  if (DartVM::IsRunningPrecompiledCode()) {
    // This covers profile and release modes which use AOT (where this flag does
    // not make sense anyway).
    GTEST_SKIP();
    return;
  }
#if FLUTTER_RELEASE
  GTEST_SKIP();
  return;
#endif

  const std::vector<fml::CommandLine::Option> options = {
      fml::CommandLine::Option("dart-flags", "--enable_mirrors")};
  fml::CommandLine command_line("", options, std::vector<std::string>());
  flutter::Settings settings = flutter::SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.dart_flags.size(), 1u);
}

TEST_F(ShellTest, BlacklistedDartVMFlag) {
  // Run this test in a thread-safe manner, otherwise gtest will complain.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";

  const std::vector<fml::CommandLine::Option> options = {
      fml::CommandLine::Option("dart-flags", "--verify_after_gc")};
  fml::CommandLine command_line("", options, std::vector<std::string>());

#if !FLUTTER_RELEASE
  // Upon encountering a non-whitelisted Dart flag the process terminates.
  const char* expected =
      "Encountered blacklisted Dart VM flag: --verify_after_gc";
  ASSERT_DEATH(flutter::SettingsFromCommandLine(command_line), expected);
#else
  flutter::Settings settings = flutter::SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.dart_flags.size(), 0u);
#endif
}

TEST_F(ShellTest, WhitelistedDartVMFlag) {
  const std::vector<fml::CommandLine::Option> options = {
      fml::CommandLine::Option("dart-flags",
                               "--max_profile_depth 1,--random_seed 42")};
  fml::CommandLine command_line("", options, std::vector<std::string>());
  flutter::Settings settings = flutter::SettingsFromCommandLine(command_line);

#if !FLUTTER_RELEASE
  EXPECT_EQ(settings.dart_flags.size(), 2u);
  EXPECT_EQ(settings.dart_flags[0], "--max_profile_depth 1");
  EXPECT_EQ(settings.dart_flags[1], "--random_seed 42");
#else
  EXPECT_EQ(settings.dart_flags.size(), 0u);
#endif
}

TEST_F(ShellTest, NoNeedToReportTimingsByDefault) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());
  ASSERT_FALSE(GetNeedsReportTimings(shell.get()));

  // This assertion may or may not be the direct result of needs_report_timings_
  // being false. The count could be 0 simply because we just cleared
  // unreported timings by reporting them. Hence this can't replace the
  // ASSERT_FALSE(GetNeedsReportTimings(shell.get())) check. We added
  // this assertion for an additional confidence that we're not pushing
  // back to unreported timings unnecessarily.
  //
  // Conversely, do not assert UnreportedTimingsCount(shell.get()) to be
  // positive in any tests. Otherwise those tests will be flaky as the clearing
  // of unreported timings is unpredictive.
  ASSERT_EQ(UnreportedTimingsCount(shell.get()), 0);
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, NeedsReportTimingsIsSetWithCallback) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("dummyReportTimingsMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());
  ASSERT_TRUE(GetNeedsReportTimings(shell.get()));
  DestroyShell(std::move(shell));
}

static void CheckFrameTimings(const std::vector<FrameTiming>& timings,
                              fml::TimePoint start,
                              fml::TimePoint finish) {
  fml::TimePoint last_frame_start;
  for (size_t i = 0; i < timings.size(); i += 1) {
    // Ensure that timings are sorted.
    ASSERT_TRUE(timings[i].Get(FrameTiming::kPhases[0]) >= last_frame_start);
    last_frame_start = timings[i].Get(FrameTiming::kPhases[0]);

    fml::TimePoint last_phase_time;
    for (auto phase : FrameTiming::kPhases) {
      ASSERT_TRUE(timings[i].Get(phase) >= start);
      ASSERT_TRUE(timings[i].Get(phase) <= finish);

      // phases should have weakly increasing time points
      ASSERT_TRUE(last_phase_time <= timings[i].Get(phase));
      last_phase_time = timings[i].Get(phase);
    }
  }
}

// TODO(43192): This test is disable because of flakiness.
TEST_F(ShellTest, DISABLED_ReportTimingsIsCalled) {
  fml::TimePoint start = fml::TimePoint::Now();
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("reportTimingsMain");
  fml::AutoResetWaitableEvent reportLatch;
  std::vector<int64_t> timestamps;
  auto nativeTimingCallback = [&reportLatch,
                               &timestamps](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    timestamps = tonic::DartConverter<std::vector<int64_t>>::FromArguments(
        args, 0, exception);
    reportLatch.Signal();
  };
  AddNativeCallback("NativeReportTimingsCallback",
                    CREATE_NATIVE_ENTRY(nativeTimingCallback));
  RunEngine(shell.get(), std::move(configuration));

  // Pump many frames so we can trigger the report quickly instead of waiting
  // for the 1 second threshold.
  for (int i = 0; i < 200; i += 1) {
    PumpOneFrame(shell.get());
  }

  reportLatch.Wait();
  DestroyShell(std::move(shell));

  fml::TimePoint finish = fml::TimePoint::Now();
  ASSERT_TRUE(timestamps.size() > 0);
  ASSERT_TRUE(timestamps.size() % FrameTiming::kCount == 0);
  std::vector<FrameTiming> timings(timestamps.size() / FrameTiming::kCount);

  for (size_t i = 0; i * FrameTiming::kCount < timestamps.size(); i += 1) {
    for (auto phase : FrameTiming::kPhases) {
      timings[i].Set(
          phase,
          fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromMicroseconds(
              timestamps[i * FrameTiming::kCount + phase])));
    }
  }
  CheckFrameTimings(timings, start, finish);
}

TEST_F(ShellTest, FrameRasterizedCallbackIsCalled) {
  fml::TimePoint start = fml::TimePoint::Now();

  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent timingLatch;
  FrameTiming timing;

  for (auto phase : FrameTiming::kPhases) {
    timing.Set(phase, fml::TimePoint());
    // Check that the time points are initially smaller than start, so
    // CheckFrameTimings will fail if they're not properly set later.
    ASSERT_TRUE(timing.Get(phase) < start);
  }

  settings.frame_rasterized_callback = [&timing,
                                        &timingLatch](const FrameTiming& t) {
    timing = t;
    timingLatch.Signal();
  };

  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("onBeginFrameMain");

  int64_t begin_frame;
  auto nativeOnBeginFrame = [&begin_frame](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    begin_frame =
        tonic::DartConverter<int64_t>::FromArguments(args, 0, exception);
  };
  AddNativeCallback("NativeOnBeginFrame",
                    CREATE_NATIVE_ENTRY(nativeOnBeginFrame));

  RunEngine(shell.get(), std::move(configuration));

  PumpOneFrame(shell.get());

  // Check that timing is properly set. This implies that
  // settings.frame_rasterized_callback is called.
  timingLatch.Wait();
  fml::TimePoint finish = fml::TimePoint::Now();
  std::vector<FrameTiming> timings = {timing};
  CheckFrameTimings(timings, start, finish);

  // Check that onBeginFrame has the same timestamp as FrameTiming's build start
  int64_t build_start =
      timing.Get(FrameTiming::kBuildStart).ToEpochDelta().ToMicroseconds();
  ASSERT_EQ(build_start, begin_frame);
  DestroyShell(std::move(shell));
}

TEST(SettingsTest, FrameTimingSetsAndGetsProperly) {
  // Ensure that all phases are in kPhases.
  ASSERT_EQ(sizeof(FrameTiming::kPhases),
            FrameTiming::kCount * sizeof(FrameTiming::Phase));

  int lastPhaseIndex = -1;
  FrameTiming timing;
  for (auto phase : FrameTiming::kPhases) {
    ASSERT_TRUE(phase > lastPhaseIndex);  // Ensure that kPhases are in order.
    lastPhaseIndex = phase;
    auto fake_time =
        fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromMicroseconds(phase));
    timing.Set(phase, fake_time);
    ASSERT_TRUE(timing.Get(phase) == fake_time);
  }
}

#if FLUTTER_RELEASE
TEST_F(ShellTest, ReportTimingsIsCalledLaterInReleaseMode) {
#else
TEST_F(ShellTest, ReportTimingsIsCalledSoonerInNonReleaseMode) {
#endif
  fml::TimePoint start = fml::TimePoint::Now();
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("reportTimingsMain");

  // Wait for 2 reports: the first one is the immediate callback of the first
  // frame; the second one will exercise the batching logic.
  fml::CountDownLatch reportLatch(2);
  std::vector<int64_t> timestamps;
  auto nativeTimingCallback = [&reportLatch,
                               &timestamps](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    timestamps = tonic::DartConverter<std::vector<int64_t>>::FromArguments(
        args, 0, exception);
    reportLatch.CountDown();
  };
  AddNativeCallback("NativeReportTimingsCallback",
                    CREATE_NATIVE_ENTRY(nativeTimingCallback));
  RunEngine(shell.get(), std::move(configuration));

  PumpOneFrame(shell.get());
  PumpOneFrame(shell.get());

  reportLatch.Wait();
  DestroyShell(std::move(shell));

  fml::TimePoint finish = fml::TimePoint::Now();
  fml::TimeDelta ellapsed = finish - start;

#if FLUTTER_RELEASE
  // Our batch time is 1000ms. Hopefully the 800ms limit is relaxed enough to
  // make it not too flaky.
  ASSERT_TRUE(ellapsed >= fml::TimeDelta::FromMilliseconds(800));
#else
  // Our batch time is 100ms. Hopefully the 500ms limit is relaxed enough to
  // make it not too flaky.
  ASSERT_TRUE(ellapsed <= fml::TimeDelta::FromMilliseconds(500));
#endif
}

TEST_F(ShellTest, ReportTimingsIsCalledImmediatelyAfterTheFirstFrame) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  configuration.SetEntrypoint("reportTimingsMain");
  fml::AutoResetWaitableEvent reportLatch;
  std::vector<int64_t> timestamps;
  auto nativeTimingCallback = [&reportLatch,
                               &timestamps](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    timestamps = tonic::DartConverter<std::vector<int64_t>>::FromArguments(
        args, 0, exception);
    reportLatch.Signal();
  };
  AddNativeCallback("NativeReportTimingsCallback",
                    CREATE_NATIVE_ENTRY(nativeTimingCallback));
  RunEngine(shell.get(), std::move(configuration));

  for (int i = 0; i < 10; i += 1) {
    PumpOneFrame(shell.get());
  }

  reportLatch.Wait();
  DestroyShell(std::move(shell));

  // Check for the immediate callback of the first frame that doesn't wait for
  // the other 9 frames to be rasterized.
  ASSERT_EQ(timestamps.size(), FrameTiming::kCount);
}

TEST_F(ShellTest, ReloadSystemFonts) {
  auto settings = CreateSettingsForFixture();

  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  auto shell = CreateShell(std::move(settings), std::move(task_runners));

  auto fontCollection = GetFontCollection(shell.get());
  std::vector<std::string> families(1, "Robotofake");
  auto font =
      fontCollection->GetMinikinFontCollectionForFamilies(families, "en");
  if (font == nullptr) {
    // The system does not have default font. Aborts this test.
    return;
  }
  unsigned int id = font->getId();
  // The result should be cached.
  font = fontCollection->GetMinikinFontCollectionForFamilies(families, "en");
  ASSERT_EQ(font->getId(), id);
  bool result = shell->ReloadSystemFonts();

  // The cache is cleared, and FontCollection will be assigned a new id.
  font = fontCollection->GetMinikinFontCollectionForFamilies(families, "en");
  ASSERT_NE(font->getId(), id);
  ASSERT_TRUE(result);
  shell.reset();
}

TEST_F(ShellTest, WaitForFirstFrame) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());
  fml::Status result =
      shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1000));
  ASSERT_TRUE(result.ok());
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, WaitForFirstFrameTimeout) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  fml::Status result =
      shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(10));
  ASSERT_EQ(result.code(), fml::StatusCode::kDeadlineExceeded);
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, WaitForFirstFrameMultiple) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());
  fml::Status result =
      shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1000));
  ASSERT_TRUE(result.ok());
  for (int i = 0; i < 100; ++i) {
    result = shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1));
    ASSERT_TRUE(result.ok());
  }
  DestroyShell(std::move(shell));
}

/// Makes sure that WaitForFirstFrame works if we rendered a frame with the
/// single-thread setup.
TEST_F(ShellTest, WaitForFirstFrameInlined) {
  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());
  fml::AutoResetWaitableEvent event;
  task_runner->PostTask([&shell, &event] {
    fml::Status result =
        shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1000));
    ASSERT_EQ(result.code(), fml::StatusCode::kFailedPrecondition);
    event.Signal();
  });
  ASSERT_FALSE(event.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(1000)));
  DestroyShell(std::move(shell), std::move(task_runners));
}

static size_t GetRasterizerResourceCacheBytesSync(Shell& shell) {
  size_t bytes = 0;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell.GetTaskRunners().GetGPUTaskRunner(), [&]() {
        if (auto rasterizer = shell.GetRasterizer()) {
          bytes = rasterizer->GetResourceCacheMaxBytes().value_or(0U);
        }
        latch.Signal();
      });
  latch.Wait();
  return bytes;
}

TEST_F(ShellTest, SetResourceCacheSize) {
  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            static_cast<size_t>(24 * (1 << 20)));

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [&shell]() {
        shell->GetPlatformView()->SetViewportMetrics(
            {1.0, 400, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
      });
  PumpOneFrame(shell.get());

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell), 3840000U);

  std::string request_json = R"json({
                                "method": "Skia.setResourceCacheMaxBytes",
                                "args": 10000
                              })json";
  std::vector<uint8_t> data(request_json.begin(), request_json.end());
  auto platform_message = fml::MakeRefCounted<PlatformMessage>(
      "flutter/skia", std::move(data), nullptr);
  SendEnginePlatformMessage(shell.get(), std::move(platform_message));
  PumpOneFrame(shell.get());
  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell), 10000U);

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [&shell]() {
        shell->GetPlatformView()->SetViewportMetrics(
            {1.0, 800, 400, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
      });
  PumpOneFrame(shell.get());

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell), 10000U);
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, SetResourceCacheSizeEarly) {
  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [&shell]() {
        shell->GetPlatformView()->SetViewportMetrics(
            {1.0, 400, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
      });
  PumpOneFrame(shell.get());

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            static_cast<size_t>(3840000U));
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, SetResourceCacheSizeNotifiesDart) {
  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [&shell]() {
        shell->GetPlatformView()->SetViewportMetrics(
            {1.0, 400, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
      });
  PumpOneFrame(shell.get());

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("testSkiaResourceCacheSendsResponse");

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            static_cast<size_t>(3840000U));

  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyNative", CREATE_NATIVE_ENTRY([&latch](auto args) {
                      latch.Signal();
                    }));

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get());

  latch.Wait();

  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            static_cast<size_t>(10000U));
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, CanCreateImagefromDecompressedBytes) {
  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();

  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("canCreateImageFromDecompressedData");

  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyWidthHeight",
                    CREATE_NATIVE_ENTRY([&latch](auto args) {
                      auto width = tonic::DartConverter<int>::FromDart(
                          Dart_GetNativeArgument(args, 0));
                      auto height = tonic::DartConverter<int>::FromDart(
                          Dart_GetNativeArgument(args, 1));
                      ASSERT_EQ(width, 10);
                      ASSERT_EQ(height, 10);
                      latch.Signal();
                    }));

  RunEngine(shell.get(), std::move(configuration));

  latch.Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

class MockTexture : public Texture {
 public:
  MockTexture(int64_t textureId,
              std::shared_ptr<fml::AutoResetWaitableEvent> latch)
      : Texture(textureId), latch_(latch) {}

  ~MockTexture() override = default;

  // Called from GPU thread.
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrContext* context) override {}

  void OnGrContextCreated() override {}

  void OnGrContextDestroyed() override {}

  void MarkNewFrameAvailable() override {
    frames_available_++;
    latch_->Signal();
  }

  void OnTextureUnregistered() override {
    unregistered_ = true;
    latch_->Signal();
  }

  bool unregistered() { return unregistered_; }
  int frames_available() { return frames_available_; }

 private:
  bool unregistered_ = false;
  int frames_available_ = 0;
  std::shared_ptr<fml::AutoResetWaitableEvent> latch_;
};

TEST_F(ShellTest, TextureFrameMarkedAvailableAndUnregister) {
  Settings settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(ValidateShell(shell.get()));
  PlatformViewNotifyCreated(shell.get());

  RunEngine(shell.get(), std::move(configuration));

  std::shared_ptr<fml::AutoResetWaitableEvent> latch =
      std::make_shared<fml::AutoResetWaitableEvent>();

  std::shared_ptr<MockTexture> mockTexture =
      std::make_shared<MockTexture>(0, latch);

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetGPUTaskRunner(), [&]() {
        shell->GetPlatformView()->RegisterTexture(mockTexture);
        shell->GetPlatformView()->MarkTextureFrameAvailable(0);
      });
  latch->Wait();

  EXPECT_EQ(mockTexture->frames_available(), 1);

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetGPUTaskRunner(),
      [&]() { shell->GetPlatformView()->UnregisterTexture(0); });
  latch->Wait();

  EXPECT_EQ(mockTexture->unregistered(), true);
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, IsolateCanAccessPersistentIsolateData) {
  const std::string message = "dummy isolate launch data.";

  Settings settings = CreateSettingsForFixture();
  settings.persistent_isolate_data =
      std::make_shared<fml::DataMapping>(message);
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // gpu
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  fml::AutoResetWaitableEvent message_latch;
  AddNativeCallback("NotifyMessage",
                    CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      const auto message_from_dart =
                          tonic::DartConverter<std::string>::FromDart(
                              Dart_GetNativeArgument(args, 0));
                      ASSERT_EQ(message, message_from_dart);
                      message_latch.Signal();
                    }));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("canAccessIsolateLaunchData");

  fml::AutoResetWaitableEvent event;
  shell->RunEngine(std::move(configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch.Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, RasterizerScreenshot) {
  Settings settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(ValidateShell(shell.get()));
  PlatformViewNotifyCreated(shell.get());

  RunEngine(shell.get(), std::move(configuration));

  auto latch = std::make_shared<fml::AutoResetWaitableEvent>();

  PumpOneFrame(shell.get());

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetGPUTaskRunner(), [&shell, &latch]() {
        Rasterizer::Screenshot screenshot =
            shell->GetRasterizer()->ScreenshotLastLayerTree(
                Rasterizer::ScreenshotType::CompressedImage, true);
        EXPECT_NE(screenshot.data, nullptr);

        latch->Signal();
      });
  latch->Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, RasterizerMakeRasterSnapshot) {
  Settings settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);
  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(ValidateShell(shell.get()));
  PlatformViewNotifyCreated(shell.get());

  RunEngine(shell.get(), std::move(configuration));

  auto latch = std::make_shared<fml::AutoResetWaitableEvent>();

  PumpOneFrame(shell.get());

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetGPUTaskRunner(), [&shell, &latch]() {
        SnapshotDelegate* delegate =
            reinterpret_cast<Rasterizer*>(shell->GetRasterizer().get());
        sk_sp<SkImage> image = delegate->MakeRasterSnapshot(
            SkPicture::MakePlaceholder({0, 0, 50, 50}), SkISize::Make(50, 50));
        EXPECT_NE(image, nullptr);

        latch->Signal();
      });
  latch->Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

}  // namespace testing
}  // namespace flutter
