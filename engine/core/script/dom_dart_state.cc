// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/script/dom_dart_state.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/script/dart_loader.h"
#include "sky/engine/tonic/dart_builtin.h"

namespace blink {

DOMDartState::DOMDartState(Document* document)
    : document_(document), loader_(adoptPtr(new DartLoader(this))) {
}

DOMDartState::~DOMDartState() {
}

void DOMDartState::DidSetIsolate() {
  Scope dart_scope(this);
  x_handle_.Set(this, Dart_NewStringFromCString("x"));
  y_handle_.Set(this, Dart_NewStringFromCString("y"));
  index_handle_.Set(this, Dart_NewStringFromCString("index"));
  value_handle_.Set(this, Dart_NewStringFromCString("_value"));

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
