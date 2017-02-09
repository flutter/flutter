// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/mask_filter.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/utils.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"
#include "third_party/skia/include/effects/SkShadowMaskFilter.h"

namespace blink {

static void MaskFilter_constructorBlur(Dart_NativeArguments args) {
  DartCallConstructor(&MaskFilter::CreateBlur, args);
}

static void MaskFilter_constructorShadow(Dart_NativeArguments args) {
  DartCallConstructor(&MaskFilter::CreateShadow, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, MaskFilter);

void MaskFilter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"MaskFilter_constructorBlur", MaskFilter_constructorBlur, 3, true},
      {"MaskFilter_constructorShadow", MaskFilter_constructorShadow, 8, true},
  });
}

ftl::RefPtr<MaskFilter> MaskFilter::CreateBlur(unsigned style, double sigma) {
  return ftl::MakeRefCounted<MaskFilter>(
      SkBlurMaskFilter::Make(static_cast<SkBlurStyle>(style), sigma));
}

ftl::RefPtr<MaskFilter> MaskFilter::CreateShadow(double occluderHeight,
                                                 double lightPosX,
                                                 double lightPosY,
                                                 double lightPosZ,
                                                 double lightRadius,
                                                 double ambientAlpha,
                                                 double spotAlpha) {
  return ftl::MakeRefCounted<MaskFilter>(
      SkShadowMaskFilter::Make(occluderHeight,
                               SkPoint3::Make(lightPosX, lightPosY, lightPosZ),
                               lightRadius,
                               ambientAlpha,
                               spotAlpha));
}

MaskFilter::MaskFilter(sk_sp<SkMaskFilter> filter)
    : filter_(std::move(filter)) {}

MaskFilter::~MaskFilter() {
  // Skia objects must be deleted on the IO thread so that any associated GL
  // objects will be cleaned up through the IO thread's GL context.
  SkiaUnrefOnIOThread(&filter_);
}

}  // namespace blink
