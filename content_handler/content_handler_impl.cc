// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/content_handler_impl.h"

#include <utility>

#include "flutter/content_handler/application_impl.h"

namespace flutter_content_handler {

ContentHandlerImpl::ContentHandlerImpl(
    mojo::InterfaceRequest<mojo::ContentHandler> request)
    : binding_(this, request.Pass()) {}

ContentHandlerImpl::~ContentHandlerImpl() {}

void ContentHandlerImpl::StartApplication(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response) {
  new ApplicationImpl(std::move(application), std::move(response));
}

}  // namespace flutter_content_handler
