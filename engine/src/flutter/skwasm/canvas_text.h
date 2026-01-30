// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_CANVAS_TEXT_H_
#define FLUTTER_SKWASM_CANVAS_TEXT_H_

#include <memory>

#include "flutter/display_list/dl_text.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace flutter {
std::shared_ptr<DlText> TextFromBlob(const sk_sp<SkTextBlob>& blob);
}

#endif  // FLUTTER_SKWASM_CANVAS_TEXT_H_
