// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <algorithm>
#include <ctime>
#include <functional>
#include <future>
#include <memory>

#include "assets/directory_asset_bundle.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/picture_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/dart/dart_converter.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/shell_test_external_view_embedder.h"
#include "flutter/shell/common/shell_test_platform_view.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/common/vsync_waiter_fallback.h"
#include "flutter/shell/version/version.h"
#include "flutter/testing/testing.h"
#include "third_party/rapidjson/include/rapidjson/writer.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/tonic/converter/dart_converter.h"

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/vulkan/vulkan_application.h"  // nogncheck
#endif

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

static bool RasterizerHasLayerTree(Shell* shell) {
  fml::AutoResetWaitableEvent latch;
  bool has_layer_tree = false;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetRasterTaskRunner(),
      [shell, &latch, &has_layer_tree]() {
        has_layer_tree = shell->GetRasterizer()->GetLastLayerTree() != nullptr;
        latch.Signal();
      });
  latch.Wait();
  return has_layer_tree;
}

static void ValidateDestroyPlatformView(Shell* shell) {
  ASSERT_TRUE(shell != nullptr);
  ASSERT_TRUE(shell->IsSetup());

  // To validate destroy platform view, we must ensure the rasterizer has a
  // layer tree before the platform view is destroyed.
  ASSERT_TRUE(RasterizerHasLayerTree(shell));

  ShellTest::PlatformViewNotifyDestroyed(shell);
  // Validate the layer tree is destroyed
  ASSERT_FALSE(RasterizerHasLayerTree(shell));
}

static std::string CreateFlagsString(std::vector<const char*>& flags) {
  if (flags.size() == 0) {
    return "";
  }
  std::string flags_string = flags[0];
  for (size_t i = 1; i < flags.size(); ++i) {
    flags_string += ",";
    flags_string += flags[i];
  }
  return flags_string;
}

static void TestDartVmFlags(std::vector<const char*>& flags) {
  std::string flags_string = CreateFlagsString(flags);
  const std::vector<fml::CommandLine::Option> options = {
      fml::CommandLine::Option("dart-flags", flags_string)};
  fml::CommandLine command_line("", options, std::vector<std::string>());
  flutter::Settings settings = flutter::SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.dart_flags.size(), flags.size());
  for (size_t i = 0; i < flags.size(); ++i) {
    EXPECT_EQ(settings.dart_flags[i], flags[i]);
  }
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
                           thread_host.raster_thread->GetTaskRunner(),
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
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  auto shell = Shell::Create(
      std::move(task_runners), settings,
      [](Shell& shell) {
        // This is unused in the platform view as we are not using the simulated
        // vsync mechanism. We should have better DI in the tests.
        const auto vsync_clock = std::make_shared<ShellTestVsyncClock>();
        return ShellTestPlatformView::Create(
            shell, shell.GetTaskRunners(), vsync_clock,
            [task_runners = shell.GetTaskRunners()]() {
              return static_cast<std::unique_ptr<VsyncWaiter>>(
                  std::make_unique<VsyncWaiterFallback>(task_runners));
            },
            ShellTestPlatformView::BackendType::kDefaultBackend, nullptr);
      },
      [](Shell& shell) { return std::make_unique<Rasterizer>(shell); });
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
      thread_host.platform_thread->GetTaskRunner(),  // raster
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

TEST_F(ShellTest, DisallowedDartVMFlag) {
  // Run this test in a thread-safe manner, otherwise gtest will complain.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";

  const std::vector<fml::CommandLine::Option> options = {
      fml::CommandLine::Option("dart-flags", "--verify_after_gc")};
  fml::CommandLine command_line("", options, std::vector<std::string>());

  // Upon encountering a disallowed Dart flag the process terminates.
  const char* expected =
      "Encountered disallowed Dart VM flag: --verify_after_gc";
  ASSERT_DEATH(flutter::SettingsFromCommandLine(command_line), expected);
}

TEST_F(ShellTest, AllowedDartVMFlag) {
  std::vector<const char*> flags = {
      "--enable-isolate-groups",
      "--no-enable-isolate-groups",
      "--lazy_async_stacks",
      "--no-causal_async_stacks",
  };
#if !FLUTTER_RELEASE
  flags.push_back("--max_profile_depth 1");
  flags.push_back("--random_seed 42");
  if (!DartVM::IsRunningPrecompiledCode()) {
    flags.push_back("--enable_mirrors");
  }
#endif
  TestDartVmFlags(flags);
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

  int64_t frame_target_time;
  auto nativeOnBeginFrame = [&frame_target_time](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    frame_target_time =
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

  // Check that onBeginFrame, which is the frame_target_time, is after
  // FrameTiming's build start
  int64_t build_start =
      timing.Get(FrameTiming::kBuildStart).ToEpochDelta().ToMicroseconds();
  ASSERT_GT(frame_target_time, build_start);
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, ExternalEmbedderNoThreadMerger) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  bool end_frame_called = false;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        ASSERT_TRUE(raster_thread_merger.get() == nullptr);
        ASSERT_FALSE(should_resubmit_frame);
        end_frame_called = true;
        end_frame_latch.Signal();
      };
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kResubmitFrame, false);
  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);
  end_frame_latch.Wait();

  ASSERT_TRUE(end_frame_called);

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_ExternalEmbedderEndFrameIsCalledWhenPostPrerollResultIsResubmit
#else
       ExternalEmbedderEndFrameIsCalledWhenPostPrerollResultIsResubmit
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  bool end_frame_called = false;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        ASSERT_TRUE(raster_thread_merger.get() != nullptr);
        ASSERT_TRUE(should_resubmit_frame);
        end_frame_called = true;
        end_frame_latch.Signal();
      };
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kResubmitFrame, true);
  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);
  end_frame_latch.Wait();

  ASSERT_TRUE(end_frame_called);

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_OnPlatformViewDestroyDisablesThreadMerger
#else
       OnPlatformViewDestroyDisablesThreadMerger
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> thread_merger) {
        raster_thread_merger = thread_merger;
      };
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSuccess, true);

  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);

  auto result =
      shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1000));
  ASSERT_TRUE(result.ok());

  ASSERT_TRUE(raster_thread_merger->IsEnabled());

  ValidateDestroyPlatformView(shell.get());
  ASSERT_TRUE(raster_thread_merger->IsEnabled());

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());
  ASSERT_TRUE(raster_thread_merger->IsEnabled());

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_OnPlatformViewDestroyAfterMergingThreads
#else
       OnPlatformViewDestroyAfterMergingThreads
#endif
) {
  const size_t ThreadMergingLease = 10;
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  std::shared_ptr<ShellTestExternalViewEmbedder> external_view_embedder;

  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        if (should_resubmit_frame && !raster_thread_merger->IsMerged()) {
          raster_thread_merger->MergeWithLease(ThreadMergingLease);

          ASSERT_TRUE(raster_thread_merger->IsMerged());
          external_view_embedder->UpdatePostPrerollResult(
              PostPrerollResult::kSuccess);
        }
        end_frame_latch.Signal();
      };
  external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSuccess, true);
  // Set resubmit once to trigger thread merging.
  external_view_embedder->UpdatePostPrerollResult(
      PostPrerollResult::kResubmitFrame);
  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);
  // Pump one frame to trigger thread merging.
  end_frame_latch.Wait();
  // Pump another frame to ensure threads are merged and a regular layer tree is
  // submitted.
  PumpOneFrame(shell.get(), 100, 100, builder);
  // Threads are merged here. PlatformViewNotifyDestroy should be executed
  // successfully.
  ASSERT_TRUE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));
  ValidateDestroyPlatformView(shell.get());

  // Ensure threads are unmerged after platform view destroy
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_OnPlatformViewDestroyWhenThreadsAreMerging
#else
       OnPlatformViewDestroyWhenThreadsAreMerging
#endif
) {
  const size_t kThreadMergingLease = 10;
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        if (should_resubmit_frame && !raster_thread_merger->IsMerged()) {
          raster_thread_merger->MergeWithLease(kThreadMergingLease);
        }
        end_frame_latch.Signal();
      };
  // Start with a regular layer tree with `PostPrerollResult::kSuccess` so we
  // can later check if the rasterizer is tore down using
  // |ValidateDestroyPlatformView|
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSuccess, true);

  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);
  // Pump one frame and threads aren't merged
  end_frame_latch.Wait();
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));

  // Pump a frame with `PostPrerollResult::kResubmitFrame` to start merging
  // threads
  external_view_embedder->UpdatePostPrerollResult(
      PostPrerollResult::kResubmitFrame);
  PumpOneFrame(shell.get(), 100, 100, builder);

  // Now destroy the platform view immediately.
  // Two things can happen here:
  // 1. Threads haven't merged. 2. Threads has already merged.
  // |Shell:OnPlatformViewDestroy| should be able to handle both cases.
  ValidateDestroyPlatformView(shell.get());

  // Ensure threads are unmerged after platform view destroy
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_OnPlatformViewDestroyWithThreadMergerWhileThreadsAreUnmerged
#else
       OnPlatformViewDestroyWithThreadMergerWhileThreadsAreUnmerged
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        end_frame_latch.Signal();
      };
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSuccess, true);
  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };
  PumpOneFrame(shell.get(), 100, 100, builder);
  end_frame_latch.Wait();

  // Threads should not be merged.
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));
  ValidateDestroyPlatformView(shell.get());

  // Ensure threads are unmerged after platform view destroy
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());

  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, OnPlatformViewDestroyWithoutRasterThreadMerger) {
  auto settings = CreateSettingsForFixture();

  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, nullptr);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };
  PumpOneFrame(shell.get(), 100, 100, builder);

  // Threads should not be merged.
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));
  ValidateDestroyPlatformView(shell.get());

  // Ensure threads are unmerged after platform view destroy
  ASSERT_FALSE(fml::TaskRunnerChecker::RunsOnTheSameThread(
      shell->GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId(),
      shell->GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId()));

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());

  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_OnPlatformViewDestroyWithStaticThreadMerging
#else
       OnPlatformViewDestroyWithStaticThreadMerging
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        end_frame_latch.Signal();
      };
  auto external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSuccess, true);
  ThreadHost thread_host(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners(
      "test",
      thread_host.platform_thread->GetTaskRunner(),  // platform
      thread_host.platform_thread->GetTaskRunner(),  // raster
      thread_host.ui_thread->GetTaskRunner(),        // ui
      thread_host.io_thread->GetTaskRunner()         // io
  );
  auto shell = CreateShell(std::move(settings), std::move(task_runners), false,
                           external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };
  PumpOneFrame(shell.get(), 100, 100, builder);
  end_frame_latch.Wait();

  ValidateDestroyPlatformView(shell.get());

  // Validate the platform view can be recreated and destroyed again
  ValidateShell(shell.get());

  DestroyShell(std::move(shell), std::move(task_runners));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
// TODO(https://github.com/flutter/flutter/issues/66056): Deflake on all other
// platforms
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_SkipAndSubmitFrame
#else
       SkipAndSubmitFrame
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  std::shared_ptr<ShellTestExternalViewEmbedder> external_view_embedder;

  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        if (should_resubmit_frame && !raster_thread_merger->IsMerged()) {
          raster_thread_merger->MergeWithLease(10);
          external_view_embedder->UpdatePostPrerollResult(
              PostPrerollResult::kSuccess);
        }
        end_frame_latch.Signal();
      };
  external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kSkipAndRetryFrame, true);

  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);

  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");
  RunEngine(shell.get(), std::move(configuration));

  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  PumpOneFrame(shell.get());

  // `EndFrame` changed the post preroll result to `kSuccess`.
  end_frame_latch.Wait();
  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  // Let the resubmitted frame to run and `GetSubmittedFrameCount` should be
  // called.
  end_frame_latch.Wait();
  ASSERT_EQ(1, external_view_embedder->GetSubmittedFrameCount());

  PlatformViewNotifyDestroyed(shell.get());
  DestroyShell(std::move(shell));
}

// TODO(https://github.com/flutter/flutter/issues/59816): Enable on fuchsia.
TEST_F(ShellTest,
#if defined(OS_FUCHSIA)
       DISABLED_ResubmitFrame
#else
       ResubmitFrame
#endif
) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent end_frame_latch;
  std::shared_ptr<ShellTestExternalViewEmbedder> external_view_embedder;
  fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger_ref;
  auto end_frame_callback =
      [&](bool should_resubmit_frame,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        if (!raster_thread_merger_ref) {
          raster_thread_merger_ref = raster_thread_merger;
        }
        if (should_resubmit_frame && !raster_thread_merger->IsMerged()) {
          raster_thread_merger->MergeWithLease(10);
          external_view_embedder->UpdatePostPrerollResult(
              PostPrerollResult::kSuccess);
        }
        end_frame_latch.Signal();
      };
  external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      end_frame_callback, PostPrerollResult::kResubmitFrame, true);

  auto shell = CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                           false, external_view_embedder);
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");
  RunEngine(shell.get(), std::move(configuration));

  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  PumpOneFrame(shell.get());
  // `EndFrame` changed the post preroll result to `kSuccess` and merged the
  // threads. During the frame, the threads are not merged, So no
  // `external_view_embedder->GetSubmittedFrameCount()` is called.
  end_frame_latch.Wait();
  ASSERT_TRUE(raster_thread_merger_ref->IsMerged());
  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  // This is the resubmitted frame, which threads are also merged.
  end_frame_latch.Wait();
  ASSERT_EQ(1, external_view_embedder->GetSubmittedFrameCount());

  PlatformViewNotifyDestroyed(shell.get());
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
  fml::TimeDelta elapsed = finish - start;

#if FLUTTER_RELEASE
  // Our batch time is 1000ms. Hopefully the 800ms limit is relaxed enough to
  // make it not too flaky.
  ASSERT_TRUE(elapsed >= fml::TimeDelta::FromMilliseconds(800));
#else
  // Our batch time is 100ms. Hopefully the 500ms limit is relaxed enough to
  // make it not too flaky.
  ASSERT_TRUE(elapsed <= fml::TimeDelta::FromMilliseconds(500));
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

TEST_F(ShellTest, WaitForFirstFrameZeroSizeFrame) {
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));
  PumpOneFrame(shell.get(), {1.0, 0.0, 0.0});
  fml::Status result =
      shell->WaitForFirstFrame(fml::TimeDelta::FromMilliseconds(1000));
  ASSERT_FALSE(result.ok());
  ASSERT_EQ(result.code(), fml::StatusCode::kDeadlineExceeded);

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
  ASSERT_FALSE(result.ok());
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
    ASSERT_FALSE(result.ok());
    ASSERT_EQ(result.code(), fml::StatusCode::kFailedPrecondition);
    event.Signal();
  });
  ASSERT_FALSE(event.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(1000)));

  DestroyShell(std::move(shell), std::move(task_runners));
}

static size_t GetRasterizerResourceCacheBytesSync(const Shell& shell) {
  size_t bytes = 0;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell.GetTaskRunners().GetRasterTaskRunner(), [&]() {
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

  // The Vulkan and GL backends set different default values for the resource
  // cache size.
#ifdef SHELL_ENABLE_VULKAN
  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            vulkan::kGrCacheMaxByteSize);
#else
  EXPECT_EQ(GetRasterizerResourceCacheBytesSync(*shell),
            static_cast<size_t>(24 * (1 << 20)));
#endif

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [&shell]() {
        shell->GetPlatformView()->SetViewportMetrics({1.0, 400, 200});
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
        shell->GetPlatformView()->SetViewportMetrics({1.0, 800, 400});
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
        shell->GetPlatformView()->SetViewportMetrics({1.0, 400, 200});
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
        shell->GetPlatformView()->SetViewportMetrics({1.0, 400, 200});
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

  // Called from raster thread.
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrDirectContext* context,
             SkFilterQuality filter_quality) override {}

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
      shell->GetTaskRunners().GetRasterTaskRunner(), [&]() {
        shell->GetPlatformView()->RegisterTexture(mockTexture);
        shell->GetPlatformView()->MarkTextureFrameAvailable(0);
      });
  latch->Wait();

  EXPECT_EQ(mockTexture->frames_available(), 1);

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetRasterTaskRunner(),
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
                           CreateNewThread(),       // raster
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

static void LogSkData(sk_sp<SkData> data, const char* title) {
  FML_LOG(ERROR) << "---------- " << title;
  std::ostringstream ostr;
  for (size_t i = 0; i < data->size();) {
    ostr << std::hex << std::setfill('0') << std::setw(2)
         << static_cast<int>(data->bytes()[i]) << " ";
    i++;
    if (i % 16 == 0 || i == data->size()) {
      FML_LOG(ERROR) << ostr.str();
      ostr.str("");
      ostr.clear();
    }
  }
}

TEST_F(ShellTest, Screenshot) {
  auto settings = CreateSettingsForFixture();
  fml::AutoResetWaitableEvent firstFrameLatch;
  settings.frame_rasterized_callback =
      [&firstFrameLatch](const FrameTiming& t) { firstFrameLatch.Signal(); };

  std::unique_ptr<Shell> shell = CreateShell(settings);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  LayerTreeBuilder builder = [&](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    SkCanvas* recording_canvas =
        recorder.beginRecording(SkRect::MakeXYWH(0, 0, 80, 80));
    recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, 80, 80),
                               SkPaint(SkColor4f::FromColor(SK_ColorRED)));
    auto sk_picture = recorder.finishRecordingAsPicture();
    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(10, 10),
        flutter::SkiaGPUObject<SkPicture>({sk_picture, queue}), false, false);
    root->Add(picture_layer);
  };

  PumpOneFrame(shell.get(), 100, 100, builder);
  firstFrameLatch.Wait();

  std::promise<Rasterizer::Screenshot> screenshot_promise;
  auto screenshot_future = screenshot_promise.get_future();

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetRasterTaskRunner(),
      [&screenshot_promise, &shell]() {
        auto rasterizer = shell->GetRasterizer();
        screenshot_promise.set_value(rasterizer->ScreenshotLastLayerTree(
            Rasterizer::ScreenshotType::CompressedImage, false));
      });

  auto fixtures_dir =
      fml::OpenDirectory(GetFixturesPath(), false, fml::FilePermission::kRead);

  auto reference_png = fml::FileMapping::CreateReadOnly(
      fixtures_dir, "shelltest_screenshot.png");

  // Use MakeWithoutCopy instead of MakeWithCString because we don't want to
  // encode the null sentinel
  sk_sp<SkData> reference_data = SkData::MakeWithoutCopy(
      reference_png->GetMapping(), reference_png->GetSize());

  sk_sp<SkData> screenshot_data = screenshot_future.get().data;
  if (!reference_data->equals(screenshot_data.get())) {
    LogSkData(reference_data, "reference");
    LogSkData(screenshot_data, "screenshot");
    ASSERT_TRUE(false);
  }

  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, CanConvertToAndFromMappings) {
  const size_t buffer_size = 2 << 20;

  uint8_t* buffer = static_cast<uint8_t*>(::malloc(buffer_size));
  ASSERT_NE(buffer, nullptr);
  ASSERT_TRUE(MemsetPatternSetOrCheck(
      buffer, buffer_size, MemsetPatternOp::kMemsetPatternOpSetBuffer));

  std::unique_ptr<fml::Mapping> mapping =
      std::make_unique<fml::NonOwnedMapping>(
          buffer, buffer_size, [](const uint8_t* buffer, size_t size) {
            ::free(const_cast<uint8_t*>(buffer));
          });

  ASSERT_EQ(mapping->GetSize(), buffer_size);

  fml::AutoResetWaitableEvent latch;
  AddNativeCallback(
      "SendFixtureMapping", CREATE_NATIVE_ENTRY([&](auto args) {
        auto mapping_from_dart =
            tonic::DartConverter<std::unique_ptr<fml::Mapping>>::FromDart(
                Dart_GetNativeArgument(args, 0));
        ASSERT_NE(mapping_from_dart, nullptr);
        ASSERT_EQ(mapping_from_dart->GetSize(), buffer_size);
        ASSERT_TRUE(MemsetPatternSetOrCheck(
            const_cast<uint8_t*>(mapping_from_dart->GetMapping()),  // buffer
            mapping_from_dart->GetSize(),                           // size
            MemsetPatternOp::kMemsetPatternOpCheckBuffer            // op
            ));
        latch.Signal();
      }));

  AddNativeCallback(
      "GetFixtureMapping", CREATE_NATIVE_ENTRY([&](auto args) {
        tonic::DartConverter<tonic::DartConverterMapping>::SetReturnValue(
            args, mapping);
      }));

  auto settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("canConvertMappings");
  std::unique_ptr<Shell> shell = CreateShell(settings);
  ASSERT_NE(shell.get(), nullptr);
  RunEngine(shell.get(), std::move(configuration));
  latch.Wait();
  DestroyShell(std::move(shell));
}

// Compares local times as seen by the dart isolate and as seen by this test
// fixture, to a resolution of 1 hour.
//
// This verifies that (1) the isolate is able to get a timezone (doesn't lock
// up for example), and (2) that the host and the isolate agree on what the
// timezone is.
TEST_F(ShellTest, LocaltimesMatch) {
  fml::AutoResetWaitableEvent latch;
  std::string dart_isolate_time_str;

  // See fixtures/shell_test.dart, the callback NotifyLocalTime is declared
  // there.
  AddNativeCallback("NotifyLocalTime", CREATE_NATIVE_ENTRY([&](auto args) {
                      dart_isolate_time_str =
                          tonic::DartConverter<std::string>::FromDart(
                              Dart_GetNativeArgument(args, 0));
                      latch.Signal();
                    }));

  auto settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("localtimesMatch");
  std::unique_ptr<Shell> shell = CreateShell(settings);
  ASSERT_NE(shell.get(), nullptr);
  RunEngine(shell.get(), std::move(configuration));
  latch.Wait();

  char timestr[200];
  const time_t timestamp = time(nullptr);
  const struct tm* local_time = localtime(&timestamp);
  ASSERT_NE(local_time, nullptr)
      << "Could not get local time: errno=" << errno << ": " << strerror(errno);
  // Example: "2020-02-26 14" for 2pm on February 26, 2020.
  const size_t format_size =
      strftime(timestr, sizeof(timestr), "%Y-%m-%d %H", local_time);
  ASSERT_NE(format_size, 0UL)
      << "strftime failed: host time: " << std::string(timestr)
      << " dart isolate time: " << dart_isolate_time_str;

  const std::string host_local_time_str = timestr;

  ASSERT_EQ(dart_isolate_time_str, host_local_time_str)
      << "Local times in the dart isolate and the local time seen by the test "
      << "differ by more than 1 hour, but are expected to be about equal";

  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, CanDecompressImageFromAsset) {
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyWidthHeight", CREATE_NATIVE_ENTRY([&](auto args) {
                      auto width = tonic::DartConverter<int>::FromDart(
                          Dart_GetNativeArgument(args, 0));
                      auto height = tonic::DartConverter<int>::FromDart(
                          Dart_GetNativeArgument(args, 1));
                      ASSERT_EQ(width, 100);
                      ASSERT_EQ(height, 100);
                      latch.Signal();
                    }));

  AddNativeCallback(
      "GetFixtureImage", CREATE_NATIVE_ENTRY([](auto args) {
        auto fixture = OpenFixtureAsMapping("shelltest_screenshot.png");
        tonic::DartConverter<tonic::DartConverterMapping>::SetReturnValue(
            args, fixture);
      }));

  auto settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("canDecompressImageFromAsset");
  std::unique_ptr<Shell> shell = CreateShell(settings);
  ASSERT_NE(shell.get(), nullptr);
  RunEngine(shell.get(), std::move(configuration));
  latch.Wait();
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, OnServiceProtocolGetSkSLsWorks) {
  fml::ScopedTemporaryDirectory base_dir;
  ASSERT_TRUE(base_dir.fd().is_valid());
  PersistentCache::SetCacheDirectoryPath(base_dir.path());
  PersistentCache::ResetCacheForProcess();

  // Create 2 dummy SkSL cache file IE (base32 encoding of A), II (base32
  // encoding of B) with content x and y.
  std::vector<std::string> components = {
      "flutter_engine", GetFlutterEngineVersion(), "skia", GetSkiaVersion(),
      PersistentCache::kSkSLSubdirName};
  auto sksl_dir = fml::CreateDirectory(base_dir.fd(), components,
                                       fml::FilePermission::kReadWrite);
  const std::string x = "x";
  const std::string y = "y";
  auto x_data = std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>{x.begin(), x.end()});
  auto y_data = std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>{y.begin(), y.end()});
  ASSERT_TRUE(fml::WriteAtomically(sksl_dir, "IE", *x_data));
  ASSERT_TRUE(fml::WriteAtomically(sksl_dir, "II", *y_data));

  Settings settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);
  ServiceProtocol::Handler::ServiceProtocolMap empty_params;
  rapidjson::Document document;
  OnServiceProtocol(shell.get(), ServiceProtocolEnum::kGetSkSLs,
                    shell->GetTaskRunners().GetIOTaskRunner(), empty_params,
                    &document);
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);
  DestroyShell(std::move(shell));

  const std::string expected_json1 =
      "{\"type\":\"GetSkSLs\",\"SkSLs\":{\"II\":\"eQ==\",\"IE\":\"eA==\"}}";
  const std::string expected_json2 =
      "{\"type\":\"GetSkSLs\",\"SkSLs\":{\"IE\":\"eA==\",\"II\":\"eQ==\"}}";
  bool json_is_expected = (expected_json1 == buffer.GetString()) ||
                          (expected_json2 == buffer.GetString());
  ASSERT_TRUE(json_is_expected) << buffer.GetString() << " is not equal to "
                                << expected_json1 << " or " << expected_json2;
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
      shell->GetTaskRunners().GetRasterTaskRunner(), [&shell, &latch]() {
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
      shell->GetTaskRunners().GetRasterTaskRunner(), [&shell, &latch]() {
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

static sk_sp<SkPicture> MakeSizedPicture(int width, int height) {
  SkPictureRecorder recorder;
  SkCanvas* recording_canvas =
      recorder.beginRecording(SkRect::MakeXYWH(0, 0, width, height));
  recording_canvas->drawRect(SkRect::MakeXYWH(0, 0, width, height),
                             SkPaint(SkColor4f::FromColor(SK_ColorRED)));
  return recorder.finishRecordingAsPicture();
}

TEST_F(ShellTest, OnServiceProtocolEstimateRasterCacheMemoryWorks) {
  Settings settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);

  // 1. Construct a picture and a picture layer to be raster cached.
  sk_sp<SkPicture> picture = MakeSizedPicture(10, 10);
  fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
      GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
  auto picture_layer = std::make_shared<PictureLayer>(
      SkPoint::Make(0, 0),
      flutter::SkiaGPUObject<SkPicture>({MakeSizedPicture(100, 100), queue}),
      false, false);
  picture_layer->set_paint_bounds(SkRect::MakeWH(100, 100));

  // 2. Rasterize the picture and the picture layer in the raster cache.
  std::promise<bool> rasterized;
  shell->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [&shell, &rasterized, &picture, &picture_layer] {
        auto* compositor_context = shell->GetRasterizer()->compositor_context();
        auto& raster_cache = compositor_context->raster_cache();
        // 2.1. Rasterize the picture. Call Draw multiple times to pass the
        // access threshold (default to 3) so a cache can be generated.
        SkCanvas dummy_canvas;
        bool picture_cache_generated;
        for (int i = 0; i < 4; i += 1) {
          picture_cache_generated =
              raster_cache.Prepare(nullptr,  // GrDirectContext
                                   picture.get(), SkMatrix::I(),
                                   nullptr,  // SkColorSpace
                                   true,     // isComplex
                                   false     // willChange
              );
          raster_cache.Draw(*picture, dummy_canvas);
        }
        ASSERT_TRUE(picture_cache_generated);

        // 2.2. Rasterize the picture layer.
        Stopwatch raster_time;
        Stopwatch ui_time;
        MutatorsStack mutators_stack;
        TextureRegistry texture_registry;
        PrerollContext preroll_context = {
            nullptr,                 /* raster_cache */
            nullptr,                 /* gr_context */
            nullptr,                 /* external_view_embedder */
            mutators_stack, nullptr, /* color_space */
            kGiantRect,              /* cull_rect */
            false,                   /* layer reads from surface */
            raster_time,    ui_time, texture_registry,
            false, /* checkerboard_offscreen_layers */
            1.0f,  /* frame_device_pixel_ratio */
            false, /* has_platform_view */
        };
        raster_cache.Prepare(&preroll_context, picture_layer.get(),
                             SkMatrix::I());
        rasterized.set_value(true);
      });
  rasterized.get_future().wait();

  // 3. Call the service protocol and check its output.
  ServiceProtocol::Handler::ServiceProtocolMap empty_params;
  rapidjson::Document document;
  OnServiceProtocol(
      shell.get(), ServiceProtocolEnum::kEstimateRasterCacheMemory,
      shell->GetTaskRunners().GetRasterTaskRunner(), empty_params, &document);
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);
  std::string expected_json =
      "{\"type\":\"EstimateRasterCacheMemory\",\"layerBytes\":40000,\"picture"
      "Bytes\":400}";
  std::string actual_json = buffer.GetString();
  ASSERT_EQ(actual_json, expected_json);

  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, DiscardLayerTreeOnResize) {
  auto settings = CreateSettingsForFixture();

  SkISize wrong_size = SkISize::Make(400, 100);
  SkISize expected_size = SkISize::Make(400, 200);

  fml::AutoResetWaitableEvent end_frame_latch;
  std::shared_ptr<ShellTestExternalViewEmbedder> external_view_embedder;
  fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger_ref;
  auto end_frame_callback =
      [&](bool should_merge_thread,
          fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
        if (!raster_thread_merger_ref) {
          raster_thread_merger_ref = raster_thread_merger;
        }
        if (should_merge_thread) {
          // TODO(cyanglaz): This test used external_view_embedder so we need to
          // merge the threads here. However, the scenario it is testing is
          // unrelated to platform views. We should consider to update this test
          // so it doesn't require external_view_embedder.
          // https://github.com/flutter/flutter/issues/69895
          raster_thread_merger->MergeWithLease(10);
          external_view_embedder->UpdatePostPrerollResult(
              PostPrerollResult::kSuccess);
        }
        end_frame_latch.Signal();
      };

  external_view_embedder = std::make_shared<ShellTestExternalViewEmbedder>(
      std::move(end_frame_callback), PostPrerollResult::kResubmitFrame, true);

  std::unique_ptr<Shell> shell = CreateShell(
      settings, GetTaskRunnersForFixture(), false, external_view_embedder);

  // Create the surface needed by rasterizer
  PlatformViewNotifyCreated(shell.get());

  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(),
      [&shell, &expected_size]() {
        shell->GetPlatformView()->SetViewportMetrics(
            {1.0, static_cast<double>(expected_size.width()),
             static_cast<double>(expected_size.height())});
      });

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("emptyMain");

  RunEngine(shell.get(), std::move(configuration));

  PumpOneFrame(shell.get(), static_cast<double>(wrong_size.width()),
               static_cast<double>(wrong_size.height()));

  end_frame_latch.Wait();

  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  // Threads will be merged at the end of this frame.
  PumpOneFrame(shell.get(), static_cast<double>(expected_size.width()),
               static_cast<double>(expected_size.height()));

  end_frame_latch.Wait();
  // Even the threads are merged at the end of the frame,
  // during the frame, the threads are not merged,
  // So no `external_view_embedder->GetSubmittedFrameCount()` is called.
  ASSERT_TRUE(raster_thread_merger_ref->IsMerged());
  ASSERT_EQ(0, external_view_embedder->GetSubmittedFrameCount());

  end_frame_latch.Wait();
  ASSERT_EQ(1, external_view_embedder->GetSubmittedFrameCount());
  ASSERT_EQ(expected_size, external_view_embedder->GetLastSubmittedFrameSize());

  PlatformViewNotifyDestroyed(shell.get());
  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, IgnoresInvalidMetrics) {
  fml::AutoResetWaitableEvent latch;
  double last_device_pixel_ratio;
  double last_width;
  double last_height;
  auto native_report_device_pixel_ratio = [&](Dart_NativeArguments args) {
    auto dpr_handle = Dart_GetNativeArgument(args, 0);
    ASSERT_TRUE(Dart_IsDouble(dpr_handle));
    Dart_DoubleValue(dpr_handle, &last_device_pixel_ratio);
    ASSERT_FALSE(last_device_pixel_ratio == 0.0);

    auto width_handle = Dart_GetNativeArgument(args, 1);
    ASSERT_TRUE(Dart_IsDouble(width_handle));
    Dart_DoubleValue(width_handle, &last_width);
    ASSERT_FALSE(last_width == 0.0);

    auto height_handle = Dart_GetNativeArgument(args, 2);
    ASSERT_TRUE(Dart_IsDouble(height_handle));
    Dart_DoubleValue(height_handle, &last_height);
    ASSERT_FALSE(last_height == 0.0);

    latch.Signal();
  };

  Settings settings = CreateSettingsForFixture();
  auto task_runner = CreateNewThread();
  TaskRunners task_runners("test", task_runner, task_runner, task_runner,
                           task_runner);

  AddNativeCallback("ReportMetrics",
                    CREATE_NATIVE_ENTRY(native_report_device_pixel_ratio));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("reportMetrics");

  RunEngine(shell.get(), std::move(configuration));

  task_runner->PostTask([&]() {
    shell->GetPlatformView()->SetViewportMetrics({0.0, 400, 200});
    task_runner->PostTask([&]() {
      shell->GetPlatformView()->SetViewportMetrics({0.8, 0.0, 200});
      task_runner->PostTask([&]() {
        shell->GetPlatformView()->SetViewportMetrics({0.8, 400, 0.0});
        task_runner->PostTask([&]() {
          shell->GetPlatformView()->SetViewportMetrics({0.8, 400, 200.0});
        });
      });
    });
  });
  latch.Wait();
  ASSERT_EQ(last_device_pixel_ratio, 0.8);
  ASSERT_EQ(last_width, 400.0);
  ASSERT_EQ(last_height, 200.0);
  latch.Reset();

  task_runner->PostTask([&]() {
    shell->GetPlatformView()->SetViewportMetrics({1.2, 600, 300});
  });
  latch.Wait();
  ASSERT_EQ(last_device_pixel_ratio, 1.2);
  ASSERT_EQ(last_width, 600.0);
  ASSERT_EQ(last_height, 300.0);

  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, OnServiceProtocolSetAssetBundlePathWorks) {
  Settings settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell(settings);
  RunConfiguration configuration =
      RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("canAccessResourceFromAssetDir");

  // Verify isolate can load a known resource with the
  // default asset directory - kernel_blob.bin
  fml::AutoResetWaitableEvent latch;

  // Callback used to signal whether the resource was loaded successfully.
  bool can_access_resource = false;
  auto native_can_access_resource = [&can_access_resource,
                                     &latch](Dart_NativeArguments args) {
    Dart_Handle exception = nullptr;
    can_access_resource =
        tonic::DartConverter<bool>::FromArguments(args, 0, exception);
    latch.Signal();
  };
  AddNativeCallback("NotifyCanAccessResource",
                    CREATE_NATIVE_ENTRY(native_can_access_resource));

  // Callback used to delay the asset load until after the service
  // protocol method has finished.
  auto native_notify_set_asset_bundle_path =
      [&shell](Dart_NativeArguments args) {
        // Update the asset directory to a bonus path.
        ServiceProtocol::Handler::ServiceProtocolMap params;
        params["assetDirectory"] = "assetDirectory";
        rapidjson::Document document;
        OnServiceProtocol(shell.get(), ServiceProtocolEnum::kSetAssetBundlePath,
                          shell->GetTaskRunners().GetUITaskRunner(), params,
                          &document);
        rapidjson::StringBuffer buffer;
        rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
        document.Accept(writer);
      };
  AddNativeCallback("NotifySetAssetBundlePath",
                    CREATE_NATIVE_ENTRY(native_notify_set_asset_bundle_path));

  RunEngine(shell.get(), std::move(configuration));

  latch.Wait();
  ASSERT_TRUE(can_access_resource);

  DestroyShell(std::move(shell));
}

TEST_F(ShellTest, EngineRootIsolateLaunchesDontTakeVMDataSettings) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  // Make sure the shell launch does not kick off the creation of the VM
  // instance by already creating one upfront.
  auto vm_settings = CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(vm_settings);
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());

  auto settings = vm_settings;
  fml::AutoResetWaitableEvent isolate_create_latch;
  settings.root_isolate_create_callback = [&](const auto& isolate) {
    isolate_create_latch.Signal();
  };
  auto shell = CreateShell(settings);
  ASSERT_TRUE(ValidateShell(shell.get()));
  auto configuration = RunConfiguration::InferFromSettings(settings);
  ASSERT_TRUE(configuration.IsValid());
  RunEngine(shell.get(), std::move(configuration));
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  isolate_create_latch.Wait();
}

TEST_F(ShellTest, AssetManagerSingle) {
  fml::ScopedTemporaryDirectory asset_dir;
  fml::UniqueFD asset_dir_fd = fml::OpenDirectory(
      asset_dir.path().c_str(), false, fml::FilePermission::kRead);

  std::string filename = "test_name";
  std::string content = "test_content";

  bool success = fml::WriteAtomically(asset_dir_fd, filename.c_str(),
                                      fml::DataMapping(content));
  ASSERT_TRUE(success);

  AssetManager asset_manager;
  asset_manager.PushBack(
      std::make_unique<DirectoryAssetBundle>(std::move(asset_dir_fd), false));

  auto mapping = asset_manager.GetAsMapping(filename);
  ASSERT_TRUE(mapping != nullptr);

  std::string result(reinterpret_cast<const char*>(mapping->GetMapping()),
                     mapping->GetSize());

  ASSERT_TRUE(result == content);
}

TEST_F(ShellTest, AssetManagerMulti) {
  fml::ScopedTemporaryDirectory asset_dir;
  fml::UniqueFD asset_dir_fd = fml::OpenDirectory(
      asset_dir.path().c_str(), false, fml::FilePermission::kRead);

  std::vector<std::string> filenames = {
      "good0",
      "bad0",
      "good1",
      "bad1",
  };

  for (auto filename : filenames) {
    bool success = fml::WriteAtomically(asset_dir_fd, filename.c_str(),
                                        fml::DataMapping(filename));
    ASSERT_TRUE(success);
  }

  AssetManager asset_manager;
  asset_manager.PushBack(
      std::make_unique<DirectoryAssetBundle>(std::move(asset_dir_fd), false));

  auto mappings = asset_manager.GetAsMappings("(.*)");
  ASSERT_TRUE(mappings.size() == 4);

  std::vector<std::string> expected_results = {
      "good0",
      "good1",
  };

  mappings = asset_manager.GetAsMappings("(.*)good(.*)");
  ASSERT_TRUE(mappings.size() == expected_results.size());

  for (auto& mapping : mappings) {
    std::string result(reinterpret_cast<const char*>(mapping->GetMapping()),
                       mapping->GetSize());
    ASSERT_NE(
        std::find(expected_results.begin(), expected_results.end(), result),
        expected_results.end());
  }
}

}  // namespace testing
}  // namespace flutter
