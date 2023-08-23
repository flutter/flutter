// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>
#include <optional>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/resource_binder.h"
#include "impeller/core/sampler.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/texture.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/compute_pipeline_descriptor.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      An object used to specify compute work to the GPU along with
///             references to resources the GPU will used when doing said work.
///
///             To construct a valid command, follow these steps:
///             * Specify a valid pipeline.
///             * (Optional) Specify a debug label.
///
///             Command are very lightweight objects and can be created
///             frequently and on demand. The resources referenced in commands
///             views into buffers managed by other allocators and resource
///             managers.
///
struct ComputeCommand : public ResourceBinder {
  //----------------------------------------------------------------------------
  /// The pipeline to use for this command.
  ///
  std::shared_ptr<Pipeline<ComputePipelineDescriptor>> pipeline;
  //----------------------------------------------------------------------------
  /// The buffer, texture, and sampler bindings used by the compute pipeline
  /// stage.
  ///
  Bindings bindings;

#ifdef IMPELLER_DEBUG
  //----------------------------------------------------------------------------
  /// The debugging label to use for the command.
  ///
  std::string label;
#endif  // IMPELLER_DEBUG

  // |ResourceBinder|
  bool BindResource(ShaderStage stage,
                    const ShaderUniformSlot& slot,
                    const ShaderMetadata& metadata,
                    const BufferView& view) override;

  // |ResourceBinder|
  bool BindResource(ShaderStage stage,
                    const SampledImageSlot& slot,
                    const ShaderMetadata& metadata,
                    const std::shared_ptr<const Texture>& texture,
                    const std::shared_ptr<const Sampler>& sampler) override;

  constexpr explicit operator bool() const {
    return pipeline && pipeline->IsValid();
  }
};

}  // namespace impeller
