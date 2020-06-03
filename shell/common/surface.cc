// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/surface.h"

namespace flutter {

Surface::Surface() = default;

Surface::~Surface() = default;

flutter::ExternalViewEmbedder* Surface::GetExternalViewEmbedder() {
  return nullptr;
}

bool Surface::MakeRenderContextCurrent() {
  return true;
}

}  // namespace flutter
