// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/io/dart_io.h"

#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"

using tonic::ToDart;

namespace blink {

void DartIO::InitForIsolate() {
  Dart_Handle result = Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:io")), dart::bin::LookupIONative,
      dart::bin::LookupIONativeSymbol);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

bool DartIO::EntropySource(uint8_t* buffer, intptr_t length) {
  return dart::bin::GetEntropy(buffer, length);
}

}  // namespace blink
