// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_EXCEPTION_FACTORY_H_
#define FLUTTER_TONIC_DART_EXCEPTION_FACTORY_H_

#include <string>
#include <vector>

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_persistent_value.h"

namespace blink {
class DartState;

class DartExceptionFactory {
 public:
  explicit DartExceptionFactory(DartState* dart_state);
  ~DartExceptionFactory();

  Dart_Handle CreateNullArgumentException(int index);
  Dart_Handle CreateException(const std::string& class_name,
                              const std::string& message);
  Dart_Handle CreateException(const std::string& class_name,
                              Dart_Handle message);

 private:
  DartState* dart_state_;
  DartPersistentValue core_library_;
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_EXCEPTION_FACTORY_H_
