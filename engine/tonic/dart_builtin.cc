// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/tonic/dart_builtin.h"

#include <stdlib.h>
#include <string.h>

#include "base/logging.h"

namespace blink {

DartBuiltin::DartBuiltin(const Natives* natives, size_t count)
    : natives_(natives), count_(count) {
}

DartBuiltin::~DartBuiltin() {
}

Dart_NativeFunction DartBuiltin::Resolver(Dart_Handle name,
                                          int argument_count,
                                          bool* auto_setup_scope) const {
  const char* function_name = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  DCHECK(function_name != nullptr);
  DCHECK(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  for (size_t i = 0; i < count_; ++i) {
    const Natives& entry = natives_[i];
    if (!strcmp(function_name, entry.name) &&
        (entry.argument_count == argument_count)) {
      return entry.function;
    }
  }
  return nullptr;
}

const uint8_t* DartBuiltin::Symbolizer(Dart_NativeFunction native_function) const {
  for (size_t i = 0; i < count_; ++i) {
    const Natives& entry = natives_[i];
    if (entry.function == native_function)
      return reinterpret_cast<const uint8_t*>(entry.name);
  }
  return nullptr;
}

}  // namespace blink
