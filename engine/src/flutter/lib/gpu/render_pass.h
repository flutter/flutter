// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RENDER_PASS_H_
#define FLUTTER_LIB_GPU_RENDER_PASS_H_

#include <array>
#include <cstdint>
#include <map>
#include <memory>
#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/recording.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "lib/gpu/device_buffer.h"
#include "lib/gpu/render_pipeline.h"
#include "lib/gpu/texture.h"

namespace flutter {
namespace gpu {

class RenderPass : public RefCountedDartWrappable<RenderPass> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(RenderPass);

 public:
  RenderPass();

  ~RenderPass() override;

  impeller::RenderTarget& GetRenderTarget();
  const impeller::RenderTarget& GetRenderTarget() const;

  impeller::ColorAttachmentDescriptor& GetColorAttachmentDescriptor(
      size_t color_attachment_index);

  impeller::DepthAttachmentDescriptor& GetDepthAttachmentDescriptor();

  impeller::StencilAttachmentDescriptor& GetStencilFrontAttachmentDescriptor();

  impeller::StencilAttachmentDescriptor& GetStencilBackAttachmentDescriptor();

  impeller::PipelineDescriptor& GetPipelineDescriptor();

  /// Adds this pass's recording to [command_buffer], which replays it on the
  /// raster thread when submitted. Fails when the render target is invalid
  /// or the command buffer was already submitted.
  bool Begin(flutter::gpu::CommandBuffer& command_buffer);

  void SetPipeline(fml::RefPtr<RenderPipeline> pipeline);

  /// Set the face culling mode for subsequent draws.
  void SetCullMode(impeller::CullMode mode);

  /// Set the front-face winding order for subsequent draws.
  void SetWindingOrder(impeller::WindingOrder order);

  /// Set the primitive topology for subsequent draws.
  void SetPrimitiveType(impeller::PrimitiveType type);

  /// Set the polygon fill mode for subsequent draws.
  void SetPolygonMode(impeller::PolygonMode mode);

  /// The number of binding set slots a pass can hold at once. Mirrors
  /// `RenderPass.maxBindingSets` in `gpu/lib/src/render_pass.dart`.
  static constexpr size_t kMaxBindingSets = 4;

  /// Mirrors `impeller::kMaxVertexBuffers`. Index `i` corresponds to the
  /// binding declared at slot `i` in the active VertexLayout.
  static constexpr size_t kMaxVertexBufferSlots = 16;

  /// Puts [set] in [slot], replacing whatever was there. Passing a null set
  /// empties the slot. Out of range slots are ignored.
  void BindSet(size_t slot, fml::RefPtr<BindingSet> set);

  void ClearBindings();

  /// Records [binding] of [shader] reading [length_in_bytes] of [buffer] at
  /// [offset_in_bytes]. Returns false when the binding is missing, the
  /// shader's stage takes no bindings, or the view runs past the buffer.
  bool BindUniform(Shader& shader,
                   const Shader::UniformBinding* binding,
                   const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
                   size_t offset_in_bytes,
                   size_t length_in_bytes);

  /// The texture counterpart to `BindUniform`. The sampler is resolved when
  /// the pass is replayed.
  bool BindTexture(Shader& shader,
                   const Shader::TextureBinding* binding,
                   std::shared_ptr<const impeller::Texture> texture,
                   const impeller::SamplerDescriptor& sampler);

  void BindVertexBuffer(size_t slot, impeller::BufferView view);

  void BindIndexBuffer(impeller::BufferView view, impeller::IndexType type);

  void SetStencilReference(uint32_t reference);

  void SetScissor(impeller::IRect32 scissor);

  void SetViewport(impeller::Viewport viewport);

  /// Records a draw. [element_count] is the vertex count for a non-indexed
  /// draw, or the index count when [indexed] is true. Returns false when the
  /// pass cannot record (not begun, or already submitted), when an indexed
  /// draw has no index buffer, or when the backend already failed to build
  /// the pipeline for the current state. A first build failure is only
  /// known at replay, so that draw is dropped there and later draws with the
  /// same state fail here.
  bool Draw(size_t element_count, size_t instance_count, bool indexed);

  /// Whether the next draw must snapshot the pipeline state. Exposed for
  /// testing the dirty tracking.
  bool IsPipelineStateDirtyForTesting() const;

  /// Clears the pipeline dirty flag without snapshotting, so tests can
  /// observe which mutations re-dirty it.
  void ClearPipelineStateDirtyForTesting();

  const RenderPassRecording& GetRecordingForTesting() const;

  /// The sets bound to each slot, for inspection. The recording holds
  /// snapshots of their contents.
  std::array<fml::RefPtr<BindingSet>, kMaxBindingSets> binding_sets;

 private:
  /// The recording while ops may still be added to it, or null once the
  /// command buffer it was added to has been submitted.
  RenderPassRecording* OpenRecording();

  /// Snapshots the pipeline-affecting state for the draws that follow.
  void RecordPipelineState();

  // The non-dirtying counterpart of GetColorAttachmentDescriptor, for the
  // pipeline snapshot itself.
  impeller::ColorAttachmentDescriptor& ColorAttachmentDescriptorAt(
      size_t color_attachment_index);

  std::shared_ptr<RenderPassRecording> recording_;
  bool begun_ = false;

  bool pipeline_state_dirty_ = true;
  // Index of the snapshot recorded for the current state, valid while the
  // state is clean and `pipeline_known_failed_` is false.
  uint32_t pipeline_state_index_ = 0;
  // Whether the backend already failed to build the current state.
  bool pipeline_known_failed_ = false;

  impeller::IndexType index_buffer_type_ = impeller::IndexType::kNone;

  impeller::RenderTarget render_target_;

  // Command encoding state.
  fml::RefPtr<RenderPipeline> render_pipeline_;
  impeller::PipelineDescriptor pipeline_descriptor_;

  // Pipeline descriptor layout state. We always keep track of this state,
  // but we'll only apply it as necessary to match the RenderTarget.
  std::map<size_t, impeller::ColorAttachmentDescriptor> color_descriptors_;
  impeller::StencilAttachmentDescriptor stencil_front_desc_;
  impeller::StencilAttachmentDescriptor stencil_back_desc_;
  impeller::DepthAttachmentDescriptor depth_desc_;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_Initialize(Dart_Handle wrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_RenderPass_SetColorAttachment(
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
    int slice);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_RenderPass_SetDepthStencilAttachment(
    flutter::gpu::RenderPass* wrapper,
    int depth_load_action,
    int depth_store_action,
    float depth_clear_value,
    int stencil_load_action,
    int stencil_store_action,
    int stencil_clear_value,
    flutter::gpu::Texture* texture,
    int mip_level,
    int slice);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_RenderPass_Begin(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::CommandBuffer* command_buffer);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_BindPipeline(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::RenderPipeline* pipeline);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_BindVertexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int slot);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_BindIndexBufferDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes,
    int index_type);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_BindUniformDevice(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    Dart_Handle uniform_name_handle,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_BindTexture(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    Dart_Handle uniform_name_handle,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_BindTextureIndexed(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_texture_index,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_BindSet(
    flutter::gpu::RenderPass* wrapper,
    flutter::gpu::BindingSet* binding_set,
    int slot);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_ClearBindings(
    flutter::gpu::RenderPass* wrapper);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetColorBlendEnable(
    flutter::gpu::RenderPass* wrapper,
    int color_attachment_index,
    bool enable);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetColorBlendEquation(
    flutter::gpu::RenderPass* wrapper,
    int color_attachment_index,
    int color_blend_operation,
    int source_color_blend_factor,
    int destination_color_blend_factor,
    int alpha_blend_operation,
    int source_alpha_blend_factor,
    int destination_alpha_blend_factor);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetDepthWriteEnable(
    flutter::gpu::RenderPass* wrapper,
    bool enable);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetDepthCompareOperation(
    flutter::gpu::RenderPass* wrapper,
    int compare_operation);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetStencilReference(
    flutter::gpu::RenderPass* wrapper,
    int stencil_reference);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetStencilConfig(
    flutter::gpu::RenderPass* wrapper,
    int stencil_compare_operation,
    int stencil_fail_operation,
    int depth_fail_operation,
    int depth_stencil_pass_operation,
    int read_mask,
    int write_mask,
    int target);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetScissor(
    flutter::gpu::RenderPass* wrapper,
    int x,
    int y,
    int width,
    int height);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetViewport(
    flutter::gpu::RenderPass* wrapper,
    int x,
    int y,
    int width,
    int height,
    float z_near,
    float z_far);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetCullMode(
    flutter::gpu::RenderPass* wrapper,
    int cull_mode);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetPrimitiveType(
    flutter::gpu::RenderPass* wrapper,
    int primitive_type);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetWindingOrder(
    flutter::gpu::RenderPass* wrapper,
    int winding_order);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_RenderPass_SetPolygonMode(
    flutter::gpu::RenderPass* wrapper,
    int polygon_mode);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_Draw(
    flutter::gpu::RenderPass* wrapper,
    int vertex_count,
    int instance_count);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_RenderPass_DrawIndexed(
    flutter::gpu::RenderPass* wrapper,
    int index_count,
    int instance_count);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_RENDER_PASS_H_
