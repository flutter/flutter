// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_mojo_internal.h"

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/bindings/mojo_natives.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

void DartMojoInternal::InitForIsolate() {
  DART_CHECK_VALID(Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:mojo.internal")),
      MojoNativeLookup,
      MojoNativeSymbol));
}

}  // namespace blink
