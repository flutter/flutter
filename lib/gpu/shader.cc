// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader.h"

#include <utility>

#include "fml/make_copyable.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_library.h"
#include "lib/gpu/shader_library.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, Shader);

Shader::Shader() = default;

Shader::~Shader() = default;

fml::RefPtr<Shader> Shader::Make(
    std::string entrypoint,
    impeller::ShaderStage stage,
    std::shared_ptr<fml::Mapping> code_mapping,
    std::vector<impeller::RuntimeUniformDescription> uniforms,
    std::shared_ptr<impeller::VertexDescriptor> vertex_desc) {
  auto shader = fml::MakeRefCounted<Shader>();
  shader->entrypoint_ = std::move(entrypoint);
  shader->stage_ = stage;
  shader->code_mapping_ = std::move(code_mapping);
  shader->uniforms_ = std::move(uniforms);
  shader->vertex_desc_ = std::move(vertex_desc);
  return shader;
}

std::shared_ptr<const impeller::ShaderFunction> Shader::GetFunctionFromLibrary(
    impeller::ShaderLibrary& library) {
  return library.GetFunction(entrypoint_, stage_);
}

bool Shader::IsRegistered(Context& context) {
  auto& lib = *context.GetContext()->GetShaderLibrary();
  return GetFunctionFromLibrary(lib) != nullptr;
}

bool Shader::RegisterSync(Context& context) {
  if (IsRegistered(context)) {
    return true;  // Already registered.
  }

  auto& lib = *context.GetContext()->GetShaderLibrary();

  std::promise<bool> promise;
  auto future = promise.get_future();
  lib.RegisterFunction(
      entrypoint_, stage_, code_mapping_,
      fml::MakeCopyable([promise = std::move(promise)](bool result) mutable {
        promise.set_value(result);
      }));
  if (!future.get()) {
    return false;  // Registration failed.
  }
  return true;
}

std::shared_ptr<impeller::VertexDescriptor> Shader::GetVertexDescriptor()
    const {
  return vertex_desc_;
}

impeller::ShaderStage Shader::GetShaderStage() const {
  return stage_;
}

int Shader::GetUniformSlot(const std::string& name) const {
  for (const auto& uniform : uniforms_) {
    if (name == uniform.name) {
      return uniform.location;
    }
  }
  return -1;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

int InternalFlutterGpu_Shader_GetShaderStage(flutter::gpu::Shader* wrapper) {
  return static_cast<int>(wrapper->GetShaderStage());
}

int InternalFlutterGpu_Shader_GetUniformSlot(flutter::gpu::Shader* wrapper,
                                             Dart_Handle name_handle) {
  auto name = tonic::StdStringFromDart(name_handle);
  return wrapper->GetUniformSlot(name);
}
