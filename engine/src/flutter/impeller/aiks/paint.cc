// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"

namespace impeller {

Paint::Paint() = default;

Paint::~Paint() = default;

void Paint::SetColor(Color color) {
  color_ = std::move(color);
}

}  // namespace impeller
