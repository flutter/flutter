// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_INVOKE_H_
#define SKY_ENGINE_TONIC_DART_INVOKE_H_

#include <initializer_list>

#include "dart/runtime/include/dart_api.h"

namespace blink {

bool DartInvokeField(Dart_Handle target,
                     const char* name,
                     std::initializer_list<Dart_Handle> args);

bool DartInvokeAppClosure(Dart_Handle closure,
                          int number_of_arguments,
                          Dart_Handle* arguments);

bool DartInvokeAppClosure(Dart_Handle closure,
                          std::initializer_list<Dart_Handle> args);

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_INVOKE_H_
