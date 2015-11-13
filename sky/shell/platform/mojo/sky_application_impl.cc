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
  : app_(this, application.Pass()),
    initial_response_(response.Pass()) {
}

SkyApplicationImpl::~SkyApplicationImpl() {
}

void SkyApplicationImpl::Initialize(mojo::ApplicationImpl* app) {
  DCHECK(initial_response_);
  UnpackInitialResponse();
  shell_view_.reset(new ShellView(Shell::Shared()));
  PlatformViewMojo* view = platform_view();
  view->Init(app);
  view->Run(app_.url(), bundle_.Pass());
}

bool SkyApplicationImpl::ConfigureIncomingConnection(
    mojo::ApplicationConnection* connection) {
  return true;
}

void SkyApplicationImpl::UnpackInitialResponse() {
  DCHECK(initial_response_);
  DCHECK(!bundle_);
  mojo::asset_bundle::AssetUnpackerPtr unpacker;
  app_.ConnectToService("mojo:asset_bundle", &unpacker);
  unpacker->UnpackZipStream(initial_response_->body.Pass(),
                            mojo::GetProxy(&bundle_));
  initial_response_ = nullptr;
}

}  // namespace shell
}  // namespace sky
