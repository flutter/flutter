// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <unordered_map>

#include "application.h"
#include "lib/app/cpp/application_context.h"
#include "lib/app/fidl/application_runner.fidl.h"
#include "lib/fidl/cpp/bindings/binding_set.h"
#include "lib/fsl/tasks/message_loop.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/macros.h"

namespace flutter {

// Publishes the |component::ApplicationRunner| service and runs applications on
// their own threads.
class ApplicationRunner final : public Application::Delegate,
                                public component::ApplicationRunner {
 public:
  ApplicationRunner(fxl::Closure on_termination_callback);

  ~ApplicationRunner();

 private:
  struct ActiveApplication {
    std::unique_ptr<fsl::Thread> thread;
    std::unique_ptr<Application> application;

    ActiveApplication(std::pair<std::unique_ptr<fsl::Thread>,
                                std::unique_ptr<Application>> pair)
        : thread(std::move(pair.first)), application(std::move(pair.second)) {}

    ActiveApplication() {
      if (thread && application) {
        thread->TaskRunner()->PostTask(
            fxl::MakeCopyable([application = std::move(application)]() mutable {
              application.reset();
              fsl::MessageLoop::GetCurrent()->PostQuitTask();
            }));
        thread.reset();  // join
      }
    }
  };

  fxl::Closure on_termination_callback_;
  std::unique_ptr<component::ApplicationContext> host_context_;
  f1dl::BindingSet<component::ApplicationRunner> active_applications_bindings_;
  std::unordered_map<const Application*, ActiveApplication>
      active_applications_;

  // |component::ApplicationRunner|
  void StartApplication(component::ApplicationPackagePtr application,
                        component::ApplicationStartupInfoPtr startup_info,
                        f1dl::InterfaceRequest<component::ApplicationController>
                            controller) override;

  void RegisterApplication(
      f1dl::InterfaceRequest<component::ApplicationRunner> request);

  void UnregisterApplication(const Application* application);

  // |Application::Delegate|
  void OnApplicationTerminate(const Application* application) override;

  void SetupICU();

  void SetupGlobalFonts();

  void FireTerminationCallbackIfNecessary();

  FXL_DISALLOW_COPY_AND_ASSIGN(ApplicationRunner);
};

}  // namespace flutter
