// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_SHADER_BUNDLE_DATA_H_
#define FLUTTER_IMPELLER_COMPILER_SHADER_BUNDLE_DATA_H_

#include <cstdint>
#include <memory>
#include <vector>

#include "flutter/fml/mapping.h"
#include "impeller/compiler/types.h"
#include "impeller/shader_bundle/shader_bundle_flatbuffers.h"

namespace impeller {
namespace compiler {

class ShaderBundleData {
 public:
  struct ShaderUniformStructField {
    std::string name;
    spirv_cross::SPIRType::BaseType type =
        spirv_cross::SPIRType::BaseType::Float;
    size_t offset_in_bytes = 0u;
    size_t element_size_in_bytes = 0u;
    size_t total_size_in_bytes = 0u;
    std::optional<size_t> array_elements = std::nullopt;
    // Component count of a single column. For non-matrix types this is the
    // vector length; for matrices this is the row count.
    size_t vec_size = 0u;
    // The number of columns. 1 for scalars and vectors; N for an NxN matrix.
    size_t columns = 0u;
  };

  struct ShaderUniformStruct {
    std::string name;
    size_t ext_res_0 = 0u;
    size_t set = 0u;
    size_t binding = 0u;
    size_t size_in_bytes = 0u;
    std::vector<ShaderUniformStructField> fields;
  };

  struct ShaderUniformTexture {
    std::string name;
    size_t ext_res_0 = 0u;
    size_t set = 0u;
    size_t binding = 0u;
  };

  struct ShaderStorageBuffer {
    std::string name;
    size_t ext_res_0 = 0u;
    size_t set = 0u;
    size_t binding = 0u;
    // False when every member of the buffer block is `readonly`.
    bool writable = true;
  };

  // The compute workgroup size. A 0 in any dimension means that dimension is
  // sized by a specialization constant. All 0 for non-compute stages.
  struct WorkgroupSize {
    uint32_t x = 0u;
    uint32_t y = 0u;
    uint32_t z = 0u;
  };

  ShaderBundleData(std::string entrypoint,
                   spv::ExecutionModel stage,
                   TargetPlatform target_platform);

  ~ShaderBundleData();

  void AddUniformStruct(ShaderUniformStruct uniform_struct);

  void AddUniformTexture(ShaderUniformTexture uniform_texture);

  void AddStorageBuffer(ShaderStorageBuffer storage_buffer);

  void SetWorkgroupSize(WorkgroupSize workgroup_size);

  void AddInputDescription(InputDescription input);

  void SetShaderData(std::shared_ptr<fml::Mapping> shader);

  void SetSkSLData(std::shared_ptr<fml::Mapping> sksl);

  std::unique_ptr<fb::shaderbundle::BackendShaderT> CreateFlatbuffer() const;

 private:
  const std::string entrypoint_;
  const spv::ExecutionModel stage_;
  const TargetPlatform target_platform_;
  std::vector<ShaderUniformStruct> uniform_structs_;
  std::vector<ShaderUniformTexture> uniform_textures_;
  std::vector<ShaderStorageBuffer> storage_buffers_;
  WorkgroupSize workgroup_size_;
  std::vector<InputDescription> inputs_;
  std::shared_ptr<fml::Mapping> shader_;
  std::shared_ptr<fml::Mapping> sksl_;

  ShaderBundleData(const ShaderBundleData&) = delete;

  ShaderBundleData& operator=(const ShaderBundleData&) = delete;
};

}  // namespace compiler
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_SHADER_BUNDLE_DATA_H_
