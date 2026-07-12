// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/shader_types.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/gles/buffer_bindings_gles.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/formats_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/sampler_library_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/command.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::NiceMock;

TEST(BufferBindingsGLESTest, ToVertexAttribTypeSupportedFormats) {
  EXPECT_EQ(ToVertexAttribType(VertexAttributeFormat::kFloat32x3),
            std::optional<GLenum>(GL_FLOAT));
  EXPECT_EQ(ToVertexAttribType(VertexAttributeFormat::kSInt8x4),
            std::optional<GLenum>(GL_BYTE));
  EXPECT_EQ(ToVertexAttribType(VertexAttributeFormat::kUInt8),
            std::optional<GLenum>(GL_UNSIGNED_BYTE));
  EXPECT_EQ(ToVertexAttribType(VertexAttributeFormat::kSInt16x2),
            std::optional<GLenum>(GL_SHORT));
  EXPECT_EQ(ToVertexAttribType(VertexAttributeFormat::kUInt16),
            std::optional<GLenum>(GL_UNSIGNED_SHORT));
}

TEST(BufferBindingsGLESTest, ToVertexAttribTypeRejectsUnsupportedFormats) {
  // Half-float and 32-bit integer vertex attributes are not available on the
  // GLES 2.0 floor.
  EXPECT_FALSE(ToVertexAttribType(VertexAttributeFormat::kFloat16).has_value());
  EXPECT_FALSE(ToVertexAttribType(VertexAttributeFormat::kSInt32).has_value());
  EXPECT_FALSE(
      ToVertexAttribType(VertexAttributeFormat::kUInt32x4).has_value());
  EXPECT_FALSE(ToVertexAttribType(VertexAttributeFormat::kInvalid).has_value());
}

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
  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float)}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = sizeof(float)},
                                 reactor, std::move(backing_store));
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
  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float) * 4}));
  DeviceBufferGLES device_buffer(
      DeviceBufferDescriptor{.size = sizeof(float) * 4}, reactor,
      std::move(backing_store));
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
  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{1024}));  // Plenty of space
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 1024}, reactor,
                                 std::move(backing_store));
  BufferView buffer_view(&device_buffer, Range(0, 1024));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                       bound_buffers, Range{0, 0},
                                       Range{0, 1}));
}

// Regression guard: a float uniform that arrives at the GLES backend without
// `float_type` populated must be rejected rather than silently dispatched to
// the wrong glUniform call. This is the fault mode that motivated the schema
// extension; if a future change forgets to populate `float_type` (in the
// shader bundle loader, runtime effects, or anywhere else), this test
// catches it at unit-test time instead of at runtime.
TEST(BufferBindingsGLESTest, BindUniformFailsWithoutFloatType) {
  BufferBindingsGLES bindings;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;
  uniform_bindings["SHADERMETADATA.FOOBAR"] = 1;
  bindings.SetUniformBindings(std::move(uniform_bindings));
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  std::vector<BufferResource> bound_buffers;
  std::vector<TextureAndSampler> bound_textures;

  ShaderMetadata shader_metadata = {
      .name = "shader_metadata",
      .members = {ShaderStructMemberMetadata{.type = ShaderType::kFloat,
                                             .name = "foobar",
                                             .offset = 0,
                                             .size = sizeof(float),
                                             .byte_length = sizeof(float),
                                             .array_elements = std::nullopt,
                                             .float_type = std::nullopt}}};
  std::shared_ptr<ReactorGLES> reactor;
  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float)}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = sizeof(float)},
                                 reactor, std::move(backing_store));
  BufferView buffer_view(&device_buffer, Range(0, sizeof(float)));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_FALSE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                        bound_buffers, Range{0, 0},
                                        Range{0, 1}));
}

// An instanced draw reaches per-instance data through instance-rate vertex
// attributes. A vertex layout with an instance-rate binding must set a
// glVertexAttribDivisor of 1 on that binding's attributes, while a
// per-vertex binding keeps a divisor of 0.
TEST(BufferBindingsGLESTest, BindVertexAttributesSetsInstanceRateDivisor) {
  auto mock_gles_impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*mock_gles_impl, VertexAttribDivisor(0, 0)).Times(1);
  EXPECT_CALL(*mock_gles_impl, VertexAttribDivisor(1, 1)).Times(1);
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));

  BufferBindingsGLES bindings;

  ShaderStageIOSlot per_vertex_input = {
      .name = "position",
      .location = 0,
      .set = 0,
      .binding = 0,
      .type = ShaderType::kFloat,
      .bit_width = sizeof(float) * 8,
      .vec_size = 2,
      .columns = 1,
      .offset = 0,
  };
  ShaderStageIOSlot per_instance_input = {
      .name = "instance_offset",
      .location = 1,
      .set = 0,
      .binding = 1,
      .type = ShaderType::kFloat,
      .bit_width = sizeof(float) * 8,
      .vec_size = 2,
      .columns = 1,
      .offset = 0,
  };
  std::vector<ShaderStageIOSlot> inputs = {per_vertex_input,
                                           per_instance_input};
  std::vector<ShaderStageBufferLayout> layouts = {
      ShaderStageBufferLayout{.stride = sizeof(float) * 2,
                              .binding = 0,
                              .input_rate = VertexInputRate::kVertex},
      ShaderStageBufferLayout{.stride = sizeof(float) * 2,
                              .binding = 1,
                              .input_rate = VertexInputRate::kInstance},
  };

  ASSERT_TRUE(bindings.RegisterVertexStageInput(mock_gl->GetProcTable(), inputs,
                                                layouts));
  // Binding 0 is per-vertex (divisor 0); binding 1 is per-instance
  // (divisor 1).
  EXPECT_TRUE(bindings.BindVertexAttributes(mock_gl->GetProcTable(),
                                            /*binding=*/0, /*vertex_offset=*/0,
                                            /*instance=*/0));
  EXPECT_TRUE(bindings.BindVertexAttributes(mock_gl->GetProcTable(),
                                            /*binding=*/1, /*vertex_offset=*/0,
                                            /*instance=*/0));
}

namespace {

class BindTexturesTestWorker : public ReactorGLES::Worker {
 public:
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

// Owns the reactor, sampler, and metadata behind a set of texture bindings.
struct BoundTexturesFixture {
  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<BindTexturesTestWorker> worker;
  std::unique_ptr<SamplerLibrary> sampler_library;
  raw_ptr<const Sampler> sampler;
  std::vector<std::unique_ptr<ShaderMetadata>> metadata;
  std::vector<TextureAndSampler> bound_textures;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;

  explicit BoundTexturesFixture(std::unique_ptr<ProcTableGLES> proc_table) {
    reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
    worker = std::make_shared<BindTexturesTestWorker>();
    reactor->AddWorker(worker);
    sampler_library = std::make_unique<SamplerLibraryGLES>(
        /*supports_decal_sampler_address_mode=*/false);
    sampler = sampler_library->GetSampler({});
  }

  void AddTextures(ShaderStage stage, size_t count) {
    for (size_t i = 0; i < count; i++) {
      TextureDescriptor desc;
      desc.storage_mode = StorageMode::kDevicePrivate;
      desc.type = TextureType::kTexture2D;
      desc.format = PixelFormat::kR8G8B8A8UNormInt;
      desc.size = {1, 1};
      desc.mip_count = 1u;
      desc.usage = TextureUsage::kShaderRead;
      auto texture = std::make_shared<TextureGLES>(reactor, desc);
      const std::string name = "tex" + std::to_string(metadata.size());
      const std::string key = "TEX" + std::to_string(metadata.size());
      uniform_bindings[key] = static_cast<GLint>(100 + metadata.size());
      auto meta = std::make_unique<ShaderMetadata>();
      meta->name = name;
      TextureAndSampler data = {};
      data.stage = stage;
      data.texture = TextureResource(meta.get(), std::move(texture));
      data.sampler = sampler;
      metadata.push_back(std::move(meta));
      bound_textures.push_back(std::move(data));
    }
  }
};

// Capabilities of a minimum-spec ES3 driver (16 per stage, 32 combined).
std::unique_ptr<NiceMock<MockGLESImpl>> MakeSixteenUnitMockImpl() {
  auto impl = std::make_unique<NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*impl, GetIntegerv(_, _))
      .WillRepeatedly([](GLenum name, GLint* value) {
        switch (name) {
          case GL_MAX_TEXTURE_IMAGE_UNITS:
          case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
            *value = 16;
            break;
          case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
            *value = 32;
            break;
          default:
            break;
        }
      });
  return impl;
}

}  // namespace

// One vertex texture pushes the last of 16 fragment samplers onto unit 16,
// which must bind on a 16-per-stage driver since units are combined in GL.
TEST(BufferBindingsGLESTest, BindsTexturesAcrossThePerStageUnitBoundary) {
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(MakeSixteenUnitMockImpl());
  BoundTexturesFixture fixture(
      std::make_unique<ProcTableGLES>(kMockResolverGLES));
  fixture.AddTextures(ShaderStage::kVertex, 1);
  fixture.AddTextures(ShaderStage::kFragment, 16);
  ASSERT_TRUE(fixture.reactor->React());

  BufferBindingsGLES bindings;
  bindings.SetUniformBindings(std::move(fixture.uniform_bindings));
  std::vector<BufferResource> bound_buffers;
  EXPECT_TRUE(bindings.BindUniformData(
      fixture.reactor->GetProcTable(), fixture.bound_textures, bound_buffers,
      Range{0, fixture.bound_textures.size()}, Range{0, 0}));
}

// More samplers in one stage than its limit is still rejected.
TEST(BufferBindingsGLESTest, RejectsTexturesBeyondThePerStageLimit) {
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(MakeSixteenUnitMockImpl());
  BoundTexturesFixture fixture(
      std::make_unique<ProcTableGLES>(kMockResolverGLES));
  fixture.AddTextures(ShaderStage::kFragment, 17);
  ASSERT_TRUE(fixture.reactor->React());

  BufferBindingsGLES bindings;
  bindings.SetUniformBindings(std::move(fixture.uniform_bindings));
  std::vector<BufferResource> bound_buffers;
  EXPECT_FALSE(bindings.BindUniformData(
      fixture.reactor->GetProcTable(), fixture.bound_textures, bound_buffers,
      Range{0, fixture.bound_textures.size()}, Range{0, 0}));
}

// Units past the combined limit (the mock default, 8) are rejected even when
// each stage is within its per-stage limit.
TEST(BufferBindingsGLESTest, RejectsTexturesBeyondTheCombinedLimit) {
  auto impl = std::make_unique<NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*impl, GetIntegerv(_, _))
      .WillRepeatedly([](GLenum name, GLint* value) {
        switch (name) {
          case GL_MAX_TEXTURE_IMAGE_UNITS:
          case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
            *value = 8;
            break;
          default:
            break;
        }
      });
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(impl));
  BoundTexturesFixture fixture(
      std::make_unique<ProcTableGLES>(kMockResolverGLES));
  fixture.AddTextures(ShaderStage::kVertex, 8);
  fixture.AddTextures(ShaderStage::kFragment, 8);
  ASSERT_TRUE(fixture.reactor->React());

  BufferBindingsGLES bindings;
  bindings.SetUniformBindings(std::move(fixture.uniform_bindings));
  std::vector<BufferResource> bound_buffers;
  EXPECT_FALSE(bindings.BindUniformData(
      fixture.reactor->GetProcTable(), fixture.bound_textures, bound_buffers,
      Range{0, fixture.bound_textures.size()}, Range{0, 0}));
}

}  // namespace testing
}  // namespace impeller
