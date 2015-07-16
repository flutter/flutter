// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/packager/logging.h"

#include "base/logging.h"

bool LogIfError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    LOG(ERROR) << Dart_GetError(handle);

    // Only unhandled exceptions have stacktraces.
    if (!Dart_ErrorHasException(handle))
      return true;

    Dart_Handle stacktrace = Dart_ErrorGetStacktrace(handle);
    const char* stacktrace_cstr = "";
    Dart_StringToCString(Dart_ToString(stacktrace), &stacktrace_cstr);
    LOG(ERROR) << stacktrace_cstr;
    return true;
  }
  return false;
}

std::string StringFromDart(Dart_Handle string) {
  CHECK(Dart_IsString(string));
  uint8_t* utf8_array;
  intptr_t length;
  Dart_StringToUTF8(string, &utf8_array, &length);
  return std::string(reinterpret_cast<const char*>(utf8_array), length);
}

Dart_Handle StringToDart(const std::string& string) {
  return Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(string.data()),
                                string.length());
}
