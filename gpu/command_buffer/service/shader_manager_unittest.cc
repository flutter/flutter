// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/shader_manager.h"

#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::testing::Return;
using ::testing::ReturnRef;

namespace gpu {
namespace gles2 {

class ShaderManagerTest : public GpuServiceTest {
 public:
  ShaderManagerTest() {
  }

  ~ShaderManagerTest() override { manager_.Destroy(false); }

 protected:
  ShaderManager manager_;
};

TEST_F(ShaderManagerTest, Basic) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLenum kShader1Type = GL_VERTEX_SHADER;
  const GLuint kClient2Id = 2;
  // Check we can create shader.
  Shader* info0 = manager_.CreateShader(
      kClient1Id, kService1Id, kShader1Type);
  // Check shader got created.
  ASSERT_TRUE(info0 != NULL);
  Shader* shader1 = manager_.GetShader(kClient1Id);
  ASSERT_EQ(info0, shader1);
  // Check we get nothing for a non-existent shader.
  EXPECT_TRUE(manager_.GetShader(kClient2Id) == NULL);
  // Check we can't get the shader after we remove it.
  EXPECT_CALL(*gl_, DeleteShader(kService1Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.Delete(shader1);
  EXPECT_TRUE(manager_.GetShader(kClient1Id) == NULL);
}

TEST_F(ShaderManagerTest, Destroy) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLenum kShader1Type = GL_VERTEX_SHADER;
  // Check we can create shader.
  Shader* shader1 = manager_.CreateShader(
      kClient1Id, kService1Id, kShader1Type);
  // Check shader got created.
  ASSERT_TRUE(shader1 != NULL);
  EXPECT_CALL(*gl_, DeleteShader(kService1Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.Destroy(true);
  // Check that resources got freed.
  shader1 = manager_.GetShader(kClient1Id);
  ASSERT_TRUE(shader1 == NULL);
}

TEST_F(ShaderManagerTest, DeleteBug) {
  const GLuint kClient1Id = 1;
  const GLuint kClient2Id = 2;
  const GLuint kService1Id = 11;
  const GLuint kService2Id = 12;
  const GLenum kShaderType = GL_VERTEX_SHADER;
  // Check we can create shader.
  scoped_refptr<Shader> shader1(
      manager_.CreateShader(kClient1Id, kService1Id, kShaderType));
  scoped_refptr<Shader> shader2(
      manager_.CreateShader(kClient2Id, kService2Id, kShaderType));
  ASSERT_TRUE(shader1.get());
  ASSERT_TRUE(shader2.get());
  manager_.UseShader(shader1.get());
  manager_.Delete(shader1.get());

  EXPECT_CALL(*gl_, DeleteShader(kService2Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.Delete(shader2.get());
  EXPECT_TRUE(manager_.IsOwned(shader1.get()));
  EXPECT_FALSE(manager_.IsOwned(shader2.get()));

  EXPECT_CALL(*gl_, DeleteShader(kService1Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.UnuseShader(shader1.get());
}

TEST_F(ShaderManagerTest, DoCompile) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLenum kShader1Type = GL_VERTEX_SHADER;
  const char* kClient1Source = "hello world";
  const GLenum kAttrib1Type = GL_FLOAT_VEC2;
  const GLint kAttrib1Size = 2;
  const GLenum kAttrib1Precision = GL_MEDIUM_FLOAT;
  const char* kAttrib1Name = "attr1";
  const GLenum kAttrib2Type = GL_FLOAT_VEC3;
  const GLint kAttrib2Size = 4;
  const GLenum kAttrib2Precision = GL_HIGH_FLOAT;
  const char* kAttrib2Name = "attr2";
  const bool kAttribStaticUse = false;
  const GLenum kUniform1Type = GL_FLOAT_MAT2;
  const GLint kUniform1Size = 3;
  const GLenum kUniform1Precision = GL_LOW_FLOAT;
  const bool kUniform1StaticUse = true;
  const char* kUniform1Name = "uni1";
  const GLenum kUniform2Type = GL_FLOAT_MAT3;
  const GLint kUniform2Size = 5;
  const GLenum kUniform2Precision = GL_MEDIUM_FLOAT;
  const bool kUniform2StaticUse = false;
  const char* kUniform2Name = "uni2";
  const GLenum kVarying1Type = GL_FLOAT_VEC4;
  const GLint kVarying1Size = 1;
  const GLenum kVarying1Precision = GL_HIGH_FLOAT;
  const bool kVarying1StaticUse = false;
  const char* kVarying1Name = "varying1";

  // Check we can create shader.
  Shader* shader1 = manager_.CreateShader(
      kClient1Id, kService1Id, kShader1Type);
  // Check shader got created.
  ASSERT_TRUE(shader1 != NULL);
  EXPECT_EQ(kService1Id, shader1->service_id());
  // Check if the shader has correct type.
  EXPECT_EQ(kShader1Type, shader1->shader_type());
  EXPECT_FALSE(shader1->valid());
  EXPECT_FALSE(shader1->InUse());
  EXPECT_TRUE(shader1->source().empty());
  EXPECT_TRUE(shader1->log_info().empty());
  EXPECT_TRUE(shader1->last_compiled_source().empty());
  EXPECT_TRUE(shader1->translated_source().empty());
  EXPECT_EQ(0u, shader1->attrib_map().size());
  EXPECT_EQ(0u, shader1->uniform_map().size());
  EXPECT_EQ(0u, shader1->varying_map().size());
  EXPECT_EQ(Shader::kShaderStateWaiting, shader1->shader_state());

  // Check we can set its source.
  shader1->set_source(kClient1Source);
  EXPECT_STREQ(kClient1Source, shader1->source().c_str());
  EXPECT_TRUE(shader1->last_compiled_source().empty());

  // Check that DoCompile() will not work if RequestCompile() was not called.
  shader1->DoCompile();
  EXPECT_EQ(Shader::kShaderStateWaiting, shader1->shader_state());
  EXPECT_FALSE(shader1->valid());

  // Check RequestCompile() will update the state and last compiled source, but
  // still keep the actual compile state invalid.
  scoped_refptr<ShaderTranslatorInterface> translator(new MockShaderTranslator);
  shader1->RequestCompile(translator, Shader::kANGLE);
  EXPECT_EQ(Shader::kShaderStateCompileRequested, shader1->shader_state());
  EXPECT_STREQ(kClient1Source, shader1->last_compiled_source().c_str());
  EXPECT_FALSE(shader1->valid());

  // Check DoCompile() will set compilation states, log, translated source,
  // shader variables, and name mapping.
  const std::string kLog = "foo";
  const std::string kTranslatedSource = "poo";

  AttributeMap attrib_map;
  attrib_map[kAttrib1Name] = TestHelper::ConstructAttribute(
      kAttrib1Type, kAttrib1Size, kAttrib1Precision,
      kAttribStaticUse, kAttrib1Name);
  attrib_map[kAttrib2Name] = TestHelper::ConstructAttribute(
      kAttrib2Type, kAttrib2Size, kAttrib2Precision,
      kAttribStaticUse, kAttrib2Name);
  UniformMap uniform_map;
  uniform_map[kUniform1Name] = TestHelper::ConstructUniform(
      kUniform1Type, kUniform1Size, kUniform1Precision,
      kUniform1StaticUse, kUniform1Name);
  uniform_map[kUniform2Name] = TestHelper::ConstructUniform(
      kUniform2Type, kUniform2Size, kUniform2Precision,
      kUniform2StaticUse, kUniform2Name);
  VaryingMap varying_map;
  varying_map[kVarying1Name] = TestHelper::ConstructVarying(
      kVarying1Type, kVarying1Size, kVarying1Precision,
      kVarying1StaticUse, kVarying1Name);

  TestHelper::SetShaderStates(
      gl_.get(), shader1, true, &kLog, &kTranslatedSource,
      &attrib_map, &uniform_map, &varying_map, NULL);
  EXPECT_TRUE(shader1->valid());
  // When compilation succeeds, no log is recorded.
  EXPECT_STREQ("", shader1->log_info().c_str());
  EXPECT_STREQ(kClient1Source, shader1->last_compiled_source().c_str());
  EXPECT_STREQ(kTranslatedSource.c_str(), shader1->translated_source().c_str());

  // Check varying infos got copied.
  EXPECT_EQ(attrib_map.size(), shader1->attrib_map().size());
  for (AttributeMap::const_iterator it = attrib_map.begin();
       it != attrib_map.end(); ++it) {
    const sh::Attribute* variable_info = shader1->GetAttribInfo(it->first);
    ASSERT_TRUE(variable_info != NULL);
    EXPECT_EQ(it->second.type, variable_info->type);
    EXPECT_EQ(it->second.arraySize, variable_info->arraySize);
    EXPECT_EQ(it->second.precision, variable_info->precision);
    EXPECT_EQ(it->second.staticUse, variable_info->staticUse);
    EXPECT_STREQ(it->second.name.c_str(), variable_info->name.c_str());
  }
  // Check uniform infos got copied.
  EXPECT_EQ(uniform_map.size(), shader1->uniform_map().size());
  for (UniformMap::const_iterator it = uniform_map.begin();
       it != uniform_map.end(); ++it) {
    const sh::Uniform* variable_info = shader1->GetUniformInfo(it->first);
    ASSERT_TRUE(variable_info != NULL);
    EXPECT_EQ(it->second.type, variable_info->type);
    EXPECT_EQ(it->second.arraySize, variable_info->arraySize);
    EXPECT_EQ(it->second.precision, variable_info->precision);
    EXPECT_EQ(it->second.staticUse, variable_info->staticUse);
    EXPECT_STREQ(it->second.name.c_str(), variable_info->name.c_str());
  }
  // Check varying infos got copied.
  EXPECT_EQ(varying_map.size(), shader1->varying_map().size());
  for (VaryingMap::const_iterator it = varying_map.begin();
       it != varying_map.end(); ++it) {
    const sh::Varying* variable_info = shader1->GetVaryingInfo(it->first);
    ASSERT_TRUE(variable_info != NULL);
    EXPECT_EQ(it->second.type, variable_info->type);
    EXPECT_EQ(it->second.arraySize, variable_info->arraySize);
    EXPECT_EQ(it->second.precision, variable_info->precision);
    EXPECT_EQ(it->second.staticUse, variable_info->staticUse);
    EXPECT_STREQ(it->second.name.c_str(), variable_info->name.c_str());
  }

  // Compile failure case.
  TestHelper::SetShaderStates(
      gl_.get(), shader1, false, &kLog, &kTranslatedSource,
      &attrib_map, &uniform_map, &varying_map, NULL);
  EXPECT_FALSE(shader1->valid());
  EXPECT_STREQ(kLog.c_str(), shader1->log_info().c_str());
  EXPECT_STREQ("", shader1->translated_source().c_str());
  EXPECT_TRUE(shader1->attrib_map().empty());
  EXPECT_TRUE(shader1->uniform_map().empty());
  EXPECT_TRUE(shader1->varying_map().empty());
}

TEST_F(ShaderManagerTest, ShaderInfoUseCount) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLenum kShader1Type = GL_VERTEX_SHADER;
  // Check we can create shader.
  Shader* shader1 = manager_.CreateShader(
      kClient1Id, kService1Id, kShader1Type);
  // Check shader got created.
  ASSERT_TRUE(shader1 != NULL);
  EXPECT_FALSE(shader1->InUse());
  EXPECT_FALSE(shader1->IsDeleted());
  manager_.UseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  manager_.UseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  EXPECT_CALL(*gl_, DeleteShader(kService1Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.Delete(shader1);
  EXPECT_TRUE(shader1->IsDeleted());
  Shader* shader2 = manager_.GetShader(kClient1Id);
  EXPECT_EQ(shader1, shader2);
  manager_.UnuseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  manager_.UnuseShader(shader1);  // this should delete the info.
  shader2 = manager_.GetShader(kClient1Id);
  EXPECT_TRUE(shader2 == NULL);

  shader1 = manager_.CreateShader(kClient1Id, kService1Id, kShader1Type);
  ASSERT_TRUE(shader1 != NULL);
  EXPECT_FALSE(shader1->InUse());
  manager_.UseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  manager_.UseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  manager_.UnuseShader(shader1);
  EXPECT_TRUE(shader1->InUse());
  manager_.UnuseShader(shader1);
  EXPECT_FALSE(shader1->InUse());
  shader2 = manager_.GetShader(kClient1Id);
  EXPECT_EQ(shader1, shader2);
  EXPECT_CALL(*gl_, DeleteShader(kService1Id))
      .Times(1)
      .RetiresOnSaturation();
  manager_.Delete(shader1);  // this should delete the shader.
  shader2 = manager_.GetShader(kClient1Id);
  EXPECT_TRUE(shader2 == NULL);
}

}  // namespace gles2
}  // namespace gpu
