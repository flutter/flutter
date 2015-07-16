// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/program_info_manager.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

uint32 ComputeOffset(const void* start, const void* position) {
  return static_cast<const uint8*>(position) -
         static_cast<const uint8*>(start);
}

const GLuint kClientProgramId = 321;

}  // namespace anonymous

namespace gpu {
namespace gles2 {

class ProgramInfoManagerTest : public testing::Test {
 public:
  ProgramInfoManagerTest() {}
  ~ProgramInfoManagerTest() override {}

 protected:
  typedef ProgramInfoManager::Program Program;

  struct ProgramES2Data {
    // TODO(zmo): Also add attrib data.
    ProgramInfoHeader header;
    ProgramInput uniforms[2];
    int32_t uniform_loc0[1];
    int32_t uniform_loc1[2];
    char uniform_name0[4];
    char uniform_name1[8];
  };

  struct UniformBlocksData {
    UniformBlocksHeader header;
    UniformBlockInfo entry[2];
    char name0[4];
    uint32_t indices0[2];
    char name1[8];
    uint32_t indices1[1];
  };

  struct UniformsES3Data {
    UniformsES3Header header;
    UniformES3Info entry[2];
  };

  struct TransformFeedbackVaryingsData {
    TransformFeedbackVaryingsHeader header;
    TransformFeedbackVaryingInfo entry[2];
    char name0[4];
    char name1[8];
  };

  void SetUp() override {
    program_info_manager_.reset(new ProgramInfoManager);
    program_info_manager_->CreateInfo(kClientProgramId);
    {
      base::AutoLock auto_lock(program_info_manager_->lock_);
      program_ = program_info_manager_->GetProgramInfo(
          NULL, kClientProgramId, ProgramInfoManager::kNone);
      ASSERT_TRUE(program_ != NULL);
    }
  }

  void TearDown() override {}

  void SetupProgramES2Data(ProgramES2Data* data) {
    // The names needs to be of size 4*k-1 to avoid padding in the struct Data.
    // This is a testing only problem.
    const char* kName[] = { "cow", "bull[0]" };
    data->header.link_status = 1;
    data->header.num_attribs = 0;
    data->header.num_uniforms = 2;
    data->uniforms[0].type = GL_FLOAT;
    data->uniforms[0].size = 1;
    data->uniforms[0].location_offset =
        ComputeOffset(data, &data->uniform_loc0);
    data->uniforms[0].name_offset =
        ComputeOffset(data, &data->uniform_name0);
    data->uniforms[0].name_length = strlen(kName[0]);
    data->uniforms[1].type = GL_FLOAT_VEC4;
    data->uniforms[1].size = 2;
    data->uniforms[1].location_offset =
        ComputeOffset(data, &data->uniform_loc1);
    data->uniforms[1].name_offset =
        ComputeOffset(data, &data->uniform_name1);
    data->uniforms[1].name_length = strlen(kName[1]);
    data->uniform_loc0[0] = 1;
    data->uniform_loc1[0] = 2;
    data->uniform_loc1[1] = 3;
    memcpy(data->uniform_name0, kName[0], arraysize(data->uniform_name0));
    memcpy(data->uniform_name1, kName[1], arraysize(data->uniform_name1));
  }

  void SetupUniformBlocksData(UniformBlocksData* data) {
    // The names needs to be of size 4*k-1 to avoid padding in the struct Data.
    // This is a testing only problem.
    const char* kName[] = { "cow", "chicken" };
    const uint32_t kIndices0[] = { 1, 2 };
    const uint32_t kIndices1[] = { 3 };
    const uint32_t* kIndices[] = { kIndices0, kIndices1 };
    data->header.num_uniform_blocks = 2;
    data->entry[0].binding = 0;
    data->entry[0].data_size = 8;
    data->entry[0].name_offset = ComputeOffset(data, data->name0);
    data->entry[0].name_length = arraysize(data->name0);
    data->entry[0].active_uniforms = arraysize(data->indices0);
    data->entry[0].active_uniform_offset = ComputeOffset(data, data->indices0);
    data->entry[0].referenced_by_vertex_shader = static_cast<uint32_t>(true);
    data->entry[0].referenced_by_fragment_shader = static_cast<uint32_t>(false);
    data->entry[1].binding = 1;
    data->entry[1].data_size = 4;
    data->entry[1].name_offset = ComputeOffset(data, data->name1);
    data->entry[1].name_length = arraysize(data->name1);
    data->entry[1].active_uniforms = arraysize(data->indices1);
    data->entry[1].active_uniform_offset = ComputeOffset(data, data->indices1);
    data->entry[1].referenced_by_vertex_shader = static_cast<uint32_t>(false);
    data->entry[1].referenced_by_fragment_shader = static_cast<uint32_t>(true);
    memcpy(data->name0, kName[0], arraysize(data->name0));
    data->indices0[0] = kIndices[0][0];
    data->indices0[1] = kIndices[0][1];
    memcpy(data->name1, kName[1], arraysize(data->name1));
    data->indices1[0] = kIndices[1][0];
  }

  void SetupUniformsES3Data(UniformsES3Data* data) {
    data->header.num_uniforms = 2;
    data->entry[0].block_index = 1;
    data->entry[0].offset = 2;
    data->entry[0].array_stride = 3;
    data->entry[0].matrix_stride = 4;
    data->entry[0].is_row_major = 0;
    data->entry[1].block_index = 5;
    data->entry[1].offset = 6;
    data->entry[1].array_stride = 7;
    data->entry[1].matrix_stride = 8;
    data->entry[1].is_row_major = 1;
  }

  void SetupTransformFeedbackVaryingsData(TransformFeedbackVaryingsData* data) {
    // The names needs to be of size 4*k-1 to avoid padding in the struct Data.
    // This is a testing only problem.
    const char* kName[] = { "cow", "chicken" };
    data->header.num_transform_feedback_varyings = 2;
    data->entry[0].size = 1;
    data->entry[0].type = GL_FLOAT_VEC2;
    data->entry[0].name_offset = ComputeOffset(data, data->name0);
    data->entry[0].name_length = arraysize(data->name0);
    data->entry[1].size = 2;
    data->entry[1].type = GL_FLOAT;
    data->entry[1].name_offset = ComputeOffset(data, data->name1);
    data->entry[1].name_length = arraysize(data->name1);
    memcpy(data->name0, kName[0], arraysize(data->name0));
    memcpy(data->name1, kName[1], arraysize(data->name1));
  }

  scoped_ptr<ProgramInfoManager> program_info_manager_;
  Program* program_;
};

TEST_F(ProgramInfoManagerTest, UpdateES2) {
  ProgramES2Data data;
  SetupProgramES2Data(&data);
  const std::string kNames[] = { data.uniform_name0, data.uniform_name1 };
  const int32_t* kLocs[] = { data.uniform_loc0, data.uniform_loc1 };
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  EXPECT_FALSE(program_->IsCached(ProgramInfoManager::kES2));
  program_->UpdateES2(result);
  EXPECT_TRUE(program_->IsCached(ProgramInfoManager::kES2));

  GLint params = 0;
  EXPECT_TRUE(program_->GetProgramiv(GL_LINK_STATUS, &params));
  EXPECT_TRUE(params);

  params = 0;
  EXPECT_TRUE(program_->GetProgramiv(GL_ACTIVE_ATTRIBUTES, &params));
  EXPECT_EQ(data.header.num_attribs, static_cast<uint32_t>(params));
  params = 0;
  EXPECT_TRUE(program_->GetProgramiv(GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &params));
  EXPECT_EQ(0, params);

  params = 0;
  EXPECT_TRUE(program_->GetProgramiv(GL_ACTIVE_UNIFORMS, &params));
  EXPECT_EQ(data.header.num_uniforms, static_cast<uint32_t>(params));
  GLint active_uniform_max_length = 0;
  EXPECT_TRUE(program_->GetProgramiv(
      GL_ACTIVE_UNIFORM_MAX_LENGTH, &active_uniform_max_length));

  for (uint32_t ii = 0; ii < data.header.num_uniforms; ++ii) {
    const Program::UniformInfo* info = program_->GetUniformInfo(ii);
    EXPECT_TRUE(info != NULL);
    EXPECT_EQ(data.uniforms[ii].type, info->type);
    EXPECT_EQ(data.uniforms[ii].size, info->size);
    EXPECT_LT(kNames[0].length(),
              static_cast<size_t>(active_uniform_max_length));
    EXPECT_EQ(kNames[ii], info->name);
    EXPECT_EQ(kNames[ii][kNames[ii].length() - 1] == ']', info->is_array);
    EXPECT_EQ(data.uniforms[ii].size,
              static_cast<int32_t>(info->element_locations.size()));
    for (int32_t uu = 0; uu < data.uniforms[ii].size; ++uu) {
      EXPECT_EQ(kLocs[ii][uu], info->element_locations[uu]);
    }
  }
}

TEST_F(ProgramInfoManagerTest, UpdateES3UniformBlocks) {
  UniformBlocksData data;
  SetupUniformBlocksData(&data);
  const std::string kName[] = { data.name0, data.name1 };
  const uint32_t* kIndices[] = { data.indices0, data.indices1 };
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  EXPECT_FALSE(program_->IsCached(ProgramInfoManager::kES3UniformBlocks));
  program_->UpdateES3UniformBlocks(result);
  EXPECT_TRUE(program_->IsCached(ProgramInfoManager::kES3UniformBlocks));

  GLint uniform_block_count = 0;
  EXPECT_TRUE(program_->GetProgramiv(
      GL_ACTIVE_UNIFORM_BLOCKS, &uniform_block_count));
  EXPECT_EQ(data.header.num_uniform_blocks,
            static_cast<uint32_t>(uniform_block_count));
  GLint max_name_length = 0;
  EXPECT_TRUE(program_->GetProgramiv(
      GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH, &max_name_length));
  for (uint32_t ii = 0; ii < data.header.num_uniform_blocks; ++ii) {
    EXPECT_EQ(ii, program_->GetUniformBlockIndex(kName[ii]));
    const Program::UniformBlock* info = program_->GetUniformBlock(ii);
    EXPECT_TRUE(info != NULL);
    EXPECT_EQ(data.entry[ii].binding, info->binding);
    EXPECT_EQ(data.entry[ii].data_size, info->data_size);
    EXPECT_EQ(data.entry[ii].active_uniforms,
              info->active_uniform_indices.size());
    for (uint32_t uu = 0; uu < data.entry[ii].active_uniforms; ++uu) {
      EXPECT_EQ(kIndices[ii][uu], info->active_uniform_indices[uu]);
    }
    EXPECT_EQ(data.entry[ii].referenced_by_vertex_shader,
              static_cast<GLboolean>(info->referenced_by_vertex_shader));
    EXPECT_EQ(data.entry[ii].referenced_by_fragment_shader,
              static_cast<GLboolean>(info->referenced_by_fragment_shader));
    EXPECT_EQ(kName[ii], info->name);
    EXPECT_GE(max_name_length, static_cast<GLint>(info->name.size()) + 1);
  }

  EXPECT_EQ(GL_INVALID_INDEX, program_->GetUniformBlockIndex("BadName"));
  EXPECT_EQ(NULL, program_->GetUniformBlock(data.header.num_uniform_blocks));
}

TEST_F(ProgramInfoManagerTest, UpdateES3TransformFeedbackVaryings) {
  TransformFeedbackVaryingsData data;
  SetupTransformFeedbackVaryingsData(&data);
  const std::string kName[] = { data.name0, data.name1 };
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  EXPECT_FALSE(program_->IsCached(
      ProgramInfoManager::kES3TransformFeedbackVaryings));
  program_->UpdateES3TransformFeedbackVaryings(result);
  EXPECT_TRUE(program_->IsCached(
      ProgramInfoManager::kES3TransformFeedbackVaryings));

  GLint transform_feedback_varying_count = 0;
  EXPECT_TRUE(program_->GetProgramiv(
      GL_TRANSFORM_FEEDBACK_VARYINGS, &transform_feedback_varying_count));
  EXPECT_EQ(data.header.num_transform_feedback_varyings,
            static_cast<uint32_t>(transform_feedback_varying_count));
  GLint max_name_length = 0;
  EXPECT_TRUE(program_->GetProgramiv(
      GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, &max_name_length));
  for (uint32_t ii = 0; ii < data.header.num_transform_feedback_varyings;
       ++ii) {
    const Program::TransformFeedbackVarying* varying =
        program_->GetTransformFeedbackVarying(ii);
    EXPECT_TRUE(varying != NULL);
    EXPECT_EQ(data.entry[ii].size, static_cast<uint32_t>(varying->size));
    EXPECT_EQ(data.entry[ii].type, varying->type);
    EXPECT_EQ(kName[ii], varying->name);
    EXPECT_GE(max_name_length, static_cast<GLint>(varying->name.size()) + 1);
  }
  EXPECT_EQ(NULL, program_->GetTransformFeedbackVarying(
  data.header.num_transform_feedback_varyings));
}

TEST_F(ProgramInfoManagerTest, GetUniformBlockIndexCached) {
  UniformBlocksData data;
  SetupUniformBlocksData(&data);
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  program_->UpdateES3UniformBlocks(result);

  EXPECT_EQ(0u, program_info_manager_->GetUniformBlockIndex(
      NULL, kClientProgramId, data.name0));
  EXPECT_EQ(1u, program_info_manager_->GetUniformBlockIndex(
      NULL, kClientProgramId, data.name1));
  EXPECT_EQ(GL_INVALID_INDEX, program_info_manager_->GetUniformBlockIndex(
      NULL, kClientProgramId, "BadName"));
}

TEST_F(ProgramInfoManagerTest, GetActiveUniformBlockNameCached) {
  UniformBlocksData data;
  SetupUniformBlocksData(&data);
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  program_->UpdateES3UniformBlocks(result);

  GLsizei buf_size = std::max(strlen(data.name0), strlen(data.name1)) + 1;
  std::vector<char> buffer(buf_size);
  GLsizei length = 0;
  EXPECT_EQ(true, program_info_manager_->GetActiveUniformBlockName(
      NULL, kClientProgramId, 0, buf_size, &length, &buffer[0]));
  EXPECT_EQ(static_cast<GLsizei>(strlen(data.name0)), length);
  EXPECT_STREQ(data.name0, &buffer[0]);

  EXPECT_EQ(true, program_info_manager_->GetActiveUniformBlockName(
      NULL, kClientProgramId, 1, buf_size, &length, &buffer[0]));
  EXPECT_EQ(static_cast<GLsizei>(strlen(data.name1)), length);
  EXPECT_STREQ(data.name1, &buffer[0]);

  // Test length == NULL.
  EXPECT_EQ(true, program_info_manager_->GetActiveUniformBlockName(
      NULL, kClientProgramId, 0, buf_size, NULL, &buffer[0]));
  EXPECT_STREQ(data.name0, &buffer[0]);

  // Test buffer == NULL.
  EXPECT_EQ(true, program_info_manager_->GetActiveUniformBlockName(
      NULL, kClientProgramId, 0, buf_size, &length, NULL));
  EXPECT_EQ(0, length);

  // Test buf_size smaller than string size.
  buf_size = strlen(data.name0);
  EXPECT_EQ(true, program_info_manager_->GetActiveUniformBlockName(
      NULL, kClientProgramId, 0, buf_size, &length, &buffer[0]));
  EXPECT_EQ(buf_size, length + 1);
  EXPECT_STREQ(std::string(data.name0).substr(0, length).c_str(), &buffer[0]);
}

TEST_F(ProgramInfoManagerTest, GetActiveUniformBlockivCached) {
  UniformBlocksData data;
  SetupUniformBlocksData(&data);
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  program_->UpdateES3UniformBlocks(result);
  const char* kName[] = { data.name0, data.name1 };
  const uint32_t* kIndices[] = { data.indices0, data.indices1 };

  for (uint32_t ii = 0; ii < data.header.num_uniform_blocks; ++ii) {
    ASSERT_GE(2u, data.entry[ii].active_uniforms);
    GLint params[2];
    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii, GL_UNIFORM_BLOCK_BINDING, params));
    EXPECT_EQ(data.entry[ii].binding, static_cast<uint32_t>(params[0]));

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii, GL_UNIFORM_BLOCK_DATA_SIZE, params));
    EXPECT_EQ(data.entry[ii].data_size, static_cast<uint32_t>(params[0]));

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii, GL_UNIFORM_BLOCK_NAME_LENGTH, params));
    EXPECT_EQ(strlen(kName[ii]) + 1, static_cast<uint32_t>(params[0]));

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, params));
    EXPECT_EQ(data.entry[ii].active_uniforms, static_cast<uint32_t>(params[0]));

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii,
        GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, params));
    for (uint32_t uu = 0; uu < data.entry[ii].active_uniforms; ++uu) {
      EXPECT_EQ(kIndices[ii][uu], static_cast<uint32_t>(params[uu]));
    }

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii,
        GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER, params));
    EXPECT_EQ(data.entry[ii].referenced_by_vertex_shader,
              static_cast<uint32_t>(params[0]));

    EXPECT_TRUE(program_info_manager_->GetActiveUniformBlockiv(
        NULL, kClientProgramId, ii,
        GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER, params));
    EXPECT_EQ(data.entry[ii].referenced_by_fragment_shader,
              static_cast<uint32_t>(params[0]));
  }
}

TEST_F(ProgramInfoManagerTest, GetTransformFeedbackVaryingCached) {
  TransformFeedbackVaryingsData data;
  SetupTransformFeedbackVaryingsData(&data);
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  program_->UpdateES3TransformFeedbackVaryings(result);
  const char* kName[] = { data.name0, data.name1 };
  GLsizei buf_size = std::max(strlen(kName[0]), strlen(kName[1])) + 1;
  for (uint32_t ii = 0; ii < data.header.num_transform_feedback_varyings;
       ++ii) {
    std::vector<char> buffer(buf_size);
    GLsizei length = 0;
    GLsizei size = 0;
    GLenum type = 0;
    EXPECT_EQ(true, program_info_manager_->GetTransformFeedbackVarying(
        NULL, kClientProgramId, ii, buf_size,
        &length, &size, &type, &buffer[0]));
    EXPECT_EQ(data.entry[ii].size, static_cast<uint32_t>(size));
    EXPECT_EQ(data.entry[ii].type, static_cast<uint32_t>(type));
    EXPECT_STREQ(kName[ii], &buffer[0]);
    EXPECT_EQ(strlen(kName[ii]), static_cast<size_t>(length));
  }
}

TEST_F(ProgramInfoManagerTest, GetUniformIndices) {
  ProgramES2Data data;
  SetupProgramES2Data(&data);
  std::vector<int8> result(sizeof(data));
  memcpy(&result[0], &data, sizeof(data));
  program_->UpdateES2(result);

  {  // Original order.
    const char* kNames[] = { data.uniform_name0, data.uniform_name1 };
    const GLuint kIndices[] = { 0, 1 };
    const GLsizei kCount = 2;
    GLuint indices[kCount];
    EXPECT_TRUE(program_info_manager_->GetUniformIndices(
        NULL, kClientProgramId, kCount, kNames, indices));
    for (GLsizei ii = 0; ii < kCount; ++ii) {
      EXPECT_EQ(kIndices[ii], indices[ii]);
    }
  }

  {  // Switched order.
    const char* kNames[] = { data.uniform_name1, data.uniform_name0 };
    const GLuint kIndices[] = { 1, 0 };
    const GLsizei kCount = 2;
    GLuint indices[kCount];
    EXPECT_TRUE(program_info_manager_->GetUniformIndices(
        NULL, kClientProgramId, kCount, kNames, indices));
    for (GLsizei ii = 0; ii < kCount; ++ii) {
      EXPECT_EQ(kIndices[ii], indices[ii]);
    }
  }

  {  // With bad names.
    const char* kNames[] = { data.uniform_name1, "BadName" };
    const GLuint kIndices[] = { 1, GL_INVALID_INDEX };
    const GLsizei kCount = 2;
    GLuint indices[kCount];
    EXPECT_TRUE(program_info_manager_->GetUniformIndices(
        NULL, kClientProgramId, kCount, kNames, indices));
    for (GLsizei ii = 0; ii < kCount; ++ii) {
      EXPECT_EQ(kIndices[ii], indices[ii]);
    }
  }

  {  // Both "foo" and "foo[0]" are considered valid names for an array,
     // but not "foo[1]".
    const char* kNames[] = { "bull", "bull[0]", "bull[1]" };
    const GLuint kIndices[] = { 1, 1, GL_INVALID_INDEX };
    const GLsizei kCount = 3;
    GLuint indices[kCount];
    EXPECT_TRUE(program_info_manager_->GetUniformIndices(
        NULL, kClientProgramId, kCount, kNames, indices));
    for (GLsizei ii = 0; ii < kCount; ++ii) {
      EXPECT_EQ(kIndices[ii], indices[ii]);
    }
  }
}

TEST_F(ProgramInfoManagerTest, GetActiveUniformsivCached) {
  // ES3 only parameters.
  UniformsES3Data data_es3;
  SetupUniformsES3Data(&data_es3);
  std::vector<int8> result(sizeof(data_es3));
  memcpy(&result[0], &data_es3, sizeof(data_es3));
  EXPECT_FALSE(program_->IsCached(ProgramInfoManager::kES3Uniformsiv));
  program_->UpdateES3Uniformsiv(result);
  EXPECT_TRUE(program_->IsCached(ProgramInfoManager::kES3Uniformsiv));

  uint32_t count = data_es3.header.num_uniforms;
  std::vector<GLuint> indices(count);
  for (uint32_t ii = 0; ii < count; ++ii) {
    indices[ii] = ii;
  }
  std::vector<GLint> block_index(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_BLOCK_INDEX, &block_index[0]));
  std::vector<GLint> offset(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_OFFSET, &offset[0]));
  std::vector<GLint> array_stride(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_ARRAY_STRIDE, &array_stride[0]));
  std::vector<GLint> matrix_stride(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_MATRIX_STRIDE, &matrix_stride[0]));
  std::vector<GLint> is_row_major(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_IS_ROW_MAJOR, &is_row_major[0]));

  for (uint32_t ii = 0; ii < count; ++ii) {
    EXPECT_EQ(data_es3.entry[ii].block_index, block_index[ii]);
    EXPECT_EQ(data_es3.entry[ii].offset, offset[ii]);
    EXPECT_EQ(data_es3.entry[ii].array_stride, array_stride[ii]);
    EXPECT_EQ(data_es3.entry[ii].matrix_stride, matrix_stride[ii]);
    EXPECT_EQ(data_es3.entry[ii].is_row_major, is_row_major[ii]);
  }

  // ES2 parameters.
  ProgramES2Data data_es2;
  SetupProgramES2Data(&data_es2);
  result.resize(sizeof(data_es2));
  memcpy(&result[0], &data_es2, sizeof(data_es2));
  EXPECT_FALSE(program_->IsCached(ProgramInfoManager::kES2));
  program_->UpdateES2(result);
  EXPECT_TRUE(program_->IsCached(ProgramInfoManager::kES2));

  std::vector<GLint> size(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_SIZE, &size[0]));
  std::vector<GLint> type(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_TYPE, &type[0]));
  std::vector<GLint> name_length(count);
  EXPECT_TRUE(program_info_manager_->GetActiveUniformsiv(
      NULL, kClientProgramId, static_cast<GLsizei>(count), &indices[0],
      GL_UNIFORM_NAME_LENGTH, &name_length[0]));

  for (uint32_t ii = 0; ii < count; ++ii) {
    EXPECT_EQ(data_es2.uniforms[ii].size, size[ii]);
    EXPECT_EQ(data_es2.uniforms[ii].type, static_cast<uint32_t>(type[ii]));
    EXPECT_EQ(data_es2.uniforms[ii].name_length + 1,
              static_cast<uint32_t>(name_length[ii]));
  }
}

}  // namespace gles2
}  // namespace gpu

