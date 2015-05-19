// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/script/dom_dart_state.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/script/dart_loader.h"

namespace blink {

DOMDartState::DOMDartState(Document* document)
    : document_(document), loader_(adoptPtr(new DartLoader(this))) {
}

DOMDartState::~DOMDartState() {
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

}
