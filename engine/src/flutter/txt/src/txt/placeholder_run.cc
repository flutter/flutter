// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "placeholder_run.h"

namespace txt {

PlaceholderRun::PlaceholderRun() {}

PlaceholderRun::PlaceholderRun(double width,
                               double height,
                               PlaceholderAlignment alignment,
                               TextBaseline baseline,
                               double baseline_offset)
    : width(width),
      height(height),
      alignment(alignment),
      baseline(baseline),
      baseline_offset(baseline_offset) {}

}  // namespace txt
