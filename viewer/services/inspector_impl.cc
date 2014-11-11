// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/services/inspector_impl.h"

#include "base/bind.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/services/inspector/inspector.mojom.h"
#include "sky/viewer/document_view.h"

namespace sky {

InspectorServiceImpl::InspectorServiceImpl(DocumentView* view)
    : view_(view->GetWeakPtr()) {
}

InspectorServiceImpl::~InspectorServiceImpl() {
}

void Ignored() {}

void InspectorServiceImpl::Inject() {
  if (!view_)
    return;

  mojo::ServiceProviderPtr inpector_service_provider;
  view_->shell()->ConnectToApplication("mojo:sky_inspector_server",
                                       GetProxy(&inpector_service_provider));
  InspectorServerPtr inspector;
  ConnectToService(inpector_service_provider.get(), &inspector);
  inspector->Listen(9898, base::Bind(&Ignored));
  // Listen drops existing agents/backends, wait before registering new ones.
  inspector.WaitForIncomingMethodCall();

  view_->web_view()->injectModule("/sky/framework/inspector/inspector.sky");
}

}  // namespace sky
