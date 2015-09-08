// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_VERTEXMODE_H_
#define SKY_ENGINE_CORE_PAINTING_VERTEXMODE_H_

#include "sky/engine/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

class VertexMode {};

template <>
struct DartConverter<VertexMode>
    : public DartConverterEnum<SkCanvas::VertexMode> {};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_VERTEXMODE_H_
