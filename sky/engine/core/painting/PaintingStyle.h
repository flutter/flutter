// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGSTYLE_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGSTYLE_H_

#include "sky/engine/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace blink {

class PaintingStyle {};

template <>
struct DartConverter<PaintingStyle> : public DartConverterEnum<SkPaint::Style> {
};

// If this fails, it's because SkPaint::Style has changed. We need to change
// PaintingStyle.dart to ensure the PaintingStyle enum is in sync with the C++
// values.
COMPILE_ASSERT(SkPaint::kStyleCount == 3, Need_to_update_PaintingStyle_dart);

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGSTYLE_H_
