// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_
#define SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_

#include <memory>

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/platform/fonts/FontSelector.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {
class Window;

class DOMDartState : public DartState {
 public:
  DOMDartState(std::unique_ptr<Window> window, const std::string& url);
  ~DOMDartState() override;

  virtual void DidSetIsolate();

  Window* window() const { return window_.get(); }
  const std::string& url() const { return url_; }

  static DOMDartState* Current();

  // Cached handles to strings used in Dart/C++ conversions.
  Dart_Handle x_handle() { return x_handle_.value(); }
  Dart_Handle y_handle() { return y_handle_.value(); }
  Dart_Handle dx_handle() { return dx_handle_.value(); }
  Dart_Handle dy_handle() { return dy_handle_.value(); }
  Dart_Handle value_handle() { return value_handle_.value(); }
  Dart_Handle color_class() { return color_class_.value(); }

  void set_font_selector(PassRefPtr<FontSelector> selector);
  PassRefPtr<FontSelector> font_selector();

 private:
  std::unique_ptr<Window> window_;
  std::string url_;

  DartPersistentValue x_handle_;
  DartPersistentValue y_handle_;
  DartPersistentValue dx_handle_;
  DartPersistentValue dy_handle_;
  DartPersistentValue value_handle_;
  DartPersistentValue color_class_;
  RefPtr<FontSelector> font_selector_;
};

}  // namespace blink

#endif // SKY_ENGINE_CORE_SCRIPT_DOM_DART_STATE_H_
