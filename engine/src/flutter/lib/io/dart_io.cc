// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/io/dart_io.h"

#include "flutter/fml/logging.h"

#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/logging/dart_error.h"

using tonic::LogIfError;
using tonic::ToDart;

namespace flutter {

void DartIO::InitForIsolate(bool disable_http) {
  Dart_Handle result = Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:io")), dart::bin::LookupIONative,
      dart::bin::LookupIONativeSymbol);
  FML_CHECK(!LogIfError(result));

  // The SDK expects this field to represent "allow http" so we switch the
  // value.
  Dart_Handle allow_http_value = disable_http ? Dart_False() : Dart_True();
  Dart_Handle set_field_result =
      Dart_SetField(Dart_LookupLibrary(ToDart("dart:_http")),
                    ToDart("_embedderAllowsHttp"), allow_http_value);
  FML_CHECK(!LogIfError(set_field_result));
}

}  // namespace flutter
