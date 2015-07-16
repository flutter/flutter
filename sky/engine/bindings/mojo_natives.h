// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_MOJO_NATIVES_H_
#define SKY_ENGINE_BINDINGS_MOJO_NATIVES_H_

#include "dart/runtime/include/dart_api.h"

namespace blink {

Dart_NativeFunction MojoNativeLookup(Dart_Handle name,
                                     int argument_count,
                                     bool* auto_setup_scope);

const uint8_t* MojoNativeSymbol(Dart_NativeFunction nf);

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_MOJO_NATIVES_H_
