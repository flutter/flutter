// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/services/inspector_impl.h"

#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/viewer/document_view.h"

namespace sky {

InspectorServiceImpl::InspectorServiceImpl(DocumentView* view)
    : view_(view->GetWeakPtr()) {
}

InspectorServiceImpl::~InspectorServiceImpl() {
}

void InspectorServiceImpl::Inject() {
  if (!view_)
    return;
  view_->web_view()->injectModule("/sky/framework/inspector/inspector.sky");
}

}  // namespace sky
