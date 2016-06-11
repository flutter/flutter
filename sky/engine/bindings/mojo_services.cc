// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/mojo_services.h"

#include "base/threading/worker_pool.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/dart_library_natives.h"
#include "flutter/tonic/dart_state.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "sky/engine/bindings/flutter_dart_state.h"

namespace blink {
namespace {

MojoServices* GetMojoServices() {
  return static_cast<FlutterDartState*>(DartState::Current())->mojo_services();
}

void DartTakeRootBundle(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeRootBundle());
}

void DartTakeIncomingServices(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeIncomingServices());
}

void DartTakeOutgoingServices(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeOutgoingServices());
}

void DartTakeShell(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeShell());
}

void DartTakeView(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeView());
}

void DartTakeViewServices(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, GetMojoServices()->TakeViewServices());
}

}  // namespace

void MojoServices::RegisterNatives(DartLibraryNatives* natives) {
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
  FlutterDartState* state = static_cast<FlutterDartState*>(
      DartState::From(isolate));
  state->set_mojo_services(std::unique_ptr<MojoServices>(new MojoServices(
      services.Pass(), incoming_services.Pass(), root_bundle.Pass())));
}

MojoServices::MojoServices(sky::ServicesDataPtr services,
                           mojo::ServiceProviderPtr incoming_services,
                           mojo::asset_bundle::AssetBundlePtr root_bundle)
  : services_(services.Pass()),
    root_bundle_(root_bundle.Pass()),
    incoming_services_(incoming_services.Pass()) {
  if (services_ && services_->outgoing_services.is_pending()) {
    outgoing_services_ = services_->outgoing_services.Pass();
  } else {
    outgoing_services_ = GetProxy(&services_from_dart_);
  }
}

MojoServices::~MojoServices() {
}

int MojoServices::TakeRootBundle() {
  return root_bundle_.PassInterfaceHandle().PassHandle().release().value();
}

int MojoServices::TakeIncomingServices() {
  return incoming_services_.PassInterfaceHandle().PassHandle().release().value();
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
