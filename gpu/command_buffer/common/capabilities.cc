// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/capabilities.h"

namespace gpu {

Capabilities::PerStagePrecisions::PerStagePrecisions() {
}

Capabilities::Capabilities()
    : max_combined_texture_image_units(0),
      max_cube_map_texture_size(0),
      max_fragment_uniform_vectors(0),
      max_renderbuffer_size(0),
      max_texture_image_units(0),
      max_texture_size(0),
      max_varying_vectors(0),
      max_vertex_attribs(0),
      max_vertex_texture_image_units(0),
      max_vertex_uniform_vectors(0),
      num_compressed_texture_formats(0),
      num_shader_binary_formats(0),
      bind_generates_resource_chromium(0),
      max_3d_texture_size(0),
      max_array_texture_layers(0),
      max_color_attachments(0),
      max_combined_fragment_uniform_components(0),
      max_combined_uniform_blocks(0),
      max_combined_vertex_uniform_components(0),
      max_draw_buffers(0),
      max_element_index(0),
      max_elements_indices(0),
      max_elements_vertices(0),
      max_fragment_input_components(0),
      max_fragment_uniform_blocks(0),
      max_fragment_uniform_components(0),
      max_program_texel_offset(0),
      max_samples(0),
      max_server_wait_timeout(0),
      max_transform_feedback_interleaved_components(0),
      max_transform_feedback_separate_attribs(0),
      max_transform_feedback_separate_components(0),
      max_uniform_block_size(0),
      max_uniform_buffer_bindings(0),
      max_varying_components(0),
      max_vertex_output_components(0),
      max_vertex_uniform_blocks(0),
      max_vertex_uniform_components(0),
      min_program_texel_offset(0),
      num_extensions(0),
      num_program_binary_formats(0),
      uniform_buffer_offset_alignment(1),
      post_sub_buffer(false),
      egl_image_external(false),
      texture_format_atc(false),
      texture_format_bgra8888(false),
      texture_format_dxt1(false),
      texture_format_dxt5(false),
      texture_format_etc1(false),
      texture_format_etc1_npot(false),
      texture_rectangle(false),
      iosurface(false),
      texture_usage(false),
      texture_storage(false),
      discard_framebuffer(false),
      sync_query(false),
      image(false),
      future_sync_points(false),
      blend_equation_advanced(false),
      blend_equation_advanced_coherent(false),
      texture_rg(false),
      major_version(2),
      minor_version(0) {
}

}  // namespace gpu
