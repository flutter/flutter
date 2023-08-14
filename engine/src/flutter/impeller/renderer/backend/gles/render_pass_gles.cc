// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/render_pass_gles.h"

#include <algorithm>

#include "flutter/fml/trace_event.h"
#include "impeller/base/config.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/formats_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {

RenderPassGLES::RenderPassGLES(std::weak_ptr<const Context> context,
                               const RenderTarget& target,
                               ReactorGLES::Ref reactor)
    : RenderPass(std::move(context), target),
      reactor_(std::move(reactor)),
      is_valid_(reactor_ && reactor_->IsValid()) {}

// |RenderPass|
RenderPassGLES::~RenderPassGLES() = default;

// |RenderPass|
bool RenderPassGLES::IsValid() const {
  return is_valid_;
}

// |RenderPass|
void RenderPassGLES::OnSetLabel(std::string label) {
  label_ = std::move(label);
}

void ConfigureBlending(const ProcTableGLES& gl,
                       const ColorAttachmentDescriptor* color) {
  if (color->blending_enabled) {
    gl.Enable(GL_BLEND);
    gl.BlendFuncSeparate(
        ToBlendFactor(color->src_color_blend_factor),  // src color
        ToBlendFactor(color->dst_color_blend_factor),  // dst color
        ToBlendFactor(color->src_alpha_blend_factor),  // src alpha
        ToBlendFactor(color->dst_alpha_blend_factor)   // dst alpha
    );
    gl.BlendEquationSeparate(
        ToBlendOperation(color->color_blend_op),  // mode color
        ToBlendOperation(color->alpha_blend_op)   // mode alpha
    );
  } else {
    gl.Disable(GL_BLEND);
  }

  {
    const auto is_set = [](std::underlying_type_t<ColorWriteMask> mask,
                           ColorWriteMask check) -> GLboolean {
      using RawType = decltype(mask);
      return (static_cast<RawType>(mask) & static_cast<RawType>(check))
                 ? GL_TRUE
                 : GL_FALSE;
    };

    gl.ColorMask(is_set(color->write_mask, ColorWriteMask::kRed),    // red
                 is_set(color->write_mask, ColorWriteMask::kGreen),  // green
                 is_set(color->write_mask, ColorWriteMask::kBlue),   // blue
                 is_set(color->write_mask, ColorWriteMask::kAlpha)   // alpha
    );
  }
}

void ConfigureStencil(GLenum face,
                      const ProcTableGLES& gl,
                      const StencilAttachmentDescriptor& stencil,
                      uint32_t stencil_reference) {
  gl.StencilOpSeparate(
      face,                                    // face
      ToStencilOp(stencil.stencil_failure),    // stencil fail
      ToStencilOp(stencil.depth_failure),      // depth fail
      ToStencilOp(stencil.depth_stencil_pass)  // depth stencil pass
  );
  gl.StencilFuncSeparate(face,                                        // face
                         ToCompareFunction(stencil.stencil_compare),  // func
                         stencil_reference,                           // ref
                         stencil.read_mask                            // mask
  );
  gl.StencilMaskSeparate(face, stencil.write_mask);
}

void ConfigureStencil(const ProcTableGLES& gl,
                      const PipelineDescriptor& pipeline,
                      uint32_t stencil_reference) {
  if (!pipeline.HasStencilAttachmentDescriptors()) {
    gl.Disable(GL_STENCIL_TEST);
    return;
  }

  gl.Enable(GL_STENCIL_TEST);
  const auto& front = pipeline.GetFrontStencilAttachmentDescriptor();
  const auto& back = pipeline.GetBackStencilAttachmentDescriptor();

  if (front.has_value() && back.has_value() && front == back) {
    ConfigureStencil(GL_FRONT_AND_BACK, gl, *front, stencil_reference);
    return;
  }
  if (front.has_value()) {
    ConfigureStencil(GL_FRONT, gl, *front, stencil_reference);
  }
  if (back.has_value()) {
    ConfigureStencil(GL_BACK, gl, *back, stencil_reference);
  }
}

//------------------------------------------------------------------------------
/// @brief      Encapsulates data that will be needed in the reactor for the
///             encoding of commands for this render pass.
///
struct RenderPassData {
  Viewport viewport;

  Color clear_color;
  uint32_t clear_stencil = 0u;
  Scalar clear_depth = 1.0;

  std::shared_ptr<Texture> color_attachment;
  std::shared_ptr<Texture> depth_attachment;
  std::shared_ptr<Texture> stencil_attachment;

  bool clear_color_attachment = true;
  bool clear_depth_attachment = true;
  bool clear_stencil_attachment = true;

  bool discard_color_attachment = true;
  bool discard_depth_attachment = true;
  bool discard_stencil_attachment = true;

  std::string label;
};

[[nodiscard]] bool EncodeCommandsInReactor(
    const RenderPassData& pass_data,
    const std::shared_ptr<Allocator>& transients_allocator,
    const ReactorGLES& reactor,
    const std::vector<Command>& commands) {
  TRACE_EVENT0("impeller", "RenderPassGLES::EncodeCommandsInReactor");

  if (commands.empty()) {
    return true;
  }

  const auto& gl = reactor.GetProcTable();

  fml::ScopedCleanupClosure pop_pass_debug_marker(
      [&gl]() { gl.PopDebugGroup(); });
  if (!pass_data.label.empty()) {
    gl.PushDebugGroup(pass_data.label);
  } else {
    pop_pass_debug_marker.Release();
  }

  GLuint fbo = GL_NONE;
  fml::ScopedCleanupClosure delete_fbo([&gl, &fbo]() {
    if (fbo != GL_NONE) {
      gl.BindFramebuffer(GL_FRAMEBUFFER, GL_NONE);
      gl.DeleteFramebuffers(1u, &fbo);
    }
  });

  const auto is_default_fbo =
      TextureGLES::Cast(*pass_data.color_attachment).IsWrapped();

  if (!is_default_fbo) {
    // Create and bind an offscreen FBO.
    gl.GenFramebuffers(1u, &fbo);
    gl.BindFramebuffer(GL_FRAMEBUFFER, fbo);

    if (auto color = TextureGLES::Cast(pass_data.color_attachment.get())) {
      if (!color->SetAsFramebufferAttachment(
              GL_FRAMEBUFFER, fbo, TextureGLES::AttachmentPoint::kColor0)) {
        return false;
      }
    }
    if (auto depth = TextureGLES::Cast(pass_data.depth_attachment.get())) {
      if (!depth->SetAsFramebufferAttachment(
              GL_FRAMEBUFFER, fbo, TextureGLES::AttachmentPoint::kDepth)) {
        return false;
      }
    }
    if (auto stencil = TextureGLES::Cast(pass_data.stencil_attachment.get())) {
      if (!stencil->SetAsFramebufferAttachment(
              GL_FRAMEBUFFER, fbo, TextureGLES::AttachmentPoint::kStencil)) {
        return false;
      }
    }

    if (gl.CheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
      VALIDATION_LOG << "Could not create a complete frambuffer.";
      return false;
    }
  }

  gl.ClearColor(pass_data.clear_color.red,    // red
                pass_data.clear_color.green,  // green
                pass_data.clear_color.blue,   // blue
                pass_data.clear_color.alpha   // alpha
  );
  if (pass_data.depth_attachment) {
    gl.ClearDepthf(pass_data.clear_depth);
  }
  if (pass_data.stencil_attachment) {
    gl.ClearStencil(pass_data.clear_stencil);
  }

  GLenum clear_bits = 0u;
  if (pass_data.clear_color_attachment) {
    clear_bits |= GL_COLOR_BUFFER_BIT;
  }
  if (pass_data.clear_depth_attachment) {
    clear_bits |= GL_DEPTH_BUFFER_BIT;
  }
  if (pass_data.clear_stencil_attachment) {
    clear_bits |= GL_STENCIL_BUFFER_BIT;
  }

  gl.Disable(GL_SCISSOR_TEST);
  gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_STENCIL_TEST);
  gl.Disable(GL_CULL_FACE);
  gl.Disable(GL_BLEND);
  gl.ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

  gl.Clear(clear_bits);

  for (const auto& command : commands) {
    if (command.instance_count != 1u) {
      VALIDATION_LOG << "GLES backend does not support instanced rendering.";
      return false;
    }

    if (!command.pipeline) {
      VALIDATION_LOG << "Command has no pipeline specified.";
      return false;
    }

#ifdef IMPELLER_DEBUG
    fml::ScopedCleanupClosure pop_cmd_debug_marker(
        [&gl]() { gl.PopDebugGroup(); });
    if (!command.label.empty()) {
      gl.PushDebugGroup(command.label);
    } else {
      pop_cmd_debug_marker.Release();
    }
#endif  // IMPELLER_DEBUG

    const auto& pipeline = PipelineGLES::Cast(*command.pipeline);

    const auto* color_attachment =
        pipeline.GetDescriptor().GetLegacyCompatibleColorAttachment();
    if (!color_attachment) {
      VALIDATION_LOG
          << "Color attachment is too complicated for a legacy renderer.";
      return false;
    }

    //--------------------------------------------------------------------------
    /// Configure blending.
    ///
    ConfigureBlending(gl, color_attachment);

    //--------------------------------------------------------------------------
    /// Setup stencil.
    ///
    ConfigureStencil(gl, pipeline.GetDescriptor(), command.stencil_reference);

    //--------------------------------------------------------------------------
    /// Configure depth.
    ///
    if (auto depth =
            pipeline.GetDescriptor().GetDepthStencilAttachmentDescriptor();
        depth.has_value()) {
      gl.Enable(GL_DEPTH_TEST);
      gl.DepthFunc(ToCompareFunction(depth->depth_compare));
      gl.DepthMask(depth->depth_write_enabled ? GL_TRUE : GL_FALSE);
    } else {
      gl.Disable(GL_DEPTH_TEST);
    }

    // Both the viewport and scissor are specified in framebuffer coordinates.
    // Impeller's framebuffer coordinate system is top left origin, but OpenGL's
    // is bottom left origin, so we convert the coordinates here.
    auto target_size = pass_data.color_attachment->GetSize();

    //--------------------------------------------------------------------------
    /// Setup the viewport.
    ///
    const auto& viewport = command.viewport.value_or(pass_data.viewport);
    gl.Viewport(viewport.rect.origin.x,  // x
                target_size.height - viewport.rect.origin.y -
                    viewport.rect.size.height,  // y
                viewport.rect.size.width,       // width
                viewport.rect.size.height       // height
    );
    if (pass_data.depth_attachment) {
      gl.DepthRangef(viewport.depth_range.z_near, viewport.depth_range.z_far);
    }

    //--------------------------------------------------------------------------
    /// Setup the scissor rect.
    ///
    if (command.scissor.has_value()) {
      const auto& scissor = command.scissor.value();
      gl.Enable(GL_SCISSOR_TEST);
      gl.Scissor(
          scissor.origin.x,                                             // x
          target_size.height - scissor.origin.y - scissor.size.height,  // y
          scissor.size.width,                                           // width
          scissor.size.height  // height
      );
    } else {
      gl.Disable(GL_SCISSOR_TEST);
    }

    //--------------------------------------------------------------------------
    /// Setup culling.
    ///
    switch (pipeline.GetDescriptor().GetCullMode()) {
      case CullMode::kNone:
        gl.Disable(GL_CULL_FACE);
        break;
      case CullMode::kFrontFace:
        gl.Enable(GL_CULL_FACE);
        gl.CullFace(GL_FRONT);
        break;
      case CullMode::kBackFace:
        gl.Enable(GL_CULL_FACE);
        gl.CullFace(GL_BACK);
        break;
    }
    //--------------------------------------------------------------------------
    /// Setup winding order.
    ///
    switch (pipeline.GetDescriptor().GetWindingOrder()) {
      case WindingOrder::kClockwise:
        gl.FrontFace(GL_CW);
        break;
      case WindingOrder::kCounterClockwise:
        gl.FrontFace(GL_CCW);
        break;
    }

    if (command.index_type == IndexType::kUnknown) {
      return false;
    }

    const auto& vertex_desc_gles = pipeline.GetBufferBindings();

    //--------------------------------------------------------------------------
    /// Bind vertex and index buffers.
    ///
    auto vertex_buffer_view = command.GetVertexBuffer();

    if (!vertex_buffer_view) {
      return false;
    }

    auto vertex_buffer =
        vertex_buffer_view.buffer->GetDeviceBuffer(*transients_allocator);

    if (!vertex_buffer) {
      return false;
    }

    const auto& vertex_buffer_gles = DeviceBufferGLES::Cast(*vertex_buffer);
    if (!vertex_buffer_gles.BindAndUploadDataIfNecessary(
            DeviceBufferGLES::BindingType::kArrayBuffer)) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Bind the pipeline program.
    ///
    if (!pipeline.BindProgram()) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Bind vertex attribs.
    ///
    if (!vertex_desc_gles->BindVertexAttributes(
            gl, vertex_buffer_view.range.offset)) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Bind uniform data.
    ///
    if (!vertex_desc_gles->BindUniformData(gl,                        //
                                           *transients_allocator,     //
                                           command.vertex_bindings,   //
                                           command.fragment_bindings  //
                                           )) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Determine the primitive type.
    ///
    // GLES doesn't support setting the fill mode, so override the primitive
    // with GL_LINE_STRIP to somewhat emulate PolygonMode::kLine. This isn't
    // correct; full triangle outlines won't be drawn and disconnected
    // geometry may appear connected. However this can still be useful for
    // wireframe debug views.
    auto mode = pipeline.GetDescriptor().GetPolygonMode() == PolygonMode::kLine
                    ? GL_LINE_STRIP
                    : ToMode(pipeline.GetDescriptor().GetPrimitiveType());

    //--------------------------------------------------------------------------
    /// Finally! Invoke the draw call.
    ///
    if (command.index_type == IndexType::kNone) {
      gl.DrawArrays(mode, command.base_vertex, command.vertex_count);
    } else {
      // Bind the index buffer if necessary.
      auto index_buffer_view = command.index_buffer;
      auto index_buffer =
          index_buffer_view.buffer->GetDeviceBuffer(*transients_allocator);
      const auto& index_buffer_gles = DeviceBufferGLES::Cast(*index_buffer);
      if (!index_buffer_gles.BindAndUploadDataIfNecessary(
              DeviceBufferGLES::BindingType::kElementArrayBuffer)) {
        return false;
      }
      gl.DrawElements(mode,                             // mode
                      command.vertex_count,             // count
                      ToIndexType(command.index_type),  // type
                      reinterpret_cast<const GLvoid*>(static_cast<GLsizei>(
                          index_buffer_view.range.offset))  // indices
      );
    }

    //--------------------------------------------------------------------------
    /// Unbind vertex attribs.
    ///
    if (!vertex_desc_gles->UnbindVertexAttributes(gl)) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Unbind the program pipeline.
    ///
    if (!pipeline.UnbindProgram()) {
      return false;
    }
  }

  if (gl.DiscardFramebufferEXT.IsAvailable()) {
    std::vector<GLenum> attachments;

    if (pass_data.discard_color_attachment) {
      attachments.push_back(is_default_fbo ? GL_COLOR_EXT
                                           : GL_COLOR_ATTACHMENT0);
    }
    if (pass_data.discard_depth_attachment) {
      attachments.push_back(is_default_fbo ? GL_DEPTH_EXT
                                           : GL_DEPTH_ATTACHMENT);
    }

// TODO(jonahwilliams): discarding the stencil on the default fbo when running
// on Windows causes Angle to discard the entire render target. Until we know
// the reason, default to storing.
#ifdef FML_OS_WIN
    if (pass_data.discard_stencil_attachment && !is_default_fbo) {
#else
    if (pass_data.discard_stencil_attachment) {
#endif
      attachments.push_back(is_default_fbo ? GL_STENCIL_EXT
                                           : GL_STENCIL_ATTACHMENT);
    }
    gl.DiscardFramebufferEXT(GL_FRAMEBUFFER,      // target
                             attachments.size(),  // attachments to discard
                             attachments.data()   // size
    );
  }

  return true;
}

// |RenderPass|
bool RenderPassGLES::OnEncodeCommands(const Context& context) const {
  if (!IsValid()) {
    return false;
  }
  if (commands_.empty()) {
    return true;
  }
  const auto& render_target = GetRenderTarget();
  if (!render_target.HasColorAttachment(0u)) {
    return false;
  }
  const auto& color0 = render_target.GetColorAttachments().at(0u);
  const auto& depth0 = render_target.GetDepthAttachment();
  const auto& stencil0 = render_target.GetStencilAttachment();

  auto pass_data = std::make_shared<RenderPassData>();
  pass_data->label = label_;
  pass_data->viewport.rect = Rect::MakeSize(GetRenderTargetSize());

  //----------------------------------------------------------------------------
  /// Setup color data.
  ///
  pass_data->color_attachment = color0.texture;
  pass_data->clear_color = color0.clear_color;
  pass_data->clear_color_attachment = CanClearAttachment(color0.load_action);
  pass_data->discard_color_attachment =
      CanDiscardAttachmentWhenDone(color0.store_action);

  //----------------------------------------------------------------------------
  /// Setup depth data.
  ///
  if (depth0.has_value()) {
    pass_data->depth_attachment = depth0->texture;
    pass_data->clear_depth = depth0->clear_depth;
    pass_data->clear_depth_attachment = CanClearAttachment(depth0->load_action);
    pass_data->discard_depth_attachment =
        CanDiscardAttachmentWhenDone(depth0->store_action);
  }

  //----------------------------------------------------------------------------
  /// Setup depth data.
  ///
  if (stencil0.has_value()) {
    pass_data->stencil_attachment = stencil0->texture;
    pass_data->clear_stencil = stencil0->clear_stencil;
    pass_data->clear_stencil_attachment =
        CanClearAttachment(stencil0->load_action);
    pass_data->discard_stencil_attachment =
        CanDiscardAttachmentWhenDone(stencil0->store_action);
  }

  std::shared_ptr<const RenderPassGLES> shared_this = shared_from_this();
  return reactor_->AddOperation([pass_data,
                                 allocator = context.GetResourceAllocator(),
                                 render_pass = std::move(shared_this)](
                                    const auto& reactor) {
    auto result = EncodeCommandsInReactor(*pass_data, allocator, reactor,
                                          render_pass->commands_);
    FML_CHECK(result) << "Must be able to encode GL commands without error.";
  });
}

}  // namespace impeller
