// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_exception_factory.h"

#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

DartExceptionFactory::DartExceptionFactory(DartState* dart_state)
    : dart_state_(dart_state) {
}

DartExceptionFactory::~DartExceptionFactory() {
}

Dart_Handle DartExceptionFactory::CreateNullArgumentException(int index) {
  StringBuilder message;
  message.appendLiteral("Argument ");
  message.appendNumber(index);
  message.appendLiteral(" cannot be null.");
  return CreateException("ArgumentError", message.toString());
}

Dart_Handle DartExceptionFactory::CreateException(const String& class_name,
                                                  const String& message) {
  if (core_library_.is_empty()) {
    Dart_Handle library = DartBuiltin::LookupLibrary("dart:core");
    core_library_.Set(dart_state_, library);
  }

  Dart_Handle exception_class = Dart_GetType(
      core_library_.value(), StringToDart(dart_state_, class_name), 0, 0);
  Dart_Handle message_handle = StringToDart(dart_state_, message);
  return Dart_New(exception_class, Dart_EmptyString(), 1, &message_handle);
}

}  // namespace blink
