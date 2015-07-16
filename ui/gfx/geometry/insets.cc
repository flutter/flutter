// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/insets.h"

#include "base/strings/stringprintf.h"

namespace gfx {

template class InsetsBase<Insets, int>;

Insets::Insets() : InsetsBase<Insets, int>(0, 0, 0, 0) {}

Insets::Insets(int top, int left, int bottom, int right)
    : InsetsBase<Insets, int>(top, left, bottom, right) {}

Insets::~Insets() {}

std::string Insets::ToString() const {
  // Print members in the same order of the constructor parameters.
  return base::StringPrintf("%d,%d,%d,%d", top(),  left(), bottom(), right());
}

}  // namespace gfx
