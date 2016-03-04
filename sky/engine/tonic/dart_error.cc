// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_error.h"

#include "base/logging.h"

namespace blink {
namespace DartError {
const char kInvalidArgument[] = "Invalid argument.";
const char kInvalidDartWrappable[] = "Invalid Dart wrappable object.";
}  // namespace DartError

bool LogIfError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    LOG(ERROR) << Dart_GetError(handle);
    return true;
  }
  return false;
}

}  // namespace blink
