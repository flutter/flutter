// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_

#include <functional>
#include <memory>

#include "impeller/core/texture.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Wraps an existing VkImage into an Impeller Texture.
///
/// @param[in]  context        The Impeller Vulkan context.
/// @param[in]  desc           The descriptor of the texture.
/// @param[in]  image          The Vulkan image handle to wrap.
/// @param[in]  deletion_proc  Optional callback when the wrapped texture is
/// destroyed.
///
/// @return     A shared pointer to the wrapped Texture, or nullptr on failure.
///
std::shared_ptr<Texture> WrapTextureVK(
    const std::shared_ptr<Context>& context,
    TextureDescriptor desc,
    vk::Image image,
    std::function<void()> deletion_proc = nullptr);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_
