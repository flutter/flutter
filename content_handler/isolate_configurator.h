// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <fuchsia/cpp/component.h>
#include <fuchsia/cpp/ui.h>
#include <fuchsia/cpp/views_v1.h>

#include "lib/fxl/macros.h"
#include "lib/ui/flutter/sdk_ext/src/natives.h"
#include "unique_fdio_ns.h"

namespace flutter {

// Contains all the information necessary to configure a new root isolate. This
// is a single use item. The lifetime of this object must extend past that of
// the root isolate.
class IsolateConfigurator final : mozart::NativesDelegate {
 public:
  IsolateConfigurator(
      const UniqueFDIONS& fdio_ns,
      fidl::InterfaceHandle<views_v1::ViewContainer> view_container,
      component::ApplicationEnvironmentPtr application_environment,
      fidl::InterfaceRequest<component::ServiceProvider>
          outgoing_services_request);

  ~IsolateConfigurator();

  // Can be used only once and only on the UI thread with the newly created
  // isolate already current.
  bool ConfigureCurrentIsolate();

 private:
  bool used_ = false;
  const UniqueFDIONS& fdio_ns_;
  fidl::InterfaceHandle<views_v1::ViewContainer> view_container_;
  component::ApplicationEnvironmentPtr application_environment_;
  fidl::InterfaceRequest<component::ServiceProvider> outgoing_services_request_;

  // |mozart::NativesDelegate|
  void OfferServiceProvider(fidl::InterfaceHandle<component::ServiceProvider>,
                            fidl::VectorPtr<fidl::StringPtr> services);

  void BindFuchsia();

  void BindZircon();

  void BindDartIO();

  void BindScenic();

  FXL_DISALLOW_COPY_AND_ASSIGN(IsolateConfigurator);
};

}  // namespace flutter
