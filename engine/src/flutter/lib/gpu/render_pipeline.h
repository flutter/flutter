// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RENDER_PIPELINE_H_
#define FLUTTER_LIB_GPU_RENDER_PIPELINE_H_

#include <future>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_set>

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
  /// What resolving a backend pipeline needs, without the Dart wrapper, so a
  /// recording can hold it and drop it on any thread.
  class Core {
   public:
    Core(std::string vertex_name,
         std::string vertex_entrypoint,
         std::shared_future<bool> vertex_registration,
         std::string fragment_name,
         std::string fragment_entrypoint,
         std::shared_future<bool> fragment_registration,
         std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor);

    /// Sets the vertex descriptor and stage entrypoints on [desc], after
    /// waiting for the shader registrations current when the pipeline was
    /// created. Returns false (after a validation log naming the shader) when
    /// a registration failed or a stage's function is not in [library].
    [[nodiscard]] bool BindToPipelineDescriptor(
        impeller::ShaderLibrary& library,
        impeller::PipelineDescriptor& desc) const;

    /// Records that the backend failed to build the pipeline for the state
    /// hashed to [key], so later draws with that state fail on the recording
    /// thread instead of being dropped at replay.
    void MarkBuildFailed(size_t key) const;

    bool HasBuildFailed(size_t key) const;

   private:
    const std::string vertex_name_;
    const std::string vertex_entrypoint_;
    const std::shared_future<bool> vertex_registration_;
    const std::string fragment_name_;
    const std::string fragment_entrypoint_;
    const std::shared_future<bool> fragment_registration_;
    const std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor_;
    mutable std::mutex failed_mutex_;
    mutable std::unordered_set<size_t> failed_keys_;
  };

  RenderPipeline(fml::RefPtr<flutter::gpu::Shader> vertex_shader,
                 fml::RefPtr<flutter::gpu::Shader> fragment_shader,
                 std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor);

  ~RenderPipeline() override;

  /// Sets this pipeline's vertex descriptor and stage entrypoints on [desc].
  /// Returns false (after a validation log naming the shader) when either
  /// stage's function cannot be resolved from [library], in which case the
  /// descriptor must not be used to build a backend pipeline.
  [[nodiscard]] bool BindToPipelineDescriptor(
      impeller::ShaderLibrary& library,
      impeller::PipelineDescriptor& desc);

  const std::shared_ptr<const Core>& GetCore() const;

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
  std::shared_ptr<const Core> core_;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPipeline);
};

/// Checks that [vertex_shader] and [fragment_shader] are actually a vertex
/// and a fragment shader, returning an error message suitable for a Dart
/// exception when they are not (pairing the wrong stages otherwise fails
/// deep inside backend pipeline compilation with no useful signal).
const char* ValidateRenderPipelineShaderStages(const Shader& vertex_shader,
                                               const Shader& fragment_shader);

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
