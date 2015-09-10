// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_TEXTALIGN_H_
#define SKY_ENGINE_CORE_TEXT_TEXTALIGN_H_

#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/platform/graphics/GraphicsTypes.h"

namespace blink {

template <>
struct DartConverter<TextAlign>
    : public DartConverterEnum<int> {};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_TEXTALIGN_H_
