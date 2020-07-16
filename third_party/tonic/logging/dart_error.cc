// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tonic/logging/dart_error.h"
#include "tonic/converter/dart_converter.h"

#include "tonic/common/macros.h"

namespace tonic {
namespace DartError {
const char kInvalidArgument[] = "Invalid argument.";
}  // namespace DartError

bool LogIfError(Dart_Handle handle) {
  if (Dart_IsUnhandledExceptionError(handle)) {
    Dart_Handle stack_trace_handle = Dart_ErrorGetStackTrace(handle);
    const std::string stack_trace =
        tonic::StdStringFromDart(Dart_ToString(stack_trace_handle));
    tonic::Log("Dart Unhandled Exception: %s", stack_trace.c_str());
    return true;
  } else if (Dart_IsError(handle)) {
    tonic::Log("Dart Error: %s", Dart_GetError(handle));
    return true;
  } else {
    return false;
  }
}

DartErrorHandleType GetErrorHandleType(Dart_Handle handle) {
  if (Dart_IsCompilationError(handle)) {
    return kCompilationErrorType;
  } else if (Dart_IsApiError(handle)) {
    return kApiErrorType;
  } else if (Dart_IsError(handle)) {
    return kUnknownErrorType;
  } else {
    return kNoError;
  }
}

int GetErrorExitCode(Dart_Handle handle) {
  if (Dart_IsCompilationError(handle)) {
    return 254;  // dart::bin::kCompilationErrorExitCode
  } else if (Dart_IsApiError(handle)) {
    return 253;  // dart::bin::kApiErrorExitCode
  } else if (Dart_IsError(handle)) {
    return 255;  // dart::bin::kErrorExitCode
  } else {
    return 0;
  }
}

}  // namespace tonic
