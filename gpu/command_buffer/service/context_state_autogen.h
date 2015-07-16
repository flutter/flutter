// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by context_state.h
#ifndef GPU_COMMAND_BUFFER_SERVICE_CONTEXT_STATE_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_SERVICE_CONTEXT_STATE_AUTOGEN_H_

struct EnableFlags {
  EnableFlags();
  bool blend;
  bool cached_blend;
  bool cull_face;
  bool cached_cull_face;
  bool depth_test;
  bool cached_depth_test;
  bool dither;
  bool cached_dither;
  bool polygon_offset_fill;
  bool cached_polygon_offset_fill;
  bool sample_alpha_to_coverage;
  bool cached_sample_alpha_to_coverage;
  bool sample_coverage;
  bool cached_sample_coverage;
  bool scissor_test;
  bool cached_scissor_test;
  bool stencil_test;
  bool cached_stencil_test;
  bool rasterizer_discard;
  bool cached_rasterizer_discard;
  bool primitive_restart_fixed_index;
  bool cached_primitive_restart_fixed_index;
};

GLfloat blend_color_red;
GLfloat blend_color_green;
GLfloat blend_color_blue;
GLfloat blend_color_alpha;
GLenum blend_equation_rgb;
GLenum blend_equation_alpha;
GLenum blend_source_rgb;
GLenum blend_dest_rgb;
GLenum blend_source_alpha;
GLenum blend_dest_alpha;
GLfloat color_clear_red;
GLfloat color_clear_green;
GLfloat color_clear_blue;
GLfloat color_clear_alpha;
GLclampf depth_clear;
GLint stencil_clear;
GLboolean color_mask_red;
GLboolean cached_color_mask_red;
GLboolean color_mask_green;
GLboolean cached_color_mask_green;
GLboolean color_mask_blue;
GLboolean cached_color_mask_blue;
GLboolean color_mask_alpha;
GLboolean cached_color_mask_alpha;
GLenum cull_mode;
GLenum depth_func;
GLboolean depth_mask;
GLboolean cached_depth_mask;
GLclampf z_near;
GLclampf z_far;
GLenum front_face;
GLenum hint_generate_mipmap;
GLenum hint_fragment_shader_derivative;
GLfloat line_width;
GLfloat modelview_matrix[16];
GLfloat projection_matrix[16];
GLint pack_alignment;
GLint unpack_alignment;
GLfloat polygon_offset_factor;
GLfloat polygon_offset_units;
GLclampf sample_coverage_value;
GLboolean sample_coverage_invert;
GLint scissor_x;
GLint scissor_y;
GLsizei scissor_width;
GLsizei scissor_height;
GLenum stencil_front_func;
GLint stencil_front_ref;
GLuint stencil_front_mask;
GLenum stencil_back_func;
GLint stencil_back_ref;
GLuint stencil_back_mask;
GLuint stencil_front_writemask;
GLuint cached_stencil_front_writemask;
GLuint stencil_back_writemask;
GLuint cached_stencil_back_writemask;
GLenum stencil_front_fail_op;
GLenum stencil_front_z_fail_op;
GLenum stencil_front_z_pass_op;
GLenum stencil_back_fail_op;
GLenum stencil_back_z_fail_op;
GLenum stencil_back_z_pass_op;
GLint viewport_x;
GLint viewport_y;
GLsizei viewport_width;
GLsizei viewport_height;

inline void SetDeviceCapabilityState(GLenum cap, bool enable) {
  switch (cap) {
    case GL_BLEND:
      if (enable_flags.cached_blend == enable && !ignore_cached_state)
        return;
      enable_flags.cached_blend = enable;
      break;
    case GL_CULL_FACE:
      if (enable_flags.cached_cull_face == enable && !ignore_cached_state)
        return;
      enable_flags.cached_cull_face = enable;
      break;
    case GL_DEPTH_TEST:
      if (enable_flags.cached_depth_test == enable && !ignore_cached_state)
        return;
      enable_flags.cached_depth_test = enable;
      break;
    case GL_DITHER:
      if (enable_flags.cached_dither == enable && !ignore_cached_state)
        return;
      enable_flags.cached_dither = enable;
      break;
    case GL_POLYGON_OFFSET_FILL:
      if (enable_flags.cached_polygon_offset_fill == enable &&
          !ignore_cached_state)
        return;
      enable_flags.cached_polygon_offset_fill = enable;
      break;
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
      if (enable_flags.cached_sample_alpha_to_coverage == enable &&
          !ignore_cached_state)
        return;
      enable_flags.cached_sample_alpha_to_coverage = enable;
      break;
    case GL_SAMPLE_COVERAGE:
      if (enable_flags.cached_sample_coverage == enable && !ignore_cached_state)
        return;
      enable_flags.cached_sample_coverage = enable;
      break;
    case GL_SCISSOR_TEST:
      if (enable_flags.cached_scissor_test == enable && !ignore_cached_state)
        return;
      enable_flags.cached_scissor_test = enable;
      break;
    case GL_STENCIL_TEST:
      if (enable_flags.cached_stencil_test == enable && !ignore_cached_state)
        return;
      enable_flags.cached_stencil_test = enable;
      break;
    case GL_RASTERIZER_DISCARD:
      if (enable_flags.cached_rasterizer_discard == enable &&
          !ignore_cached_state)
        return;
      enable_flags.cached_rasterizer_discard = enable;
      break;
    case GL_PRIMITIVE_RESTART_FIXED_INDEX:
      if (enable_flags.cached_primitive_restart_fixed_index == enable &&
          !ignore_cached_state)
        return;
      enable_flags.cached_primitive_restart_fixed_index = enable;
      break;
    default:
      NOTREACHED();
      return;
  }
  if (enable)
    glEnable(cap);
  else
    glDisable(cap);
}
#endif  // GPU_COMMAND_BUFFER_SERVICE_CONTEXT_STATE_AUTOGEN_H_
