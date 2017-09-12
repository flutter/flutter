// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/mask_filter.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/utils.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"

namespace blink {

static void MaskFilter_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&MaskFilter::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, MaskFilter);

void MaskFilter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"MaskFilter_constructor", MaskFilter_constructor, 3, true},
  });
}

fxl::RefPtr<MaskFilter> MaskFilter::Create(unsigned style, double sigma) {
  return fxl::MakeRefCounted<MaskFilter>(
      SkBlurMaskFilter::Make(static_cast<SkBlurStyle>(style), sigma));
}

MaskFilter::MaskFilter(sk_sp<SkMaskFilter> filter)
    : filter_(std::move(filter)) {}

MaskFilter::~MaskFilter() {
  // Skia objects must be deleted on the IO thread so that any associated GL
  // objects will be cleaned up through the IO thread's GL context.
  SkiaUnrefOnIOThread(&filter_);
}

}  // namespace blink
