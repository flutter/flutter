// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dom_dart_state.h"

#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/core/window/window.h"

namespace blink {

DOMDartState::DOMDartState(std::unique_ptr<Window> window, const std::string& url)
    : window_(std::move(window)), url_(url) {
}

DOMDartState::~DOMDartState() {
  // We've already destroyed the isolate. Revoke any weak ptrs held by
  // DartPersistentValues so they don't try to enter the destroyed isolate to
  // clean themselves up.
  weak_factory_.InvalidateWeakPtrs();
}

DOMDartState* DOMDartState::Current() {
  return static_cast<DOMDartState*>(DartState::Current());
}

void DOMDartState::DidSetIsolate() {
  Scope dart_scope(this);
  x_handle_.Set(this, ToDart("x"));
  y_handle_.Set(this, ToDart("y"));
  dx_handle_.Set(this, ToDart("_dx"));
  dy_handle_.Set(this, ToDart("_dy"));
  value_handle_.Set(this, ToDart("_value"));

  Dart_Handle library = Dart_LookupLibrary(ToDart("dart:ui"));
  color_class_.Set(this, Dart_GetType(library, ToDart("Color"), 0, 0));
}

void DOMDartState::set_font_selector(PassRefPtr<FontSelector> selector) {
  font_selector_ = selector;
}

PassRefPtr<FontSelector> DOMDartState::font_selector() {
  return font_selector_;
}


}  // namespace blink
