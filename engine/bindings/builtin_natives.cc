// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings/builtin_natives.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "base/bind.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/time/time.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/bindings/builtin.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_timer_heap.h"
#include "sky/engine/tonic/dart_value.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

#define REGISTER_FUNCTION(name, count)                                         \
  { "" #name, name, count },
#define DECLARE_FUNCTION(name, count)                                          \
  extern void name(Dart_NativeArguments args);

// Lists the native functions implementing basic functionality in
// the Mojo embedder dart, such as printing, and file I/O.
#define BUILTIN_NATIVE_LIST(V) \
  V(Logger_PrintString, 1)     \
  V(ScheduleMicrotask, 1)      \
  V(GetBaseURLString, 0)       \
  V(Timer_create, 3)           \
  V(Timer_cancel, 1)

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name;
  Dart_NativeFunction function;
  int argument_count;
} BuiltinEntries[] = {BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)};

Dart_NativeFunction BuiltinNatives::NativeLookup(Dart_Handle name,
                                                 int argument_count,
                                                 bool* auto_setup_scope) {
  const char* function_name = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  DCHECK(function_name != nullptr);
  DCHECK(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  size_t num_entries = arraysize(BuiltinEntries);
  for (size_t i = 0; i < num_entries; i++) {
    const struct NativeEntries& entry = BuiltinEntries[i];
    if (!strcmp(function_name, entry.name) &&
        (entry.argument_count == argument_count)) {
      return entry.function;
    }
  }
  return nullptr;
}

const uint8_t* BuiltinNatives::NativeSymbol(Dart_NativeFunction native_function) {
  size_t num_entries = arraysize(BuiltinEntries);
  for (size_t i = 0; i < num_entries; i++) {
    const struct NativeEntries& entry = BuiltinEntries[i];
    if (entry.function == native_function) {
      return reinterpret_cast<const uint8_t*>(entry.name);
    }
  }
  return nullptr;
}

static Dart_Handle GetClosure(Dart_Handle builtin_library, const char* name) {
  Dart_Handle getter_name = ToDart(name);
  Dart_Handle closure = Dart_Invoke(builtin_library, getter_name, 0, nullptr);
  DART_CHECK_VALID(closure);
  return closure;
}

static void InitDartInternal(Dart_Handle builtin_library,
                             BuiltinNatives::IsolateType isolate_type) {
  Dart_Handle print = GetClosure(builtin_library, "_getPrintClosure");
  Dart_Handle timer = GetClosure(builtin_library, "_getCreateTimerClosure");

  Dart_Handle internal_library = DartBuiltin::LookupLibrary("dart:_internal");

  DART_CHECK_VALID(Dart_SetField(
      internal_library, ToDart("_printClosure"), print));

  if (isolate_type == BuiltinNatives::MainIsolate) {
    Dart_Handle vm_hooks_name = ToDart("VMLibraryHooks");
    Dart_Handle vm_hooks = Dart_GetClass(internal_library, vm_hooks_name);
    DART_CHECK_VALID(vm_hooks);
    Dart_Handle timer_name = ToDart("timerFactory");
    DART_CHECK_VALID(Dart_SetField(vm_hooks, timer_name, timer));
  } else {
    CHECK(isolate_type == BuiltinNatives::DartIOIsolate);
    Dart_Handle io_lib = DartBuiltin::LookupLibrary("dart:io");
    Dart_Handle setup_hooks = Dart_NewStringFromCString("_setupHooks");
    DART_CHECK_VALID(Dart_Invoke(io_lib, setup_hooks, 0, NULL));
    Dart_Handle isolate_lib = DartBuiltin::LookupLibrary("dart:isolate");
    DART_CHECK_VALID(Dart_Invoke(isolate_lib, setup_hooks, 0, NULL));
  }
}

static void InitDartCore(Dart_Handle builtin,
                         BuiltinNatives::IsolateType isolate_type) {
  Dart_Handle get_base_url = GetClosure(builtin, "_getGetBaseURLClosure");
  Dart_Handle core_library = DartBuiltin::LookupLibrary("dart:core");
  DART_CHECK_VALID(Dart_SetField(core_library,
      ToDart("_uriBaseClosure"), get_base_url));
}

static void InitDartAsync(Dart_Handle builtin_library,
                          BuiltinNatives::IsolateType isolate_type) {
  Dart_Handle schedule_microtask;
  if (isolate_type == BuiltinNatives::MainIsolate) {
    schedule_microtask =
        GetClosure(builtin_library, "_getScheduleMicrotaskClosure");
  } else {
    CHECK(isolate_type == BuiltinNatives::DartIOIsolate);
    Dart_Handle isolate_lib = DartBuiltin::LookupLibrary("dart:isolate");
    Dart_Handle method_name =
        Dart_NewStringFromCString("_getIsolateScheduleImmediateClosure");
    schedule_microtask = Dart_Invoke(isolate_lib, method_name, 0, NULL);
  }
  Dart_Handle async_library = DartBuiltin::LookupLibrary("dart:async");
  Dart_Handle set_schedule_microtask = ToDart("_setScheduleImmediateClosure");
  DART_CHECK_VALID(Dart_Invoke(async_library, set_schedule_microtask, 1,
                               &schedule_microtask));
}

void BuiltinNatives::Init(IsolateType isolate_type) {
  Dart_Handle builtin = Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin);
  InitDartInternal(builtin, isolate_type);
  InitDartCore(builtin, isolate_type);
  InitDartAsync(builtin, isolate_type);
}

// Implementation of native functions which are used for some
// test/debug functionality in standalone dart mode.
void Logger_PrintString(Dart_NativeArguments args) {
  intptr_t length = 0;
  uint8_t* chars = nullptr;
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  Dart_Handle result = Dart_StringToUTF8(str, &chars, &length);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  } else {

  String message(chars, length);
  // TODO(dart): Hook up to developer console (if/when that's a thing).
#if OS(ANDROID)
    LOG(INFO) << "CONSOLE: " << message.utf8().data();
#else
    printf("CONSOLE: %s\n", message.utf8().data());
    fflush(stdout);
#endif
  }
}

static void ExecuteMicrotask(base::WeakPtr<DartState> dart_state,
                             RefPtr<DartValue> callback) {
  if (!dart_state)
    return;
  DartIsolateScope scope(dart_state->isolate());
  DartApiScope api_scope;
  DartInvokeAppClosure(callback->dart_value(), 0, nullptr);
}

void ScheduleMicrotask(Dart_NativeArguments args) {
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  if (LogIfError(closure) || !Dart_IsClosure(closure))
    return;
  DartState* dart_state = DartState::Current();
  CHECK(dart_state);
  Microtask::enqueueMicrotask(base::Bind(&ExecuteMicrotask,
    dart_state->GetWeakPtr(), DartValue::Create(dart_state, closure)));
}

void GetBaseURLString(Dart_NativeArguments args) {
  String url = DOMDartState::Current()->url();
  Dart_SetReturnValue(args, StringToDart(DartState::Current(), url));
}

void Timer_create(Dart_NativeArguments args) {
  int64_t milliseconds = 0;
  DART_CHECK_VALID(Dart_GetNativeIntegerArgument(args, 0, &milliseconds));
  Dart_Handle closure = Dart_GetNativeArgument(args, 1);
  DART_CHECK_VALID(closure);
  CHECK(Dart_IsClosure(closure));
  bool repeating = false;
  DART_CHECK_VALID(Dart_GetNativeBooleanArgument(args, 2, &repeating));

  DartState* state = DartState::Current();
  CHECK(state);

  OwnPtr<DartTimerHeap::Task> task = adoptPtr(new DartTimerHeap::Task);
  task->closure.Set(state, closure);
  task->delay = base::TimeDelta::FromMilliseconds(milliseconds);
  task->repeating = repeating;

  int timer_id = state->timer_heap().Add(task.release());
  Dart_SetIntegerReturnValue(args, timer_id);
}

void Timer_cancel(Dart_NativeArguments args) {
  int64_t timer_id = 0;
  DART_CHECK_VALID(Dart_GetNativeIntegerArgument(args, 0, &timer_id));

  DartState* state = DartState::Current();
  CHECK(state);
  state->timer_heap().Remove(timer_id);
}

}  // namespace blink
