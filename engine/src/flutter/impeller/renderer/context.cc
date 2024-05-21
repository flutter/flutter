// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/context.h"

namespace impeller {

Context::~Context() = default;

Context::Context() = default;

bool Context::UpdateOffscreenLayerPixelFormat(PixelFormat format) {
  return false;
}

}  // namespace impeller
