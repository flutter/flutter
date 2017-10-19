// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_DART_RUNTIME_HOOKS_H_
#define FLUTTER_LIB_UI_DART_RUNTIME_HOOKS_H_

#include "lib/fxl/macros.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class DartRuntimeHooks {
 public:
  enum IsolateType {
    MainIsolate,
    SecondaryIsolate,
  };

  static void Install(IsolateType isolate_type, const std::string& script_uri);
  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  FXL_DISALLOW_IMPLICIT_CONSTRUCTORS(DartRuntimeHooks);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_DART_RUNTIME_HOOKS_H_
