// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/rand_util.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/mojo_natives.h"

#if defined(OS_ANDROID)
#include <android/log.h>
#endif

namespace mojo {
namespace dart {

// Lists the native functions implementing basic functionality in
// the Mojo embedder dart, such as printing, and file I/O.
#define BUILTIN_NATIVE_LIST(V)                                                 \
  V(Crypto_GetRandomBytes, 1)                                                  \
  V(Logger_PrintString, 1)                                                     \

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name;
  Dart_NativeFunction function;
  int argument_count;
} BuiltinEntries[] = {BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)};

Dart_NativeFunction Builtin::NativeLookup(Dart_Handle name,
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

const uint8_t* Builtin::NativeSymbol(Dart_NativeFunction nf) {
  size_t num_entries = arraysize(BuiltinEntries);
  for (size_t i = 0; i < num_entries; i++) {
    const struct NativeEntries& entry = BuiltinEntries[i];
    if (entry.function == nf) {
      return reinterpret_cast<const uint8_t*>(entry.name);
    }
  }
  return nullptr;
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
    // TODO(dart): Hook up to developer console (if/when that's a thing).
    // Uses fwrite to support printing NUL bytes.
    fwrite(chars, 1, length, stdout);
    fputs("\n", stdout);
#if defined(OS_ANDROID)
    // In addition to writing to the stdout, write to the logcat so that the
    // message is discoverable when running on an unrooted device. Use the
    // "chromium" tag to match native printouts produced by base LOG macros, so
    // that the same rule will pick them up in scripts that stream relevant
    // logcat output to host terminal.
    __android_log_print(ANDROID_LOG_INFO, "chromium", "%.*s", length, chars);
#endif
  }
  fflush(stdout);
}

static bool GetInt64Value(Dart_Handle value_obj, int64_t* value) {
  bool valid = Dart_IsInteger(value_obj);
  if (valid) {
    Dart_Handle result = Dart_IntegerFitsIntoInt64(value_obj, &valid);
    if (Dart_IsError(result))
      Dart_PropagateError(result);
  }
  if (!valid)
    return false;
  Dart_Handle result = Dart_IntegerToInt64(value_obj, value);
  if (Dart_IsError(result))
    Dart_PropagateError(result);
  return true;
}

void Crypto_GetRandomBytes(Dart_NativeArguments args) {
  Dart_Handle count_obj = Dart_GetNativeArgument(args, 0);
  const int64_t kMaxRandomBytes = 4096;
  int64_t count64 = 0;
  if (!GetInt64Value(count_obj, &count64) || (count64 < 0) ||
      (count64 > kMaxRandomBytes)) {
    Dart_Handle error = Dart_NewStringFromCString(
        "Invalid argument: count must be a positive int "
        "less than or equal to 4096.");
    Dart_ThrowException(error);
  }
  intptr_t count = static_cast<intptr_t>(count64);
  scoped_ptr<uint8_t[]> buffer(new uint8_t[count]);

  base::RandBytes(reinterpret_cast<void*>(buffer.get()), count);

  Dart_Handle result = Dart_NewTypedData(Dart_TypedData_kUint8, count);
  if (Dart_IsError(result)) {
    Dart_Handle error = Dart_NewStringFromCString(
        "Failed to allocate storage.");
    Dart_ThrowException(error);
  }
  Dart_ListSetAsBytes(result, 0, buffer.get(), count);
  Dart_SetReturnValue(args, result);
}

}  // namespace bin
}  // namespace dart
