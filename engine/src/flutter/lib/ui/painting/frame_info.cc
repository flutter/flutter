
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/frame_info.h"

#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, FrameInfo);

#define FOR_EACH_BINDING(V)    \
  V(FrameInfo, durationMillis) \
  V(FrameInfo, image)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void FrameInfo::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

}  // namespace blink
