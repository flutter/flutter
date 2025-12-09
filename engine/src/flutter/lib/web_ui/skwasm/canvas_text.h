// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_CANVAS_TEXT_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_CANVAS_TEXT_H_

#include "flutter/display_list/dl_text.h"
#include "third_party/skia/include/core/SkRefCnt.h"

#include <memory>

namespace flutter {
std::shared_ptr<DlText> textFromBlob(const sk_sp<SkTextBlob>& blob);
}

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_CANVAS_TEXT_H_
