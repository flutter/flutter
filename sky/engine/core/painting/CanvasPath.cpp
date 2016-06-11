// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/CanvasPath.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"

namespace blink {

typedef CanvasPath Path;

static void Path_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&CanvasPath::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Path);

#define FOR_EACH_BINDING(V) \
  V(Path, moveTo) \
  V(Path, relativeMoveTo) \
  V(Path, lineTo) \
  V(Path, relativeLineTo) \
  V(Path, quadraticBezierTo) \
  V(Path, relativeQuadraticBezierTo) \
  V(Path, cubicTo) \
  V(Path, relativeCubicTo) \
  V(Path, conicTo) \
  V(Path, relativeConicTo) \
  V(Path, arcTo) \
  V(Path, addRect) \
  V(Path, addOval) \
  V(Path, addArc) \
  V(Path, addRRect) \
  V(Path, close) \
  V(Path, reset) \
  V(Path, contains) \
  V(Path, shift)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasPath::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "Path_constructor", Path_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

CanvasPath::CanvasPath()
{
}

CanvasPath::~CanvasPath()
{
}

scoped_refptr<CanvasPath> CanvasPath::shift(const Offset& offset) {
  scoped_refptr<CanvasPath> path = CanvasPath::create();
  m_path.offset(offset.sk_size.width(), offset.sk_size.height(), &path->m_path);
  return std::move(path);
}

} // namespace blink
