// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_
#define SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_

#include "sky/engine/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace blink {

struct TransferMode {
  SkXfermode::Mode mode;

  TransferMode() : mode() { }
  TransferMode(SkXfermode::Mode mode) : mode(mode) { }
  operator SkXfermode::Mode() { return mode; }
};

template <>
struct DartConverter<TransferMode>
    : public DartConverterEnum<SkXfermode::Mode> {};

// If this fails, it's because SkXfermode has changed. We need to change
// TransferMode.dart to ensure the TransferMode enum is in sync with the C++
// values.
COMPILE_ASSERT(SkXfermode::kLastMode == 28, Need_to_update_TransferMode_dart);

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_TRANSFERMODE_H_
