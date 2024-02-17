// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_RENDER_PASS_H_
#define FLUTTER_IMPELLER_RENDERER_RENDER_PASS_H_

#include <string>

#include "fml/status.h"
#include "impeller/core/formats.h"
#include "impeller/core/resource_binder.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class HostBuffer;
class Allocator;

//------------------------------------------------------------------------------
/// @brief      Render passes encode render commands directed as one specific
///             render target into an underlying command buffer.
///
///             Render passes can be obtained from the command buffer in which
///             the pass is meant to encode commands into.
///
/// @see        `CommandBuffer`
///
class RenderPass : public ResourceBinder {
 public:
  virtual ~RenderPass();

  const std::shared_ptr<const Context>& GetContext() const;

  const RenderTarget& GetRenderTarget() const;

  ISize GetRenderTargetSize() const;

  const Matrix& GetOrthographicTransform() const;

  virtual bool IsValid() const = 0;

  void SetLabel(std::string label);

  /// @brief Reserve [command_count] commands in the HAL command buffer.
  ///
  /// Note: this is not the native command buffer.
  virtual void ReserveCommands(size_t command_count) {
    commands_.reserve(command_count);
  }

  //----------------------------------------------------------------------------
  /// The pipeline to use for this command.
  virtual void SetPipeline(
      const std::shared_ptr<Pipeline<PipelineDescriptor>>& pipeline);

  //----------------------------------------------------------------------------
  /// The debugging label to use for the command.
  virtual void SetCommandLabel(std::string_view label);

  //----------------------------------------------------------------------------
  /// The reference value to use in stenciling operations. Stencil configuration
  /// is part of pipeline setup and can be read from the pipelines descriptor.
  ///
  /// @see         `Pipeline`
  /// @see         `PipelineDescriptor`
  ///
  virtual void SetStencilReference(uint32_t value);

  virtual void SetBaseVertex(uint64_t value);

  //----------------------------------------------------------------------------
  /// The viewport coordinates that the rasterizer linearly maps normalized
  /// device coordinates to.
  /// If unset, the viewport is the size of the render target with a zero
  /// origin, znear=0, and zfar=1.
  ///
  virtual void SetViewport(Viewport viewport);

  //----------------------------------------------------------------------------
  /// The scissor rect to use for clipping writes to the render target. The
  /// scissor rect must lie entirely within the render target.
  /// If unset, no scissor is applied.
  ///
  virtual void SetScissor(IRect scissor);

  //----------------------------------------------------------------------------
  /// The number of instances of the given set of vertices to render. Not all
  /// backends support rendering more than one instance at a time.
  ///
  /// @warning      Setting this to more than one will limit the availability of
  ///               backends to use with this command.
  ///
  virtual void SetInstanceCount(size_t count);

  //----------------------------------------------------------------------------
  /// @brief      Specify the vertex and index buffer to use for this command.
  ///
  /// @param[in]  buffer  The vertex and index buffer definition. If possible,
  ///             this value should be moved and not copied.
  ///
  /// @return     returns if the binding was updated.
  ///
  virtual bool SetVertexBuffer(VertexBuffer buffer);

  /// Record the currently pending command.
  virtual fml::Status Draw();

  // |ResourceBinder|
  virtual bool BindResource(ShaderStage stage,
                            DescriptorType type,
                            const ShaderUniformSlot& slot,
                            const ShaderMetadata& metadata,
                            BufferView view) override;

  virtual bool BindResource(
      ShaderStage stage,
      DescriptorType type,
      const ShaderUniformSlot& slot,
      const std::shared_ptr<const ShaderMetadata>& metadata,
      BufferView view);

  // |ResourceBinder|
  virtual bool BindResource(
      ShaderStage stage,
      DescriptorType type,
      const SampledImageSlot& slot,
      const ShaderMetadata& metadata,
      std::shared_ptr<const Texture> texture,
      const std::unique_ptr<const Sampler>& sampler) override;

  //----------------------------------------------------------------------------
  /// @brief      Encode the recorded commands to the underlying command buffer.
  ///
  /// @return     If the commands were encoded to the underlying command
  ///             buffer.
  ///
  bool EncodeCommands() const;

  //----------------------------------------------------------------------------
  /// @brief      Accessor for the current Commands.
  ///
  /// @details    Visible for testing.
  ///
  virtual const std::vector<Command>& GetCommands() const { return commands_; }

  //----------------------------------------------------------------------------
  /// @brief      The sample count of the attached render target.
  SampleCount GetSampleCount() const;

  //----------------------------------------------------------------------------
  /// @brief      The pixel format of the attached render target.
  PixelFormat GetRenderTargetPixelFormat() const;

  //----------------------------------------------------------------------------
  /// @brief      Whether the render target has a depth attachment.
  bool HasDepthAttachment() const;

  //----------------------------------------------------------------------------
  /// @brief      Whether the render target has an stencil attachment.
  bool HasStencilAttachment() const;

 protected:
  const std::shared_ptr<const Context> context_;
  // The following properties: sample_count, pixel_format,
  // has_stencil_attachment, and render_target_size are cached on the
  // RenderTarget to speed up numerous lookups during rendering. This is safe as
  // the RenderTarget itself is copied into the RenderTarget and only exposed as
  // a const reference.
  const SampleCount sample_count_;
  const PixelFormat pixel_format_;
  const bool has_depth_attachment_;
  const bool has_stencil_attachment_;
  const ISize render_target_size_;
  const RenderTarget render_target_;
  std::vector<Command> commands_;
  const Matrix orthographic_;

  //----------------------------------------------------------------------------
  /// @brief      Record a command for subsequent encoding to the underlying
  ///             command buffer. No work is encoded into the command buffer at
  ///             this time.
  ///
  /// @param[in]  command  The command
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  bool AddCommand(Command&& command);

  RenderPass(std::shared_ptr<const Context> context,
             const RenderTarget& target);

  virtual void OnSetLabel(std::string label) = 0;

  virtual bool OnEncodeCommands(const Context& context) const = 0;

 private:
  RenderPass(const RenderPass&) = delete;

  RenderPass& operator=(const RenderPass&) = delete;

  Command pending_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_RENDER_PASS_H_
