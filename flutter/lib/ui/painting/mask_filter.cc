// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/mask_filter.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"

namespace blink {

static void MaskFilter_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&MaskFilter::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, MaskFilter);

void MaskFilter::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "MaskFilter_constructor", MaskFilter_constructor, 4, true },
  });
}

scoped_refptr<MaskFilter> MaskFilter::Create(unsigned style, double sigma,
                                             unsigned flags) {
  return new MaskFilter(SkBlurMaskFilter::Make(
      static_cast<SkBlurStyle>(style), sigma, flags));
}

MaskFilter::MaskFilter(sk_sp<SkMaskFilter> filter)
  : filter_(std::move(filter)) {
}

MaskFilter::~MaskFilter() {
}

} // namespace blink
