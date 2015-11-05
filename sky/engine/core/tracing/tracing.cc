// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/tracing/tracing.h"

#include "base/trace_event/trace_event.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/wtf/text/StringUTF8Adaptor.h"

namespace blink {

namespace {

void BeginTracing(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  String name = DartConverter<String>::FromArguments(args, 1, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  StringUTF8Adaptor utf8(name);
  // TRACE_EVENT_COPY_BEGIN0 needs a c-style null-terminated string.
  CString cstring(utf8.data(), utf8.length());
  TRACE_EVENT_COPY_BEGIN0("script", cstring.data());
}

void EndTracing(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  String name = DartConverter<String>::FromArguments(args, 1, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  StringUTF8Adaptor utf8(name);
  // TRACE_EVENT_COPY_END0 needs a c-style null-terminated string.
  CString cstring(utf8.data(), utf8.length());
  TRACE_EVENT_COPY_END0("script", cstring.data());
}

}  // namespace

void Tracing::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "Tracing_begin", BeginTracing, 2, true },
    { "Tracing_end", EndTracing, 2, true },
  });
}

}  // namespace blink
