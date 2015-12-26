// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_BINDING_MACROS_H_
#define SKY_ENGINE_TONIC_DART_BINDING_MACROS_H_

#include "sky/engine/tonic/dart_args.h"

#define DART_NATIVE_CALLBACK(CLASS, METHOD) \
  static void CLASS_##METHOD(Dart_NativeArguments args) { \
    DartCall(&CLASS::METHOD, args); \
  }

#define DART_REGISTER_NATIVE(CLASS, METHOD) \
  { #CLASS "_" #METHOD, CLASS_##METHOD, \
    IndicesForSignature<decltype(&CLASS::METHOD)>::count + 1, true },

#define DART_BIND_ALL(CLASS, FOR_EACH) \
FOR_EACH(DART_NATIVE_CALLBACK) \
void CLASS::RegisterNatives(DartLibraryNatives* natives) { \
  natives->Register({ \
    FOR_EACH(DART_REGISTER_NATIVE) \
  }); \
}

#endif  // SKY_ENGINE_TONIC_DART_BINDING_MACROS_H_
