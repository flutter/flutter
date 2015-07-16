// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/program_cache.h"

#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/mocks.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::Return;

namespace gpu {
namespace gles2 {

class NoBackendProgramCache : public ProgramCache {
 public:
  ProgramLoadResult LoadLinkedProgram(
      GLuint /* program */,
      Shader* /* shader_a */,
      Shader* /* shader_b */,
      const LocationMap* /* bind_attrib_location_map */,
      const std::vector<std::string>& /* transform_feedback_varyings */,
      GLenum /* transform_feedback_buffer_mode */,
      const ShaderCacheCallback& /* callback */) override {
    return PROGRAM_LOAD_SUCCESS;
  }
  void SaveLinkedProgram(
      GLuint /* program */,
      const Shader* /* shader_a */,
      const Shader* /* shader_b */,
      const LocationMap* /* bind_attrib_location_map */,
      const std::vector<std::string>& /* transform_feedback_varyings */,
      GLenum /* transform_feedback_buffer_mode */,
      const ShaderCacheCallback& /* callback */) override {}

  void LoadProgram(const std::string& /* program */) override {}

  void ClearBackend() override {}

  void SaySuccessfullyCached(const std::string& shader1,
                             const std::string& shader2,
                             std::map<std::string, GLint>* attrib_map,
                             const std::vector<std::string>& varyings,
                             GLenum buffer_mode) {
    char a_sha[kHashLength];
    char b_sha[kHashLength];
    ComputeShaderHash(shader1, a_sha);
    ComputeShaderHash(shader2, b_sha);

    char sha[kHashLength];
    ComputeProgramHash(a_sha,
                       b_sha,
                       attrib_map,
                       varyings,
                       buffer_mode,
                       sha);
    const std::string shaString(sha, kHashLength);

    LinkedProgramCacheSuccess(shaString);
  }

  void ComputeShaderHash(const std::string& shader,
                         char* result) const {
    ProgramCache::ComputeShaderHash(shader, result);
  }

  void ComputeProgramHash(
      const char* hashed_shader_0,
      const char* hashed_shader_1,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      char* result) const {
    ProgramCache::ComputeProgramHash(hashed_shader_0,
                                     hashed_shader_1,
                                     bind_attrib_location_map,
                                     transform_feedback_varyings,
                                     transform_feedback_buffer_mode,
                                     result);
  }

  void Evict(const std::string& program_hash) {
    ProgramCache::Evict(program_hash);
  }
};

class ProgramCacheTest : public testing::Test {
 public:
  ProgramCacheTest() :
    cache_(new NoBackendProgramCache()) { }

 protected:
  scoped_ptr<NoBackendProgramCache> cache_;
  std::vector<std::string> varyings_;
};

TEST_F(ProgramCacheTest, LinkStatusSave) {
  const std::string shader1 = "abcd1234";
  const std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  {
    std::string shader_a = shader1;
    std::string shader_b = shader2;
    EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
              cache_->GetLinkedProgramStatus(
                  shader_a, shader_b, NULL, varyings_, GL_NONE));
    cache_->SaySuccessfullyCached(shader_a, shader_b, NULL, varyings_, GL_NONE);

    shader_a.clear();
    shader_b.clear();
  }
  // make sure it was copied
  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED,
            cache_->GetLinkedProgramStatus(
                shader1, shader2, NULL, varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, LinkUnknownOnFragmentSourceChange) {
  const std::string shader1 = "abcd1234";
  std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_, GL_NONE);

  shader2 = "different!";
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, LinkUnknownOnVertexSourceChange) {
  std::string shader1 = "abcd1234";
  const std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_, GL_NONE);

  shader1 = "different!";
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, StatusEviction) {
  const std::string shader1 = "abcd1234";
  const std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_, GL_NONE);
  char a_sha[ProgramCache::kHashLength];
  char b_sha[ProgramCache::kHashLength];
  cache_->ComputeShaderHash(shader1, a_sha);
  cache_->ComputeShaderHash(shader2, b_sha);

  char sha[ProgramCache::kHashLength];
  cache_->ComputeProgramHash(a_sha,
                             b_sha,
                             NULL,
                             varyings_,
                             GL_NONE,
                             sha);
  cache_->Evict(std::string(sha, ProgramCache::kHashLength));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, EvictionWithReusedShader) {
  const std::string shader1 = "abcd1234";
  const std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  const std::string shader3 = "asbjbbjj239a";
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_, GL_NONE);
  cache_->SaySuccessfullyCached(shader1, shader3, NULL, varyings_, GL_NONE);

  char a_sha[ProgramCache::kHashLength];
  char b_sha[ProgramCache::kHashLength];
  char c_sha[ProgramCache::kHashLength];
  cache_->ComputeShaderHash(shader1, a_sha);
  cache_->ComputeShaderHash(shader2, b_sha);
  cache_->ComputeShaderHash(shader3, c_sha);

  char sha[ProgramCache::kHashLength];
  cache_->ComputeProgramHash(a_sha,
                             b_sha,
                             NULL,
                             varyings_,
                             GL_NONE,
                             sha);
  cache_->Evict(std::string(sha, ProgramCache::kHashLength));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
  EXPECT_EQ(ProgramCache::LINK_SUCCEEDED,
            cache_->GetLinkedProgramStatus(shader1, shader3, NULL,
            varyings_, GL_NONE));


  cache_->ComputeProgramHash(a_sha,
                             c_sha,
                             NULL,
                             varyings_,
                             GL_NONE,
                             sha);
  cache_->Evict(std::string(sha, ProgramCache::kHashLength));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader3, NULL,
            varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, StatusClear) {
  const std::string shader1 = "abcd1234";
  const std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  const std::string shader3 = "asbjbbjj239a";
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_, GL_NONE);
  cache_->SaySuccessfullyCached(shader1, shader3, NULL, varyings_, GL_NONE);
  cache_->Clear();
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_NONE));
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader3, NULL,
            varyings_, GL_NONE));
}

TEST_F(ProgramCacheTest, LinkUnknownOnTransformFeedbackChange) {
  const std::string shader1 = "abcd1234";
  std::string shader2 = "abcda sda b1~#4 bbbbb1234";
  varyings_.push_back("a");
  cache_->SaySuccessfullyCached(shader1, shader2, NULL, varyings_,
                                GL_INTERLEAVED_ATTRIBS);

  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_SEPARATE_ATTRIBS));

  varyings_.push_back("b");
  EXPECT_EQ(ProgramCache::LINK_UNKNOWN,
            cache_->GetLinkedProgramStatus(shader1, shader2, NULL,
            varyings_, GL_INTERLEAVED_ATTRIBS));
}

}  // namespace gles2
}  // namespace gpu
