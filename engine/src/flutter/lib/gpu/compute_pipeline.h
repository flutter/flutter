// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_COMPUTE_PIPELINE_H_
#define FLUTTER_LIB_GPU_COMPUTE_PIPELINE_H_

#include <memory>
#include <string>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/renderer/compute_pipeline_descriptor.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline.h"

namespace flutter {
namespace gpu {

/// A compute pipeline built from a single compute shader.
class ComputePipeline : public RefCountedDartWrappable<ComputePipeline> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ComputePipeline);

 public:
  explicit ComputePipeline(fml::RefPtr<Shader> shader);

  ~ComputePipeline() override;

  const fml::RefPtr<Shader>& GetShader() const;

  /// Returns the backend pipeline for the shader's current code, building it
  /// on first use. A hot reload marks the shader dirty, which re-registers it
  /// (evicting the pipelines built from the old code) and builds a new
  /// pipeline here. Returns null and sets `out_error` if the shader cannot be
  /// registered or the pipeline cannot be built, for example because the
  /// shader's workgroup size exceeds the device limits.
  std::shared_ptr<impeller::Pipeline<impeller::ComputePipelineDescriptor>>
  GetOrCreatePipeline(impeller::Context& context, std::string& out_error);

 private:
  fml::RefPtr<Shader> shader_;
  std::shared_ptr<impeller::Pipeline<impeller::ComputePipelineDescriptor>>
      pipeline_;

  FML_DISALLOW_COPY_AND_ASSIGN(ComputePipeline);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_ComputePipeline_Initialize(
    Dart_Handle wrapper,
    flutter::gpu::Context* gpu_context,
    flutter::gpu::Shader* compute_shader);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_COMPUTE_PIPELINE_H_
