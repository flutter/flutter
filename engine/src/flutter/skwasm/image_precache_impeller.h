// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_IMAGE_PRECACHE_IMPELLER_H_
#define FLUTTER_SKWASM_IMAGE_PRECACHE_IMPELLER_H_

#include "flutter/display_list/display_list.h"
#include "impeller/entity/contents/content_context.h"

namespace Skwasm {

// Pre-populates the ContentContext texture cache with all images referenced
// within the given DisplayList before rendering the main frame.
//
// In wimp, picture-backed images (DlWimpImageFromPicture) are rasterized to
// textures via DisplayListToTexture. If rasterization occurs on-demand
// mid-frame during Canvas dispatch, the nested Canvas session will start and
// end its own render pass on the shared ContentContext. This resets the
// RenderTargetCache usage tracking in the middle of the outer frame, causing
// active intermediate render targets (e.g. for image filters and blurs) to be
// stomped.
//
// Pre-caching images before RenderToTarget ensures each image is rasterized in
// its own standalone pass prior to the outer frame pass.
void PrecacheImages(const flutter::DisplayList* display_list,
                    impeller::ContentContext& context);

}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_IMAGE_PRECACHE_IMPELLER_H_
