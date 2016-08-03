// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_MOJO_CONVERTER_H_
#define FLUTTER_TONIC_MOJO_CONVERTER_H_

#include "lib/tonic/converter/dart_converter.h"
#include "mojo/public/cpp/system/handle.h"

namespace tonic {

template <typename HandleType>
struct DartConverter<mojo::ScopedHandleBase<HandleType>> {
  static mojo::ScopedHandleBase<HandleType> FromDart(Dart_Handle handle) {
    uint64_t raw_handle = 0;
    Dart_Handle result = Dart_IntegerToUint64(handle, &raw_handle);
    if (Dart_IsError(result) || !raw_handle)
      return mojo::ScopedHandleBase<HandleType>();

    HandleType mojo_handle(static_cast<MojoHandle>(raw_handle));
    return mojo::MakeScopedHandle(mojo_handle);
  }

  static Dart_Handle ToDart(mojo::ScopedHandleBase<HandleType> mojo_handle) {
    return Dart_NewInteger(static_cast<int64_t>(mojo_handle.release().value()));
  }

  static mojo::ScopedHandleBase<HandleType>
  FromArguments(Dart_NativeArguments args, int index, Dart_Handle& exception) {
    int64_t raw_handle = 0;
    Dart_Handle result =
        Dart_GetNativeIntegerArgument(args, index, &raw_handle);
    if (Dart_IsError(result) || !raw_handle)
      return mojo::ScopedHandleBase<HandleType>();

    HandleType mojo_handle(static_cast<MojoHandle>(raw_handle));
    return mojo::MakeScopedHandle(mojo_handle);
  }
};

}  // namespace tonic

#endif  // FLUTTER_TONIC_MOJO_CONVERTER_H_
