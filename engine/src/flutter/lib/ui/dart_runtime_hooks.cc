// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/dart_runtime_hooks.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <sstream>

#include "flutter/common/settings.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/runtime/dart_plugin_registrant.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_error.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/scopes/dart_api_scope.h"
#include "third_party/tonic/scopes/dart_isolate_scope.h"

using tonic::DartConverter;
using tonic::ToDart;

namespace flutter {

#define REGISTER_FUNCTION(name, count) {"" #name, name, count, true},
#define DECLARE_FUNCTION(name, count) \
  extern void name(Dart_NativeArguments args);

#define BUILTIN_NATIVE_LIST(V)                 \
  V(Logger_PrintString, 1)                     \
  V(Logger_PrintDebugString, 1)                \
  V(DartPluginRegistrant_EnsureInitialized, 0) \
  V(ScheduleMicrotask, 1)                      \
  V(GetCallbackHandle, 1)                      \
  V(GetCallbackFromHandle, 1)

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

void DartRuntimeHooks::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)});
}

static void PropagateIfError(Dart_Handle result) {
  if (Dart_IsError(result)) {
    FML_LOG(ERROR) << "Dart Error: " << ::Dart_GetError(result);
    Dart_PropagateError(result);
  }
}

static Dart_Handle InvokeFunction(Dart_Handle builtin_library,
                                  const char* name) {
  Dart_Handle getter_name = ToDart(name);
  return Dart_Invoke(builtin_library, getter_name, 0, nullptr);
}

static void InitDartInternal(Dart_Handle builtin_library, bool is_ui_isolate) {
  Dart_Handle print = InvokeFunction(builtin_library, "_getPrintClosure");

  Dart_Handle internal_library = Dart_LookupLibrary(ToDart("dart:_internal"));

  Dart_Handle result =
      Dart_SetField(internal_library, ToDart("_printClosure"), print);
  PropagateIfError(result);

  if (is_ui_isolate) {
    // Call |_setupHooks| to configure |VMLibraryHooks|.
    Dart_Handle method_name = Dart_NewStringFromCString("_setupHooks");
    result = Dart_Invoke(builtin_library, method_name, 0, NULL);
    PropagateIfError(result);
  }

  Dart_Handle setup_hooks = Dart_NewStringFromCString("_setupHooks");

  Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
  result = Dart_Invoke(io_lib, setup_hooks, 0, NULL);
  PropagateIfError(result);

  Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
  result = Dart_Invoke(isolate_lib, setup_hooks, 0, NULL);
  PropagateIfError(result);
}

static void InitDartCore(Dart_Handle builtin, const std::string& script_uri) {
  Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
  Dart_Handle get_base_url =
      Dart_Invoke(io_lib, ToDart("_getUriBaseClosure"), 0, NULL);
  Dart_Handle core_library = Dart_LookupLibrary(ToDart("dart:core"));
  Dart_Handle result =
      Dart_SetField(core_library, ToDart("_uriBaseClosure"), get_base_url);
  PropagateIfError(result);
}

static void InitDartAsync(Dart_Handle builtin_library, bool is_ui_isolate) {
  Dart_Handle schedule_microtask;
  if (is_ui_isolate) {
    schedule_microtask =
        InvokeFunction(builtin_library, "_getScheduleMicrotaskClosure");
  } else {
    Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
    Dart_Handle method_name =
        Dart_NewStringFromCString("_getIsolateScheduleImmediateClosure");
    schedule_microtask = Dart_Invoke(isolate_lib, method_name, 0, NULL);
  }
  Dart_Handle async_library = Dart_LookupLibrary(ToDart("dart:async"));
  Dart_Handle set_schedule_microtask = ToDart("_setScheduleImmediateClosure");
  Dart_Handle result = Dart_Invoke(async_library, set_schedule_microtask, 1,
                                   &schedule_microtask);
  PropagateIfError(result);
}

static void InitDartIO(Dart_Handle builtin_library,
                       const std::string& script_uri) {
  Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
  Dart_Handle platform_type =
      Dart_GetNonNullableType(io_lib, ToDart("_Platform"), 0, nullptr);
  if (!script_uri.empty()) {
    Dart_Handle result = Dart_SetField(platform_type, ToDart("_nativeScript"),
                                       ToDart(script_uri));
    PropagateIfError(result);
  }
  // typedef _LocaleClosure = String Function();
  Dart_Handle /* _LocaleClosure? */ locale_closure =
      InvokeFunction(builtin_library, "_getLocaleClosure");
  PropagateIfError(locale_closure);
  //   static String Function()? _localeClosure;
  Dart_Handle result =
      Dart_SetField(platform_type, ToDart("_localeClosure"), locale_closure);
  PropagateIfError(result);

  // Register dart:io service extensions used for network profiling.
  Dart_Handle network_profiling_type =
      Dart_GetNonNullableType(io_lib, ToDart("_NetworkProfiling"), 0, nullptr);
  PropagateIfError(network_profiling_type);
  result = Dart_Invoke(network_profiling_type,
                       ToDart("_registerServiceExtension"), 0, nullptr);
  PropagateIfError(result);
}

void DartRuntimeHooks::Install(bool is_ui_isolate,
                               const std::string& script_uri) {
  Dart_Handle builtin = Dart_LookupLibrary(ToDart("dart:ui"));
  InitDartInternal(builtin, is_ui_isolate);
  InitDartCore(builtin, script_uri);
  InitDartAsync(builtin, is_ui_isolate);
  InitDartIO(builtin, script_uri);
}

void Logger_PrintDebugString(Dart_NativeArguments args) {
#ifndef NDEBUG
  Logger_PrintString(args);
#endif
}

// Implementation of native functions which are used for some
// test/debug functionality in standalone dart mode.
void Logger_PrintString(Dart_NativeArguments args) {
  // Obtain the log buffer from Dart code.
  std::string message;
  {
    Dart_Handle str = Dart_GetNativeArgument(args, 0);
    uint8_t* chars = nullptr;
    intptr_t length = 0;
    Dart_Handle result = Dart_StringToUTF8(str, &chars, &length);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
      return;
    }
    if (length > 0) {
      message = std::string{reinterpret_cast<const char*>(chars),
                            static_cast<size_t>(length)};
    }
  }

  const auto& tag = UIDartState::Current()->logger_prefix();
  UIDartState::Current()->LogMessage(tag, message);

  if (dart::bin::ShouldCaptureStdout()) {
    std::stringstream stream;
    if (!tag.empty()) {
      stream << tag << ": ";
    }
    stream << message;
    std::string log = stream.str();

    // For now we report print output on the Stdout stream.
    uint8_t newline[] = {'\n'};
    Dart_ServiceSendDataEvent("Stdout", "WriteEvent",
                              reinterpret_cast<const uint8_t*>(log.c_str()),
                              log.size());
    Dart_ServiceSendDataEvent("Stdout", "WriteEvent", newline, sizeof(newline));
  }
}

void ScheduleMicrotask(Dart_NativeArguments args) {
  Dart_Handle closure = Dart_GetNativeArgument(args, 0);
  UIDartState::Current()->ScheduleMicrotask(closure);
}

static std::string GetFunctionLibraryUrl(Dart_Handle closure) {
  if (Dart_IsClosure(closure)) {
    closure = Dart_ClosureFunction(closure);
    PropagateIfError(closure);
  }

  if (!Dart_IsFunction(closure)) {
    return "";
  }

  Dart_Handle url = Dart_Null();
  Dart_Handle owner = Dart_FunctionOwner(closure);
  if (Dart_IsInstance(owner)) {
    owner = Dart_ClassLibrary(owner);
  }
  if (Dart_IsLibrary(owner)) {
    url = Dart_LibraryUrl(owner);
    PropagateIfError(url);
  }
  return DartConverter<std::string>::FromDart(url);
}

static std::string GetFunctionClassName(Dart_Handle closure) {
  Dart_Handle result;

  if (Dart_IsClosure(closure)) {
    closure = Dart_ClosureFunction(closure);
    PropagateIfError(closure);
  }

  if (!Dart_IsFunction(closure)) {
    return "";
  }

  bool is_static = false;
  result = Dart_FunctionIsStatic(closure, &is_static);
  PropagateIfError(result);
  if (!is_static) {
    return "";
  }

  result = Dart_FunctionOwner(closure);
  PropagateIfError(result);

  if (Dart_IsLibrary(result) || !Dart_IsInstance(result)) {
    return "";
  }
  return DartConverter<std::string>::FromDart(Dart_ClassName(result));
}

static std::string GetFunctionName(Dart_Handle func) {
  if (Dart_IsClosure(func)) {
    func = Dart_ClosureFunction(func);
    PropagateIfError(func);
  }

  if (!Dart_IsFunction(func)) {
    return "";
  }

  bool is_static = false;
  Dart_Handle result = Dart_FunctionIsStatic(func, &is_static);
  PropagateIfError(result);
  if (!is_static) {
    return "";
  }

  result = Dart_FunctionName(func);
  PropagateIfError(result);

  return DartConverter<std::string>::FromDart(result);
}

void GetCallbackHandle(Dart_NativeArguments args) {
  Dart_Handle func = Dart_GetNativeArgument(args, 0);
  std::string name = GetFunctionName(func);
  std::string class_name = GetFunctionClassName(func);
  std::string library_path = GetFunctionLibraryUrl(func);

  // `name` is empty if `func` can't be used as a callback. This is the case
  // when `func` is not a function object or is not a static function. Anonymous
  // closures (e.g. `(int a, int b) => a + b;`) also cannot be used as
  // callbacks, so `func` must be a tear-off of a named static function.
  if (!Dart_IsTearOff(func) || name.empty()) {
    Dart_SetReturnValue(args, Dart_Null());
    return;
  }
  Dart_SetReturnValue(
      args, DartConverter<int64_t>::ToDart(DartCallbackCache::GetCallbackHandle(
                name, class_name, library_path)));
}

void GetCallbackFromHandle(Dart_NativeArguments args) {
  Dart_Handle h = Dart_GetNativeArgument(args, 0);
  int64_t handle = DartConverter<int64_t>::FromDart(h);
  Dart_SetReturnValue(args, DartCallbackCache::GetCallback(handle));
}

void DartPluginRegistrant_EnsureInitialized(Dart_NativeArguments args) {
  FindAndInvokeDartPluginRegistrant();
}

}  // namespace flutter
