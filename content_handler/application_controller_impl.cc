// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/application_controller_impl.h"

#include <utility>

#include <fdio/namespace.h>
#include <zircon/status.h>

#include "flutter/content_handler/app.h"
#include "flutter/content_handler/runtime_holder.h"
#include "lib/app/cpp/connect.h"
#include "lib/fsl/vmo/vector.h"
#include "lib/fxl/logging.h"

namespace flutter_runner {

ApplicationControllerImpl::ApplicationControllerImpl(
    App* app,
    app::ApplicationPackagePtr application,
    app::ApplicationStartupInfoPtr startup_info,
    f1dl::InterfaceRequest<app::ApplicationController> controller)
    : app_(app), binding_(this) {
  if (controller.is_valid()) {
    binding_.Bind(std::move(controller));
    binding_.set_error_handler([this] {
      app_->Destroy(this);
      // |this| has been deleted at this point.
    });
  }

  std::vector<char> bundle;
  if (application->data) {
    if (!fsl::VectorFromVmo(std::move(application->data), &bundle)) {
      FXL_LOG(ERROR) << "Failed to receive bundle.";
      return;
    }
  }

  // TODO(jeffbrown): Decide what to do with command-line arguments and
  // startup handles.

  if (startup_info->launch_info->directory_request.is_valid()) {
    service_provider_bridge_.ServeDirectory(
        std::move(startup_info->launch_info->directory_request));
  }

  service_provider_bridge_.AddService<mozart::ViewProvider>(
      [this](f1dl::InterfaceRequest<mozart::ViewProvider> request) {
        view_provider_bindings_.AddBinding(this, std::move(request));
      });

  app::ServiceProviderPtr service_provider;
  auto request = service_provider.NewRequest();
  service_provider_bridge_.set_backend(std::move(service_provider));

  fdio_ns_t* fdio_ns = SetupNamespace(startup_info->flat_namespace);
  if (fdio_ns == nullptr) {
    FXL_LOG(ERROR) << "Failed to initialize namespace";
    return;
  }

  url_ = startup_info->launch_info->url;
  runtime_holder_.reset(new RuntimeHolder());
  runtime_holder_->SetMainIsolateShutdownCallback([this]() { Kill(); });
  runtime_holder_->Init(
      fdio_ns, app::ApplicationContext::CreateFrom(std::move(startup_info)),
      std::move(request), std::move(bundle));
}

ApplicationControllerImpl::~ApplicationControllerImpl() = default;

constexpr char kServiceRootPath[] = "/svc";

fdio_ns_t* ApplicationControllerImpl::SetupNamespace(
    const app::FlatNamespacePtr& flat) {
  fdio_ns_t* fdio_namespc;
  zx_status_t status = fdio_ns_create(&fdio_namespc);
  if (status != ZX_OK) {
    FXL_LOG(ERROR) << "Failed to create namespace";
    return nullptr;
  }
  for (size_t i = 0; i < flat->paths.size(); ++i) {
    if (flat->paths[i] == kServiceRootPath) {
      // Ownership of /svc goes to the ApplicationContext created above.
      continue;
    }
    zx::channel dir = std::move(flat->directories[i]);
    zx_handle_t dir_handle = dir.release();
    const char* path = flat->paths[i]->data();
    status = fdio_ns_bind(fdio_namespc, path, dir_handle);
    if (status != ZX_OK) {
      FXL_LOG(ERROR) << "Failed to bind " << flat->paths[i] << " to namespace";
      zx_handle_close(dir_handle);
      fdio_ns_destroy(fdio_namespc);
      return nullptr;
    }
  }
  return fdio_namespc;
}

void ApplicationControllerImpl::Kill() {
  SendReturnCode(runtime_holder_->return_code());
  runtime_holder_.reset();
  app_->Destroy(this);
  // |this| has been deleted at this point.
}

void ApplicationControllerImpl::Detach() {
  binding_.set_error_handler(fxl::Closure());
}

void ApplicationControllerImpl::Wait(const WaitCallback& callback) {
  wait_callbacks_.push_back(callback);
}

void ApplicationControllerImpl::SendReturnCode(int32_t return_code) {
  for (const auto& iter : wait_callbacks_) {
    iter(return_code);
  }
  wait_callbacks_.clear();
}

void ApplicationControllerImpl::CreateView(
    f1dl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
    f1dl::InterfaceRequest<app::ServiceProvider> services) {
  runtime_holder_->CreateView(url_, std::move(view_owner_request),
                              std::move(services));
}

Dart_Port ApplicationControllerImpl::GetUIIsolateMainPort() {
  if (!runtime_holder_)
    return ILLEGAL_PORT;
  return runtime_holder_->GetUIIsolateMainPort();
}

std::string ApplicationControllerImpl::GetUIIsolateName() {
  if (!runtime_holder_) {
    return "";
  }
  return runtime_holder_->GetUIIsolateName();
}

}  // namespace flutter_runner
