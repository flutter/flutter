// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_UI_DART_STATE_H_
#define FLUTTER_LIB_UI_UI_DART_STATE_H_

#include <utility>

#include "dart/runtime/include/dart_api.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "lib/fxl/build_config.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"

namespace blink {
class FontSelector;
class Window;

class IsolateClient {
 public:
  virtual void DidCreateSecondaryIsolate(Dart_Isolate isolate) = 0;

 protected:
  virtual ~IsolateClient();
};

class UIDartState : public tonic::DartState {
 public:
  UIDartState(IsolateClient* isolate_client, std::unique_ptr<Window> window);
  ~UIDartState() override;

  static UIDartState* Current();

  UIDartState* CreateForChildIsolate();

  IsolateClient* isolate_client() { return isolate_client_; }
  Dart_Port main_port() const { return main_port_; }
  const std::string& debug_name() const { return debug_name_; }
  Window* window() const { return window_.get(); }

  void set_debug_name_prefix(const std::string& debug_name_prefix);
  void set_font_selector(PassRefPtr<FontSelector> selector);
  PassRefPtr<FontSelector> font_selector();

 private:
  void DidSetIsolate() override;

  IsolateClient* isolate_client_;
  Dart_Port main_port_;
  std::string debug_name_prefix_;
  std::string debug_name_;
  std::unique_ptr<Window> window_;
  RefPtr<FontSelector> font_selector_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_UI_DART_STATE_H_
