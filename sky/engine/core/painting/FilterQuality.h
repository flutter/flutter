// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_FILTERQUALITY_H_
#define SKY_ENGINE_CORE_PAINTING_FILTERQUALITY_H_

#include "sky/engine/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace blink {

class FilterQuality {};

template <>
struct DartConverter<FilterQuality>
    : public DartConverterEnum<SkFilterQuality> {};

// If this fails, it's because SkFilterQuality has changed. We need to change
// FilterQuality.dart to ensure the FilterQuality enum is in sync with the C++
// values.
COMPILE_ASSERT(SkFilterQuality::kHigh_SkFilterQuality == 3, Need_to_update_FilterQuality_dart);

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_FILTERQUALITY_H_
