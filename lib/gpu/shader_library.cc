// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader_library.h"

#include <utility>

#include "flutter/lib/gpu/fixtures.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/mapping.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/renderer/vertex_descriptor.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace flutter {
namespace gpu {

// ===[ BEGIN MEMES ]===========================================================
static fml::RefPtr<Shader> OpenRuntimeStageAsShader(
    std::shared_ptr<fml::Mapping> payload,
    const std::shared_ptr<impeller::VertexDescriptor>& vertex_desc) {
  impeller::RuntimeStage stage(std::move(payload));
  return Shader::Make(stage.GetEntrypoint(),
                      ToShaderStage(stage.GetShaderStage()),
                      stage.GetCodeMapping(), stage.GetUniforms(), vertex_desc);
}

static void InstantiateTestShaderLibrary() {
  ShaderLibrary::ShaderMap shaders;
  auto vertex_desc = std::make_shared<impeller::VertexDescriptor>();
  vertex_desc->SetStageInputs(
      // TODO(bdero): The stage inputs need to be packed into the flatbuffer.
      FlutterGPUUnlitVertexShader::kAllShaderStageInputs,
      // TODO(bdero): Make the vertex attribute layout fully configurable.
      //              When encoding commands, allow for specifying a stride,
      //              type, and vertex buffer slot for each attribute.
      //              Provide a way to lookup vertex attribute slot locations by
      //              name from the shader.
      FlutterGPUUnlitVertexShader::kInterleavedBufferLayout);
  shaders["UnlitVertex"] = OpenRuntimeStageAsShader(
      std::make_shared<fml::NonOwnedMapping>(kFlutterGPUUnlitVertIPLR,
                                             kFlutterGPUUnlitVertIPLRLength),
      vertex_desc);
  shaders["UnlitFragment"] = OpenRuntimeStageAsShader(
      std::make_shared<fml::NonOwnedMapping>(kFlutterGPUUnlitFragIPLR,
                                             kFlutterGPUUnlitFragIPLRLength),
      nullptr);
  auto library = ShaderLibrary::MakeFromShaders(std::move(shaders));
  ShaderLibrary::SetOverride(library);
}
// ===[ END MEMES ]=============================================================

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, ShaderLibrary);

fml::RefPtr<ShaderLibrary> ShaderLibrary::override_shader_library_;

fml::RefPtr<ShaderLibrary> ShaderLibrary::MakeFromAsset(
    const std::string& name,
    std::string& out_error) {
  // ===========================================================================
  // This is a temporary hack to get the shader library populated in the
  // framework before the shader bundle format is landed!
  InstantiateTestShaderLibrary();
  // ===========================================================================

  if (override_shader_library_) {
    return override_shader_library_;
  }
  // TODO(bdero): Load the ShaderLibrary asset.
  out_error = "Shader bundle asset unimplemented";
  return nullptr;
}

fml::RefPtr<ShaderLibrary> ShaderLibrary::MakeFromShaders(ShaderMap shaders) {
  auto res =
      fml::MakeRefCounted<flutter::gpu::ShaderLibrary>(std::move(shaders));
  return res;
}

void ShaderLibrary::SetOverride(
    fml::RefPtr<ShaderLibrary> override_shader_library) {
  override_shader_library_ = std::move(override_shader_library);
}

fml::RefPtr<Shader> ShaderLibrary::GetShader(const std::string& shader_name,
                                             Dart_Handle shader_wrapper) const {
  auto it = shaders_.find(shader_name);
  if (it == shaders_.end()) {
    return nullptr;  // No matching shaders.
  }
  auto shader = it->second;

  if (shader->dart_wrapper() == nullptr) {
    shader->AssociateWithDartWrapper(shader_wrapper);
  }
  return shader;
}

ShaderLibrary::ShaderLibrary(ShaderMap shaders)
    : shaders_(std::move(shaders)) {}

ShaderLibrary::~ShaderLibrary() = default;

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_ShaderLibrary_InitializeWithAsset(
    Dart_Handle wrapper,
    Dart_Handle asset_name) {
  if (!Dart_IsString(asset_name)) {
    return tonic::ToDart("Asset name must be a string");
  }

  std::string error;
  auto res = flutter::gpu::ShaderLibrary::MakeFromAsset(
      tonic::StdStringFromDart(asset_name), error);
  if (!res) {
    return tonic::ToDart(error);
  }
  res->AssociateWithDartWrapper(wrapper);
  return Dart_Null();
}

Dart_Handle InternalFlutterGpu_ShaderLibrary_GetShader(
    flutter::gpu::ShaderLibrary* wrapper,
    Dart_Handle shader_name,
    Dart_Handle shader_wrapper) {
  FML_DCHECK(Dart_IsString(shader_name));
  auto shader =
      wrapper->GetShader(tonic::StdStringFromDart(shader_name), shader_wrapper);
  if (!shader) {
    return Dart_Null();
  }
  return tonic::ToDart(shader.get());
}
