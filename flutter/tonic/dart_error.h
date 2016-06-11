// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_ERROR_H_
#define FLUTTER_TONIC_DART_ERROR_H_

#include "dart/runtime/include/dart_api.h"

namespace blink {

namespace DartError {
extern const char kInvalidArgument[];
extern const char kInvalidDartWrappable[];
}  // namespace DartError

bool LogIfError(Dart_Handle handle);

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_ERROR_H_

