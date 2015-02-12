// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings2/builtin_natives.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "base/bind.h"
#include "base/logging.h"
#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/bindings2/builtin.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_state.h"
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

static void InitDartInternal(Dart_Handle builtin_library) {
  Dart_Handle print = GetClosure(builtin_library, "_getPrintClosure");
  Dart_Handle timer = GetClosure(builtin_library, "_getCreateTimerClosure");

  Dart_Handle internal_library = DartBuiltin::LookupLibrary("dart:_internal");

  DART_CHECK_VALID(Dart_SetField(
      internal_library, ToDart("_printClosure"), print));

  Dart_Handle vm_hooks_name = ToDart("VMLibraryHooks");
  Dart_Handle vm_hooks = Dart_GetClass(internal_library, vm_hooks_name);
  DART_CHECK_VALID(vm_hooks);
  Dart_Handle timer_name = ToDart("timerFactory");
  DART_CHECK_VALID(Dart_SetField(vm_hooks, timer_name, timer));
}

static void InitAsync(Dart_Handle builtin_library) {
  Dart_Handle schedule_microtask =
      GetClosure(builtin_library, "_getScheduleMicrotaskClosure");
  Dart_Handle async_library = DartBuiltin::LookupLibrary("dart:async");
  Dart_Handle set_schedule_microtask = ToDart("_setScheduleImmediateClosure");
  DART_CHECK_VALID(Dart_Invoke(async_library, set_schedule_microtask, 1,
                               &schedule_microtask));
}

void BuiltinNatives::Init() {
  Dart_Handle builtin = Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin);
  InitDartInternal(builtin);
  InitAsync(builtin);
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
  LogIfError(Dart_InvokeClosure(callback->dart_value(), 0, nullptr));
}

void ScheduleMicrotask(Dart_NativeArguments args) {
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  if (LogIfError(closure) || !Dart_IsClosure(closure))
    return;
  DartState* dart_state = DartState::Current();
  Microtask::enqueueMicrotask(base::Bind(&ExecuteMicrotask,
    dart_state->GetWeakPtr(), DartValue::Create(dart_state, closure)));
}

void Timer_create(Dart_NativeArguments args) {
  int64_t milliseconds = 0;
  DART_CHECK_VALID(Dart_GetNativeIntegerArgument(args, 0, &milliseconds));
  Dart_Handle closure = Dart_GetNativeArgument(args, 1);
  DART_CHECK_VALID(closure);
  CHECK(Dart_IsClosure(closure));
  bool repeating = false;
  DART_CHECK_VALID(Dart_GetNativeBooleanArgument(args, 2, &repeating));

  DOMDartState* state = DOMDartState::Current();
  int timer_id = DOMTimer::install(state->document(),
                                   ScheduledAction::Create(state, closure),
                                   milliseconds,
                                   !repeating);
  Dart_SetIntegerReturnValue(args, timer_id);
}

void Timer_cancel(Dart_NativeArguments args) {
  int64_t timer_id = 0;
  DART_CHECK_VALID(Dart_GetNativeIntegerArgument(args, 0, &timer_id));

  DOMDartState* state = DOMDartState::Current();
  DOMTimer::removeByID(state->document(), timer_id);
}

}  // namespace blink
