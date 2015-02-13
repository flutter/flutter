// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_BUILTIN_SKY_H_
#define SKY_ENGINE_BINDINGS_BUILTIN_SKY_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_class_provider.h"
#include "sky/engine/tonic/dart_persistent_value.h"

namespace blink {
class DOMDartState;

class BuiltinSky : public DartClassProvider {
 public:
  explicit BuiltinSky(DOMDartState* dart_state);
  ~BuiltinSky();

  void InstallWindow(DOMDartState* dart_state);

  // DartClassProvider:
  Dart_Handle GetClassByName(const char* class_name) override;

 private:
  DartPersistentValue library_;

  DISALLOW_COPY_AND_ASSIGN(BuiltinSky);
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_BUILTIN_SKY_H_
