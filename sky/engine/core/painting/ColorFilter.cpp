// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/ColorFilter.h"

#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

static void ColorFilter_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ColorFilter::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ColorFilter);

void ColorFilter::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "ColorFilter_constructor", ColorFilter_constructor, 3, true },
  });
}

PassRefPtr<ColorFilter> ColorFilter::create(CanvasColor color,
                                            TransferMode transfer_mode) {
  return adoptRef(new ColorFilter(
      adoptRef(SkColorFilter::CreateModeFilter(color, transfer_mode))));
}

ColorFilter::ColorFilter(PassRefPtr<SkColorFilter> filter)
    : filter_(filter) {
}

ColorFilter::~ColorFilter() {
}

} // namespace blink
