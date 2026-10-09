// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <pthread.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <memory>
#include <optional>

#include <string>
#include <utility>

#include "common/settings.h"
#include "flutter/fml/cpu_affinity.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_display.h"
#include "flutter/shell/platform/android/android_image_generator.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"

namespace flutter {

/// Inheriting ThreadConfigurer and use Android platform thread API to configure
/// the thread priorities
static void AndroidPlatformThreadConfigSetter(
    const fml::Thread::ThreadConfig& config) {
  // set thread name
  fml::Thread::SetCurrentThreadName(config);
  // set thread priority
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kBackground: {
      fml::RequestAffinity(fml::CpuAffinity::kEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, 10) != 0) {
        FML_LOG(ERROR) << "Failed to set IO task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::kDisplay: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, -1) != 0) {
        FML_LOG(ERROR) << "Failed to set UI task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::kRaster: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      // Android describes -8 as "most important display threads, for
      // compositing the screen and retrieving input events". Conservatively
      // set the raster thread to slightly lower priority than it.
      if (::setpriority(PRIO_PROCESS, 0, -5) != 0) {
        // Defensive fallback. Depending on the OEM, it may not be possible
        // to set priority to -5.
        if (::setpriority(PRIO_PROCESS, 0, -2) != 0) {
          FML_LOG(ERROR) << "Failed to set raster task runner priority";
        }
      }
      break;
    }
    default:
      fml::RequestAffinity(fml::CpuAffinity::kNotPerformance);
      if (::setpriority(PRIO_PROCESS, 0, 0) != 0) {
        FML_LOG(ERROR) << "Failed to set priority";
      }
  }
}
static PlatformData GetDefaultPlatformData() {
  PlatformData platform_data;
  platform_data.lifecycle_state = "AppLifecycleState.detached";
  return platform_data;
}

namespace {

// The ID of the implicit view in single-view mode.
constexpr int64_t kImplicitViewId = 0;

// The holder owns its engine through an embedder API handle. Where embedder.h
// has no equivalent yet, the holder reaches past the handle with a cast or
// GetShell(). Keep each of those visible at its use so that
// ci/bin/android_embedder_ratchet.dart counts it; the counts must reach zero
// before the holder switches to FlutterEngineInitialize.

Shell& GetShell(FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  return reinterpret_cast<EmbedderEngine*>(engine)->GetShell();
}

FlutterEngineProcTable LoadEmbedderApi() {
  FlutterEngineProcTable embedder_api = {};
  embedder_api.struct_size = sizeof(FlutterEngineProcTable);
  FlutterEngineResult result = FlutterEngineGetProcAddresses(&embedder_api);
  FML_CHECK(result == kSuccess)
      << "FlutterEngineGetProcAddresses failed: " << result;
  return embedder_api;
}

// The embedder API callbacks of the PlatformView overrides that
// PlatformViewAndroid no longer has.
PlatformViewAndroid::PlatformDispatchTable MakePlatformDispatchTable(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<VsyncWaiterAndroid>& vsync_waiter) {
  return {
      .update_semantics_callback =
          [jni_facade](
              int64_t view_id, const flutter::SemanticsNodeUpdates& update,
              const flutter::CustomAccessibilityActionUpdates& actions) {
            PlatformViewAndroidDelegate(jni_facade)
                .UpdateSemantics(update, actions);
          },
      .vsync_callback =
          [vsync_waiter](intptr_t baton) { vsync_waiter->AwaitVSync(baton); },
      .compute_platform_resolved_locale_callback =
          [jni_facade](const std::vector<std::string>& supported_locale_data) {
            return jni_facade->FlutterViewComputePlatformResolvedLocale(
                supported_locale_data);
          },
      .on_pre_engine_restart_callback =
          [jni_facade]() { jni_facade->FlutterViewOnPreEngineRestart(); },
  };
}

// Gives the vsync source the engine handle once the holder owns the engine,
// or retires it when there is no engine. There is no source when the Shell
// failed before it created the platform view.
void AttachVsyncWaiter(VsyncWaiterAndroid* vsync_waiter,
                       FLUTTER_API_SYMBOL(FlutterEngine) engine,
                       const FlutterEngineProcTable* embedder_api) {
  if (vsync_waiter == nullptr) {
    return;
  }
  if (engine != nullptr) {
    vsync_waiter->Attach(engine, embedder_api);
  } else {
    vsync_waiter->Detach();
  }
}

}  // namespace

AndroidShellHolder::AndroidShellHolder(
    const flutter::Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      embedder_api_(LoadEmbedderApi()),
      android_rendering_api_(android_rendering_api) {
  static size_t thread_host_count = 1;
  auto thread_label = std::to_string(thread_host_count++);

  auto mask = ThreadHost::Type::kRaster | ThreadHost::Type::kIo;
  if (settings.merged_platform_ui_thread !=
      Settings::MergedPlatformUIThread::kEnabled) {
    mask |= ThreadHost::Type::kUi;
  }

  flutter::ThreadHost::ThreadHostConfig host_config(
      thread_label, mask, AndroidPlatformThreadConfigSetter);
  host_config.ui_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kUi, thread_label),
      fml::Thread::ThreadPriority::kDisplay);
  host_config.raster_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kRaster, thread_label),
      fml::Thread::ThreadPriority::kRaster);
  host_config.io_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kIo, thread_label),
      fml::Thread::ThreadPriority::kNormal);

  thread_host_ = std::make_shared<ThreadHost>(host_config);

  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;
  std::shared_ptr<VsyncWaiterAndroid> vsync_waiter;
  AndroidRenderingAPI rendering_api = android_rendering_api_;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&jni_facade, &weak_platform_view, &vsync_waiter,
       rendering_api](Shell& shell) {
        vsync_waiter =
            std::make_shared<VsyncWaiterAndroid>(shell.GetTaskRunners());
        std::unique_ptr<PlatformViewAndroid> platform_view_android;
        platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            jni_facade,              // JNI interop
            rendering_api,           // rendering API
            MakePlatformDispatchTable(jni_facade,
                                      vsync_waiter)  // embedder callbacks
        );
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> raster_runner;
  fml::RefPtr<fml::TaskRunner> ui_runner;
  fml::RefPtr<fml::TaskRunner> io_runner;
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  raster_runner = thread_host_->raster_thread->GetTaskRunner();
  if (settings.merged_platform_ui_thread ==
      Settings::MergedPlatformUIThread::kEnabled) {
    ui_runner = platform_runner;
  } else {
    ui_runner = thread_host_->ui_thread->GetTaskRunner();
  }
  io_runner = thread_host_->io_thread->GetTaskRunner();

  flutter::TaskRunners task_runners(thread_label,     // label
                                    platform_runner,  // platform
                                    raster_runner,    // raster
                                    ui_runner,        // ui
                                    io_runner         // io
  );

  // The same Shell::Create that FlutterEngineInitialize ends in, minus what
  // Android does itself: the holder owns the threads behind |task_runners|,
  // and Launch() runs the root isolate once the APK assets are known.
  auto engine = std::make_unique<EmbedderEngine>(
      /*thread_host=*/nullptr, task_runners, settings_,
      /*run_configuration=*/std::nullopt, on_create_platform_view,
      on_create_rasterizer, /*external_texture_resolver=*/nullptr);
  if (engine->LaunchShell(GetDefaultPlatformData())) {
    engine_.reset(
        reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(engine.release()));
  }

  if (engine_) {
    GetShell(engine_.get())
        .GetDartVM()
        ->GetConcurrentMessageLoop()
        ->PostTaskToAllWorkers([]() {
          if (::setpriority(PRIO_PROCESS, gettid(), 1) != 0) {
            FML_LOG(ERROR) << "Failed to set Workers task runner priority";
          }
        });

    GetShell(engine_.get())
        .RegisterImageDecoder(
            [runner = task_runners.GetIOTaskRunner()](sk_sp<SkData> buffer) {
              return AndroidImageGenerator::MakeFromData(std::move(buffer),
                                                         runner);
            },
            -1);
    FML_DLOG(INFO) << "Registered Android SDK image decoder (API level 28+)";
  }

  platform_view_ = weak_platform_view;
  FML_DCHECK(platform_view_);
  vsync_waiter_ = std::move(vsync_waiter);
  AttachVsyncWaiter(vsync_waiter_.get(), engine_.get(), &embedder_api_);
  is_valid_ = engine_ != nullptr;
}

AndroidShellHolder::AndroidShellHolder(
    const Settings& settings,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<ThreadHost>& thread_host,
    UniqueEngine engine,
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const fml::WeakPtr<PlatformViewAndroid>& platform_view,
    std::shared_ptr<VsyncWaiterAndroid> vsync_waiter,
    AndroidRenderingAPI rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      platform_view_(platform_view),
      thread_host_(thread_host),
      engine_(std::move(engine)),
      embedder_api_(LoadEmbedderApi()),
      vsync_waiter_(std::move(vsync_waiter)),
      apk_asset_provider_(std::move(apk_asset_provider)),
      android_rendering_api_(rendering_api) {
  FML_DCHECK(jni_facade);
  FML_DCHECK(engine_);
  FML_DCHECK(GetShell(engine_.get()).IsSetup());
  FML_DCHECK(platform_view_);
  FML_DCHECK(thread_host_);
  // The spawned engine may already wait for a vsync; see VsyncWaiterAndroid.
  AttachVsyncWaiter(vsync_waiter_.get(), engine_.get(), &embedder_api_);
  is_valid_ = engine_ != nullptr;
}

AndroidShellHolder::~AndroidShellHolder() {
  if (vsync_waiter_) {
    vsync_waiter_->Detach();
  }
  engine_.reset();
  thread_host_.reset();
}

void AndroidShellHolder::EngineDeleter::operator()(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  // Deletes the engine the way the Shell was deleted before it moved behind
  // a handle. FlutterEngineShutdown would also call NotifyDestroyed() on the
  // platform view first.
  delete reinterpret_cast<EmbedderEngine*>(engine);
}

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

std::unique_ptr<AndroidShellHolder> AndroidShellHolder::Spawn(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  FML_DCHECK(engine_ && GetShell(engine_.get()).IsSetup())
      << "A new Shell can only be spawned "
         "if the current Shell is properly constructed";

  // Pull out the new PlatformViewAndroid from the new Shell to feed to it to
  // the new AndroidShellHolder.
  //
  // It's a weak pointer because it's owned by the Shell (which we're also)
  // making below. And the AndroidShellHolder then owns the Shell.
  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;

  // Take out the old AndroidContext to reuse inside the PlatformViewAndroid
  // of the new Shell.
  PlatformViewAndroid* android_platform_view = platform_view_.get();
  // There's some indirection with platform_view_ being a weak pointer but
  // we just checked that the engine_ exists above and a valid shell is the
  // owner of the platform view so this weak pointer always exists.
  FML_DCHECK(android_platform_view);
  std::shared_ptr<flutter::AndroidContext> android_context =
      android_platform_view->GetAndroidContext();
  FML_DCHECK(android_context);

  // This is a synchronous call, so the captures don't have race checks.
  std::shared_ptr<VsyncWaiterAndroid> vsync_waiter;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&jni_facade, android_context, &weak_platform_view,
       &vsync_waiter](Shell& shell) {
        vsync_waiter =
            std::make_shared<VsyncWaiterAndroid>(shell.GetTaskRunners());
        std::unique_ptr<PlatformViewAndroid> platform_view_android;
        platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            jni_facade,              // JNI interop
            android_context,         // Android context
            MakePlatformDispatchTable(jni_facade,
                                      vsync_waiter)  // embedder callbacks
        );
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    // If the RunConfiguration was null, the kernel blob wasn't readable.
    // Fail the whole thing.
    return nullptr;
  }
  config->SetEngineId(engine_id);

  // embedder.h has no spawn API yet.
  std::unique_ptr<EmbedderEngine> spawned =
      reinterpret_cast<EmbedderEngine*>(engine_.get())
          ->Spawn(std::move(config.value()), initial_route,
                  on_create_platform_view, on_create_rasterizer);
  UniqueEngine engine(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(spawned.release()));

  return std::unique_ptr<AndroidShellHolder>(new AndroidShellHolder(
      GetSettings(), jni_facade, thread_host_, std::move(engine),
      apk_asset_provider_->Clone(), weak_platform_view, std::move(vsync_waiter),
      android_context->RenderingApi()));
}

void AndroidShellHolder::Launch(
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  if (!IsValid()) {
    return;
  }

  apk_asset_provider_ = std::move(apk_asset_provider);
  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    return;
  }
  config->SetEngineId(engine_id);
  UpdateDisplayMetrics();
  GetShell(engine_.get()).RunEngine(std::move(config.value()));
}

Rasterizer::Screenshot AndroidShellHolder::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!IsValid()) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  return GetShell(engine_.get()).Screenshot(type, base64_encode);
}

fml::WeakPtr<PlatformViewAndroid> AndroidShellHolder::GetPlatformView() {
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(engine_);
  GetShell(engine_.get()).NotifyLowMemoryWarning();
}

const std::shared_ptr<PlatformMessageHandler>&
AndroidShellHolder::GetPlatformMessageHandler() const {
  return GetShell(engine_.get()).GetPlatformMessageHandler();
}

Shell* AndroidShellHolder::GetShellForTesting() const {
  return engine_ ? &GetShell(engine_.get()) : nullptr;
}

void AndroidShellHolder::SetSemanticsEnabled(bool enabled) {
  FlutterEngineResult result =
      embedder_api_.UpdateSemanticsEnabled(engine_.get(), enabled);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineUpdateSemanticsEnabled failed: " << result;
  }
}

void AndroidShellHolder::SetAccessibilityFeatures(int32_t flags) {
  FlutterEngineResult result = embedder_api_.UpdateAccessibilityFeatures(
      engine_.get(), static_cast<FlutterAccessibilityFeature>(flags));
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineUpdateAccessibilityFeatures failed: "
                   << result;
  }
}

void AndroidShellHolder::DispatchSemanticsAction(int32_t node_id,
                                                 int32_t action,
                                                 fml::MallocMapping args) {
  // TODO(team-android): Remove implicit view assumption.
  // https://github.com/flutter/flutter/issues/142845
  FlutterSendSemanticsActionInfo info = {
      .struct_size = sizeof(FlutterSendSemanticsActionInfo),
      .view_id = kImplicitViewId,
      .node_id = static_cast<uint64_t>(node_id),
      .action = static_cast<FlutterSemanticsAction>(action),
      .data = args.GetMapping(),
      .data_length = args.GetSize(),
  };
  FlutterEngineResult result =
      embedder_api_.SendSemanticsAction(engine_.get(), &info);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendSemanticsAction failed: " << result;
  }
}

void AndroidShellHolder::ScheduleFrame() {
  FlutterEngineResult result = embedder_api_.ScheduleFrame(engine_.get());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineScheduleFrame failed: " << result;
  }
}

FlutterEngineProcTable& AndroidShellHolder::GetEmbedderApiForTesting() {
  return embedder_api_;
}

std::optional<RunConfiguration> AndroidShellHolder::BuildRunConfiguration(
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args) const {
  std::unique_ptr<IsolateConfiguration> isolate_configuration;
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    isolate_configuration = IsolateConfiguration::CreateForAppSnapshot();
  } else {
    std::unique_ptr<fml::Mapping> kernel_blob =
        fml::FileMapping::CreateReadOnly(
            GetSettings().application_kernel_asset);
    if (!kernel_blob) {
      FML_DLOG(ERROR) << "Unable to load the kernel blob asset.";
      return std::nullopt;
    }
    isolate_configuration =
        IsolateConfiguration::CreateForKernel(std::move(kernel_blob));
  }

  RunConfiguration config(std::move(isolate_configuration));
  config.AddAssetResolver(apk_asset_provider_->Clone());

  {
    if (!entrypoint.empty() && !libraryUrl.empty()) {
      config.SetEntrypointAndLibrary(entrypoint, libraryUrl);
    } else if (!entrypoint.empty()) {
      config.SetEntrypoint(entrypoint);
    }
    if (!entrypoint_args.empty()) {
      config.SetEntrypointArgs(entrypoint_args);
    }
  }
  return config;
}

void AndroidShellHolder::UpdateDisplayMetrics() {
  std::vector<std::unique_ptr<Display>> displays;
  displays.push_back(std::make_unique<AndroidDisplay>(jni_facade_));
  GetShell(engine_.get()).OnDisplayUpdates(std::move(displays));
}

bool AndroidShellHolder::IsSurfaceControlEnabled() {
  return GetPlatformView()->IsSurfaceControlEnabled();
}

}  // namespace flutter
