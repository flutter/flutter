// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SHELL_TEST_H_
#define FLUTTER_SHELL_COMMON_SHELL_TEST_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/test_gl_surface.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

class ShellTest : public ThreadTest {
 public:
  ShellTest();

  ~ShellTest();

  Settings CreateSettingsForFixture();
  std::unique_ptr<Shell> CreateShell(Settings settings,
                                     bool simulate_vsync = false);
  std::unique_ptr<Shell> CreateShell(Settings settings,
                                     TaskRunners task_runners,
                                     bool simulate_vsync = false);
  void DestroyShell(std::unique_ptr<Shell> shell);
  void DestroyShell(std::unique_ptr<Shell> shell, TaskRunners task_runners);
  TaskRunners GetTaskRunnersForFixture();

  void SendEnginePlatformMessage(Shell* shell,
                                 fml::RefPtr<PlatformMessage> message);

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

  static void PlatformViewNotifyCreated(
      Shell* shell);  // This creates the surface
  static void RunEngine(Shell* shell, RunConfiguration configuration);
  static void RestartEngine(Shell* shell, RunConfiguration configuration);

  /// Issue as many VSYNC as needed to flush the UI tasks so far, and reset
  /// the `will_draw_new_frame` to true.
  static void VSyncFlush(Shell* shell, bool& will_draw_new_frame);

  /// Given the root layer, this callback builds the layer tree to be rasterized
  /// in PumpOneFrame.
  using LayerTreeBuilder =
      std::function<void(std::shared_ptr<ContainerLayer> root)>;
  static void PumpOneFrame(Shell* shell,
                           double width = 1,
                           double height = 1,
                           LayerTreeBuilder = {});

  static void DispatchFakePointerData(Shell* shell);

  // Declare |UnreportedTimingsCount|, |GetNeedsReportTimings| and
  // |SetNeedsReportTimings| inside |ShellTest| mainly for easier friend class
  // declarations as shell unit tests and Shell are in different name spaces.

  static bool GetNeedsReportTimings(Shell* shell);
  static void SetNeedsReportTimings(Shell* shell, bool value);

  std::shared_ptr<txt::FontCollection> GetFontCollection(Shell* shell);

  // Do not assert |UnreportedTimingsCount| to be positive in any tests.
  // Otherwise those tests will be flaky as the clearing of unreported timings
  // is unpredictive.
  static int UnreportedTimingsCount(Shell* shell);

 protected:
  // |testing::ThreadTest|
  void SetUp() override;

  // |testing::ThreadTest|
  void TearDown() override;

 private:
  fml::UniqueFD assets_dir_;
  std::shared_ptr<TestDartNativeResolver> native_resolver_;
  std::unique_ptr<ThreadHost> thread_host_;

  void SetSnapshotsAndAssets(Settings& settings);
};

class ShellTestVsyncClock {
 public:
  /// Simulate that a vsync signal is triggered.
  void SimulateVSync();

  /// A future that will return the index the next vsync signal.
  std::future<int> NextVSync();

 private:
  std::mutex mutex_;
  std::vector<std::promise<int>> vsync_promised_;
  size_t vsync_issued_ = 0;
};

class ShellTestVsyncWaiter : public VsyncWaiter {
 public:
  ShellTestVsyncWaiter(TaskRunners task_runners, ShellTestVsyncClock& clock)
      : VsyncWaiter(std::move(task_runners)), clock_(clock) {}

 protected:
  void AwaitVSync() override;

 private:
  ShellTestVsyncClock& clock_;
};

class ShellTestPlatformView : public PlatformView, public GPUSurfaceGLDelegate {
 public:
  ShellTestPlatformView(PlatformView::Delegate& delegate,
                        TaskRunners task_runners,
                        bool simulate_vsync = false);

  ~ShellTestPlatformView() override;

  void SimulateVSync();

 private:
  TestGLSurface gl_surface_;

  bool simulate_vsync_ = false;
  ShellTestVsyncClock vsync_clock_;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  PointerDataDispatcherMaker GetDispatcherMaker() override;

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
  GLContextMakeCurrent() override;

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent() override;

  // |GPUSurfaceGLDelegate|
  intptr_t GLContextFBO() const override;

  // |GPUSurfaceGLDelegate|
  GLProcResolver GetGLProcResolver() const override;

  // |GPUSurfaceGLDelegate|
  ExternalViewEmbedder* GetExternalViewEmbedder() override;

  std::shared_ptr<RendererContextSwitchManager>
  GetRendererContextSwitchManager() override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTestPlatformView);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SHELL_TEST_H_
