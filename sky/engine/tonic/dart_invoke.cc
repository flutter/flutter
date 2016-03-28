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
  TRACE_EVENT1("flutter", "DartInvokeField", "name", name);
  Dart_Handle field = Dart_NewStringFromCString(name);
  return LogIfError(Dart_Invoke(
      target, field, args.size(), const_cast<Dart_Handle*>(args.begin())));
}

void DartInvoke(Dart_Handle closure, std::initializer_list<Dart_Handle> args) {
  TRACE_EVENT0("flutter", "DartInvoke");
  int argc = args.size();
  Dart_Handle* argv = const_cast<Dart_Handle*>(args.begin());
  Dart_Handle handle = Dart_InvokeClosure(closure, argc, argv);
  LogIfError(handle);
}

void DartInvokeVoid(Dart_Handle closure) {
  TRACE_EVENT0("flutter", "DartInvokeVoid");
  Dart_Handle handle = Dart_InvokeClosure(closure, 0, nullptr);
  LogIfError(handle);
}

}  // namespace blink
