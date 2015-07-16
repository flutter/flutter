// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dom_dart_state.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/tonic/dart_builtin.h"

namespace blink {

DOMDartState::DOMDartState(Document* document, const String& url)
    : document_(document), url_(url) {
}

DOMDartState::~DOMDartState() {
  // We've already destroyed the isolate. Revoke any weak ptrs held by
  // DartPersistentValues so they don't try to enter the destroyed isolate to
  // clean themselves up.
  weak_factory_.InvalidateWeakPtrs();
}

void DOMDartState::DidSetIsolate() {
  Scope dart_scope(this);
  x_handle_.Set(this, ToDart("x"));
  y_handle_.Set(this, ToDart("y"));
  dx_handle_.Set(this, ToDart("_dx"));
  dy_handle_.Set(this, ToDart("_dy"));
  value_handle_.Set(this, ToDart("_value"));

  Dart_Handle sky_library = DartBuiltin::LookupLibrary("dart:sky");
  color_class_.Set(this, Dart_GetType(sky_library, ToDart("Color"), 0, 0));
}

DOMDartState* DOMDartState::Current() {
  return static_cast<DOMDartState*>(DartState::Current());
}

Document* DOMDartState::CurrentDocument() {
  return Current()->document_.get();
}

LocalFrame* DOMDartState::CurrentFrame() {
  DCHECK(Current()->document_);
  return Current()->document_->frame();
}

LocalDOMWindow* DOMDartState::CurrentWindow() {
  DCHECK(Current()->document_);
  return Current()->document_->domWindow();
}

}  // namespace blink
