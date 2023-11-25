// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/pipeline_library.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, RenderPass);

RenderPass::RenderPass()
    : vertex_buffer_(
          impeller::VertexBuffer{.index_type = impeller::IndexType::kNone}){};

RenderPass::~RenderPass() = default;

const std::weak_ptr<const impeller::Context>& RenderPass::GetContext() const {
  return render_pass_->GetContext();
}

impeller::Command& RenderPass::GetCommand() {
  return command_;
}

const impeller::Command& RenderPass::GetCommand() const {
  return command_;
}

impeller::RenderTarget& RenderPass::GetRenderTarget() {
  return render_target_;
}

const impeller::RenderTarget& RenderPass::GetRenderTarget() const {
  return render_target_;
}

impeller::VertexBuffer& RenderPass::GetVertexBuffer() {
  return vertex_buffer_;
}

bool RenderPass::Begin(flutter::gpu::CommandBuffer& command_buffer) {
  render_pass_ =
      command_buffer.GetCommandBuffer()->CreateRenderPass(render_target_);
  if (!render_pass_) {
    return false;
  }
  command_buffer.AddRenderPass(render_pass_);
  return true;
}

void RenderPass::SetPipeline(fml::RefPtr<RenderPipeline> pipeline) {
  render_pipeline_ = std::move(pipeline);
}

std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>
RenderPass::GetOrCreatePipeline() {
  // Infer the pipeline layout based on the shape of the RenderTarget.
  auto pipeline_desc = pipeline_descriptor_;
  {
    FML_DCHECK(render_target_.HasColorAttachment(0))
        << "The render target has no color attachment. This should never "
           "happen.";
    color_desc_.format = render_target_.GetRenderTargetPixelFormat();
    pipeline_desc.SetColorAttachmentDescriptor(0, color_desc_);
  }

  if (auto stencil = render_target_.GetStencilAttachment()) {
    pipeline_desc.SetStencilPixelFormat(
        stencil->texture->GetTextureDescriptor().format);
    pipeline_desc.SetStencilAttachmentDescriptors(stencil_front_desc_,
                                                  stencil_back_desc_);
  } else {
    pipeline_desc.ClearStencilAttachments();
  }

  if (auto depth = render_target_.GetDepthAttachment()) {
    pipeline_desc.SetDepthStencilAttachmentDescriptor(depth_desc_);
  } else {
    pipeline_desc.ClearDepthAttachment();
  }

  auto& context = *GetContext().lock();

  render_pipeline_->BindToPipelineDescriptor(*context.GetShaderLibrary(),
                                             pipeline_desc);

  auto pipeline =
      context.GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  FML_DCHECK(pipeline) << "Couldn't resolve render pipeline";
  return pipeline;
}

impeller::Command RenderPass::ProvisionRasterCommand() {
  impeller::Command result = command_;

  result.pipeline = GetOrCreatePipeline();
  result.BindVertices(vertex_buffer_);

  return result;
}

bool RenderPass::Draw() {
  impeller::Command result = ProvisionRasterCommand();
  return render_pass_->AddCommand(std::move(result));
}

}  // namespace gpu
}  // namespace flutter

static impeller::Color ToImpellerColor(uint32_t argb) {
  return impeller::Color::MakeRGBA8((argb >> 16) & 0xFF,  // R
                                    (argb >> 8) & 0xFF,   // G
                                    argb & 0xFF,          // B
                                    argb >> 24);          // A
}

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_RenderPass_Initialize(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::gpu::RenderPass>();
  res->AssociateWithDartWrapper(wrapper);
}

Dart_Handle InternalFlutterGpu_RenderPass_SetColorAttachment(
    flutter::gpu::RenderPass* wrapper,
    int load_action,
    int store_action,
    int clear_color,
    flutter::gpu::Texture* texture,
    Dart_Handle resolve_texture_wrapper) {
  impeller::ColorAttachment desc;
  desc.load_action = flutter::gpu::ToImpellerLoadAction(
      static_cast<flutter::gpu::FlutterGPULoadAction>(load_action));
  desc.store_action = flutter::gpu::ToImpellerStoreAction(
      static_cast<flutter::gpu::FlutterGPUStoreAction>(store_action));
  desc.clear_color = ToImpellerColor(static_cast<uint32_t>(clear_color));
  desc.texture = texture->GetTexture();
  if (!Dart_IsNull(resolve_texture_wrapper)) {
    flutter::gpu::Texture* resolve_texture =
        tonic::DartConverter<flutter::gpu::Texture*>::FromDart(
            resolve_texture_wrapper);
    desc.resolve_texture = resolve_texture->GetTexture();
  }
  wrapper->GetRenderTarget().SetColorAttachment(desc, 0);
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_RenderPass_SetStencilAttachment(
    flutter::gpu::RenderPass* wrapper,
    int load_action,
    int store_action,
    int clear_stencil,
    flutter::gpu::Texture* texture) {
  impeller::StencilAttachment desc;
  desc.load_action = flutter::gpu::ToImpellerLoadAction(
      static_cast<flutter::gpu::FlutterGPULoadAction>(load_action));
  desc.store_action = flutter::gpu::ToImpellerStoreAction(
      static_cast<flutter::gpu::FlutterGPUStoreAction>(store_action));
  desc.clear_stencil = clear_stencil;
  desc.texture = texture->GetTexture();
  wrapper->GetRenderTarget().SetStencilAttachment(desc);
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

template <typename TBuffer>
static void BindVertexBuffer(flutter::gpu::RenderPass* wrapper,
                             TBuffer* buffer,
                             int offset_in_bytes,
                             int length_in_bytes,
                             int vertex_count) {
  auto& vertex_buffer = wrapper->GetVertexBuffer();
  vertex_buffer.vertex_buffer = impeller::BufferView{
      .buffer = buffer->GetBuffer(),
      .range = impeller::Range(offset_in_bytes, length_in_bytes),
  };
  vertex_buffer.vertex_count = vertex_count;
}

void InternalFlutterGpu_RenderPass_BindVertexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int vertex_count) {
  BindVertexBuffer(wrapper, device_buffer, offset_in_bytes, length_in_bytes,
                   vertex_count);
}

void InternalFlutterGpu_RenderPass_BindVertexBufferHost(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::HostBuffer* host_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int vertex_count) {
  BindVertexBuffer(wrapper, host_buffer, offset_in_bytes, length_in_bytes,
                   vertex_count);
}

template <typename TBuffer>
static bool BindUniform(flutter::gpu::RenderPass* wrapper,
                        int stage,
                        int slot_id,
                        TBuffer* buffer,
                        int offset_in_bytes,
                        int length_in_bytes) {
  // TODO(113715): Populate this metadata once GLES is able to handle
  //               non-struct uniform names.
  std::shared_ptr<impeller::ShaderMetadata> metadata =
      std::make_shared<impeller::ShaderMetadata>();

  auto& command = wrapper->GetCommand();
  impeller::ShaderUniformSlot slot;
  // Don't populate the slot name... we don't have it here and Impeller doesn't
  // even use it for anything.
  slot.ext_res_0 = slot_id;
  return command.BindResource(
      flutter::gpu::ToImpellerShaderStage(
          static_cast<flutter::gpu::FlutterGPUShaderStage>(stage)),
      slot, metadata,
      impeller::BufferView{
          .buffer = buffer->GetBuffer(),
          .range = impeller::Range(offset_in_bytes, length_in_bytes),
      });
}

bool InternalFlutterGpu_RenderPass_BindUniformDevice(
    flutter::gpu::RenderPass* wrapper,
    int stage,
    int slot_id,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  return BindUniform(wrapper, stage, slot_id, device_buffer, offset_in_bytes,
                     length_in_bytes);
}

bool InternalFlutterGpu_RenderPass_BindUniformHost(
    flutter::gpu::RenderPass* wrapper,
    int stage,
    int slot_id,
    flutter::gpu::HostBuffer* host_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  return BindUniform(wrapper, stage, slot_id, host_buffer, offset_in_bytes,
                     length_in_bytes);
}

bool InternalFlutterGpu_RenderPass_Draw(flutter::gpu::RenderPass* wrapper) {
  return wrapper->Draw();
}
