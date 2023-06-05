// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/core/texture.h"

namespace impeller {

std::shared_ptr<Texture> WrapTextureMTL(
    TextureDescriptor desc,
    const void* mtl_texture,
    std::function<void()> deletion_proc = nullptr);

}  // namespace impeller
