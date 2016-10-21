// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/application_impl.h"

#include <utility>

#include "flutter/content_handler/runtime_holder.h"
#include "lib/ftl/logging.h"
#include "lib/mtl/data_pipe/vector.h"
#include "lib/mtl/shared_buffer/strings.h"
#include "lib/zip/unzipper.h"
#include "mojo/public/cpp/application/connect.h"

namespace flutter_content_handler {

ApplicationImpl::ApplicationImpl(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response)
    : binding_(this, std::move(application)) {
  if (response->body->is_stream()) {
    // TODO(abarth): Currently we block the UI thread to drain the response body,
    // but we should do that work asynchronously instead. However, there when I
    // tried draining the data pipe asynchronously, the drain didn't complete.
    // We'll need to investigate why in more detail.
    bool result = mtl::BlockingCopyToVector(std::move(response->body->get_stream()), &bundle_);
    if (!result) {
      FTL_LOG(ERROR) << "Failed to receive bundle.";
      return;
    }
  } else if (response->body->is_buffer()) {
    std::string string;
    bool result = mtl::StringFromSharedBuffer(std::move(response->body->get_buffer()), &string);
    if (!result) {
      FTL_LOG(ERROR) << "Failed to receive bundle.";
      return;
    }
    bundle_.assign(string.begin(), string.end());
  } else {
    FTL_NOTREACHED();
  }
}

ApplicationImpl::~ApplicationImpl() {}

void ApplicationImpl::Initialize(mojo::InterfaceHandle<mojo::Shell> shell,
                                 mojo::Array<mojo::String> args,
                                 const mojo::String& url) {
  shell_ = mojo::ShellPtr::Create(shell.Pass());
  url_ = url;
  mojo::ApplicationConnectorPtr connector;
  shell_->CreateApplicationConnector(mojo::GetProxy(&connector));
  runtime_holder_.reset(new RuntimeHolder());
  runtime_holder_->Init(std::move(connector), std::move(bundle_));
}

void ApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    const mojo::String& resolved_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services) {
  service_provider_bindings_.AddBinding(this, std::move(services));
}

void ApplicationImpl::RequestQuit() {
  binding_.Close();
  delete this;
}

void ApplicationImpl::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {
  if (service_name == mozart::ViewProvider::Name_) {
    view_provider_bindings_.AddBinding(
        this,
        mojo::InterfaceRequest<mozart::ViewProvider>(std::move(client_handle)));
  }
}

void ApplicationImpl::CreateView(
    mojo::InterfaceRequest<mozart::ViewOwner> view_owner_request,
    mojo::InterfaceRequest<mojo::ServiceProvider> services) {
  runtime_holder_->CreateView(url_, std::move(view_owner_request),
                              std::move(services));
}

}  // namespace flutter_content_handler
