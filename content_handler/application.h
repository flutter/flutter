// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <array>
#include <memory>
#include <set>

#include <fuchsia/cpp/component.h>
#include <fuchsia/cpp/views_v1.h>
#include <fuchsia/cpp/views_v1_token.h>

#include "engine.h"
#include "flutter/common/settings.h"
#include "lib/app/cpp/application_context.h"
#include "lib/fidl/cpp/binding_set.h"
#include "lib/fidl/cpp/interface_request.h"
#include "lib/fsl/threading/thread.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"
#include "lib/svc/cpp/service_provider_bridge.h"
#include "unique_fdio_ns.h"

namespace flutter {

// Represents an instance of a Flutter application that contains one of more
// Flutter engine instances.
class Application final : public Engine::Delegate,
                          public component::ApplicationController,
                          public views_v1::ViewProvider {
 public:
  using TerminationCallback = std::function<void(const Application*)>;

  // Creates a dedicated thread to run the application and constructions the
  // application on it. The application can be accessed only on this thread.
  // This is a synchronous operation.
  static std::pair<std::unique_ptr<fsl::Thread>, std::unique_ptr<Application>>
  Create(TerminationCallback termination_callback,
         component::ApplicationPackage package,
         component::ApplicationStartupInfo startup_info,
         fidl::InterfaceRequest<component::ApplicationController> controller);

  // Must be called on the same thread returned from the create call. The thread
  // may be collected after.
  ~Application();

  const std::string& GetDebugLabel() const;

 private:
  blink::Settings settings_;
  TerminationCallback termination_callback_;
  const std::string debug_label_;
  UniqueFDIONS fdio_ns_ = UniqueFDIONSCreate();
  fxl::UniqueFD application_directory_;
  fxl::UniqueFD application_assets_directory_;
  fidl::Binding<component::ApplicationController> application_controller_;
  fidl::InterfaceRequest<component::ServiceProvider> outgoing_services_request_;
  component::ServiceProviderBridge service_provider_bridge_;
  std::unique_ptr<component::ApplicationContext> application_context_;
  fidl::BindingSet<views_v1::ViewProvider> shells_bindings_;
  fxl::RefPtr<blink::DartSnapshot> isolate_snapshot_;
  std::set<std::unique_ptr<Engine>> shell_holders_;
  std::vector<WaitCallback> wait_callbacks_;
  std::pair<bool, uint32_t> last_return_code_;

  Application(
      TerminationCallback termination_callback,
      component::ApplicationPackage package,
      component::ApplicationStartupInfo startup_info,
      fidl::InterfaceRequest<component::ApplicationController> controller);

  // |component::ApplicationController|
  void Kill() override;

  // |component::ApplicationController|
  void Detach() override;

  // |component::ApplicationController|
  void Wait(WaitCallback callback) override;

  // |views_v1::ViewProvider|
  void CreateView(
      fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner,
      fidl::InterfaceRequest<component::ServiceProvider> services) override;

  // |flutter::Engine::Delegate|
  void OnEngineTerminate(const Engine* holder) override;

  void CreateShellForView(
      fidl::InterfaceRequest<views_v1::ViewProvider> view_provider_request);

  void AttemptVMLaunchWithCurrentSettings(const blink::Settings& settings);

  FXL_DISALLOW_COPY_AND_ASSIGN(Application);
};

}  // namespace flutter
