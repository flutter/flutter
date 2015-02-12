// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/viewer/internals.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/viewer/document_view.h"
#include "sky/viewer/runtime_flags.h"
#include <limits>

using namespace blink;

namespace sky {
namespace {

int kInternalsKey = 0;

Internals* GetInternals() {
  DartState* state = DartState::Current();
  return static_cast<Internals*>(state->GetUserData(&kInternalsKey));
}

void RenderTreeAsText(Dart_NativeArguments args) {
  Dart_Handle result = StdStringToDart(GetInternals()->RenderTreeAsText());
  Dart_SetReturnValue(args, result);
}

void ContentAsText(Dart_NativeArguments args) {
  Dart_Handle result = StdStringToDart(GetInternals()->ContentAsText());
  Dart_SetReturnValue(args, result);
}

void NotifyTestComplete(Dart_NativeArguments args) {
  Dart_Handle test_result = Dart_GetNativeArgument(args, 0);
  GetInternals()->NotifyTestComplete(StdStringFromDart(test_result));
}

void PassShellProxyHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetInternals()->PassShellProxyHandle().value());
}

const DartBuiltin::Natives kNativeFunctions[] = {
  {"renderTreeAsText", RenderTreeAsText, 0},
  {"contentAsText", ContentAsText, 0},
  {"notifyTestComplete", NotifyTestComplete, 1},
  {"passShellProxyHandle", PassShellProxyHandle, 0},
};

const DartBuiltin& GetBuiltin() {
  static DartBuiltin& builtin = *new DartBuiltin(kNativeFunctions,
                                                 arraysize(kNativeFunctions));
  return builtin;
}

Dart_NativeFunction Resolver(Dart_Handle name,
                             int argument_count,
                             bool* auto_setup_scope) {
  return GetBuiltin().Resolver(name, argument_count, auto_setup_scope);
}

const uint8_t* Symbolizer(Dart_NativeFunction native_function) {
  return GetBuiltin().Symbolizer(native_function);
}

const char kLibraryName[] = "dart:sky.internals";
const char kLibrarySource[] = R"DART(
String renderTreeAsText() native "renderTreeAsText";
String contentAsText() native "contentAsText";
void notifyTestComplete(String test_result) native "notifyTestComplete";
int passShellProxyHandle() native "passShellProxyHandle";
)DART";

}  // namespace

void Internals::Create(Dart_Isolate isolate, DocumentView* document_view) {
  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(document_view));
  Dart_Handle library =
      Dart_LoadLibrary(Dart_NewStringFromCString(kLibraryName),
                       Dart_NewStringFromCString(kLibrarySource), 0, 0);
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_FinalizeLoading(true)));
  CHECK(!LogIfError(Dart_SetNativeResolver(library, Resolver, Symbolizer)));
}

Internals::Internals(DocumentView* document_view)
  : document_view_(document_view->GetWeakPtr()),
    shell_binding_(this) {
  if (document_view_->imported_services())
    mojo::ConnectToService(document_view_->imported_services(), &test_harness_);
}

Internals::~Internals() {
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
