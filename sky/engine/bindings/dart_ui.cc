// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_ui.h"

#include "gen/sky/bindings/DartGlobal.h"
#include "sky/engine/bindings/dart_runtime_hooks.h"
#include "sky/engine/core/painting/painting.h"
#include "sky/engine/core/tracing/tracing.h"
#include "sky/engine/core/window/window.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {
namespace {

static DartLibraryNatives* g_natives;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  if (auto result = g_natives->GetNativeFunction(name,
                                                 argument_count,
                                                 auto_setup_scope))
    return result;
  return skySnapshotResolver(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  if (auto result = g_natives->GetSymbol(native_function))
    return result;
  return skySnapshotSymbolizer(native_function);
}

}  // namespace

void DartUI::InitForIsolate() {
  if (!g_natives) {
    g_natives = new DartLibraryNatives();
    DartRuntimeHooks::RegisterNatives(g_natives);
    Window::RegisterNatives(g_natives);
    Painting::RegisterNatives(g_natives);
    Tracing::RegisterNatives(g_natives);
  }

  DART_CHECK_VALID(Dart_SetNativeResolver(
      Dart_LookupLibrary(ToDart("dart:ui")), GetNativeFunction, GetSymbol));
}

}  // namespace blink
