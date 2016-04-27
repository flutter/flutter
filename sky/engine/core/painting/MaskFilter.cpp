// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/MaskFilter.h"

#include "third_party/skia/include/effects/SkBlurMaskFilter.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

static void MaskFilter_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&MaskFilter::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, MaskFilter);

void MaskFilter::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "MaskFilter_constructor", MaskFilter_constructor, 4, true },
  });
}

PassRefPtr<MaskFilter> MaskFilter::create(
      unsigned style, double sigma, unsigned flags) {
  return adoptRef(new MaskFilter(SkBlurMaskFilter::Make(
      static_cast<SkBlurStyle>(style), sigma, flags)));
}

MaskFilter::MaskFilter(sk_sp<SkMaskFilter> filter)
    : filter_(filter) {
}

MaskFilter::~MaskFilter() {
}

} // namespace blink
