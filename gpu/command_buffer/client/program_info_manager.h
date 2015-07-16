// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_PROGRAM_INFO_MANAGER_H_
#define GPU_COMMAND_BUFFER_CLIENT_PROGRAM_INFO_MANAGER_H_

#include <GLES3/gl3.h>

#include <string>
#include <vector>

#include "base/containers/hash_tables.h"
#include "base/gtest_prod_util.h"
#include "base/synchronization/lock.h"
#include "gles2_impl_export.h"
#include "gpu/command_buffer/client/gles2_implementation.h"

namespace gpu {
namespace gles2 {

// Manages info about OpenGL ES Programs.
class GLES2_IMPL_EXPORT ProgramInfoManager {
 public:
  ProgramInfoManager();
  ~ProgramInfoManager();

  void CreateInfo(GLuint program);

  void DeleteInfo(GLuint program);

  bool GetProgramiv(
      GLES2Implementation* gl, GLuint program, GLenum pname, GLint* params);

  GLint GetAttribLocation(
      GLES2Implementation* gl, GLuint program, const char* name);

  GLint GetUniformLocation(
      GLES2Implementation* gl, GLuint program, const char* name);

  GLint GetFragDataLocation(
      GLES2Implementation* gl, GLuint program, const char* name);

  bool GetActiveAttrib(
      GLES2Implementation* gl, GLuint program, GLuint index, GLsizei bufsize,
      GLsizei* length, GLint* size, GLenum* type, char* name);

  bool GetActiveUniform(
      GLES2Implementation* gl, GLuint program, GLuint index, GLsizei bufsize,
      GLsizei* length, GLint* size, GLenum* type, char* name);

  GLuint GetUniformBlockIndex(
      GLES2Implementation* gl, GLuint program, const char* name);

  bool GetActiveUniformBlockName(
      GLES2Implementation* gl, GLuint program, GLuint index,
      GLsizei buf_size, GLsizei* length, char* name);

  bool GetActiveUniformBlockiv(
      GLES2Implementation* gl, GLuint program, GLuint index,
      GLenum pname, GLint* params);

  // Attempt to update the |index| uniform block binding.
  // It's no op if the program does not exist, or the |index| uniform block
  // is not in the cache, or binding >= GL_MAX_UNIFORM_BUFFER_BINDINGS.
  void UniformBlockBinding(
      GLES2Implementation* gl, GLuint program, GLuint index, GLuint binding);

  bool GetTransformFeedbackVarying(
      GLES2Implementation* gl, GLuint program, GLuint index, GLsizei bufsize,
      GLsizei* length, GLsizei* size, GLenum* type, char* name);

  bool GetUniformIndices(
      GLES2Implementation* gl, GLuint program, GLsizei count,
      const char* const* names, GLuint* indices);

  bool GetActiveUniformsiv(
      GLES2Implementation* gl, GLuint program, GLsizei count,
      const GLuint* indices, GLenum pname, GLint* params);

 private:
  friend class ProgramInfoManagerTest;

  FRIEND_TEST_ALL_PREFIXES(ProgramInfoManagerTest, UpdateES2);
  FRIEND_TEST_ALL_PREFIXES(ProgramInfoManagerTest, UpdateES3UniformBlocks);
  FRIEND_TEST_ALL_PREFIXES(ProgramInfoManagerTest,
                           UpdateES3TransformFeedbackVaryings);
  FRIEND_TEST_ALL_PREFIXES(ProgramInfoManagerTest,
                           GetActiveUniformsivCached);

  enum ProgramInfoType {
    kES2,
    kES3UniformBlocks,
    kES3TransformFeedbackVaryings,
    kES3Uniformsiv,
    kNone,
  };

  // Need GLES2_IMPL_EXPORT for tests.
  class GLES2_IMPL_EXPORT Program {
   public:
    struct UniformInfo {
      UniformInfo(GLsizei _size, GLenum _type, const std::string& _name);
      ~UniformInfo();

      GLsizei size;
      GLenum type;
      bool is_array;
      std::string name;
      std::vector<GLint> element_locations;
    };
    struct UniformES3 {
      UniformES3();
      ~UniformES3();

      GLint block_index;
      GLint offset;
      GLint array_stride;
      GLint matrix_stride;
      GLint is_row_major;
    };
    struct VertexAttrib {
      VertexAttrib(GLsizei _size, GLenum _type, const std::string& _name,
                   GLint _location);
      ~VertexAttrib();

      GLsizei size;
      GLenum type;
      GLint location;
      std::string name;
    };
    struct UniformBlock {
      UniformBlock();
      ~UniformBlock();

      GLuint binding;
      GLuint data_size;
      std::vector<GLuint> active_uniform_indices;
      GLboolean referenced_by_vertex_shader;
      GLboolean referenced_by_fragment_shader;
      std::string name;
    };
    struct TransformFeedbackVarying {
      TransformFeedbackVarying();
      ~TransformFeedbackVarying();

      GLsizei size;
      GLenum type;
      std::string name;
    };

    Program();
    ~Program();

    const VertexAttrib* GetAttribInfo(GLint index) const;

    GLint GetAttribLocation(const std::string& name) const;

    const UniformInfo* GetUniformInfo(GLint index) const;

    // Gets the location of a uniform by name.
    GLint GetUniformLocation(const std::string& name) const;
    // Gets the index of a uniform by name. Return INVALID_INDEX in failure.
    GLuint GetUniformIndex(const std::string& name) const;

    bool GetUniformsiv(
        GLsizei count, const GLuint* indices, GLenum pname, GLint* params);

    GLint GetFragDataLocation(const std::string& name) const;
    void CacheFragDataLocation(const std::string& name, GLint loc);

    bool GetProgramiv(GLenum pname, GLint* params);

    // Gets the index of a uniform block by name.
    GLuint GetUniformBlockIndex(const std::string& name) const;
    const UniformBlock* GetUniformBlock(GLuint index) const;
    // Update the binding if the |index| uniform block is in the cache.
    void UniformBlockBinding(GLuint index, GLuint binding);

    const TransformFeedbackVarying* GetTransformFeedbackVarying(
        GLuint index) const;

    // Updates the ES2 only program info after a successful link.
    void UpdateES2(const std::vector<int8>& result);

    // Updates the ES3 UniformBlock info after a successful link.
    void UpdateES3UniformBlocks(const std::vector<int8>& result);

    // Updates the ES3 Uniformsiv info after a successful link.
    void UpdateES3Uniformsiv(const std::vector<int8>& result);

    // Updates the ES3 TransformFeedbackVaryings info after a successful link.
    void UpdateES3TransformFeedbackVaryings(const std::vector<int8>& result);

    bool IsCached(ProgramInfoType type) const;

   private:
    bool cached_es2_;

    GLsizei max_attrib_name_length_;

    // Attrib by index.
    std::vector<VertexAttrib> attrib_infos_;

    GLsizei max_uniform_name_length_;

    // Uniform info by index.
    std::vector<UniformInfo> uniform_infos_;

    // This is true if glLinkProgram was successful last time it was called.
    bool link_status_;

    // BELOW ARE ES3 ONLY INFORMATION.

    bool cached_es3_uniform_blocks_;

    uint32_t active_uniform_block_max_name_length_;

    // Uniform blocks by index.
    std::vector<UniformBlock> uniform_blocks_;

    bool cached_es3_transform_feedback_varyings_;

    uint32_t transform_feedback_varying_max_length_;

    // TransformFeedback varyings by index.
    std::vector<TransformFeedbackVarying> transform_feedback_varyings_;

    bool cached_es3_uniformsiv_;

    std::vector<UniformES3> uniforms_es3_;

    base::hash_map<std::string, GLint> frag_data_locations_;
  };

  Program* GetProgramInfo(
      GLES2Implementation* gl, GLuint program, ProgramInfoType type);

  typedef base::hash_map<GLuint, Program> ProgramInfoMap;

  ProgramInfoMap program_infos_;

  mutable base::Lock lock_;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_PROGRAM_INFO_MANAGER_H_
