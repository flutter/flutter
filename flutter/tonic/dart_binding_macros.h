// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_BINDING_MACROS_H_
#define FLUTTER_TONIC_DART_BINDING_MACROS_H_

#include "flutter/tonic/dart_args.h"

#define DART_NATIVE_CALLBACK(CLASS, METHOD) \
  static void CLASS##_##METHOD(Dart_NativeArguments args) { \
    blink::DartCall(&CLASS::METHOD, args);                  \
  }

#define DART_NATIVE_CALLBACK_STATIC(CLASS, METHOD) \
  static void CLASS##_##METHOD(Dart_NativeArguments args) { \
    blink::DartCallStatic(&CLASS::METHOD, args);            \
  }

#define DART_REGISTER_NATIVE(CLASS, METHOD) \
  { #CLASS "_" #METHOD, CLASS##_##METHOD, \
    blink::IndicesForSignature<decltype(&CLASS::METHOD)>::count + 1, true },

#define DART_REGISTER_NATIVE_STATIC(CLASS, METHOD) \
  { #CLASS "_" #METHOD, CLASS##_##METHOD, \
    blink::IndicesForSignature<decltype(&CLASS::METHOD)>::count, true },

#define DART_BIND_ALL(CLASS, FOR_EACH) \
FOR_EACH(DART_NATIVE_CALLBACK) \
void CLASS::RegisterNatives(blink::DartLibraryNatives* natives) {      \
  natives->Register({ \
    FOR_EACH(DART_REGISTER_NATIVE) \
  }); \
}

#endif  // FLUTTER_TONIC_DART_BINDING_MACROS_H_
