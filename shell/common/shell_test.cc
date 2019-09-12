// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

void ShellTest::PumpOneFrame(Shell* shell) {
  // Set viewport to nonempty, and call Animator::BeginFrame to make the layer
  // tree pipeline nonempty. Without either of this, the layer tree below
  // won't be rasterized.
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, engine = shell->weak_engine_]() {
        engine->SetViewportMetrics(
            {1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0});
        engine->animator_->BeginFrame(fml::TimePoint::Now(),
                                      fml::TimePoint::Now());
        latch.Signal();
      });
  latch.Wait();

  latch.Reset();
  // Call |Render| to rasterize a layer tree and trigger |OnFrameRasterized|
  fml::WeakPtr<RuntimeDelegate> runtime_delegate = shell->weak_engine_;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, runtime_delegate]() {
        auto layer_tree = std::make_unique<LayerTree>();
        SkMatrix identity;
        identity.setIdentity();
        auto root_layer = std::make_shared<TransformLayer>(identity);
        layer_tree->set_root_layer(root_layer);
        runtime_delegate->Render(std::move(layer_tree));
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

std::unique_ptr<Shell> ShellTest::CreateShell(Settings settings) {
  return CreateShell(std::move(settings), GetTaskRunnersForFixture());
}

std::unique_ptr<Shell> ShellTest::CreateShell(Settings settings,
                                              TaskRunners task_runners) {
  return Shell::Create(
      task_runners, settings,
      [](Shell& shell) {
        return std::make_unique<ShellTestPlatformView>(shell,
                                                       shell.GetTaskRunners());
      },
      [](Shell& shell) {
        return std::make_unique<Rasterizer>(shell, shell.GetTaskRunners());
      });
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

ShellTestPlatformView::ShellTestPlatformView(PlatformView::Delegate& delegate,
                                             TaskRunners task_runners)
    : PlatformView(delegate, std::move(task_runners)) {}

ShellTestPlatformView::~ShellTestPlatformView() = default;

// |PlatformView|
std::unique_ptr<Surface> ShellTestPlatformView::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceGL>(this, true);
}

// |GPUSurfaceGLDelegate|
bool ShellTestPlatformView::GLContextMakeCurrent() {
  return gl_surface_.MakeCurrent();
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

}  // namespace testing
}  // namespace flutter
