// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_
#define SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_

#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace blink {

class TransferMode {
 public:
  SkXfermode::Mode sk_mode;
};

template<>
struct DartConverter<TransferMode, void> {
  static TransferMode FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                                 int index,
                                                 Dart_Handle& exception);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_
