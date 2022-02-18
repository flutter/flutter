// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_mask_filter.h"

namespace flutter {

std::shared_ptr<DlMaskFilter> DlMaskFilter::From(SkMaskFilter* sk_filter) {
  if (sk_filter == nullptr) {
    return nullptr;
  }
  // There are no inspection methods for SkMaskFilter so we cannot break
  // the Skia filter down into a specific subclass (i.e. Blur).
  return std::make_shared<DlUnknownMaskFilter>(sk_ref_sp(sk_filter));
}

}  // namespace flutter
