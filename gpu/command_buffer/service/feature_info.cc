// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/feature_info.h"

#include <set>

#include "base/command_line.h"
#include "base/macros.h"
#include "base/metrics/histogram.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/config/gpu_switches.h"
#include "ui/gl/gl_fence.h"
#include "ui/gl/gl_implementation.h"

#if !defined(OS_MACOSX)
#include "ui/gl/gl_fence_egl.h"
#endif

namespace gpu {
namespace gles2 {

namespace {

struct FormatInfo {
  GLenum format;
  const GLenum* types;
  size_t count;
};

class StringSet {
 public:
  StringSet() {}

  StringSet(const char* s) {
    Init(s);
  }

  StringSet(const std::string& str) {
    Init(str);
  }

  void Init(const char* s) {
    std::string str(s ? s : "");
    Init(str);
  }

  void Init(const std::string& str) {
    std::vector<std::string> tokens;
    Tokenize(str, " ", &tokens);
    string_set_.insert(tokens.begin(), tokens.end());
  }

  bool Contains(const char* s) {
    return string_set_.find(s) != string_set_.end();
  }

  bool Contains(const std::string& s) {
    return string_set_.find(s) != string_set_.end();
  }

 private:
  std::set<std::string> string_set_;
};

// Process a string of wordaround type IDs (seperated by ',') and set up
// the corresponding Workaround flags.
void StringToWorkarounds(
    const std::string& types, FeatureInfo::Workarounds* workarounds) {
  DCHECK(workarounds);
  std::vector<std::string> pieces;
  base::SplitString(types, ',', &pieces);
  for (size_t i = 0; i < pieces.size(); ++i) {
    int number = 0;
    bool succeed = base::StringToInt(pieces[i], &number);
    DCHECK(succeed);
    switch (number) {
#define GPU_OP(type, name)    \
  case gpu::type:             \
    workarounds->name = true; \
    break;
      GPU_DRIVER_BUG_WORKAROUNDS(GPU_OP)
#undef GPU_OP
      default:
        NOTIMPLEMENTED();
    }
  }
  if (workarounds->max_texture_size_limit_4096)
    workarounds->max_texture_size = 4096;
  if (workarounds->max_cube_map_texture_size_limit_4096)
    workarounds->max_cube_map_texture_size = 4096;
  if (workarounds->max_cube_map_texture_size_limit_1024)
    workarounds->max_cube_map_texture_size = 1024;
  if (workarounds->max_cube_map_texture_size_limit_512)
    workarounds->max_cube_map_texture_size = 512;

  if (workarounds->max_fragment_uniform_vectors_32)
    workarounds->max_fragment_uniform_vectors = 32;
  if (workarounds->max_varying_vectors_16)
    workarounds->max_varying_vectors = 16;
  if (workarounds->max_vertex_uniform_vectors_256)
    workarounds->max_vertex_uniform_vectors = 256;
}

}  // anonymous namespace.

FeatureInfo::FeatureFlags::FeatureFlags()
    : chromium_color_buffer_float_rgba(false),
      chromium_color_buffer_float_rgb(false),
      chromium_framebuffer_multisample(false),
      chromium_sync_query(false),
      use_core_framebuffer_multisample(false),
      multisampled_render_to_texture(false),
      use_img_for_multisampled_render_to_texture(false),
      oes_standard_derivatives(false),
      oes_egl_image_external(false),
      oes_depth24(false),
      oes_compressed_etc1_rgb8_texture(false),
      packed_depth24_stencil8(false),
      npot_ok(false),
      enable_texture_float_linear(false),
      enable_texture_half_float_linear(false),
      angle_translated_shader_source(false),
      angle_pack_reverse_row_order(false),
      arb_texture_rectangle(false),
      angle_instanced_arrays(false),
      occlusion_query_boolean(false),
      use_arb_occlusion_query2_for_occlusion_query_boolean(false),
      use_arb_occlusion_query_for_occlusion_query_boolean(false),
      native_vertex_array_object(false),
      ext_texture_format_atc(false),
      ext_texture_format_bgra8888(false),
      ext_texture_format_dxt1(false),
      ext_texture_format_dxt5(false),
      enable_shader_name_hashing(false),
      enable_samplers(false),
      ext_draw_buffers(false),
      nv_draw_buffers(false),
      ext_frag_depth(false),
      ext_shader_texture_lod(false),
      use_async_readpixels(false),
      map_buffer_range(false),
      ext_discard_framebuffer(false),
      angle_depth_texture(false),
      is_swiftshader(false),
      angle_texture_usage(false),
      ext_texture_storage(false),
      chromium_path_rendering(false),
      blend_equation_advanced(false),
      blend_equation_advanced_coherent(false),
      ext_texture_rg(false),
      enable_subscribe_uniform(false),
      emulate_primitive_restart_fixed_index(false) {
}

FeatureInfo::Workarounds::Workarounds() :
#define GPU_OP(type, name) name(false),
    GPU_DRIVER_BUG_WORKAROUNDS(GPU_OP)
#undef GPU_OP
    max_texture_size(0),
    max_cube_map_texture_size(0),
    max_fragment_uniform_vectors(0),
    max_varying_vectors(0),
    max_vertex_uniform_vectors(0) {
}

FeatureInfo::FeatureInfo() {
  InitializeBasicState(*base::CommandLine::ForCurrentProcess());
}

FeatureInfo::FeatureInfo(const base::CommandLine& command_line) {
  InitializeBasicState(command_line);
}

void FeatureInfo::InitializeBasicState(const base::CommandLine& command_line) {
  if (command_line.HasSwitch(switches::kGpuDriverBugWorkarounds)) {
    std::string types = command_line.GetSwitchValueASCII(
        switches::kGpuDriverBugWorkarounds);
    StringToWorkarounds(types, &workarounds_);
  }
  feature_flags_.enable_shader_name_hashing =
      !command_line.HasSwitch(switches::kDisableShaderNameHashing);

  feature_flags_.is_swiftshader =
      (command_line.GetSwitchValueASCII(switches::kUseGL) == "swiftshader");

  feature_flags_.enable_subscribe_uniform =
      command_line.HasSwitch(switches::kEnableSubscribeUniformExtension);

  static const GLenum kAlphaTypes[] = {
      GL_UNSIGNED_BYTE,
  };
  static const GLenum kRGBTypes[] = {
      GL_UNSIGNED_BYTE,
      GL_UNSIGNED_SHORT_5_6_5,
  };
  static const GLenum kRGBATypes[] = {
      GL_UNSIGNED_BYTE,
      GL_UNSIGNED_SHORT_4_4_4_4,
      GL_UNSIGNED_SHORT_5_5_5_1,
  };
  static const GLenum kLuminanceTypes[] = {
      GL_UNSIGNED_BYTE,
  };
  static const GLenum kLuminanceAlphaTypes[] = {
      GL_UNSIGNED_BYTE,
  };
  static const FormatInfo kFormatTypes[] = {
    { GL_ALPHA, kAlphaTypes, arraysize(kAlphaTypes), },
    { GL_RGB, kRGBTypes, arraysize(kRGBTypes), },
    { GL_RGBA, kRGBATypes, arraysize(kRGBATypes), },
    { GL_LUMINANCE, kLuminanceTypes, arraysize(kLuminanceTypes), },
    { GL_LUMINANCE_ALPHA, kLuminanceAlphaTypes,
      arraysize(kLuminanceAlphaTypes), } ,
  };
  for (size_t ii = 0; ii < arraysize(kFormatTypes); ++ii) {
    const FormatInfo& info = kFormatTypes[ii];
    ValueValidator<GLenum>& validator = texture_format_validators_[info.format];
    for (size_t jj = 0; jj < info.count; ++jj) {
      validator.AddValue(info.types[jj]);
    }
  }
}

bool FeatureInfo::Initialize() {
  disallowed_features_ = DisallowedFeatures();
  InitializeFeatures();
  return true;
}

bool FeatureInfo::Initialize(const DisallowedFeatures& disallowed_features) {
  disallowed_features_ = disallowed_features;
  InitializeFeatures();
  return true;
}

bool IsGL_REDSupportedOnFBOs() {
  // Skia uses GL_RED with frame buffers, unfortunately, Mesa claims to support
  // GL_EXT_texture_rg, but it doesn't support it on frame buffers.  To fix
  // this, we try it, and if it fails, we don't expose GL_EXT_texture_rg.
  GLint fb_binding = 0;
  GLint tex_binding = 0;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fb_binding);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &tex_binding);

  GLuint textureId = 0;
  glGenTextures(1, &textureId);
  glBindTexture(GL_TEXTURE_2D, textureId);
  GLubyte data[1] = {0};
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, 1, 1, 0, GL_RED_EXT,
               GL_UNSIGNED_BYTE, data);
  GLuint textureFBOID = 0;
  glGenFramebuffersEXT(1, &textureFBOID);
  glBindFramebufferEXT(GL_FRAMEBUFFER, textureFBOID);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                            textureId, 0);
  bool result =
      glCheckFramebufferStatusEXT(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_UNSUPPORTED;
  glDeleteFramebuffersEXT(1, &textureFBOID);
  glDeleteTextures(1, &textureId);

  glBindFramebufferEXT(GL_FRAMEBUFFER, static_cast<GLuint>(fb_binding));
  glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(tex_binding));

  DCHECK(glGetError() == GL_NO_ERROR);

  return result;
}

void FeatureInfo::InitializeFeatures() {
  // Figure out what extensions to turn on.
  StringSet extensions(
      reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS)));

  const char* renderer_str =
      reinterpret_cast<const char*>(glGetString(GL_RENDERER));
  const char* version_str =
      reinterpret_cast<const char*>(glGetString(GL_VERSION));

  gl_version_info_.reset(new gfx::GLVersionInfo(version_str, renderer_str));

  AddExtensionString("GL_ANGLE_translated_shader_source");
  AddExtensionString("GL_CHROMIUM_async_pixel_transfers");
  AddExtensionString("GL_CHROMIUM_bind_uniform_location");
  AddExtensionString("GL_CHROMIUM_command_buffer_query");
  AddExtensionString("GL_CHROMIUM_command_buffer_latency_query");
  AddExtensionString("GL_CHROMIUM_copy_texture");
  AddExtensionString("GL_CHROMIUM_get_error_query");
  AddExtensionString("GL_CHROMIUM_lose_context");
  AddExtensionString("GL_CHROMIUM_pixel_transfer_buffer_object");
  AddExtensionString("GL_CHROMIUM_rate_limit_offscreen_context");
  AddExtensionString("GL_CHROMIUM_resize");
  AddExtensionString("GL_CHROMIUM_resource_safe");
  AddExtensionString("GL_CHROMIUM_strict_attribs");
  AddExtensionString("GL_CHROMIUM_texture_mailbox");
  AddExtensionString("GL_CHROMIUM_trace_marker");
  AddExtensionString("GL_EXT_debug_marker");

  if (feature_flags_.enable_subscribe_uniform) {
    AddExtensionString("GL_CHROMIUM_subscribe_uniform");
  }

  // OES_vertex_array_object is emulated if not present natively,
  // so the extension string is always exposed.
  AddExtensionString("GL_OES_vertex_array_object");

  if (!disallowed_features_.gpu_memory_manager)
    AddExtensionString("GL_CHROMIUM_gpu_memory_manager");

  if (extensions.Contains("GL_ANGLE_translated_shader_source")) {
    feature_flags_.angle_translated_shader_source = true;
  }

  // Check if we should allow GL_EXT_texture_compression_dxt1 and
  // GL_EXT_texture_compression_s3tc.
  bool enable_dxt1 = false;
  bool enable_dxt3 = false;
  bool enable_dxt5 = false;
  bool have_s3tc = extensions.Contains("GL_EXT_texture_compression_s3tc");
  bool have_dxt3 =
      have_s3tc || extensions.Contains("GL_ANGLE_texture_compression_dxt3");
  bool have_dxt5 =
      have_s3tc || extensions.Contains("GL_ANGLE_texture_compression_dxt5");

  if (extensions.Contains("GL_EXT_texture_compression_dxt1") || have_s3tc) {
    enable_dxt1 = true;
  }
  if (have_dxt3) {
    enable_dxt3 = true;
  }
  if (have_dxt5) {
    enable_dxt5 = true;
  }

  if (enable_dxt1) {
    feature_flags_.ext_texture_format_dxt1 = true;

    AddExtensionString("GL_EXT_texture_compression_dxt1");
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGB_S3TC_DXT1_EXT);
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGBA_S3TC_DXT1_EXT);
  }

  if (enable_dxt3) {
    // The difference between GL_EXT_texture_compression_s3tc and
    // GL_CHROMIUM_texture_compression_dxt3 is that the former
    // requires on the fly compression. The latter does not.
    AddExtensionString("GL_CHROMIUM_texture_compression_dxt3");
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGBA_S3TC_DXT3_EXT);
  }

  if (enable_dxt5) {
    feature_flags_.ext_texture_format_dxt5 = true;

    // The difference between GL_EXT_texture_compression_s3tc and
    // GL_CHROMIUM_texture_compression_dxt5 is that the former
    // requires on the fly compression. The latter does not.
    AddExtensionString("GL_CHROMIUM_texture_compression_dxt5");
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGBA_S3TC_DXT5_EXT);
  }

  bool have_atc = extensions.Contains("GL_AMD_compressed_ATC_texture") ||
                  extensions.Contains("GL_ATI_texture_compression_atitc");
  if (have_atc) {
    feature_flags_.ext_texture_format_atc = true;

    AddExtensionString("GL_AMD_compressed_ATC_texture");
    validators_.compressed_texture_format.AddValue(GL_ATC_RGB_AMD);
    validators_.compressed_texture_format.AddValue(
        GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD);
  }

  // Check if we should enable GL_EXT_texture_filter_anisotropic.
  if (extensions.Contains("GL_EXT_texture_filter_anisotropic")) {
    AddExtensionString("GL_EXT_texture_filter_anisotropic");
    validators_.texture_parameter.AddValue(
        GL_TEXTURE_MAX_ANISOTROPY_EXT);
    validators_.g_l_state.AddValue(
        GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT);
  }

  // Check if we should support GL_OES_packed_depth_stencil and/or
  // GL_GOOGLE_depth_texture / GL_CHROMIUM_depth_texture.
  //
  // NOTE: GL_OES_depth_texture requires support for depth cubemaps.
  // GL_ARB_depth_texture requires other features that
  // GL_OES_packed_depth_stencil does not provide.
  //
  // Therefore we made up GL_GOOGLE_depth_texture / GL_CHROMIUM_depth_texture.
  //
  // GL_GOOGLE_depth_texture is legacy. As we exposed it into NaCl we can't
  // get rid of it.
  //
  bool enable_depth_texture = false;
  if (!workarounds_.disable_depth_texture &&
      (extensions.Contains("GL_ARB_depth_texture") ||
       extensions.Contains("GL_OES_depth_texture") ||
       extensions.Contains("GL_ANGLE_depth_texture") ||
       gl_version_info_->is_es3)) {
    enable_depth_texture = true;
    feature_flags_.angle_depth_texture =
        extensions.Contains("GL_ANGLE_depth_texture");
  }

  if (enable_depth_texture) {
    AddExtensionString("GL_CHROMIUM_depth_texture");
    AddExtensionString("GL_GOOGLE_depth_texture");
    texture_format_validators_[GL_DEPTH_COMPONENT].AddValue(GL_UNSIGNED_SHORT);
    texture_format_validators_[GL_DEPTH_COMPONENT].AddValue(GL_UNSIGNED_INT);
    validators_.texture_internal_format.AddValue(GL_DEPTH_COMPONENT);
    validators_.texture_format.AddValue(GL_DEPTH_COMPONENT);
    validators_.pixel_type.AddValue(GL_UNSIGNED_SHORT);
    validators_.pixel_type.AddValue(GL_UNSIGNED_INT);
  }

  if (extensions.Contains("GL_EXT_packed_depth_stencil") ||
      extensions.Contains("GL_OES_packed_depth_stencil") ||
      gl_version_info_->is_es3) {
    AddExtensionString("GL_OES_packed_depth_stencil");
    feature_flags_.packed_depth24_stencil8 = true;
    if (enable_depth_texture) {
      texture_format_validators_[GL_DEPTH_STENCIL]
          .AddValue(GL_UNSIGNED_INT_24_8);
      validators_.texture_internal_format.AddValue(GL_DEPTH_STENCIL);
      validators_.texture_format.AddValue(GL_DEPTH_STENCIL);
      validators_.pixel_type.AddValue(GL_UNSIGNED_INT_24_8);
    }
    validators_.render_buffer_format.AddValue(GL_DEPTH24_STENCIL8);
  }

  if (gl_version_info_->is_es3 ||
      extensions.Contains("GL_OES_vertex_array_object") ||
      extensions.Contains("GL_ARB_vertex_array_object") ||
      extensions.Contains("GL_APPLE_vertex_array_object")) {
    feature_flags_.native_vertex_array_object = true;
  }

  // If we're using client_side_arrays we have to emulate
  // vertex array objects since vertex array objects do not work
  // with client side arrays.
  if (workarounds_.use_client_side_arrays_for_stream_buffers) {
    feature_flags_.native_vertex_array_object = false;
  }

  if (gl_version_info_->is_es3 ||
      extensions.Contains("GL_OES_element_index_uint") ||
      gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_OES_element_index_uint");
    validators_.index_type.AddValue(GL_UNSIGNED_INT);
  }

  // With EXT_sRGB, unsized SRGB_EXT and SRGB_ALPHA_EXT are accepted by the
  // <format> and <internalformat> parameter of TexImage2D. GLES3 adds support
  // for SRGB Textures but the accepted internal formats for TexImage2D are only
  // sized formats GL_SRGB8 and GL_SRGB8_ALPHA8. Also, SRGB_EXT isn't a valid
  // <format> in this case. So, even with GLES3 explicitly check for
  // GL_EXT_sRGB.
  if (((gl_version_info_->is_es3 ||
        extensions.Contains("GL_OES_rgb8_rgba8")) &&
      extensions.Contains("GL_EXT_sRGB")) || gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_EXT_sRGB");
    texture_format_validators_[GL_SRGB_EXT].AddValue(GL_UNSIGNED_BYTE);
    texture_format_validators_[GL_SRGB_ALPHA_EXT].AddValue(GL_UNSIGNED_BYTE);
    validators_.texture_internal_format.AddValue(GL_SRGB_EXT);
    validators_.texture_internal_format.AddValue(GL_SRGB_ALPHA_EXT);
    validators_.texture_format.AddValue(GL_SRGB_EXT);
    validators_.texture_format.AddValue(GL_SRGB_ALPHA_EXT);
    validators_.render_buffer_format.AddValue(GL_SRGB8_ALPHA8_EXT);
    validators_.frame_buffer_parameter.AddValue(
        GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT);
  }

  bool enable_texture_format_bgra8888 = false;
  bool enable_read_format_bgra = false;
  bool enable_render_buffer_bgra = false;
  bool enable_immutable_texture_format_bgra_on_es3 =
      extensions.Contains("GL_APPLE_texture_format_BGRA8888");

  // Check if we should allow GL_EXT_texture_format_BGRA8888
  if (extensions.Contains("GL_EXT_texture_format_BGRA8888") ||
      enable_immutable_texture_format_bgra_on_es3 ||
      extensions.Contains("GL_EXT_bgra")) {
    enable_texture_format_bgra8888 = true;
  }

  // Only desktop GL extension GL_EXT_bgra or ANGLE guarantee that we can
  // allocate a renderbuffer with this format.
  if (extensions.Contains("GL_EXT_bgra") || gl_version_info_->is_angle) {
    enable_render_buffer_bgra = true;
  }

  if (extensions.Contains("GL_EXT_read_format_bgra") ||
      extensions.Contains("GL_EXT_bgra")) {
    enable_read_format_bgra = true;
  }

  if (enable_texture_format_bgra8888) {
    feature_flags_.ext_texture_format_bgra8888 = true;
    AddExtensionString("GL_EXT_texture_format_BGRA8888");
    texture_format_validators_[GL_BGRA_EXT].AddValue(GL_UNSIGNED_BYTE);
    validators_.texture_internal_format.AddValue(GL_BGRA_EXT);
    validators_.texture_format.AddValue(GL_BGRA_EXT);
  }

  if (enable_read_format_bgra) {
    AddExtensionString("GL_EXT_read_format_bgra");
    validators_.read_pixel_format.AddValue(GL_BGRA_EXT);
  }

  if (enable_render_buffer_bgra) {
    AddExtensionString("GL_CHROMIUM_renderbuffer_format_BGRA8888");
    validators_.render_buffer_format.AddValue(GL_BGRA8_EXT);
  }

  if (extensions.Contains("GL_OES_rgb8_rgba8") || gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_OES_rgb8_rgba8");
    validators_.render_buffer_format.AddValue(GL_RGB8_OES);
    validators_.render_buffer_format.AddValue(GL_RGBA8_OES);
  }

  // Check if we should allow GL_OES_texture_npot
  if (gl_version_info_->is_es3 ||
      extensions.Contains("GL_ARB_texture_non_power_of_two") ||
      extensions.Contains("GL_OES_texture_npot")) {
    AddExtensionString("GL_OES_texture_npot");
    feature_flags_.npot_ok = true;
  }

  // Check if we should allow GL_OES_texture_float, GL_OES_texture_half_float,
  // GL_OES_texture_float_linear, GL_OES_texture_half_float_linear
  bool enable_texture_float = false;
  bool enable_texture_float_linear = false;
  bool enable_texture_half_float = false;
  bool enable_texture_half_float_linear = false;

  bool may_enable_chromium_color_buffer_float = false;

  if (extensions.Contains("GL_ARB_texture_float")) {
    enable_texture_float = true;
    enable_texture_float_linear = true;
    enable_texture_half_float = true;
    enable_texture_half_float_linear = true;
    may_enable_chromium_color_buffer_float = true;
  } else {
    // GLES3 adds support for Float type by default but it doesn't support all
    // formats as GL_OES_texture_float(i.e.LUMINANCE_ALPHA,LUMINANCE and Alpha)
    if (extensions.Contains("GL_OES_texture_float")) {
      enable_texture_float = true;
      if (extensions.Contains("GL_OES_texture_float_linear")) {
        enable_texture_float_linear = true;
      }
      // This extension allows a variety of floating point formats to be
      // rendered to via framebuffer objects. Enable it's usage only if
      // support for Floating textures is enabled.
      if ((gl_version_info_->is_es3 &&
           extensions.Contains("GL_EXT_color_buffer_float")) ||
          gl_version_info_->is_angle) {
        may_enable_chromium_color_buffer_float = true;
      }
    }

    // TODO(dshwang): GLES3 supports half float by default but GL_HALF_FLOAT_OES
    // isn't equal to GL_HALF_FLOAT.
    if (extensions.Contains("GL_OES_texture_half_float")) {
      enable_texture_half_float = true;
      if (extensions.Contains("GL_OES_texture_half_float_linear")) {
        enable_texture_half_float_linear = true;
      }
    }
  }

  if (enable_texture_float) {
    texture_format_validators_[GL_ALPHA].AddValue(GL_FLOAT);
    texture_format_validators_[GL_RGB].AddValue(GL_FLOAT);
    texture_format_validators_[GL_RGBA].AddValue(GL_FLOAT);
    texture_format_validators_[GL_LUMINANCE].AddValue(GL_FLOAT);
    texture_format_validators_[GL_LUMINANCE_ALPHA].AddValue(GL_FLOAT);
    validators_.pixel_type.AddValue(GL_FLOAT);
    validators_.read_pixel_type.AddValue(GL_FLOAT);
    AddExtensionString("GL_OES_texture_float");
    if (enable_texture_float_linear) {
      AddExtensionString("GL_OES_texture_float_linear");
    }
  }

  if (enable_texture_half_float) {
    texture_format_validators_[GL_ALPHA].AddValue(GL_HALF_FLOAT_OES);
    texture_format_validators_[GL_RGB].AddValue(GL_HALF_FLOAT_OES);
    texture_format_validators_[GL_RGBA].AddValue(GL_HALF_FLOAT_OES);
    texture_format_validators_[GL_LUMINANCE].AddValue(GL_HALF_FLOAT_OES);
    texture_format_validators_[GL_LUMINANCE_ALPHA].AddValue(GL_HALF_FLOAT_OES);
    validators_.pixel_type.AddValue(GL_HALF_FLOAT_OES);
    validators_.read_pixel_type.AddValue(GL_HALF_FLOAT_OES);
    AddExtensionString("GL_OES_texture_half_float");
    if (enable_texture_half_float_linear) {
      AddExtensionString("GL_OES_texture_half_float_linear");
    }
  }

  if (may_enable_chromium_color_buffer_float) {
    static_assert(GL_RGBA32F_ARB == GL_RGBA32F &&
                  GL_RGBA32F_EXT == GL_RGBA32F &&
                  GL_RGB32F_ARB == GL_RGB32F &&
                  GL_RGB32F_EXT == GL_RGB32F,
                  "sized float internal format variations must match");
    // We don't check extension support beyond ARB_texture_float on desktop GL,
    // and format support varies between GL configurations. For example, spec
    // prior to OpenGL 3.0 mandates framebuffer support only for one
    // implementation-chosen format, and ES3.0 EXT_color_buffer_float does not
    // support rendering to RGB32F. Check for framebuffer completeness with
    // formats that the extensions expose, and only enable an extension when a
    // framebuffer created with its texture format is reported as complete.
    GLint fb_binding = 0;
    GLint tex_binding = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fb_binding);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &tex_binding);

    GLuint tex_id = 0;
    GLuint fb_id = 0;
    GLsizei width = 16;

    glGenTextures(1, &tex_id);
    glGenFramebuffersEXT(1, &fb_id);
    glBindTexture(GL_TEXTURE_2D, tex_id);
    // Nearest filter needed for framebuffer completeness on some drivers.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, width, 0, GL_RGBA,
                 GL_FLOAT, NULL);
    glBindFramebufferEXT(GL_FRAMEBUFFER, fb_id);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_TEXTURE_2D, tex_id, 0);
    GLenum statusRGBA = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, width, 0, GL_RGB,
                 GL_FLOAT, NULL);
    GLenum statusRGB = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER);
    glDeleteFramebuffersEXT(1, &fb_id);
    glDeleteTextures(1, &tex_id);

    glBindFramebufferEXT(GL_FRAMEBUFFER, static_cast<GLuint>(fb_binding));
    glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(tex_binding));

    DCHECK(glGetError() == GL_NO_ERROR);

    if (statusRGBA == GL_FRAMEBUFFER_COMPLETE) {
      validators_.texture_internal_format.AddValue(GL_RGBA32F);
      feature_flags_.chromium_color_buffer_float_rgba = true;
      AddExtensionString("GL_CHROMIUM_color_buffer_float_rgba");
    }
    if (statusRGB == GL_FRAMEBUFFER_COMPLETE) {
      validators_.texture_internal_format.AddValue(GL_RGB32F);
      feature_flags_.chromium_color_buffer_float_rgb = true;
      AddExtensionString("GL_CHROMIUM_color_buffer_float_rgb");
    }
  }

  // Check for multisample support
  if (!workarounds_.disable_multisampling) {
    bool ext_has_multisample =
        extensions.Contains("GL_EXT_framebuffer_multisample") ||
        gl_version_info_->is_es3;
    if (gl_version_info_->is_angle) {
      ext_has_multisample |=
          extensions.Contains("GL_ANGLE_framebuffer_multisample");
    }
    feature_flags_.use_core_framebuffer_multisample = gl_version_info_->is_es3;
    if (ext_has_multisample) {
      feature_flags_.chromium_framebuffer_multisample = true;
      validators_.frame_buffer_target.AddValue(GL_READ_FRAMEBUFFER_EXT);
      validators_.frame_buffer_target.AddValue(GL_DRAW_FRAMEBUFFER_EXT);
      validators_.g_l_state.AddValue(GL_READ_FRAMEBUFFER_BINDING_EXT);
      validators_.g_l_state.AddValue(GL_MAX_SAMPLES_EXT);
      validators_.render_buffer_parameter.AddValue(GL_RENDERBUFFER_SAMPLES_EXT);
      AddExtensionString("GL_CHROMIUM_framebuffer_multisample");
    }
    if (extensions.Contains("GL_EXT_multisampled_render_to_texture")) {
      feature_flags_.multisampled_render_to_texture = true;
    } else if (extensions.Contains("GL_IMG_multisampled_render_to_texture")) {
      feature_flags_.multisampled_render_to_texture = true;
      feature_flags_.use_img_for_multisampled_render_to_texture = true;
    }
    if (feature_flags_.multisampled_render_to_texture) {
      validators_.render_buffer_parameter.AddValue(
          GL_RENDERBUFFER_SAMPLES_EXT);
      validators_.g_l_state.AddValue(GL_MAX_SAMPLES_EXT);
      validators_.frame_buffer_parameter.AddValue(
          GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT);
      AddExtensionString("GL_EXT_multisampled_render_to_texture");
    }
  }

  if (extensions.Contains("GL_OES_depth24") || gfx::HasDesktopGLFeatures() ||
      gl_version_info_->is_es3) {
    AddExtensionString("GL_OES_depth24");
    feature_flags_.oes_depth24 = true;
    validators_.render_buffer_format.AddValue(GL_DEPTH_COMPONENT24);
  }

  if (!workarounds_.disable_oes_standard_derivatives &&
      (gl_version_info_->is_es3 ||
       extensions.Contains("GL_OES_standard_derivatives") ||
       gfx::HasDesktopGLFeatures())) {
    AddExtensionString("GL_OES_standard_derivatives");
    feature_flags_.oes_standard_derivatives = true;
    validators_.hint_target.AddValue(GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES);
    validators_.g_l_state.AddValue(GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES);
  }

  if (extensions.Contains("GL_OES_EGL_image_external")) {
    AddExtensionString("GL_OES_EGL_image_external");
    feature_flags_.oes_egl_image_external = true;
    validators_.texture_bind_target.AddValue(GL_TEXTURE_EXTERNAL_OES);
    validators_.get_tex_param_target.AddValue(GL_TEXTURE_EXTERNAL_OES);
    validators_.texture_parameter.AddValue(GL_REQUIRED_TEXTURE_IMAGE_UNITS_OES);
    validators_.g_l_state.AddValue(GL_TEXTURE_BINDING_EXTERNAL_OES);
  }

  if (extensions.Contains("GL_OES_compressed_ETC1_RGB8_texture")) {
    AddExtensionString("GL_OES_compressed_ETC1_RGB8_texture");
    feature_flags_.oes_compressed_etc1_rgb8_texture = true;
    validators_.compressed_texture_format.AddValue(GL_ETC1_RGB8_OES);
  }

  if (extensions.Contains("GL_AMD_compressed_ATC_texture")) {
    AddExtensionString("GL_AMD_compressed_ATC_texture");
    validators_.compressed_texture_format.AddValue(
        GL_ATC_RGB_AMD);
    validators_.compressed_texture_format.AddValue(
        GL_ATC_RGBA_EXPLICIT_ALPHA_AMD);
    validators_.compressed_texture_format.AddValue(
        GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD);
  }

  if (extensions.Contains("GL_IMG_texture_compression_pvrtc")) {
    AddExtensionString("GL_IMG_texture_compression_pvrtc");
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG);
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG);
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG);
    validators_.compressed_texture_format.AddValue(
        GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG);
  }

  // Ideally we would only expose this extension on Mac OS X, to
  // support GL_CHROMIUM_iosurface and the compositor. We don't want
  // applications to start using it; they should use ordinary non-
  // power-of-two textures. However, for unit testing purposes we
  // expose it on all supported platforms.
  if (extensions.Contains("GL_ARB_texture_rectangle")) {
    AddExtensionString("GL_ARB_texture_rectangle");
    feature_flags_.arb_texture_rectangle = true;
    validators_.texture_bind_target.AddValue(GL_TEXTURE_RECTANGLE_ARB);
    // For the moment we don't add this enum to the texture_target
    // validator. This implies that the only way to get image data into a
    // rectangular texture is via glTexImageIOSurface2DCHROMIUM, which is
    // just fine since again we don't want applications depending on this
    // extension.
    validators_.get_tex_param_target.AddValue(GL_TEXTURE_RECTANGLE_ARB);
    validators_.g_l_state.AddValue(GL_TEXTURE_BINDING_RECTANGLE_ARB);
  }

#if defined(OS_MACOSX)
  AddExtensionString("GL_CHROMIUM_iosurface");
#endif

  // TODO(gman): Add support for these extensions.
  //     GL_OES_depth32

  feature_flags_.enable_texture_float_linear |= enable_texture_float_linear;
  feature_flags_.enable_texture_half_float_linear |=
      enable_texture_half_float_linear;

  if (extensions.Contains("GL_ANGLE_pack_reverse_row_order")) {
    AddExtensionString("GL_ANGLE_pack_reverse_row_order");
    feature_flags_.angle_pack_reverse_row_order = true;
    validators_.pixel_store.AddValue(GL_PACK_REVERSE_ROW_ORDER_ANGLE);
    validators_.g_l_state.AddValue(GL_PACK_REVERSE_ROW_ORDER_ANGLE);
  }

  if (extensions.Contains("GL_ANGLE_texture_usage")) {
    feature_flags_.angle_texture_usage = true;
    AddExtensionString("GL_ANGLE_texture_usage");
    validators_.texture_parameter.AddValue(GL_TEXTURE_USAGE_ANGLE);
  }

  // Note: Only APPLE_texture_format_BGRA8888 extension allows BGRA8_EXT in
  // ES3's glTexStorage2D. We prefer support BGRA to texture storage.
  // So we don't expose GL_EXT_texture_storage when ES3 +
  // GL_EXT_texture_format_BGRA8888 because we fail the GL_BGRA8 requirement.
  // However we expose GL_EXT_texture_storage when just ES3 because we don't
  // claim to handle GL_BGRA8.
  bool support_texture_storage_on_es3 =
      (gl_version_info_->is_es3 &&
       enable_immutable_texture_format_bgra_on_es3) ||
      (gl_version_info_->is_es3 &&
       !enable_texture_format_bgra8888);
  if (extensions.Contains("GL_EXT_texture_storage") ||
      extensions.Contains("GL_ARB_texture_storage") ||
      support_texture_storage_on_es3) {
    feature_flags_.ext_texture_storage = true;
    AddExtensionString("GL_EXT_texture_storage");
    validators_.texture_parameter.AddValue(GL_TEXTURE_IMMUTABLE_FORMAT_EXT);
    if (enable_texture_format_bgra8888)
        validators_.texture_internal_format_storage.AddValue(GL_BGRA8_EXT);
    if (enable_texture_float) {
        validators_.texture_internal_format_storage.AddValue(GL_RGBA32F_EXT);
        validators_.texture_internal_format_storage.AddValue(GL_RGB32F_EXT);
        validators_.texture_internal_format_storage.AddValue(GL_ALPHA32F_EXT);
        validators_.texture_internal_format_storage.AddValue(
            GL_LUMINANCE32F_EXT);
        validators_.texture_internal_format_storage.AddValue(
            GL_LUMINANCE_ALPHA32F_EXT);
    }
    if (enable_texture_half_float) {
        validators_.texture_internal_format_storage.AddValue(GL_RGBA16F_EXT);
        validators_.texture_internal_format_storage.AddValue(GL_RGB16F_EXT);
        validators_.texture_internal_format_storage.AddValue(GL_ALPHA16F_EXT);
        validators_.texture_internal_format_storage.AddValue(
            GL_LUMINANCE16F_EXT);
        validators_.texture_internal_format_storage.AddValue(
            GL_LUMINANCE_ALPHA16F_EXT);
    }
  }

  bool have_ext_occlusion_query_boolean =
      extensions.Contains("GL_EXT_occlusion_query_boolean");
  bool have_arb_occlusion_query2 =
      extensions.Contains("GL_ARB_occlusion_query2");
  bool have_arb_occlusion_query =
      extensions.Contains("GL_ARB_occlusion_query");

  if (!workarounds_.disable_ext_occlusion_query &&
      (have_ext_occlusion_query_boolean ||
       have_arb_occlusion_query2 ||
       have_arb_occlusion_query)) {
    AddExtensionString("GL_EXT_occlusion_query_boolean");
    feature_flags_.occlusion_query_boolean = true;
    feature_flags_.use_arb_occlusion_query2_for_occlusion_query_boolean =
        !have_ext_occlusion_query_boolean && have_arb_occlusion_query2;
    feature_flags_.use_arb_occlusion_query_for_occlusion_query_boolean =
        !have_ext_occlusion_query_boolean && have_arb_occlusion_query &&
        !have_arb_occlusion_query2;
  }

  if (!workarounds_.disable_angle_instanced_arrays &&
      (extensions.Contains("GL_ANGLE_instanced_arrays") ||
       (extensions.Contains("GL_ARB_instanced_arrays") &&
        extensions.Contains("GL_ARB_draw_instanced")) ||
       gl_version_info_->is_es3)) {
    AddExtensionString("GL_ANGLE_instanced_arrays");
    feature_flags_.angle_instanced_arrays = true;
    validators_.vertex_attribute.AddValue(GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE);
  }

  bool vendor_agnostic_draw_buffers =
      extensions.Contains("GL_ARB_draw_buffers") ||
      extensions.Contains("GL_EXT_draw_buffers");
  if (!workarounds_.disable_ext_draw_buffers &&
      (vendor_agnostic_draw_buffers ||
       (extensions.Contains("GL_NV_draw_buffers") &&
        gl_version_info_->is_es3))) {
    AddExtensionString("GL_EXT_draw_buffers");
    feature_flags_.ext_draw_buffers = true;

    // This flag is set to enable emulation of EXT_draw_buffers when we're
    // running on GLES 3.0+, NV_draw_buffers extension is supported and
    // glDrawBuffers from GLES 3.0 core has been bound. It toggles using the
    // NV_draw_buffers extension directive instead of EXT_draw_buffers extension
    // directive in ESSL 100 shaders translated by ANGLE, enabling them to write
    // into multiple gl_FragData values, which is not by default possible in
    // ESSL 100 with core GLES 3.0. For more information, see the
    // NV_draw_buffers specification.
    feature_flags_.nv_draw_buffers = !vendor_agnostic_draw_buffers;

    GLint max_color_attachments = 0;
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS_EXT, &max_color_attachments);
    for (GLenum i = GL_COLOR_ATTACHMENT1_EXT;
         i < static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + max_color_attachments);
         ++i) {
      validators_.attachment.AddValue(i);
    }
    static_assert(GL_COLOR_ATTACHMENT0_EXT == GL_COLOR_ATTACHMENT0,
                  "GL_COLOR_ATTACHMENT0_EXT should equal GL_COLOR_ATTACHMENT0");

    validators_.g_l_state.AddValue(GL_MAX_COLOR_ATTACHMENTS_EXT);
    validators_.g_l_state.AddValue(GL_MAX_DRAW_BUFFERS_ARB);
    GLint max_draw_buffers = 0;
    glGetIntegerv(GL_MAX_DRAW_BUFFERS_ARB, &max_draw_buffers);
    for (GLenum i = GL_DRAW_BUFFER0_ARB;
         i < static_cast<GLenum>(GL_DRAW_BUFFER0_ARB + max_draw_buffers);
         ++i) {
      validators_.g_l_state.AddValue(i);
    }
  }

  if (gl_version_info_->is_es3 ||
      extensions.Contains("GL_EXT_blend_minmax") ||
      gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_EXT_blend_minmax");
    validators_.equation.AddValue(GL_MIN_EXT);
    validators_.equation.AddValue(GL_MAX_EXT);
    static_assert(GL_MIN_EXT == GL_MIN && GL_MAX_EXT == GL_MAX,
                  "min & max variations must match");
  }

  // TODO(dshwang): GLES3 supports gl_FragDepth, not gl_FragDepthEXT.
  if (extensions.Contains("GL_EXT_frag_depth") || gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_EXT_frag_depth");
    feature_flags_.ext_frag_depth = true;
  }

  if (extensions.Contains("GL_EXT_shader_texture_lod") ||
      gfx::HasDesktopGLFeatures()) {
    AddExtensionString("GL_EXT_shader_texture_lod");
    feature_flags_.ext_shader_texture_lod = true;
  }

#if !defined(OS_MACOSX)
  if (workarounds_.disable_egl_khr_fence_sync) {
    gfx::g_driver_egl.ext.b_EGL_KHR_fence_sync = false;
  }
  if (workarounds_.disable_egl_khr_wait_sync) {
    gfx::g_driver_egl.ext.b_EGL_KHR_wait_sync = false;
  }
#endif
  if (workarounds_.disable_arb_sync)
    gfx::g_driver_gl.ext.b_GL_ARB_sync = false;
  bool ui_gl_fence_works = gfx::GLFence::IsSupported();
  UMA_HISTOGRAM_BOOLEAN("GPU.FenceSupport", ui_gl_fence_works);

  feature_flags_.map_buffer_range =
      gl_version_info_->is_es3 ||
      extensions.Contains("GL_ARB_map_buffer_range") ||
      extensions.Contains("GL_EXT_map_buffer_range");

  // Really it's part of core OpenGL 2.1 and up, but let's assume the
  // extension is still advertised.
  bool has_pixel_buffers =
      gl_version_info_->is_es3 ||
      extensions.Contains("GL_ARB_pixel_buffer_object") ||
      extensions.Contains("GL_NV_pixel_buffer_object");

  // We will use either glMapBuffer() or glMapBufferRange() for async readbacks.
  if (has_pixel_buffers && ui_gl_fence_works &&
      !workarounds_.disable_async_readpixels) {
    feature_flags_.use_async_readpixels = true;
  }

  if (gl_version_info_->is_es3 ||
      extensions.Contains("GL_ARB_sampler_objects")) {
    feature_flags_.enable_samplers = true;
    // TODO(dsinclair): Add AddExtensionString("GL_CHROMIUM_sampler_objects")
    // when available.
  }

  if ((gl_version_info_->is_es3 ||
       extensions.Contains("GL_EXT_discard_framebuffer")) &&
      !workarounds_.disable_discard_framebuffer) {
    // DiscardFramebufferEXT is automatically bound to InvalidateFramebuffer.
    AddExtensionString("GL_EXT_discard_framebuffer");
    feature_flags_.ext_discard_framebuffer = true;
  }

  if (ui_gl_fence_works) {
    AddExtensionString("GL_CHROMIUM_sync_query");
    feature_flags_.chromium_sync_query = true;
  }

  bool blend_equation_advanced_coherent =
    extensions.Contains("GL_NV_blend_equation_advanced_coherent") ||
    extensions.Contains("GL_KHR_blend_equation_advanced_coherent");

  if (blend_equation_advanced_coherent ||
      extensions.Contains("GL_NV_blend_equation_advanced") ||
      extensions.Contains("GL_KHR_blend_equation_advanced")) {
    const GLenum equations[] = {GL_MULTIPLY_KHR,
                                GL_SCREEN_KHR,
                                GL_OVERLAY_KHR,
                                GL_DARKEN_KHR,
                                GL_LIGHTEN_KHR,
                                GL_COLORDODGE_KHR,
                                GL_COLORBURN_KHR,
                                GL_HARDLIGHT_KHR,
                                GL_SOFTLIGHT_KHR,
                                GL_DIFFERENCE_KHR,
                                GL_EXCLUSION_KHR,
                                GL_HSL_HUE_KHR,
                                GL_HSL_SATURATION_KHR,
                                GL_HSL_COLOR_KHR,
                                GL_HSL_LUMINOSITY_KHR};

    for (GLenum equation : equations)
      validators_.equation.AddValue(equation);
    if (blend_equation_advanced_coherent)
      AddExtensionString("GL_KHR_blend_equation_advanced_coherent");

    AddExtensionString("GL_KHR_blend_equation_advanced");
    feature_flags_.blend_equation_advanced = true;
    feature_flags_.blend_equation_advanced_coherent =
      blend_equation_advanced_coherent;
  }

  if (extensions.Contains("GL_NV_path_rendering")) {
    if (extensions.Contains("GL_EXT_direct_state_access") ||
        gl_version_info_->is_es3) {
      AddExtensionString("GL_CHROMIUM_path_rendering");
      feature_flags_.chromium_path_rendering = true;
      validators_.g_l_state.AddValue(GL_PATH_MODELVIEW_MATRIX_CHROMIUM);
      validators_.g_l_state.AddValue(GL_PATH_PROJECTION_MATRIX_CHROMIUM);
    }
  }

  if ((gl_version_info_->is_es3 || extensions.Contains("GL_EXT_texture_rg") ||
       extensions.Contains("GL_ARB_texture_rg")) &&
      IsGL_REDSupportedOnFBOs()) {
    feature_flags_.ext_texture_rg = true;
    AddExtensionString("GL_EXT_texture_rg");

    validators_.texture_format.AddValue(GL_RED_EXT);
    validators_.texture_format.AddValue(GL_RG_EXT);
    validators_.texture_internal_format.AddValue(GL_RED_EXT);
    validators_.texture_internal_format.AddValue(GL_RG_EXT);
    validators_.read_pixel_format.AddValue(GL_RED_EXT);
    validators_.read_pixel_format.AddValue(GL_RG_EXT);
    validators_.render_buffer_format.AddValue(GL_R8_EXT);
    validators_.render_buffer_format.AddValue(GL_RG8_EXT);

    texture_format_validators_[GL_RED_EXT].AddValue(GL_UNSIGNED_BYTE);
    texture_format_validators_[GL_RG_EXT].AddValue(GL_UNSIGNED_BYTE);

    if (enable_texture_float) {
      texture_format_validators_[GL_RED_EXT].AddValue(GL_FLOAT);
      texture_format_validators_[GL_RG_EXT].AddValue(GL_FLOAT);
    }
    if (enable_texture_half_float) {
      texture_format_validators_[GL_RED_EXT].AddValue(GL_HALF_FLOAT_OES);
      texture_format_validators_[GL_RG_EXT].AddValue(GL_HALF_FLOAT_OES);
    }
  }

#if !defined(OS_MACOSX)
  if (workarounds_.ignore_egl_sync_failures) {
    gfx::GLFenceEGL::SetIgnoreFailures();
  }
#endif

  if (gl_version_info_->IsLowerThanGL(4, 3)) {
    // crbug.com/481184.
    // GL_PRIMITIVE_RESTART_FIXED_INDEX is only available on Desktop GL 4.3+,
    // but we emulate ES 3.0 on top of Desktop GL 4.2+.
    feature_flags_.emulate_primitive_restart_fixed_index = true;
  }
}

bool FeatureInfo::IsES3Capable() const {
  if (gl_version_info_->IsAtLeastGLES(3, 0))
    return true;
  // TODO(zmo): For Desktop GL, with anything lower than 4.2, we need to check
  // the existence of a few extensions to have full WebGL 2 capabilities.
  if (gl_version_info_->IsAtLeastGL(4, 2))
    return true;
#if defined(OS_MACOSX)
  // TODO(zmo): For experimentation purpose  on MacOSX with core profile,
  // allow 3.2 or plus for now.
  if (gl_version_info_->IsAtLeastGL(3, 2))
    return true;
#endif
  return false;
}

void FeatureInfo::EnableES3Validators() {
  DCHECK(IsES3Capable());
  validators_.UpdateValuesES3();

  GLint max_color_attachments = 0;
  glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &max_color_attachments);
  const int kTotalColorAttachmentEnums = 16;
  const GLenum kColorAttachments[] = {
    GL_COLOR_ATTACHMENT0,
    GL_COLOR_ATTACHMENT1,
    GL_COLOR_ATTACHMENT2,
    GL_COLOR_ATTACHMENT3,
    GL_COLOR_ATTACHMENT4,
    GL_COLOR_ATTACHMENT5,
    GL_COLOR_ATTACHMENT6,
    GL_COLOR_ATTACHMENT7,
    GL_COLOR_ATTACHMENT8,
    GL_COLOR_ATTACHMENT9,
    GL_COLOR_ATTACHMENT10,
    GL_COLOR_ATTACHMENT11,
    GL_COLOR_ATTACHMENT12,
    GL_COLOR_ATTACHMENT13,
    GL_COLOR_ATTACHMENT14,
    GL_COLOR_ATTACHMENT15,
  };
  if (max_color_attachments < kTotalColorAttachmentEnums) {
    validators_.attachment.RemoveValues(
        kColorAttachments + max_color_attachments,
        kTotalColorAttachmentEnums - max_color_attachments);
  }

  GLint max_draw_buffers = 0;
  glGetIntegerv(GL_MAX_DRAW_BUFFERS, &max_draw_buffers);
  const int kTotalDrawBufferEnums = 16;
  const GLenum kDrawBuffers[] = {
    GL_DRAW_BUFFER0,
    GL_DRAW_BUFFER1,
    GL_DRAW_BUFFER2,
    GL_DRAW_BUFFER3,
    GL_DRAW_BUFFER4,
    GL_DRAW_BUFFER5,
    GL_DRAW_BUFFER6,
    GL_DRAW_BUFFER7,
    GL_DRAW_BUFFER8,
    GL_DRAW_BUFFER9,
    GL_DRAW_BUFFER10,
    GL_DRAW_BUFFER11,
    GL_DRAW_BUFFER12,
    GL_DRAW_BUFFER13,
    GL_DRAW_BUFFER14,
    GL_DRAW_BUFFER15,
  };
  if (max_draw_buffers < kTotalDrawBufferEnums) {
    validators_.g_l_state.RemoveValues(
        kDrawBuffers + max_draw_buffers,
        kTotalDrawBufferEnums - max_draw_buffers);
  }
}

void FeatureInfo::AddExtensionString(const char* s) {
  std::string str(s);
  size_t pos = extensions_.find(str);
  while (pos != std::string::npos &&
         pos + str.length() < extensions_.length() &&
         extensions_.substr(pos + str.length(), 1) != " ") {
    // This extension name is a substring of another.
    pos = extensions_.find(str, pos + str.length());
  }
  if (pos == std::string::npos) {
    extensions_ += (extensions_.empty() ? "" : " ") + str;
  }
}

FeatureInfo::~FeatureInfo() {
}

}  // namespace gles2
}  // namespace gpu
