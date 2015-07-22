// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

// TODO(iansf): Implement exceptions.
void ExceptionState::ThrowDOMException(const ExceptionCode&,
                                       const String& message) {
    had_exception_ = true;
}

void ExceptionState::ThrowTypeError(const String& message) {
    had_exception_ = true;
}

void ExceptionState::ThrowRangeError(const String& message) {
    had_exception_ = true;
}

bool ExceptionState::ThrowIfNeeded() {
  return had_exception_;
}

void ExceptionState::ClearException() {
    had_exception_ = false;
}

Dart_Handle ExceptionState::GetDartException(Dart_NativeArguments args,
                                             bool auto_scope) {
  // TODO(abarth): Still don't understand autoscope.
  DCHECK(auto_scope);
  // TODO(eseidel): This should be a real exception object!
  return Dart_NewStringFromCString("Exception support missing. See exception_state.cc");
}

}  // namespace blink
