// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/memory_program_cache.h"

#include "base/bind.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/shader_manager.h"
#include "gpu/command_buffer/service/shader_translator.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_mock.h"

using ::testing::_;
using ::testing::Invoke;
using ::testing::SetArgPointee;

namespace gpu {
namespace gles2 {

class ProgramBinaryEmulator {
 public:
  ProgramBinaryEmulator(GLsizei length,
                        GLenum format,
                        const char* binary)
      : length_(length),
        format_(format),
        binary_(binary) { }

  void GetProgramBinary(GLuint program,
                        GLsizei buffer_size,
                        GLsizei* length,
                        GLenum* format,
                        GLvoid* binary) {
    if (length) {
      *length = length_;
    }
    *format = format_;
    memcpy(binary, binary_, length_);
  }

  void ProgramBinary(GLuint program,
                     GLenum format,
                     const GLvoid* binary,
                     GLsizei length) {
    // format and length are verified by matcher
    EXPECT_EQ(0, memcmp(binary_, binary, length));
  }

  GLsizei length() const { return length_; }
  GLenum format() const { return format_; }
  const char* binary() const { return binary_; }

 private:
  GLsizei length_;
  GLenum format_;
  const char* binary_;
};

class MemoryProgramCacheTest : public GpuServiceTest {
 public:
  static const size_t kCacheSizeBytes = 1024;
  static const GLuint kVertexShaderClientId = 90;
  static const GLuint kVertexShaderServiceId = 100;
  static const GLuint kFragmentShaderClientId = 91;
  static const GLuint kFragmentShaderServiceId = 100;

  MemoryProgramCacheTest()
      : cache_(new MemoryProgramCache(kCacheSizeBytes)),
        vertex_shader_(NULL),
        fragment_shader_(NULL),
        shader_cache_count_(0) { }
  ~MemoryProgramCacheTest() override { shader_manager_.Destroy(false); }

  void ShaderCacheCb(const std::string& key, const std::string& shader) {
    shader_cache_count_++;
    shader_cache_shader_ = shader;
  }

  int32 shader_cache_count() { return shader_cache_count_; }
  const std::string& shader_cache_shader() { return shader_cache_shader_; }

 protected:
  void SetUp() override {
    GpuServiceTest::SetUpWithGLVersion("3.0", "GL_ARB_get_program_binary");

    vertex_shader_ = shader_manager_.CreateShader(kVertexShaderClientId,
                                                  kVertexShaderServiceId,
                                                  GL_VERTEX_SHADER);
    fragment_shader_ = shader_manager_.CreateShader(
        kFragmentShaderClientId,
        kFragmentShaderServiceId,
        GL_FRAGMENT_SHADER);
    ASSERT_TRUE(vertex_shader_ != NULL);
    ASSERT_TRUE(fragment_shader_ != NULL);
    AttributeMap vertex_attrib_map;
    UniformMap vertex_uniform_map;
    VaryingMap vertex_varying_map;
    AttributeMap fragment_attrib_map;
    UniformMap fragment_uniform_map;
    VaryingMap fragment_varying_map;

    vertex_attrib_map["a"] = TestHelper::ConstructAttribute(
        GL_FLOAT_VEC2, 34, GL_LOW_FLOAT, false, "a");
    vertex_uniform_map["a"] = TestHelper::ConstructUniform(
        GL_FLOAT, 10, GL_MEDIUM_FLOAT, true, "a");
    vertex_uniform_map["b"] = TestHelper::ConstructUniform(
        GL_FLOAT_VEC3, 3114, GL_HIGH_FLOAT, true, "b");
    vertex_varying_map["c"] = TestHelper::ConstructVarying(
        GL_FLOAT_VEC4, 2, GL_HIGH_FLOAT, true, "c");
    fragment_attrib_map["jjjbb"] = TestHelper::ConstructAttribute(
        GL_FLOAT_MAT4, 1114, GL_MEDIUM_FLOAT, false, "jjjbb");
    fragment_uniform_map["k"] = TestHelper::ConstructUniform(
        GL_FLOAT_MAT2, 34413, GL_MEDIUM_FLOAT, true, "k");
    fragment_varying_map["c"] = TestHelper::ConstructVarying(
        GL_FLOAT_VEC4, 2, GL_HIGH_FLOAT, true, "c");

    vertex_shader_->set_source("bbbalsldkdkdkd");
    fragment_shader_->set_source("bbbal   sldkdkdkas 134 ad");

    TestHelper::SetShaderStates(
        gl_.get(), vertex_shader_, true, NULL, NULL,
        &vertex_attrib_map, &vertex_uniform_map, &vertex_varying_map,
        NULL);
    TestHelper::SetShaderStates(
        gl_.get(), fragment_shader_, true, NULL, NULL,
        &fragment_attrib_map, &fragment_uniform_map, &fragment_varying_map,
        NULL);
  }

  void SetExpectationsForSaveLinkedProgram(
      const GLint program_id,
      ProgramBinaryEmulator* emulator) const {
    EXPECT_CALL(*gl_.get(),
                GetProgramiv(program_id, GL_PROGRAM_BINARY_LENGTH_OES, _))
        .WillOnce(SetArgPointee<2>(emulator->length()));
    EXPECT_CALL(*gl_.get(),
                GetProgramBinary(program_id, emulator->length(), _, _, _))
        .WillOnce(Invoke(emulator, &ProgramBinaryEmulator::GetProgramBinary));
  }

  void SetExpectationsForLoadLinkedProgram(
      const GLint program_id,
      ProgramBinaryEmulator* emulator) const {
    EXPECT_CALL(*gl_.get(),
                ProgramBinary(program_id,
                              emulator->format(),
                              _,
                              emulator->length()))
        .WillOnce(Invoke(emulator, &ProgramBinaryEmulator::ProgramBinary));
    EXPECT_CALL(*gl_.get(),
                GetProgramiv(program_id, GL_LINK_STATUS, _))
                .WillOnce(SetArgPointee<2>(GL_TRUE));
  }

  void SetExpectationsForLoadLinkedProgramFailure(
      const GLint program_id,
      ProgramBinaryEmulator* emulator) const {
    EXPECT_CALL(*gl_.get(),
                ProgramBinary(program_id,
                              emulator->format(),
                              _,
                              emulator->length()))
        .WillOnce(Invoke(emulator, &ProgramBinaryEmulator::ProgramBinary));
    EXPECT_CALL(*gl_.get(),
                GetProgramiv(program_id, GL_LINK_STATUS, _))
                .WillOnce(SetArgPointee<2>(GL_FALSE));
  }

  scoped_ptr<MemoryProgramCache> cache_;
  ShaderManager shader_manager_;
  Shader* vertex_shader_;
  Shader* fragment_shader_;
  int32 shader_cache_count_;
  std::string shader_cache_shader_;
  std::vector<std::string> varyings_;
};

TEST_F(MemoryProgramCacheTest, CacheSave) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
  EXPECT_EQ(1, shader_cache_count());
}

TEST_F(MemoryProgramCacheTest, LoadProgram) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
  EXPECT_EQ(1, shader_cache_count());

  cache_->Clear();

  cache_->LoadProgram(shader_cache_shader());
  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
}

TEST_F(MemoryProgramCacheTest, CacheLoadMatchesSave) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));
  EXPECT_EQ(1, shader_cache_count());

  AttributeMap vertex_attrib_map = vertex_shader_->attrib_map();
  UniformMap vertex_uniform_map = vertex_shader_->uniform_map();
  VaryingMap vertex_varying_map = vertex_shader_->varying_map();
  AttributeMap fragment_attrib_map = fragment_shader_->attrib_map();
  UniformMap fragment_uniform_map = fragment_shader_->uniform_map();
  VaryingMap fragment_varying_map = fragment_shader_->varying_map();

  vertex_shader_->set_attrib_map(AttributeMap());
  vertex_shader_->set_uniform_map(UniformMap());
  vertex_shader_->set_varying_map(VaryingMap());
  fragment_shader_->set_attrib_map(AttributeMap());
  fragment_shader_->set_uniform_map(UniformMap());
  fragment_shader_->set_varying_map(VaryingMap());

  SetExpectationsForLoadLinkedProgram(kProgramId, &emulator);

  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_SUCCESS, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));

  // apparently the hash_map implementation on android doesn't have the
  // equality operator
#if !defined(OS_ANDROID)
  EXPECT_EQ(vertex_attrib_map, vertex_shader_->attrib_map());
  EXPECT_EQ(vertex_uniform_map, vertex_shader_->uniform_map());
  EXPECT_EQ(vertex_varying_map, vertex_shader_->varying_map());
  EXPECT_EQ(fragment_attrib_map, fragment_shader_->attrib_map());
  EXPECT_EQ(fragment_uniform_map, fragment_shader_->uniform_map());
  EXPECT_EQ(fragment_varying_map, fragment_shader_->varying_map());
#endif
}

TEST_F(MemoryProgramCacheTest, LoadProgramMatchesSave) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));
  EXPECT_EQ(1, shader_cache_count());

  AttributeMap vertex_attrib_map = vertex_shader_->attrib_map();
  UniformMap vertex_uniform_map = vertex_shader_->uniform_map();
  VaryingMap vertex_varying_map = vertex_shader_->varying_map();
  AttributeMap fragment_attrib_map = fragment_shader_->attrib_map();
  UniformMap fragment_uniform_map = fragment_shader_->uniform_map();
  VaryingMap fragment_varying_map = fragment_shader_->varying_map();

  vertex_shader_->set_attrib_map(AttributeMap());
  vertex_shader_->set_uniform_map(UniformMap());
  vertex_shader_->set_varying_map(VaryingMap());
  fragment_shader_->set_attrib_map(AttributeMap());
  fragment_shader_->set_uniform_map(UniformMap());
  fragment_shader_->set_varying_map(VaryingMap());

  SetExpectationsForLoadLinkedProgram(kProgramId, &emulator);

  cache_->Clear();
  cache_->LoadProgram(shader_cache_shader());

  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_SUCCESS, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));

  // apparently the hash_map implementation on android doesn't have the
  // equality operator
#if !defined(OS_ANDROID)
  EXPECT_EQ(vertex_attrib_map, vertex_shader_->attrib_map());
  EXPECT_EQ(vertex_uniform_map, vertex_shader_->uniform_map());
  EXPECT_EQ(vertex_varying_map, vertex_shader_->varying_map());
  EXPECT_EQ(fragment_attrib_map, fragment_shader_->attrib_map());
  EXPECT_EQ(fragment_uniform_map, fragment_shader_->uniform_map());
  EXPECT_EQ(fragment_varying_map, fragment_shader_->varying_map());
#endif
}

TEST_F(MemoryProgramCacheTest, LoadFailOnLinkFalse) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  SetExpectationsForLoadLinkedProgramFailure(kProgramId, &emulator);
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

TEST_F(MemoryProgramCacheTest, LoadFailOnDifferentSource) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  const std::string vertex_orig_source = vertex_shader_->last_compiled_source();
  vertex_shader_->set_source("different!");
  TestHelper::SetShaderStates(gl_.get(), vertex_shader_, true);
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));

  vertex_shader_->set_source(vertex_orig_source);
  TestHelper::SetShaderStates(gl_.get(), vertex_shader_, true);
  fragment_shader_->set_source("different!");
  TestHelper::SetShaderStates(gl_.get(), fragment_shader_, true);
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

TEST_F(MemoryProgramCacheTest, LoadFailOnDifferentMap) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  ProgramCache::LocationMap binding_map;
  binding_map["test"] = 512;
  cache_->SaveLinkedProgram(kProgramId,
                            vertex_shader_,
                            fragment_shader_,
                            &binding_map,
                            varyings_,
                            GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  binding_map["different!"] = 59;
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      &binding_map,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

TEST_F(MemoryProgramCacheTest, LoadFailOnDifferentTransformFeedbackVaryings) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  varyings_.push_back("test");
  cache_->SaveLinkedProgram(kProgramId,
                            vertex_shader_,
                            fragment_shader_,
                            NULL,
                            varyings_,
                            GL_INTERLEAVED_ATTRIBS,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_SEPARATE_ATTRIBS,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));

  varyings_.push_back("different!");
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_FAILURE, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_INTERLEAVED_ATTRIBS,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

TEST_F(MemoryProgramCacheTest, MemoryProgramCacheEviction) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator1(kBinaryLength, kFormat, test_binary);


  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator1);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  const int kEvictingProgramId = 11;
  const GLuint kEvictingBinaryLength = kCacheSizeBytes - kBinaryLength + 1;

  // save old source and modify for new program
  const std::string& old_sig = fragment_shader_->last_compiled_signature();
  fragment_shader_->set_source("al sdfkjdk");
  TestHelper::SetShaderStates(gl_.get(), fragment_shader_, true);

  scoped_ptr<char[]> bigTestBinary =
      scoped_ptr<char[]>(new char[kEvictingBinaryLength]);
  for (size_t i = 0; i < kEvictingBinaryLength; ++i) {
    bigTestBinary[i] = i % 250;
  }
  ProgramBinaryEmulator emulator2(kEvictingBinaryLength,
                                  kFormat,
                                  bigTestBinary.get());

  SetExpectationsForSaveLinkedProgram(kEvictingProgramId, &emulator2);
  cache_->SaveLinkedProgram(kEvictingProgramId,
                            vertex_shader_,
                            fragment_shader_,
                            NULL,
                            varyings_,
                            GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN, cache_->GetLinkedProgramStatus(
      old_sig,
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
}

TEST_F(MemoryProgramCacheTest, SaveCorrectProgram) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator1(kBinaryLength, kFormat, test_binary);

  vertex_shader_->set_source("different!");
  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator1);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));
}

TEST_F(MemoryProgramCacheTest, LoadCorrectProgram) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED, cache_->GetLinkedProgramStatus(
      vertex_shader_->last_compiled_signature(),
      fragment_shader_->last_compiled_signature(),
      NULL, varyings_, GL_NONE));

  SetExpectationsForLoadLinkedProgram(kProgramId, &emulator);

  fragment_shader_->set_source("different!");
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_SUCCESS, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

TEST_F(MemoryProgramCacheTest, OverwriteOnNewSave) {
  const GLenum kFormat = 1;
  const int kProgramId = 10;
  const int kBinaryLength = 20;
  char test_binary[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary[i] = i;
  }
  ProgramBinaryEmulator emulator(kBinaryLength, kFormat, test_binary);

  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));


  char test_binary2[kBinaryLength];
  for (int i = 0; i < kBinaryLength; ++i) {
    test_binary2[i] = (i*2) % 250;
  }
  ProgramBinaryEmulator emulator2(kBinaryLength, kFormat, test_binary2);
  SetExpectationsForSaveLinkedProgram(kProgramId, &emulator2);
  cache_->SaveLinkedProgram(kProgramId, vertex_shader_,
                            fragment_shader_, NULL, varyings_, GL_NONE,
                            base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                                       base::Unretained(this)));

  SetExpectationsForLoadLinkedProgram(kProgramId, &emulator2);
  EXPECT_EQ(ProgramCache::PROGRAM_LOAD_SUCCESS, cache_->LoadLinkedProgram(
      kProgramId,
      vertex_shader_,
      fragment_shader_,
      NULL,
      varyings_,
      GL_NONE,
      base::Bind(&MemoryProgramCacheTest::ShaderCacheCb,
                 base::Unretained(this))));
}

}  // namespace gles2
}  // namespace gpu
