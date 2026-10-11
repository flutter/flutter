// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_COMPUTE_PASS_H_
#define FLUTTER_LIB_GPU_COMPUTE_PASS_H_

#include <array>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <unordered_map>

#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/compute_pipeline.h"
#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/gpu/texture.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/raw_ptr.h"
#include "impeller/core/sampler.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/compute_pass.h"
#include "impeller/renderer/pipeline.h"

namespace flutter {
namespace gpu {

/// A pass that dispatches compute work, recorded into a command buffer.
///
/// Bindings are kept here, keyed by the shader binding they fill, and applied
/// to the backend pass at the next dispatch after they change. They persist
/// across dispatches until replaced or cleared.
class ComputePass : public RefCountedDartWrappable<ComputePass> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ComputePass);

 public:
  ComputePass();

  ~ComputePass() override;

  /// Ends the command buffer's open pass and starts recording this one.
  bool Begin(flutter::gpu::CommandBuffer& command_buffer);

  /// Ends this pass if it is still the command buffer's open pass. Does
  /// nothing if a later command already ended it.
  bool End();

  /// The context of the command buffer this pass records into. Null before
  /// `Begin`.
  const std::shared_ptr<impeller::Context>& GetContext() const;

  void SetPipeline(fml::RefPtr<ComputePipeline> pipeline);

  /// Binds a uniform struct of a compute shader. Returns false if `binding`
  /// is null, `shader` is not a compute shader, or the view runs past the end
  /// of `buffer`.
  bool BindUniform(const Shader& shader,
                   const Shader::UniformBinding* binding,
                   const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
                   size_t offset_in_bytes,
                   size_t length_in_bytes);

  /// The storage buffer counterpart to `BindUniform`.
  bool BindStorageBuffer(
      const Shader& shader,
      const Shader::StorageBufferBinding* binding,
      const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
      size_t offset_in_bytes,
      size_t length_in_bytes);

  /// The texture counterpart to `BindUniform`. Returns false if the texture
  /// or sampler is null.
  bool BindTexture(const Shader& shader,
                   const Shader::TextureBinding* binding,
                   std::shared_ptr<const impeller::Texture> texture,
                   impeller::raw_ptr<const impeller::Sampler> sampler);

  /// The number of binding set slots a pass can hold at once. Mirrors
  /// `ComputePass.maxBindingSets` in `gpu/lib/src/compute_pass.dart`.
  static constexpr size_t kMaxBindingSets = 4;

  /// Puts [set] in [slot], replacing whatever was there. Passing a null set
  /// empties the slot. Out of range slots are ignored.
  void BindSet(size_t slot, fml::RefPtr<BindingSet> set);

  void ClearBindings();

  /// Dispatches a grid of workgroups with the bound pipeline and bindings.
  /// Returns an error message if nothing is bound, a binding the shader
  /// declares is missing, the count exceeds the device limit, or the backend
  /// fails. Dispatching zero workgroups along any dimension does nothing.
  std::optional<std::string> Dispatch(std::array<uint32_t, 3> workgroup_count);

  /// Hands the backend pass a resource for every binding `shader` declares,
  /// taking each from an individual bind if there is one, and otherwise from
  /// the highest binding set slot that holds it. Returns an error naming the
  /// first binding with no resource. Called by `Dispatch` whenever a binding
  /// or the pipeline changed since the last dispatch.
  std::optional<std::string> ApplyBindings(const Shader& shader);

 private:
  struct TextureBinding {
    std::shared_ptr<const impeller::Texture> texture;
    impeller::raw_ptr<const impeller::Sampler> sampler;
  };

  std::shared_ptr<impeller::Context> context_;
  std::shared_ptr<impeller::ComputePass> compute_pass_;
  fml::RefPtr<CommandBuffer> command_buffer_;

  fml::RefPtr<ComputePipeline> pipeline_;
  // The backend pipeline last set on `compute_pass_`.
  std::shared_ptr<impeller::Pipeline<impeller::ComputePipelineDescriptor>>
      bound_pipeline_;

  // Individual bindings, keyed by the shader metadata of the binding they
  // fill, which is unique to each binding of each shader.
  // Uniform and storage buffers.
  std::unordered_map<const impeller::ShaderMetadata*, impeller::BufferView>
      buffer_bindings_;
  std::unordered_map<const impeller::ShaderMetadata*, TextureBinding>
      texture_bindings_;
  std::array<fml::RefPtr<BindingSet>, kMaxBindingSets> binding_sets_;
  // Whether a binding changed since the backend pass last received them.
  bool bindings_dirty_ = true;

  FML_DISALLOW_COPY_AND_ASSIGN(ComputePass);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_ComputePass_Initialize(Dart_Handle wrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_ComputePass_Begin(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::CommandBuffer* command_buffer);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_ComputePass_End(
    flutter::gpu::ComputePass* wrapper);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_ComputePass_BindPipeline(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::ComputePipeline* pipeline);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_ComputePass_BindUniformIndexed(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_ComputePass_BindStorageBufferIndexed(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::Shader* shader,
    int storage_buffer_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_ComputePass_BindTextureIndexed(
    flutter::gpu::ComputePass* wrapper,
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
extern void InternalFlutterGpu_ComputePass_BindSet(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::BindingSet* binding_set,
    int slot);

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_ComputePass_ClearBindings(
    flutter::gpu::ComputePass* wrapper);

FLUTTER_GPU_EXPORT
extern Dart_Handle InternalFlutterGpu_ComputePass_Dispatch(
    flutter::gpu::ComputePass* wrapper,
    int workgroup_count_x,
    int workgroup_count_y,
    int workgroup_count_z);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_COMPUTE_PASS_H_
