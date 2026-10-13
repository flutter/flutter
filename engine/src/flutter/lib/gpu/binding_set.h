// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_BINDING_SET_H_
#define FLUTTER_LIB_GPU_BINDING_SET_H_

#include <memory>
#include <vector>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/export.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/gpu/texture.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/raw_ptr.h"
#include "impeller/core/sampler.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/texture.h"

namespace flutter {
namespace gpu {

/// A group of uniform and texture bindings, resolved against shader
/// reflection once at creation and replayed by every draw that binds it.
///
/// Binding the set on a render pass costs one slot assignment no matter how
/// many resources it holds, so a renderer that draws many nodes with the same
/// material stops paying per-resource bind work per draw.
class BindingSet : public RefCountedDartWrappable<BindingSet> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(BindingSet);

 public:
  struct BufferBinding {
    impeller::ShaderStage stage;
    impeller::ShaderUniformSlot slot;
    /// Borrowed from the shader that declared the binding, which this set
    /// keeps alive.
    const impeller::ShaderMetadata* metadata;
    impeller::BufferView view;
  };

  struct TextureBinding {
    impeller::ShaderStage stage;
    impeller::SampledImageSlot slot;
    const impeller::ShaderMetadata* metadata;
    std::shared_ptr<const impeller::Texture> texture;
    /// Owned by the context's sampler library, which caches it for the
    /// context's lifetime. The Dart wrapper holds the context that resolved
    /// this binding, so the sampler outlives the set.
    impeller::raw_ptr<const impeller::Sampler> sampler;
  };

  BindingSet();

  ~BindingSet() override;

  /// Appends the uniform struct at `uniform_struct_index` in `shader`'s
  /// binding order, viewing `length_in_bytes` of `buffer` starting at
  /// `offset_in_bytes`. Returns false when the index names no struct, the
  /// shader's stage takes no uniform bindings, or the view runs past the end
  /// of the buffer.
  bool AddUniform(Shader& shader,
                  int uniform_struct_index,
                  const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
                  size_t offset_in_bytes,
                  size_t length_in_bytes);

  /// The texture counterpart to `AddUniform`.
  bool AddTexture(Shader& shader,
                  int uniform_texture_index,
                  std::shared_ptr<const impeller::Texture> texture,
                  impeller::raw_ptr<const impeller::Sampler> sampler);

  /// Drops every binding so the set can be repopulated. Used when a shader
  /// reload replaces the reflection data the bindings resolved against.
  void Clear();

  const std::vector<BufferBinding>& GetBufferBindings() const;

  const std::vector<TextureBinding>& GetTextureBindings() const;

 private:
  /// Keeps `shader` alive for this set's lifetime, since the bindings point
  /// into reflection data the shader owns.
  void RetainShader(Shader& shader);

  std::vector<BufferBinding> buffer_bindings_;
  std::vector<TextureBinding> texture_bindings_;
  std::vector<fml::RefPtr<Shader>> shaders_;

  FML_DISALLOW_COPY_AND_ASSIGN(BindingSet);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern void InternalFlutterGpu_BindingSet_Initialize(Dart_Handle wrapper);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_BindingSet_AddUniform(
    flutter::gpu::BindingSet* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes);

FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_BindingSet_AddTexture(
    flutter::gpu::BindingSet* wrapper,
    flutter::gpu::Context* context,
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
extern void InternalFlutterGpu_BindingSet_Clear(
    flutter::gpu::BindingSet* wrapper);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_BINDING_SET_H_
