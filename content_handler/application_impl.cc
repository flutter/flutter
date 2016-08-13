// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/application_impl.h"

#include <utility>

#include "lib/ftl/logging.h"
#include "mojo/public/cpp/application/connect.h"

namespace flutter_content_handler {

ApplicationImpl::ApplicationImpl(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response)
    : binding_(this, std::move(application)),
      initial_response_(std::move(response)) {}

ApplicationImpl::~ApplicationImpl() {}

void ApplicationImpl::Initialize(mojo::InterfaceHandle<mojo::Shell> shell,
                                 mojo::Array<mojo::String> args,
                                 const mojo::String& url) {
  FTL_DCHECK(initial_response_);
  shell_ = mojo::ShellPtr::Create(shell.Pass());
  url_ = url;
}

void ApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    const mojo::String& resolved_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services) {}

void ApplicationImpl::RequestQuit() {
  binding_.Close();
  delete this;
}

}  // namespace flutter_content_handler
