// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/application_controller_impl.h"

#include <utility>

#include "apps/modular/lib/app/connect.h"
#include "flutter/content_handler/app.h"
#include "flutter/content_handler/runtime_holder.h"
#include "lib/ftl/logging.h"
#include "lib/mtl/vmo/vector.h"

namespace flutter_runner {

ApplicationControllerImpl::ApplicationControllerImpl(
    App* app,
    modular::ApplicationPackagePtr application,
    modular::ApplicationStartupInfoPtr startup_info,
    fidl::InterfaceRequest<modular::ApplicationController> controller)
    : app_(app), binding_(this) {
  if (controller.is_pending()) {
    binding_.Bind(std::move(controller));
    binding_.set_connection_error_handler([this] {
      app_->Destroy(this);
      // |this| has been deleted at this point.
    });
  }

  std::vector<char> bundle;
  if (!mtl::VectorFromVmo(std::move(application->data), &bundle)) {
    FTL_LOG(ERROR) << "Failed to receive bundle.";
    return;
  }

  // TODO(jeffbrown): Decide what to do with command-line arguments and
  // startup handles.

  if (startup_info->launch_info->services) {
    service_provider_bindings_.AddBinding(
        this, std::move(startup_info->launch_info->services));
  }

  url_ = startup_info->launch_info->url;
  runtime_holder_.reset(new RuntimeHolder());
  runtime_holder_->Init(std::move(startup_info->environment),
                        fidl::GetProxy(&dart_service_provider_),
                        std::move(bundle));
}

ApplicationControllerImpl::~ApplicationControllerImpl() = default;

void ApplicationControllerImpl::Kill(const KillCallback& callback) {
  runtime_holder_.reset();
  app_->Destroy(this);
  // |this| has been deleted at this point.
}

void ApplicationControllerImpl::Detach() {
  binding_.set_connection_error_handler(ftl::Closure());
}

void ApplicationControllerImpl::ConnectToService(
    const fidl::String& service_name,
    mx::channel channel) {
  if (service_name == mozart::ViewProvider::Name_) {
    view_provider_bindings_.AddBinding(
        this, fidl::InterfaceRequest<mozart::ViewProvider>(std::move(channel)));
  } else {
    dart_service_provider_->ConnectToService(service_name, std::move(channel));
  }
}

void ApplicationControllerImpl::CreateView(
    fidl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
    fidl::InterfaceRequest<modular::ServiceProvider> services) {
  runtime_holder_->CreateView(url_, std::move(view_owner_request),
                              std::move(services));
}

}  // namespace flutter_runner
