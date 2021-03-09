// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/range/range.h"

#include <inttypes.h>

#include <algorithm>

#include "base/strings/stringprintf.h"

namespace gfx {

std::string Range::ToString() const {
  return base::StringPrintf("{%" PRIu32 ",%" PRIu32 "}", start(), end());
}

std::ostream& operator<<(std::ostream& os, const Range& range) {
  return os << range.ToString();
}

}  // namespace gfx
