// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "lib/app/fidl/application_environment.fidl.h"
#include "lib/fxl/macros.h"
#include "lib/ui/flutter/sdk_ext/src/natives.h"
#include "lib/ui/views/fidl/view_containers.fidl.h"
#include "lib/ui/views/fidl/views.fidl.h"
#include "unique_fdio_ns.h"

namespace flutter {

// Contains all the information necessary to configure a new root isolate. This
// is a single use item. The lifetime of this object must extend past that of
// the root isolate.
class IsolateConfigurator final : mozart::NativesDelegate {
 public:
  IsolateConfigurator(
      const UniqueFDIONS& fdio_ns,
      mozart::ViewPtr& view,
      component::ApplicationEnvironmentPtr application_environment,
      f1dl::InterfaceRequest<component::ServiceProvider>
          outgoing_services_request);

  ~IsolateConfigurator();

  // Can be used only once and only on the UI thread with the newly created
  // isolate already current.
  bool ConfigureCurrentIsolate();

 private:
  bool used_ = false;
  const UniqueFDIONS& fdio_ns_;
  mozart::ViewPtr& view_;
  component::ApplicationEnvironmentPtr application_environment_;
  f1dl::InterfaceRequest<component::ServiceProvider> outgoing_services_request_;

  // |mozart::NativesDelegate|
  mozart::View* GetMozartView() override;

  void BindFuchsia();

  void BindZircon();

  void BindDartIO();

  void BindScenic();

  FXL_DISALLOW_COPY_AND_ASSIGN(IsolateConfigurator);
};

}  // namespace flutter
