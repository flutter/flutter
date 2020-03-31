// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "engine.h"

#include <lib/async/cpp/task.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <zircon/status.h>
#include <sstream>

#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "fuchsia_intl.h"
#include "platform_view.h"
#include "runtime/dart/utils/files.h"
#include "task_runner_adapter.h"
#include "third_party/skia/include/ports/SkFontMgr_fuchsia.h"
#include "thread.h"

namespace flutter_runner {

static void UpdateNativeThreadLabelNames(const std::string& label,
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

static fml::RefPtr<flutter::PlatformMessage> MakeLocalizationPlatformMessage(
    const fuchsia::intl::Profile& intl_profile) {
  return fml::MakeRefCounted<flutter::PlatformMessage>(
      "flutter/localization", MakeLocalizationPlatformMessageData(intl_profile),
      nullptr);
}

Engine::Engine(Delegate& delegate,
               std::string thread_label,
               std::shared_ptr<sys::ServiceDirectory> svc,
               std::shared_ptr<sys::ServiceDirectory> runner_services,
               flutter::Settings settings,
               fml::RefPtr<const flutter::DartSnapshot> isolate_snapshot,
               fuchsia::ui::views::ViewToken view_token,
               UniqueFDIONS fdio_ns,
               fidl::InterfaceRequest<fuchsia::io::Directory> directory_request)
    : delegate_(delegate),
      thread_label_(std::move(thread_label)),
      settings_(std::move(settings)),
      weak_factory_(this) {
  if (zx::event::create(0, &vsync_event_) != ZX_OK) {
    FML_DLOG(ERROR) << "Could not create the vsync event.";
    return;
  }

  // Launch the threads that will be used to run the shell. These threads will
  // be joined in the destructor.
  for (auto& thread : threads_) {
    thread.reset(new Thread());
  }

  // Set up the session connection.
  auto scenic = svc->Connect<fuchsia::ui::scenic::Scenic>();
  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session;
  fidl::InterfaceHandle<fuchsia::ui::scenic::SessionListener> session_listener;
  auto session_listener_request = session_listener.NewRequest();
  scenic->CreateSession(session.NewRequest(), session_listener.Bind());

  // Grab the parent environment services. The platform view may want to access
  // some of these services.
  fuchsia::sys::EnvironmentPtr environment;
  svc->Connect(environment.NewRequest());
  fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
      parent_environment_service_provider;
  environment->GetServices(parent_environment_service_provider.NewRequest());
  environment.Unbind();

  // We need to manually schedule a frame when the session metrics change.
  OnMetricsUpdate on_session_metrics_change_callback = std::bind(
      &Engine::OnSessionMetricsDidChange, this, std::placeholders::_1);

  OnSizeChangeHint on_session_size_change_hint_callback =
      std::bind(&Engine::OnSessionSizeChangeHint, this, std::placeholders::_1,
                std::placeholders::_2);

  OnEnableWireframe on_enable_wireframe_callback = std::bind(
      &Engine::OnDebugWireframeSettingsChanged, this, std::placeholders::_1);

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

  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  fuchsia::ui::views::ViewRef dart_view_ref;
  view_ref_pair.view_ref.Clone(&dart_view_ref);
  zx::eventpair dart_view_ref_event_pair(std::move(dart_view_ref.reference));

  // Setup the callback that will instantiate the platform view.
  flutter::Shell::CreateCallback<flutter::PlatformView>
      on_create_platform_view = fml::MakeCopyable(
          [debug_label = thread_label_, view_ref = std::move(view_ref),
           runner_services,
           parent_environment_service_provider =
               std::move(parent_environment_service_provider),
           session_listener_request = std::move(session_listener_request),
           on_session_listener_error_callback =
               std::move(on_session_listener_error_callback),
           on_session_metrics_change_callback =
               std::move(on_session_metrics_change_callback),
           on_session_size_change_hint_callback =
               std::move(on_session_size_change_hint_callback),
           on_enable_wireframe_callback =
               std::move(on_enable_wireframe_callback),
           vsync_handle = vsync_event_.get()](flutter::Shell& shell) mutable {
            return std::make_unique<flutter_runner::PlatformView>(
                shell,                   // delegate
                debug_label,             // debug label
                std::move(view_ref),     // view ref
                shell.GetTaskRunners(),  // task runners
                std::move(runner_services),
                std::move(parent_environment_service_provider),  // services
                std::move(session_listener_request),  // session listener
                std::move(on_session_listener_error_callback),
                std::move(on_session_metrics_change_callback),
                std::move(on_session_size_change_hint_callback),
                std::move(on_enable_wireframe_callback),
                vsync_handle  // vsync handle
            );
          });

  // Session can be terminated on the raster thread, but we must terminate
  // ourselves on the platform thread.
  //
  // This handles the fidl error callback when the Session connection is
  // broken. The SessionListener interface also has an OnError method, which is
  // invoked on the platform thread (in PlatformView).
  fml::closure on_session_error_callback =
      [dispatcher = async_get_default_dispatcher(),
       weak = weak_factory_.GetWeakPtr()]() {
        async::PostTask(dispatcher, [weak]() {
          if (weak) {
            weak->Terminate();
          }
        });
      };

  // Get the task runners from the managed threads. The current thread will be
  // used as the "platform" thread.
  const flutter::TaskRunners task_runners(
      thread_label_,  // Dart thread labels
      CreateFMLTaskRunner(async_get_default_dispatcher()),  // platform
      CreateFMLTaskRunner(threads_[0]->dispatcher()),       // raster
      CreateFMLTaskRunner(threads_[1]->dispatcher()),       // ui
      CreateFMLTaskRunner(threads_[2]->dispatcher())        // io
  );

  // Setup the callback that will instantiate the rasterizer.
  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer =
      fml::MakeCopyable([thread_label = thread_label_,              //
                         view_token = std::move(view_token),        //
                         view_ref_pair = std::move(view_ref_pair),  //
                         session = std::move(session),              //
                         on_session_error_callback,                 //
                         vsync_event = vsync_event_.get()           //
  ](flutter::Shell& shell) mutable {
        std::unique_ptr<flutter_runner::CompositorContext> compositor_context;
        {
          TRACE_DURATION("flutter", "CreateCompositorContext");
          compositor_context =
              std::make_unique<flutter_runner::CompositorContext>(
                  thread_label,           // debug label
                  std::move(view_token),  // scenic view we attach our tree to
                  std::move(view_ref_pair),  // scenic view ref/view ref control
                  std::move(session),        // scenic session
                  on_session_error_callback,  // session did encounter error
                  vsync_event                 // vsync event handle
              );
        }

        return std::make_unique<flutter::Rasterizer>(
            shell.GetTaskRunners(),        // task runners
            std::move(compositor_context)  // compositor context
        );
      });

  UpdateNativeThreadLabelNames(thread_label_, task_runners);

  settings_.verbose_logging = true;

  settings_.advisory_script_uri = thread_label_;

  settings_.advisory_script_entrypoint = thread_label_;

  settings_.root_isolate_create_callback =
      std::bind(&Engine::OnMainIsolateStart, this);

  settings_.root_isolate_shutdown_callback =
      std::bind([weak = weak_factory_.GetWeakPtr(),
                 runner = task_runners.GetPlatformTaskRunner()]() {
        runner->PostTask([weak = std::move(weak)] {
          if (weak) {
            weak->OnMainIsolateShutdown();
          }
        });
      });

  auto vm = flutter::DartVMRef::Create(settings_);

  if (!isolate_snapshot) {
    isolate_snapshot = vm->GetVMData()->GetIsolateSnapshot();
  }

  {
    TRACE_EVENT0("flutter", "CreateShell");
    shell_ = flutter::Shell::Create(
        task_runners,                 // host task runners
        flutter::WindowData(),        // default window data
        settings_,                    // shell launch settings
        std::move(isolate_snapshot),  // isolate snapshot
        on_create_platform_view,      // platform view create callback
        on_create_rasterizer,         // rasterizer create callback
        std::move(vm)                 // vm reference
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
        std::move(fdio_ns),                  //
        std::move(environment),              //
        directory_request.TakeChannel(),     //
        std::move(dart_view_ref_event_pair)  //
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
      settings_, task_runners.GetIOTaskRunner());

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
  for (const auto& thread : threads_) {
    thread->Quit();
  }
  for (const auto& thread : threads_) {
    thread->Join();
  }
}

std::pair<bool, uint32_t> Engine::GetEngineReturnCode() const {
  std::pair<bool, uint32_t> code(false, 0);
  if (!shell_) {
    return code;
  }
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

void Engine::OnSessionMetricsDidChange(
    const fuchsia::ui::gfx::Metrics& metrics) {
  if (!shell_) {
    return;
  }

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [rasterizer = shell_->GetRasterizer(), metrics]() {
        if (rasterizer) {
          auto compositor_context =
              reinterpret_cast<flutter_runner::CompositorContext*>(
                  rasterizer->compositor_context());

          compositor_context->OnSessionMetricsDidChange(metrics);
        }
      });
}

void Engine::OnDebugWireframeSettingsChanged(bool enabled) {
  if (!shell_) {
    return;
  }

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [rasterizer = shell_->GetRasterizer(), enabled]() {
        if (rasterizer) {
          auto compositor_context =
              reinterpret_cast<flutter_runner::CompositorContext*>(
                  rasterizer->compositor_context());

          compositor_context->OnWireframeEnabled(enabled);
        }
      });
}

void Engine::OnSessionSizeChangeHint(float width_change_factor,
                                     float height_change_factor) {
  if (!shell_) {
    return;
  }

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [rasterizer = shell_->GetRasterizer(), width_change_factor,
       height_change_factor]() {
        if (rasterizer) {
          auto compositor_context = reinterpret_cast<CompositorContext*>(
              rasterizer->compositor_context());

          compositor_context->OnSessionSizeChangeHint(width_change_factor,
                                                      height_change_factor);
        }
      });
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

}  // namespace flutter_runner
