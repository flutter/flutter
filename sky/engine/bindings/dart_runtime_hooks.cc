// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_runtime_hooks.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dart/runtime/bin/embedded_dart_io.h"
#include "dart/runtime/include/dart_api.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/tonic/dart_api_scope.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/dart_invoke.h"
#include "flutter/tonic/dart_isolate_scope.h"
#include "flutter/tonic/dart_library_natives.h"
#include "flutter/tonic/dart_microtask_queue.h"
#include "flutter/tonic/dart_state.h"
#include "lib/ftl/logging.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/wtf/text/WTFString.h"

#if defined(OS_ANDROID)
#include <android/log.h>
#endif

#if __APPLE__
extern "C" {
// Cannot import the syslog.h header directly because of macro collision
extern void syslog(int, const char *, ...);
}
#endif

namespace blink {

#define REGISTER_FUNCTION(name, count)                                         \
  { "" #name, name, count, true },
#define DECLARE_FUNCTION(name, count)                                          \
  extern void name(Dart_NativeArguments args);

// Lists the native functions implementing basic functionality in
// the Mojo embedder dart, such as printing, and file I/O.
#define BUILTIN_NATIVE_LIST(V) \
  V(Logger_PrintString, 1)     \
  V(ScheduleMicrotask, 1)      \
  V(GetBaseURLString, 0)

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

void DartRuntimeHooks::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)
  });
}

static Dart_Handle GetClosure(Dart_Handle builtin_library, const char* name) {
  Dart_Handle getter_name = ToDart(name);
  Dart_Handle closure = Dart_Invoke(builtin_library, getter_name, 0, nullptr);
  DART_CHECK_VALID(closure);
  return closure;
}

static void InitDartInternal(Dart_Handle builtin_library,
                             DartRuntimeHooks::IsolateType isolate_type) {
  Dart_Handle print = GetClosure(builtin_library, "_getPrintClosure");

  Dart_Handle internal_library = Dart_LookupLibrary(ToDart("dart:_internal"));

  DART_CHECK_VALID(Dart_SetField(
      internal_library, ToDart("_printClosure"), print));

  if (isolate_type == DartRuntimeHooks::MainIsolate) {
    // Call |_setupHooks| to configure |VMLibraryHooks|.
    Dart_Handle method_name =
        Dart_NewStringFromCString("_setupHooks");
    DART_CHECK_VALID(Dart_Invoke(builtin_library, method_name, 0, NULL))

    // Call |_setupHooks| to configure |VMLibraryHooks|.
    Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
    DART_CHECK_VALID(isolate_lib);
    DART_CHECK_VALID(Dart_Invoke(isolate_lib, method_name, 0, NULL));
  } else {
    FTL_CHECK(isolate_type == DartRuntimeHooks::SecondaryIsolate);
    Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
    DART_CHECK_VALID(io_lib);
    Dart_Handle setup_hooks = Dart_NewStringFromCString("_setupHooks");
    DART_CHECK_VALID(Dart_Invoke(io_lib, setup_hooks, 0, NULL));
    Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
    DART_CHECK_VALID(isolate_lib);
    DART_CHECK_VALID(Dart_Invoke(isolate_lib, setup_hooks, 0, NULL));
  }
}

static void InitDartCore(Dart_Handle builtin) {
  Dart_Handle get_base_url = GetClosure(builtin, "_getGetBaseURLClosure");
  Dart_Handle core_library = Dart_LookupLibrary(ToDart("dart:core"));
  DART_CHECK_VALID(Dart_SetField(core_library,
      ToDart("_uriBaseClosure"), get_base_url));
}

static void InitDartAsync(Dart_Handle builtin_library,
                          DartRuntimeHooks::IsolateType isolate_type) {
  Dart_Handle schedule_microtask;
  if (isolate_type == DartRuntimeHooks::MainIsolate) {
    schedule_microtask =
        GetClosure(builtin_library, "_getScheduleMicrotaskClosure");
  } else {
    FTL_CHECK(isolate_type == DartRuntimeHooks::SecondaryIsolate);
    Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
    Dart_Handle method_name =
        Dart_NewStringFromCString("_getIsolateScheduleImmediateClosure");
    schedule_microtask = Dart_Invoke(isolate_lib, method_name, 0, NULL);
  }
  Dart_Handle async_library = Dart_LookupLibrary(ToDart("dart:async"));
  Dart_Handle set_schedule_microtask = ToDart("_setScheduleImmediateClosure");
  DART_CHECK_VALID(Dart_Invoke(async_library, set_schedule_microtask, 1,
                               &schedule_microtask));
}

static void InitDartIo(const std::string& script_uri) {
  if (!script_uri.empty()) {
    Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
    DART_CHECK_VALID(io_lib);
    Dart_Handle platform_type = Dart_GetType(io_lib, ToDart("_Platform"),
                                             0, nullptr);
    DART_CHECK_VALID(platform_type);
    DART_CHECK_VALID(Dart_SetField(
        platform_type, ToDart("_nativeScript"), ToDart(script_uri)));
  }
}

void DartRuntimeHooks::Install(IsolateType isolate_type, const std::string& script_uri) {
  Dart_Handle builtin = Dart_LookupLibrary(ToDart("dart:ui"));
  DART_CHECK_VALID(builtin);
  InitDartInternal(builtin, isolate_type);
  InitDartCore(builtin);
  InitDartAsync(builtin, isolate_type);
  InitDartIo(script_uri);
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
    // Uses fwrite to support printing NUL bytes.
    fwrite(chars, 1, length, stdout);
    fputs("\n", stdout);
    fflush(stdout);
#if defined(OS_ANDROID)
    // In addition to writing to the stdout, write to the logcat so that the
    // message is discoverable when running on an unrooted device.
    __android_log_print(ANDROID_LOG_INFO, "flutter", "%.*s", (int)length, chars);
#elif __APPLE__
    syslog(1 /* LOG_ALERT */, "%.*s", (int)length, chars);
#endif
  }
  if (dart::bin::ShouldCaptureStdout()) {
    // For now we report print output on the Stdout stream.
    uint8_t newline[] = { '\n' };
    Dart_ServiceSendDataEvent("Stdout", "WriteEvent", chars, length);
    Dart_ServiceSendDataEvent("Stdout", "WriteEvent",
                              newline, sizeof(newline));
  }
}

void ScheduleMicrotask(Dart_NativeArguments args) {
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  if (LogIfError(closure) || !Dart_IsClosure(closure))
    return;
  DartMicrotaskQueue::ScheduleMicrotask(closure);
}

void GetBaseURLString(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, ToDart(UIDartState::Current()->url()));
}

}  // namespace blink
