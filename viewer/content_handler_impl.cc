// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/content_handler_impl.h"

#include "sky/viewer/document_view.h"

namespace sky {

ContentHandlerImpl::ContentHandlerImpl(
    scoped_refptr<base::MessageLoopProxy> compositor_thread)
    : compositor_thread_(compositor_thread) {
}

ContentHandlerImpl::~ContentHandlerImpl() {
}

void ContentHandlerImpl::StartApplication(mojo::ShellPtr shell,
                                          mojo::URLResponsePtr response) {
  new DocumentView(response.Pass(), shell.Pass(), compositor_thread_);
}

}  // namespace sky
