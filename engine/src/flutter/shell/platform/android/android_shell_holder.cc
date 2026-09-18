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
#include "flutter/shell/platform/android/embedder_android_engine.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/shell_android_engine.h"
#include "flutter/shell/platform/embedder/embedder_asset_resolver.h"

namespace flutter {
static PlatformData GetDefaultPlatformData() {
  PlatformData platform_data;
  platform_data.lifecycle_state = "AppLifecycleState.detached";
  return platform_data;
}

AndroidShellHolder::AndroidShellHolder(
    const flutter::Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
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
  AndroidRenderingAPI rendering_api = android_rendering_api_;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [this, &jni_facade, &weak_platform_view, rendering_api](Shell& shell) {
        PlatformView::Delegate& delegate = shell;
        std::shared_ptr<AndroidContext> android_context =
            PlatformViewAndroid::CreateAndroidContext(
                shell.GetTaskRunners(), rendering_api,
                settings_.enable_opengl_gpu_tracing,
                PlatformViewAndroid::CreateContextSettings(settings_),
                delegate.OnPlatformViewGetShutdownSafeIOTaskRunner());
        auto embedder_surface = std::make_unique<EmbedderSurfaceAndroid>(
            android_context, shell, jni_facade, shell.GetTaskRunners(),
            PlatformViewAndroid::MeetsHCPPCriteria(settings_));
        embedder_surface_ = embedder_surface.get();
        platform_view_android_ = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            jni_facade,              // JNI interop
            android_context,         // Android context
            embedder_surface_        // embedder surface
        );
        weak_platform_view = platform_view_android_->GetWeakPtr();

        auto platform_view_embedder = std::make_unique<PlatformViewEmbedder>(
            shell, shell.GetTaskRunners(), std::move(embedder_surface),
            CreateDispatchTable(weak_platform_view), nullptr);
        platform_view_android_->SetPlatformView(
            platform_view_embedder->GetWeakPtr());
        return platform_view_embedder;
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

  auto shell =
      Shell::Create(GetDefaultPlatformData(),  // window data
                    task_runners,              // task runners
                    settings_,                 // settings
                    on_create_platform_view,   // platform view create callback
                    on_create_rasterizer       // rasterizer create callback
      );

  if (shell) {
    shell->GetDartVM()->GetConcurrentMessageLoop()->PostTaskToAllWorkers([]() {
      if (::setpriority(PRIO_PROCESS, gettid(), 1) != 0) {
        FML_LOG(ERROR) << "Failed to set Workers task runner priority";
      }
    });

    if (settings_.enable_embedder_api) {
      auto embedder_engine = std::make_unique<EmbedderAndroidEngine>(
          task_runners, std::move(shell), settings_, jni_facade_,
          android_rendering_api_);
      embedder_engine->SetPlatformMessageHandler(
          platform_view_android_->GetPlatformMessageHandler());
      engine_ = std::move(embedder_engine);
    } else {
      engine_ = std::make_unique<ShellAndroidEngine>(std::move(shell));
    }
    platform_view_android_->SetEngine(engine_.get());

    engine_->RegisterImageDecoder(
        [runner = task_runners.GetIOTaskRunner()](sk_sp<SkData> buffer) {
          return AndroidImageGenerator::MakeFromData(std::move(buffer), runner);
        },
        -1);
    FML_DLOG(INFO) << "Registered Android SDK image decoder (API level 28+)";
  }

  platform_view_ = weak_platform_view;
  FML_DCHECK(platform_view_);
  is_valid_ = engine_ && engine_->IsValid();
}

AndroidShellHolder::AndroidShellHolder(
    const Settings& settings,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<ThreadHost>& thread_host,
    std::unique_ptr<AndroidEngine> engine,
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const fml::WeakPtr<PlatformViewAndroid>& platform_view,
    std::unique_ptr<PlatformViewAndroid> platform_view_android,
    EmbedderSurfaceAndroid* embedder_surface,
    AndroidRenderingAPI rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      platform_view_(platform_view),
      platform_view_android_(std::move(platform_view_android)),
      embedder_surface_(embedder_surface),
      thread_host_(thread_host),
      engine_(std::move(engine)),
      apk_asset_provider_(std::move(apk_asset_provider)),
      android_rendering_api_(rendering_api) {
  FML_DCHECK(jni_facade);
  FML_DCHECK(engine_);
  FML_DCHECK(engine_->IsSetup());
  FML_DCHECK(platform_view_);
  FML_DCHECK(platform_view_android_);
  FML_DCHECK(thread_host_);
  is_valid_ = engine_ && engine_->IsValid();
}

AndroidShellHolder::~AndroidShellHolder() {
  if (platform_view_android_) {
    platform_view_android_->SetEngine(nullptr);
  }
  engine_.reset();
  embedder_surface_ = nullptr;
  platform_view_android_.reset();
  thread_host_.reset();
}

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

PlatformViewEmbedder::PlatformDispatchTable
AndroidShellHolder::CreateDispatchTable(
    const fml::WeakPtr<PlatformViewAndroid>& platform_view) const {
  PlatformViewEmbedder::PlatformDispatchTable dispatch_table;
  dispatch_table.update_semantics_callback =
      [platform_view](
          int64_t view_id, const flutter::SemanticsNodeUpdates& update,
          const flutter::CustomAccessibilityActionUpdates& actions) {
        if (platform_view) {
          platform_view->UpdateSemantics(view_id, update, actions);
        }
      };
  dispatch_table.platform_message_response_callback =
      [platform_view](std::unique_ptr<PlatformMessage> message) {
        if (platform_view) {
          platform_view->HandlePlatformMessage(std::move(message));
        }
      };
  dispatch_table.compute_platform_resolved_locale_callback =
      [platform_view](const std::vector<std::string>& supported_locale_data)
      -> std::unique_ptr<std::vector<std::string>> {
    if (platform_view) {
      return platform_view->ComputePlatformResolvedLocales(
          supported_locale_data);
    }
    return nullptr;
  };
  dispatch_table.on_pre_engine_restart_callback = [platform_view]() {
    if (platform_view) {
      platform_view->OnPreEngineRestart();
    }
  };
  dispatch_table.on_channel_update = [platform_view](const std::string& name,
                                                     bool listening) {
    if (platform_view) {
      platform_view->SendChannelUpdate(name, listening);
    }
  };
  dispatch_table.view_focus_change_request_callback =
      [platform_view](const ViewFocusChangeRequest& request) {
        if (platform_view) {
          platform_view->RequestViewFocusChange(request);
        }
      };
  dispatch_table.platform_message_response_completion_callback =
      [platform_view](int response_id, std::unique_ptr<fml::Mapping> mapping) {
        if (platform_view && platform_view->GetPlatformMessageHandler()) {
          platform_view->GetPlatformMessageHandler()
              ->InvokePlatformMessageResponseCallback(response_id,
                                                      std::move(mapping));
        }
      };
  dispatch_table.platform_message_empty_response_completion_callback =
      [platform_view](int response_id) {
        if (platform_view && platform_view->GetPlatformMessageHandler()) {
          platform_view->GetPlatformMessageHandler()
              ->InvokePlatformMessageEmptyResponseCallback(response_id);
        }
      };
  dispatch_table.request_dart_deferred_library_callback =
      [platform_view](intptr_t loading_unit_id) {
        if (platform_view) {
          platform_view->RequestDartDeferredLibrary(loading_unit_id);
        }
      };
  dispatch_table.get_scaled_font_size_callback =
      [platform_view](double unscaled_font_size, int configuration_id) {
        return platform_view ? platform_view->GetScaledFontSize(
                                   unscaled_font_size, configuration_id)
                             : -1.0;
      };
  dispatch_table.create_vsync_waiter_callback = [platform_view]() {
    return platform_view ? platform_view->CreateVSyncWaiter() : nullptr;
  };
  dispatch_table.set_application_locale_callback =
      [platform_view](std::string locale) {
        if (platform_view) {
          platform_view->SetApplicationLocale(std::move(locale));
        }
      };
  dispatch_table.set_semantics_tree_enabled_callback =
      [platform_view](bool enabled) {
        if (platform_view) {
          platform_view->SetSemanticsTreeEnabled(enabled);
        }
      };
  dispatch_table.custom_platform_message_handler =
      platform_view ? platform_view->GetPlatformMessageHandler() : nullptr;
  return dispatch_table;
}

std::unique_ptr<AndroidShellHolder> AndroidShellHolder::Spawn(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  FML_DCHECK(engine_ && engine_->IsSetup())
      << "A new Shell can only be spawned "
         "if the current Shell is properly constructed";

  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;
  std::unique_ptr<PlatformViewAndroid> spawned_platform_view_android;
  EmbedderSurfaceAndroid* spawned_embedder_surface = nullptr;

  // Take out the old AndroidContext to reuse inside the PlatformViewAndroid
  // of the new Shell.
  PlatformViewAndroid* android_platform_view = platform_view_.get();
  FML_DCHECK(android_platform_view);
  std::shared_ptr<flutter::AndroidContext> android_context =
      android_platform_view->GetAndroidContext();
  FML_DCHECK(android_context);

  // This is a synchronous call, so the captures don't have race checks.
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [this, &jni_facade, android_context, &weak_platform_view,
       &spawned_platform_view_android,
       &spawned_embedder_surface](Shell& shell) {
        auto embedder_surface = std::make_unique<EmbedderSurfaceAndroid>(
            android_context, shell, jni_facade, shell.GetTaskRunners(),
            PlatformViewAndroid::MeetsHCPPCriteria(settings_));
        spawned_embedder_surface = embedder_surface.get();
        spawned_platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                    // delegate
            shell.GetTaskRunners(),   // task runners
            jni_facade,               // JNI interop
            android_context,          // Android context
            spawned_embedder_surface  // embedder surface
        );
        weak_platform_view = spawned_platform_view_android->GetWeakPtr();

        auto platform_view_embedder = std::make_unique<PlatformViewEmbedder>(
            shell, shell.GetTaskRunners(), std::move(embedder_surface),
            CreateDispatchTable(weak_platform_view), nullptr);
        spawned_platform_view_android->SetPlatformView(
            platform_view_embedder->GetWeakPtr());
        return platform_view_embedder;
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

  std::unique_ptr<AndroidEngine> spawned_engine =
      engine_->Spawn(std::move(config.value()), initial_route,
                     on_create_platform_view, on_create_rasterizer);
  if (!spawned_engine) {
    return nullptr;
  }
  if (settings_.enable_embedder_api) {
    static_cast<EmbedderAndroidEngine*>(spawned_engine.get())
        ->SetPlatformMessageHandler(
            spawned_platform_view_android->GetPlatformMessageHandler());
  }
  spawned_platform_view_android->SetEngine(spawned_engine.get());

  return std::unique_ptr<AndroidShellHolder>(new AndroidShellHolder(
      GetSettings(), jni_facade, thread_host_, std::move(spawned_engine),
      apk_asset_provider_->Clone(), weak_platform_view,
      std::move(spawned_platform_view_android), spawned_embedder_surface,
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

  UpdateDisplayMetrics();

  apk_asset_provider_ = std::move(apk_asset_provider);
  if (!apk_asset_provider_) {
    if (settings_.enable_embedder_api) {
      auto* embedder_engine =
          static_cast<EmbedderAndroidEngine*>(engine_.get());
      if (embedder_engine != nullptr) {
        embedder_engine->Run(nullptr, entrypoint, libraryUrl, entrypoint_args,
                             engine_id);
      }
    }
    return;
  }

  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    return;
  }
  config->SetEngineId(engine_id);
  engine_->RunEngine(std::move(config.value()));
  if (settings_.enable_embedder_api) {
    engine_->UpdateAssetResolverByType(
        apk_asset_provider_->Clone(),
        AssetResolver::AssetResolverType::kApkAssetProvider);
  }
}

Rasterizer::Screenshot AndroidShellHolder::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!IsValid()) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  return engine_->Screenshot(type, base64_encode);
}

fml::WeakPtr<PlatformViewAndroid> AndroidShellHolder::GetPlatformView() {
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(engine_);
  engine_->NotifyLowMemoryWarning();
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
  if (settings_.enable_embedder_api) {
    auto cloned = apk_asset_provider_->Clone();
    config.AddAssetResolver(std::make_unique<EmbedderAssetResolver>(
        cloned->ToFlutterAssetResolver()));
  } else {
    config.AddAssetResolver(apk_asset_provider_->Clone());
  }

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
  engine_->OnDisplayUpdates(std::move(displays));
}

bool AndroidShellHolder::IsSurfaceControlEnabled() {
  return GetPlatformView()->IsSurfaceControlEnabled();
}

}  // namespace flutter
