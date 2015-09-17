// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_FONTWEIGHT_H_
#define SKY_ENGINE_CORE_TEXT_FONTWEIGHT_H_

#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/platform/fonts/FontTraits.h"

namespace blink {

template <>
struct DartConverter<FontWeight>
    : public DartConverterEnum<FontWeight> {};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_FONTWEIGHT_H_
