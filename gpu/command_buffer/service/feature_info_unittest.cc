// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/feature_info.h"

#include "base/command_line.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "gpu/command_buffer/service/texture_manager.h"
#include "gpu/config/gpu_driver_bug_workaround_type.h"
#include "gpu/config/gpu_switches.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_fence.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_mock.h"

using ::testing::_;
using ::testing::DoAll;
using ::testing::HasSubstr;
using ::testing::InSequence;
using ::testing::MatcherCast;
using ::testing::Not;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SetArrayArgument;
using ::testing::SetArgumentPointee;
using ::testing::StrEq;

namespace gpu {
namespace gles2 {

namespace {
const char kGLRendererStringANGLE[] = "ANGLE (some renderer)";
}  // anonymous namespace

class FeatureInfoTest : public GpuServiceTest {
 public:
  FeatureInfoTest() {
  }

  void SetupInitExpectations(const char* extensions) {
    SetupInitExpectationsWithGLVersion(extensions, "", "3.0");
  }

  void SetupInitExpectationsWithGLVersion(
      const char* extensions, const char* renderer, const char* version) {
    GpuServiceTest::SetUpWithGLVersion(version, extensions);
    TestHelper::SetupFeatureInfoInitExpectationsWithGLVersion(
        gl_.get(), extensions, renderer, version);
    info_ = new FeatureInfo();
    info_->Initialize();
  }

  void SetupWithCommandLine(const base::CommandLine& command_line) {
    GpuServiceTest::SetUp();
    info_ = new FeatureInfo(command_line);
  }

  void SetupInitExpectationsWithCommandLine(
      const char* extensions,
      const base::CommandLine& command_line) {
    GpuServiceTest::SetUpWithGLVersion("2.0", extensions);
    TestHelper::SetupFeatureInfoInitExpectationsWithGLVersion(
        gl_.get(), extensions, "", "");
    info_ = new FeatureInfo(command_line);
    info_->Initialize();
  }

  void SetupWithoutInit() {
    GpuServiceTest::SetUp();
    info_ = new FeatureInfo();
  }

 protected:
  void SetUp() override {
    // Do nothing here, since we are using the explicit Setup*() functions.
  }

  void TearDown() override {
    info_ = NULL;
    GpuServiceTest::TearDown();
  }

  scoped_refptr<FeatureInfo> info_;
};

namespace {

struct FormatInfo {
   GLenum format;
   const GLenum* types;
   size_t count;
};

}  // anonymous namespace.

TEST_F(FeatureInfoTest, Basic) {
  SetupWithoutInit();
  // Test it starts off uninitialized.
  EXPECT_FALSE(info_->feature_flags().chromium_framebuffer_multisample);
  EXPECT_FALSE(info_->feature_flags().use_core_framebuffer_multisample);
  EXPECT_FALSE(info_->feature_flags().multisampled_render_to_texture);
  EXPECT_FALSE(info_->feature_flags(
      ).use_img_for_multisampled_render_to_texture);
  EXPECT_FALSE(info_->feature_flags().oes_standard_derivatives);
  EXPECT_FALSE(info_->feature_flags().npot_ok);
  EXPECT_FALSE(info_->feature_flags().enable_texture_float_linear);
  EXPECT_FALSE(info_->feature_flags().enable_texture_half_float_linear);
  EXPECT_FALSE(info_->feature_flags().oes_egl_image_external);
  EXPECT_FALSE(info_->feature_flags().oes_depth24);
  EXPECT_FALSE(info_->feature_flags().packed_depth24_stencil8);
  EXPECT_FALSE(info_->feature_flags().angle_translated_shader_source);
  EXPECT_FALSE(info_->feature_flags().angle_pack_reverse_row_order);
  EXPECT_FALSE(info_->feature_flags().arb_texture_rectangle);
  EXPECT_FALSE(info_->feature_flags().angle_instanced_arrays);
  EXPECT_FALSE(info_->feature_flags().occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query2_for_occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query_for_occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags().native_vertex_array_object);
  EXPECT_FALSE(info_->feature_flags().map_buffer_range);
  EXPECT_FALSE(info_->feature_flags().use_async_readpixels);
  EXPECT_FALSE(info_->feature_flags().ext_draw_buffers);
  EXPECT_FALSE(info_->feature_flags().nv_draw_buffers);
  EXPECT_FALSE(info_->feature_flags().ext_discard_framebuffer);
  EXPECT_FALSE(info_->feature_flags().angle_depth_texture);

#define GPU_OP(type, name) EXPECT_FALSE(info_->workarounds().name);
  GPU_DRIVER_BUG_WORKAROUNDS(GPU_OP)
#undef GPU_OP
  EXPECT_EQ(0, info_->workarounds().max_texture_size);
  EXPECT_EQ(0, info_->workarounds().max_cube_map_texture_size);
  EXPECT_FALSE(info_->workarounds().gl_clear_broken);

  // Test good types.
  {
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
      const ValueValidator<GLenum>& validator =
          info_->GetTextureFormatValidator(info.format);
      for (size_t jj = 0; jj < info.count; ++jj) {
        EXPECT_TRUE(validator.IsValid(info.types[jj]));
      }
    }
  }

  // Test some bad types
  {
    static const GLenum kAlphaTypes[] = {
        GL_UNSIGNED_SHORT_5_5_5_1,
        GL_FLOAT,
    };
    static const GLenum kRGBTypes[] = {
        GL_UNSIGNED_SHORT_4_4_4_4,
        GL_FLOAT,
    };
    static const GLenum kRGBATypes[] = {
        GL_UNSIGNED_SHORT_5_6_5,
        GL_FLOAT,
    };
    static const GLenum kLuminanceTypes[] = {
        GL_UNSIGNED_SHORT_4_4_4_4,
        GL_FLOAT,
    };
    static const GLenum kLuminanceAlphaTypes[] = {
        GL_UNSIGNED_SHORT_5_5_5_1,
        GL_FLOAT,
    };
    static const GLenum kBGRATypes[] = {
        GL_UNSIGNED_BYTE,
        GL_UNSIGNED_SHORT_5_6_5,
        GL_FLOAT,
    };
    static const GLenum kDepthTypes[] = {
        GL_UNSIGNED_BYTE,
        GL_UNSIGNED_SHORT,
        GL_UNSIGNED_INT,
        GL_FLOAT,
    };
    static const FormatInfo kFormatTypes[] = {
      { GL_ALPHA, kAlphaTypes, arraysize(kAlphaTypes), },
      { GL_RGB, kRGBTypes, arraysize(kRGBTypes), },
      { GL_RGBA, kRGBATypes, arraysize(kRGBATypes), },
      { GL_LUMINANCE, kLuminanceTypes, arraysize(kLuminanceTypes), },
      { GL_LUMINANCE_ALPHA, kLuminanceAlphaTypes,
        arraysize(kLuminanceAlphaTypes), } ,
      { GL_BGRA_EXT, kBGRATypes, arraysize(kBGRATypes), },
      { GL_DEPTH_COMPONENT, kDepthTypes, arraysize(kDepthTypes), },
    };
    for (size_t ii = 0; ii < arraysize(kFormatTypes); ++ii) {
      const FormatInfo& info = kFormatTypes[ii];
      const ValueValidator<GLenum>& validator =
          info_->GetTextureFormatValidator(info.format);
      for (size_t jj = 0; jj < info.count; ++jj) {
        EXPECT_FALSE(validator.IsValid(info.types[jj]));
      }
    }
  }
}

TEST_F(FeatureInfoTest, InitializeNoExtensions) {
  SetupInitExpectations("");
  // Check default extensions are there
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_resource_safe"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_strict_attribs"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_ANGLE_translated_shader_source"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_trace_marker"));

  // Check a couple of random extensions that should not be there.
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_npot")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_texture_compression_dxt1")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_texture_compression_dxt3")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_texture_compression_dxt5")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_ANGLE_texture_usage")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_texture_storage")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_compressed_ETC1_RGB8_texture")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_AMD_compressed_ATC_texture")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_IMG_texture_compression_pvrtc")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_sRGB")));
  EXPECT_FALSE(info_->feature_flags().npot_ok);
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_ETC1_RGB8_OES));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGB_AMD));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGBA_EXPLICIT_ALPHA_AMD));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG));
  EXPECT_FALSE(info_->validators()->read_pixel_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_FALSE(info_->validators()->texture_parameter.IsValid(
      GL_TEXTURE_MAX_ANISOTROPY_EXT));
  EXPECT_FALSE(info_->validators()->g_l_state.IsValid(
      GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT));
  EXPECT_FALSE(info_->validators()->frame_buffer_target.IsValid(
      GL_READ_FRAMEBUFFER_EXT));
  EXPECT_FALSE(info_->validators()->frame_buffer_target.IsValid(
      GL_DRAW_FRAMEBUFFER_EXT));
  EXPECT_FALSE(info_->validators()->g_l_state.IsValid(
      GL_READ_FRAMEBUFFER_BINDING_EXT));
  EXPECT_FALSE(info_->validators()->render_buffer_parameter.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH24_STENCIL8));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_STENCIL));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_RGBA32F));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_RGB32F));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_DEPTH_STENCIL));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(
      GL_UNSIGNED_INT_24_8));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH_COMPONENT24));
  EXPECT_FALSE(info_->validators()->texture_parameter.IsValid(
      GL_TEXTURE_USAGE_ANGLE));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH_COMPONENT16));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH_COMPONENT32_OES));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH24_STENCIL8_OES));
  EXPECT_FALSE(info_->validators()->equation.IsValid(GL_MIN_EXT));
  EXPECT_FALSE(info_->validators()->equation.IsValid(GL_MAX_EXT));
  EXPECT_FALSE(info_->feature_flags().chromium_sync_query);
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_SRGB_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_SRGB_ALPHA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_SRGB8_ALPHA8_EXT));
  EXPECT_FALSE(info_->validators()->frame_buffer_parameter.IsValid(
      GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT));
}

TEST_F(FeatureInfoTest, InitializeWithANGLE) {
  SetupInitExpectationsWithGLVersion("", kGLRendererStringANGLE, "");
  EXPECT_TRUE(info_->gl_version_info().is_angle);
}

TEST_F(FeatureInfoTest, InitializeNPOTExtensionGLES) {
  SetupInitExpectations("GL_OES_texture_npot");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_npot"));
  EXPECT_TRUE(info_->feature_flags().npot_ok);
}

TEST_F(FeatureInfoTest, InitializeNPOTExtensionGL) {
  SetupInitExpectations("GL_ARB_texture_non_power_of_two");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_npot"));
  EXPECT_TRUE(info_->feature_flags().npot_ok);
}

TEST_F(FeatureInfoTest, InitializeDXTExtensionGLES2) {
  SetupInitExpectations("GL_EXT_texture_compression_dxt1");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_compression_dxt1"));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT));
  EXPECT_FALSE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT));
}

TEST_F(FeatureInfoTest, InitializeDXTExtensionGL) {
  SetupInitExpectations("GL_EXT_texture_compression_s3tc");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_compression_dxt1"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_texture_compression_dxt3"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_texture_compression_dxt5"));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_format_BGRA8888GLES2) {
  SetupInitExpectations("GL_EXT_texture_format_BGRA8888");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_format_BGRA8888"));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_BGRA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_BGRA8_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_format_BGRA8888GL) {
  SetupInitExpectations("GL_EXT_bgra");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_format_BGRA8888"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_read_format_bgra"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_renderbuffer_format_BGRA8888"));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_BGRA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_BGRA8_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_format_BGRA8888Apple) {
  SetupInitExpectations("GL_APPLE_texture_format_BGRA8888");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_format_BGRA8888"));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_BGRA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_BGRA8_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_read_format_bgra) {
  SetupInitExpectations("GL_EXT_read_format_bgra");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_read_format_bgra"));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(
      GL_BGRA_EXT));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_BGRA8_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_sRGB) {
  SetupInitExpectations("GL_EXT_sRGB GL_OES_rgb8_rgba8");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_sRGB"));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_SRGB_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_SRGB_ALPHA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_SRGB8_ALPHA8_EXT));
  EXPECT_TRUE(info_->validators()->frame_buffer_parameter.IsValid(
      GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_storage) {
  SetupInitExpectations("GL_EXT_texture_storage");
  EXPECT_TRUE(info_->feature_flags().ext_texture_storage);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_TRUE(info_->validators()->texture_parameter.IsValid(
      GL_TEXTURE_IMMUTABLE_FORMAT_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_BGRA8_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGBA32F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGB32F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_ALPHA32F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE32F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE_ALPHA32F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGBA16F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGB16F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_ALPHA16F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE16F_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE_ALPHA16F_EXT));
}

TEST_F(FeatureInfoTest, InitializeARB_texture_storage) {
  SetupInitExpectations("GL_ARB_texture_storage");
  EXPECT_TRUE(info_->feature_flags().ext_texture_storage);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_TRUE(info_->validators()->texture_parameter.IsValid(
      GL_TEXTURE_IMMUTABLE_FORMAT_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_storage_BGRA) {
  SetupInitExpectations("GL_EXT_texture_storage GL_EXT_bgra");
  EXPECT_TRUE(info_->feature_flags().ext_texture_storage);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_BGRA8_EXT));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

TEST_F(FeatureInfoTest, InitializeARB_texture_storage_BGRA) {
  SetupInitExpectations("GL_ARB_texture_storage GL_EXT_bgra");
  EXPECT_TRUE(info_->feature_flags().ext_texture_storage);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_BGRA8_EXT));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_storage_BGRA8888) {
  SetupInitExpectations(
      "GL_EXT_texture_storage GL_EXT_texture_format_BGRA8888");
  EXPECT_TRUE(info_->feature_flags().ext_texture_storage);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_BGRA8_EXT));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_storage_float) {
  SetupInitExpectations("GL_EXT_texture_storage GL_OES_texture_float");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_float"));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGBA32F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGB32F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_ALPHA32F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE32F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE_ALPHA32F_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_storage_half_float) {
  SetupInitExpectations("GL_EXT_texture_storage GL_OES_texture_half_float");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_half_float"));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGBA16F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_RGB16F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_ALPHA16F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE16F_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_LUMINANCE_ALPHA16F_EXT));
}

// Check how to handle ES, texture_storage and BGRA combination; 10 tests.

// 1- ES2 + GL_EXT_texture_storage -> GL_EXT_texture_storage (and no
// GL_EXT_texture_format_BGRA8888 - we don't claim to handle GL_BGRA8 in
// glTexStorage2DEXT)
TEST_F(FeatureInfoTest, InitializeGLES2_texture_storage) {
  SetupInitExpectationsWithGLVersion(
      "GL_EXT_texture_storage", "", "OpenGL ES 2.0");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_texture_format_BGRA8888")));
}

// 2- ES2 + GL_EXT_texture_storage + (GL_EXT_texture_format_BGRA8888 or
// GL_APPLE_texture_format_bgra8888)
TEST_F(FeatureInfoTest, InitializeGLES2_texture_storage_BGRA) {
  SetupInitExpectationsWithGLVersion(
      "GL_EXT_texture_storage GL_EXT_texture_format_BGRA8888",
      "",
      "OpenGL ES 2.0");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

// 3- ES2 + GL_EXT_texture_format_BGRA8888 or GL_APPLE_texture_format_bgra8888
TEST_F(FeatureInfoTest, InitializeGLES2_texture_format_BGRA) {
  SetupInitExpectationsWithGLVersion(
      "GL_EXT_texture_format_BGRA8888", "", "OpenGL ES 2.0");
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_EXT_texture_storage")));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

// 4- ES2 (neither GL_EXT_texture_storage nor GL_EXT_texture_format_BGRA8888) ->
// nothing
TEST_F(FeatureInfoTest, InitializeGLES2_neither_texture_storage_nor_BGRA) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 2.0");
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_EXT_texture_storage")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_texture_format_BGRA8888")));
}

// 5- ES3 + GL_EXT_texture_format_BGRA8888 -> GL_EXT_texture_format_BGRA8888
// (we can't expose GL_EXT_texture_storage because we fail the GL_BGRA8
// requirement)
TEST_F(FeatureInfoTest, InitializeGLES3_texture_storage_EXT_BGRA) {
  SetupInitExpectationsWithGLVersion(
      "GL_EXT_texture_format_BGRA8888", "", "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_EXT_texture_storage")));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

// 6- ES3 + GL_APPLE_texture_format_bgra8888 -> GL_EXT_texture_storage +
// GL_EXT_texture_format_BGRA8888 (driver promises to handle GL_BGRA8 by
// exposing GL_APPLE_texture_format_bgra8888)
TEST_F(FeatureInfoTest, InitializeGLES3_texture_storage_APPLE_BGRA) {
  SetupInitExpectationsWithGLVersion(
      "GL_APPLE_texture_format_BGRA8888", "", "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

// 7- ES3 + GL_EXT_texture_storage + GL_EXT_texture_format_BGRA8888 ->
// GL_EXT_texture_storage + GL_EXT_texture_format_BGRA8888  (driver promises to
// handle GL_BGRA8 by exposing GL_EXT_texture_storage)
TEST_F(FeatureInfoTest, InitializeGLES3_EXT_texture_storage_EXT_BGRA) {
  SetupInitExpectationsWithGLVersion(
      "GL_EXT_texture_storage GL_EXT_texture_format_BGRA8888",
      "",
      "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_format_BGRA8888"));
}

// 8- ES3 + none of the above -> GL_EXT_texture_storage (and no
// GL_EXT_texture_format_BGRA8888 - we don't claim to handle GL_BGRA8)
TEST_F(FeatureInfoTest, InitializeGLES3_texture_storage) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_texture_storage"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_EXT_texture_format_BGRA8888")));
}

// 9- ANGLE will add the GL_CHROMIUM_renderbuffer_format_BGRA8888 extension and
// the GL_BGRA8_EXT render buffer format.
TEST_F(FeatureInfoTest, InitializeWithANGLE_BGRA8) {
  SetupInitExpectationsWithGLVersion("", kGLRendererStringANGLE, "");
  EXPECT_TRUE(info_->gl_version_info().is_angle);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_renderbuffer_format_BGRA8888"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(GL_BGRA8_EXT));
}

// 10- vanilla opengl es means no GL_CHROMIUM_renderbuffer_format_BGRA8888
TEST_F(FeatureInfoTest,
       InitializeGLES2_no_CHROMIUM_renderbuffer_format_BGRA8888) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 2.0");
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_renderbuffer_format_BGRA8888")));
}

TEST_F(FeatureInfoTest, InitializeARB_texture_float) {
  SetupInitExpectations("GL_ARB_texture_float");
  EXPECT_TRUE(info_->feature_flags().chromium_color_buffer_float_rgba);
  EXPECT_TRUE(info_->feature_flags().chromium_color_buffer_float_rgb);
  std::string extensions = info_->extensions() + " ";
  EXPECT_THAT(extensions, HasSubstr("GL_CHROMIUM_color_buffer_float_rgb "));
  EXPECT_THAT(extensions, HasSubstr("GL_CHROMIUM_color_buffer_float_rgba"));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_RGBA32F));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_RGB32F));
}

TEST_F(FeatureInfoTest, Initialize_texture_floatGLES3) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_float")));
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_half_float")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_float_linear")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_half_float_linear")));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_FLOAT));
}

TEST_F(FeatureInfoTest, Initialize_sRGBGLES3) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 3.0");
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_EXT_sRGB")));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_SRGB_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_SRGB_ALPHA_EXT).IsValid(
      GL_UNSIGNED_BYTE));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_EXT));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_SRGB_ALPHA_EXT));
  EXPECT_FALSE(info_->validators()->render_buffer_format.IsValid(
      GL_SRGB8_ALPHA8_EXT));
  EXPECT_FALSE(info_->validators()->frame_buffer_parameter.IsValid(
      GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT));
}

TEST_F(FeatureInfoTest, InitializeOES_texture_floatGLES2) {
  SetupInitExpectations("GL_OES_texture_float");
  EXPECT_FALSE(info_->feature_flags().enable_texture_float_linear);
  EXPECT_FALSE(info_->feature_flags().enable_texture_half_float_linear);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_float"));
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_half_float")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_float_linear")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_half_float_linear")));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_FLOAT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_texture_float_linearGLES2) {
  SetupInitExpectations("GL_OES_texture_float GL_OES_texture_float_linear");
  EXPECT_TRUE(info_->feature_flags().enable_texture_float_linear);
  EXPECT_FALSE(info_->feature_flags().enable_texture_half_float_linear);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_float"));
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_half_float")));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_float_linear"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_half_float_linear")));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_FLOAT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_texture_half_floatGLES2) {
  SetupInitExpectations("GL_OES_texture_half_float");
  EXPECT_FALSE(info_->feature_flags().enable_texture_float_linear);
  EXPECT_FALSE(info_->feature_flags().enable_texture_half_float_linear);
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_float")));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_half_float"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_float_linear")));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_half_float_linear")));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_FLOAT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_texture_half_float_linearGLES2) {
  SetupInitExpectations(
      "GL_OES_texture_half_float GL_OES_texture_half_float_linear");
  EXPECT_FALSE(info_->feature_flags().enable_texture_float_linear);
  EXPECT_TRUE(info_->feature_flags().enable_texture_half_float_linear);
  EXPECT_THAT(info_->extensions(), Not(HasSubstr("GL_OES_texture_float")));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_texture_half_float"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_OES_texture_float_linear")));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_texture_half_float_linear"));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_FLOAT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_HALF_FLOAT_OES));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_FLOAT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_FLOAT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGB).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_RGBA).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE).IsValid(
      GL_HALF_FLOAT_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_LUMINANCE_ALPHA).IsValid(
      GL_HALF_FLOAT_OES));
}

TEST_F(FeatureInfoTest, InitializeEXT_framebuffer_multisample) {
  SetupInitExpectations("GL_EXT_framebuffer_multisample");
  EXPECT_TRUE(info_->feature_flags().chromium_framebuffer_multisample);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_framebuffer_multisample"));
  EXPECT_TRUE(info_->validators()->frame_buffer_target.IsValid(
      GL_READ_FRAMEBUFFER_EXT));
  EXPECT_TRUE(info_->validators()->frame_buffer_target.IsValid(
      GL_DRAW_FRAMEBUFFER_EXT));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_READ_FRAMEBUFFER_BINDING_EXT));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_parameter.IsValid(
      GL_RENDERBUFFER_SAMPLES_EXT));
}

TEST_F(FeatureInfoTest, InitializeANGLE_framebuffer_multisample) {
  SetupInitExpectationsWithGLVersion(
      "GL_ANGLE_framebuffer_multisample", kGLRendererStringANGLE, "");
  EXPECT_TRUE(info_->feature_flags().chromium_framebuffer_multisample);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_framebuffer_multisample"));
  EXPECT_TRUE(info_->validators()->frame_buffer_target.IsValid(
      GL_READ_FRAMEBUFFER_EXT));
  EXPECT_TRUE(info_->validators()->frame_buffer_target.IsValid(
      GL_DRAW_FRAMEBUFFER_EXT));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_READ_FRAMEBUFFER_BINDING_EXT));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_parameter.IsValid(
      GL_RENDERBUFFER_SAMPLES_EXT));
}

// We don't allow ANGLE_framebuffer_multisample on non-ANGLE implementations,
// because we wouldn't be choosing the right driver entry point and because the
// extension was falsely advertised on some Android devices (crbug.com/165736).
TEST_F(FeatureInfoTest, InitializeANGLE_framebuffer_multisampleWithoutANGLE) {
  SetupInitExpectations("GL_ANGLE_framebuffer_multisample");
  EXPECT_FALSE(info_->feature_flags().chromium_framebuffer_multisample);
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_framebuffer_multisample")));
  EXPECT_FALSE(info_->validators()->frame_buffer_target.IsValid(
      GL_READ_FRAMEBUFFER_EXT));
  EXPECT_FALSE(info_->validators()->frame_buffer_target.IsValid(
      GL_DRAW_FRAMEBUFFER_EXT));
  EXPECT_FALSE(info_->validators()->g_l_state.IsValid(
      GL_READ_FRAMEBUFFER_BINDING_EXT));
  EXPECT_FALSE(info_->validators()->g_l_state.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_FALSE(info_->validators()->render_buffer_parameter.IsValid(
      GL_RENDERBUFFER_SAMPLES_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_multisampled_render_to_texture) {
  SetupInitExpectations("GL_EXT_multisampled_render_to_texture");
  EXPECT_TRUE(info_->feature_flags(
      ).multisampled_render_to_texture);
  EXPECT_FALSE(info_->feature_flags(
      ).use_img_for_multisampled_render_to_texture);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_multisampled_render_to_texture"));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_parameter.IsValid(
      GL_RENDERBUFFER_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->frame_buffer_parameter.IsValid(
      GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT));
}

TEST_F(FeatureInfoTest, InitializeIMG_multisampled_render_to_texture) {
  SetupInitExpectations("GL_IMG_multisampled_render_to_texture");
  EXPECT_TRUE(info_->feature_flags(
      ).multisampled_render_to_texture);
  EXPECT_TRUE(info_->feature_flags(
      ).use_img_for_multisampled_render_to_texture);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_multisampled_render_to_texture"));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_MAX_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_parameter.IsValid(
      GL_RENDERBUFFER_SAMPLES_EXT));
  EXPECT_TRUE(info_->validators()->frame_buffer_parameter.IsValid(
      GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_filter_anisotropic) {
  SetupInitExpectations("GL_EXT_texture_filter_anisotropic");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_texture_filter_anisotropic"));
  EXPECT_TRUE(info_->validators()->texture_parameter.IsValid(
      GL_TEXTURE_MAX_ANISOTROPY_EXT));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_ARB_depth_texture) {
  SetupInitExpectations("GL_ARB_depth_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_GOOGLE_depth_texture"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_depth_texture"));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_INT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_DEPTH_STENCIL).IsValid(
      GL_UNSIGNED_INT_24_8));
}

TEST_F(FeatureInfoTest, InitializeOES_ARB_depth_texture) {
  SetupInitExpectations("GL_OES_depth_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_GOOGLE_depth_texture"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_depth_texture"));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_INT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_DEPTH_STENCIL).IsValid(
      GL_UNSIGNED_INT_24_8));
}

TEST_F(FeatureInfoTest, InitializeANGLE_depth_texture) {
  SetupInitExpectations("GL_ANGLE_depth_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_GOOGLE_depth_texture"));
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_depth_texture"));
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_ANGLE_depth_texture")));
  EXPECT_TRUE(info_->feature_flags().angle_depth_texture);
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH_COMPONENT16));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH_COMPONENT32_OES));
  EXPECT_FALSE(info_->validators()->texture_internal_format_storage.IsValid(
      GL_DEPTH24_STENCIL8_OES));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_INT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_DEPTH_STENCIL).IsValid(
      GL_UNSIGNED_INT_24_8));
}

TEST_F(FeatureInfoTest, InitializeEXT_packed_depth_stencil) {
  SetupInitExpectations("GL_EXT_packed_depth_stencil");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_packed_depth_stencil"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH24_STENCIL8));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
}

TEST_F(FeatureInfoTest, InitializeOES_packed_depth_stencil) {
  SetupInitExpectations("GL_OES_packed_depth_stencil");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_packed_depth_stencil"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH24_STENCIL8));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_FALSE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
}

TEST_F(FeatureInfoTest,
       InitializeOES_packed_depth_stencil_and_GL_ARB_depth_texture) {
  SetupInitExpectations("GL_OES_packed_depth_stencil GL_ARB_depth_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_packed_depth_stencil"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH24_STENCIL8));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(
      GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(
      GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(
      GL_UNSIGNED_INT_24_8));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT).IsValid(
      GL_UNSIGNED_INT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_STENCIL).IsValid(
      GL_UNSIGNED_INT_24_8));
}

TEST_F(FeatureInfoTest, InitializeOES_depth24) {
  SetupInitExpectations("GL_OES_depth24");
  EXPECT_TRUE(info_->feature_flags().oes_depth24);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_depth24"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_DEPTH_COMPONENT24));
}

TEST_F(FeatureInfoTest, InitializeOES_standard_derivatives) {
  SetupInitExpectations("GL_OES_standard_derivatives");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_standard_derivatives"));
  EXPECT_TRUE(info_->feature_flags().oes_standard_derivatives);
  EXPECT_TRUE(info_->validators()->hint_target.IsValid(
      GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_rgb8_rgba8) {
  SetupInitExpectations("GL_OES_rgb8_rgba8");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_rgb8_rgba8"));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_RGB8_OES));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(
      GL_RGBA8_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_EGL_image_external) {
  SetupInitExpectations("GL_OES_EGL_image_external");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_EGL_image_external"));
  EXPECT_TRUE(info_->feature_flags().oes_egl_image_external);
  EXPECT_TRUE(info_->validators()->texture_bind_target.IsValid(
      GL_TEXTURE_EXTERNAL_OES));
  EXPECT_TRUE(info_->validators()->get_tex_param_target.IsValid(
      GL_TEXTURE_EXTERNAL_OES));
  EXPECT_TRUE(info_->validators()->texture_parameter.IsValid(
      GL_REQUIRED_TEXTURE_IMAGE_UNITS_OES));
  EXPECT_TRUE(info_->validators()->g_l_state.IsValid(
      GL_TEXTURE_BINDING_EXTERNAL_OES));
}

TEST_F(FeatureInfoTest, InitializeOES_compressed_ETC1_RGB8_texture) {
  SetupInitExpectations("GL_OES_compressed_ETC1_RGB8_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_compressed_ETC1_RGB8_texture"));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_ETC1_RGB8_OES));
  EXPECT_FALSE(info_->validators()->texture_internal_format.IsValid(
      GL_ETC1_RGB8_OES));
}

TEST_F(FeatureInfoTest, InitializeAMD_compressed_ATC_texture) {
  SetupInitExpectations("GL_AMD_compressed_ATC_texture");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_AMD_compressed_ATC_texture"));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGB_AMD));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGBA_EXPLICIT_ALPHA_AMD));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD));
}

TEST_F(FeatureInfoTest, InitializeIMG_texture_compression_pvrtc) {
  SetupInitExpectations("GL_IMG_texture_compression_pvrtc");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_IMG_texture_compression_pvrtc"));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG));
  EXPECT_TRUE(info_->validators()->compressed_texture_format.IsValid(
      GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG));
}

TEST_F(FeatureInfoTest, InitializeEXT_occlusion_query_boolean) {
  SetupInitExpectations("GL_EXT_occlusion_query_boolean");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_occlusion_query_boolean"));
  EXPECT_TRUE(info_->feature_flags().occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query2_for_occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query_for_occlusion_query_boolean);
}

TEST_F(FeatureInfoTest, InitializeARB_occlusion_query) {
  SetupInitExpectations("GL_ARB_occlusion_query");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_occlusion_query_boolean"));
  EXPECT_TRUE(info_->feature_flags().occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query2_for_occlusion_query_boolean);
  EXPECT_TRUE(info_->feature_flags(
      ).use_arb_occlusion_query_for_occlusion_query_boolean);
}

TEST_F(FeatureInfoTest, InitializeARB_occlusion_query2) {
  SetupInitExpectations("GL_ARB_occlusion_query2 GL_ARB_occlusion_query2");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_EXT_occlusion_query_boolean"));
  EXPECT_TRUE(info_->feature_flags().occlusion_query_boolean);
  EXPECT_TRUE(info_->feature_flags(
      ).use_arb_occlusion_query2_for_occlusion_query_boolean);
  EXPECT_FALSE(info_->feature_flags(
      ).use_arb_occlusion_query_for_occlusion_query_boolean);
}

TEST_F(FeatureInfoTest, InitializeOES_vertex_array_object) {
  SetupInitExpectations("GL_OES_vertex_array_object");
  EXPECT_THAT(info_->extensions(),
      HasSubstr("GL_OES_vertex_array_object"));
  EXPECT_TRUE(info_->feature_flags().native_vertex_array_object);
}

TEST_F(FeatureInfoTest, InitializeARB_vertex_array_object) {
  SetupInitExpectations("GL_ARB_vertex_array_object");
  EXPECT_THAT(info_->extensions(),
      HasSubstr("GL_OES_vertex_array_object"));
  EXPECT_TRUE(info_->feature_flags().native_vertex_array_object);
}

TEST_F(FeatureInfoTest, InitializeAPPLE_vertex_array_object) {
  SetupInitExpectations("GL_APPLE_vertex_array_object");
  EXPECT_THAT(info_->extensions(),
      HasSubstr("GL_OES_vertex_array_object"));
  EXPECT_TRUE(info_->feature_flags().native_vertex_array_object);
}

TEST_F(FeatureInfoTest, InitializeNo_vertex_array_object) {
  SetupInitExpectations("");
  // Even if the native extensions are not available the implementation
  // may still emulate the GL_OES_vertex_array_object functionality. In this
  // scenario native_vertex_array_object must be false.
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_vertex_array_object"));
  EXPECT_FALSE(info_->feature_flags().native_vertex_array_object);
}

TEST_F(FeatureInfoTest, InitializeOES_element_index_uint) {
  SetupInitExpectations("GL_OES_element_index_uint");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_OES_element_index_uint"));
  EXPECT_TRUE(info_->validators()->index_type.IsValid(GL_UNSIGNED_INT));
}

TEST_F(FeatureInfoTest, InitializeVAOsWithClientSideArrays) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::USE_CLIENT_SIDE_ARRAYS_FOR_STREAM_BUFFERS));
  SetupInitExpectationsWithCommandLine("GL_OES_vertex_array_object",
                                       command_line);
  EXPECT_TRUE(info_->workarounds().use_client_side_arrays_for_stream_buffers);
  EXPECT_FALSE(info_->feature_flags().native_vertex_array_object);
}

TEST_F(FeatureInfoTest, InitializeEXT_blend_minmax) {
  SetupInitExpectations("GL_EXT_blend_minmax");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_blend_minmax"));
  EXPECT_TRUE(info_->validators()->equation.IsValid(GL_MIN_EXT));
  EXPECT_TRUE(info_->validators()->equation.IsValid(GL_MAX_EXT));
}

TEST_F(FeatureInfoTest, InitializeEXT_frag_depth) {
  SetupInitExpectations("GL_EXT_frag_depth");
  EXPECT_TRUE(info_->feature_flags().ext_frag_depth);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_frag_depth"));
}

TEST_F(FeatureInfoTest, InitializeEXT_shader_texture_lod) {
  SetupInitExpectations("GL_EXT_shader_texture_lod");
  EXPECT_TRUE(info_->feature_flags().ext_shader_texture_lod);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_shader_texture_lod"));
}

TEST_F(FeatureInfoTest, InitializeEXT_discard_framebuffer) {
  SetupInitExpectations("GL_EXT_discard_framebuffer");
  EXPECT_TRUE(info_->feature_flags().ext_discard_framebuffer);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_discard_framebuffer"));
}

TEST_F(FeatureInfoTest, InitializeSamplersWithARBSamplerObjects) {
  SetupInitExpectationsWithGLVersion(
      "GL_ARB_sampler_objects", "", "OpenGL 3.0");
  EXPECT_TRUE(info_->feature_flags().enable_samplers);
}

TEST_F(FeatureInfoTest, InitializeWithES3) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL ES 3.0");
  EXPECT_TRUE(info_->feature_flags().chromium_framebuffer_multisample);
  EXPECT_TRUE(info_->feature_flags().use_core_framebuffer_multisample);
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_CHROMIUM_framebuffer_multisample"));
  EXPECT_TRUE(info_->feature_flags().use_async_readpixels);
  EXPECT_TRUE(info_->feature_flags().oes_standard_derivatives);
  EXPECT_TRUE(info_->feature_flags().oes_depth24);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_GOOGLE_depth_texture"));
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_depth_texture"));
  EXPECT_TRUE(
      info_->validators()->texture_internal_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_TRUE(
      info_->validators()->texture_internal_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_COMPONENT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT));
  EXPECT_TRUE(info_->validators()->pixel_type.IsValid(GL_UNSIGNED_INT_24_8));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT)
                  .IsValid(GL_UNSIGNED_SHORT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_COMPONENT)
                  .IsValid(GL_UNSIGNED_INT));
  EXPECT_TRUE(info_->GetTextureFormatValidator(GL_DEPTH_STENCIL)
                  .IsValid(GL_UNSIGNED_INT_24_8));
  EXPECT_TRUE(info_->feature_flags().packed_depth24_stencil8);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_OES_depth24"));
  EXPECT_TRUE(
      info_->validators()->render_buffer_format.IsValid(GL_DEPTH_COMPONENT24));
  EXPECT_TRUE(
      info_->validators()->render_buffer_format.IsValid(GL_DEPTH24_STENCIL8));
  EXPECT_TRUE(
      info_->validators()->texture_internal_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_DEPTH_STENCIL));
  EXPECT_TRUE(info_->feature_flags().npot_ok);
  EXPECT_TRUE(info_->feature_flags().native_vertex_array_object);
  EXPECT_TRUE(info_->feature_flags().enable_samplers);
  EXPECT_TRUE(info_->feature_flags().map_buffer_range);
  EXPECT_TRUE(info_->feature_flags().ext_discard_framebuffer);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_EXT_discard_framebuffer"));
  EXPECT_TRUE(info_->feature_flags().chromium_sync_query);
  EXPECT_TRUE(gfx::GLFence::IsSupported());
}

TEST_F(FeatureInfoTest, InitializeWithoutSamplers) {
  SetupInitExpectationsWithGLVersion("", "", "OpenGL GL 3.0");
  EXPECT_FALSE(info_->feature_flags().enable_samplers);
}

TEST_F(FeatureInfoTest, ParseDriverBugWorkaroundsSingle) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::EXIT_ON_CONTEXT_LOST));
  // Workarounds should get parsed without the need for a context.
  SetupWithCommandLine(command_line);
  EXPECT_TRUE(info_->workarounds().exit_on_context_lost);
}

TEST_F(FeatureInfoTest, ParseDriverBugWorkaroundsMultiple) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::EXIT_ON_CONTEXT_LOST) + "," +
      base::IntToString(gpu::MAX_CUBE_MAP_TEXTURE_SIZE_LIMIT_1024) + "," +
      base::IntToString(gpu::MAX_TEXTURE_SIZE_LIMIT_4096));
  // Workarounds should get parsed without the need for a context.
  SetupWithCommandLine(command_line);
  EXPECT_TRUE(info_->workarounds().exit_on_context_lost);
  EXPECT_EQ(1024, info_->workarounds().max_cube_map_texture_size);
  EXPECT_EQ(4096, info_->workarounds().max_texture_size);
}

TEST_F(FeatureInfoTest, InitializeWithARBSync) {
  SetupInitExpectations("GL_ARB_sync");
  EXPECT_TRUE(info_->feature_flags().chromium_sync_query);
  EXPECT_TRUE(gfx::GLFence::IsSupported());
}

TEST_F(FeatureInfoTest, InitializeWithNVFence) {
  SetupInitExpectations("GL_NV_fence");
  EXPECT_TRUE(info_->feature_flags().chromium_sync_query);
  EXPECT_TRUE(gfx::GLFence::IsSupported());
}

TEST_F(FeatureInfoTest, InitializeWithNVDrawBuffers) {
  SetupInitExpectationsWithGLVersion("GL_NV_draw_buffers", "", "OpenGL ES 3.0");
  EXPECT_TRUE(info_->feature_flags().nv_draw_buffers);
  EXPECT_TRUE(info_->feature_flags().ext_draw_buffers);
}

TEST_F(FeatureInfoTest, InitializeWithPreferredEXTDrawBuffers) {
  SetupInitExpectationsWithGLVersion(
      "GL_NV_draw_buffers GL_EXT_draw_buffers", "", "OpenGL ES 3.0");
  EXPECT_FALSE(info_->feature_flags().nv_draw_buffers);
  EXPECT_TRUE(info_->feature_flags().ext_draw_buffers);
}

TEST_F(FeatureInfoTest, ARBSyncDisabled) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::DISABLE_ARB_SYNC));
  SetupInitExpectationsWithCommandLine("GL_ARB_sync", command_line);
  EXPECT_FALSE(info_->feature_flags().chromium_sync_query);
  EXPECT_FALSE(gfx::GLFence::IsSupported());
}

TEST_F(FeatureInfoTest, InitializeCHROMIUM_path_rendering) {
  SetupInitExpectationsWithGLVersion(
      "GL_NV_path_rendering GL_EXT_direct_state_access", "", "4.3");
  EXPECT_TRUE(info_->feature_flags().chromium_path_rendering);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_path_rendering"));
}

TEST_F(FeatureInfoTest, InitializeCHROMIUM_path_rendering2) {
  SetupInitExpectationsWithGLVersion(
      "GL_NV_path_rendering", "", "OpenGL ES 3.1");
  EXPECT_TRUE(info_->feature_flags().chromium_path_rendering);
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_CHROMIUM_path_rendering"));
}

TEST_F(FeatureInfoTest, InitializeNoCHROMIUM_path_rendering) {
  SetupInitExpectationsWithGLVersion("", "", "4.3");
  EXPECT_FALSE(info_->feature_flags().chromium_path_rendering);
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_path_rendering")));
}

TEST_F(FeatureInfoTest, InitializeNoCHROMIUM_path_rendering2) {
  SetupInitExpectationsWithGLVersion("GL_NV_path_rendering", "", "4.3");
  EXPECT_FALSE(info_->feature_flags().chromium_path_rendering);
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_CHROMIUM_path_rendering")));
}

TEST_F(FeatureInfoTest, InitializeNoKHR_blend_equation_advanced) {
  SetupInitExpectationsWithGLVersion("", "", "4.3");
  EXPECT_FALSE(info_->feature_flags().blend_equation_advanced);
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_KHR_blend_equation_advanced")));
}

TEST_F(FeatureInfoTest, InitializeKHR_blend_equations_advanced) {
  SetupInitExpectations("GL_KHR_blend_equation_advanced");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_KHR_blend_equation_advanced"));
  EXPECT_TRUE(info_->feature_flags().blend_equation_advanced);
}

TEST_F(FeatureInfoTest, InitializeNV_blend_equations_advanced) {
  SetupInitExpectations("GL_NV_blend_equation_advanced");
  EXPECT_THAT(info_->extensions(), HasSubstr("GL_KHR_blend_equation_advanced"));
  EXPECT_TRUE(info_->feature_flags().blend_equation_advanced);
}

TEST_F(FeatureInfoTest, InitializeNoKHR_blend_equation_advanced_coherent) {
  SetupInitExpectationsWithGLVersion("", "", "4.3");
  EXPECT_FALSE(info_->feature_flags().blend_equation_advanced_coherent);
  EXPECT_THAT(info_->extensions(),
              Not(HasSubstr("GL_KHR_blend_equation_advanced_coherent")));
}

TEST_F(FeatureInfoTest, InitializeKHR_blend_equations_advanced_coherent) {
  SetupInitExpectations("GL_KHR_blend_equation_advanced_coherent");
  EXPECT_THAT(info_->extensions(),
              HasSubstr("GL_KHR_blend_equation_advanced_coherent"));
  EXPECT_TRUE(info_->feature_flags().blend_equation_advanced);
  EXPECT_TRUE(info_->feature_flags().blend_equation_advanced_coherent);
}

TEST_F(FeatureInfoTest, InitializeEXT_texture_rgWithFloat) {
  SetupInitExpectations(
      "GL_EXT_texture_rg GL_OES_texture_float GL_OES_texture_half_float");
  EXPECT_TRUE(info_->feature_flags().ext_texture_rg);

  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(GL_R8_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(GL_RG8_EXT));

  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_HALF_FLOAT_OES));
  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_HALF_FLOAT_OES));
  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_UNSIGNED_BYTE));
  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_UNSIGNED_BYTE));

  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_BYTE));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_BYTE));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_SHORT));
  EXPECT_FALSE(info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_SHORT));
}

TEST_F(FeatureInfoTest, InitializeARB_texture_rgNoFloat) {
  SetupInitExpectations("GL_ARB_texture_rg");
  EXPECT_TRUE(info_->feature_flags().ext_texture_rg);

  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->texture_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->texture_internal_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(GL_RED_EXT));
  EXPECT_TRUE(info_->validators()->read_pixel_format.IsValid(GL_RG_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(GL_R8_EXT));
  EXPECT_TRUE(info_->validators()->render_buffer_format.IsValid(GL_RG8_EXT));

  EXPECT_FALSE(
      info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_HALF_FLOAT_OES));
  EXPECT_FALSE(
      info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_HALF_FLOAT_OES));
  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RED_EXT).IsValid(GL_UNSIGNED_BYTE));
  EXPECT_TRUE(
      info_->GetTextureFormatValidator(GL_RG_EXT).IsValid(GL_UNSIGNED_BYTE));
}

}  // namespace gles2
}  // namespace gpu
