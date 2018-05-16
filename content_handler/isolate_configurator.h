// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <component/cpp/fidl.h>
#include <ui/cpp/fidl.h>
#include <views_v1/cpp/fidl.h>

#include "lib/fxl/macros.h"
#include "lib/ui/flutter/sdk_ext/src/natives.h"
#include "unique_fdio_ns.h"

namespace flutter {

// Contains all the information necessary to configure a new root isolate. This
// is a single use item. The lifetime of this object must extend past that of
// the root isolate.
class IsolateConfigurator final {
 public:
  IsolateConfigurator(
      UniqueFDIONS fdio_ns,
      fidl::InterfaceHandle<views_v1::ViewContainer> view_container,
      fidl::InterfaceHandle<component::ApplicationEnvironment>
          application_environment,
      fidl::InterfaceRequest<component::ServiceProvider>
          outgoing_services_request);

  ~IsolateConfigurator();

  // Can be used only once and only on the UI thread with the newly created
  // isolate already current.
  bool ConfigureCurrentIsolate(mozart::NativesDelegate* natives_delegate);

 private:
  bool used_ = false;
  UniqueFDIONS fdio_ns_;
  fidl::InterfaceHandle<views_v1::ViewContainer> view_container_;
  fidl::InterfaceHandle<component::ApplicationEnvironment>
      application_environment_;
  fidl::InterfaceRequest<component::ServiceProvider> outgoing_services_request_;

  void BindFuchsia();

  void BindZircon();

  void BindDartIO();

  void BindScenic(mozart::NativesDelegate* natives_delegate);

  FXL_DISALLOW_COPY_AND_ASSIGN(IsolateConfigurator);
};

}  // namespace flutter
