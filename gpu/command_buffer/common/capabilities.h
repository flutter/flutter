// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_CAPABILITIES_H_
#define GPU_COMMAND_BUFFER_COMMON_CAPABILITIES_H_

#include "gpu/gpu_export.h"

// From gl2.h. We want to avoid including gl headers because client-side and
// service-side headers conflict.
#define GL_FRAGMENT_SHADER 0x8B30
#define GL_VERTEX_SHADER 0x8B31
#define GL_LOW_FLOAT 0x8DF0
#define GL_MEDIUM_FLOAT 0x8DF1
#define GL_HIGH_FLOAT 0x8DF2
#define GL_LOW_INT 0x8DF3
#define GL_MEDIUM_INT 0x8DF4
#define GL_HIGH_INT 0x8DF5

namespace gpu {

struct GPU_EXPORT Capabilities {
  struct ShaderPrecision {
    ShaderPrecision() : min_range(0), max_range(0), precision(0) {}
    int min_range;
    int max_range;
    int precision;
  };

  struct PerStagePrecisions {
    PerStagePrecisions();

    ShaderPrecision low_int;
    ShaderPrecision medium_int;
    ShaderPrecision high_int;
    ShaderPrecision low_float;
    ShaderPrecision medium_float;
    ShaderPrecision high_float;
  };

  Capabilities();

  template <typename T>
  void VisitStagePrecisions(unsigned stage,
                            PerStagePrecisions* precisions,
                            const T& visitor) {
    visitor(stage, GL_LOW_INT, &precisions->low_int);
    visitor(stage, GL_MEDIUM_INT, &precisions->medium_int);
    visitor(stage, GL_HIGH_INT, &precisions->high_int);
    visitor(stage, GL_LOW_FLOAT, &precisions->low_float);
    visitor(stage, GL_MEDIUM_FLOAT, &precisions->medium_float);
    visitor(stage, GL_HIGH_FLOAT, &precisions->high_float);
  }

  template <typename T>
  void VisitPrecisions(const T& visitor) {
    VisitStagePrecisions(GL_VERTEX_SHADER, &vertex_shader_precisions, visitor);
    VisitStagePrecisions(GL_FRAGMENT_SHADER, &fragment_shader_precisions,
                         visitor);
  }

  PerStagePrecisions vertex_shader_precisions;
  PerStagePrecisions fragment_shader_precisions;
  int max_combined_texture_image_units;
  int max_cube_map_texture_size;
  int max_fragment_uniform_vectors;
  int max_renderbuffer_size;
  int max_texture_image_units;
  int max_texture_size;
  int max_varying_vectors;
  int max_vertex_attribs;
  int max_vertex_texture_image_units;
  int max_vertex_uniform_vectors;
  int num_compressed_texture_formats;
  int num_shader_binary_formats;
  int bind_generates_resource_chromium;

  int max_3d_texture_size;
  int max_array_texture_layers;
  int max_color_attachments;
  int max_combined_fragment_uniform_components;
  int max_combined_uniform_blocks;
  int max_combined_vertex_uniform_components;
  int max_draw_buffers;
  int max_element_index;
  int max_elements_indices;
  int max_elements_vertices;
  int max_fragment_input_components;
  int max_fragment_uniform_blocks;
  int max_fragment_uniform_components;
  int max_program_texel_offset;
  int max_samples;
  int max_server_wait_timeout;
  int max_transform_feedback_interleaved_components;
  int max_transform_feedback_separate_attribs;
  int max_transform_feedback_separate_components;
  int max_uniform_block_size;
  int max_uniform_buffer_bindings;
  int max_varying_components;
  int max_vertex_output_components;
  int max_vertex_uniform_blocks;
  int max_vertex_uniform_components;
  int min_program_texel_offset;
  int num_extensions;
  int num_program_binary_formats;
  int uniform_buffer_offset_alignment;

  bool post_sub_buffer;
  bool egl_image_external;
  bool texture_format_atc;
  bool texture_format_bgra8888;
  bool texture_format_dxt1;
  bool texture_format_dxt5;
  bool texture_format_etc1;
  bool texture_format_etc1_npot;
  bool texture_rectangle;
  bool iosurface;
  bool texture_usage;
  bool texture_storage;
  bool discard_framebuffer;
  bool sync_query;
  bool image;
  bool future_sync_points;
  bool blend_equation_advanced;
  bool blend_equation_advanced_coherent;
  bool texture_rg;

  int major_version;
  int minor_version;
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_CAPABILITIES_H_
