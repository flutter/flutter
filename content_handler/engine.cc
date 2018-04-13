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

#ifdef ERROR
#undef ERROR
#endif

namespace flutter {

Engine::Engine(Delegate& delegate,
               std::string thread_label,
               component::ApplicationContext& application_context,
               blink::Settings settings,
               f1dl::InterfaceRequest<mozart::ViewOwner> view_owner,
               const UniqueFDIONS& fdio_ns,
               f1dl::InterfaceRequest<component::ServiceProvider>
                   outgoing_services_request)
    : delegate_(delegate),
      thread_label_(std::move(thread_label)),
      settings_(std::move(settings)),
      weak_factory_(this) {
  // Launch the threads that will be used to run the shell. These threads will
  // be joined in the destructor.
  for (auto& thread : host_threads_) {
    thread.Run();
  }

  mozart::ViewManagerPtr view_manager;
  application_context.ConnectToEnvironmentService(view_manager.NewRequest());

  zx::eventpair import_token, export_token;
  if (zx::eventpair::create(0u, &import_token, &export_token) != ZX_OK) {
    FXL_DLOG(ERROR) << "Could not create event pair.";
    return;
  }

  // Setup the session connection.
  ui::ScenicPtr scenic;
  view_manager->GetScenic(scenic.NewRequest());

  // Grab the parent environent services. The platform view may want to access
  // some of these services.
  component::ServiceProviderPtr parent_environment_service_provider;
  application_context.environment()->GetServices(
      parent_environment_service_provider.NewRequest());

  // We need to manually schedule a frame when the session metrics change.
  OnMetricsUpdate on_session_metrics_change_callback = std::bind(
      &Engine::OnSessionMetricsDidChange, this, std::placeholders::_1);

  fxl::Closure on_session_error_callback = std::bind(&Engine::Terminate, this);

  // Grab the accessibilty context writer that can understand the semtics tree
  // on the platform view.
  maxwell::ContextWriterPtr accessibility_context_writer;
  application_context.ConnectToEnvironmentService(
      accessibility_context_writer.NewRequest());

  // Setup the callback that will instantiate the platform view.
  shell::Shell::CreateCallback<shell::PlatformView> on_create_platform_view =
      fxl::MakeCopyable([debug_label = thread_label_,  //
                         parent_environment_service_provider =
                             std::move(parent_environment_service_provider),  //
                         view_manager = std::ref(view_manager),               //
                         view_owner = std::move(view_owner),                  //
                         scenic = std::move(scenic),                          //
                         accessibility_context_writer =
                             std::move(accessibility_context_writer),  //
                         export_token = std::move(export_token),       //
                         import_token = std::move(import_token),       //
                         on_session_metrics_change_callback,           //
                         on_session_error_callback                     //
  ](shell::Shell& shell) mutable {
        return std::make_unique<flutter::PlatformView>(
            shell,                                           // delegate
            debug_label,                                     // debug label
            shell.GetTaskRunners(),                          // task runners
            std::move(parent_environment_service_provider),  // services
            view_manager,                                    // view manager
            std::move(view_owner),                           // view owner
            std::move(scenic),                               // scenic
            std::move(export_token),                         // export token
            std::move(import_token),                         // import token
            std::move(
                accessibility_context_writer),  // accessibility context writer
            std::move(on_session_metrics_change_callback),  // metrics change
            std::move(on_session_error_callback)            // session_error
        );
      });

  // Setup the callback that will instantiate the rasterizer.
  shell::Shell::CreateCallback<shell::Rasterizer> on_create_rasterizer =
      [](shell::Shell& shell) {
        return std::make_unique<shell::Rasterizer>(
            shell.GetTaskRunners()  // task runners
        );
      };

  // Get the task runners from the managed threads. The current thread will be
  // used as the "platform" thread.
  blink::TaskRunners task_runners(
      thread_label_,                                  // Dart thread labels
      fsl::MessageLoop::GetCurrent()->task_runner(),  // platform
      host_threads_[0].TaskRunner(),                  // gpu
      host_threads_[1].TaskRunner(),                  // ui
      host_threads_[2].TaskRunner()                   // io
  );

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

  shell_ = shell::Shell::Create(
      task_runners,             // host task runners
      settings_,                // shell launch settings
      on_create_platform_view,  // platform view create callback
      on_create_rasterizer      // rasterizer create callback
  );

  if (!shell_) {
    FXL_LOG(ERROR) << "Could not launch the shell with settings: "
                   << settings_.ToString();
    return;
  }

  // Shell has been created. Before we run the engine, setup the isolate
  // configurator.
  {
    PlatformView* platform_view =
        static_cast<PlatformView*>(shell_->GetPlatformView().get());
    auto& view = platform_view->GetMozartView();
    component::ApplicationEnvironmentPtr application_environment;
    application_context.ConnectToEnvironmentService(
        application_environment.NewRequest());

    isolate_configurator_ = std::make_unique<IsolateConfigurator>(
        fdio_ns,                              //
        view,                                 //
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

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fxl::MakeCopyable([engine = shell_->GetEngine(),                     //
                         run_configuration = std::move(run_configuration)  //
  ]() mutable {
        if (!engine || !engine->Run(std::move(run_configuration))) {
          FXL_LOG(ERROR) << "Could not (re)launch the engine in configuration";
        }
      }));

  UpdateNativeThreadLabelNames();
}

Engine::~Engine() {
  for (const auto& thread : host_threads_) {
    thread.TaskRunner()->PostTask(
        []() { fsl::MessageLoop::GetCurrent()->PostQuitTask(); });
  }
}

void Engine::UpdateNativeThreadLabelNames() const {
  auto set_thread_name = [](fxl::RefPtr<fxl::TaskRunner> runner,
                            std::string prefix, std::string suffix) {
    runner->PostTask([name = prefix + suffix]() {
      zx::thread::self().set_property(ZX_PROP_NAME, name.c_str(), name.size());
    });
  };
  auto runners = shell_->GetTaskRunners();
  set_thread_name(runners.GetPlatformTaskRunner(), thread_label_, ".platform");
  set_thread_name(runners.GetUITaskRunner(), thread_label_, ".ui");
  set_thread_name(runners.GetGPUTaskRunner(), thread_label_, ".gpu");
  set_thread_name(runners.GetIOTaskRunner(), thread_label_, ".io");
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
      !isolate_configurator_->ConfigureCurrentIsolate()) {
    FXL_LOG(ERROR) << "Could not configure some native embedder bindings for a "
                      "new root isolate.";
  }
}

void Engine::OnMainIsolateShutdown() {
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

}  // namespace flutter
