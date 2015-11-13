// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/internals.h"

#include "base/threading/worker_pool.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "services/asset_bundle/asset_unpacker_impl.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_library_natives.h"
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

void TakeRootBundleHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeRootBundleHandle().value());
}

void TakeShellProxyHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, 0);
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
  Dart_SetIntegerReturnValue(args, 0);
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

void Internals::Create(Dart_Isolate isolate,
                       mojo::ServiceProviderPtr service_provider,
                       mojo::asset_bundle::AssetBundlePtr root_bundle) {
  EnsureNatives();

  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(service_provider.Pass(),
                                                   root_bundle.Pass()));
  Dart_Handle library = Dart_LookupLibrary(ToDart("dart:ui_internals"));
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_SetNativeResolver(
      library, GetNativeFunction, GetSymbol)));
}

Internals::Internals(mojo::ServiceProviderPtr platform_service_provider,
                     mojo::asset_bundle::AssetBundlePtr root_bundle)
  : root_bundle_(root_bundle.Pass()),
    service_provider_impl_(GetProxy(&service_provider_)),

    platform_service_provider_(platform_service_provider.Pass()) {
  service_provider_impl_.set_fallback_service_provider(
      platform_service_provider_.get());
  service_provider_impl_.AddService<mojo::asset_bundle::AssetUnpacker>(this);

  // Currently we don't consume any services provided by the application.
  // So there's no need to hold the proxy to the application's ServiceProvider.
  mojo::ServiceProviderPtr application_service_provider;
  services_provided_to_embedder_ = GetProxy(&application_service_provider);
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

mojo::Handle Internals::TakeRootBundleHandle() {
  return root_bundle_.PassInterface().PassHandle().release();
}

mojo::Handle Internals::TakeServicesProvidedToEmbedder() {
  return services_provided_to_embedder_.PassMessagePipe().release();
}

}  // namespace shell
}  // namespace sky
