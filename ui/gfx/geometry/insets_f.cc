// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/insets_f.h"

#include "base/strings/stringprintf.h"

namespace gfx {

template class InsetsBase<InsetsF, float>;

InsetsF::InsetsF() : InsetsBase<InsetsF, float>(0, 0, 0, 0) {}

InsetsF::InsetsF(float top, float left, float bottom, float right)
    : InsetsBase<InsetsF, float>(top, left, bottom, right) {}

InsetsF::~InsetsF() {}

std::string InsetsF::ToString() const {
  // Print members in the same order of the constructor parameters.
  return base::StringPrintf("%f,%f,%f,%f", top(),  left(), bottom(), right());
}

}  // namespace gfx
