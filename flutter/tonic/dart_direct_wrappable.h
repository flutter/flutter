// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_DIRECT_WRAPPABLE_H_
#define FLUTTER_TONIC_DART_DIRECT_WRAPPABLE_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"

namespace blink {
class DartState;
struct DartWrapperInfo;

template<typename T>
struct DartDirectWrappable;

template<>
struct DartDirectWrappable<void*> {
  static Dart_Handle Wrap(DartState* dart_state, void* val,
                          const DartWrapperInfo& info);
  static void* FromDart(Dart_Handle handle);
  static void* FromArguments(Dart_NativeArguments args,
                             int index,
                             Dart_Handle& exception);
};

template<typename T>
struct DartDirectWrappable {
  static Dart_Handle Wrap(DartState* dart_state, T val,
                          const DartWrapperInfo& info) {
    return DartDirectWrappable<void*>::Wrap(dart_state, static_cast<void*>(val),
                                            info);
  }

  static T FromDart(Dart_Handle handle) {
    return static_cast<T>(DartDirectWrappable<void*>::FromDart(handle));
  }

  static T FromArguments(Dart_NativeArguments args, int index,
                         Dart_Handle& exception) {
    return static_cast<T>(DartDirectWrappable<void*>::FromArguments(
        args, index, exception));
  }
};

template<typename T, const DartWrapperInfo& (*GetWrapperInfo)()>
struct DartConverterDirectWrappable {
  static Dart_Handle ToDart(T val) {
    if (!val)
      return Dart_Null();
    return DartDirectWrappable<T>::Wrap(
        DartState::Current(), val, GetWrapperInfo());
  }

  static void SetReturnValue(Dart_NativeArguments args, T val) {
    Dart_SetReturnValue(args, ToDart(val));
  }

  static T FromDart(Dart_Handle handle) {
    return DartDirectWrappable<T>::FromDart(handle);
  }

  static T FromArguments(Dart_NativeArguments args,
                         int index,
                         Dart_Handle& exception) {
    return DartDirectWrappable<T>::FromArguments(args, index, exception);
  }
};

#define IMPLEMENT_DIRECT_WRAPPABLE(LibraryName, DartName, ImplType)            \
static const DartWrapperInfo kDartWrapperInfo_##LibraryName_##DartName = {     \
  #LibraryName, #DartName, 0, 0, 0,                                            \
};                                                                             \
static const DartWrapperInfo& GetWrapperTypeInfo_##LibraryName_##DartName() {  \
  return kDartWrapperInfo_##LibraryName_##DartName;                            \
}                                                                              \
template <>                                                                    \
struct DartConverter<ImplType> : public DartConverterDirectWrappable<          \
    ImplType, GetWrapperTypeInfo_##LibraryName_##DartName> {};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_DIRECT_WRAPPABLE_H_
