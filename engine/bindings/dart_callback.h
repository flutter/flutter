// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_DART_CALLBACK_H_
#define SKY_ENGINE_BINDINGS_DART_CALLBACK_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_persistent_value.h"

namespace blink {

class DartCallback {
 public:
  DartCallback(DartState* dart_state,
               Dart_Handle callback,
               Dart_Handle& exception);
  ~DartCallback();

  bool handleEvent(int argc, Dart_Handle* argv);

  bool IsIsolateAlive() const;
  Dart_Isolate GetIsolate() const;

 private:
  DartPersistentValue callback_;
};
}

#endif  // SKY_ENGINE_BINDINGS_DART_CALLBACK_H_
