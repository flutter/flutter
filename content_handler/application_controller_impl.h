// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
#define FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_

#include <memory>

#include <fdio/namespace.h>

#include <fuchsia/cpp/component.h>
#include <fuchsia/cpp/ui.h>
#include <fuchsia/cpp/views_v1.h>

#include "lib/fidl/cpp/binding.h"
#include "lib/fidl/cpp/binding_set.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "lib/svc/cpp/service_provider_bridge.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter_runner {
class App;
class RuntimeHolder;

class ApplicationControllerImpl : public component::ApplicationController,
                                  public views_v1::ViewProvider {
 public:
  ApplicationControllerImpl(
      App* app,
      component::ApplicationPackage application,
      component::ApplicationStartupInfo startup_info,
      fidl::InterfaceRequest<component::ApplicationController> controller);

  ~ApplicationControllerImpl() override;

  // |component::ApplicationController| implementation

  void Kill() override;
  void Detach() override;
  void Wait(WaitCallback callback) override;

  // |views_v1::ViewProvider| implementation

  void CreateView(
      fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner_request,
      fidl::InterfaceRequest<component::ServiceProvider> services) override;

  Dart_Port GetUIIsolateMainPort();
  std::string GetUIIsolateName();

 private:
  void StartRuntimeIfReady();
  void SendReturnCode(int32_t return_code);

  fdio_ns_t* SetupNamespace(component::FlatNamespace flat);

  App* app_;
  fidl::Binding<component::ApplicationController> binding_;

  component::ServiceProviderBridge service_provider_bridge_;

  fidl::BindingSet<views_v1::ViewProvider> view_provider_bindings_;

  std::string url_;
  std::unique_ptr<RuntimeHolder> runtime_holder_;

  std::vector<WaitCallback> wait_callbacks_;

  FXL_DISALLOW_COPY_AND_ASSIGN(ApplicationControllerImpl);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
