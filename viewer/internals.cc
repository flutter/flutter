// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/internals.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
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

void NotifyTestComplete(Dart_NativeArguments args) {
  Dart_Handle test_result = Dart_GetNativeArgument(args, 0);
  GetInternals()->NotifyTestComplete(StdStringFromDart(test_result));
}

void TakeRootBundleHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, 0);
}

void TakeShellProxyHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args,
      GetInternals()->TakeShellProxyHandle().value());
}

void TakeServicesProvidedByEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeServicesProvidedByEmbedder().value());
}

void TakeServicesProvidedToEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeServicesProvidedToEmbedder().value());
}

void TakeServiceRegistry(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeServiceRegistry().value());
}

const DartBuiltin::Natives kNativeFunctions[] = {
    {"notifyTestComplete", NotifyTestComplete, 1},
    {"takeRootBundleHandle", TakeRootBundleHandle, 0},
    {"takeServiceRegistry", TakeServiceRegistry, 0},
    {"takeServicesProvidedByEmbedder", TakeServicesProvidedByEmbedder, 0},
    {"takeServicesProvidedToEmbedder", TakeServicesProvidedToEmbedder, 0},
    {"takeShellProxyHandle", TakeShellProxyHandle, 0},
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

}  // namespace

void Internals::Create(Dart_Isolate isolate, DocumentView* document_view) {
  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(document_view));
  Dart_Handle library =
      Dart_LookupLibrary(Dart_NewStringFromCString(kLibraryName));
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_SetNativeResolver(library, Resolver, Symbolizer)));
}

Internals::Internals(DocumentView* document_view)
  : document_view_(document_view->GetWeakPtr()),
    shell_binding_(this) {
  test_harness_ = document_view_->TakeTestHarness();
}

Internals::~Internals() {
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

mojo::Handle Internals::TakeServicesProvidedToEmbedder() {
  if (!document_view_)
    return mojo::Handle();
  return document_view_->TakeServicesProvidedToEmbedder().release();
}

mojo::Handle Internals::TakeServicesProvidedByEmbedder() {
  if (!document_view_)
    return mojo::Handle();
  return document_view_->TakeServicesProvidedByEmbedder().release();
}

mojo::Handle Internals::TakeServiceRegistry() {
  if (!document_view_)
    return mojo::Handle();
  return document_view_->TakeServiceRegistry().release();
}

// Returns a MessagePipe handle that's connected to this Shell. The caller
// owns the handle and is expected to use it to create the JS Application for
// the DocumentView.
mojo::Handle Internals::TakeShellProxyHandle() {
  mojo::ShellPtr shell;
  if (!shell_binding_.is_bound())
    shell_binding_.Bind(GetProxy(&shell));
  return shell.PassInterface().PassHandle().release();
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

}  // namespace sky
