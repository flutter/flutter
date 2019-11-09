// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/shell_test.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

ShellTest::ShellTest()
    : native_resolver_(std::make_shared<TestDartNativeResolver>()) {}

ShellTest::~ShellTest() = default;

void ShellTest::SendEnginePlatformMessage(
    Shell* shell,
    fml::RefPtr<PlatformMessage> message) {
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(),
      [shell, &latch, message = std::move(message)]() {
        if (auto engine = shell->weak_engine_) {
          engine->HandlePlatformMessage(std::move(message));
        }
        latch.Signal();
      });
  latch.Wait();
}

void ShellTest::SetSnapshotsAndAssets(Settings& settings) {
  if (!assets_dir_.is_valid()) {
    return;
  }

  settings.assets_dir = assets_dir_.get();

  // In JIT execution, all snapshots are present within the binary itself and
  // don't need to be explicitly suppiled by the embedder.
  if (DartVM::IsRunningPrecompiledCode()) {
    settings.vm_snapshot_data = [this]() {
      return fml::FileMapping::CreateReadOnly(assets_dir_, "vm_snapshot_data");
    };

    settings.isolate_snapshot_data = [this]() {
      return fml::FileMapping::CreateReadOnly(assets_dir_,
                                              "isolate_snapshot_data");
    };

    if (DartVM::IsRunningPrecompiledCode()) {
      settings.vm_snapshot_instr = [this]() {
        return fml::FileMapping::CreateReadExecute(assets_dir_,
                                                   "vm_snapshot_instr");
      };

      settings.isolate_snapshot_instr = [this]() {
        return fml::FileMapping::CreateReadExecute(assets_dir_,
                                                   "isolate_snapshot_instr");
      };
    }
  } else {
    settings.application_kernels = [this]() {
      std::vector<std::unique_ptr<const fml::Mapping>> kernel_mappings;
      kernel_mappings.emplace_back(
          fml::FileMapping::CreateReadOnly(assets_dir_, "kernel_blob.bin"));
      return kernel_mappings;
    };
  }
}

void ShellTest::PlatformViewNotifyCreated(Shell* shell) {
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(), [shell, &latch]() {
        shell->GetPlatformView()->NotifyCreated();
        latch.Signal();
      });
  latch.Wait();
}

void ShellTest::RunEngine(Shell* shell, RunConfiguration configuration) {
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetPlatformTaskRunner(),
      [shell, &latch, &configuration]() {
        shell->RunEngine(std::move(configuration),
                         [&latch](Engine::RunStatus run_status) {
                           ASSERT_EQ(run_status, Engine::RunStatus::Success);
                           latch.Signal();
                         });
      });
  latch.Wait();
}

void ShellTest::RestartEngine(Shell* shell, RunConfiguration configuration) {
  std::promise<bool> restarted;
  fml::TaskRunner::RunNowOrPostTask(
      shell->GetTaskRunners().GetUITaskRunner(),
      [shell, &restarted, &configuration]() {
        restarted.set_value(shell->engine_->Restart(std::move(configuration)));
      });
  ASSERT_TRUE(restarted.get_future().get());
}

void ShellTest::VSyncFlush(Shell* shell, bool& will_draw_new_frame) {
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetPlatformTaskRunner()->PostTask(
      [shell, &will_draw_new_frame, &latch] {
        // The following UI task ensures that all previous UI tasks are flushed.
        fml::AutoResetWaitableEvent ui_latch;
        shell->GetTaskRunners().GetUITaskRunner()->PostTask(
            [&ui_latch, &will_draw_new_frame]() {
              will_draw_new_frame = true;
              ui_latch.Signal();
            });

        ShellTestPlatformView* test_platform_view =
            static_cast<ShellTestPlatformView*>(shell->GetPlatformView().get());
        do {
          test_platform_view->SimulateVSync();
        } while (ui_latch.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(1)));

        latch.Signal();
      });
  latch.Wait();
}

void ShellTest::PumpOneFrame(Shell* shell,
                             double width,
                             double height,
                             LayerTreeBuilder builder) {
  // Set viewport to nonempty, and call Animator::BeginFrame to make the layer
  // tree pipeline nonempty. Without either of this, the layer tree below
  // won't be rasterized.
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, engine = shell->weak_engine_, width, height]() {
        engine->SetViewportMetrics(
            {1, width, height, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
        engine->animator_->BeginFrame(fml::TimePoint::Now(),
                                      fml::TimePoint::Now());
        latch.Signal();
      });
  latch.Wait();

  latch.Reset();
  // Call |Render| to rasterize a layer tree and trigger |OnFrameRasterized|
  fml::WeakPtr<RuntimeDelegate> runtime_delegate = shell->weak_engine_;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, runtime_delegate, &builder]() {
        auto layer_tree = std::make_unique<LayerTree>();
        SkMatrix identity;
        identity.setIdentity();
        auto root_layer = std::make_shared<TransformLayer>(identity);
        layer_tree->set_root_layer(root_layer);
        if (builder) {
          builder(root_layer);
        }
        runtime_delegate->Render(std::move(layer_tree));
        latch.Signal();
      });
  latch.Wait();
}

void ShellTest::DispatchFakePointerData(Shell* shell) {
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetPlatformTaskRunner()->PostTask([&latch, shell]() {
    auto packet = std::make_unique<PointerDataPacket>(1);
    shell->OnPlatformViewDispatchPointerDataPacket(std::move(packet));
    latch.Signal();
  });
  latch.Wait();
}

int ShellTest::UnreportedTimingsCount(Shell* shell) {
  return shell->unreported_timings_.size();
}

void ShellTest::SetNeedsReportTimings(Shell* shell, bool value) {
  shell->SetNeedsReportTimings(value);
}

bool ShellTest::GetNeedsReportTimings(Shell* shell) {
  return shell->needs_report_timings_;
}

std::shared_ptr<txt::FontCollection> ShellTest::GetFontCollection(
    Shell* shell) {
  return shell->weak_engine_->GetFontCollection().GetFontCollection();
}

Settings ShellTest::CreateSettingsForFixture() {
  Settings settings;
  settings.leak_vm = false;
  settings.task_observer_add = [](intptr_t key, fml::closure handler) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, handler);
  };
  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };
  settings.isolate_create_callback = [this]() {
    native_resolver_->SetNativeResolverForIsolate();
  };
  SetSnapshotsAndAssets(settings);
  return settings;
}

TaskRunners ShellTest::GetTaskRunnersForFixture() {
  return {
      "test",
      thread_host_->platform_thread->GetTaskRunner(),  // platform
      thread_host_->gpu_thread->GetTaskRunner(),       // gpu
      thread_host_->ui_thread->GetTaskRunner(),        // ui
      thread_host_->io_thread->GetTaskRunner()         // io
  };
}

std::unique_ptr<Shell> ShellTest::CreateShell(Settings settings,
                                              bool simulate_vsync) {
  return CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                     simulate_vsync);
}

std::unique_ptr<Shell> ShellTest::CreateShell(Settings settings,
                                              TaskRunners task_runners,
                                              bool simulate_vsync) {
  return Shell::Create(
      task_runners, settings,
      [simulate_vsync](Shell& shell) {
        return std::make_unique<ShellTestPlatformView>(
            shell, shell.GetTaskRunners(), simulate_vsync);
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell, shell.GetTaskRunners());
      });
}

void ShellTest::DestroyShell(std::unique_ptr<Shell> shell) {
  DestroyShell(std::move(shell), GetTaskRunnersForFixture());
}

void ShellTest::DestroyShell(std::unique_ptr<Shell> shell,
                             TaskRunners task_runners) {
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(task_runners.GetPlatformTaskRunner(),
                                    [&shell, &latch]() mutable {
                                      shell.reset();
                                      latch.Signal();
                                    });
  latch.Wait();
}

// |testing::ThreadTest|
void ShellTest::SetUp() {
  ThreadTest::SetUp();
  assets_dir_ =
      fml::OpenDirectory(GetFixturesPath(), false, fml::FilePermission::kRead);
  thread_host_ = std::make_unique<ThreadHost>(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::Platform | ThreadHost::Type::IO | ThreadHost::Type::UI |
          ThreadHost::Type::GPU);
}

// |testing::ThreadTest|
void ShellTest::TearDown() {
  ThreadTest::TearDown();
  assets_dir_.reset();
  thread_host_.reset();
}

void ShellTest::AddNativeCallback(std::string name,
                                  Dart_NativeFunction callback) {
  native_resolver_->AddNativeCallback(std::move(name), callback);
}

void ShellTestVsyncClock::SimulateVSync() {
  std::scoped_lock lock(mutex_);
  if (vsync_issued_ >= vsync_promised_.size()) {
    vsync_promised_.emplace_back();
  }
  FML_CHECK(vsync_issued_ < vsync_promised_.size());
  vsync_promised_[vsync_issued_].set_value(vsync_issued_);
  vsync_issued_ += 1;
}

std::future<int> ShellTestVsyncClock::NextVSync() {
  std::scoped_lock lock(mutex_);
  vsync_promised_.emplace_back();
  return vsync_promised_.back().get_future();
}

void ShellTestVsyncWaiter::AwaitVSync() {
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());
  auto vsync_future = clock_.NextVSync();

  auto async_wait = std::async([&vsync_future, this]() {
    vsync_future.wait();

    // Post the `FireCallback` to the Platform thread so earlier Platform tasks
    // (specifically, the `VSyncFlush` call) will be finished before
    // `FireCallback` is executed. This is only needed for our unit tests.
    //
    // Without this, the repeated VSYNC signals in `VSyncFlush` may start both
    // the current frame in the UI thread and the next frame in the secondary
    // callback (both of them are waiting for VSYNCs). That breaks the unit
    // test's assumption that each frame's VSYNC must be issued by different
    // `VSyncFlush` call (which resets the `will_draw_new_frame` bit).
    //
    // For example, HandlesActualIphoneXsInputEvents will fail without this.
    task_runners_.GetPlatformTaskRunner()->PostTask([this]() {
      FireCallback(fml::TimePoint::Now(), fml::TimePoint::Now());
    });
  });
}

ShellTestPlatformView::ShellTestPlatformView(PlatformView::Delegate& delegate,
                                             TaskRunners task_runners,
                                             bool simulate_vsync)
    : PlatformView(delegate, std::move(task_runners)),
      gl_surface_(SkISize::Make(800, 600)),
      simulate_vsync_(simulate_vsync) {}

ShellTestPlatformView::~ShellTestPlatformView() = default;

std::unique_ptr<VsyncWaiter> ShellTestPlatformView::CreateVSyncWaiter() {
  return simulate_vsync_ ? std::make_unique<ShellTestVsyncWaiter>(task_runners_,
                                                                  vsync_clock_)
                         : PlatformView::CreateVSyncWaiter();
}

void ShellTestPlatformView::SimulateVSync() {
  vsync_clock_.SimulateVSync();
}

// |PlatformView|
std::unique_ptr<Surface> ShellTestPlatformView::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceGL>(this, true);
}

// |PlatformView|
PointerDataDispatcherMaker ShellTestPlatformView::GetDispatcherMaker() {
  return [](DefaultPointerDataDispatcher::Delegate& delegate) {
    return std::make_unique<SmoothPointerDataDispatcher>(delegate);
  };
}

// |GPUSurfaceGLDelegate|
std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
ShellTestPlatformView::GLContextMakeCurrent() {
  return std::make_unique<
      RendererContextSwitchManager::RendererContextSwitchPureResult>(
      gl_surface_.MakeCurrent());
}

// |GPUSurfaceGLDelegate|
bool ShellTestPlatformView::GLContextClearCurrent() {
  return gl_surface_.ClearCurrent();
}

// |GPUSurfaceGLDelegate|
bool ShellTestPlatformView::GLContextPresent() {
  return gl_surface_.Present();
}

// |GPUSurfaceGLDelegate|
intptr_t ShellTestPlatformView::GLContextFBO() const {
  return gl_surface_.GetFramebuffer();
}

// |GPUSurfaceGLDelegate|
GPUSurfaceGLDelegate::GLProcResolver ShellTestPlatformView::GetGLProcResolver()
    const {
  return [surface = &gl_surface_](const char* name) -> void* {
    return surface->GetProcAddress(name);
  };
}

// |GPUSurfaceGLDelegate|
ExternalViewEmbedder* ShellTestPlatformView::GetExternalViewEmbedder() {
  return nullptr;
}

std::shared_ptr<RendererContextSwitchManager>
ShellTestPlatformView::GetRendererContextSwitchManager() {
  return nullptr;
}

}  // namespace testing
}  // namespace flutter
