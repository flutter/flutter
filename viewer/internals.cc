// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/internals.h"

#include "mojo/edk/js/core.h"
#include "mojo/edk/js/handle.h"
#include "mojo/edk/js/support.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/viewer/document_view.h"
#include "v8/include/v8.h"
#include <limits>

namespace sky {

gin::WrapperInfo Internals::kWrapperInfo = {gin::kEmbedderNativeGin};

// static
gin::Handle<Internals> Internals::Create(
    v8::Isolate* isolate, DocumentView* document_view) {
  gin::Handle<Internals> internals =
      gin::CreateHandle(isolate, new Internals(document_view));
  v8::Handle<v8::Object> object = internals.ToV8().As<v8::Object>();
  object->Set(gin::StringToV8(isolate, "core"),
              mojo::js::Core::GetModule(isolate));
  object->Set(gin::StringToV8(isolate, "support"),
              mojo::js::Support::GetModule(isolate));
  return internals;
}

Internals::Internals(DocumentView* document_view)
    : document_view_(document_view->GetWeakPtr()) {
  mojo::ConnectToService(document_view->imported_services(), &test_harness_);
}

Internals::~Internals() {
}

gin::ObjectTemplateBuilder Internals::GetObjectTemplateBuilder(
    v8::Isolate* isolate) {
  return Wrappable<Internals>::GetObjectTemplateBuilder(isolate)
      .SetMethod("renderTreeAsText", &Internals::RenderTreeAsText)
      .SetMethod("contentAsText", &Internals::ContentAsText)
      .SetMethod("notifyTestComplete", &Internals::NotifyTestComplete)
      .SetMethod("connectToService", &Internals::ConnectToService)
      .SetMethod("pauseAnimations", &Internals::pauseAnimations);
}

std::string Internals::RenderTreeAsText() {
  if (!document_view_)
    return std::string();
  return document_view_->web_view()->mainFrame()->renderTreeAsText().utf8();
}

std::string Internals::ContentAsText() {
  if (!document_view_)
    return std::string();
  return document_view_->web_view()->mainFrame()->contentAsText(
      1024*1024).utf8();
}

void Internals::NotifyTestComplete(const std::string& test_result) {
  test_harness_->OnTestComplete(test_result);
}

mojo::Handle Internals::ConnectToService(
    const std::string& application_url, const std::string& interface_name) {
  if (!document_view_)
    return mojo::Handle();

  mojo::ServiceProviderPtr service_provider;
  document_view_->shell()->ConnectToApplication(
      application_url, mojo::GetProxy(&service_provider));

  mojo::MessagePipe pipe;
  service_provider->ConnectToService(interface_name, pipe.handle1.Pass());
  return pipe.handle0.release();
}

void Internals::pauseAnimations(double pauseTime) {
  if (pauseTime < 0)
    return;

    document_view_->web_view()->mainFrame()->document().pauseAnimationsForTesting(pauseTime);
}

}  // namespace sky
