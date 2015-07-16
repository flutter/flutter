// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_invoke.h"

#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {

bool DartInvokeAppField(Dart_Handle target, Dart_Handle name,
                               int number_of_arguments,
                               Dart_Handle* arguments) {
  TRACE_EVENT0("sky", "DartInvoke::DartInvokeAppField");
  return LogIfError(Dart_Invoke(target, name, number_of_arguments, arguments));
}

bool DartInvokeAppClosure(Dart_Handle closure,
                          int number_of_arguments,
                          Dart_Handle* arguments) {
  TRACE_EVENT0("sky", "DartInvoke::DartInvokeAppClosure");
  return LogIfError(
      Dart_InvokeClosure(closure, number_of_arguments, arguments));
}

}  // namespace blink
