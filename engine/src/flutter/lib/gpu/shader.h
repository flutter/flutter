// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_SHADER_H_
#define FLUTTER_LIB_GPU_SHADER_H_

#include <algorithm>
#include <memory>
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

  ~Shader() override;

  static fml::RefPtr<Shader> Make(
      std::string entrypoint,
      impeller::ShaderStage stage,
      std::shared_ptr<fml::Mapping> code_mapping,
      std::shared_ptr<impeller::VertexDescriptor> vertex_desc,
      std::unordered_map<std::string, UniformBinding> uniform_structs,
      std::unordered_map<std::string, impeller::SampledImageSlot>
          uniform_textures);

  std::shared_ptr<const impeller::ShaderFunction> GetFunctionFromLibrary(
      impeller::ShaderLibrary& library);

  bool IsRegistered(Context& context);

  bool RegisterSync(Context& context);

  std::shared_ptr<impeller::VertexDescriptor> GetVertexDescriptor() const;

  impeller::ShaderStage GetShaderStage() const;

  const Shader::UniformBinding* GetUniformStruct(const std::string& name) const;

  const impeller::SampledImageSlot* GetUniformTexture(
      const std::string& name) const;

 private:
  Shader();

  std::string entrypoint_;
  impeller::ShaderStage stage_;
  std::shared_ptr<fml::Mapping> code_mapping_;
  std::shared_ptr<impeller::VertexDescriptor> vertex_desc_;
  std::unordered_map<std::string, UniformBinding> uniform_structs_;
  std::unordered_map<std::string, impeller::SampledImageSlot> uniform_textures_;

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

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_SHADER_H_
