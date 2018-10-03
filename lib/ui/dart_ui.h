// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_DART_UI_H_
#define FLUTTER_LIB_UI_DART_UI_H_

#include "flutter/fml/macros.h"

namespace blink {

class DartUI {
 public:
  static void InitForGlobal();
  static void InitForIsolate(bool is_root_isolate);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(DartUI);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_DART_UI_H_
