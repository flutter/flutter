// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/sky_application_impl.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

SkyApplicationImpl::SkyApplicationImpl(
  mojo::InterfaceRequest<mojo::Application> application,
  mojo::URLResponsePtr response)
  : binding_(this, application.Pass()),
    initial_response_(response.Pass()) {
}

SkyApplicationImpl::~SkyApplicationImpl() {
}

void SkyApplicationImpl::Initialize(mojo::ShellPtr shell,
                                    mojo::Array<mojo::String> args,
                                    const mojo::String& url) {
  DCHECK(initial_response_);
  UnpackInitialResponse(shell.get());
  shell_view_.reset(new ShellView(Shell::Shared()));
  platform_view()->Init(shell.get());
  shell_ = shell.Pass();
}

void SkyApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
    mojo::ServiceProviderPtr incoming_services,
    const mojo::String& resolved_url) {
  if (!bundle_) {
    LOG(INFO) << "Cannot handle multiple connections yet.";
    return;
  }

  mojo::ServiceRegistryPtr service_registry;

  if (incoming_services)
    mojo::ConnectToService(incoming_services.get(), &service_registry);

  ServicesDataPtr services = ServicesData::New();
  services->shell = shell_.Pass();
  services->service_registry = service_registry.Pass();
  platform_view()->Run(resolved_url, services.Pass(), bundle_.Pass());
}

void SkyApplicationImpl::RequestQuit() {
}

void SkyApplicationImpl::UnpackInitialResponse(mojo::Shell* shell) {
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
