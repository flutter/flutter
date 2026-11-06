// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RENDER_PIPELINE_H_
#define FLUTTER_LIB_GPU_RENDER_PIPELINE_H_

#include <atomic>
#include <cstdint>
#include <future>
#include <memory>
#include <mutex>
#include <string>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/pipeline_state.h"
#include "flutter/lib/gpu/retain_stamp.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/vertex_descriptor.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_set.h"

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

    /// A backend pipeline, or null if it failed to build.
    struct ResolvedPipeline {
      std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>
          pipeline;
      RetainStamp retain_stamp;
    };

    /// The backend pipeline for [state], built on first use. Only for use on
    /// the replay thread. The result is only valid until the next call.
    ///
    /// Keyed on plain data so that a state change costs one hash, instead of
    /// building a descriptor and looking it up in the pipeline library.
    const ResolvedPipeline& Resolve(impeller::Context& context,
                                    const PipelineState& state) const;

    /// Whether the backend failed to build the pipeline for [state], so that
    /// draws with that state fail on the recording thread instead of being
    /// dropped at replay.
    bool HasBuildFailed(const PipelineState& state) const;

    /// Tracks which recording last retained this core.
    const RetainStamp& GetRetainStamp() const { return retain_stamp_; }

   private:
    const std::string vertex_name_;
    const std::string vertex_entrypoint_;
    const std::shared_future<bool> vertex_registration_;
    const std::string fragment_name_;
    const std::string fragment_entrypoint_;
    const std::shared_future<bool> fragment_registration_;
    const std::shared_ptr<impeller::VertexDescriptor> vertex_descriptor_;
    RetainStamp retain_stamp_;

    // Replay thread only.
    mutable absl::
        flat_hash_map<PipelineState, ResolvedPipeline, PipelineState::Hash>
            resolved_;
    mutable uint64_t resolved_generation_ = 0;

    // Keeps the check on the recording thread free of locks and hashing,
    // since a pipeline almost never fails to build.
    mutable std::atomic<bool> has_failures_ = false;
    mutable std::mutex failed_mutex_;
    mutable absl::flat_hash_set<size_t> failed_keys_;
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
