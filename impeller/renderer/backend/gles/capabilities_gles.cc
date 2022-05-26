// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/capabilities_gles.h"

#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

CapabilitiesGLES::CapabilitiesGLES(const ProcTableGLES& gl) {
  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &value);
    max_combined_texture_image_units = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, &value);
    max_cube_map_texture_size = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS, &value);
    max_fragment_uniform_vectors = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &value);
    max_renderbuffer_size = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &value);
    max_texture_image_units = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_TEXTURE_SIZE, &value);
    max_texture_size = ISize{value, value};
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VARYING_VECTORS, &value);
    max_varying_vectors = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_ATTRIBS, &value);
    max_vertex_attribs = value;
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &value);
    max_vertex_texture_image_units = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS, &value);
    max_vertex_uniform_vectors = value;
  }

  {
    GLint values[2] = {};
    gl.GetIntegerv(GL_MAX_VIEWPORT_DIMS, values);
    max_viewport_dims = ISize{values[0], values[1]};
  }

  {
    GLint value = 0;
    gl.GetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS, &value);
    num_compressed_texture_formats = value;
  }

  if (gl.GetDescription()->IsES()) {
    GLint value = 0;
    gl.GetIntegerv(GL_NUM_SHADER_BINARY_FORMATS, &value);
    num_shader_binary_formats = value;
  }
}

size_t CapabilitiesGLES::GetMaxTextureUnits(ShaderStage stage) const {
  switch (stage) {
    case ShaderStage::kVertex:
      return max_vertex_texture_image_units;
    case ShaderStage::kFragment:
      return max_texture_image_units;
    case ShaderStage::kUnknown:
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
      return 0u;
  }
  FML_UNREACHABLE();
}

}  // namespace impeller
