// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dom_dart_state.h"

#include "sky/engine/core/window/window.h"

namespace blink {

DOMDartState::DOMDartState(IsolateClient* isolate_client,
                           const std::string& url,
                           std::unique_ptr<Window> window)
    : FlutterDartState(isolate_client, url),
      window_(std::move(window)) {
}

DOMDartState::~DOMDartState() {
}

DOMDartState* DOMDartState::Current() {
  return static_cast<DOMDartState*>(DartState::Current());
}

void DOMDartState::set_font_selector(PassRefPtr<FontSelector> selector) {
  font_selector_ = selector;
}

PassRefPtr<FontSelector> DOMDartState::font_selector() {
  return font_selector_;
}


}  // namespace blink
