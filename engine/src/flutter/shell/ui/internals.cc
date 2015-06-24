// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/internals.h"

#include "base/threading/worker_pool.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "services/asset_bundle/asset_unpacker_impl.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_state.h"

using namespace blink;

namespace sky {
namespace shell {
namespace {

int kInternalsKey = 0;

Internals* GetInternals() {
  DartState* state = DartState::Current();
  return static_cast<Internals*>(state->GetUserData(&kInternalsKey));
}

void ContentAsText(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_EmptyString());
}

void NotifyTestComplete(Dart_NativeArguments args) {
}

void RenderTreeAsText(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_EmptyString());
}

void TakeShellProxyHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, 0);
}

void TakeServicesProvidedByEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeServicesProvidedByEmbedder().value());
}

void TakeServicesProvidedToEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, 0);
}

void TakeServiceRegistry(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, 0);
}

const DartBuiltin::Natives kNativeFunctions[] = {
    {"contentAsText", ContentAsText, 0},
    {"notifyTestComplete", NotifyTestComplete, 1},
    {"renderTreeAsText", RenderTreeAsText, 0},
    {"takeShellProxyHandle", TakeShellProxyHandle, 0},
    {"takeServicesProvidedByEmbedder", TakeServicesProvidedByEmbedder, 0},
    {"takeServicesProvidedToEmbedder", TakeServicesProvidedToEmbedder, 0},
    {"takeServiceRegistry", TakeServiceRegistry, 0},
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

void Internals::Create(Dart_Isolate isolate,
                       mojo::ServiceProviderPtr service_provider) {
  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(service_provider.Pass()));
  Dart_Handle library =
      Dart_LookupLibrary(Dart_NewStringFromCString(kLibraryName));
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_SetNativeResolver(library, Resolver, Symbolizer)));
}

Internals::Internals(mojo::ServiceProviderPtr platform_service_provider)
  : service_provider_impl_(GetProxy(&service_provider_)),
    platform_service_provider_(platform_service_provider.Pass()) {
  service_provider_impl_.set_fallback_service_provider(
      platform_service_provider_.get());
  service_provider_impl_.AddService<mojo::asset_bundle::AssetUnpacker>(this);
}

Internals::~Internals() {
}

void Internals::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<mojo::asset_bundle::AssetUnpacker> request) {
  new mojo::asset_bundle::AssetUnpackerImpl(
      request.Pass(), base::WorkerPool::GetTaskRunner(true));
}

mojo::Handle Internals::TakeServicesProvidedByEmbedder() {
  return service_provider_.PassInterface().PassHandle().release();
}

}  // namespace shell
}  // namespace sky
