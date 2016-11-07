// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
#define FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_

#include <memory>

#include "apps/modular/services/application/application_controller.fidl.h"
#include "apps/modular/services/application/application_runner.fidl.h"
#include "apps/modular/services/application/service_provider.fidl.h"
#include "apps/mozart/services/views/view_provider.fidl.h"
#include "lib/fidl/cpp/bindings/binding.h"
#include "lib/fidl/cpp/bindings/binding_set.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {
class App;
class RuntimeHolder;

class ApplicationControllerImpl : public modular::ApplicationController,
                                  public modular::ServiceProvider,
                                  public mozart::ViewProvider {
 public:
  ApplicationControllerImpl(
      App* app,
      modular::ApplicationPackagePtr application,
      modular::ApplicationStartupInfoPtr startup_info,
      fidl::InterfaceRequest<modular::ApplicationController> controller);

  ~ApplicationControllerImpl() override;

  // |modular::ApplicationController| implementation

  void Kill(const KillCallback& callback) override;
  void Detach() override;

  // |modular::ServiceProvider| implementation

  void ConnectToService(const fidl::String& service_name,
                        mx::channel client_handle) override;

  // |mozart::ViewProvider| implementation

  void CreateView(
      fidl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
      fidl::InterfaceRequest<modular::ServiceProvider> services) override;

 private:
  void StartRuntimeIfReady();

  App* app_;
  fidl::Binding<modular::ApplicationController> binding_;

  fidl::BindingSet<modular::ServiceProvider> service_provider_bindings_;
  fidl::BindingSet<mozart::ViewProvider> view_provider_bindings_;

  std::string url_;
  std::unique_ptr<RuntimeHolder> runtime_holder_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ApplicationControllerImpl);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
