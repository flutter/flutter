// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path.h"

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

TEST_F(ShellTest, PathVolatilityOldPathsBecomeNonVolatile) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto native_validate_path = [message_latch](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);
    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        handle, tonic::DartWrappable::kPeerIndex, &peer);
    EXPECT_FALSE(Dart_IsError(result));
    CanvasPath* path = reinterpret_cast<CanvasPath*>(peer);
    EXPECT_TRUE(path);
    EXPECT_TRUE(path->path().isVolatile());
    std::shared_ptr<VolatilePathTracker> tracker =
        UIDartState::Current()->GetVolatilePathTracker();
    EXPECT_TRUE(tracker);

    for (int i = 0; i < VolatilePathTracker::kFramesOfVolatility; i++) {
      EXPECT_TRUE(path->path().isVolatile());
      tracker->OnFrame();
    }
    EXPECT_FALSE(path->path().isVolatile());
    message_latch->Signal();
  };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidatePath", CREATE_NATIVE_ENTRY(native_validate_path));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("createPath");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, PathVolatilityGCRemovesPathFromTracker) {
  static_assert(VolatilePathTracker::kFramesOfVolatility > 1);
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto native_validate_path = [message_latch](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);
    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        handle, tonic::DartWrappable::kPeerIndex, &peer);
    EXPECT_FALSE(Dart_IsError(result));
    CanvasPath* path = reinterpret_cast<CanvasPath*>(peer);
    EXPECT_TRUE(path);
    EXPECT_TRUE(path->path().isVolatile());
    std::shared_ptr<VolatilePathTracker> tracker =
        UIDartState::Current()->GetVolatilePathTracker();
    EXPECT_TRUE(tracker);
    EXPECT_EQ(GetLiveTrackedPathCount(tracker), 1ul);
    EXPECT_TRUE(path->path().isVolatile());

    tracker->OnFrame();
    EXPECT_EQ(GetLiveTrackedPathCount(tracker), 1ul);
    EXPECT_TRUE(path->path().isVolatile());

    // simulate GC
    path->Release();
    EXPECT_EQ(GetLiveTrackedPathCount(tracker), 0ul);

    tracker->OnFrame();
    EXPECT_EQ(GetLiveTrackedPathCount(tracker), 0ul);

    message_latch->Signal();
  };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidatePath", CREATE_NATIVE_ENTRY(native_validate_path));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("createPath");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  DestroyShell(std::move(shell), std::move(task_runners));
}

// Screen diffing tests use deterministic rendering. Allowing a path to be
// volatile or not for an individual frame can result in minor pixel differences
// that cause the test to fail.
// If deterministic rendering is enabled, the tracker should be disabled and
// paths should always be non-volatile.
TEST_F(ShellTest, DeterministicRenderingDisablesPathVolatility) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();

  auto native_validate_path = [message_latch](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);
    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        handle, tonic::DartWrappable::kPeerIndex, &peer);
    EXPECT_FALSE(Dart_IsError(result));
    CanvasPath* path = reinterpret_cast<CanvasPath*>(peer);
    EXPECT_TRUE(path);
    EXPECT_FALSE(path->path().isVolatile());
    std::shared_ptr<VolatilePathTracker> tracker =
        UIDartState::Current()->GetVolatilePathTracker();
    EXPECT_TRUE(tracker);
    EXPECT_FALSE(tracker->enabled());

    for (int i = 0; i < VolatilePathTracker::kFramesOfVolatility; i++) {
      tracker->OnFrame();
      EXPECT_FALSE(path->path().isVolatile());
    }
    EXPECT_FALSE(path->path().isVolatile());
    message_latch->Signal();
  };

  Settings settings = CreateSettingsForFixture();
  settings.skia_deterministic_rendering_on_cpu = true;
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ValidatePath", CREATE_NATIVE_ENTRY(native_validate_path));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("createPath");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();

  DestroyShell(std::move(shell), std::move(task_runners));
}

}  // namespace testing
}  // namespace flutter
