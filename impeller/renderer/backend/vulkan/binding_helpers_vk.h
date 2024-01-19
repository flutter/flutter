// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BINDING_HELPERS_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BINDING_HELPERS_VK_H_

#include "fml/status_or.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/compute_command.h"

namespace impeller {

// Limit on the total number of buffer and image bindings that allow the Vulkan
// backend to avoid dynamic heap allocations.
static constexpr size_t kMaxBindings = 32;

fml::StatusOr<vk::DescriptorSet> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    Allocator& allocator,
    const ComputeCommand& command,
    std::array<vk::DescriptorImageInfo, kMaxBindings>& image_workspace,
    std::array<vk::DescriptorBufferInfo, kMaxBindings>& buffer_workspace,
    std::array<vk::WriteDescriptorSet, kMaxBindings + kMaxBindings>&
        write_workspace);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BINDING_HELPERS_VK_H_
