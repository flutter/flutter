// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/internals.h"

#include <limits>

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "services/sky/document_view.h"
#include "services/sky/runtime_flags.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_library_natives.h"

using namespace blink;

namespace sky {
namespace {

int kInternalsKey = 0;

Internals* GetInternals() {
  DartState* state = DartState::Current();
  return static_cast<Internals*>(state->GetUserData(&kInternalsKey));
}

void TakeRootBundleHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args,
      GetInternals()->TakeRootBundleHandle().value());
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

static DartLibraryNatives* g_natives;

void EnsureNatives() {
  if (g_natives)
    return;
  g_natives = new DartLibraryNatives();
  g_natives->Register({
    {"takeRootBundleHandle", TakeRootBundleHandle, 0, true},
    {"takeServiceRegistry", TakeServiceRegistry, 0, true},
    {"takeServicesProvidedByEmbedder", TakeServicesProvidedByEmbedder, 0, true},
    {"takeServicesProvidedToEmbedder", TakeServicesProvidedToEmbedder, 0, true},
    {"takeShellProxyHandle", TakeShellProxyHandle, 0, true},
  });
}

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  return g_natives->GetSymbol(native_function);
}

}  // namespace

void Internals::Create(Dart_Isolate isolate, DocumentView* document_view) {
  EnsureNatives();

  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(document_view));
  Dart_Handle library = Dart_LookupLibrary(ToDart("dart:ui_internals"));
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_SetNativeResolver(
      library, GetNativeFunction, GetSymbol)));
}

Internals::Internals(DocumentView* document_view)
  : document_view_(document_view->GetWeakPtr()),
    shell_binding_(this) {
}

Internals::~Internals() {
}

mojo::Handle Internals::TakeRootBundleHandle() {
  if (!document_view_)
    return mojo::Handle();
  return document_view_->TakeRootBundleHandle().release();
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
