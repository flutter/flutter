// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/shell_test_platform_view.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/vsync_waiter_fallback.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

ShellTest::ShellTest()
    : thread_host_("io.flutter.test." + GetCurrentTestName() + ".",
                   ThreadHost::Type::Platform | ThreadHost::Type::IO |
                       ThreadHost::Type::UI | ThreadHost::Type::GPU) {}

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
  PumpOneFrame(shell, {1.0, width, height}, std::move(builder));
}

void ShellTest::PumpOneFrame(Shell* shell,
                             flutter::ViewportMetrics viewport_metrics,
                             LayerTreeBuilder builder) {
  // Set viewport to nonempty, and call Animator::BeginFrame to make the layer
  // tree pipeline nonempty. Without either of this, the layer tree below
  // won't be rasterized.
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, engine = shell->weak_engine_, viewport_metrics]() {
        engine->SetViewportMetrics(std::move(viewport_metrics));
        const auto frame_begin_time = fml::TimePoint::Now();
        const auto frame_end_time =
            frame_begin_time + fml::TimeDelta::FromSecondsF(1.0 / 60.0);
        engine->animator_->BeginFrame(frame_begin_time, frame_end_time);
        latch.Signal();
      });
  latch.Wait();

  latch.Reset();
  // Call |Render| to rasterize a layer tree and trigger |OnFrameRasterized|
  fml::WeakPtr<RuntimeDelegate> runtime_delegate = shell->weak_engine_;
  shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [&latch, runtime_delegate, &builder, viewport_metrics]() {
        auto layer_tree = std::make_unique<LayerTree>(
            SkISize::Make(viewport_metrics.physical_width,
                          viewport_metrics.physical_height),
            static_cast<float>(viewport_metrics.physical_depth),
            static_cast<float>(viewport_metrics.device_pixel_ratio));
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
  auto packet = std::make_unique<PointerDataPacket>(1);
  DispatchPointerData(shell, std::move(packet));
}

void ShellTest::DispatchPointerData(Shell* shell,
                                    std::unique_ptr<PointerDataPacket> packet) {
  fml::AutoResetWaitableEvent latch;
  shell->GetTaskRunners().GetPlatformTaskRunner()->PostTask(
      [&latch, shell, &packet]() {
        // Goes through PlatformView to ensure packet is corrected converted.
        shell->GetPlatformView()->DispatchPointerDataPacket(std::move(packet));
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

void ShellTest::OnServiceProtocol(
    Shell* shell,
    ServiceProtocolEnum some_protocol,
    fml::RefPtr<fml::TaskRunner> task_runner,
    const ServiceProtocol::Handler::ServiceProtocolMap& params,
    rapidjson::Document* response) {
  std::promise<bool> finished;
  fml::TaskRunner::RunNowOrPostTask(
      task_runner, [shell, some_protocol, params, response, &finished]() {
        switch (some_protocol) {
          case ServiceProtocolEnum::kGetSkSLs:
            shell->OnServiceProtocolGetSkSLs(params, response);
            break;
          case ServiceProtocolEnum::kEstimateRasterCacheMemory:
            shell->OnServiceProtocolEstimateRasterCacheMemory(params, response);
            break;
          case ServiceProtocolEnum::kSetAssetBundlePath:
            shell->OnServiceProtocolSetAssetBundlePath(params, response);
            break;
          case ServiceProtocolEnum::kRunInView:
            shell->OnServiceProtocolRunInView(params, response);
            break;
        }
        finished.set_value(true);
      });
  finished.get_future().wait();
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
#if OS_FUCHSIA
  settings.verbose_logging = true;
#endif
  SetSnapshotsAndAssets(settings);
  return settings;
}

TaskRunners ShellTest::GetTaskRunnersForFixture() {
  return {
      "test",
      thread_host_.platform_thread->GetTaskRunner(),  // platform
      thread_host_.raster_thread->GetTaskRunner(),    // raster
      thread_host_.ui_thread->GetTaskRunner(),        // ui
      thread_host_.io_thread->GetTaskRunner()         // io
  };
}

fml::TimePoint ShellTest::GetLatestFrameTargetTime(Shell* shell) const {
  return shell->GetLatestFrameTargetTime();
}

std::unique_ptr<Shell> ShellTest::CreateShell(Settings settings,
                                              bool simulate_vsync) {
  return CreateShell(std::move(settings), GetTaskRunnersForFixture(),
                     simulate_vsync);
}

std::unique_ptr<Shell> ShellTest::CreateShell(
    Settings settings,
    TaskRunners task_runners,
    bool simulate_vsync,
    std::shared_ptr<ShellTestExternalViewEmbedder>
        shell_test_external_view_embedder) {
  const auto vsync_clock = std::make_shared<ShellTestVsyncClock>();
  CreateVsyncWaiter create_vsync_waiter = [&]() {
    if (simulate_vsync) {
      return static_cast<std::unique_ptr<VsyncWaiter>>(
          std::make_unique<ShellTestVsyncWaiter>(task_runners, vsync_clock));
    } else {
      return static_cast<std::unique_ptr<VsyncWaiter>>(
          std::make_unique<VsyncWaiterFallback>(task_runners));
    }
  };
  return Shell::Create(
      task_runners, settings,
      [vsync_clock, &create_vsync_waiter,
       shell_test_external_view_embedder](Shell& shell) {
        return ShellTestPlatformView::Create(
            shell, shell.GetTaskRunners(), vsync_clock,
            std::move(create_vsync_waiter),
            ShellTestPlatformView::BackendType::kDefaultBackend,
            shell_test_external_view_embedder);
      },
      [](Shell& shell) { return std::make_unique<Rasterizer>(shell); });
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

}  // namespace testing
}  // namespace flutter
