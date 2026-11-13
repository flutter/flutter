// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include <memory>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/shader_types.h"
#include "impeller/geometry/color.h"
#include "lib/gpu/context.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, RenderPass);

RenderPass::RenderPass() = default;

RenderPass::~RenderPass() = default;

impeller::RenderTarget& RenderPass::GetRenderTarget() {
  pipeline_state_dirty_ = true;
  return render_target_;
}

const impeller::RenderTarget& RenderPass::GetRenderTarget() const {
  return render_target_;
}

impeller::ColorAttachmentDescriptor& RenderPass::ColorAttachmentDescriptorAt(
    size_t color_attachment_index) {
  auto color = color_descriptors_.find(color_attachment_index);
  if (color == color_descriptors_.end()) {
    return color_descriptors_[color_attachment_index] = {};
  }
  return color->second;
}

impeller::ColorAttachmentDescriptor& RenderPass::GetColorAttachmentDescriptor(
    size_t color_attachment_index) {
  pipeline_state_dirty_ = true;
  return ColorAttachmentDescriptorAt(color_attachment_index);
}

impeller::DepthAttachmentDescriptor&
RenderPass::GetDepthAttachmentDescriptor() {
  pipeline_state_dirty_ = true;
  return depth_desc_;
}

impeller::StencilAttachmentDescriptor&
RenderPass::GetStencilFrontAttachmentDescriptor() {
  pipeline_state_dirty_ = true;
  return stencil_front_desc_;
}

impeller::StencilAttachmentDescriptor&
RenderPass::GetStencilBackAttachmentDescriptor() {
  pipeline_state_dirty_ = true;
  return stencil_back_desc_;
}

impeller::PipelineDescriptor& RenderPass::GetPipelineDescriptor() {
  pipeline_state_dirty_ = true;
  return pipeline_descriptor_;
}

bool RenderPass::IsPipelineStateDirtyForTesting() const {
  return pipeline_state_dirty_;
}

void RenderPass::ClearPipelineStateDirtyForTesting() {
  pipeline_state_dirty_ = false;
}

bool RenderPass::Begin(flutter::gpu::CommandBuffer& command_buffer) {
  if (command_buffer_ || !render_target_.IsValid()) {
    return false;
  }
  PassRecording* recording =
      command_buffer.BeginPass(PassRecording::Kind::kRender, this);
  if (!recording) {
    return false;
  }
  recording->render_target = render_target_;
  command_buffer_ = fml::Ref(&command_buffer);
  pipeline_state_dirty_ = true;
  return true;
}

void RenderPass::End() {
  if (command_buffer_) {
    command_buffer_->EndPass(this);
  }
}

void RenderPass::SetPipeline(fml::RefPtr<RenderPipeline> pipeline) {
  if (render_pipeline_.get() == pipeline.get()) {
    return;
  }
  pipeline_state_dirty_ = true;
  // On debug this makes a difference, but not on release builds.
  // NOLINTNEXTLINE(performance-move-const-arg)
  render_pipeline_ = std::move(pipeline);
}

// The setters below assign through the pipeline descriptor directly rather
// than through GetPipelineDescriptor, which would dirty the state
// unconditionally. Callers re-send the same fixed-function state ahead of
// most draws, and dirtying on a redundant assignment would record the
// pipeline state for every one of them.

void RenderPass::SetCullMode(impeller::CullMode mode) {
  if (pipeline_descriptor_.GetCullMode() == mode) {
    return;
  }
  pipeline_descriptor_.SetCullMode(mode);
  pipeline_state_dirty_ = true;
}

void RenderPass::SetWindingOrder(impeller::WindingOrder order) {
  if (pipeline_descriptor_.GetWindingOrder() == order) {
    return;
  }
  pipeline_descriptor_.SetWindingOrder(order);
  pipeline_state_dirty_ = true;
}

void RenderPass::SetPrimitiveType(impeller::PrimitiveType type) {
  if (pipeline_descriptor_.GetPrimitiveType() == type) {
    return;
  }
  pipeline_descriptor_.SetPrimitiveType(type);
  pipeline_state_dirty_ = true;
}

void RenderPass::SetPolygonMode(impeller::PolygonMode mode) {
  if (pipeline_descriptor_.GetPolygonMode() == mode) {
    return;
  }
  pipeline_descriptor_.SetPolygonMode(mode);
  pipeline_state_dirty_ = true;
}

void RenderPass::BindSet(size_t slot, const fml::RefPtr<BindingSet>& set) {
  PassRecording* recording = GetRecording();
  if (!recording || slot >= kMaxBindingSets) {
    return;
  }
  auto* op = recording->ops.Append<BindSetOp>();
  op->slot = static_cast<uint32_t>(slot);
  op->contents = nullptr;
  if (set) {
    const std::shared_ptr<const BindingSet::Contents>& contents =
        set->Snapshot();
    recording->Retain(contents);
    op->contents = contents.get();
  }
}

void RenderPass::ClearBindings() {
  index_buffer_type_ = impeller::IndexType::kNone;
  if (PassRecording* recording = GetRecording()) {
    recording->ops.Append<ClearBindingsOp>();
  }
}

// Whether a shader stage can take resource bindings from a render pass.
static bool IsRenderStage(impeller::ShaderStage stage) {
  return stage == impeller::ShaderStage::kVertex ||
         stage == impeller::ShaderStage::kFragment;
}

// Whether a view fits in [buffer]. Written so that neither term can overflow.
static bool IsViewInBounds(DeviceBuffer& buffer,
                           size_t offset_in_bytes,
                           size_t length_in_bytes) {
  const size_t size = buffer.GetBuffer()->GetDeviceBufferDescriptor().size;
  return offset_in_bytes <= size && length_in_bytes <= size - offset_in_bytes;
}

bool RenderPass::BindUniform(Shader& shader,
                             const Shader::UniformBinding* binding,
                             DeviceBuffer& buffer,
                             size_t offset_in_bytes,
                             size_t length_in_bytes) {
  PassRecording* recording = GetRecording();
  if (!recording || !binding || !IsRenderStage(shader.GetShaderStage()) ||
      !IsViewInBounds(buffer, offset_in_bytes, length_in_bytes)) {
    return false;
  }
  const std::shared_ptr<const Shader::Reflection>& reflection =
      shader.GetReflection();
  recording->Retain(reflection);
  recording->Retain(buffer.GetBuffer());
  auto* op = recording->ops.Append<BindUniformOp>();
  op->stage = shader.GetShaderStage();
  op->binding = binding;
  op->buffer = buffer.GetBuffer().get();
  op->offset = static_cast<uint32_t>(offset_in_bytes);
  op->length = static_cast<uint32_t>(length_in_bytes);
  return true;
}

bool RenderPass::BindTexture(Shader& shader,
                             const Shader::TextureBinding* binding,
                             Texture& texture,
                             const impeller::SamplerDescriptor& sampler) {
  PassRecording* recording = GetRecording();
  if (!recording || !binding || !IsRenderStage(shader.GetShaderStage())) {
    return false;
  }
  const std::shared_ptr<const Shader::Reflection>& reflection =
      shader.GetReflection();
  recording->Retain(reflection);
  recording->Retain(texture.GetTexture());
  auto* op = recording->ops.Append<BindTextureOp>();
  op->stage = shader.GetShaderStage();
  op->binding = binding;
  op->texture = texture.GetTexture().get();
  op->sampler_key = impeller::SamplerDescriptor::ToKey(sampler);
  return true;
}

void RenderPass::BindVertexBuffer(size_t slot,
                                  DeviceBuffer& buffer,
                                  size_t offset_in_bytes,
                                  size_t length_in_bytes) {
  PassRecording* recording = GetRecording();
  if (!recording || slot >= kMaxVertexBufferSlots ||
      !IsViewInBounds(buffer, offset_in_bytes, length_in_bytes)) {
    return;
  }
  recording->Retain(buffer.GetBuffer());
  auto* op = recording->ops.Append<BindVertexBufferOp>();
  op->slot = static_cast<uint32_t>(slot);
  op->buffer = buffer.GetBuffer().get();
  op->offset = static_cast<uint32_t>(offset_in_bytes);
  op->length = static_cast<uint32_t>(length_in_bytes);
}

void RenderPass::BindIndexBuffer(DeviceBuffer& buffer,
                                 size_t offset_in_bytes,
                                 size_t length_in_bytes,
                                 impeller::IndexType type) {
  PassRecording* recording = GetRecording();
  if (!recording || !IsViewInBounds(buffer, offset_in_bytes, length_in_bytes)) {
    return;
  }
  index_buffer_type_ = type;
  recording->Retain(buffer.GetBuffer());
  auto* op = recording->ops.Append<BindIndexBufferOp>();
  op->type = type;
  op->buffer = buffer.GetBuffer().get();
  op->offset = static_cast<uint32_t>(offset_in_bytes);
  op->length = static_cast<uint32_t>(length_in_bytes);
}

void RenderPass::SetStencilReference(uint32_t reference) {
  if (PassRecording* recording = GetRecording()) {
    recording->ops.Append<SetStencilReferenceOp>()->reference = reference;
  }
}

void RenderPass::SetScissor(impeller::IRect32 scissor) {
  if (PassRecording* recording = GetRecording()) {
    recording->ops.Append<SetScissorOp>()->scissor = scissor;
  }
}

void RenderPass::SetViewport(const impeller::Viewport& viewport) {
  if (PassRecording* recording = GetRecording()) {
    auto* op = recording->ops.Append<SetViewportOp>();
    op->rect = viewport.rect;
    op->z_near = viewport.depth_range.z_near;
    op->z_far = viewport.depth_range.z_far;
  }
}

void RenderPass::RecordPipelineState(PassRecording& recording) {
  pipeline_state_dirty_ = false;

  // Infer the pipeline layout based on the shape of the RenderTarget.
  auto descriptor =
      std::make_shared<impeller::PipelineDescriptor>(pipeline_descriptor_);

  descriptor->SetSampleCount(render_target_.GetSampleCount());

  render_target_.IterateAllColorAttachments(
      [&](size_t index, const impeller::ColorAttachment& attachment) -> bool {
        auto& color = ColorAttachmentDescriptorAt(index);
        color.format = render_target_.GetRenderTargetPixelFormat();
        return true;
      });

  descriptor->SetColorAttachmentDescriptors(color_descriptors_);

  {
    auto stencil = render_target_.GetStencilAttachment();
    if (stencil && impeller::IsStencilWritable(
                       stencil->texture->GetTextureDescriptor().format)) {
      descriptor->SetStencilPixelFormat(
          stencil->texture->GetTextureDescriptor().format);
      descriptor->SetStencilAttachmentDescriptors(stencil_front_desc_,
                                                  stencil_back_desc_);
    } else {
      descriptor->ClearStencilAttachments();
    }
  }

  {
    auto depth = render_target_.GetDepthAttachment();
    if (depth && impeller::IsDepthWritable(
                     depth->texture->GetTextureDescriptor().format)) {
      descriptor->SetDepthPixelFormat(
          depth->texture->GetTextureDescriptor().format);
      descriptor->SetDepthStencilAttachmentDescriptor(depth_desc_);
    } else {
      descriptor->ClearDepthAttachment();
    }
  }

  const std::shared_ptr<const RenderPipeline::Core>& core =
      render_pipeline_->GetCore();
  pipeline_known_failed_ = core->HasBuildFailed(*descriptor);
  if (pipeline_known_failed_) {
    return;
  }
  recording.Retain(core);
  auto* op = recording.ops.Append<SetPipelineStateOp>();
  op->core = core.get();
  op->descriptor = descriptor.get();
  recording.Retain(std::move(descriptor));
}

bool RenderPass::Draw(size_t element_count,
                      size_t instance_count,
                      bool indexed) {
  PassRecording* recording = GetRecording();
  if (!recording) {
    return false;
  }
  if (element_count == 0u || instance_count == 0u) {
    return true;
  }
  if (indexed && index_buffer_type_ == impeller::IndexType::kNone) {
    // drawIndexed was called without an index buffer bound.
    return false;
  }
  if (!render_pipeline_) {
    return false;
  }
  if (pipeline_state_dirty_) {
    RecordPipelineState(*recording);
  }
  if (pipeline_known_failed_) {
    // The backend already failed to build this state, and logged why.
    return false;
  }
  auto* op = recording->ops.Append<DrawOp>();
  op->indexed = indexed;
  op->element_count = static_cast<uint32_t>(element_count);
  op->instance_count = static_cast<uint32_t>(instance_count);
  return true;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_RenderPass_Initialize(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::gpu::RenderPass>();
  res->AssociateWithDartWrapper(wrapper);
}

Dart_Handle InternalFlutterGpu_RenderPass_SetColorAttachment(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Context* context,
    int color_attachment_index,
    int load_action,
    int store_action,
    float clear_color_r,
    float clear_color_g,
    float clear_color_b,
    float clear_color_a,
    flutter::gpu::Texture* texture,
    Dart_Handle resolve_texture_wrapper,
    int mip_level,
    int slice) {
  impeller::ColorAttachment desc;
  desc.load_action = flutter::gpu::ToImpellerLoadAction(load_action);
  desc.store_action = flutter::gpu::ToImpellerStoreAction(store_action);
  desc.clear_color = impeller::Color(clear_color_r, clear_color_g,
                                     clear_color_b, clear_color_a);
  desc.texture = texture->GetTexture();
  desc.mip_level = mip_level;
  desc.slice = slice;
  if (!Dart_IsNull(resolve_texture_wrapper)) {
    flutter::gpu::Texture* resolve_texture =
        tonic::DartConverter<flutter::gpu::Texture*>::FromDart(
            resolve_texture_wrapper);
    desc.resolve_texture = resolve_texture->GetTexture();

    // If the backend doesn't support normal MSAA, gracefully fallback to
    // rendering without MSAA.
    if (!flutter::gpu::SupportsNormalOffscreenMSAA(context->GetContext())) {
      desc.texture = desc.resolve_texture;
      desc.resolve_texture = nullptr;
      desc.store_action = impeller::StoreAction::kStore;
    }
  }
  wrapper->GetRenderTarget().SetColorAttachment(desc, color_attachment_index);
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_RenderPass_SetDepthStencilAttachment(
    flutter::gpu::RenderPass* wrapper,
    int depth_load_action,
    int depth_store_action,
    float depth_clear_value,
    int stencil_load_action,
    int stencil_store_action,
    int stencil_clear_value,
    flutter::gpu::Texture* texture,
    int mip_level,
    int slice) {
  {
    impeller::DepthAttachment desc;
    desc.load_action = flutter::gpu::ToImpellerLoadAction(depth_load_action);
    desc.store_action = flutter::gpu::ToImpellerStoreAction(depth_store_action);
    desc.clear_depth = depth_clear_value;
    desc.texture = texture->GetTexture();
    desc.mip_level = mip_level;
    desc.slice = slice;
    wrapper->GetRenderTarget().SetDepthAttachment(desc);
  }
  {
    impeller::StencilAttachment desc;
    desc.load_action = flutter::gpu::ToImpellerLoadAction(stencil_load_action);
    desc.store_action =
        flutter::gpu::ToImpellerStoreAction(stencil_store_action);
    desc.clear_stencil = stencil_clear_value;
    desc.texture = texture->GetTexture();
    desc.mip_level = mip_level;
    desc.slice = slice;
    wrapper->GetRenderTarget().SetStencilAttachment(desc);
  }

  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_RenderPass_Begin(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::CommandBuffer* command_buffer) {
  if (!wrapper->Begin(*command_buffer)) {
    return tonic::ToDart("Failed to begin RenderPass");
  }
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_RenderPass_End(
    flutter::gpu::RenderPass* wrapper) {
  wrapper->End();
  return Dart_Null();
}

void InternalFlutterGpu_RenderPass_BindPipeline(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::RenderPipeline* pipeline) {
  auto ref = fml::RefPtr<flutter::gpu::RenderPipeline>(pipeline);
  wrapper->SetPipeline(std::move(ref));
}

void InternalFlutterGpu_RenderPass_BindVertexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int slot) {
  if (slot < 0 || offset_in_bytes < 0 || length_in_bytes < 0) {
    return;
  }
  wrapper->BindVertexBuffer(static_cast<size_t>(slot), *device_buffer,
                            static_cast<size_t>(offset_in_bytes),
                            static_cast<size_t>(length_in_bytes));
}

void InternalFlutterGpu_RenderPass_BindIndexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int index_type) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return;
  }
  wrapper->BindIndexBuffer(*device_buffer, static_cast<size_t>(offset_in_bytes),
                           static_cast<size_t>(length_in_bytes),
                           flutter::gpu::ToImpellerIndexType(index_type));
}

static bool BindUniformStruct(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    const flutter::gpu::Shader::UniformBinding* uniform_struct,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return false;
  }
  return wrapper->BindUniform(*shader, uniform_struct, *device_buffer,
                              static_cast<size_t>(offset_in_bytes),
                              static_cast<size_t>(length_in_bytes));
}

bool InternalFlutterGpu_RenderPass_BindUniformDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    Dart_Handle uniform_name_handle,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  auto uniform_name = tonic::StdStringFromDart(uniform_name_handle);
  return BindUniformStruct(wrapper, shader,
                           shader->GetUniformStruct(uniform_name),
                           device_buffer, offset_in_bytes, length_in_bytes);
}

bool InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  return BindUniformStruct(wrapper, shader,
                           shader->GetUniformStructAt(uniform_struct_index),
                           device_buffer, offset_in_bytes, length_in_bytes);
}

static bool BindTextureBinding(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    const flutter::gpu::Shader::TextureBinding* texture_binding,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy) {
  return wrapper->BindTexture(
      *shader, texture_binding, *texture,
      flutter::gpu::ToImpellerSamplerDescriptor(
          min_filter, mag_filter, mip_filter, width_address_mode,
          height_address_mode, max_anisotropy));
}

bool InternalFlutterGpu_RenderPass_BindTexture(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    Dart_Handle uniform_name_handle,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy) {
  auto uniform_name = tonic::StdStringFromDart(uniform_name_handle);
  return BindTextureBinding(
      wrapper, shader, shader->GetUniformTexture(uniform_name), texture,
      min_filter, mag_filter, mip_filter, width_address_mode,
      height_address_mode, max_anisotropy);
}

bool InternalFlutterGpu_RenderPass_BindTextureIndexed(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_texture_index,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy) {
  return BindTextureBinding(
      wrapper, shader, shader->GetUniformTextureAt(uniform_texture_index),
      texture, min_filter, mag_filter, mip_filter, width_address_mode,
      height_address_mode, max_anisotropy);
}

void InternalFlutterGpu_RenderPass_BindSet(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::BindingSet* binding_set,
    int slot) {
  if (slot < 0) {
    return;
  }
  wrapper->BindSet(slot, fml::RefPtr<flutter::gpu::BindingSet>(binding_set));
}

void InternalFlutterGpu_RenderPass_ClearBindings(
    flutter::gpu::RenderPass* wrapper) {
  wrapper->ClearBindings();
}

void InternalFlutterGpu_RenderPass_SetColorBlendEnable(
    flutter::gpu::RenderPass* wrapper,
    int color_attachment_index,
    bool enable) {
  auto& color = wrapper->GetColorAttachmentDescriptor(color_attachment_index);
  color.blending_enabled = enable;
}

void InternalFlutterGpu_RenderPass_SetColorBlendEquation(
    flutter::gpu::RenderPass* wrapper,
    int color_attachment_index,
    int color_blend_operation,
    int source_color_blend_factor,
    int destination_color_blend_factor,
    int alpha_blend_operation,
    int source_alpha_blend_factor,
    int destination_alpha_blend_factor) {
  auto& color = wrapper->GetColorAttachmentDescriptor(color_attachment_index);
  color.color_blend_op =
      flutter::gpu::ToImpellerBlendOperation(color_blend_operation);
  color.src_color_blend_factor =
      flutter::gpu::ToImpellerBlendFactor(source_color_blend_factor);
  color.dst_color_blend_factor =
      flutter::gpu::ToImpellerBlendFactor(destination_color_blend_factor);
  color.alpha_blend_op =
      flutter::gpu::ToImpellerBlendOperation(alpha_blend_operation);
  color.src_alpha_blend_factor =
      flutter::gpu::ToImpellerBlendFactor(source_alpha_blend_factor);
  color.dst_alpha_blend_factor =
      flutter::gpu::ToImpellerBlendFactor(destination_alpha_blend_factor);
}

void InternalFlutterGpu_RenderPass_SetDepthWriteEnable(
    flutter::gpu::RenderPass* wrapper,
    bool enable) {
  auto& depth = wrapper->GetDepthAttachmentDescriptor();
  depth.depth_write_enabled = enable;
}

void InternalFlutterGpu_RenderPass_SetDepthCompareOperation(
    flutter::gpu::RenderPass* wrapper,
    int compare_operation) {
  auto& depth = wrapper->GetDepthAttachmentDescriptor();
  depth.depth_compare =
      flutter::gpu::ToImpellerCompareFunction(compare_operation);
}

void InternalFlutterGpu_RenderPass_SetStencilReference(
    flutter::gpu::RenderPass* wrapper,
    int stencil_reference) {
  wrapper->SetStencilReference(static_cast<uint32_t>(stencil_reference));
}

void InternalFlutterGpu_RenderPass_SetScissor(flutter::gpu::RenderPass* wrapper,
                                              int x,
                                              int y,
                                              int width,
                                              int height) {
  wrapper->SetScissor(impeller::IRect32::MakeXYWH(x, y, width, height));
}

void InternalFlutterGpu_RenderPass_SetViewport(
    flutter::gpu::RenderPass* wrapper,
    int x,
    int y,
    int width,
    int height,
    float z_near,
    float z_far) {
  auto rect = impeller::TRect<float>::MakeXYWH(x, y, width, height);

  auto depth_range = impeller::DepthRange();
  depth_range.z_near = z_near;
  depth_range.z_far = z_far;

  auto viewport = impeller::Viewport();
  viewport.rect = rect;
  viewport.depth_range = depth_range;

  wrapper->SetViewport(viewport);
}

void InternalFlutterGpu_RenderPass_SetStencilConfig(
    flutter::gpu::RenderPass* wrapper,
    int stencil_compare_operation,
    int stencil_fail_operation,
    int depth_fail_operation,
    int depth_stencil_pass_operation,
    int read_mask,
    int write_mask,
    int target_face) {
  impeller::StencilAttachmentDescriptor desc;
  desc.stencil_compare =
      flutter::gpu::ToImpellerCompareFunction(stencil_compare_operation);
  desc.stencil_failure =
      flutter::gpu::ToImpellerStencilOperation(stencil_fail_operation);
  desc.depth_failure =
      flutter::gpu::ToImpellerStencilOperation(depth_fail_operation);
  desc.depth_stencil_pass =
      flutter::gpu::ToImpellerStencilOperation(depth_stencil_pass_operation);
  desc.read_mask = static_cast<uint32_t>(read_mask);
  desc.write_mask = static_cast<uint32_t>(write_mask);

  // Corresponds to the `StencilFace` enum in `gpu/lib/src/render_pass.dart`.
  if (target_face != 2 /* both or front */) {
    wrapper->GetStencilFrontAttachmentDescriptor() = desc;
  }
  if (target_face != 1 /* both or back */) {
    wrapper->GetStencilBackAttachmentDescriptor() = desc;
  }
}

void InternalFlutterGpu_RenderPass_SetCullMode(
    flutter::gpu::RenderPass* wrapper,
    int cull_mode) {
  wrapper->SetCullMode(flutter::gpu::ToImpellerCullMode(cull_mode));
}

void InternalFlutterGpu_RenderPass_SetPrimitiveType(
    flutter::gpu::RenderPass* wrapper,
    int primitive_type) {
  wrapper->SetPrimitiveType(
      flutter::gpu::ToImpellerPrimitiveType(primitive_type));
}

void InternalFlutterGpu_RenderPass_SetWindingOrder(
    flutter::gpu::RenderPass* wrapper,
    int winding_order) {
  wrapper->SetWindingOrder(flutter::gpu::ToImpellerWindingOrder(winding_order));
}

void InternalFlutterGpu_RenderPass_SetPolygonMode(
    flutter::gpu::RenderPass* wrapper,
    int polygon_mode) {
  wrapper->SetPolygonMode(flutter::gpu::ToImpellerPolygonMode(polygon_mode));
}

bool InternalFlutterGpu_RenderPass_Draw(flutter::gpu::RenderPass* wrapper,
                                        int vertex_count,
                                        int instance_count) {
  // Guard the casts to size_t; a negative value would wrap.
  return vertex_count >= 0 && instance_count >= 0 &&
         wrapper->Draw(vertex_count, instance_count, /*indexed=*/false);
}

bool InternalFlutterGpu_RenderPass_DrawIndexed(
    flutter::gpu::RenderPass* wrapper,
    int index_count,
    int instance_count) {
  // Guard the casts to size_t; a negative value would wrap.
  return index_count >= 0 && instance_count >= 0 &&
         wrapper->Draw(index_count, instance_count, /*indexed=*/true);
}
