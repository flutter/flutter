// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/core/script/ui_dart_state.h"

#include "flutter/sky/engine/core/window/window.h"
#include "flutter/sky/engine/public/platform/Platform.h"

namespace blink {

UIDartState::UIDartState(IsolateClient* isolate_client,
                         const std::string& url,
                         std::unique_ptr<Window> window)
    : FlutterDartState(isolate_client, url), window_(std::move(window)) {}

UIDartState::~UIDartState() {}

UIDartState* UIDartState::Current() {
  return static_cast<UIDartState*>(DartState::Current());
}

void UIDartState::set_font_selector(PassRefPtr<FontSelector> selector) {
  font_selector_ = selector;
}

PassRefPtr<FontSelector> UIDartState::font_selector() {
  return font_selector_;
}

}  // namespace blink
