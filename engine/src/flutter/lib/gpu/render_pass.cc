// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"
#include <memory>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/base/validation.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/shader_types.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "lib/gpu/context.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, RenderPass);

RenderPass::RenderPass()
    : recording_(std::make_shared<RenderPassRecording>()) {}

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

const RenderPassRecording& RenderPass::GetRecordingForTesting() const {
  return *recording_;
}

RenderPassRecording* RenderPass::OpenRecording() {
  return recording_->sealed ? nullptr : recording_.get();
}

bool RenderPass::Begin(flutter::gpu::CommandBuffer& command_buffer) {
  if (begun_ || !render_target_.IsValid()) {
    return false;
  }
  recording_->render_target = render_target_;
  if (!command_buffer.AddRenderPass(recording_)) {
    return false;
  }
  begun_ = true;
  return true;
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
// most draws, and dirtying on a redundant assignment would snapshot the
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

void RenderPass::BindSet(size_t slot, fml::RefPtr<BindingSet> set) {
  if (slot >= kMaxBindingSets) {
    return;
  }
  auto* recording = OpenRecording();
  if (!recording) {
    return;
  }
  recording->Push(RecordedOp::kBindSet, recording->sets,
                  RenderPassRecording::SetBind{
                      .slot = static_cast<uint32_t>(slot),
                      .contents = set ? set->Snapshot() : nullptr,
                  });
  // On debug this makes a difference, but not on release builds.
  // NOLINTNEXTLINE(performance-move-const-arg)
  binding_sets[slot] = std::move(set);
}

void RenderPass::ClearBindings() {
  for (auto& set : binding_sets) {
    set = nullptr;
  }
  index_buffer_type_ = impeller::IndexType::kNone;
  if (auto* recording = OpenRecording()) {
    recording->Push(RecordedOp::kClearBindings);
  }
}

// Whether a shader stage can take resource bindings from a render pass.
static bool IsRenderStage(impeller::ShaderStage stage) {
  return stage == impeller::ShaderStage::kVertex ||
         stage == impeller::ShaderStage::kFragment;
}

bool RenderPass::BindUniform(
    Shader& shader,
    const Shader::UniformBinding* binding,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    size_t offset_in_bytes,
    size_t length_in_bytes) {
  auto* recording = OpenRecording();
  if (!recording || !binding || !IsRenderStage(shader.GetShaderStage())) {
    return false;
  }
  if (!buffer || offset_in_bytes + length_in_bytes >
                     buffer->GetDeviceBufferDescriptor().size) {
    return false;
  }
  recording->RetainReflection(shader.GetReflection());
  recording->Push(
      RecordedOp::kBindUniform, recording->uniforms,
      RenderPassRecording::UniformBind{
          .binding = binding,
          .stage = shader.GetShaderStage(),
          .view = impeller::BufferView(
              buffer, impeller::Range(offset_in_bytes, length_in_bytes)),
      });
  return true;
}

bool RenderPass::BindTexture(Shader& shader,
                             const Shader::TextureBinding* binding,
                             std::shared_ptr<const impeller::Texture> texture,
                             const impeller::SamplerDescriptor& sampler) {
  auto* recording = OpenRecording();
  if (!recording || !binding || !texture ||
      !IsRenderStage(shader.GetShaderStage())) {
    return false;
  }
  recording->RetainReflection(shader.GetReflection());
  recording->Push(RecordedOp::kBindTexture, recording->textures,
                  RenderPassRecording::TextureBind{
                      .binding = binding,
                      .stage = shader.GetShaderStage(),
                      .texture = std::move(texture),
                      .sampler = sampler,
                  });
  return true;
}

void RenderPass::BindVertexBuffer(size_t slot, impeller::BufferView view) {
  auto* recording = OpenRecording();
  if (!recording || slot >= kMaxVertexBufferSlots) {
    return;
  }
  recording->Push(RecordedOp::kBindVertexBuffer, recording->vertex_buffers,
                  RenderPassRecording::VertexBufferBind{
                      .slot = static_cast<uint32_t>(slot),
                      .view = std::move(view),
                  });
}

void RenderPass::BindIndexBuffer(impeller::BufferView view,
                                 impeller::IndexType type) {
  index_buffer_type_ = type;
  if (auto* recording = OpenRecording()) {
    recording->Push(RecordedOp::kBindIndexBuffer, recording->index_buffers,
                    RenderPassRecording::IndexBufferBind{
                        .view = std::move(view),
                        .type = type,
                    });
  }
}

void RenderPass::SetStencilReference(uint32_t reference) {
  if (auto* recording = OpenRecording()) {
    recording->Push(RecordedOp::kSetStencilReference,
                    recording->stencil_references, std::move(reference));
  }
}

void RenderPass::SetScissor(impeller::IRect32 scissor) {
  if (auto* recording = OpenRecording()) {
    recording->Push(RecordedOp::kSetScissor, recording->scissors,
                    std::move(scissor));
  }
}

void RenderPass::SetViewport(impeller::Viewport viewport) {
  if (auto* recording = OpenRecording()) {
    recording->Push(RecordedOp::kSetViewport, recording->viewports,
                    std::move(viewport));
  }
}

void RenderPass::RecordPipelineState() {
  pipeline_state_dirty_ = false;
  pipeline_known_failed_ = false;

  // Infer the pipeline layout based on the shape of the RenderTarget.
  auto pipeline_desc = pipeline_descriptor_;

  pipeline_desc.SetSampleCount(render_target_.GetSampleCount());

  render_target_.IterateAllColorAttachments(
      [&](size_t index, const impeller::ColorAttachment& attachment) -> bool {
        auto& color = ColorAttachmentDescriptorAt(index);
        color.format = render_target_.GetRenderTargetPixelFormat();
        return true;
      });

  pipeline_desc.SetColorAttachmentDescriptors(color_descriptors_);

  {
    auto stencil = render_target_.GetStencilAttachment();
    if (stencil && impeller::IsStencilWritable(
                       stencil->texture->GetTextureDescriptor().format)) {
      pipeline_desc.SetStencilPixelFormat(
          stencil->texture->GetTextureDescriptor().format);
      pipeline_desc.SetStencilAttachmentDescriptors(stencil_front_desc_,
                                                    stencil_back_desc_);
    } else {
      pipeline_desc.ClearStencilAttachments();
    }
  }

  {
    auto depth = render_target_.GetDepthAttachment();
    if (depth && impeller::IsDepthWritable(
                     depth->texture->GetTextureDescriptor().format)) {
      pipeline_desc.SetDepthPixelFormat(
          depth->texture->GetTextureDescriptor().format);
      pipeline_desc.SetDepthStencilAttachmentDescriptor(depth_desc_);
    } else {
      pipeline_desc.ClearDepthAttachment();
    }
  }

  const auto& core = render_pipeline_->GetCore();
  const size_t key = pipeline_desc.GetHash();
  if (core->HasBuildFailed(key)) {
    pipeline_known_failed_ = true;
    return;
  }
  pipeline_state_index_ =
      static_cast<uint32_t>(recording_->pipeline_states.size());
  recording_->pipeline_states.push_back(RenderPassRecording::PipelineState{
      .pipeline = core,
      .descriptor = std::move(pipeline_desc),
      .key = key,
  });
}

bool RenderPass::Draw(size_t element_count,
                      size_t instance_count,
                      bool indexed) {
  auto* recording = OpenRecording();
  if (!recording || !begun_) {
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
    RecordPipelineState();
  }
  if (pipeline_known_failed_) {
    // The backend already failed to build this state, and logged why.
    return false;
  }
  recording->Push(RecordedOp::kDraw, recording->draws,
                  RenderPassRecording::Draw{
                      .pipeline_state = pipeline_state_index_,
                      .element_count = static_cast<uint32_t>(element_count),
                      .instance_count = static_cast<uint32_t>(instance_count),
                      .indexed = indexed,
                  });
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

void InternalFlutterGpu_RenderPass_BindPipeline(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::RenderPipeline* pipeline) {
  auto ref = fml::RefPtr<flutter::gpu::RenderPipeline>(pipeline);
  wrapper->SetPipeline(std::move(ref));
}

static void BindVertexBuffer(
    flutter::gpu::RenderPass* wrapper,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int slot) {
  if (slot < 0) {
    return;
  }
  wrapper->BindVertexBuffer(
      static_cast<size_t>(slot),
      impeller::BufferView(buffer,
                           impeller::Range(offset_in_bytes, length_in_bytes)));
}

void InternalFlutterGpu_RenderPass_BindVertexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int slot) {
  BindVertexBuffer(wrapper, device_buffer->GetBuffer(), offset_in_bytes,
                   length_in_bytes, slot);
}

static void BindIndexBuffer(
    flutter::gpu::RenderPass* wrapper,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int index_type) {
  wrapper->BindIndexBuffer(
      impeller::BufferView(buffer,
                           impeller::Range(offset_in_bytes, length_in_bytes)),
      flutter::gpu::ToImpellerIndexType(index_type));
}

void InternalFlutterGpu_RenderPass_BindIndexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int index_type) {
  BindIndexBuffer(wrapper, device_buffer->GetBuffer(), offset_in_bytes,
                  length_in_bytes, index_type);
}

static bool BindUniformStruct(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    const flutter::gpu::Shader::UniformBinding* uniform_struct,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return false;
  }
  return wrapper->BindUniform(*shader, uniform_struct, buffer,
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
  return BindUniformStruct(
      wrapper, shader, shader->GetUniformStruct(uniform_name),
      device_buffer->GetBuffer(), offset_in_bytes, length_in_bytes);
}

bool InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  return BindUniformStruct(
      wrapper, shader, shader->GetUniformStructAt(uniform_struct_index),
      device_buffer->GetBuffer(), offset_in_bytes, length_in_bytes);
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
      *shader, texture_binding, texture->GetTexture(),
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
