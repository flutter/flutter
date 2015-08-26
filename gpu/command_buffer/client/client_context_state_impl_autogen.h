// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by client_context_state.cc
#ifndef GPU_COMMAND_BUFFER_CLIENT_CLIENT_CONTEXT_STATE_IMPL_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_CLIENT_CLIENT_CONTEXT_STATE_IMPL_AUTOGEN_H_

ClientContextState::EnableFlags::EnableFlags()
    : blend(false),
      cull_face(false),
      depth_test(false),
      dither(true),
      polygon_offset_fill(false),
      sample_alpha_to_coverage(false),
      sample_coverage(false),
      scissor_test(false),
      stencil_test(false),
      rasterizer_discard(false),
      primitive_restart_fixed_index(false) {}

bool ClientContextState::SetCapabilityState(GLenum cap,
                                            bool enabled,
                                            bool* changed) {
  *changed = false;
  switch (cap) {
    case GL_BLEND:
      if (enable_flags.blend != enabled) {
        *changed = true;
        enable_flags.blend = enabled;
      }
      return true;
    case GL_CULL_FACE:
      if (enable_flags.cull_face != enabled) {
        *changed = true;
        enable_flags.cull_face = enabled;
      }
      return true;
    case GL_DEPTH_TEST:
      if (enable_flags.depth_test != enabled) {
        *changed = true;
        enable_flags.depth_test = enabled;
      }
      return true;
    case GL_DITHER:
      if (enable_flags.dither != enabled) {
        *changed = true;
        enable_flags.dither = enabled;
      }
      return true;
    case GL_POLYGON_OFFSET_FILL:
      if (enable_flags.polygon_offset_fill != enabled) {
        *changed = true;
        enable_flags.polygon_offset_fill = enabled;
      }
      return true;
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
      if (enable_flags.sample_alpha_to_coverage != enabled) {
        *changed = true;
        enable_flags.sample_alpha_to_coverage = enabled;
      }
      return true;
    case GL_SAMPLE_COVERAGE:
      if (enable_flags.sample_coverage != enabled) {
        *changed = true;
        enable_flags.sample_coverage = enabled;
      }
      return true;
    case GL_SCISSOR_TEST:
      if (enable_flags.scissor_test != enabled) {
        *changed = true;
        enable_flags.scissor_test = enabled;
      }
      return true;
    case GL_STENCIL_TEST:
      if (enable_flags.stencil_test != enabled) {
        *changed = true;
        enable_flags.stencil_test = enabled;
      }
      return true;
    case GL_RASTERIZER_DISCARD:
      if (enable_flags.rasterizer_discard != enabled) {
        *changed = true;
        enable_flags.rasterizer_discard = enabled;
      }
      return true;
    case GL_PRIMITIVE_RESTART_FIXED_INDEX:
      if (enable_flags.primitive_restart_fixed_index != enabled) {
        *changed = true;
        enable_flags.primitive_restart_fixed_index = enabled;
      }
      return true;
    default:
      return false;
  }
}
bool ClientContextState::GetEnabled(GLenum cap, bool* enabled) const {
  switch (cap) {
    case GL_BLEND:
      *enabled = enable_flags.blend;
      return true;
    case GL_CULL_FACE:
      *enabled = enable_flags.cull_face;
      return true;
    case GL_DEPTH_TEST:
      *enabled = enable_flags.depth_test;
      return true;
    case GL_DITHER:
      *enabled = enable_flags.dither;
      return true;
    case GL_POLYGON_OFFSET_FILL:
      *enabled = enable_flags.polygon_offset_fill;
      return true;
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
      *enabled = enable_flags.sample_alpha_to_coverage;
      return true;
    case GL_SAMPLE_COVERAGE:
      *enabled = enable_flags.sample_coverage;
      return true;
    case GL_SCISSOR_TEST:
      *enabled = enable_flags.scissor_test;
      return true;
    case GL_STENCIL_TEST:
      *enabled = enable_flags.stencil_test;
      return true;
    case GL_RASTERIZER_DISCARD:
      *enabled = enable_flags.rasterizer_discard;
      return true;
    case GL_PRIMITIVE_RESTART_FIXED_INDEX:
      *enabled = enable_flags.primitive_restart_fixed_index;
      return true;
    default:
      return false;
  }
}
#endif  // GPU_COMMAND_BUFFER_CLIENT_CLIENT_CONTEXT_STATE_IMPL_AUTOGEN_H_
