// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DEBUG_PRINT_H_
#define FLUTTER_FLOW_DEBUG_PRINT_H_

#include "flutter/flow/matrix_decomposition.h"
#include "flutter/flow/raster_cache_key.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "third_party/skia/include/core/SkPoint3.h"
#include "third_party/skia/include/core/SkRRect.h"

#define DEF_PRINTER(x) std::ostream& operator<<(std::ostream&, const x&);

DEF_PRINTER(flow::MatrixDecomposition);
DEF_PRINTER(flow::PictureRasterCacheKey);
DEF_PRINTER(SkISize);
DEF_PRINTER(SkMatrix);
DEF_PRINTER(SkMatrix44);
DEF_PRINTER(SkPoint);
DEF_PRINTER(SkRect);
DEF_PRINTER(SkRRect);
DEF_PRINTER(SkVector3);
DEF_PRINTER(SkVector4);

#endif  // FLUTTER_FLOW_DEBUG_PRINT_H_
