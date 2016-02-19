// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/mojo_services.h"

#include "base/threading/worker_pool.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "services/asset_bundle/asset_unpacker_impl.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "sky/engine/tonic/dart_state.h"

namespace blink {
namespace {

int kMojoServicesKey = 0;

MojoServices* GetMojoServices() {
  DartState* state = DartState::Current();
  return static_cast<MojoServices*>(state->GetUserData(&kMojoServicesKey));
}

void DartTakeRootBundleHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetMojoServices()->TakeRootBundleHandle().value());
}

void DartTakeShellProxyHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetMojoServices()->TakeShellProxy().value());
}

void DartTakeServicesProvidedByEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetMojoServices()->TakeServicesProvidedByEmbedder().value());
}

void DartTakeServicesProvidedToEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetMojoServices()->TakeServicesProvidedToEmbedder().value());
}

void DartTakeViewHostHandle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetMojoServices()->TakeViewHostHandle().value());
}

}  // namespace

void MojoServices::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    {"takeRootBundleHandle", DartTakeRootBundleHandle, 0, true},
    {"takeServicesProvidedByEmbedder", DartTakeServicesProvidedByEmbedder, 0, true},
    {"takeServicesProvidedToEmbedder", DartTakeServicesProvidedToEmbedder, 0, true},
    {"takeShellProxyHandle", DartTakeShellProxyHandle, 0, true},
    {"takeViewHostHandle", DartTakeViewHostHandle, 0, true},
  });
}

void MojoServices::Create(Dart_Isolate isolate,
                          sky::ServicesDataPtr services,
                          mojo::asset_bundle::AssetBundlePtr root_bundle) {
  DartState* state = DartState::From(isolate);
  state->SetUserData(&kMojoServicesKey, new MojoServices(
      services.Pass(), root_bundle.Pass()));
}

MojoServices::MojoServices(sky::ServicesDataPtr services,
                           mojo::asset_bundle::AssetBundlePtr root_bundle)
  : services_(services.Pass()),
    root_bundle_(root_bundle.Pass()),
    service_provider_impl_(GetProxy(&service_provider_)) {
  if (services_ && services_->services_provided_by_embedder) {
    service_provider_impl_.set_fallback_service_provider(
        services_->services_provided_by_embedder.get());
  }
  service_provider_impl_.AddService<mojo::asset_bundle::AssetUnpacker>(this);
  if (services_ && services_->services_provided_to_embedder.is_pending()) {
    services_provided_to_embedder_ = services_->services_provided_to_embedder.Pass();
  } else {
    services_provided_to_embedder_ = GetProxy(&services_from_dart_);
  }
}

MojoServices::~MojoServices() {
}

void MojoServices::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<mojo::asset_bundle::AssetUnpacker> request) {
  new mojo::asset_bundle::AssetUnpackerImpl(
      request.Pass(), base::WorkerPool::GetTaskRunner(true));
}

mojo::Handle MojoServices::TakeShellProxy() {
  return services_ ? services_->shell.PassInterface().PassHandle().release() : mojo::Handle();
}

mojo::Handle MojoServices::TakeServicesProvidedByEmbedder() {
  return service_provider_.PassInterface().PassHandle().release();
}

mojo::Handle MojoServices::TakeRootBundleHandle() {
  return root_bundle_.PassInterface().PassHandle().release();
}

mojo::Handle MojoServices::TakeServicesProvidedToEmbedder() {
  return services_provided_to_embedder_.PassMessagePipe().release();
}

mojo::Handle MojoServices::TakeViewHostHandle() {
  return services_ ? services_->view_host.PassInterface().PassHandle().release() : mojo::Handle();
}

}  // namespace blink
