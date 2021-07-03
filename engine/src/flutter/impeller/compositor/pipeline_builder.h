// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/pipeline_descriptor.h"
#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A utility for creating pipelines from reflected shader
///             information.
///
/// @tparam     VertexShader_    The reflected vertex shader information. Found
///                              in a generated header file called
///                              <shader_name>.vert.h.
/// @tparam     FragmentShader_  The reflected fragment shader information.
///                              Found in a generated header file called
///                              <shader_name>.frag.h.
///
template <class VertexShader_, class FragmentShader_>
struct PipelineBuilder {
 public:
  using VertexShader = VertexShader_;
  using FragmentShader = FragmentShader_;

  static constexpr size_t kVertexBufferIndex =
      VertexDescriptor::kReservedVertexBufferIndex;

  //----------------------------------------------------------------------------
  /// @brief      Create a default pipeline descriptor using the combination
  ///             reflected shader information. The descriptor can be configured
  ///             further before a pipline state object is created using it.
  ///
  /// @param[in]  context  The context
  ///
  /// @return     If the combination of reflected shader information is
  ///             compatible and the requisite functions can be found in the
  ///             context, a pipeine descriptor.
  ///
  static std::optional<PipelineDescriptor> MakeDefaultPipelineDescriptor(
      const Context& context) {
    PipelineDescriptor desc;

    // Setup debug instrumentation.
    desc.SetLabel(SPrintF("%s Pipeline", VertexShader::kLabel.data()));

    // Resolve pipeline entrypoints.
    {
      auto vertex_function = context.GetShaderLibrary()->GetFunction(
          VertexShader::kEntrypointName, ShaderStage::kVertex);
      auto fragment_function = context.GetShaderLibrary()->GetFunction(
          FragmentShader::kEntrypointName, ShaderStage::kFragment);

      if (!vertex_function || !fragment_function) {
        FML_LOG(ERROR) << "Could not resolve pipeline entrypoint(s).";
        return std::nullopt;
      }

      desc.AddStageEntrypoint(std::move(vertex_function));
      desc.AddStageEntrypoint(std::move(fragment_function));
    }

    // Setup the vertex descriptor from reflected information.
    {
      auto vertex_descriptor = std::make_shared<VertexDescriptor>();
      if (!vertex_descriptor->SetStageInputs(
              VertexShader::kAllShaderStageInputs)) {
        FML_LOG(ERROR) << "Could not configure vertex descriptor.";
        return std::nullopt;
      }
      desc.SetVertexDescriptor(std::move(vertex_descriptor));
    }

    // Setup fragment shader output descriptions.
    {
      // Configure the sole color attachments pixel format.
      // TODO(csg): This can be easily reflected but we are sticking to the
      // convention that the first stage output is the color output.
      ColorAttachmentDescriptor color0;
      color0.format = PixelFormat::kPixelFormat_B8G8R8A8_UNormInt_SRGB;
      desc.SetColorAttachmentDescriptor(0u, std::move(color0));
    }

    // Setup depth and stencil attachment descriptions.
    {
      // Configure the stencil attachment.
      // TODO(csg): Make this configurable if possible as the D32 component is
      // wasted. This can even be moved out of the "default" descriptor
      // construction as a case can be made that this is caller responsibility.
      const auto combined_depth_stencil_format =
          PixelFormat::kPixelFormat_D32_Float_S8_UNormInt;
      desc.SetDepthPixelFormat(combined_depth_stencil_format);
      desc.SetStencilPixelFormat(combined_depth_stencil_format);
    }

    return desc;
  }
};

}  // namespace impeller
