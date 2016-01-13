// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_CHECKERBOARD_H_
#define FLOW_CHECKERBOARD_H_

#include "third_party/skia/include/core/SkCanvas.h"

namespace flow {

void DrawCheckerboard(SkCanvas* canvas, const SkRect& rect);

}  // namespace flow

#endif  // FLOW_CHECKERBOARD_H_
