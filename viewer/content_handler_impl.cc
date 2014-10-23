// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/content_handler_impl.h"

#include "sky/viewer/document_view.h"

namespace sky {

ContentHandlerImpl::ContentHandlerImpl(
    mojo::Shell* shell,
    scoped_refptr<base::MessageLoopProxy> compositor_thread)
  : shell_(shell),
    compositor_thread_(compositor_thread) {
}

ContentHandlerImpl::~ContentHandlerImpl() {
}

void ContentHandlerImpl::OnConnect(
      const mojo::String& url,
      mojo::URLResponsePtr response,
      mojo::InterfaceRequest<mojo::ServiceProvider> service_provider_request) {
  new DocumentView(response.Pass(), service_provider_request.Pass(),
                   shell_, compositor_thread_);
}

}  // namespace sky
