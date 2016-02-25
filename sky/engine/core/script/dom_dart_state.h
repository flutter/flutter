// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_
#define SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_

#include "sky/engine/bindings/flutter_dart_state.h"
#include "sky/engine/platform/fonts/FontSelector.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {
class Window;

class DOMDartState : public FlutterDartState {
 public:
  DOMDartState(IsolateClient* isolate_client, const std::string& url,
               std::unique_ptr<Window> window);
  ~DOMDartState() override;

  Window* window() const { return window_.get(); }

  static DOMDartState* Current();

  void set_font_selector(PassRefPtr<FontSelector> selector);
  PassRefPtr<FontSelector> font_selector();

 private:
  std::unique_ptr<Window> window_;
  RefPtr<FontSelector> font_selector_;
};

}  // namespace blink

#endif // SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_
