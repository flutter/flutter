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
  PlatformViewMojo* view = platform_view();
  view->Init(shell.Pass());
  view->Run(url, bundle_.Pass());
}

void SkyApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::ServiceProviderPtr exposed_services,
    const mojo::String& resolved_url) {
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
