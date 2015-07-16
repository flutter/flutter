// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_COPY_TEXTURE_CHROMIUM_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_COPY_TEXTURE_CHROMIUM_H_

#include <vector>

#include "base/containers/hash_tables.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class GLES2Decoder;

}  // namespace gles2.

// This class encapsulates the resources required to implement the
// GL_CHROMIUM_copy_texture extension.  The copy operation is performed
// via glCopyTexImage2D() or a blit to a framebuffer object.
// The target of |dest_id| texture must be GL_TEXTURE_2D.
class GPU_EXPORT CopyTextureCHROMIUMResourceManager {
 public:
  CopyTextureCHROMIUMResourceManager();
  ~CopyTextureCHROMIUMResourceManager();

  void Initialize(const gles2::GLES2Decoder* decoder);
  void Destroy();

  void DoCopyTexture(const gles2::GLES2Decoder* decoder,
                     GLenum source_target,
                     GLuint source_id,
                     GLenum source_internal_format,
                     GLuint dest_id,
                     GLenum dest_internal_format,
                     GLsizei width,
                     GLsizei height,
                     bool flip_y,
                     bool premultiply_alpha,
                     bool unpremultiply_alpha);

  void DoCopySubTexture(const gles2::GLES2Decoder* decoder,
                        GLenum source_target,
                        GLuint source_id,
                        GLenum source_internal_format,
                        GLuint dest_id,
                        GLenum dest_internal_format,
                        GLint xoffset,
                        GLint yoffset,
                        GLsizei dest_width,
                        GLsizei dest_height,
                        GLsizei source_width,
                        GLsizei source_height,
                        bool flip_y,
                        bool premultiply_alpha,
                        bool unpremultiply_alpha);

  // This will apply a transform on the source texture before copying to
  // destination texture.
  void DoCopyTextureWithTransform(const gles2::GLES2Decoder* decoder,
                                  GLenum source_target,
                                  GLuint source_id,
                                  GLuint dest_id,
                                  GLsizei width,
                                  GLsizei height,
                                  bool flip_y,
                                  bool premultiply_alpha,
                                  bool unpremultiply_alpha,
                                  const GLfloat transform_matrix[16]);

  void DoCopySubTextureWithTransform(const gles2::GLES2Decoder* decoder,
                                     GLenum source_target,
                                     GLuint source_id,
                                     GLuint dest_id,
                                     GLint xoffset,
                                     GLint yoffset,
                                     GLsizei dest_width,
                                     GLsizei dest_height,
                                     GLsizei source_width,
                                     GLsizei source_height,
                                     bool flip_y,
                                     bool premultiply_alpha,
                                     bool unpremultiply_alpha,
                                     const GLfloat transform_matrix[16]);

  // The attributes used during invocation of the extension.
  static const GLuint kVertexPositionAttrib = 0;

 private:
  struct ProgramInfo {
    ProgramInfo()
        : program(0u),
          matrix_handle(0u),
          half_size_handle(0u),
          sampler_handle(0u) {}

    GLuint program;
    GLuint matrix_handle;
    GLuint half_size_handle;
    GLuint sampler_handle;
  };

  void DoCopyTextureInternal(const gles2::GLES2Decoder* decoder,
                             GLenum source_target,
                             GLuint source_id,
                             GLuint dest_id,
                             GLint xoffset,
                             GLint yoffset,
                             GLsizei dest_width,
                             GLsizei dest_height,
                             GLsizei source_width,
                             GLsizei source_height,
                             bool flip_y,
                             bool premultiply_alpha,
                             bool unpremultiply_alpha,
                             const GLfloat transform_matrix[16]);

  bool initialized_;
  typedef std::vector<GLuint> ShaderVector;
  ShaderVector vertex_shaders_;
  ShaderVector fragment_shaders_;
  typedef std::pair<int, int> ProgramMapKey;
  typedef base::hash_map<ProgramMapKey, ProgramInfo> ProgramMap;
  ProgramMap programs_;
  GLuint buffer_id_;
  GLuint framebuffer_;

  DISALLOW_COPY_AND_ASSIGN(CopyTextureCHROMIUMResourceManager);
};

}  // namespace gpu.

#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_COPY_TEXTURE_CHROMIUM_H_
