// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_invoke.h"

#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {

bool DartInvokeField(Dart_Handle target,
                     const char* name,
                     std::initializer_list<Dart_Handle> args) {
  TRACE_EVENT1("sky", "DartInvokeField", "name", name);
  Dart_Handle field = Dart_NewStringFromCString(name);
  return LogIfError(Dart_Invoke(
      target, field, args.size(), const_cast<Dart_Handle*>(args.begin())));
}

bool DartInvokeAppClosure(Dart_Handle closure,
                          int number_of_arguments,
                          Dart_Handle* arguments) {
  TRACE_EVENT0("sky", "DartInvoke::DartInvokeAppClosure");
  Dart_Handle handle = Dart_InvokeClosure(closure, number_of_arguments, arguments);
  bool result = LogIfError(handle);
  CHECK(!Dart_IsCompilationError(handle));
  return result;
}

}  // namespace blink
