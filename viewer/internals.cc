// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/internals.h"

#include "mojo/edk/js/core.h"
#include "mojo/edk/js/handle.h"
#include "mojo/edk/js/support.h"
#include "mojo/edk/js/threading.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/viewer/document_view.h"
#include "sky/viewer/runtime_flags.h"
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
  object->Set(gin::StringToV8(isolate, "threading"),
              mojo::js::Threading::GetModule(isolate));
  return internals;
}

Internals::Internals(DocumentView* document_view)
  : document_view_(document_view->GetWeakPtr()),
    shell_binding_(this) {
  if (document_view_->imported_services())
    mojo::ConnectToService(document_view_->imported_services(), &test_harness_);
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
      .SetMethod("connectToEmbedderService",
                 &Internals::ConnectToEmbedderService)
      .SetMethod("pauseAnimations", &Internals::pauseAnimations)
      .SetMethod("passShellProxyHandle", &Internals::PassShellProxyHandle);
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
  if (!RuntimeFlags::Get().testing())
    return;
  std::vector<unsigned char> pixels;
  document_view_->GetPixelsForTesting(&pixels);
  if (test_harness_) {
    test_harness_->OnTestComplete(test_result,
        mojo::Array<uint8_t>::From(pixels));
  }
}

mojo::Handle Internals::ConnectToEmbedderService(
    const std::string& interface_name) {
  if (!document_view_ || !document_view_->imported_services())
    return mojo::Handle();

  mojo::MessagePipe pipe;
  document_view_->imported_services()->ConnectToService(interface_name,
                                                        pipe.handle1.Pass());
  return pipe.handle0.release();
}

// Returns a MessagePipe handle that's connected to this Shell. The caller
// owns the handle and is expected to use it to create the JS Application for
// the DocumentView.
mojo::Handle Internals::PassShellProxyHandle() {
  mojo::ShellPtr shell;
  if (!shell_binding_.is_bound())
    shell_binding_.Bind(GetProxy(&shell));
  return shell.PassMessagePipe().release();
}

void Internals::ConnectToApplication(
    const mojo::String& application_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::ServiceProviderPtr exposed_services) {
  if (document_view_) {
    document_view_->shell()->ConnectToApplication(
        application_url, services.Pass(), exposed_services.Pass());
  }
}

mojo::Handle Internals::ConnectToService(
    const std::string& application_url, const std::string& interface_name) {
  if (!document_view_)
    return mojo::Handle();

  mojo::ServiceProviderPtr service_provider;
  ConnectToApplication(application_url, mojo::GetProxy(&service_provider),
                       nullptr);

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
