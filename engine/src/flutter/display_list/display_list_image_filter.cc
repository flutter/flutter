// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_image_filter.h"

namespace flutter {

std::shared_ptr<DlImageFilter> DlImageFilter::From(
    const SkImageFilter* sk_filter) {
  if (sk_filter == nullptr) {
    return nullptr;
  }
  {
    SkColorFilter* color_filter;
    if (sk_filter->isColorFilterNode(&color_filter)) {
      FML_DCHECK(color_filter != nullptr);
      // If |isColorFilterNode| succeeds, the pointer it sets into color_filter
      // will be ref'd already so we do not use sk_ref_sp() here as that would
      // double-ref the color filter object. Instead we use a bare sk_sp
      // constructor to adopt this reference into an sk_sp<SkCF> without
      // reffing it and let the compiler manage the refs.
      return std::make_shared<DlColorFilterImageFilter>(
          DlColorFilter::From(sk_sp<SkColorFilter>(color_filter)));
    }
  }
  return std::make_shared<DlUnknownImageFilter>(sk_ref_sp(sk_filter));
}

}  // namespace flutter
