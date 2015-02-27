// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/shell/ui/internals.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
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

void TakeServicesProvidedByEmbedder(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(
      args, GetInternals()->TakeServicesProvidedByEmbedder().value());
}

const DartBuiltin::Natives kNativeFunctions[] = {
    {"takeServicesProvidedByEmbedder", TakeServicesProvidedByEmbedder, 0},
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
int takeServicesProvidedByEmbedder() native "takeServicesProvidedByEmbedder";
)DART";

}  // namespace

void Internals::Create(Dart_Isolate isolate,
                       mojo::ServiceProviderPtr service_provider) {
  DartState* state = DartState::From(isolate);
  state->SetUserData(&kInternalsKey, new Internals(service_provider.Pass()));
  Dart_Handle library =
      Dart_LoadLibrary(Dart_NewStringFromCString(kLibraryName),
                       Dart_NewStringFromCString(kLibrarySource), 0, 0);
  CHECK(!LogIfError(library));
  CHECK(!LogIfError(Dart_FinalizeLoading(true)));
  CHECK(!LogIfError(Dart_SetNativeResolver(library, Resolver, Symbolizer)));
}

Internals::Internals(mojo::ServiceProviderPtr service_provider)
  : service_provider_(service_provider.Pass()) {
}

Internals::~Internals() {
}

mojo::Handle Internals::TakeServicesProvidedByEmbedder() {
  return service_provider_.PassMessagePipe().release();
}

}  // namespace shell
}  // namespace sky
