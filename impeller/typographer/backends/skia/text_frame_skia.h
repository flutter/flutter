// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/typographer/text_frame.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace impeller {

TextFrame TextFrameFromTextBlob(sk_sp<SkTextBlob> blob, Scalar scale = 1.0f);

}  // namespace impeller
