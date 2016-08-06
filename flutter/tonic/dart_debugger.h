// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_DEBUGGER_H_
#define FLUTTER_TONIC_DART_DEBUGGER_H_

#include <memory>
#include <vector>

#include "dart/runtime/include/dart_api.h"
#include "dart/runtime/include/dart_native_api.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "lib/ftl/synchronization/monitor.h"
#include "lib/ftl/synchronization/mutex.h"

namespace blink {

class DartDebuggerIsolate {
 public:
  DartDebuggerIsolate(Dart_IsolateId id) : id_(id) {}

  Dart_IsolateId id() const { return id_; }

  void Notify() { monitor_.Signal(); }

  void MessageLoop();

 private:
  const Dart_IsolateId id_;
  ftl::Monitor monitor_;
};

class DartDebugger {
 public:
  static void InitDebugger();

 private:
  static void BptResolvedHandler(Dart_IsolateId isolate_id,
                                 intptr_t bp_id,
                                 const Dart_CodeLocation& location);

  static void PausedEventHandler(Dart_IsolateId isolate_id,
                                 intptr_t bp_id,
                                 const Dart_CodeLocation& loc);

  static void ExceptionThrownHandler(Dart_IsolateId isolate_id,
                                     Dart_Handle exception,
                                     Dart_StackTrace stack_trace);

  static void IsolateEventHandler(Dart_IsolateId isolate_id,
                                  Dart_IsolateEvent kind);

  static void NotifyIsolate(Dart_Isolate isolate);

  static intptr_t FindIsolateIndexById(Dart_IsolateId id);

  static intptr_t FindIsolateIndexByIdLocked(Dart_IsolateId id);

  static void AddIsolate(Dart_IsolateId id);

  static void RemoveIsolate(Dart_IsolateId id);

  static ftl::Mutex* mutex_;
  static std::vector<std::unique_ptr<DartDebuggerIsolate>>* isolates_;

  friend class DartDebuggerIsolate;
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_DEBUGGER_H_
