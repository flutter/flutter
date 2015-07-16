// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_BUILTIN_H_
#define SKY_ENGINE_TONIC_DART_BUILTIN_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {

class DartBuiltin {
 public:
  struct Natives {
    const char* name;
    Dart_NativeFunction function;
    int argument_count;
  };

  DartBuiltin(const Natives* natives, size_t count);
  ~DartBuiltin();

  Dart_NativeFunction Resolver(Dart_Handle name,
                               int argument_count,
                               bool* auto_setup_scope) const;

  const uint8_t* Symbolizer(Dart_NativeFunction native_function) const;

  // Helper around Dart_LookupLibrary.
  static Dart_Handle LookupLibrary(const char* name);

 private:
  const Natives* natives_;
  size_t count_;

  DISALLOW_COPY_AND_ASSIGN(DartBuiltin);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_BUILTIN_H_
