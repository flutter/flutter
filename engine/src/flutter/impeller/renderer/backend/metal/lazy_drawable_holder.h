// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <future>
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"

@protocol CAMetalDrawable;
@class CAMetalLayer;

namespace impeller {

/// @brief Create a deferred drawable from a CAMetalLayer.
std::shared_future<id<CAMetalDrawable>> GetDrawableDeferred(
    CAMetalLayer* layer);

/// @brief Create a TextureMTL from a deferred drawable.
///
///        This function is safe to call multiple times and will only call
///        nextDrawable once.
std::shared_ptr<TextureMTL> CreateTextureFromDrawableFuture(
    TextureDescriptor desc,
    const std::shared_future<id<CAMetalDrawable>>& drawble_future);

}  // namespace impeller
