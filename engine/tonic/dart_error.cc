// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/tonic/dart_error.h"

#include "base/logging.h"

namespace blink {

namespace DartError {

const char kInvalidArgument[] = "Invalid argument.";

}  // namespace DartError

bool LogIfError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    LOG(ERROR) << Dart_GetError(handle);

    // Only unhandled exceptions have stacktraces.
    if (!Dart_ErrorHasException(handle))
      return true;

    Dart_Handle stacktrace = Dart_ErrorGetStacktrace(handle);
    const char* stacktrace_cstr = "";
    Dart_StringToCString(Dart_ToString(stacktrace), &stacktrace_cstr);
    LOG(ERROR) << stacktrace_cstr;
    return true;
  }
  return false;
}

}  // namespace blink
