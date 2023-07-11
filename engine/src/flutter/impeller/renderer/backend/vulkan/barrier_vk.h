// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Defines an operations and memory access barrier on a resource.
///
///             For further reading, see
///             https://www.khronos.org/events/vulkan-how-to-use-synchronisation-validation-across-multiple-queues-and-command-buffers
///             and the Vulkan spec. The docs for the various member of this
///             class are based on verbiage in the spec.
///
struct BarrierVK {
  vk::CommandBuffer cmd_buffer = {};
  vk::ImageLayout new_layout = vk::ImageLayout::eUndefined;

  // The first synchronization scope defines what operations the barrier waits
  // for to be done. In the Vulkan spec, this is usually referred to as the src
  // scope.
  vk::PipelineStageFlags src_stage = vk::PipelineStageFlagBits::eNone;

  // The first access scope defines what memory operations are guaranteed to
  // happen before the barrier. In the Vulkan spec, this is usually referred to
  // as the src scope.
  vk::AccessFlags src_access = vk::AccessFlagBits::eNone;

  // The second synchronization scope defines what operations wait for the
  // barrier to be done. In the Vulkan spec, this is usually referred to as the
  // dst scope.
  vk::PipelineStageFlags dst_stage = vk::PipelineStageFlagBits::eNone;

  // The second access scope defines what memory operations are prevented from
  // running till after the barrier. In the Vulkan spec, this is usually
  // referred to as the dst scope.
  vk::AccessFlags dst_access = vk::AccessFlagBits::eNone;
};

}  // namespace impeller
