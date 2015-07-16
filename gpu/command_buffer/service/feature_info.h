// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_FEATURE_INFO_H_
#define GPU_COMMAND_BUFFER_SERVICE_FEATURE_INFO_H_

#include <set>
#include <string>
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/sys_info.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gles2_cmd_validation.h"
#include "gpu/config/gpu_driver_bug_workaround_type.h"
#include "gpu/gpu_export.h"
#include "ui/gl/gl_version_info.h"

namespace base {
class CommandLine;
}

namespace gpu {
namespace gles2 {

// FeatureInfo records the features that are available for a ContextGroup.
class GPU_EXPORT FeatureInfo : public base::RefCounted<FeatureInfo> {
 public:
  struct FeatureFlags {
    FeatureFlags();

    bool chromium_color_buffer_float_rgba;
    bool chromium_color_buffer_float_rgb;
    bool chromium_framebuffer_multisample;
    bool chromium_sync_query;
    // Use glBlitFramebuffer() and glRenderbufferStorageMultisample() with
    // GL_EXT_framebuffer_multisample-style semantics, since they are exposed
    // as core GL functions on this implementation.
    bool use_core_framebuffer_multisample;
    bool multisampled_render_to_texture;
    // Use the IMG GLenum values and functions rather than EXT.
    bool use_img_for_multisampled_render_to_texture;
    bool oes_standard_derivatives;
    bool oes_egl_image_external;
    bool oes_depth24;
    bool oes_compressed_etc1_rgb8_texture;
    bool packed_depth24_stencil8;
    bool npot_ok;
    bool enable_texture_float_linear;
    bool enable_texture_half_float_linear;
    bool angle_translated_shader_source;
    bool angle_pack_reverse_row_order;
    bool arb_texture_rectangle;
    bool angle_instanced_arrays;
    bool occlusion_query_boolean;
    bool use_arb_occlusion_query2_for_occlusion_query_boolean;
    bool use_arb_occlusion_query_for_occlusion_query_boolean;
    bool native_vertex_array_object;
    bool ext_texture_format_atc;
    bool ext_texture_format_bgra8888;
    bool ext_texture_format_dxt1;
    bool ext_texture_format_dxt5;
    bool enable_shader_name_hashing;
    bool enable_samplers;
    bool ext_draw_buffers;
    bool nv_draw_buffers;
    bool ext_frag_depth;
    bool ext_shader_texture_lod;
    bool use_async_readpixels;
    bool map_buffer_range;
    bool ext_discard_framebuffer;
    bool angle_depth_texture;
    bool is_swiftshader;
    bool angle_texture_usage;
    bool ext_texture_storage;
    bool chromium_path_rendering;
    bool blend_equation_advanced;
    bool blend_equation_advanced_coherent;
    bool ext_texture_rg;
    bool enable_subscribe_uniform;
    bool emulate_primitive_restart_fixed_index;
  };

  struct Workarounds {
    Workarounds();

#define GPU_OP(type, name) bool name;
    GPU_DRIVER_BUG_WORKAROUNDS(GPU_OP)
#undef GPU_OP

    // Note: 0 here means use driver limit.
    GLint max_texture_size;
    GLint max_cube_map_texture_size;
    GLint max_fragment_uniform_vectors;
    GLint max_varying_vectors;
    GLint max_vertex_uniform_vectors;
  };

  // Constructor with workarounds taken from the current process's CommandLine
  FeatureInfo();

  // Constructor with workarounds taken from |command_line|
  FeatureInfo(const base::CommandLine& command_line);

  // Initializes the feature information. Needs a current GL context.
  bool Initialize();
  bool Initialize(const DisallowedFeatures& disallowed_features);

  const Validators* validators() const {
    return &validators_;
  }

  const ValueValidator<GLenum>& GetTextureFormatValidator(GLenum format) {
    return texture_format_validators_[format];
  }

  const std::string& extensions() const {
    return extensions_;
  }

  const FeatureFlags& feature_flags() const {
    return feature_flags_;
  }

  const Workarounds& workarounds() const {
    return workarounds_;
  }

  const gfx::GLVersionInfo& gl_version_info() const {
    DCHECK(gl_version_info_.get());
    return *(gl_version_info_.get());
  }

  bool IsES3Capable() const;
  void EnableES3Validators();

 private:
  friend class base::RefCounted<FeatureInfo>;
  friend class BufferManagerClientSideArraysTest;

  typedef base::hash_map<GLenum, ValueValidator<GLenum> > ValidatorMap;
  ValidatorMap texture_format_validators_;

  ~FeatureInfo();

  void AddExtensionString(const char* s);
  void InitializeBasicState(const base::CommandLine& command_line);
  void InitializeFeatures();

  Validators validators_;

  DisallowedFeatures disallowed_features_;

  // The extensions string returned by glGetString(GL_EXTENSIONS);
  std::string extensions_;

  // Flags for some features
  FeatureFlags feature_flags_;

  // Flags for Workarounds.
  Workarounds workarounds_;

  scoped_ptr<gfx::GLVersionInfo> gl_version_info_;

  DISALLOW_COPY_AND_ASSIGN(FeatureInfo);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_FEATURE_INFO_H_
