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
namespace {
const GLint kBlockDataSize = 16;
}

using ::testing::_;
using ::testing::NiceMock;

namespace {
// A context that supports every format tier.
constexpr VertexFormatSupportGLES kFullVertexFormatSupport = {
    .half_float_type = GL_HALF_FLOAT,
    .integer = true,
    .packed_2_10_10_10 = true,
    .bgra = true,
};
}  // namespace

TEST(BufferBindingsGLESTest, ToVertexAttribGLESFloats) {
  auto attrib = ToVertexAttribGLES(VertexAttributeFormat::kFloat32x3,
                                   kFullVertexFormatSupport);
  ASSERT_TRUE(attrib.has_value());
  EXPECT_EQ(attrib->size, 3);
  EXPECT_EQ(attrib->type, static_cast<GLenum>(GL_FLOAT));
  EXPECT_EQ(attrib->normalized, GL_FALSE);
  EXPECT_FALSE(attrib->integer);
}

TEST(BufferBindingsGLESTest, ToVertexAttribGLESNormalized) {
  auto attrib = ToVertexAttribGLES(VertexAttributeFormat::kUNorm8x4,
                                   kFullVertexFormatSupport);
  ASSERT_TRUE(attrib.has_value());
  EXPECT_EQ(attrib->size, 4);
  EXPECT_EQ(attrib->type, static_cast<GLenum>(GL_UNSIGNED_BYTE));
  EXPECT_EQ(attrib->normalized, GL_TRUE);
  EXPECT_FALSE(attrib->integer);
}

TEST(BufferBindingsGLESTest, ToVertexAttribGLESIntegersTakeTheIPointerPath) {
  auto attrib = ToVertexAttribGLES(VertexAttributeFormat::kUInt32x2,
                                   kFullVertexFormatSupport);
  ASSERT_TRUE(attrib.has_value());
  EXPECT_EQ(attrib->size, 2);
  EXPECT_EQ(attrib->type, static_cast<GLenum>(GL_UNSIGNED_INT));
  EXPECT_EQ(attrib->normalized, GL_FALSE);
  EXPECT_TRUE(attrib->integer);
}

TEST(BufferBindingsGLESTest, ToVertexAttribGLESPackedFormats) {
  auto bgra = ToVertexAttribGLES(VertexAttributeFormat::kUNorm8x4BGRA,
                                 kFullVertexFormatSupport);
  ASSERT_TRUE(bgra.has_value());
  // Byte ordering is expressed by passing GL_BGRA_EXT as the component count.
  EXPECT_EQ(bgra->size, GL_BGRA_EXT);
  EXPECT_EQ(bgra->type, static_cast<GLenum>(GL_UNSIGNED_BYTE));
  EXPECT_EQ(bgra->normalized, GL_TRUE);

  auto packed = ToVertexAttribGLES(VertexAttributeFormat::kUNorm10_10_10_2,
                                   kFullVertexFormatSupport);
  ASSERT_TRUE(packed.has_value());
  EXPECT_EQ(packed->size, 4);
  EXPECT_EQ(packed->type, static_cast<GLenum>(GL_UNSIGNED_INT_2_10_10_10_REV));
  EXPECT_EQ(packed->normalized, GL_TRUE);
}

TEST(BufferBindingsGLESTest, ToVertexAttribGLESHonorsTheHalfFloatEnum) {
  VertexFormatSupportGLES support = kFullVertexFormatSupport;
  support.half_float_type = GL_HALF_FLOAT_OES;
  auto attrib = ToVertexAttribGLES(VertexAttributeFormat::kFloat16x2, support);
  ASSERT_TRUE(attrib.has_value());
  EXPECT_EQ(attrib->type, static_cast<GLenum>(GL_HALF_FLOAT_OES));
}

TEST(BufferBindingsGLESTest, ToVertexAttribGLESRejectsUnsupportedFormats) {
  // The OpenGL ES 2.0 floor: normalized and 32-bit float formats only.
  constexpr VertexFormatSupportGLES kFloor = {};
  EXPECT_TRUE(
      ToVertexAttribGLES(VertexAttributeFormat::kUNorm8x4, kFloor).has_value());
  EXPECT_FALSE(
      ToVertexAttribGLES(VertexAttributeFormat::kFloat16, kFloor).has_value());
  EXPECT_FALSE(
      ToVertexAttribGLES(VertexAttributeFormat::kSInt32, kFloor).has_value());
  EXPECT_FALSE(ToVertexAttribGLES(VertexAttributeFormat::kUNorm8x4BGRA, kFloor)
                   .has_value());
  EXPECT_FALSE(
      ToVertexAttribGLES(VertexAttributeFormat::kUNorm10_10_10_2, kFloor)
          .has_value());
  EXPECT_FALSE(ToVertexAttribGLES(VertexAttributeFormat::kInvalid,
                                  kFullVertexFormatSupport)
                   .has_value());
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

// A normalized attribute reaches glVertexAttribPointer with the normalized
// flag set, so the hardware converts the stored bytes to floats on read.
TEST(BufferBindingsGLESTest, BindVertexAttributesNormalizesPackedColors) {
  auto mock_gles_impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*mock_gles_impl, VertexAttribPointer(/*index=*/0, /*size=*/4,
                                                   GL_UNSIGNED_BYTE, GL_TRUE,
                                                   /*stride=*/4, _))
      .Times(1);
  EXPECT_CALL(*mock_gles_impl, VertexAttribIPointer(_, _, _, _, _)).Times(0);
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));

  BufferBindingsGLES bindings;
  // The shader declares a vec4; only the explicit format says the buffer holds
  // four normalized bytes.
  ShaderStageIOSlot input = {
      .name = "color",
      .location = 0,
      .set = 0,
      .binding = 0,
      .type = ShaderType::kFloat,
      .bit_width = sizeof(float) * 8,
      .vec_size = 4,
      .columns = 1,
      .offset = 0,
      .vertex_format = VertexAttributeFormat::kUNorm8x4,
  };
  std::vector<ShaderStageIOSlot> inputs = {input};
  std::vector<ShaderStageBufferLayout> layouts = {
      ShaderStageBufferLayout{
          .stride = 4, .binding = 0, .input_rate = VertexInputRate::kVertex},
  };

  ASSERT_TRUE(bindings.RegisterVertexStageInput(mock_gl->GetProcTable(), inputs,
                                                layouts));
  EXPECT_TRUE(bindings.BindVertexAttributes(mock_gl->GetProcTable(),
                                            /*binding=*/0, /*vertex_offset=*/0,
                                            /*instance=*/0));
}

// An integer-typed input must go through glVertexAttribIPointer, which hands
// the value to the shader unconverted.
TEST(BufferBindingsGLESTest, BindVertexAttributesUsesIPointerForIntegers) {
  auto mock_gles_impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*mock_gles_impl,
              VertexAttribIPointer(/*index=*/0, /*size=*/1, GL_UNSIGNED_INT,
                                   /*stride=*/4, _))
      .Times(1);
  EXPECT_CALL(*mock_gles_impl, VertexAttribPointer(_, _, _, _, _, _)).Times(0);
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));

  BufferBindingsGLES bindings;
  ShaderStageIOSlot input = {
      .name = "packed_color",
      .location = 0,
      .set = 0,
      .binding = 0,
      .type = ShaderType::kUnsignedInt,
      .bit_width = 32,
      .vec_size = 1,
      .columns = 1,
      .offset = 0,
  };
  std::vector<ShaderStageIOSlot> inputs = {input};
  std::vector<ShaderStageBufferLayout> layouts = {
      ShaderStageBufferLayout{
          .stride = 4, .binding = 0, .input_rate = VertexInputRate::kVertex},
  };

  ASSERT_TRUE(bindings.RegisterVertexStageInput(mock_gl->GetProcTable(), inputs,
                                                layouts));
  EXPECT_TRUE(bindings.BindVertexAttributes(mock_gl->GetProcTable(),
                                            /*binding=*/0, /*vertex_offset=*/0,
                                            /*instance=*/0));
}

// Registering a pipeline whose vertex layout the device cannot read fails at
// pipeline creation rather than at draw time.
TEST(BufferBindingsGLESTest, RegisterVertexStageInputRejectsUnusableFormat) {
  auto mock_gles_impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();
  std::shared_ptr<MockGLES> mock_gl =
      MockGLES::Init(std::move(mock_gles_impl),
                     std::vector<const char*>{"GL_KHR_debug"}, "OpenGL ES 2.0");

  BufferBindingsGLES bindings;
  ShaderStageIOSlot input = {
      .name = "packed_normal",
      .location = 0,
      .set = 0,
      .binding = 0,
      .type = ShaderType::kFloat,
      .bit_width = sizeof(float) * 8,
      .vec_size = 4,
      .columns = 1,
      .offset = 0,
      .vertex_format = VertexAttributeFormat::kUNorm10_10_10_2,
  };
  std::vector<ShaderStageIOSlot> inputs = {input};
  std::vector<ShaderStageBufferLayout> layouts = {
      ShaderStageBufferLayout{
          .stride = 4, .binding = 0, .input_rate = VertexInputRate::kVertex},
  };

  EXPECT_FALSE(bindings.RegisterVertexStageInput(mock_gl->GetProcTable(),
                                                 inputs, layouts));
}

namespace {
class TestWorker : public ReactorGLES::Worker {
 public:
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};
}  // namespace

void TestBindUniformBufferRange(size_t buffer_view_length,
                                size_t expected_bound_size) {
  BufferBindingsGLES bindings;
  auto mock_gles_impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();

  const GLuint kProgram = 1;

  ON_CALL(*mock_gles_impl,
          GetProgramiv(/*program=*/kProgram,
                       /*pname=*/GL_ACTIVE_UNIFORM_BLOCKS, /*params=*/_))
      .WillByDefault(::testing::SetArgPointee<2>(1));
  ON_CALL(*mock_gles_impl,
          GetActiveUniformBlockiv(/*program=*/kProgram,
                                  /*uniformBlockIndex=*/0,
                                  /*pname=*/GL_UNIFORM_BLOCK_NAME_LENGTH,
                                  /*params=*/_))
      .WillByDefault(::testing::SetArgPointee<3>(9));
  ON_CALL(*mock_gles_impl,
          GetActiveUniformBlockName(/*program=*/kProgram,
                                    /*uniformBlockIndex=*/0,
                                    /*bufSize=*/9, /*length=*/_,
                                    /*uniformBlockName=*/_))
      .WillByDefault([](GLuint program, GLuint index, GLsizei bufSize,
                        GLsizei* length, GLchar* name) {
        *length = 8;
        std::memcpy(name, "FragInfo", 9);
      });
  ON_CALL(
      *mock_gles_impl,
      GetUniformBlockIndex(/*program=*/kProgram,
                           /*uniformBlockName=*/::testing::StrEq("FragInfo")))
      .WillByDefault(::testing::Return(0));
  ON_CALL(*mock_gles_impl,
          GetActiveUniformBlockiv(/*program=*/kProgram,
                                  /*uniformBlockIndex=*/0,
                                  /*pname=*/GL_UNIFORM_BLOCK_DATA_SIZE,
                                  /*params=*/_))
      .WillByDefault(::testing::SetArgPointee<3>(kBlockDataSize));

  EXPECT_CALL(*mock_gles_impl,
              BindBufferRange(/*target=*/GL_UNIFORM_BUFFER, /*index=*/0,
                              /*buffer=*/_, /*offset=*/0,
                              /*size=*/expected_bound_size))
      .Times(1);

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  ASSERT_TRUE(bindings.ReadUniformsBindings(mock_gl->GetProcTable(), kProgram));

  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  std::vector<BufferResource> bound_buffers;
  std::vector<TextureAndSampler> bound_textures;

  ShaderMetadata shader_metadata = {.name = "FragInfo"};
  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{1024}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 1024}, reactor,
                                 std::move(backing_store));
  BufferView buffer_view(&device_buffer, Range(0, buffer_view_length));
  bound_buffers.push_back(BufferResource(&shader_metadata, buffer_view));

  EXPECT_TRUE(bindings.BindUniformData(mock_gl->GetProcTable(), bound_textures,
                                       bound_buffers, Range{0, 0},
                                       Range{0, 1}));
}

TEST(BufferBindingsGLESTest,
     BindUniformBufferUsesMaxOfBufferViewAndBlockDataSize) {
  TestBindUniformBufferRange(/*buffer_view_length=*/4,
                             /*expected_bound_size=*/kBlockDataSize);
}

TEST(BufferBindingsGLESTest,
     BindUniformBufferUsesBufferViewLengthWhenGreaterThanBlockDataSize) {
  TestBindUniformBufferRange(/*buffer_view_length=*/32,
                             /*expected_bound_size=*/32);
}

namespace {

// Owns the reactor, sampler, and metadata behind a set of texture bindings.
struct BoundTexturesFixture {
  std::shared_ptr<ReactorGLES> reactor;
  std::shared_ptr<TestWorker> worker;
  std::unique_ptr<SamplerLibrary> sampler_library;
  raw_ptr<const Sampler> sampler;
  std::vector<std::unique_ptr<ShaderMetadata>> metadata;
  std::vector<TextureAndSampler> bound_textures;
  absl::flat_hash_map<std::string, GLint> uniform_bindings;

  explicit BoundTexturesFixture(std::unique_ptr<ProcTableGLES> proc_table) {
    reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
    worker = std::make_shared<TestWorker>();
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

// Units past the combined limit are rejected even when each stage is within
// its per-stage limit.
TEST(BufferBindingsGLESTest, RejectsTexturesBeyondTheCombinedLimit) {
  auto impl = std::make_unique<NiceMock<MockGLESImpl>>();
  EXPECT_CALL(*impl, GetIntegerv(_, _))
      .WillRepeatedly([](GLenum name, GLint* value) {
        switch (name) {
          case GL_MAX_TEXTURE_IMAGE_UNITS:
          case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
          case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
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
