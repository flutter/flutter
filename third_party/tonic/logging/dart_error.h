// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_TONIC_LOGGING_DART_ERROR_H_
#define LIB_TONIC_LOGGING_DART_ERROR_H_

#include "third_party/dart/runtime/include/dart_api.h"

namespace tonic {

namespace DartError {
extern const char kInvalidArgument[];
}  // namespace DartError

bool LogIfError(Dart_Handle handle);

enum DartErrorHandleType {
  kNoError,
  kUnknownErrorType,
  kApiErrorType,
  kCompilationErrorType,
};

DartErrorHandleType GetErrorHandleType(Dart_Handle handle);

int GetErrorExitCode(Dart_Handle handle);

}  // namespace tonic

#endif  // LIB_TONIC_DART_ERROR_H_
