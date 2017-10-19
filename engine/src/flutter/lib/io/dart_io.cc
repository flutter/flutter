// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/io/dart_io.h"

#include "lib/tonic/converter/dart_converter.h"
#include "third_party/dart/runtime/bin/crypto.h"
#include "third_party/dart/runtime/bin/io_natives.h"
#include "third_party/dart/runtime/include/dart_api.h"

using tonic::ToDart;

namespace blink {

void DartIO::InitForIsolate() {
  DART_CHECK_VALID(Dart_SetNativeResolver(Dart_LookupLibrary(ToDart("dart:io")),
                                          dart::bin::IONativeLookup,
                                          dart::bin::IONativeSymbol));
}

bool DartIO::EntropySource(uint8_t* buffer, intptr_t length) {
  return dart::bin::Crypto::GetRandomBytes(length, buffer);
}

}  // namespace blink
