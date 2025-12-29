// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/canvas_text.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/impeller/display_list/dl_text_impeller.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {
std::shared_ptr<DlText> TextFromBlob(const sk_sp<SkTextBlob>& blob) {
  return DlTextImpeller::MakeFromBlob(blob);
}
}  // namespace flutter
