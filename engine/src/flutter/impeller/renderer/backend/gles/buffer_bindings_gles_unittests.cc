// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/gles/buffer_bindings_gles.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/command.h"

namespace impeller {
namespace testing {

using ::testing::_;

TEST(BufferBindingsGLESTest, BindUniformData) {
  BufferBindingsGLES bindings;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;
  uniform_bindings["SHADERMETADATA.FOOBAR"] = 1;
  bindings.SetUniformBindings(std::move(uniform_bindings));
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, Uniform1fv(_, _, _)).Times(1);

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  std::vector<BufferResource> bound_buffers;
  std::vector<TextureAndSampler> bound_textures;

  ShaderMetadata shader_metadata = {
      .name = "shader_metadata",
      .members = {
          ShaderStructMemberMetadata{.type = ShaderType::kFloat,
                                     .name = "foobar",
                                     .offset = 0,
                                     .size = sizeof(float),
                                     .byte_length = sizeof(float),
                                     .array_elements = std::nullopt,
                                     .float_type = ShaderFloatType::kFloat}}};
  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<Allocation> backing_store = std::make_shared<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float)}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = sizeof(float)},
                                 reactor, backing_store);
  BufferView buffer_view(&device_buffer, Range(0, sizeof(float)));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                       bound_buffers, Range{0, 0},
                                       Range{0, 1}));
}

TEST(BufferBindingsGLESTest, BindArrayData) {
  BufferBindingsGLES bindings;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;
  uniform_bindings["SHADERMETADATA.FOOBAR[0]"] = 1;
  bindings.SetUniformBindings(std::move(uniform_bindings));
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, Uniform1fv(_, _, _)).Times(1);

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  std::vector<BufferResource> bound_buffers;
  std::vector<TextureAndSampler> bound_textures;

  ShaderMetadata shader_metadata = {
      .name = "shader_metadata",
      .members = {
          ShaderStructMemberMetadata{.type = ShaderType::kFloat,
                                     .name = "foobar",
                                     .offset = 0,
                                     .size = sizeof(float),
                                     .byte_length = sizeof(float) * 4,
                                     .array_elements = 4,
                                     .float_type = ShaderFloatType::kFloat}}};
  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<Allocation> backing_store = std::make_shared<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float) * 4}));
  DeviceBufferGLES device_buffer(
      DeviceBufferDescriptor{.size = sizeof(float) * 4}, reactor,
      backing_store);
  BufferView buffer_view(&device_buffer, Range(0, sizeof(float)));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                       bound_buffers, Range{0, 0},
                                       Range{0, 1}));
}

TEST(BufferBindingsGLESTest, BindUniformDataVerticesAndMatrices) {
  BufferBindingsGLES bindings;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;
  uniform_bindings["SHADERMETADATA.VEC2"] = 1;
  uniform_bindings["SHADERMETADATA.VEC3"] = 2;
  uniform_bindings["SHADERMETADATA.VEC4"] = 3;
  uniform_bindings["SHADERMETADATA.MAT2"] = 4;
  uniform_bindings["SHADERMETADATA.MAT3"] = 5;
  uniform_bindings["SHADERMETADATA.MAT4"] = 6;
  bindings.SetUniformBindings(std::move(uniform_bindings));
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, Uniform2fv(1, 1, _)).Times(1);
  EXPECT_CALL(*mock_gles_impl, Uniform3fv(2, 1, _)).Times(1);
  EXPECT_CALL(*mock_gles_impl, Uniform4fv(3, 1, _)).Times(1);
  EXPECT_CALL(*mock_gles_impl, UniformMatrix2fv(4, 1, GL_FALSE, _)).Times(1);
  EXPECT_CALL(*mock_gles_impl, UniformMatrix3fv(5, 1, GL_FALSE, _)).Times(1);
  EXPECT_CALL(*mock_gles_impl, UniformMatrix4fv(6, 1, GL_FALSE, _)).Times(1);

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  std::vector<BufferResource> bound_buffers;
  std::vector<TextureAndSampler> bound_textures;

  auto make_metadata = [](ShaderFloatType float_type, const char* name,
                          size_t size) {
    return ShaderStructMemberMetadata{.type = ShaderType::kFloat,
                                      .name = name,
                                      .offset = 0,
                                      .size = size,
                                      .byte_length = size,
                                      .array_elements = std::nullopt,
                                      .float_type = float_type};
  };

  ShaderMetadata shader_metadata = {
      .name = "shader_metadata",
      .members = {
          make_metadata(ShaderFloatType::kVec2, "vec2", sizeof(Vector2)),
          make_metadata(ShaderFloatType::kVec3, "vec3", sizeof(Vector3)),
          make_metadata(ShaderFloatType::kVec4, "vec4", sizeof(Vector4)),
          make_metadata(ShaderFloatType::kMat2, "mat2", sizeof(float) * 4),
          make_metadata(ShaderFloatType::kMat3, "mat3", sizeof(float) * 9),
          make_metadata(ShaderFloatType::kMat4, "mat4", sizeof(Matrix)),
      }};

  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<Allocation> backing_store = std::make_shared<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{1024}));  // Plenty of space
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 1024}, reactor,
                                 backing_store);
  BufferView buffer_view(&device_buffer, Range(0, 1024));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                       bound_buffers, Range{0, 0},
                                       Range{0, 1}));
}

}  // namespace testing
}  // namespace impeller
