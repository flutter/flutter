// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_MOJO_CONVERTER_H_
#define SKY_ENGINE_TONIC_MOJO_CONVERTER_H_

#include "mojo/public/cpp/system/handle.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

template <typename HandleType>
struct DartConverter<mojo::ScopedHandleBase<HandleType>> {
  static mojo::ScopedHandleBase<HandleType> FromDart(Dart_Handle handle) {
    uint64_t mojo_handle64 = 0;
    Dart_Handle result = Dart_IntegerToUint64(handle, &mojo_handle64);
    if (Dart_IsError(result) || !mojo_handle64)
      return mojo::ScopedHandleBase<HandleType>();

    HandleType mojo_handle(static_cast<MojoHandle>(mojo_handle64));
    return mojo::MakeScopedHandle(mojo_handle);
  }

  static Dart_Handle ToDart(mojo::ScopedHandleBase<HandleType> mojo_handle) {
    return Dart_NewInteger(static_cast<int64_t>(mojo_handle.release().value()));
  }
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_MOJO_CONVERTER_H_
