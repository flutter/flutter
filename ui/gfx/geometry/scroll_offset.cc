// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/scroll_offset.h"

#include "base/strings/stringprintf.h"

namespace gfx {

std::string ScrollOffset::ToString() const {
  return base::StringPrintf("[%lf %lf]", x_, y_);
}

}  // namespace gfx
