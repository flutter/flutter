// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_io.h"

#include "dart/runtime/bin/io_natives.h"
#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"

namespace blink {

void DartIO::InitForIsolate() {
  DART_CHECK_VALID(Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:io")),
      dart::bin::IONativeLookup,
      dart::bin::IONativeSymbol));
}

}  // namespace blink
