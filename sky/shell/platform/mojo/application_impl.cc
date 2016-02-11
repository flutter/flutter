// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/application_impl.h"

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
}

void ApplicationImpl::Initialize(mojo::ShellPtr shell,
                                 mojo::Array<mojo::String> args,
                                 const mojo::String& url) {
  DCHECK(initial_response_);
  shell_ = shell.Pass();
  url_ = url;
  UnpackInitialResponse(shell_.get());
}

void ApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
    mojo::ServiceProviderPtr incoming_services,
    const mojo::String& resolved_url) {
  service_provider_bindings_.AddBinding(this, outgoing_services.Pass());

  // It's unclear where we should get the service registry from. We currently
  // get it from the first incomming application connection, which happens to
  // work for our current use cases, but it's fragile and unsatifying. We'll
  // probably need to re-think service registry once more of the system exists.
  if (incoming_services && !initial_service_registry_)
    mojo::ConnectToService(incoming_services.get(), &initial_service_registry_);
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

void ApplicationImpl::CreateView(
    mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
    mojo::ServiceProviderPtr incoming_services,
    const mojo::ui::ViewProvider::CreateViewCallback& callback) {
  if (!bundle_) {
    LOG(ERROR) << "We only support creating one view.";
    return;
  }

  ServicesDataPtr services = ServicesData::New();
  services->shell = shell_.Pass();
  services->service_registry = initial_service_registry_.Pass();
  services->services_provided_by_embedder = incoming_services.Pass();
  services->services_provided_to_embedder = outgoing_services.Pass();

  ViewImpl* view = new ViewImpl(services.Pass(), url_, callback);
  view->Run(bundle_.Pass());
}

void ApplicationImpl::UnpackInitialResponse(mojo::Shell* shell) {
  DCHECK(initial_response_);
  DCHECK(!bundle_);
  mojo::asset_bundle::AssetUnpackerPtr unpacker;
  mojo::ConnectToService(shell, "mojo:asset_bundle", &unpacker);
  unpacker->UnpackZipStream(initial_response_->body.Pass(),
                            mojo::GetProxy(&bundle_));
  initial_response_ = nullptr;
}

}  // namespace shell
}  // namespace sky
