// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/dart_ui.h"

#include "gen/sky/bindings/DartGlobal.h"
#include "sky/engine/bindings/builtin.h"
#include "sky/engine/bindings/dart_natives.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/core/view/View.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {

DartUI::DartUI(DOMDartState* dart_state) {
  library_.Set(dart_state, Builtin::LoadAndCheckLibrary(Builtin::kUILibrary));
}

DartUI::~DartUI() {
}

Dart_NativeFunction DartUI::NativeLookup(Dart_Handle name,
                                         int argument_count,
                                         bool* auto_setup_scope) {
  if (auto result = DartNatives::NativeLookup(name, argument_count, auto_setup_scope))
    return result;
  return skySnapshotResolver(name, argument_count, auto_setup_scope);
}

const uint8_t* DartUI::NativeSymbol(Dart_NativeFunction native_function) {
  if (auto result = DartNatives::NativeSymbol(native_function))
    return result;
  return skySnapshotSymbolizer(native_function);
}

void DartUI::InstallView(View* view) {
  CHECK(!LogIfError(
      Dart_SetField(library_.value(), ToDart("view"), ToDart(view))));
}

Dart_Handle DartUI::GetClassByName(const char* class_name) {
  Dart_Handle name_handle = ToDart(class_name);
  Dart_Handle class_handle = Dart_GetType(library_.value(), name_handle, 0, nullptr);
  DCHECK(!Dart_IsError(class_handle)) << class_name << ": " << Dart_GetError(class_handle);
  return class_handle;
}

}  // namespace blink
