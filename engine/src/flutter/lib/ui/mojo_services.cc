// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/mojo_services.h"

#include "flutter/lib/ui/ui_dart_state.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_error.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"

using tonic::DartState;

namespace blink {
namespace {

MojoServices* GetMojoServices() {
  return static_cast<UIDartState*>(DartState::Current())->mojo_services();
}

void DartTakeRootBundle(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeRootBundle();
  Dart_SetIntegerReturnValue(args, handle);
}

void DartTakeIncomingServices(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeIncomingServices();
  Dart_SetIntegerReturnValue(args, handle);
}

void DartTakeOutgoingServices(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeOutgoingServices();
  Dart_SetIntegerReturnValue(args, handle);
}

void DartTakeShell(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeShell();
  Dart_SetIntegerReturnValue(args, handle);
}

void DartTakeView(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeView();
  Dart_SetIntegerReturnValue(args, handle);
}

void DartTakeViewServices(Dart_NativeArguments args) {
  int handle = MOJO_HANDLE_INVALID;
  if (MojoServices* services = GetMojoServices())
    handle = services->TakeViewServices();
  Dart_SetIntegerReturnValue(args, handle);
}

}  // namespace

void MojoServices::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"MojoServices_takeRootBundle", DartTakeRootBundle, 0, true},
      {"MojoServices_takeIncomingServices", DartTakeIncomingServices, 0, true},
      {"MojoServices_takeOutgoingServices", DartTakeOutgoingServices, 0, true},
      {"MojoServices_takeShell", DartTakeShell, 0, true},
      {"MojoServices_takeView", DartTakeView, 0, true},
      {"MojoServices_takeViewServices", DartTakeViewServices, 0, true},
  });
}

void MojoServices::Create(Dart_Isolate isolate,
                          sky::ServicesDataPtr services,
                          mojo::ServiceProviderPtr incoming_services,
                          mojo::asset_bundle::AssetBundlePtr root_bundle) {
  UIDartState* state = static_cast<UIDartState*>(DartState::From(isolate));
  state->set_mojo_services(std::unique_ptr<MojoServices>(
      new MojoServices(std::move(services), std::move(incoming_services),
                       std::move(root_bundle))));
}

MojoServices::MojoServices(sky::ServicesDataPtr services,
                           mojo::ServiceProviderPtr incoming_services,
                           mojo::asset_bundle::AssetBundlePtr root_bundle)
    : services_(std::move(services)),
      root_bundle_(std::move(root_bundle)),
      incoming_services_(std::move(incoming_services)) {
  if (services_ && services_->outgoing_services.is_pending()) {
    outgoing_services_ = std::move(services_->outgoing_services);
  } else {
    outgoing_services_ = GetProxy(&services_from_dart_);
  }
}

MojoServices::~MojoServices() {}

int MojoServices::TakeRootBundle() {
  return root_bundle_.PassInterfaceHandle().PassHandle().release().value();
}

int MojoServices::TakeIncomingServices() {
  return incoming_services_.PassInterfaceHandle()
      .PassHandle()
      .release()
      .value();
}

int MojoServices::TakeOutgoingServices() {
  return outgoing_services_.PassMessagePipe().release().value();
}

int MojoServices::TakeShell() {
  if (services_)
    return services_->shell.PassHandle().release().value();
  return MOJO_HANDLE_INVALID;
}

int MojoServices::TakeView() {
  if (services_)
    return services_->view.PassHandle().release().value();
  return MOJO_HANDLE_INVALID;
}

int MojoServices::TakeViewServices() {
  if (services_)
    return services_->view_services.PassHandle().release().value();
  return MOJO_HANDLE_INVALID;
}

}  // namespace blink
