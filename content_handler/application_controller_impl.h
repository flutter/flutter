// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
#define FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_

#include <memory>

#include <fdio/namespace.h>

#include "lib/app/fidl/application_controller.fidl.h"
#include "lib/app/fidl/application_runner.fidl.h"
#include "lib/app/fidl/service_provider.fidl.h"
#include "lib/fidl/cpp/bindings/binding.h"
#include "lib/fidl/cpp/bindings/binding_set.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "lib/svc/cpp/service_provider_bridge.h"
#include "lib/ui/views/fidl/view_provider.fidl.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter_runner {
class App;
class RuntimeHolder;

class ApplicationControllerImpl : public component::ApplicationController,
                                  public mozart::ViewProvider {
 public:
  ApplicationControllerImpl(
      App* app,
      component::ApplicationPackagePtr application,
      component::ApplicationStartupInfoPtr startup_info,
      f1dl::InterfaceRequest<component::ApplicationController> controller);

  ~ApplicationControllerImpl() override;

  // |component::ApplicationController| implementation

  void Kill() override;
  void Detach() override;
  void Wait(const WaitCallback& callback) override;

  // |mozart::ViewProvider| implementation

  void CreateView(
      f1dl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
      f1dl::InterfaceRequest<component::ServiceProvider> services) override;

  Dart_Port GetUIIsolateMainPort();
  std::string GetUIIsolateName();

 private:
  void StartRuntimeIfReady();
  void SendReturnCode(int32_t return_code);

  fdio_ns_t* SetupNamespace(const component::FlatNamespacePtr& flat);

  App* app_;
  f1dl::Binding<component::ApplicationController> binding_;

  component::ServiceProviderBridge service_provider_bridge_;

  f1dl::BindingSet<mozart::ViewProvider> view_provider_bindings_;

  std::string url_;
  std::unique_ptr<RuntimeHolder> runtime_holder_;

  std::vector<WaitCallback> wait_callbacks_;

  FXL_DISALLOW_COPY_AND_ASSIGN(ApplicationControllerImpl);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
