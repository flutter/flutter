// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_engine.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

namespace flutter {

struct ShellArgs {
  Settings settings;
  Shell::CreateCallback<PlatformView> on_create_platform_view;
  Shell::CreateCallback<Rasterizer> on_create_rasterizer;
  ShellArgs(const Settings& p_settings,
            Shell::CreateCallback<PlatformView> p_on_create_platform_view,
            Shell::CreateCallback<Rasterizer> p_on_create_rasterizer)
      : settings(p_settings),
        on_create_platform_view(std::move(p_on_create_platform_view)),
        on_create_rasterizer(std::move(p_on_create_rasterizer)) {}
};

EmbedderEngine::EmbedderEngine(
    std::shared_ptr<EmbedderThreadHost> thread_host,
    const flutter::TaskRunners& task_runners,
    const flutter::Settings& settings,
    RunConfiguration run_configuration,
    const Shell::CreateCallback<PlatformView>& on_create_platform_view,
    const Shell::CreateCallback<Rasterizer>& on_create_rasterizer,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver,
    std::vector<ImageGeneratorFactoryRegistration> image_generators)
    : thread_host_(std::move(thread_host)),
      task_runners_(task_runners),
      run_configuration_(std::move(run_configuration)),
      shell_args_(std::make_unique<ShellArgs>(settings,
                                              on_create_platform_view,
                                              on_create_rasterizer)),
      external_texture_resolver_(std::move(external_texture_resolver)),
      image_generators_(std::move(image_generators)) {}

EmbedderEngine::EmbedderEngine(
    std::shared_ptr<EmbedderThreadHost> thread_host,
    const flutter::TaskRunners& task_runners,
    std::unique_ptr<Shell> shell,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    : thread_host_(std::move(thread_host)),
      task_runners_(task_runners),
      run_configuration_(nullptr),
      shell_(std::move(shell)),
      external_texture_resolver_(std::move(external_texture_resolver)) {}

EmbedderEngine::EmbedderEngine(const flutter::TaskRunners& task_runners,
                               std::unique_ptr<Shell> shell)
    : task_runners_(task_runners),
      run_configuration_(nullptr),
      shell_(std::move(shell)) {}

EmbedderEngine::~EmbedderEngine() = default;

bool EmbedderEngine::LaunchShell() {
  if (!shell_args_) {
    FML_DLOG(ERROR) << "Invalid shell arguments.";
    return false;
  }

  if (shell_) {
    FML_DLOG(ERROR) << "Shell already initialized";
  }

  shell_ = Shell::Create(
      flutter::PlatformData(), task_runners_, shell_args_->settings,
      shell_args_->on_create_platform_view, shell_args_->on_create_rasterizer);

  for (auto& image_generator : image_generators_) {
    RegisterImageGenerator(std::move(image_generator.factory),
                           image_generator.priority);
  }
  image_generators_.clear();

  // Reset the args no matter what. They will never be used to initialize a
  // shell again.
  shell_args_.reset();

  return IsValid();
}

bool EmbedderEngine::CollectShell() {
  shell_.reset();
  return IsValid();
}

void EmbedderEngine::CollectThreadHost() {
  if (!thread_host_) {
    return;
  }

  // Once collected, EmbedderThreadHost::RunnerIsValid will return false for
  // all runners belonging to this thread host. This must be done with UI task
  // runner blocked to prevent possible raciness that could happen when
  // destroying the thread host in the middle of UI task runner execution. This
  // is not an issue for other runners, because raster task runner should not
  // have anything scheduled after engine shutdown and platform task runner is
  // where this method is called from.
  if (thread_host_.use_count() == 1) {
    if (thread_host_->GetTaskRunners().GetUITaskRunner() &&
        !thread_host_->GetTaskRunners()
             .GetUITaskRunner()
             ->RunsTasksOnCurrentThread()) {
      fml::AutoResetWaitableEvent ui_thread_running;
      fml::AutoResetWaitableEvent ui_thread_block;
      fml::AutoResetWaitableEvent ui_thread_finished;

      thread_host_->GetTaskRunners().GetUITaskRunner()->PostTask([&] {
        ui_thread_running.Signal();
        ui_thread_block.Wait();
        ui_thread_finished.Signal();
      });

      // Wait until the task is running on the UI thread.
      ui_thread_running.Wait();
      thread_host_->InvalidateActiveRunners();
      ui_thread_block.Signal();

      // Needed to keep ui_thread_block in scope until the UI thread execution
      // finishes.
      ui_thread_finished.Wait();
    } else {
      thread_host_->InvalidateActiveRunners();
    }
  }
  thread_host_.reset();
}

bool EmbedderEngine::RunRootIsolate() {
  if (!IsValid() || !run_configuration_.IsValid()) {
    return false;
  }
  shell_->RunEngine(std::move(run_configuration_));
  return true;
}

bool EmbedderEngine::IsValid() const {
  return static_cast<bool>(shell_);
}

const TaskRunners& EmbedderEngine::GetTaskRunners() const {
  return task_runners_;
}

std::shared_ptr<EmbedderThreadHost> EmbedderEngine::GetThreadHost() const {
  return thread_host_;
}

bool EmbedderEngine::NotifyCreated() {
  if (!IsValid()) {
    return false;
  }

  shell_->GetPlatformView()->NotifyCreated();
  return true;
}

bool EmbedderEngine::NotifyDestroyed() {
  if (!IsValid()) {
    return false;
  }

  shell_->GetPlatformView()->NotifyDestroyed();

  return true;
}

bool EmbedderEngine::SetViewportMetrics(
    int64_t view_id,
    const flutter::ViewportMetrics& metrics) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetViewportMetrics(view_id, metrics);
  return true;
}

bool EmbedderEngine::DispatchPointerDataPacket(
    std::unique_ptr<flutter::PointerDataPacket> packet) {
  if (!IsValid() || !packet) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->DispatchPointerDataPacket(std::move(packet));
  return true;
}

bool EmbedderEngine::SendPlatformMessage(
    std::unique_ptr<PlatformMessage> message) {
  if (!IsValid() || !message) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->DispatchPlatformMessage(std::move(message));
  return true;
}

bool EmbedderEngine::RegisterTexture(int64_t texture) {
  if (!IsValid()) {
    return false;
  }
  shell_->GetPlatformView()->RegisterTexture(
      external_texture_resolver_->ResolveExternalTexture(texture));
  return true;
}

bool EmbedderEngine::UnregisterTexture(int64_t texture) {
  if (!IsValid()) {
    return false;
  }
  shell_->GetPlatformView()->UnregisterTexture(texture);
  return true;
}

bool EmbedderEngine::MarkTextureFrameAvailable(int64_t texture) {
  if (!IsValid()) {
    return false;
  }
  shell_->GetPlatformView()->MarkTextureFrameAvailable(texture);
  return true;
}

bool EmbedderEngine::SetSemanticsEnabled(bool enabled) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetSemanticsEnabled(enabled);
  return true;
}

bool EmbedderEngine::SetAccessibilityFeatures(int32_t flags) {
  if (!IsValid()) {
    return false;
  }
  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetAccessibilityFeatures(flags);
  return true;
}

bool EmbedderEngine::DispatchSemanticsAction(int64_t view_id,
                                             int node_id,
                                             flutter::SemanticsAction action,
                                             fml::MallocMapping args) {
  if (!IsValid()) {
    return false;
  }
  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->DispatchSemanticsAction(view_id, node_id, action,
                                         std::move(args));
  return true;
}

bool EmbedderEngine::OnVsyncEvent(intptr_t baton,
                                  fml::TimePoint frame_start_time,
                                  fml::TimePoint frame_target_time) {
  if (!IsValid()) {
    return false;
  }

  return VsyncWaiterEmbedder::OnEmbedderVsync(
      task_runners_, baton, frame_start_time, frame_target_time);
}

bool EmbedderEngine::ReloadSystemFonts() {
  if (!IsValid()) {
    return false;
  }

  return shell_->ReloadSystemFonts();
}

bool EmbedderEngine::PostRenderThreadTask(const fml::closure& task) {
  if (!IsValid()) {
    return false;
  }

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(task);
  return true;
}

bool EmbedderEngine::RunTask(const FlutterTask* task) {
  // The shell doesn't need to be running or valid for access to the thread
  // host. This is why there is no `IsValid` check here. This allows embedders
  // to perform custom task runner interop before the shell is running.
  if (task == nullptr) {
    return false;
  }
  auto result = thread_host_->PostTask(reinterpret_cast<intptr_t>(task->runner),
                                       task->task);
  // If the UI and platform threads are separate, the microtask queue is
  // flushed through MessageLoopTaskQueues observer.
  // If the UI and platform threads are merged, the UI task runner has no
  // associated task queue, and microtasks need to be flushed manually
  // after running the task.
  if (result && shell_ && task_runners_.GetUITaskRunner() &&
      task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread() &&
      !task_runners_.GetUITaskRunner()->GetTaskQueueId().is_valid()) {
    shell_->FlushMicrotaskQueue();
  }

  return result;
}

bool EmbedderEngine::PostTaskOnEngineManagedNativeThreads(
    const std::function<void(FlutterNativeThreadType)>& closure) const {
  if (!IsValid() || closure == nullptr) {
    return false;
  }

  const auto trampoline = [closure](
                              FlutterNativeThreadType type,
                              const fml::RefPtr<fml::TaskRunner>& runner) {
    runner->PostTask([closure, type] { closure(type); });
  };

  // Post the task to all thread host threads.
  const auto& task_runners = shell_->GetTaskRunners();
  trampoline(kFlutterNativeThreadTypeRender,
             task_runners.GetRasterTaskRunner());
  trampoline(kFlutterNativeThreadTypeWorker, task_runners.GetIOTaskRunner());
  trampoline(kFlutterNativeThreadTypeUI, task_runners.GetUITaskRunner());
  trampoline(kFlutterNativeThreadTypePlatform,
             task_runners.GetPlatformTaskRunner());

  // Post the task to all worker threads.
  auto vm = shell_->GetDartVM();
  vm->GetConcurrentMessageLoop()->PostTaskToAllWorkers(
      [closure]() { closure(kFlutterNativeThreadTypeWorker); });

  return true;
}

bool EmbedderEngine::ScheduleFrame() {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->ScheduleFrame();
  return true;
}

Shell& EmbedderEngine::GetShell() {
  FML_DCHECK(shell_);
  return *shell_.get();
}

std::unique_ptr<EmbedderEngine> EmbedderEngine::Spawn(
    const std::shared_ptr<EmbedderThreadHost>& thread_host,
    const TaskRunners& task_runners,
    RunConfiguration run_configuration,
    const std::string& initial_route,
    const Shell::CreateCallback<PlatformView>& on_create_platform_view,
    const Shell::CreateCallback<Rasterizer>& on_create_rasterizer,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    const {
  if (!IsValid()) {
    FML_LOG(ERROR) << "Cannot spawn from an invalid engine.";
    return nullptr;
  }

  std::unique_ptr<Shell> spawned_shell =
      shell_->Spawn(std::move(run_configuration), initial_route,
                    on_create_platform_view, on_create_rasterizer);
  if (!spawned_shell) {
    FML_LOG(ERROR) << "Failed to spawn shell.";
    return nullptr;
  }

  std::shared_ptr<EmbedderThreadHost> target_thread_host =
      thread_host ? thread_host : thread_host_;

  return std::make_unique<EmbedderEngine>(
      std::move(target_thread_host), task_runners, std::move(spawned_shell),
      std::move(external_texture_resolver));
}

bool EmbedderEngine::UpdateAssetResolver(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->UpdateAssetResolverByType(std::move(updated_asset_resolver),
                                           type);
  return true;
}

bool EmbedderEngine::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->LoadDartDeferredLibrary(loading_unit_id,
                                         std::move(snapshot_data),
                                         std::move(snapshot_instructions));
  return true;
}

bool EmbedderEngine::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string& error_message,
    bool transient) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                              transient);
  return true;
}

bool EmbedderEngine::RegisterImageGenerator(ImageGeneratorFactory factory,
                                            int32_t priority) {
  if (!IsValid() || !shell_) {
    return false;
  }

  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetPlatformTaskRunner(),
      fml::MakeCopyable(
          [this, &latch, factory = std::move(factory), priority]() mutable {
            if (IsValid()) {
              shell_->RegisterImageDecoder(std::move(factory), priority);
            }
            latch.Signal();
          }));
  latch.Wait();
  return true;
}

Rasterizer::Screenshot EmbedderEngine::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) const {
  if (!IsValid()) {
    return {};
  }
  return shell_->Screenshot(type, base64_encode);
}

}  // namespace flutter
