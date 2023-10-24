// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "fml/status_or.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/compute_command.h"

namespace impeller {

fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    const std::vector<Command>& commands);

fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    const std::vector<ComputeCommand>& commands);

}  // namespace impeller
