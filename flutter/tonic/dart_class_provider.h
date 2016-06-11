// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_CLASS_PROVIDER_H_
#define FLUTTER_TONIC_DART_CLASS_PROVIDER_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_persistent_value.h"

namespace blink {
class DartState;

class DartClassProvider {
 public:
  DartClassProvider(DartState* dart_state, const char* library_name);
  ~DartClassProvider();

  Dart_Handle GetClassByName(const char* class_name);

 private:
   DartPersistentValue library_;

   DISALLOW_COPY_AND_ASSIGN(DartClassProvider);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_CLASS_PROVIDER_H_
