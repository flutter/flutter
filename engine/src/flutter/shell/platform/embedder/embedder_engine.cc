// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_engine.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/embedder_asset_resolver.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

#if FML_OS_ANDROID
#include "flutter/shell/platform/embedder/android/android_renderer.h"  // nogncheck
#endif  // FML_OS_ANDROID

namespace flutter {

namespace {

void DestroyAssetResolverIfNeeded(
    const FlutterEngineRunConfiguration* run_configuration) {
  if (run_configuration == nullptr ||
      SAFE_ACCESS(run_configuration, struct_size, 0) <
          sizeof(FlutterEngineRunConfiguration)) {
    return;
  }
  const FlutterAssetResolver* c_resolver =
      SAFE_ACCESS(run_configuration, asset_resolver, nullptr);
  if (c_resolver != nullptr &&
      c_resolver->struct_size >= sizeof(FlutterAssetResolver) &&
      c_resolver->destruction_callback != nullptr) {
    c_resolver->destruction_callback(c_resolver->user_data);
  }
}

}  // namespace

struct ShellArgs {
  Settings settings;
  Shell::CreateCallback<PlatformView> on_create_platform_view;
  Shell::CreateCallback<Rasterizer> on_create_rasterizer;
  PlatformData platform_data;
  ShellArgs(const Settings& p_settings,
            Shell::CreateCallback<PlatformView> p_on_create_platform_view,
            Shell::CreateCallback<Rasterizer> p_on_create_rasterizer,
            const PlatformData& p_platform_data)
      : settings(p_settings),
        on_create_platform_view(std::move(p_on_create_platform_view)),
        on_create_rasterizer(std::move(p_on_create_rasterizer)),
        platform_data(p_platform_data) {}
};

EmbedderEngine::EmbedderEngine(
    std::unique_ptr<EmbedderThreadHost> thread_host,
    const flutter::TaskRunners& task_runners,
    const flutter::Settings& settings,
    std::optional<RunConfiguration> run_configuration,
    const Shell::CreateCallback<PlatformView>& on_create_platform_view,
    const Shell::CreateCallback<Rasterizer>& on_create_rasterizer,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver,
    std::vector<ImageGeneratorFactoryRegistration> image_generators,
    const PlatformData& platform_data)
    : thread_host_(std::move(thread_host)),
      task_runners_(task_runners),
      run_configuration_(std::move(run_configuration)),
      shell_args_(std::make_unique<ShellArgs>(settings,
                                              on_create_platform_view,
                                              on_create_rasterizer,
                                              platform_data)),
      external_texture_resolver_(std::move(external_texture_resolver)),
      image_generators_(std::move(image_generators)) {}

EmbedderEngine::EmbedderEngine(
    std::unique_ptr<EmbedderThreadHost> thread_host,
    const flutter::TaskRunners& task_runners,
    const flutter::Settings& settings,
    std::optional<RunConfiguration> run_configuration,
    const PlatformViewFactory& on_create_platform_view,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver,
    std::vector<ImageGeneratorFactoryRegistration> image_generators,
    const PlatformData& platform_data)
    : EmbedderEngine(
          std::move(thread_host),
          task_runners,
          settings,
          std::move(run_configuration),
          [on_create_platform_view](Shell& shell) {
            return on_create_platform_view(shell, shell.GetTaskRunners());
          },
          [](Shell& shell) { return std::make_unique<Rasterizer>(shell); },
          std::move(external_texture_resolver),
          std::move(image_generators),
          platform_data) {}

EmbedderEngine::EmbedderEngine(
    const TaskRunners& task_runners,
    std::unique_ptr<Shell> spawned_shell,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    : task_runners_(task_runners),
      shell_(std::move(spawned_shell)),
      external_texture_resolver_(std::move(external_texture_resolver)) {}

EmbedderEngine::~EmbedderEngine() = default;

bool EmbedderEngine::LaunchShell() {
  if (!shell_args_) {
    FML_DLOG(ERROR) << "Invalid shell arguments.";
    return false;
  }
  PlatformData platform_data = shell_args_->platform_data;
  return LaunchShell(platform_data);
}

bool EmbedderEngine::LaunchShell(const PlatformData& platform_data) {
  if (!shell_args_) {
    FML_DLOG(ERROR) << "Invalid shell arguments.";
    return false;
  }

  if (shell_) {
    FML_DLOG(ERROR) << "Shell already initialized";
  }

  shell_ = Shell::Create(platform_data, task_runners_, shell_args_->settings,
                         shell_args_->on_create_platform_view,
                         shell_args_->on_create_rasterizer);

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

std::unique_ptr<EmbedderEngine> EmbedderEngine::Spawn(
    RunConfiguration run_configuration,
    const std::string& initial_route,
    const Shell::CreateCallback<PlatformView>& on_create_platform_view,
    const Shell::CreateCallback<Rasterizer>& on_create_rasterizer,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    const {
  if (!IsValid()) {
    return nullptr;
  }
  std::unique_ptr<Shell> spawned_shell =
      shell_->Spawn(std::move(run_configuration), initial_route,
                    on_create_platform_view, on_create_rasterizer);
  if (!spawned_shell) {
    return nullptr;
  }
  const TaskRunners task_runners = spawned_shell->GetTaskRunners();
  // std::make_unique cannot reach the private constructor.
  return std::unique_ptr<EmbedderEngine>(
      new EmbedderEngine(task_runners, std::move(spawned_shell),
                         std::move(external_texture_resolver)));
}

std::unique_ptr<EmbedderEngine> EmbedderEngine::Spawn(
    RunConfiguration run_configuration,
    const std::string& initial_route,
    const PlatformViewFactory& on_create_platform_view,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    const {
  return Spawn(
      std::move(run_configuration), initial_route,
      [on_create_platform_view](Shell& shell) {
        return on_create_platform_view(shell, shell.GetTaskRunners());
      },
      [](Shell& shell) { return std::make_unique<Rasterizer>(shell); },
      std::move(external_texture_resolver));
}

std::unique_ptr<EmbedderEngine> EmbedderEngine::Spawn(
    const FlutterEngineRunConfiguration* run_configuration,
    const std::string& initial_route,
    const PlatformViewFactory& on_create_platform_view,
    std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver)
    const {
  if (!IsValid()) {
    DestroyAssetResolverIfNeeded(run_configuration);
    return nullptr;
  }
  std::optional<RunConfiguration> config =
      BuildRunConfiguration(run_configuration);
  if (!config.has_value()) {
    DestroyAssetResolverIfNeeded(run_configuration);
    return nullptr;
  }
  return Spawn(std::move(config.value()), initial_route,
               on_create_platform_view, std::move(external_texture_resolver));
}

std::optional<RunConfiguration> EmbedderEngine::BuildRunConfiguration(
    const FlutterEngineRunConfiguration* config,
    std::string* error_out) {
  auto set_error = [error_out](const char* message) -> std::nullopt_t {
    if (error_out != nullptr) {
      *error_out = message;
    }
    return std::nullopt;
  };

  if (!config) {
    return set_error("Run configuration was null.");
  }

  if (SAFE_ACCESS(config, struct_size, 0) <
      sizeof(FlutterEngineRunConfiguration)) {
    return set_error("FlutterEngineRunConfiguration struct_size is invalid.");
  }

  int argc = SAFE_ACCESS(config, dart_entrypoint_argc, 0);
  const char* const* argv = SAFE_ACCESS(config, dart_entrypoint_argv, nullptr);
  if (argc < 0 || (argc > 0 && argv == nullptr)) {
    return set_error(
        "Invalid Dart entrypoint arguments in FlutterEngineRunConfiguration.");
  }

  const FlutterAssetResolver* c_resolver =
      SAFE_ACCESS(config, asset_resolver, nullptr);
  if (c_resolver != nullptr) {
    if (c_resolver->struct_size < sizeof(FlutterAssetResolver)) {
      return set_error("FlutterAssetResolver struct_size is invalid.");
    }
    if (c_resolver->find_asset_callback == nullptr) {
      return set_error("FlutterAssetResolver find_asset_callback is required.");
    }
  }

  std::unique_ptr<IsolateConfiguration> isolate_configuration;
  if (DartVM::IsRunningPrecompiledCode()) {
    isolate_configuration = IsolateConfiguration::CreateForAppSnapshot();
  } else {
    const char* kernel_path = SAFE_ACCESS(config, kernel_blob_path, nullptr);
    if (!kernel_path || kernel_path[0] == '\0') {
      return set_error(
          "Kernel blob path is required when not running in AOT mode.");
    }
    std::unique_ptr<fml::Mapping> kernel_blob =
        fml::FileMapping::CreateReadOnly(kernel_path);
    if (!kernel_blob) {
      return set_error("Unable to load the kernel blob asset.");
    }
    isolate_configuration =
        IsolateConfiguration::CreateForKernel(std::move(kernel_blob));
  }

  if (!isolate_configuration) {
    return set_error("Could not create isolate configuration.");
  }

  RunConfiguration run_configuration(std::move(isolate_configuration));

  if (c_resolver != nullptr) {
    run_configuration.AddAssetResolver(
        std::make_unique<EmbedderAssetResolver>(*c_resolver));
  }

  const char* entrypoint = SAFE_ACCESS(config, custom_dart_entrypoint, nullptr);
  const char* library =
      SAFE_ACCESS(config, custom_dart_entrypoint_library, nullptr);
  if (entrypoint != nullptr && entrypoint[0] != '\0') {
    if (library != nullptr && library[0] != '\0') {
      run_configuration.SetEntrypointAndLibrary(entrypoint, library);
    } else {
      run_configuration.SetEntrypoint(entrypoint);
    }
  }

  if (argc > 0) {
    std::vector<std::string> arguments(argc);
    for (int i = 0; i < argc; ++i) {
      arguments[i] = argv[i] ? std::string{argv[i]} : std::string{};
    }
    run_configuration.SetEntrypointArgs(std::move(arguments));
  }

  run_configuration.SetEngineId(SAFE_ACCESS(config, engine_id, 0));
  return run_configuration;
}

bool EmbedderEngine::CollectShell() {
  shell_.reset();
#if FML_OS_ANDROID
  // Destroy the AndroidRenderer after the shell (and its platform view and
  // rasterizer) has been collected, but before CollectThreadHost() stops the
  // raster thread (which ~AndroidContextGLSkia posts TeardownContext onto).
  if (android_renderer_slot_) {
    android_renderer_slot_->reset();
  }
#endif  // FML_OS_ANDROID
  return IsValid();
}

void EmbedderEngine::CollectThreadHost() {
  if (!thread_host_) {
    return;
  }

  // Once the collected, EmbedderThreadHost::RunnerIsValid will return false for
  // all runners belonging to this thread host. This must be done with UI task
  // runner blocked to prevent possible raciness that could happen when
  // destroying the thread host in the middle of UI task runner execution. This
  // is not an issue for other runners, because raster task runner should not
  // have anything scheduled after engine shutdown and platform task runner is
  // where this method is called from.
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
  thread_host_.reset();
}

bool EmbedderEngine::RunRootIsolate() {
  if (!IsValid() || !run_configuration_.has_value() ||
      !run_configuration_->IsValid()) {
    return false;
  }
  shell_->RunEngine(std::move(run_configuration_.value()));
  run_configuration_.reset();
  return true;
}

bool EmbedderEngine::LaunchEngine(RunConfiguration run_configuration) {
  if (!IsValid() || !run_configuration.IsValid()) {
    return false;
  }
  shell_->RunEngine(std::move(run_configuration));
  return true;
}

bool EmbedderEngine::IsValid() const {
  return static_cast<bool>(shell_);
}

const TaskRunners& EmbedderEngine::GetTaskRunners() const {
  return task_runners_;
}

bool EmbedderEngine::NotifyCreated() {
  if (!IsValid()) {
    return false;
  }

  is_surface_created_ = true;
  shell_->GetPlatformView()->NotifyCreated();
  return true;
}

bool EmbedderEngine::NotifyDestroyed() {
  if (!IsValid()) {
    return false;
  }

  is_surface_created_ = false;
  shell_->GetPlatformView()->NotifyDestroyed();

  return true;
}

bool EmbedderEngine::IsSurfaceCreated() const {
  return is_surface_created_;
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
  if (!IsValid() || !external_texture_resolver_) {
    return false;
  }
  std::unique_ptr<Texture> resolved_texture =
      external_texture_resolver_->ResolveExternalTexture(texture);
  if (!resolved_texture) {
    return false;
  }
  shell_->GetPlatformView()->RegisterTexture(std::move(resolved_texture));
  return true;
}

void EmbedderEngine::RegisterExternalTexture(std::shared_ptr<Texture> texture) {
  FML_DCHECK(IsValid());
  FML_DCHECK(texture);
  shell_->GetPlatformView()->RegisterTexture(std::move(texture));
}

EmbedderImpellerDeviceContextGetter
EmbedderEngine::GetImpellerDeviceContextGetter() const {
  FML_DCHECK(IsValid());
  // A raw pointer, because the weak pointer may only be checked on the
  // platform thread. The platform view outlives every registered texture: the
  // shell destroys the rasterizer, which owns them, before the platform view.
  // The shell itself asks the platform view for this context on the raster
  // thread when it sets the context up.
  PlatformView* platform_view = shell_->GetPlatformView().get();
  return [platform_view]() { return platform_view->GetImpellerContext(); };
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
  if (task == nullptr || !thread_host_) {
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

Shell& EmbedderEngine::GetShell() {
  FML_DCHECK(shell_);
  return *shell_.get();
}

#if FML_OS_ANDROID
void EmbedderEngine::SetAndroidRenderer(
    std::shared_ptr<AndroidRenderer> renderer) {
  if (!android_renderer_slot_) {
    android_renderer_slot_ =
        std::make_shared<std::shared_ptr<AndroidRenderer>>();
  }
  *android_renderer_slot_ = std::move(renderer);
}

const std::shared_ptr<AndroidRenderer>& EmbedderEngine::GetAndroidRenderer()
    const {
  static const std::shared_ptr<AndroidRenderer> kNullRenderer;
  return android_renderer_slot_ ? *android_renderer_slot_ : kNullRenderer;
}
#endif  // FML_OS_ANDROID

}  // namespace flutter
