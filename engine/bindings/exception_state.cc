// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings/exception_state.h"

namespace blink {

ExceptionState::ExceptionState() : code_(0), had_exception_(false) {
}

ExceptionState::ExceptionState(Context context,
                               const char* propertyName,
                               const char* interfaceName) {
}

ExceptionState::ExceptionState(Context context, const char* interfaceName) {
}

ExceptionState::~ExceptionState() {
}

void ExceptionState::ThrowDOMException(const ExceptionCode&,
                                       const String& message) {
}

void ExceptionState::ThrowTypeError(const String& message) {
}

void ExceptionState::ThrowRangeError(const String& message) {
}

bool ExceptionState::ThrowIfNeeded() {
  return had_exception_;
}

void ExceptionState::ClearException() {
}

Dart_Handle ExceptionState::GetDartException(Dart_NativeArguments args,
                                             bool auto_scope) {
  // TODO(abarth): Still don't understand autoscope.
  DCHECK(auto_scope);
  return exception_.Release();
}

}  // namespace blink
