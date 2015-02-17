// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_EXCEPTION_FACTORY_H_
#define SKY_ENGINE_TONIC_DART_EXCEPTION_FACTORY_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_persistent_value.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {
class DartState;

class DartExceptionFactory {
 public:
  explicit DartExceptionFactory(DartState* dart_state);
  ~DartExceptionFactory();

  Dart_Handle CreateNullArgumentException(int index);
  Dart_Handle CreateException(const String& class_name, const String& message);

 private:
  DartState* dart_state_;
  DartPersistentValue core_library_;
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_EXCEPTION_FACTORY_H_
