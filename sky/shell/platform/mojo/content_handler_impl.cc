// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/content_handler_impl.h"

#include "sky/shell/platform/mojo/sky_application_impl.h"

namespace sky {
namespace shell {

ContentHandlerImpl::ContentHandlerImpl(
    mojo::InterfaceRequest<mojo::ContentHandler> request)
    : binding_(this, request.Pass()) {
}

ContentHandlerImpl::~ContentHandlerImpl() {
}

void ContentHandlerImpl::StartApplication(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response) {
  new SkyApplicationImpl(application.Pass(), response.Pass());
}

}  // namespace shell
}  // namespace sky
