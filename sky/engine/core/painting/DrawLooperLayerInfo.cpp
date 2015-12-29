// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/DrawLooperLayerInfo.h"

#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

static void DrawLooperLayerInfo_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&DrawLooperLayerInfo::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(DrawLooperLayerInfo);

#define FOR_EACH_BINDING(V) \
  V(DrawLooperLayerInfo, setPaintBits) \
  V(DrawLooperLayerInfo, setColorMode) \
  V(DrawLooperLayerInfo, setOffset) \
  V(DrawLooperLayerInfo, setPostTranslate)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void DrawLooperLayerInfo::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "DrawLooperLayerInfo_constructor", DrawLooperLayerInfo_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

DrawLooperLayerInfo::DrawLooperLayerInfo() {
}

DrawLooperLayerInfo::~DrawLooperLayerInfo() {
}

} // namespace blink
