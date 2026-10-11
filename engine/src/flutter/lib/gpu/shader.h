// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_SHADER_H_
#define FLUTTER_LIB_GPU_SHADER_H_

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace flutter {
namespace gpu {

/// An immutable collection of shaders loaded from a shader bundle asset.
class Shader : public RefCountedDartWrappable<Shader> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Shader);

 public:
  struct UniformBinding {
    impeller::ShaderUniformSlot slot;
    impeller::ShaderMetadata metadata;
    size_t size_in_bytes = 0;

    const impeller::ShaderStructMemberMetadata* GetMemberMetadata(
        const std::string& name) const;
  };

  struct TextureBinding {
    impeller::SampledImageSlot slot;
    impeller::ShaderMetadata metadata;
  };

  struct StorageBufferBinding {
    /// How the shader accesses the buffer, from its `readonly` or `writeonly`
    /// qualifier.
    enum class Access {
      kReadWrite,
      kReadOnly,
      kWriteOnly,
    };

    impeller::ShaderUniformSlot slot;
    /// Names the buffer. Binding sets and compute passes also use its address
    /// to identify the binding.
    impeller::ShaderMetadata metadata;
    Access access = Access::kReadWrite;
    /// The size of the block, counting a trailing runtime-sized array as empty.
    size_t size_in_bytes = 0;
    /// The stride of the block's trailing runtime-sized array, or zero if the
    /// block does not end in one.
    size_t runtime_array_stride = 0;
  };

  ~Shader() override;

  static fml::RefPtr<Shader> Make(
      std::string library_id,
      std::string entrypoint,
      impeller::ShaderStage stage,
      std::shared_ptr<fml::Mapping> code_mapping,
      std::vector<impeller::ShaderStageIOSlot> inputs,
      std::vector<impeller::ShaderStageBufferLayout> layouts,
      std::unordered_map<std::string, UniformBinding> uniform_structs,
      std::unordered_map<std::string, TextureBinding> uniform_textures,
      std::vector<impeller::DescriptorSetLayout> descriptor_set_layouts,
      std::unordered_map<std::string, StorageBufferBinding> storage_buffers =
          {},
      std::optional<std::array<uint32_t, 3>> workgroup_size = std::nullopt);

  std::shared_ptr<const impeller::ShaderFunction> GetFunctionFromLibrary(
      impeller::ShaderLibrary& library);

  bool IsRegistered(Context& context);

  bool RegisterSync(Context& context);

  /// Whether this shader needs to be re-registered with the impeller shader
  /// library on next use. Fresh shaders start dirty. Set back to false by
  /// `RegisterSync` after registration completes, and back to true by
  /// `ResetFrom` when the underlying asset is reloaded.
  bool IsDirty() const;

  void SetClean();

  /// Replaces this shader's payload (code, layouts, uniforms) with the data
  /// from `other`, preserving the library_id / entrypoint registry key and
  /// marking this shader dirty. Used by `ShaderLibrary` to reload a shader
  /// bundle in place without breaking existing Dart wrappers.
  void ResetFrom(Shader& other);

  std::shared_ptr<impeller::VertexDescriptor> CreateVertexDescriptor() const;

  const std::vector<impeller::ShaderStageIOSlot>& GetStageInputs() const;

  const std::vector<impeller::ShaderStageBufferLayout>& GetStageBufferLayouts()
      const;

  const std::vector<impeller::DescriptorSetLayout>& GetDescriptorSetLayouts()
      const;

  impeller::ShaderStage GetShaderStage() const;

  /// The shader's entrypoint name, for identifying it in error messages.
  const std::string& GetEntrypoint() const;

  const Shader::UniformBinding* GetUniformStruct(const std::string& name) const;

  const Shader::TextureBinding* GetUniformTexture(
      const std::string& name) const;

  const Shader::StorageBufferBinding* GetStorageBuffer(
      const std::string& name) const;

  /// The workgroup size a compute shader declares, or std::nullopt for any
  /// other stage.
  const std::optional<std::array<uint32_t, 3>>& GetWorkgroupSize() const;

  /// The position of the named uniform struct in this shader's stable
  /// binding order, or -1. Indices stay valid until the shader's payload
  /// is replaced by a reload (`ResetFrom`); callers cache them to bind
  /// without passing the name across the FFI boundary on every draw.
  int GetUniformStructIndex(const std::string& name) const;

  /// The uniform struct at `index` in the stable binding order, or nullptr
  /// when the index is out of range.
  const Shader::UniformBinding* GetUniformStructAt(int index) const;

  /// The texture counterpart to `GetUniformStructIndex`.
  int GetUniformTextureIndex(const std::string& name) const;

  /// The texture counterpart to `GetUniformStructAt`.
  const Shader::TextureBinding* GetUniformTextureAt(int index) const;

  /// The storage buffer counterpart to `GetUniformStructIndex`.
  int GetStorageBufferIndex(const std::string& name) const;

  /// The storage buffer counterpart to `GetUniformStructAt`.
  const Shader::StorageBufferBinding* GetStorageBufferAt(int index) const;

 private:
  Shader();

  // Stable per-source identifier used to namespace this shader's entrypoint
  // in the shared shader registry. Set by ShaderLibrary at construction, and
  // shared by all shaders within the same library. Typically the asset path
  // the bundle was loaded from.
  std::string library_id_;
  std::string entrypoint_;
  impeller::ShaderStage stage_;
  std::shared_ptr<fml::Mapping> code_mapping_;
  std::vector<impeller::ShaderStageIOSlot> inputs_;
  std::vector<impeller::ShaderStageBufferLayout> layouts_;
  std::unordered_map<std::string, UniformBinding> uniform_structs_;
  std::unordered_map<std::string, TextureBinding> uniform_textures_;
  std::unordered_map<std::string, StorageBufferBinding> storage_buffers_;
  std::optional<std::array<uint32_t, 3>> workgroup_size_;
  // The maps' entries in a stable order for index-based lookup. Entry
  // pointers stay valid for the maps' lifetime (node-based containers);
  // rebuilt whenever the maps are replaced (`Make`, `ResetFrom`).
  std::vector<const UniformBinding*> uniform_struct_order_;
  std::vector<const TextureBinding*> uniform_texture_order_;
  std::vector<const StorageBufferBinding*> storage_buffer_order_;
  std::vector<impeller::DescriptorSetLayout> descriptor_set_layouts_;
  bool is_dirty_ = true;

  void RebuildBindingOrder();

  // Returns the scoped name to use when registering or looking up this
  // shader's function in a shared impeller::ShaderLibrary.
  std::string GetScopedName() const;

  FML_DISALLOW_COPY_AND_ASSIGN(Shader);
};

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

extern "C" {

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetUniformStructSize(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetUniformMemberOffset(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle,
    Dart_Handle member_name_handle);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetUniformStructIndex(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetUniformTextureIndex(
    flutter::gpu::Shader* wrapper,
    Dart_Handle texture_name_handle);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetStorageBufferIndex(
    flutter::gpu::Shader* wrapper,
    Dart_Handle storage_buffer_name_handle);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetStorageBufferSizeAt(
    flutter::gpu::Shader* wrapper,
    int storage_buffer_index);

FLUTTER_GPU_EXPORT
extern int InternalFlutterGpu_Shader_GetStorageBufferRuntimeArrayStrideAt(
    flutter::gpu::Shader* wrapper,
    int storage_buffer_index);

// Test-only: exposes the per-shader dirty bit so tests can assert that
// reload deduplication keeps unchanged shaders clean.
FLUTTER_GPU_EXPORT
extern bool InternalFlutterGpu_Shader_DebugIsDirty(
    flutter::gpu::Shader* wrapper);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_SHADER_H_
