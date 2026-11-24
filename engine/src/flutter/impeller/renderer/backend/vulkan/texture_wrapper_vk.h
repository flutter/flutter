// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_

#include <functional>
#include <memory>

#include "impeller/core/texture.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

/// @brief      Wrap a `VkImage` Impeller does not own as a texture source.
///
///             The image is not owned, not transitioned and not destroyed here;
///             the caller guarantees it outlives the returned source and is in
///             a layout the intended usage allows. An image view is created for
///             it and owned by the returned source.
///
///             Returns nullptr if the view could not be created.
///
///             If `cleanup` is provided it is invoked exactly once: when the
///             returned source is destroyed (after its framebuffer and image
///             view are released), or before returning if this fails.
///
/// @see        `WrapTextureMTL`, the Metal equivalent.
std::shared_ptr<TextureSourceVK> WrapTextureSourceVK(
    const ContextVK& context,
    const TextureDescriptor& desc,
    vk::Image image,
    std::function<void()> cleanup = nullptr);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_WRAPPER_VK_H_
