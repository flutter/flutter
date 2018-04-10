// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/ui_dart_state.h"

#include "flutter/lib/ui/window/window.h"
#include "flutter/sky/engine/platform/fonts/FontSelector.h"
#include "lib/tonic/converter/dart_converter.h"

using tonic::ToDart;

namespace blink {

IsolateClient::~IsolateClient() {}

UIDartState::UIDartState(IsolateClient* isolate_client,
                         std::unique_ptr<Window> window,
                         int dirfd)
    : tonic::DartState(dirfd),
      isolate_client_(isolate_client),
      main_port_(ILLEGAL_PORT),
      window_(std::move(window)) {}

UIDartState::~UIDartState() {
  main_port_ = ILLEGAL_PORT;
  // We've already destroyed the isolate. Revoke any weak ptrs held by
  // DartPersistentValues so they don't try to enter the destroyed isolate to
  // clean themselves up.
  // TODO(abarth): Can we do this work in the base class?
  weak_factory_.InvalidateWeakPtrs();
}

UIDartState* UIDartState::CreateForChildIsolate() {
  return new UIDartState(isolate_client_, nullptr);
}

void UIDartState::DidSetIsolate() {
  FXL_DCHECK(!debug_name_prefix_.empty());
  main_port_ = Dart_GetMainPortId();
  std::ostringstream debug_name;
  debug_name << debug_name_prefix_ << "$main-" << main_port_;
  debug_name_ = debug_name.str();
}

UIDartState* UIDartState::Current() {
  return static_cast<UIDartState*>(DartState::Current());
}

void UIDartState::set_font_selector(PassRefPtr<FontSelector> selector) {
  font_selector_ = selector;
}

PassRefPtr<FontSelector> UIDartState::font_selector() {
  return font_selector_;
}

void UIDartState::set_debug_name_prefix(const std::string& debug_name_prefix) {
  debug_name_prefix_ = debug_name_prefix;
}

}  // namespace blink
