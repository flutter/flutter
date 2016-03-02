// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/application_impl.h"

#include "base/files/file_util.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "mojo/public/cpp/application/connect.h"
#include "sky/shell/platform/mojo/view_impl.h"

namespace sky {
namespace shell {

ApplicationImpl::ApplicationImpl(
  mojo::InterfaceRequest<mojo::Application> application,
  mojo::URLResponsePtr response)
  : binding_(this, application.Pass()),
    initial_response_(response.Pass()) {
}

ApplicationImpl::~ApplicationImpl() {
  if (!flx_path_.empty()) {
    base::DeleteFile(flx_path_, false);
  }
}

void ApplicationImpl::Initialize(mojo::InterfaceHandle<mojo::Shell> shell,
                                 mojo::Array<mojo::String> args,
                                 const mojo::String& url) {
  DCHECK(initial_response_);
  shell_ = mojo::ShellPtr::Create(shell.Pass());
  url_ = url;
  UnpackInitialResponse(shell_.get());
}

void ApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
    mojo::InterfaceHandle<mojo::ServiceProvider> incoming_services,
    const mojo::String& resolved_url) {
  service_provider_bindings_.AddBinding(this, outgoing_services.Pass());
}

void ApplicationImpl::RequestQuit() {
}

void ApplicationImpl::ConnectToService(const mojo::String& service_name,
                                       mojo::ScopedMessagePipeHandle handle) {
  if (service_name == mojo::ui::ViewProvider::Name_) {
    view_provider_bindings_.AddBinding(
        this, mojo::MakeRequest<mojo::ui::ViewProvider>(handle.Pass()));
  }
}

void ApplicationImpl::ConnectToApplication(
    const mojo::String& application_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::InterfaceHandle<mojo::ServiceProvider> exposed_services) {
  shell_->ConnectToApplication(application_url,
                               services.Pass(),
                               exposed_services.Pass());
}

void ApplicationImpl::CreateApplicationConnector(
    mojo::InterfaceRequest<mojo::ApplicationConnector> request) {
  shell_->CreateApplicationConnector(request.Pass());
}

void ApplicationImpl::CreateView(
    mojo::InterfaceRequest<mojo::ui::ViewOwner> view_owner,
      mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
      mojo::InterfaceHandle<mojo::ServiceProvider> incoming_services) {
  // TODO(abarth): Rather than proxying the shell, we should give Dart an
  //               ApplicationConnectorPtr instead of a ShellPtr.
  mojo::ShellPtr shell;
  shell_bindings_.AddBinding(this, mojo::GetProxy(&shell));

  ServicesDataPtr services = ServicesData::New();
  services->shell = shell.Pass();
  services->services_provided_by_embedder = incoming_services.Pass();
  services->services_provided_to_embedder = outgoing_services.Pass();

  ViewImpl* view = new ViewImpl(view_owner.Pass(), services.Pass(), url_);
  view->Run(flx_path_);
}

void ApplicationImpl::UnpackInitialResponse(mojo::Shell* shell) {
  DCHECK(initial_response_);
  DCHECK(flx_path_.empty());

  if (!base::CreateTemporaryFile(&flx_path_)) {
    LOG(ERROR) << "Unable to create temporary file";
    return;
  }
  FILE* temp_file = base::OpenFile(flx_path_, "w");
  if (temp_file == nullptr) {
    LOG(ERROR) << "Unable to open temporary file";
    return;
  }

  mojo::common::BlockingCopyToFile(initial_response_->body.Pass(),
                                   temp_file);
  base::CloseFile(temp_file);

  initial_response_ = nullptr;
}

}  // namespace shell
}  // namespace sky
