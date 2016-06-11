// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_EXCEPTION_STATE_H_
#define SKY_ENGINE_BINDINGS_EXCEPTION_STATE_H_

#include "flutter/tonic/dart_persistent_value.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

typedef int ExceptionCode;

class ExceptionState {
  WTF_MAKE_NONCOPYABLE(ExceptionState);

 public:
  enum Context {
    ConstructionContext,
    ExecutionContext,
    DeletionContext,
    GetterContext,
    SetterContext,
    EnumerationContext,
    QueryContext,
    IndexedGetterContext,
    IndexedSetterContext,
    IndexedDeletionContext,
    UnknownContext,  // FIXME: Remove this once we've flipped over to the new
                     // API.
  };

  ExceptionState();
  ExceptionState(Context context, const char* interfaceName);
  ExceptionState(Context context,
                 const char* propertyName,
                 const char* interfaceName);
  ~ExceptionState();

  void ThrowDOMException(const ExceptionCode& code, const String& message);
  void ThrowTypeError(const String& message);
  void ThrowRangeError(const String& message);

  bool ThrowIfNeeded();
  void ClearException();

  ExceptionCode code() const { return code_; }
  const String& message() const { return message_; }
  bool had_exception() const { return had_exception_ || code_; }

  Dart_Handle GetDartException(Dart_NativeArguments args, bool auto_scope);

 private:
  ExceptionCode code_;
  String message_;
  bool had_exception_;
  DartPersistentValue exception_;
};

class NonThrowableExceptionState final : public ExceptionState {};

class TrackExceptionState final : public ExceptionState {};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_EXCEPTION_STATE_H_
