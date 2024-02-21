// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/common/settings.h"
#include "flutter/lib/ui/volatile_path_tracker.h"
#include "flutter/lib/ui/window/platform_message_response_dart.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/fixture_test.h"

#include <future>

namespace flutter {

class Fixture : public testing::FixtureTest {
  void TestBody() override {};
};

static void BM_PlatformMessageResponseDartComplete(benchmark::State& state) {
  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      "test", ThreadHost::Type::kPlatform | ThreadHost::Type::kRaster |
                  ThreadHost::Type::kIo | ThreadHost::Type::kUi));
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  Fixture fixture;
  auto settings = fixture.CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(settings);
  auto isolate =
      testing::RunDartCodeInIsolate(vm_ref, settings, task_runners, "main", {},
                                    testing::GetDefaultKernelFilePath(), {});

  while (state.KeepRunning()) {
    state.PauseTiming();
    bool successful = isolate->RunInIsolateScope([&]() -> bool {
      // Simulate a message of 3 MB
      std::vector<uint8_t> data(3 << 20, 0);
      std::unique_ptr<fml::Mapping> mapping =
          std::make_unique<fml::DataMapping>(data);

      Dart_Handle library = Dart_RootLibrary();
      Dart_Handle closure =
          Dart_GetField(library, Dart_NewStringFromCString("messageCallback"));

      auto message = fml::MakeRefCounted<PlatformMessageResponseDart>(
          tonic::DartPersistentValue(isolate->get(), closure),
          thread_host.ui_thread->GetTaskRunner(), "");

      message->Complete(std::move(mapping));

      return true;
    });
    FML_CHECK(successful);
    state.ResumeTiming();

    // We skip timing everything above because the copy triggered by
    // message->Complete is a task posted on the UI thread. The following wait
    // for a UI task would let us know when that copy is done.
    std::promise<bool> completed;
    task_runners.GetUITaskRunner()->PostTask(
        [&completed] { completed.set_value(true); });
    completed.get_future().wait();
  }
}

static void BM_PathVolatilityTracker(benchmark::State& state) {
  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      "test", ThreadHost::Type::kPlatform | ThreadHost::Type::kRaster |
                  ThreadHost::Type::kIo | ThreadHost::Type::kUi));
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  VolatilePathTracker tracker(task_runners.GetUITaskRunner(), true);

  while (state.KeepRunning()) {
    std::vector<std::shared_ptr<VolatilePathTracker::TrackedPath>> paths;
    constexpr int path_count = 1000;
    for (int i = 0; i < path_count; i++) {
      auto path = std::make_shared<VolatilePathTracker::TrackedPath>();
      path->path = SkPath();
      path->path.setIsVolatile(true);
      paths.push_back(std::move(path));
    }

    fml::AutoResetWaitableEvent latch;
    task_runners.GetUITaskRunner()->PostTask([&]() {
      for (const auto& path : paths) {
        tracker.Track(path);
      }
      latch.Signal();
    });

    latch.Wait();

    task_runners.GetUITaskRunner()->PostTask([&]() { tracker.OnFrame(); });

    for (int i = 0; i < path_count - 10; ++i) {
      paths[i].reset();
    }

    task_runners.GetUITaskRunner()->PostTask([&]() { tracker.OnFrame(); });

    latch.Reset();
    task_runners.GetUITaskRunner()->PostTask([&]() { latch.Signal(); });
    latch.Wait();
  }
}

BENCHMARK(BM_PlatformMessageResponseDartComplete)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK(BM_PathVolatilityTracker)->Unit(benchmark::kMillisecond);

}  // namespace flutter
