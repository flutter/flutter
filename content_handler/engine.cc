// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "engine.h"

#include <sstream>

#include "flutter/common/task_runners.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "lib/fsl/tasks/message_loop.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "platform_view.h"

namespace flutter {

static void UpdateNativeThreadLabelNames(const std::string& label,
                                         const blink::TaskRunners& runners) {
  auto set_thread_name = [](fxl::RefPtr<fxl::TaskRunner> runner,
                            std::string prefix, std::string suffix) {
    if (!runner) {
      return;
    }
    fml::TaskRunner::RunNowOrPostTask(runner, [name = prefix + suffix]() {
      zx::thread::self().set_property(ZX_PROP_NAME, name.c_str(), name.size());
    });
  };
  set_thread_name(runners.GetPlatformTaskRunner(), label, ".platform");
  set_thread_name(runners.GetUITaskRunner(), label, ".ui");
  set_thread_name(runners.GetGPUTaskRunner(), label, ".gpu");
  set_thread_name(runners.GetIOTaskRunner(), label, ".io");
}

Engine::Engine(Delegate& delegate,
               std::string thread_label,
               component::ApplicationContext& application_context,
               blink::Settings settings,
               fxl::RefPtr<blink::DartSnapshot> isolate_snapshot,
               fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner,
               UniqueFDIONS fdio_ns,
               fidl::InterfaceRequest<component::ServiceProvider>
                   outgoing_services_request)
    : delegate_(delegate),
      thread_label_(std::move(thread_label)),
      settings_(std::move(settings)),
      weak_factory_(this) {
  if (zx::event::create(0, &vsync_event_) != ZX_OK) {
    FXL_DLOG(ERROR) << "Could not create the vsync event.";
    return;
  }

  // Launch the threads that will be used to run the shell. These threads will
  // be joined in the destructor.
  for (auto& thread : host_threads_) {
    thread.Run();
  }

  views_v1::ViewManagerPtr view_manager;
  application_context.ConnectToEnvironmentService(view_manager.NewRequest());

  zx::eventpair import_token, export_token;
  if (zx::eventpair::create(0u, &import_token, &export_token) != ZX_OK) {
    FXL_DLOG(ERROR) << "Could not create event pair.";
    return;
  }

  // Setup the session connection.
  fidl::InterfaceHandle<ui::Scenic> scenic;
  view_manager->GetScenic(scenic.NewRequest());

  // Grab the parent environent services. The platform view may want to access
  // some of these services.
  fidl::InterfaceHandle<component::ServiceProvider>
      parent_environment_service_provider;
  application_context.environment()->GetServices(
      parent_environment_service_provider.NewRequest());

  // We need to manually schedule a frame when the session metrics change.
  OnMetricsUpdate on_session_metrics_change_callback = std::bind(
      &Engine::OnSessionMetricsDidChange, this, std::placeholders::_1);

  // Session errors may occur on the GPU thread, but we must terminate ourselves
  // on the platform thread.
  fxl::Closure on_session_error_callback =
      [runner = fsl::MessageLoop::GetCurrent()->task_runner(),
       weak = weak_factory_.GetWeakPtr()]() {
        runner->PostTask([weak]() {
          if (weak) {
            weak->Terminate();
          }
        });
      };

  // Grab the accessibilty context writer that can understand the semtics tree
  // on the platform view.
  fidl::InterfaceHandle<modular::ContextWriter> accessibility_context_writer;
  application_context.ConnectToEnvironmentService(
      accessibility_context_writer.NewRequest());

  // Create the compositor context from the scenic pointer to create the
  // rasterizer.
  std::unique_ptr<flow::CompositorContext> compositor_context =
      std::make_unique<flutter::CompositorContext>(
          std::move(scenic),                   // scenic
          thread_label_,                       // debug label
          std::move(import_token),             // import token
          on_session_metrics_change_callback,  // session metrics did change
          on_session_error_callback,           // session did encounter error
          vsync_event_.get()                   // vsync event handle
      );

  // Setup the callback that will instantiate the platform view.
  shell::Shell::CreateCallback<shell::PlatformView> on_create_platform_view =
      fxl::MakeCopyable([debug_label = thread_label_,  //
                         parent_environment_service_provider =
                             std::move(parent_environment_service_provider),  //
                         view_manager = view_manager.Unbind(),                //
                         view_owner = std::move(view_owner),                  //
                         accessibility_context_writer =
                             std::move(accessibility_context_writer),  //
                         export_token = std::move(export_token),       //
                         vsync_handle = vsync_event_.get()             //

  ](shell::Shell& shell) mutable {
        return std::make_unique<flutter::PlatformView>(
            shell,                                           // delegate
            debug_label,                                     // debug label
            shell.GetTaskRunners(),                          // task runners
            std::move(parent_environment_service_provider),  // services
            std::move(view_manager),                         // view manager
            std::move(view_owner),                           // view owner
            std::move(export_token),                         // export token
            std::move(
                accessibility_context_writer),  // accessibility context writer
            vsync_handle                        // vsync handle
        );
      });

  // Setup the callback that will instantiate the rasterizer.
  shell::Shell::CreateCallback<shell::Rasterizer> on_create_rasterizer =
      fxl::MakeCopyable([compositor_context = std::move(compositor_context)](
                            shell::Shell& shell) mutable {
        return std::make_unique<shell::Rasterizer>(
            shell.GetTaskRunners(),        // task runners
            std::move(compositor_context)  // compositor context
        );
      });

  // Get the task runners from the managed threads. The current thread will be
  // used as the "platform" thread.
  blink::TaskRunners task_runners(
      thread_label_,                                  // Dart thread labels
      fsl::MessageLoop::GetCurrent()->task_runner(),  // platform
      host_threads_[0].TaskRunner(),                  // gpu
      host_threads_[1].TaskRunner(),                  // ui
      host_threads_[2].TaskRunner()                   // io
  );

  UpdateNativeThreadLabelNames(thread_label_, task_runners);

  settings_.verbose_logging = true;

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

  if (!isolate_snapshot) {
    isolate_snapshot =
        blink::DartVM::ForProcess(settings_)->GetIsolateSnapshot();
  }

  shell_ = shell::Shell::Create(
      task_runners,                 // host task runners
      settings_,                    // shell launch settings
      std::move(isolate_snapshot),  // isolate snapshot
      on_create_platform_view,      // platform view create callback
      on_create_rasterizer          // rasterizer create callback
  );

  if (!shell_) {
    FXL_LOG(ERROR) << "Could not launch the shell with settings: "
                   << settings_.ToString();
    return;
  }

  // Shell has been created. Before we run the engine, setup the isolate
  // configurator.
  {
    auto view_container =
        static_cast<PlatformView*>(shell_->GetPlatformView().get())
            ->TakeViewContainer();

    component::ApplicationEnvironmentPtr application_environment;
    application_context.ConnectToEnvironmentService(
        application_environment.NewRequest());

    isolate_configurator_ = std::make_unique<IsolateConfigurator>(
        std::move(fdio_ns),                   //
        std::move(view_container),            //
        std::move(application_environment),   //
        std::move(outgoing_services_request)  //
    );
  }

  //  This platform does not get a separate surface platform view creation
  //  notification. Fire one eagerly.
  shell_->GetPlatformView()->NotifyCreated();

  // Launch the engine in the appropriate configuration.
  auto run_configuration =
      shell::RunConfiguration::InferFromSettings(settings_);

  auto on_run_failure = [weak = weak_factory_.GetWeakPtr(),  //
                         runner =
                             fsl::MessageLoop::GetCurrent()->task_runner()  //
  ]() {
    // The engine could have been killed by the caller right after the
    // constructor was called but before it could run on the UI thread.
    if (weak) {
      weak->Terminate();
    }
  };

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fxl::MakeCopyable([engine = shell_->GetEngine(),                      //
                         run_configuration = std::move(run_configuration),  //
                         on_run_failure                                     //
  ]() mutable {
        if (!engine) {
          return;
        }
        if (!engine->Run(std::move(run_configuration))) {
          on_run_failure();
        }
      }));
}

Engine::~Engine() {
  shell_.reset();
  for (const auto& thread : host_threads_) {
    thread.TaskRunner()->PostTask(
        []() { fsl::MessageLoop::GetCurrent()->PostQuitTask(); });
  }
}

std::pair<bool, uint32_t> Engine::GetEngineReturnCode() const {
  std::pair<bool, uint32_t> code(false, 0);
  if (!shell_) {
    return code;
  }
  fxl::AutoResetWaitableEvent latch;
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

void Engine::OnMainIsolateStart() {
  if (!isolate_configurator_ ||
      !isolate_configurator_->ConfigureCurrentIsolate(this)) {
    FXL_LOG(ERROR) << "Could not configure some native embedder bindings for a "
                      "new root isolate.";
  }
  FXL_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' was started.";
}

void Engine::OnMainIsolateShutdown() {
  FXL_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' shutting down.";
  Terminate();
}

void Engine::Terminate() {
  delegate_.OnEngineTerminate(this);
  // Warning. Do not do anything after this point as the delegate may have
  // collected this object.
}

void Engine::OnSessionMetricsDidChange(double device_pixel_ratio) {
  if (!shell_) {
    return;
  }

  shell_->GetTaskRunners().GetPlatformTaskRunner()->PostTask(
      [platform_view = shell_->GetPlatformView(), device_pixel_ratio]() {
        if (platform_view) {
          reinterpret_cast<flutter::PlatformView*>(platform_view.get())
              ->UpdateViewportMetrics(device_pixel_ratio);
        }
      });
}

// |mozart::NativesDelegate|
void Engine::OfferServiceProvider(
    fidl::InterfaceHandle<component::ServiceProvider> service_provider,
    fidl::VectorPtr<fidl::StringPtr> services) {
  if (!shell_) {
    return;
  }

  shell_->GetTaskRunners().GetPlatformTaskRunner()->PostTask(
      fxl::MakeCopyable([platform_view = shell_->GetPlatformView(),       //
                         service_provider = std::move(service_provider),  //
                         services = std::move(services)                   //
  ]() mutable {
        if (platform_view) {
          reinterpret_cast<flutter::PlatformView*>(platform_view.get())
              ->OfferServiceProvider(std::move(service_provider),
                                     std::move(services));
        }
      }));
}

}  // namespace flutter
