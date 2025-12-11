// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "canvas_text.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_text_skia.h"

namespace flutter {
std::shared_ptr<DlText> textFromBlob(const sk_sp<SkTextBlob>& blob) {
  return DlTextSkia::Make(blob);
}
}  // namespace flutter
