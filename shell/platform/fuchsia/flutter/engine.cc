// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "engine.h"

#include <lib/async/cpp/task.h>
#include <zircon/status.h>

#include "../runtime/dart/utils/files.h"
#include "flow/embedded_views.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "flutter_runner_product_configuration.h"
#include "fuchsia_external_view_embedder.h"
#include "fuchsia_intl.h"
#include "include/core/SkPicture.h"
#include "include/core/SkSerialProcs.h"
#include "platform_view.h"
#include "surface.h"
#include "task_runner_adapter.h"
#include "third_party/skia/include/ports/SkFontMgr_fuchsia.h"
#include "thread.h"

#if defined(LEGACY_FUCHSIA_EMBEDDER)
#include "compositor_context.h"  // nogncheck
#endif

namespace flutter_runner {
namespace {

void UpdateNativeThreadLabelNames(const std::string& label,
                                  const flutter::TaskRunners& runners) {
  auto set_thread_name = [](fml::RefPtr<fml::TaskRunner> runner,
                            std::string prefix, std::string suffix) {
    if (!runner) {
      return;
    }
    fml::TaskRunner::RunNowOrPostTask(runner, [name = prefix + suffix]() {
      zx::thread::self()->set_property(ZX_PROP_NAME, name.c_str(), name.size());
    });
  };
  set_thread_name(runners.GetPlatformTaskRunner(), label, ".platform");
  set_thread_name(runners.GetUITaskRunner(), label, ".ui");
  set_thread_name(runners.GetRasterTaskRunner(), label, ".raster");
  set_thread_name(runners.GetIOTaskRunner(), label, ".io");
}

fml::RefPtr<flutter::PlatformMessage> MakeLocalizationPlatformMessage(
    const fuchsia::intl::Profile& intl_profile) {
  return fml::MakeRefCounted<flutter::PlatformMessage>(
      "flutter/localization", MakeLocalizationPlatformMessageData(intl_profile),
      nullptr);
}

}  // namespace

Engine::Engine(Delegate& delegate,
               std::string thread_label,
               std::shared_ptr<sys::ServiceDirectory> svc,
               std::shared_ptr<sys::ServiceDirectory> runner_services,
               flutter::Settings settings,
               fml::RefPtr<const flutter::DartSnapshot> isolate_snapshot,
               fuchsia::ui::views::ViewToken view_token,
               scenic::ViewRefPair view_ref_pair,
               UniqueFDIONS fdio_ns,
               fidl::InterfaceRequest<fuchsia::io::Directory> directory_request,
               FlutterRunnerProductConfiguration product_config)
    : delegate_(delegate),
      thread_label_(std::move(thread_label)),
#if defined(LEGACY_FUCHSIA_EMBEDDER)
      use_legacy_renderer_(product_config.use_legacy_renderer()),
#endif
      intercept_all_input_(product_config.get_intercept_all_input()),
      weak_factory_(this) {
  if (zx::event::create(0, &vsync_event_) != ZX_OK) {
    FML_DLOG(ERROR) << "Could not create the vsync event.";
    return;
  }

  // Get the task runners from the managed threads. The current thread will be
  // used as the "platform" thread.
  const flutter::TaskRunners task_runners(
      thread_label_,  // Dart thread labels
      CreateFMLTaskRunner(async_get_default_dispatcher()),  // platform
      CreateFMLTaskRunner(threads_[0].dispatcher()),        // raster
      CreateFMLTaskRunner(threads_[1].dispatcher()),        // ui
      CreateFMLTaskRunner(threads_[2].dispatcher())         // io
  );
  UpdateNativeThreadLabelNames(thread_label_, task_runners);

  // Connect to Scenic.
  auto scenic = svc->Connect<fuchsia::ui::scenic::Scenic>();
  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session;
  fidl::InterfaceHandle<fuchsia::ui::scenic::SessionListener> session_listener;
  auto session_listener_request = session_listener.NewRequest();
  fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser;
  scenic->CreateSession2(session.NewRequest(), session_listener.Bind(),
                         focuser.NewRequest());

  // Make clones of the `ViewRef` before sending it down to Scenic.
  fuchsia::ui::views::ViewRef platform_view_ref, isolate_view_ref;
  view_ref_pair.view_ref.Clone(&platform_view_ref);
  view_ref_pair.view_ref.Clone(&isolate_view_ref);

  // Session is terminated on the raster thread, but we must terminate ourselves
  // on the platform thread.
  //
  // This handles the fidl error callback when the Session connection is
  // broken. The SessionListener interface also has an OnError method, which is
  // invoked on the platform thread (in PlatformView).
  fml::closure session_error_callback = [dispatcher =
                                             async_get_default_dispatcher(),
                                         weak = weak_factory_.GetWeakPtr()]() {
    async::PostTask(dispatcher, [weak]() {
      if (weak) {
        weak->Terminate();
      }
    });
  };

  // Set up the session connection and other Scenic helpers on the raster
  // thread. We also need to wait for the external view embedder to be setup
  // before creating the shell.
  fml::AutoResetWaitableEvent view_embedder_latch;
  task_runners.GetRasterTaskRunner()->PostTask(fml::MakeCopyable(
      [this, session = std::move(session),
       session_error_callback = std::move(session_error_callback),
       view_token = std::move(view_token),
       view_ref_pair = std::move(view_ref_pair),
       max_frames_in_flight = product_config.get_max_frames_in_flight(),
       vsync_handle = vsync_event_.get(), &view_embedder_latch]() mutable {
        session_connection_.emplace(
            thread_label_, std::move(session),
            std::move(session_error_callback), [](auto) {}, vsync_handle,
            max_frames_in_flight);
        surface_producer_.emplace(session_connection_->get());
#if defined(LEGACY_FUCHSIA_EMBEDDER)
        if (use_legacy_renderer_) {
          legacy_external_view_embedder_ =
              std::make_shared<flutter::SceneUpdateContext>(
                  thread_label_, std::move(view_token),
                  std::move(view_ref_pair), session_connection_.value(),
                  intercept_all_input_);
        } else
#endif
        {
          external_view_embedder_ =
              std::make_shared<FuchsiaExternalViewEmbedder>(
                  thread_label_, std::move(view_token),
                  std::move(view_ref_pair), session_connection_.value(),
                  surface_producer_.value(), intercept_all_input_);
        }
        view_embedder_latch.Signal();
      }));
  view_embedder_latch.Wait();

  // Grab the parent environment services. The platform view may want to
  // access some of these services.
  fuchsia::sys::EnvironmentPtr environment;
  svc->Connect(environment.NewRequest());
  fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
      parent_environment_service_provider;
  environment->GetServices(parent_environment_service_provider.NewRequest());
  environment.Unbind();

  OnEnableWireframe on_enable_wireframe_callback = std::bind(
      &Engine::DebugWireframeSettingsChanged, this, std::placeholders::_1);

  OnCreateView on_create_view_callback =
      std::bind(&Engine::CreateView, this, std::placeholders::_1,
                std::placeholders::_2, std::placeholders::_3);

  OnUpdateView on_update_view_callback =
      std::bind(&Engine::UpdateView, this, std::placeholders::_1,
                std::placeholders::_2, std::placeholders::_3);

  OnDestroyView on_destroy_view_callback =
      std::bind(&Engine::DestroyView, this, std::placeholders::_1);

  OnCreateSurface on_create_surface_callback =
      std::bind(&Engine::CreateSurface, this);

  // SessionListener has a OnScenicError method; invoke this callback on the
  // platform thread when that happens. The Session itself should also be
  // disconnected when this happens, and it will also attempt to terminate.
  fit::closure on_session_listener_error_callback =
      [dispatcher = async_get_default_dispatcher(),
       weak = weak_factory_.GetWeakPtr()]() {
        async::PostTask(dispatcher, [weak]() {
          if (weak) {
            weak->Terminate();
          }
        });
      };

  // Setup the callback that will instantiate the platform view.
  flutter::Shell::CreateCallback<flutter::PlatformView>
      on_create_platform_view = fml::MakeCopyable(
          [debug_label = thread_label_, view_ref = std::move(platform_view_ref),
           runner_services,
           parent_environment_service_provider =
               std::move(parent_environment_service_provider),
           session_listener_request = std::move(session_listener_request),
           focuser = std::move(focuser),
           on_session_listener_error_callback =
               std::move(on_session_listener_error_callback),
           on_enable_wireframe_callback =
               std::move(on_enable_wireframe_callback),
           on_create_view_callback = std::move(on_create_view_callback),
           on_update_view_callback = std::move(on_update_view_callback),
           on_destroy_view_callback = std::move(on_destroy_view_callback),
           on_create_surface_callback = std::move(on_create_surface_callback),
           external_view_embedder = GetExternalViewEmbedder(),
           vsync_offset = product_config.get_vsync_offset(),
           vsync_handle = vsync_event_.get()](flutter::Shell& shell) mutable {
            return std::make_unique<flutter_runner::PlatformView>(
                shell,                   // delegate
                debug_label,             // debug label
                std::move(view_ref),     // view ref
                shell.GetTaskRunners(),  // task runners
                std::move(runner_services),
                std::move(parent_environment_service_provider),  // services
                std::move(session_listener_request),  // session listener
                std::move(focuser),
                std::move(on_session_listener_error_callback),
                std::move(on_enable_wireframe_callback),
                std::move(on_create_view_callback),
                std::move(on_update_view_callback),
                std::move(on_destroy_view_callback),
                std::move(on_create_surface_callback),
                external_view_embedder,   // external view embedder
                std::move(vsync_offset),  // vsync offset
                vsync_handle);
          });

  // Setup the callback that will instantiate the rasterizer.
  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer;
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  on_create_rasterizer = [this](flutter::Shell& shell) {
    if (use_legacy_renderer_) {
      FML_DCHECK(session_connection_);
      FML_DCHECK(surface_producer_);
      FML_DCHECK(legacy_external_view_embedder_);

      auto compositor_context =
          std::make_unique<flutter_runner::CompositorContext>(
              session_connection_.value(), surface_producer_.value(),
              legacy_external_view_embedder_);
      return std::make_unique<flutter::Rasterizer>(
          shell, std::move(compositor_context));
    } else {
      return std::make_unique<flutter::Rasterizer>(shell);
    }
  };
#else
  on_create_rasterizer = [this, &product_config](flutter::Shell& shell) {
    if (product_config.enable_shader_warmup()) {
      FML_DCHECK(surface_producer_);
      WarmupSkps(
          shell.GetDartVM()->GetConcurrentMessageLoop()->GetTaskRunner().get(),
          shell.GetTaskRunners().GetRasterTaskRunner().get(),
          surface_producer_.value());
    }
    return std::make_unique<flutter::Rasterizer>(shell);
  };
#endif

  settings.root_isolate_create_callback =
      std::bind(&Engine::OnMainIsolateStart, this);
  settings.root_isolate_shutdown_callback =
      std::bind([weak = weak_factory_.GetWeakPtr(),
                 runner = task_runners.GetPlatformTaskRunner()]() {
        runner->PostTask([weak = std::move(weak)] {
          if (weak) {
            weak->OnMainIsolateShutdown();
          }
        });
      });

  auto vm = flutter::DartVMRef::Create(settings);

  if (!isolate_snapshot) {
    isolate_snapshot = vm->GetVMData()->GetIsolateSnapshot();
  }

  {
    TRACE_EVENT0("flutter", "CreateShell");
    shell_ = flutter::Shell::Create(
        std::move(task_runners),             // host task runners
        flutter::PlatformData(),             // default window data
        std::move(settings),                 // shell launch settings
        std::move(isolate_snapshot),         // isolate snapshot
        std::move(on_create_platform_view),  // platform view create callback
        std::move(on_create_rasterizer),     // rasterizer create callback
        std::move(vm)                        // vm reference
    );
  }

  if (!shell_) {
    FML_LOG(ERROR) << "Could not launch the shell.";
    return;
  }

  // Shell has been created. Before we run the engine, setup the isolate
  // configurator.
  {
    fuchsia::sys::EnvironmentPtr environment;
    svc->Connect(environment.NewRequest());

    isolate_configurator_ = std::make_unique<IsolateConfigurator>(
        std::move(fdio_ns),                    //
        std::move(environment),                //
        directory_request.TakeChannel(),       //
        std::move(isolate_view_ref.reference)  //
    );
  }

  //  This platform does not get a separate surface platform view creation
  //  notification. Fire one eagerly.
  shell_->GetPlatformView()->NotifyCreated();

  // Connect to the intl property provider.  If the connection fails, the
  // initialization of the engine will simply proceed, printing a warning
  // message.  The engine will be fully functional, except that the user's
  // locale preferences would not be communicated to flutter engine.
  {
    intl_property_provider_.set_error_handler([](zx_status_t status) {
      FML_LOG(WARNING) << "Failed to connect to "
                       << fuchsia::intl::PropertyProvider::Name_ << ": "
                       << zx_status_get_string(status)
                       << " This is not a fatal error, but the user locale "
                       << " preferences will not be forwarded to flutter apps";
    });

    // Note that we're using the runner's services, not the component's.
    // Flutter locales should be updated regardless of whether the component has
    // direct access to the fuchsia.intl.PropertyProvider service.
    ZX_ASSERT(runner_services->Connect(intl_property_provider_.NewRequest()) ==
              ZX_OK);

    auto get_profile_callback = [flutter_runner_engine =
                                     weak_factory_.GetWeakPtr()](
                                    const fuchsia::intl::Profile& profile) {
      if (!flutter_runner_engine) {
        return;
      }
      if (!profile.has_locales()) {
        FML_LOG(WARNING) << "Got intl Profile without locales";
      }
      auto message = MakeLocalizationPlatformMessage(profile);
      FML_VLOG(-1) << "Sending LocalizationPlatformMessage";
      flutter_runner_engine->shell_->GetPlatformView()->DispatchPlatformMessage(
          message);
    };

    FML_VLOG(-1) << "Requesting intl Profile";

    // Make the initial request
    intl_property_provider_->GetProfile(get_profile_callback);

    // And register for changes
    intl_property_provider_.events().OnChange = [this, runner_services,
                                                 get_profile_callback]() {
      FML_VLOG(-1) << fuchsia::intl::PropertyProvider::Name_ << ": OnChange";
      runner_services->Connect(intl_property_provider_.NewRequest());
      intl_property_provider_->GetProfile(get_profile_callback);
    };
  }

  // Launch the engine in the appropriate configuration.
  auto run_configuration = flutter::RunConfiguration::InferFromSettings(
      shell_->GetSettings(), shell_->GetTaskRunners().GetIOTaskRunner());

  auto on_run_failure = [weak = weak_factory_.GetWeakPtr()]() {
    // The engine could have been killed by the caller right after the
    // constructor was called but before it could run on the UI thread.
    if (weak) {
      weak->Terminate();
    }
  };

  // Connect to the system font provider.
  fuchsia::fonts::ProviderSyncPtr sync_font_provider;
  svc->Connect(sync_font_provider.NewRequest());

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fml::MakeCopyable([engine = shell_->GetEngine(),                        //
                         run_configuration = std::move(run_configuration),    //
                         sync_font_provider = std::move(sync_font_provider),  //
                         on_run_failure                                       //
  ]() mutable {
        if (!engine) {
          return;
        }

        // Set default font manager.
        engine->GetFontCollection().GetFontCollection()->SetDefaultFontManager(
            SkFontMgr_New_Fuchsia(std::move(sync_font_provider)));

        if (engine->Run(std::move(run_configuration)) ==
            flutter::Engine::RunStatus::Failure) {
          on_run_failure();
        }
      }));
}

Engine::~Engine() {
  shell_.reset();
  for (auto& thread : threads_) {
    thread.Quit();
  }
  for (auto& thread : threads_) {
    thread.Join();
  }
}

std::optional<uint32_t> Engine::GetEngineReturnCode() const {
  if (!shell_) {
    return std::nullopt;
  }
  std::optional<uint32_t> code;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell_->GetTaskRunners().GetUITaskRunner(),
      [&latch, &code, engine = shell_->GetEngine()]() {
        if (engine) {
          code = engine->GetUIIsolateReturnCode();
        }
        latch.Signal();
      });
  latch.Wait();
  return code;
}

static void CreateCompilationTrace(Dart_Isolate isolate) {
  Dart_EnterIsolate(isolate);

  {
    Dart_EnterScope();
    uint8_t* trace = nullptr;
    intptr_t trace_length = 0;
    Dart_Handle result = Dart_SaveCompilationTrace(&trace, &trace_length);
    tonic::LogIfError(result);

    for (intptr_t start = 0; start < trace_length;) {
      intptr_t end = start;
      while ((end < trace_length) && trace[end] != '\n')
        end++;

      std::string line(reinterpret_cast<char*>(&trace[start]), end - start);
      FML_LOG(INFO) << "compilation-trace: " << line;

      start = end + 1;
    }

    Dart_ExitScope();
  }

  // Re-enter Dart scope to release the compilation trace's memory.

  {
    Dart_EnterScope();
    uint8_t* feedback = nullptr;
    intptr_t feedback_length = 0;
    Dart_Handle result = Dart_SaveTypeFeedback(&feedback, &feedback_length);
    tonic::LogIfError(result);
    const std::string kTypeFeedbackFile = "/data/dart_type_feedback.bin";
    if (dart_utils::WriteFile(kTypeFeedbackFile,
                              reinterpret_cast<const char*>(feedback),
                              feedback_length)) {
      FML_LOG(INFO) << "Dart type feedback written to " << kTypeFeedbackFile;
    } else {
      FML_LOG(ERROR) << "Could not write Dart type feedback to "
                     << kTypeFeedbackFile;
    }
    Dart_ExitScope();
  }

  Dart_ExitIsolate();
}

void Engine::OnMainIsolateStart() {
  if (!isolate_configurator_ ||
      !isolate_configurator_->ConfigureCurrentIsolate()) {
    FML_LOG(ERROR) << "Could not configure some native embedder bindings for a "
                      "new root isolate.";
  }
  FML_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' was started.";

  const intptr_t kCompilationTraceDelayInSeconds = 0;
  if (kCompilationTraceDelayInSeconds != 0) {
    Dart_Isolate isolate = Dart_CurrentIsolate();
    FML_CHECK(isolate);
    shell_->GetTaskRunners().GetUITaskRunner()->PostDelayedTask(
        [engine = shell_->GetEngine(), isolate]() {
          if (!engine) {
            return;
          }
          CreateCompilationTrace(isolate);
        },
        fml::TimeDelta::FromSeconds(kCompilationTraceDelayInSeconds));
  }
}

void Engine::OnMainIsolateShutdown() {
  FML_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' shutting down.";
  Terminate();
}

void Engine::Terminate() {
  delegate_.OnEngineTerminate(this);
  // Warning. Do not do anything after this point as the delegate may have
  // collected this object.
}

void Engine::DebugWireframeSettingsChanged(bool enabled) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask([this, enabled]() {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
    if (use_legacy_renderer_) {
      FML_CHECK(legacy_external_view_embedder_);
      legacy_external_view_embedder_->EnableWireframe(enabled);
    } else
#endif
    {
      FML_CHECK(external_view_embedder_);
      external_view_embedder_->EnableWireframe(enabled);
    }
  });
}

void Engine::CreateView(int64_t view_id, bool hit_testable, bool focusable) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [this, view_id, hit_testable, focusable]() {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
        if (use_legacy_renderer_) {
          FML_CHECK(legacy_external_view_embedder_);
          legacy_external_view_embedder_->CreateView(view_id, hit_testable,
                                                     focusable);
        } else
#endif
        {
          FML_CHECK(external_view_embedder_);
          external_view_embedder_->CreateView(view_id);
          external_view_embedder_->SetViewProperties(view_id, hit_testable,
                                                     focusable);
        }
      });
}

void Engine::UpdateView(int64_t view_id, bool hit_testable, bool focusable) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [this, view_id, hit_testable, focusable]() {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
        if (use_legacy_renderer_) {
          FML_CHECK(legacy_external_view_embedder_);
          legacy_external_view_embedder_->UpdateView(view_id, hit_testable,
                                                     focusable);
        } else
#endif
        {
          FML_CHECK(external_view_embedder_);
          external_view_embedder_->SetViewProperties(view_id, hit_testable,
                                                     focusable);
        }
      });
}

void Engine::DestroyView(int64_t view_id) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask([this, view_id]() {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
    if (use_legacy_renderer_) {
      FML_CHECK(legacy_external_view_embedder_);
      legacy_external_view_embedder_->DestroyView(view_id);
    } else
#endif
    {
      FML_CHECK(external_view_embedder_);
      external_view_embedder_->DestroyView(view_id);
    }
  });
}

std::unique_ptr<flutter::Surface> Engine::CreateSurface() {
  return std::make_unique<Surface>(thread_label_, GetExternalViewEmbedder(),
                                   surface_producer_->gr_context());
}

std::shared_ptr<flutter::ExternalViewEmbedder>
Engine::GetExternalViewEmbedder() {
  std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder =
      nullptr;

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  if (use_legacy_renderer_) {
    FML_CHECK(legacy_external_view_embedder_);
    external_view_embedder = legacy_external_view_embedder_;
  } else
#endif
  {
    FML_CHECK(external_view_embedder_);
    external_view_embedder = external_view_embedder_;
  }
  FML_CHECK(external_view_embedder);

  return external_view_embedder;
}

#if !defined(DART_PRODUCT)
void Engine::WriteProfileToTrace() const {
  Dart_Port main_port = shell_->GetEngine()->GetUIIsolateMainPort();
  char* error = NULL;
  bool success = Dart_WriteProfileToTimeline(main_port, &error);
  if (!success) {
    FML_LOG(ERROR) << "Failed to write Dart profile to trace: " << error;
    free(error);
  }
}
#endif  // !defined(DART_PRODUCT)

void Engine::WarmupSkps(fml::BasicTaskRunner* concurrent_task_runner,
                        fml::BasicTaskRunner* raster_task_runner,
                        VulkanSurfaceProducer& surface_producer) {
  SkISize size = SkISize::Make(1024, 600);
  auto skp_warmup_surface = surface_producer.ProduceOffscreenSurface(size);
  if (!skp_warmup_surface) {
    FML_LOG(ERROR) << "SkSurface::MakeRenderTarget returned null";
    return;
  }

  // tell concurrent task runner to deserialize all skps available from
  // the asset manager
  concurrent_task_runner->PostTask([&raster_task_runner, skp_warmup_surface,
                                    &surface_producer]() {
    TRACE_DURATION("flutter", "DeserializeSkps");
    std::vector<std::unique_ptr<fml::Mapping>> skp_mappings =
        flutter::PersistentCache::GetCacheForProcess()
            ->GetSkpsFromAssetManager();
    std::vector<sk_sp<SkPicture>> pictures;
    int i = 0;
    for (auto& mapping : skp_mappings) {
      std::unique_ptr<SkMemoryStream> stream =
          SkMemoryStream::MakeDirect(mapping->GetMapping(), mapping->GetSize());
      SkDeserialProcs procs = {0};
      procs.fImageProc = flutter::DeserializeImageWithoutData;
      procs.fTypefaceProc = flutter::DeserializeTypefaceWithoutData;
      sk_sp<SkPicture> picture =
          SkPicture::MakeFromStream(stream.get(), &procs);
      if (!picture) {
        FML_LOG(ERROR) << "Failed to deserialize picture " << i;
        continue;
      }

      // Tell raster task runner to warmup have the compositor
      // context warm up the newly deserialized picture
      raster_task_runner->PostTask(
          [skp_warmup_surface, picture, &surface_producer] {
            TRACE_DURATION("flutter", "WarmupSkp");
            skp_warmup_surface->getCanvas()->drawPicture(picture);
            surface_producer.gr_context()->flush();
          });
      i++;
    }
  });
}

}  // namespace flutter_runner
