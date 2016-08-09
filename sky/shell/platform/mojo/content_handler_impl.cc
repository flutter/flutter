// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/mojo/content_handler_impl.h"

#include "flutter/sky/shell/platform/mojo/application_impl.h"

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
  new ApplicationImpl(application.Pass(), response.Pass());
}

}  // namespace shell
}  // namespace sky
