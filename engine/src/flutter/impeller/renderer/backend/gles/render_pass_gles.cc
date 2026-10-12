// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/render_pass_gles.h"

#include <cstdint>
#include <optional>
#include <tuple>
#include <utility>

#include "flutter/fml/trace_event.h"
#include "fml/closure.h"
#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/buffer_bindings_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/formats_gles.h"
#include "impeller/renderer/backend/gles/gpu_tracer_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/command.h"

namespace impeller {

RenderPassGLES::RenderPassGLES(std::shared_ptr<const Context> context,
                               const RenderTarget& target,
                               std::shared_ptr<ReactorGLES> reactor)
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
void RenderPassGLES::OnSetLabel(std::string_view label) {
  label_ = label;
}

namespace {

struct BlendStateCache {
  bool blending_enabled = false;
  ColorWriteMask write_mask = ColorWriteMaskBits::kAll;
  std::optional<std::tuple<BlendFactor, BlendFactor, BlendFactor, BlendFactor>>
      blend_factors;
  std::optional<std::pair<BlendOperation, BlendOperation>> blend_ops;

  void Configure(const ProcTableGLES& gl,
                 const ColorAttachmentDescriptor* color) {
    if (color->blending_enabled) {
      if (!blending_enabled) {
        gl.Enable(GL_BLEND);
        blending_enabled = true;
      }
      const auto factors = std::make_tuple(
          color->src_color_blend_factor, color->dst_color_blend_factor,
          color->src_alpha_blend_factor, color->dst_alpha_blend_factor);
      if (blend_factors != factors) {
        gl.BlendFuncSeparate(
            ToBlendFactor(color->src_color_blend_factor),  // src color
            ToBlendFactor(color->dst_color_blend_factor),  // dst color
            ToBlendFactor(color->src_alpha_blend_factor),  // src alpha
            ToBlendFactor(color->dst_alpha_blend_factor)   // dst alpha
        );
        blend_factors = factors;
      }
      const auto ops =
          std::make_pair(color->color_blend_op, color->alpha_blend_op);
      if (blend_ops != ops) {
        gl.BlendEquationSeparate(
            ToBlendOperation(color->color_blend_op),  // mode color
            ToBlendOperation(color->alpha_blend_op)   // mode alpha
        );
        blend_ops = ops;
      }
    } else if (blending_enabled) {
      gl.Disable(GL_BLEND);
      blending_enabled = false;
    }

    if (write_mask != color->write_mask) {
      const auto is_set = [](ColorWriteMask mask,
                             ColorWriteMask check) -> GLboolean {
        return (mask & check) ? GL_TRUE : GL_FALSE;
      };

      gl.ColorMask(
          is_set(color->write_mask, ColorWriteMaskBits::kRed),    // red
          is_set(color->write_mask, ColorWriteMaskBits::kGreen),  // green
          is_set(color->write_mask, ColorWriteMaskBits::kBlue),   // blue
          is_set(color->write_mask, ColorWriteMaskBits::kAlpha)   // alpha
      );
      write_mask = color->write_mask;
    }
  }
};

struct StencilFaceStateCache {
  std::optional<
      std::tuple<StencilOperation, StencilOperation, StencilOperation>>
      ops;
  std::optional<std::tuple<CompareFunction, uint32_t, uint32_t>> func;
  uint32_t write_mask = 0xFFFFFFFF;

  void Configure(GLenum face,
                 const ProcTableGLES& gl,
                 const StencilAttachmentDescriptor& stencil,
                 uint32_t stencil_reference) {
    const auto new_ops =
        std::make_tuple(stencil.stencil_failure, stencil.depth_failure,
                        stencil.depth_stencil_pass);
    if (ops != new_ops) {
      gl.StencilOpSeparate(
          face,                                    // face
          ToStencilOp(stencil.stencil_failure),    // stencil fail
          ToStencilOp(stencil.depth_failure),      // depth fail
          ToStencilOp(stencil.depth_stencil_pass)  // depth stencil pass
      );
      ops = new_ops;
    }
    const auto new_func = std::make_tuple(stencil.stencil_compare,
                                          stencil_reference, stencil.read_mask);
    if (func != new_func) {
      gl.StencilFuncSeparate(
          face,                                        // face
          ToCompareFunction(stencil.stencil_compare),  // func
          stencil_reference,                           // ref
          stencil.read_mask                            // mask
      );
      func = new_func;
    }
    if (write_mask != stencil.write_mask) {
      gl.StencilMaskSeparate(face, stencil.write_mask);
      write_mask = stencil.write_mask;
    }
  }
};

struct StencilStateCache {
  bool stencil_test_enabled = false;
  StencilFaceStateCache front;
  StencilFaceStateCache back;

  void Configure(const ProcTableGLES& gl,
                 const PipelineDescriptor& pipeline,
                 uint32_t stencil_reference) {
    if (!pipeline.HasStencilAttachmentDescriptors()) {
      if (stencil_test_enabled) {
        gl.Disable(GL_STENCIL_TEST);
        stencil_test_enabled = false;
      }
      return;
    }

    if (!stencil_test_enabled) {
      gl.Enable(GL_STENCIL_TEST);
      stencil_test_enabled = true;
    }
    const auto& front_desc = pipeline.GetFrontStencilAttachmentDescriptor();
    const auto& back_desc = pipeline.GetBackStencilAttachmentDescriptor();

    if (front_desc.has_value() && back_desc.has_value() &&
        front_desc == back_desc && front.ops == back.ops &&
        front.func == back.func && front.write_mask == back.write_mask) {
      front.Configure(GL_FRONT_AND_BACK, gl, *front_desc, stencil_reference);
      back = front;
      return;
    }
    if (front_desc.has_value()) {
      front.Configure(GL_FRONT, gl, *front_desc, stencil_reference);
    }
    if (back_desc.has_value()) {
      back.Configure(GL_BACK, gl, *back_desc, stencil_reference);
    }
  }
};

struct DepthStateCache {
  bool depth_test_enabled = false;
  std::optional<CompareFunction> depth_compare;
  bool depth_write_enabled = true;

  void Configure(const ProcTableGLES& gl,
                 const std::optional<DepthAttachmentDescriptor>& depth) {
    if (depth.has_value()) {
      if (!depth_test_enabled) {
        gl.Enable(GL_DEPTH_TEST);
        depth_test_enabled = true;
      }
      if (depth_compare != depth->depth_compare) {
        gl.DepthFunc(ToCompareFunction(depth->depth_compare));
        depth_compare = depth->depth_compare;
      }
      if (depth_write_enabled != depth->depth_write_enabled) {
        gl.DepthMask(depth->depth_write_enabled ? GL_TRUE : GL_FALSE);
        depth_write_enabled = depth->depth_write_enabled;
      }
    } else if (depth_test_enabled) {
      gl.Disable(GL_DEPTH_TEST);
      depth_test_enabled = false;
    }
  }
};

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
  std::shared_ptr<Texture> resolve_attachment;
  std::shared_ptr<Texture> depth_attachment;
  std::shared_ptr<Texture> stencil_attachment;

  // The subresource of each attachment to render into.
  uint32_t color_mip_level = 0u;
  uint32_t color_slice = 0u;
  uint32_t depth_mip_level = 0u;
  uint32_t depth_slice = 0u;
  uint32_t stencil_mip_level = 0u;
  uint32_t stencil_slice = 0u;

  bool clear_color_attachment = true;
  bool clear_depth_attachment = true;
  bool clear_stencil_attachment = true;

  bool discard_color_attachment = true;
  bool discard_depth_attachment = true;
  bool discard_stencil_attachment = true;

  std::string label;
};

struct RenderPassStateCache {
  std::optional<Viewport> viewport;
  std::optional<IRect32> scissor;
  BlendStateCache blend;
  StencilStateCache stencil;
  DepthStateCache depth;
  std::optional<HandleGLES> program;
  CullMode cull_mode = CullMode::kNone;
  WindingOrder winding_order = WindingOrder::kClockwise;

  void ConfigureBlending(const ProcTableGLES& gl,
                         const ColorAttachmentDescriptor* color) {
    blend.Configure(gl, color);
  }

  void ConfigureStencil(const ProcTableGLES& gl,
                        const PipelineDescriptor& pipeline,
                        uint32_t stencil_reference) {
    stencil.Configure(gl, pipeline, stencil_reference);
  }

  void ConfigureDepth(
      const ProcTableGLES& gl,
      const std::optional<DepthAttachmentDescriptor>& depth_desc) {
    depth.Configure(gl, depth_desc);
  }

  void ConfigureViewport(const ProcTableGLES& gl,
                         const RenderPassData& pass_data,
                         const std::optional<Viewport>& command_viewport,
                         const ISize& target_size,
                         bool flip_y) {
    auto new_viewport = command_viewport.value_or(pass_data.viewport);

    if (viewport.has_value() && viewport.value() == new_viewport) {
      // The viewport is the same as the last command. Skip an unnecessary call.
      return;
    }

    viewport = new_viewport;

    // FBO passes flip in the vertex shader; swapchain keeps the old
    // top-down -> bottom-up viewport conversion.
    const auto viewport_y_gl = flip_y ? new_viewport.rect.GetY()
                                      : target_size.height -
                                            new_viewport.rect.GetY() -
                                            new_viewport.rect.GetHeight();
    gl.Viewport(new_viewport.rect.GetX(),  // x
                viewport_y_gl,             // y
                new_viewport.rect.GetWidth(), new_viewport.rect.GetHeight());
    if (pass_data.depth_attachment) {
      if (gl.DepthRangef.IsAvailable()) {
        gl.DepthRangef(new_viewport.depth_range.z_near,
                       new_viewport.depth_range.z_far);
      } else {
        gl.DepthRange(new_viewport.depth_range.z_near,
                      new_viewport.depth_range.z_far);
      }
    }
  }

  // Note: RenderPass::SetScissor only populates pending_.scissor for the next
  // Draw() call (which moves pending_ into commands_ and resets pending_).
  // Subsequent Draw() calls within the same clip scope have
  // command_scissor == std::nullopt, meaning the active scissor rect remains
  // unchanged (matching Metal and Vulkan; see flutter/engine#56494).
  void ConfigureScissor(const ProcTableGLES& gl,
                        const std::optional<IRect32>& command_scissor,
                        const ISize& target_size,
                        bool flip_y) {
    if (!command_scissor.has_value() || scissor == command_scissor) {
      return;
    }
    const auto& new_scissor = command_scissor.value();
    if (!scissor.has_value()) {
      gl.Enable(GL_SCISSOR_TEST);
    }
    // Same flip handling as the viewport above.
    const auto scissor_y_gl = flip_y ? new_scissor.GetY()
                                     : target_size.height - new_scissor.GetY() -
                                           new_scissor.GetHeight();
    gl.Scissor(new_scissor.GetX(),  // x
               scissor_y_gl,        // y
               new_scissor.GetWidth(), new_scissor.GetHeight());
    scissor = new_scissor;
  }

  void ConfigureCullMode(const ProcTableGLES& gl, CullMode pipeline_cull_mode) {
    if (cull_mode == pipeline_cull_mode) {
      return;
    }
    switch (pipeline_cull_mode) {
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
    cull_mode = pipeline_cull_mode;
  }

  void ConfigureWindingOrder(const ProcTableGLES& gl,
                             WindingOrder pipeline_winding_order,
                             bool flip_y) {
    if (winding_order == pipeline_winding_order) {
      return;
    }
    switch (pipeline_winding_order) {
      case WindingOrder::kClockwise:
        gl.FrontFace(flip_y ? GL_CCW : GL_CW);
        break;
      case WindingOrder::kCounterClockwise:
        gl.FrontFace(flip_y ? GL_CW : GL_CCW);
        break;
    }
    winding_order = pipeline_winding_order;
  }

  [[nodiscard]] bool BindProgram(const ProcTableGLES& gl,
                                 const PipelineGLES& pipeline,
                                 float y_flip_value) {
    // HandleGLES::Equal compares HandleGLES::name_, which is a monotonically
    // increasing 64-bit UniqueID (impeller/base/comparable.cc), not a raw
    // OpenGL GLuint that could be recycled by the driver. In addition, each
    // Command in the pass holds a strong PipelineRef keeping its
    // UniqueHandleGLES alive for the entire pass.
    const HandleGLES& program_handle = pipeline.GetProgramHandle();
    if (program.has_value() && HandleGLES::Equal{}(*program, program_handle)) {
      return true;
    }
    if (!pipeline.BindProgram()) {
      return false;
    }

    // Bind the y-flip uniform if the vertex shader declares it.
    const GLint y_flip_loc = pipeline.GetYFlipUniformLocation();
    if (y_flip_loc >= 0) {
      gl.Uniform1fv(y_flip_loc, 1, &y_flip_value);
    }

    program = program_handle;
    return true;
  }
};

}  // namespace

static bool BindVertexBuffer(const ProcTableGLES& gl,
                             BufferBindingsGLES* vertex_desc_gles,
                             const BufferView& vertex_buffer_view,
                             size_t buffer_index,
                             size_t instance = 0) {
  if (!vertex_buffer_view) {
    return false;
  }

  const DeviceBuffer* vertex_buffer = vertex_buffer_view.GetBuffer();

  if (!vertex_buffer) {
    return false;
  }

  const auto& vertex_buffer_gles = DeviceBufferGLES::Cast(*vertex_buffer);
  if (!vertex_buffer_gles.BindAndUploadDataIfNecessary(
          DeviceBufferGLES::BindingType::kArrayBuffer)) {
    return false;
  }

  //--------------------------------------------------------------------------
  /// Bind the vertex attributes associated with vertex buffer.
  ///
  if (!vertex_desc_gles->BindVertexAttributes(
          gl, buffer_index, vertex_buffer_view.GetRange().offset, instance)) {
    return false;
  }

  return true;
}

void RenderPassGLES::ResetGLState(const ProcTableGLES& gl) {
  gl.Disable(GL_SCISSOR_TEST);
  gl.Disable(GL_DEPTH_TEST);
  gl.Disable(GL_STENCIL_TEST);
  gl.Disable(GL_CULL_FACE);
  gl.Disable(GL_BLEND);
  gl.Disable(GL_DITHER);
  gl.ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  gl.DepthMask(GL_TRUE);
  gl.StencilMaskSeparate(GL_FRONT, 0xFFFFFFFF);
  gl.StencilMaskSeparate(GL_BACK, 0xFFFFFFFF);
}

[[nodiscard]] bool EncodeCommandsInReactor(
    const RenderPassData& pass_data,
    const ReactorGLES& reactor,
    const std::vector<Command>& commands,
    const std::vector<BufferView>& vertex_buffers,
    const std::vector<TextureAndSampler>& bound_textures,
    const std::vector<BufferResource>& bound_buffers,
    const std::shared_ptr<GPUTracerGLES>& tracer,
    const std::shared_ptr<const Context>& impeller_context) {
  TRACE_EVENT0("impeller", "RenderPassGLES::EncodeCommandsInReactor");

  const auto& gl = reactor.GetProcTable();
#ifdef IMPELLER_DEBUG
  tracer->MarkFrameStart(gl);

  fml::ScopedCleanupClosure pop_pass_debug_marker(
      [&gl]() { gl.PopDebugGroup(); });
  if (!pass_data.label.empty()) {
    gl.PushDebugGroup(pass_data.label);
  } else {
    pop_pass_debug_marker.Release();
  }
#endif  // IMPELLER_DEBUG

  TextureGLES& color_gles = TextureGLES::Cast(*pass_data.color_attachment);
  const bool is_wrapped_fbo = color_gles.IsWrapped();

  std::optional<GLuint> fbo = 0;
  if (is_wrapped_fbo) {
    if (color_gles.GetFBO().has_value()) {
      // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
      gl.BindFramebuffer(GL_FRAMEBUFFER, *color_gles.GetFBO());
    }
  } else {
    // Create (once) and bind an offscreen FBO. The cached FBO remembers which
    // subresource it is bound to, so it is re-attached only when freshly
    // created or when rendering into a different mip level or slice of the
    // same texture.
    bool needs_attachment = false;
    if (color_gles.GetCachedFBO().IsDead()) {
      color_gles.SetCachedFBO(
          reactor.CreateUntrackedHandle(HandleType::kFrameBuffer));
      needs_attachment = true;
    }
    fbo = reactor.GetGLHandle(color_gles.GetCachedFBO());
    if (!fbo.has_value()) {
      return false;
    }
    gl.BindFramebuffer(GL_FRAMEBUFFER, fbo.value());

    if (needs_attachment ||
        !color_gles.CachedFBOMatchesSubresource(pass_data.color_mip_level,
                                                pass_data.color_slice)) {
      if (!color_gles.SetAsFramebufferAttachment(
              GL_FRAMEBUFFER, TextureGLES::AttachmentType::kColor0,
              pass_data.color_mip_level, pass_data.color_slice)) {
        return false;
      }

      if (auto depth = TextureGLES::Cast(pass_data.depth_attachment.get())) {
        if (!depth->SetAsFramebufferAttachment(
                GL_FRAMEBUFFER, TextureGLES::AttachmentType::kDepth,
                pass_data.depth_mip_level, pass_data.depth_slice)) {
          return false;
        }
      }
      if (auto stencil =
              TextureGLES::Cast(pass_data.stencil_attachment.get())) {
        if (!stencil->SetAsFramebufferAttachment(
                GL_FRAMEBUFFER, TextureGLES::AttachmentType::kStencil,
                pass_data.stencil_mip_level, pass_data.stencil_slice)) {
          return false;
        }
      }

      auto status = gl.CheckFramebufferStatusDebug(GL_FRAMEBUFFER);
      if (status != GL_FRAMEBUFFER_COMPLETE) {
        VALIDATION_LOG << "Could not create a complete framebuffer: "
                       << DebugToFramebufferError(status);
        return false;
      }
      color_gles.SetCachedFBOSubresource(pass_data.color_mip_level,
                                         pass_data.color_slice);
    }
  }

  gl.ClearColor(pass_data.clear_color.red,    // red
                pass_data.clear_color.green,  // green
                pass_data.clear_color.blue,   // blue
                pass_data.clear_color.alpha   // alpha
  );
  if (pass_data.depth_attachment) {
    if (gl.DepthRangef.IsAvailable()) {
      gl.ClearDepthf(pass_data.clear_depth);
    } else {
      gl.ClearDepth(pass_data.clear_depth);
    }
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

  RenderPassGLES::ResetGLState(gl);

  gl.Clear(clear_bits);

  // Both the viewport and scissor are specified in framebuffer coordinates.
  // Impeller's framebuffer coordinate system is top left origin, but OpenGL's
  // is bottom left origin, so we convert the coordinates here.
  ISize target_size = pass_data.color_attachment->GetSize();

  // Offscreen (non-wrapped) FBOs always flip in the vertex shader so they are
  // stored with a top-left origin, matching Impeller's coordinate system. See
  // https://github.com/flutter/flutter/issues/186554.
  //
  // Wrapped FBOs match the embedder's default framebuffer origin:
  // - Bottom-left (the OpenGL default): no flip.
  // - Top-left (currently only the Windows embedder, via ANGLE's
  //   EGL_SURFACE_ORIENTATION_INVERT_Y_ANGLE): flip, like offscreen FBOs.
  //   The whole pipeline is then in one orientation, so the blit that
  //   presents a wrapped framebuffer to the swapchain is a straight 1:1 copy,
  //   which lets the driver resolve or DMA it instead of running a
  //   full-screen shader pass to flip it.
  const bool top_left_default_framebuffer_origin =
      ContextGLES::Cast(*impeller_context).HasTopLeftDefaultFramebufferOrigin();
  const bool flip_y = !is_wrapped_fbo || top_left_default_framebuffer_origin;
  const float y_flip_value = flip_y ? -1.0f : 1.0f;

  RenderPassStateCache state_cache;
  // Inverted to keep front-facing consistent under the vertex y-flip.
  gl.FrontFace(flip_y ? GL_CCW : GL_CW);

  for (const auto& command : commands) {
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
    impeller_context->GetPipelineLibrary()->LogPipelineUsage(
        pipeline.GetDescriptor());
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
    state_cache.ConfigureBlending(gl, color_attachment);

    //--------------------------------------------------------------------------
    /// Setup stencil.
    ///
    state_cache.ConfigureStencil(gl, pipeline.GetDescriptor(),
                                 command.stencil_reference);

    //--------------------------------------------------------------------------
    /// Configure depth.
    ///
    state_cache.ConfigureDepth(
        gl, pipeline.GetDescriptor().GetDepthStencilAttachmentDescriptor());

    //--------------------------------------------------------------------------
    /// Setup the viewport.
    ///
    state_cache.ConfigureViewport(gl, pass_data, command.viewport, target_size,
                                  flip_y);

    //--------------------------------------------------------------------------
    /// Setup the scissor rect.
    ///
    state_cache.ConfigureScissor(gl, command.scissor, target_size, flip_y);

    //--------------------------------------------------------------------------
    /// Setup culling.
    ///
    state_cache.ConfigureCullMode(gl, pipeline.GetDescriptor().GetCullMode());

    //--------------------------------------------------------------------------
    /// Setup winding order. The pipeline's winding is inverted when
    /// `flip_y` is in effect (the vertex flip reverses the rasterizer's
    /// view of winding).
    state_cache.ConfigureWindingOrder(
        gl, pipeline.GetDescriptor().GetWindingOrder(), flip_y);

    BufferBindingsGLES* vertex_desc_gles = pipeline.GetBufferBindings();

    //--------------------------------------------------------------------------
    /// Bind vertex buffers.
    ///
    /// Note: There is no need to run `RenderPass::ValidateVertexBuffers` or
    ///       `RenderPass::ValidateIndexBuffer` here, as validation already runs
    ///       when the vertex/index buffers are set on the command.
    ///
    for (size_t i = 0; i < command.vertex_buffers.length; i++) {
      if (!BindVertexBuffer(gl, vertex_desc_gles,
                            vertex_buffers[i + command.vertex_buffers.offset],
                            i)) {
        return false;
      }
    }

    //--------------------------------------------------------------------------
    /// Bind the pipeline program.
    ///
    if (!state_cache.BindProgram(gl, pipeline, y_flip_value)) {
      return false;
    }

    //--------------------------------------------------------------------------
    /// Bind uniform data.
    ///
    if (!vertex_desc_gles->BindUniformData(
            gl,                                        //
            bound_textures,                            //
            bound_buffers,                             //
            /*texture_range=*/command.bound_textures,  //
            /*buffer_range=*/command.bound_buffers     //
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
    GLenum mode =
        pipeline.GetDescriptor().GetPolygonMode() == PolygonMode::kLine
            ? GL_LINE_STRIP
            : ToMode(pipeline.GetDescriptor().GetPrimitiveType());

    //--------------------------------------------------------------------------
    /// Finally! Invoke the draw call.
    ///
    /// An instanced draw uses the hardware instanced entry points when the
    /// driver exposes them (ES 3.0 core, or GL_EXT_instanced_arrays on ES
    /// 2.0). When it does not, the draw is emulated by repeating it once per
    /// instance, re-pointing the instance-rate vertex attributes at each
    /// instance in between.
    ///
    const bool instanced = command.instance_count > 1u;
    const bool hardware_instanced =
        instanced &&
        (gl.DrawArraysInstanced.IsAvailable() ||
         gl.DrawArraysInstancedEXT.IsAvailable()) &&
        (gl.DrawElementsInstanced.IsAvailable() ||
         gl.DrawElementsInstancedEXT.IsAvailable()) &&
        (gl.VertexAttribDivisor.IsAvailable() ||
         gl.VertexAttribDivisorEXT.IsAvailable());
    const bool emulate_instanced = instanced && !hardware_instanced;
    const GLsizei instance_count = static_cast<GLsizei>(command.instance_count);

    // A draw is indexed only when a real index type was set. A command that
    // never bound an index buffer leaves `index_type` at its `kUnknown`
    // default, which must be treated as non-indexed (matching the Metal and
    // Vulkan backends, which key off the presence of the index buffer).
    const bool is_indexed = command.index_type != IndexType::kNone &&
                            command.index_type != IndexType::kUnknown;

    // Bind the index buffer once, before any (possibly repeated) draw.
    const GLvoid* index_offset = nullptr;
    if (is_indexed) {
      auto index_buffer_view = command.index_buffer;
      const DeviceBuffer* index_buffer = index_buffer_view.GetBuffer();
      const auto& index_buffer_gles = DeviceBufferGLES::Cast(*index_buffer);
      if (!index_buffer_gles.BindAndUploadDataIfNecessary(
              DeviceBufferGLES::BindingType::kElementArrayBuffer)) {
        return false;
      }
      index_offset = reinterpret_cast<const GLvoid*>(
          static_cast<uintptr_t>(index_buffer_view.GetRange().offset));
    }

    // A non-instanced draw of the bound geometry. Used directly for ordinary
    // draws and once per instance when emulating instancing.
    const auto draw_geometry = [&]() {
      if (!is_indexed) {
        gl.DrawArrays(mode, command.base_vertex, command.element_count);
      } else {
        gl.DrawElements(mode, command.element_count,
                        ToIndexType(command.index_type), index_offset);
      }
    };

    if (command.instance_count == 0u) {
      // A zero instance count draws nothing, matching the Metal and Vulkan
      // backends.
    } else if (emulate_instanced) {
      // Repeat the draw once per instance, re-pointing the instance-rate
      // vertex attributes at each instance in between. The vertex buffers
      // were already bound above for instance 0.
      for (size_t instance = 0; instance < command.instance_count; instance++) {
        if (instance > 0u) {
          for (size_t i = 0; i < command.vertex_buffers.length; i++) {
            if (!BindVertexBuffer(
                    gl, vertex_desc_gles,
                    vertex_buffers[i + command.vertex_buffers.offset], i,
                    instance)) {
              return false;
            }
          }
        }
        draw_geometry();
      }
    } else if (hardware_instanced) {
      // A single instanced call covers every instance.
      if (!is_indexed) {
        const auto& gl_draw_arrays_instanced =
            gl.DrawArraysInstanced.IsAvailable() ? gl.DrawArraysInstanced
                                                 : gl.DrawArraysInstancedEXT;
        gl_draw_arrays_instanced(mode, command.base_vertex,
                                 command.element_count, instance_count);
      } else {
        const auto& gl_draw_elements_instanced =
            gl.DrawElementsInstanced.IsAvailable()
                ? gl.DrawElementsInstanced
                : gl.DrawElementsInstancedEXT;
        gl_draw_elements_instanced(mode, command.element_count,
                                   ToIndexType(command.index_type),
                                   index_offset, instance_count);
      }
    } else {
      draw_geometry();
    }

    //--------------------------------------------------------------------------
    /// Unbind vertex attribs.
    ///
    if (!vertex_desc_gles->UnbindVertexAttributes(gl)) {
      return false;
    }
  }

  if (pass_data.resolve_attachment &&
      !gl.GetCapabilities()->SupportsImplicitResolvingMSAA() &&
      !is_wrapped_fbo) {
    FML_DCHECK(pass_data.resolve_attachment != pass_data.color_attachment);
    TextureGLES& resolve_gles =
        TextureGLES::Cast(*pass_data.resolve_attachment);
    std::optional<GLuint> resolve_fbo_opt;

    if (!resolve_gles.GetCachedFBO().IsDead()) {
      resolve_fbo_opt = reactor.GetGLHandle(resolve_gles.GetCachedFBO());
    }

    if (!resolve_fbo_opt.has_value()) {
      HandleGLES cached_fbo =
          reactor.CreateUntrackedHandle(HandleType::kFrameBuffer);
      resolve_gles.SetCachedFBO(cached_fbo);
      resolve_fbo_opt = reactor.GetGLHandle(cached_fbo);
      gl.BindFramebuffer(GL_FRAMEBUFFER, resolve_fbo_opt.value());

      if (!resolve_gles.SetAsFramebufferAttachment(
              GL_FRAMEBUFFER, TextureGLES::AttachmentType::kColor0)) {
        return false;
      }

      auto status = gl.CheckFramebufferStatusDebug(GL_FRAMEBUFFER);
      if (status != GL_FRAMEBUFFER_COMPLETE) {
        VALIDATION_LOG << "Could not create a complete frambuffer: "
                       << DebugToFramebufferError(status);
        return false;
      }
    } else {
      gl.BindFramebuffer(GL_FRAMEBUFFER, resolve_fbo_opt.value());
    }

    // Bind MSAA renderbuffer to read framebuffer.
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, fbo.value());
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, resolve_fbo_opt.value());

    RenderPassGLES::ResetGLState(gl);
    auto size = pass_data.color_attachment->GetSize();

    gl.BlitFramebuffer(/*srcX0=*/0,
                       /*srcY0=*/0,
                       /*srcX1=*/size.width,
                       /*srcY1=*/size.height,
                       /*dstX0=*/0,
                       /*dstY0=*/0,
                       /*dstX1=*/size.width,
                       /*dstY1=*/size.height,
                       /*mask=*/GL_COLOR_BUFFER_BIT,
                       /*filter=*/GL_NEAREST);

    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, GL_NONE);
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, GL_NONE);
    // Rebind the original FBO so that we can discard it below.
    gl.BindFramebuffer(GL_FRAMEBUFFER, fbo.value());
  }

  GLint framebuffer_id = 0;
  gl.GetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer_id);
  const bool is_default_fbo = framebuffer_id == 0;

  if (gl.InvalidateFramebuffer.IsAvailable()) {
    std::array<GLenum, 3> attachments;
    size_t attachment_count = 0;

    bool angle_safe = gl.GetCapabilities()->IsANGLE() ? !is_default_fbo : true;

    if (pass_data.discard_color_attachment) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_COLOR_EXT : GL_COLOR_ATTACHMENT0);
    }

    if (pass_data.discard_depth_attachment && angle_safe) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_DEPTH_EXT : GL_DEPTH_ATTACHMENT);
    }

    if (pass_data.discard_stencil_attachment && angle_safe) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_STENCIL_EXT : GL_STENCIL_ATTACHMENT);
    }
    gl.InvalidateFramebuffer(GL_FRAMEBUFFER,     // target
                             attachment_count,   // attachments to discard
                             attachments.data()  // size
    );
  } else if (gl.DiscardFramebufferEXT.IsAvailable()) {
    std::array<GLenum, 3> attachments;
    size_t attachment_count = 0;

    // TODO(130048): discarding stencil or depth on the default fbo causes Angle
    // to discard the entire render target. Until we know the reason, default to
    // storing.
    bool angle_safe = gl.GetCapabilities()->IsANGLE() ? !is_default_fbo : true;

    if (pass_data.discard_color_attachment) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_COLOR_EXT : GL_COLOR_ATTACHMENT0);
    }

    if (pass_data.discard_depth_attachment && angle_safe) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_DEPTH_EXT : GL_DEPTH_ATTACHMENT);
    }

    if (pass_data.discard_stencil_attachment && angle_safe) {
      attachments[attachment_count++] =
          (is_default_fbo ? GL_STENCIL_EXT : GL_STENCIL_ATTACHMENT);
    }
    gl.DiscardFramebufferEXT(GL_FRAMEBUFFER,     // target
                             attachment_count,   // attachments to discard
                             attachments.data()  // size
    );
  }

#ifdef IMPELLER_DEBUG
  if (is_default_fbo) {
    tracer->MarkFrameEnd(gl);
  }
#endif  // IMPELLER_DEBUG

  return true;
}

// |RenderPass|
bool RenderPassGLES::OnEncodeCommands(const Context& context) const {
  if (!IsValid()) {
    return false;
  }
  const auto& render_target = GetRenderTarget();
  if (!render_target.HasColorAttachment(0u)) {
    return false;
  }
  const ColorAttachment& color0 = render_target.GetColorAttachment(0);
  const std::optional<DepthAttachment>& depth0 =
      render_target.GetDepthAttachment();
  const std::optional<StencilAttachment>& stencil0 =
      render_target.GetStencilAttachment();

  auto pass_data = std::make_shared<RenderPassData>();
  pass_data->label = label_;
  pass_data->viewport.rect = Rect::MakeSize(GetRenderTargetSize());

  //----------------------------------------------------------------------------
  /// Setup color data.
  ///
  pass_data->color_attachment = color0.texture;
  pass_data->resolve_attachment = color0.resolve_texture;
  pass_data->color_mip_level = color0.mip_level;
  pass_data->color_slice = color0.slice;
  pass_data->clear_color = color0.clear_color;
  pass_data->clear_color_attachment = CanClearAttachment(color0.load_action);
  pass_data->discard_color_attachment =
      CanDiscardAttachmentWhenDone(color0.store_action);

  // When we are using EXT_multisampled_render_to_texture, it is implicitly
  // resolved when we bind the texture to the framebuffer. We don't need to
  // discard the attachment when we are done. If not using
  // EXT_multisampled_render_to_texture but still using MSAA we discard the
  // attachment as normal.
  if (color0.resolve_texture) {
    pass_data->discard_color_attachment =
        pass_data->discard_color_attachment &&
        !context.GetCapabilities()->SupportsImplicitResolvingMSAA();
  }

  //----------------------------------------------------------------------------
  /// Setup depth data.
  ///
  if (depth0.has_value()) {
    pass_data->depth_attachment = depth0->texture;
    pass_data->depth_mip_level = depth0->mip_level;
    pass_data->depth_slice = depth0->slice;
    pass_data->clear_depth = depth0->clear_depth;
    pass_data->clear_depth_attachment = CanClearAttachment(depth0->load_action);
    pass_data->discard_depth_attachment =
        CanDiscardAttachmentWhenDone(depth0->store_action);
  }

  //----------------------------------------------------------------------------
  /// Setup stencil data.
  ///
  if (stencil0.has_value()) {
    pass_data->stencil_attachment = stencil0->texture;
    pass_data->stencil_mip_level = stencil0->mip_level;
    pass_data->stencil_slice = stencil0->slice;
    pass_data->clear_stencil = stencil0->clear_stencil;
    pass_data->clear_stencil_attachment =
        CanClearAttachment(stencil0->load_action);
    pass_data->discard_stencil_attachment =
        CanDiscardAttachmentWhenDone(stencil0->store_action);
  }

  return reactor_->AddOperation(
      [pass_data = std::move(pass_data), render_pass = shared_from_this(),
       tracer =
           ContextGLES::Cast(context).GetGPUTracer()](const auto& reactor) {
        auto result = EncodeCommandsInReactor(
            /*pass_data=*/*pass_data,                         //
            /*reactor=*/reactor,                              //
            /*commands=*/render_pass->commands_,              //
            /*vertex_buffers=*/render_pass->vertex_buffers_,  //
            /*bound_textures=*/render_pass->bound_textures_,  //
            /*bound_buffers=*/render_pass->bound_buffers_,    //
            /*tracer=*/tracer,                                //
            /*impeller_context=*/render_pass->context_);
        FML_CHECK(result)
            << "Must be able to encode GL commands without error.";
      },
      /*defer=*/true);
}

}  // namespace impeller
