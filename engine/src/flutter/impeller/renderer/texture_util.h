// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_TEXTURE_UTIL_H_
#define FLUTTER_IMPELLER_RENDERER_TEXTURE_UTIL_H_

#include "flutter/fml/status.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"

namespace impeller {

std::shared_ptr<Texture> CreateTexture(
    const TextureDescriptor& texture_descriptor,
    const std::vector<uint8_t>& data,
    const std::shared_ptr<impeller::Context>& context,
    std::string_view debug_label);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_TEXTURE_UTIL_H_
