// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_RSTRANSFORM_H_
#define SKY_ENGINE_CORE_PAINTING_RSTRANSFORM_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkRSXform.h"

namespace blink {
// Very simple wrapper for SkRSXform to add a null state.
class RSTransform {
 public:
  SkRSXform sk_xform;
  bool is_null;
};

template <>
struct DartConverter<RSTransform> {
  static RSTransform FromDart(Dart_Handle handle);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_RSTRANSFORM_H_
