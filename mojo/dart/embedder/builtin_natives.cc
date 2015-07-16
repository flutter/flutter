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
#include "crypto/random.h"
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
  V(Builtin_ReadSync, 1)                                                       \
  V(Builtin_EnumerateFiles, 1)                                                 \
  V(Builtin_LoadScript, 4)                                                     \
  V(Builtin_AsyncLoadError, 3)                                                 \
  V(Builtin_DoneLoading, 0)

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

void Builtin_ReadSync(Dart_NativeArguments args) {
  intptr_t chars_length = 0;
  uint8_t* chars = nullptr;
  Dart_Handle file_uri = Dart_GetNativeArgument(args, 0);
  if (!Dart_IsString(file_uri)) {
    Dart_PropagateError(file_uri);
  }

  intptr_t file_uri_length = 0;
  Dart_Handle result = Dart_StringLength(file_uri, &file_uri_length);

  result = Dart_StringToUTF8(file_uri, &chars, &chars_length);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  chars[file_uri_length] = '\0';

  base::FilePath path(base::FilePath::FromUTF8Unsafe(
      std::string(reinterpret_cast<char*>(chars))));

  std::string source;
  if (ReadFileToString(path, &source)) {
    Dart_Handle data =
        Dart_NewTypedData(Dart_TypedData_kUint8, source.length());
    char* source_chars = const_cast<char*>(source.c_str());
    Dart_ListSetAsBytes(data, 0, reinterpret_cast<uint8_t*>(source_chars),
                        source.length());
    Dart_SetReturnValue(args, data);
    return;
  }
  LOG(ERROR) << "Failed to read path: " << chars;
  Dart_SetReturnValue(args, Dart_Null());
}

void Builtin_EnumerateFiles(Dart_NativeArguments args) {
  intptr_t chars_length = 0;
  uint8_t* chars = nullptr;
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  if (!Dart_IsString(path)) {
    Dart_PropagateError(path);
  }

  intptr_t path_length = 0;
  Dart_Handle result = Dart_StringLength(path, &path_length);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  result = Dart_StringToUTF8(path, &chars, &chars_length);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  chars[path_length] = '\0';
  base::FilePath dir_path(base::FilePath::FromUTF8Unsafe(
      std::string(reinterpret_cast<char*>(chars))));

  std::vector<std::string> entries;
  base::FileEnumerator enumerator(dir_path, false, base::FileEnumerator::FILES);
  while (true) {
    base::FilePath file_path = enumerator.Next();
    std::string file_path_string = file_path.AsUTF8Unsafe();
    if (file_path_string == "") {
      break;
    }
    entries.push_back(file_path_string);
  }

  Dart_Handle list = Dart_NewList(entries.size());
  for (uintptr_t i = 0; i < entries.size(); i++) {
    Dart_Handle entry = Dart_NewStringFromUTF8(
        reinterpret_cast<const uint8_t*>(entries[i].data()),
        entries[i].length());
    Dart_ListSetAt(list, i, entry);
  }
  Dart_SetReturnValue(args, list);
}

// Callback function, gets called from asynchronous script and library
// reading code when there is an i/o error.
void Builtin_AsyncLoadError(Dart_NativeArguments args) {
  //  Dart_Handle source_uri = Dart_GetNativeArgument(args, 0);
  Dart_Handle library_uri = Dart_GetNativeArgument(args, 1);
  Dart_Handle error = Dart_GetNativeArgument(args, 2);
  Dart_Handle library = Dart_LookupLibrary(library_uri);
  // If a library with the given uri exists, give it a chance to handle
  // the error. If the load requests stems from a deferred library load,
  // an IO error is not fatal.
  if (!Dart_IsError(library)) {
    DCHECK(Dart_IsLibrary(library));
    Dart_Handle res = Dart_LibraryHandleError(library, error);
    if (Dart_IsNull(res)) {
      return;
    }
  }
  // The error was not handled above. Propagate an unhandled exception.
  error = Dart_NewUnhandledExceptionError(error);
  Dart_PropagateError(error);
}

static const uint8_t* SniffForMagicNumber(const uint8_t* text_buffer,
                                          intptr_t* buffer_len,
                                          bool* is_snapshot) {
  intptr_t len = sizeof(Builtin::snapshot_magic_number);
  for (intptr_t i = 0; i < len; i++) {
    if (text_buffer[i] != Builtin::snapshot_magic_number[i]) {
      *is_snapshot = false;
      return text_buffer;
    }
  }
  *is_snapshot = true;
  DCHECK_GT(*buffer_len, len);
  *buffer_len -= len;
  return text_buffer + len;
}

// Callback function called when the asynchronous load request of a
// script, library or part is complete.
void Builtin_LoadScript(Dart_NativeArguments args) {
  Dart_Handle tag_in = Dart_GetNativeArgument(args, 0);
  Dart_Handle resolved_script_uri = Dart_GetNativeArgument(args, 1);
  Dart_Handle library_uri = Dart_GetNativeArgument(args, 2);
  Dart_Handle source_data = Dart_GetNativeArgument(args, 3);

  Dart_TypedData_Type type = Dart_GetTypeOfExternalTypedData(source_data);
  bool external = type == Dart_TypedData_kUint8;
  uint8_t* data = nullptr;
  intptr_t num_bytes;
  Dart_Handle result = Dart_TypedDataAcquireData(
      source_data, &type, reinterpret_cast<void**>(&data), &num_bytes);
  if (Dart_IsError(result))
    Dart_PropagateError(result);

  scoped_ptr<uint8_t[]> buffer_copy;
  if (!external) {
    // If the buffer is not external, take a copy.
    buffer_copy.reset(new uint8_t[num_bytes]);
    memmove(buffer_copy.get(), data, num_bytes);
    data = buffer_copy.get();
  }

  Dart_TypedDataReleaseData(source_data);

  if (Dart_IsNull(tag_in) && Dart_IsNull(library_uri)) {
    // No tag and a null library_uri indicates this is
    // a top-level script, check if it is a snapshot or a regular
    // script file and load accordingly.
    bool is_snapshot = false;
    const uint8_t* payload =
        SniffForMagicNumber(data, &num_bytes, &is_snapshot);

    if (is_snapshot) {
      result = Dart_LoadScriptFromSnapshot(payload, num_bytes);
    } else {
      Dart_Handle source = Dart_NewStringFromUTF8(data, num_bytes);
      if (Dart_IsError(source)) {
        result = Builtin::NewError("%s is not a valid UTF-8 script",
                                   resolved_script_uri);
      } else {
        result = Dart_LoadScript(resolved_script_uri, source, 0, 0);
      }
    }
  } else {
    int64_t tag = Builtin::GetIntegerValue(tag_in);

    Dart_Handle source = Dart_NewStringFromUTF8(data, num_bytes);
    if (Dart_IsError(source)) {
      result = Builtin::NewError("%s is not a valid UTF-8 script",
                                 resolved_script_uri);
    } else {
      if (tag == Dart_kImportTag) {
        result = Dart_LoadLibrary(resolved_script_uri, source, 0, 0);
      } else {
        DCHECK_EQ(tag, Dart_kSourceTag);
        Dart_Handle library = Dart_LookupLibrary(library_uri);
        DART_CHECK_VALID(library);
        result = Dart_LoadSource(library, resolved_script_uri, source, 0, 0);
      }
    }
  }

  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

// Callback function that gets called from dartutils when there are
// no more outstanding load requests.
void Builtin_DoneLoading(Dart_NativeArguments args) {
  Dart_Handle res = Dart_FinalizeLoading(true);
  if (Dart_IsError(res)) {
    Dart_PropagateError(res);
  }
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

  crypto::RandBytes(reinterpret_cast<void*>(buffer.get()), count);

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
