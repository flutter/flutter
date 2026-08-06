// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_MIPMAP_GENERATOR_H_
#define FLUTTER_IMPELLER_ENTITY_MIPMAP_GENERATOR_H_

#include "flutter/fml/status.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Records commands that regenerate the mip chain of `texture`.
///
///             Uses `BlitPass::GenerateMipmap` where the device supports it
///             and falls back to rendering the chain where the driver's blit
///             generation is broken (see
///             `Capabilities::SupportsBlitMipmapGeneration`).
///
///             Scratch render targets come from `render_target_allocator` and
///             transient geometry and uniforms come from `data_host_buffer`,
///             so frame-loop callers get buffer recycling for free.
///
[[nodiscard]] fml::Status AddMipmapGeneration(
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture,
    RenderTargetAllocator& render_target_allocator,
    HostBuffer& data_host_buffer);

//------------------------------------------------------------------------------
/// @brief      Records commands that regenerate the mip chain of `texture`
///             without blit-based generation.
///
///             Each level is drawn into a scratch offscreen by sampling the
///             previous level with a linear filter (a 2x2 box downsample)
///             and then copied into the corresponding level of `texture`.
///             Only scaled blits corrupt on affected devices; copies do not.
///
///             `AddMipmapGeneration` dispatches here when needed and is what
///             production callers use.
///
[[nodiscard]] fml::Status AddRenderPassMipmapGeneration(
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture,
    RenderTargetAllocator& render_target_allocator,
    HostBuffer& data_host_buffer);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_MIPMAP_GENERATOR_H_
