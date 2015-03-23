// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_BUILTIN_H_
#define SKY_ENGINE_BINDINGS_BUILTIN_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {

class Builtin {
 public:
  // Note: Changes to this enum should be accompanied with changes to
  // the builtin_libraries_ array in builtin.cc.
  enum BuiltinLibraryId {
    kBuiltinLibrary,
    kSkyLibrary,
    kMojoInternalLibrary,
    kInvalidLibrary,
  };

  static void SetNativeResolver(BuiltinLibraryId id);
  static Dart_Handle LoadAndCheckLibrary(BuiltinLibraryId id);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(Builtin);
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_BUILTIN_H_
