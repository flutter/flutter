// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RENDER_PIPELINE_H_
#define FLUTTER_LIB_GPU_RENDER_PIPELINE_H_

#include <memory>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace flutter {
namespace gpu {

class RenderPipeline : public RefCountedDartWrappable<RenderPipeline> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(RenderPipeline);

 public:
  RenderPipeline(fml::RefPtr<flutter::gpu::Shader> vertex_shader,
                 fml::RefPtr<flutter::gpu::Shader> fragment_shader,
                 std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor);

  ~RenderPipeline() override;

  void BindToPipelineDescriptor(impeller::ShaderLibrary& library,
                                impeller::PipelineDescriptor& desc);

 private:
  fml::RefPtr<flutter::gpu::Shader> vertex_shader_;
  fml::RefPtr<flutter::gpu::Shader> fragment_shader_;
  // Vertex descriptor used at pipeline-build time. When the caller passes
  // a custom `VertexLayout` to `GpuContext.createRenderPipeline`, this is
  // built from that layout against the vertex shader's reflection metadata.
  // Otherwise it is the impellerc-generated default for the vertex shader.
  //
  // Shared rather than unique because `impeller::PipelineDescriptor::
  // SetVertexDescriptor` stores its argument as `shared_ptr<VertexDescriptor>`
  // and `impeller::VertexDescriptor` is non-copyable; we have to keep a
  // reference here so the descriptor remains valid across the many
  // `BindToPipelineDescriptor` calls a single pipeline may participate in.
  std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor_;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPipeline);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_RenderPipeline_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    flutter::gpu::Shader* vertex_shader,
    flutter::gpu::Shader* fragment_shader,
    Dart_Handle buffer_layouts_handle,
    Dart_Handle attributes_handle,
    Dart_Handle attribute_names_handle);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_RENDER_PIPELINE_H_
