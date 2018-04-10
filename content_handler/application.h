// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <array>
#include <memory>
#include <set>

#include "engine.h"
#include "flutter/common/settings.h"
#include "lib/app/cpp/application_context.h"
#include "lib/app/fidl/application_controller.fidl.h"
#include "lib/fidl/cpp/bindings/binding_set.h"
#include "lib/fsl/threading/thread.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"
#include "lib/svc/cpp/service_provider_bridge.h"
#include "lib/ui/views/fidl/view_provider.fidl.h"
#include "unique_fdio_ns.h"

namespace flutter {

// Represents an instance of a Flutter application that contains one of more
// Flutter engine instances.
class Application final : public Engine::Delegate,
                          public component::ApplicationController,
                          public mozart::ViewProvider {
 public:
  class Delegate {
   public:
    virtual void OnApplicationTerminate(const Application* application) = 0;
  };

  // Creates a dedicated thread to run the application and constructions the
  // application on it. The application can be accessed only on this thread.
  // This is a synchronous operation.
  static std::pair<std::unique_ptr<fsl::Thread>, std::unique_ptr<Application>>
  Create(Application::Delegate& delegate,
         component::ApplicationPackagePtr package,
         component::ApplicationStartupInfoPtr startup_info,
         f1dl::InterfaceRequest<component::ApplicationController> controller);

  // Must be called on the same thread returned from the create call. The thread
  // may be collected after.
  ~Application();

 private:
  blink::Settings settings_;
  Delegate& delegate_;
  const std::string debug_label_;
  UniqueFDIONS fdio_ns_ = UniqueFDIONSCreate();
  fxl::UniqueFD application_directory_;
  fxl::UniqueFD application_assets_directory_;
  f1dl::Binding<component::ApplicationController> application_controller_;
  f1dl::InterfaceRequest<component::ServiceProvider> outgoing_services_request_;
  component::ServiceProviderBridge service_provider_bridge_;
  std::unique_ptr<component::ApplicationContext> application_context_;
  f1dl::BindingSet<mozart::ViewProvider> shells_bindings_;
  std::set<std::unique_ptr<Engine>> shell_holders_;
  std::vector<WaitCallback> wait_callbacks_;
  std::pair<bool, uint32_t> last_return_code_;

  Application(
      Application::Delegate& delegate,
      component::ApplicationPackagePtr package,
      component::ApplicationStartupInfoPtr startup_info,
      f1dl::InterfaceRequest<component::ApplicationController> controller);

  // |component::ApplicationController|
  void Kill() override;

  // |component::ApplicationController|
  void Detach() override;

  // |component::ApplicationController|
  void Wait(const WaitCallback& callback) override;

  // |mozart::ViewProvider|
  void CreateView(
      f1dl::InterfaceRequest<mozart::ViewOwner> view_owner,
      f1dl::InterfaceRequest<component::ServiceProvider> services) override;

  // |flutter::Engine::Delegate|
  void OnEngineTerminate(const Engine* holder) override;

  void CreateShellForView(
      f1dl::InterfaceRequest<mozart::ViewProvider> view_provider_request);

  void AttemptVMLaunchWithCurrentSettings(
      const blink::Settings& settings) const;

  FXL_DISALLOW_COPY_AND_ASSIGN(Application);
};

}  // namespace flutter
