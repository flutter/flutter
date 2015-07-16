// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <vector>

#include "base/containers/small_map.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/stringprintf.h"
#include "gpu/perftests/measurements.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/perf/perf_test.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/geometry/vector2d_f.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_enums.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_version_info.h"
#include "ui/gl/gpu_timing.h"
#include "ui/gl/scoped_make_current.h"

namespace gpu {
namespace {

const int kUploadPerfWarmupRuns = 5;
const int kUploadPerfTestRuns = 30;

#define SHADER(Src) #Src

// clang-format off
const char kVertexShader[] =
SHADER(
  uniform vec2 translation;
  attribute vec2 a_position;
  attribute vec2 a_texCoord;
  varying vec2 v_texCoord;
  void main() {
    gl_Position = vec4(
        translation.x + a_position.x, translation.y + a_position.y, 0.0, 1.0);
    v_texCoord = a_texCoord;
  }
);
const char kShaderDefaultFloatPrecision[] =
SHADER(
  precision mediump float;
);
const char kFragmentShader[] =
SHADER(
  uniform sampler2D a_texture;
  varying vec2 v_texCoord;
  void main() {
    gl_FragColor = texture2D(a_texture, v_texCoord);
  }
);
// clang-format on

void CheckNoGlError(const std::string& msg) {
  CHECK_EQ(static_cast<GLenum>(GL_NO_ERROR), glGetError()) << " " << msg;
}

// Utility function to compile a shader from a string.
GLuint LoadShader(const GLenum type, const char* const src) {
  GLuint shader = 0;
  shader = glCreateShader(type);
  CHECK_NE(0u, shader);
  glShaderSource(shader, 1, &src, NULL);
  glCompileShader(shader);

  GLint compiled = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
  if (compiled == 0) {
    GLint len = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
    if (len > 1) {
      scoped_ptr<char> error_log(new char[len]);
      glGetShaderInfoLog(shader, len, NULL, error_log.get());
      LOG(ERROR) << "Error compiling shader: " << error_log.get();
    }
  }
  CHECK_NE(0, compiled);
  return shader;
}

int GLFormatBytePerPixel(GLenum format) {
  DCHECK(format == GL_RGBA || format == GL_LUMINANCE || format == GL_RED_EXT);
  return format == GL_RGBA ? 4 : 1;
}

GLenum GLFormatToInternalFormat(GLenum format) {
  return format == GL_RED ? GL_R8 : format;
}

GLenum GLFormatToStorageFormat(GLenum format) {
  switch (format) {
    case GL_RGBA:
      return GL_RGBA8;
    case GL_LUMINANCE:
      return GL_LUMINANCE8;
    case GL_RED:
      return GL_R8;
    default:
      NOTREACHED();
  }
  return 0;
}

void GenerateTextureData(const gfx::Size& size,
                         int bytes_per_pixel,
                         const int seed,
                         std::vector<uint8>* const pixels) {
  // Row bytes has to be multiple of 4 (GL_PACK_ALIGNMENT defaults to 4).
  int stride = ((size.width() * bytes_per_pixel) + 3) & ~0x3;
  pixels->resize(size.height() * stride);
  for (int y = 0; y < size.height(); ++y) {
    for (int x = 0; x < size.width(); ++x) {
      for (int channel = 0; channel < bytes_per_pixel; ++channel) {
        int index = y * stride + x * bytes_per_pixel;
        pixels->at(index) = (index + (seed << 2)) % (0x20 << channel);
      }
    }
  }
}

// Compare a buffer containing pixels in a specified format to GL_RGBA buffer
// where the former buffer have been uploaded as a texture and drawn on the
// RGBA buffer.
bool CompareBufferToRGBABuffer(GLenum format,
                               const gfx::Size& size,
                               const std::vector<uint8>& pixels,
                               const std::vector<uint8>& rgba) {
  int bytes_per_pixel = GLFormatBytePerPixel(format);
  int pixels_stride = ((size.width() * bytes_per_pixel) + 3) & ~0x3;
  int rgba_stride = size.width() * GLFormatBytePerPixel(GL_RGBA);
  for (int y = 0; y < size.height(); ++y) {
    for (int x = 0; x < size.width(); ++x) {
      int rgba_index = y * rgba_stride + x * GLFormatBytePerPixel(GL_RGBA);
      int pixels_index = y * pixels_stride + x * bytes_per_pixel;
      uint8 expected[4] = {0};
      switch (format) {
        case GL_LUMINANCE:  // (L_t, L_t, L_t, 1)
          expected[1] = pixels[pixels_index];
          expected[2] = pixels[pixels_index];
        case GL_RED:  // (R_t, 0, 0, 1)
          expected[0] = pixels[pixels_index];
          expected[3] = 255;
          break;
        case GL_RGBA:  // (R_t, G_t, B_t, A_t)
          memcpy(expected, &pixels[pixels_index], 4);
          break;
        default:
          NOTREACHED();
      }
      if (memcmp(&rgba[rgba_index], expected, 4)) {
        return false;
      }
    }
  }
  return true;
}

// PerfTest to check costs of texture upload at different stages
// on different platforms.
class TextureUploadPerfTest : public testing::Test {
 public:
  TextureUploadPerfTest() : fbo_size_(1024, 1024) {}

  // Overridden from testing::Test
  void SetUp() override {
    static bool gl_initialized = gfx::GLSurface::InitializeOneOff();
    DCHECK(gl_initialized);
    // Initialize an offscreen surface and a gl context.
    surface_ = gfx::GLSurface::CreateOffscreenGLSurface(gfx::Size(4, 4));
    gl_context_ = gfx::GLContext::CreateGLContext(NULL,  // share_group
                                                  surface_.get(),
                                                  gfx::PreferIntegratedGpu);
    ui::ScopedMakeCurrent smc(gl_context_.get(), surface_.get());
    glGenTextures(1, &color_texture_);
    glBindTexture(GL_TEXTURE_2D, color_texture_);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fbo_size_.width(),
                 fbo_size_.height(), 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);

    glGenFramebuffersEXT(1, &framebuffer_object_);
    glBindFramebufferEXT(GL_FRAMEBUFFER, framebuffer_object_);

    glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_TEXTURE_2D, color_texture_, 0);
    DCHECK_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE),
              glCheckFramebufferStatusEXT(GL_FRAMEBUFFER));

    glViewport(0, 0, fbo_size_.width(), fbo_size_.height());
    gpu_timing_client_ = gl_context_->CreateGPUTimingClient();

    if (gpu_timing_client_->IsAvailable()) {
      LOG(INFO) << "Gpu timing initialized with timer type: "
                << gpu_timing_client_->GetTimerTypeName();
      gpu_timing_client_->InvalidateTimerOffset();
    } else {
      LOG(WARNING) << "Can't initialize gpu timing";
    }
    // Prepare a simple program and a vertex buffer that will be
    // used to draw a quad on the offscreen surface.
    vertex_shader_ = LoadShader(GL_VERTEX_SHADER, kVertexShader);

    bool is_gles = gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2;
    fragment_shader_ = LoadShader(
        GL_FRAGMENT_SHADER,
        base::StringPrintf("%s%s", is_gles ? kShaderDefaultFloatPrecision : "",
                           kFragmentShader).c_str());
    program_object_ = glCreateProgram();
    CHECK_NE(0u, program_object_);

    glAttachShader(program_object_, vertex_shader_);
    glAttachShader(program_object_, fragment_shader_);
    glBindAttribLocation(program_object_, 0, "a_position");
    glBindAttribLocation(program_object_, 1, "a_texCoord");
    glLinkProgram(program_object_);

    GLint linked = -1;
    glGetProgramiv(program_object_, GL_LINK_STATUS, &linked);
    CHECK_NE(0, linked);
    glUseProgram(program_object_);
    glUniform1i(sampler_location_, 0);
    translation_location_ =
        glGetUniformLocation(program_object_, "translation");
    DCHECK_NE(-1, translation_location_);
    glUniform2f(translation_location_, 0.0f, 0.0f);

    sampler_location_ = glGetUniformLocation(program_object_, "a_texture");
    CHECK_NE(-1, sampler_location_);

    glGenBuffersARB(1, &vertex_buffer_);
    CHECK_NE(0u, vertex_buffer_);
    DCHECK_NE(0u, vertex_buffer_);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, 0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4,
                          reinterpret_cast<void*>(sizeof(GLfloat) * 2));
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    CheckNoGlError("glEnableVertexAttribArray");

    has_texture_storage_ =
        gl_context_->GetVersionInfo()->is_es3 ||
        gl_context_->HasExtension("GL_EXT_texture_storage") ||
        gl_context_->HasExtension("GL_ARB_texture_storage");
  }

  void GenerateVertexBuffer(const gfx::Size& size) {
    DCHECK_NE(0u, vertex_buffer_);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_);
    // right and top are in clipspace
    float right = -1.f + 2.f * size.width() / fbo_size_.width();
    float top = -1.f + 2.f * size.height() / fbo_size_.height();
    // Four vertexes, one per line. Each vertex has two components per
    // position and two per texcoord.
    // It represents a quad formed by two triangles if interpreted
    // as a tristrip.

    // clang-format off
    GLfloat data[16] = {
      -1.f, -1.f,    0.f, 0.f,
      right, -1.f,   1.f, 0.f,
      -1.f, top,     0.f, 1.f,
      right, top,    1.f, 1.f};
    // clang-format on
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);
    CheckNoGlError("glBufferData");
  }

  void TearDown() override {
    ui::ScopedMakeCurrent smc(gl_context_.get(), surface_.get());
    glDeleteProgram(program_object_);
    glDeleteShader(vertex_shader_);
    glDeleteShader(fragment_shader_);
    glDeleteBuffersARB(1, &vertex_buffer_);

    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
    glDeleteFramebuffersEXT(1, &framebuffer_object_);
    glDeleteTextures(1, &color_texture_);
    CheckNoGlError("glDeleteTextures");

    gpu_timing_client_ = nullptr;
    gl_context_ = nullptr;
    surface_ = nullptr;
  }

 protected:
  GLuint CreateGLTexture(const GLenum format,
                         const gfx::Size& size,
                         const bool specify_storage) {
    GLuint texture_id = 0;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    if (specify_storage) {
      if (has_texture_storage_) {
        glTexStorage2DEXT(GL_TEXTURE_2D, 1, GLFormatToStorageFormat(format),
                          size.width(), size.height());
        CheckNoGlError("glTexStorage2DEXT");
      } else {
        glTexImage2D(GL_TEXTURE_2D, 0, GLFormatToInternalFormat(format),
                     size.width(), size.height(), 0, format, GL_UNSIGNED_BYTE,
                     nullptr);
        CheckNoGlError("glTexImage2D");
      }
    }
    return texture_id;
  }

  void UploadTexture(GLuint texture_id,
                     const gfx::Size& size,
                     const std::vector<uint8>& pixels,
                     GLenum format,
                     const bool subimage) {
    if (subimage) {
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, size.width(), size.height(),
                      format, GL_UNSIGNED_BYTE, &pixels[0]);
      CheckNoGlError("glTexSubImage2D");
    } else {
      glTexImage2D(GL_TEXTURE_2D, 0, GLFormatToInternalFormat(format),
                   size.width(), size.height(), 0, format, GL_UNSIGNED_BYTE,
                   &pixels[0]);
      CheckNoGlError("glTexImage2D");
    }
  }

  // Upload and draw on the offscren surface.
  // Return a list of pair. Each pair describe a gl operation and the wall
  // time elapsed in milliseconds.
  std::vector<Measurement> UploadAndDraw(GLuint texture_id,
                                         const gfx::Size& size,
                                         const std::vector<uint8>& pixels,
                                         const GLenum format,
                                         const bool subimage) {
    MeasurementTimers tex_timers(gpu_timing_client_.get());
    UploadTexture(texture_id, size, pixels, format, subimage);
    tex_timers.Record();

    MeasurementTimers draw_timers(gpu_timing_client_.get());

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    draw_timers.Record();

    MeasurementTimers finish_timers(gpu_timing_client_.get());
    glFinish();
    CheckNoGlError("glFinish");
    finish_timers.Record();

    std::vector<uint8> pixels_rendered(size.GetArea() * 4);
    glReadPixels(0, 0, size.width(), size.height(), GL_RGBA, GL_UNSIGNED_BYTE,
                 &pixels_rendered[0]);
    CheckNoGlError("glReadPixels");
    EXPECT_TRUE(
        CompareBufferToRGBABuffer(format, size, pixels, pixels_rendered))
        << "Format is: " << gfx::GLEnums::GetStringEnum(format);

    std::vector<Measurement> measurements;
    bool gpu_timer_errors =
        gpu_timing_client_->IsAvailable() &&
        gpu_timing_client_->CheckAndResetTimerErrors();
    if (!gpu_timer_errors) {
      measurements.push_back(tex_timers.GetAsMeasurement(
          subimage ? "texsubimage2d" : "teximage2d"));
      measurements.push_back(draw_timers.GetAsMeasurement("drawarrays"));
      measurements.push_back(finish_timers.GetAsMeasurement("finish"));
    }
    return measurements;
  }

  void RunUploadAndDrawMultipleTimes(const gfx::Size& size,
                                     const GLenum format,
                                     const bool subimage) {
    std::vector<uint8> pixels;
    base::SmallMap<std::map<std::string, Measurement>>
        aggregates;  // indexed by name
    int successful_runs = 0;
    GLuint texture_id = CreateGLTexture(format, size, subimage);
    for (int i = 0; i < kUploadPerfWarmupRuns + kUploadPerfTestRuns; ++i) {
      GenerateTextureData(size, GLFormatBytePerPixel(format), i + 1, &pixels);
      auto run = UploadAndDraw(texture_id, size, pixels, format, subimage);
      if (i < kUploadPerfWarmupRuns || !run.size()) {
        continue;
      }
      successful_runs++;
      for (const Measurement& measurement : run) {
        auto& aggregate = aggregates[measurement.name];
        aggregate.name = measurement.name;
        aggregate.Increment(measurement);
      }
    }
    glDeleteTextures(1, &texture_id);

    std::string graph_name = base::StringPrintf(
        "%d_%s", size.width(), gfx::GLEnums::GetStringEnum(format).c_str());
    if (subimage) {
      graph_name += "_sub";
    }

    if (successful_runs) {
      for (const auto& entry : aggregates) {
        const auto m = entry.second.Divide(successful_runs);
        m.PrintResult(graph_name);
      }
    }
    perf_test::PrintResult("sample_runs", "", graph_name,
                           static_cast<size_t>(successful_runs), "laps", true);
  }

  const gfx::Size fbo_size_;  // for the fbo
  scoped_refptr<gfx::GLContext> gl_context_;
  scoped_refptr<gfx::GLSurface> surface_;
  scoped_refptr<gfx::GPUTimingClient> gpu_timing_client_;

  GLuint color_texture_ = 0;
  GLuint framebuffer_object_ = 0;
  GLuint vertex_shader_ = 0;
  GLuint fragment_shader_ = 0;
  GLuint program_object_ = 0;
  GLint sampler_location_ = -1;
  GLint translation_location_ = -1;
  GLuint vertex_buffer_ = 0;

  bool has_texture_storage_ = false;
};

// Perf test that generates, uploads and draws a texture on a surface repeatedly
// and prints out aggregated measurements for all the runs.
TEST_F(TextureUploadPerfTest, upload) {
  int sizes[] = {21, 128, 256, 512, 1024};
  std::vector<GLenum> formats;
  formats.push_back(GL_RGBA);

  if (!gl_context_->GetVersionInfo()->is_es3) {
    // Used by default for ResourceProvider::yuv_resource_format_.
    formats.push_back(GL_LUMINANCE);
  }

  ui::ScopedMakeCurrent smc(gl_context_.get(), surface_.get());
  const bool has_texture_rg = gl_context_->GetVersionInfo()->is_es3 ||
                              gl_context_->HasExtension("GL_EXT_texture_rg") ||
                              gl_context_->HasExtension("GL_ARB_texture_rg");

  if (has_texture_rg) {
    // Used as ResourceProvider::yuv_resource_format_ if
    // {ARB,EXT}_texture_rg are available.
    formats.push_back(GL_RED);
  }

  for (int side : sizes) {
    ASSERT_GE(fbo_size_.width(), side);
    ASSERT_GE(fbo_size_.height(), side);
    gfx::Size size(side, side);
    GenerateVertexBuffer(size);
    for (GLenum format : formats) {
      RunUploadAndDrawMultipleTimes(size, format, true);  // use glTexSubImage2D
      RunUploadAndDrawMultipleTimes(size, format, false);  // use glTexImage2D
    }
  }
}

// Perf test to check if the driver is doing texture renaming.
// This test creates one GL texture_id and four different images. For
// every image it uploads it using texture_id and it draws multiple
// times. The cpu/wall time and the gpu time for all the uploads and
// draws, but before glFinish, is computed and is printed out at the end as
// "upload_and_draw". If the gpu time is >> than the cpu/wall time we expect the
// driver to do texture renaming: this means that while the gpu is drawing using
// texture_id it didn't block cpu side the texture upload using the same
// texture_id.
TEST_F(TextureUploadPerfTest, renaming) {
  gfx::Size texture_size(fbo_size_.width() / 2, fbo_size_.height() / 2);

  std::vector<uint8> pixels[4];
  for (int i = 0; i < 4; ++i) {
    GenerateTextureData(texture_size, 4, i + 1, &pixels[i]);
  }

  ui::ScopedMakeCurrent smc(gl_context_.get(), surface_.get());
  GenerateVertexBuffer(texture_size);

  gfx::Vector2dF positions[] = {gfx::Vector2dF(0.f, 0.f),
                                gfx::Vector2dF(1.f, 0.f),
                                gfx::Vector2dF(0.f, 1.f),
                                gfx::Vector2dF(1.f, 1.f)};
  GLuint texture_id = CreateGLTexture(GL_RGBA, texture_size, true);

  MeasurementTimers upload_and_draw_timers(gpu_timing_client_.get());

  for (int i = 0; i < 4; ++i) {
    UploadTexture(texture_id, texture_size, pixels[i % 4], GL_RGBA, true);
    DCHECK_NE(-1, translation_location_);
    glUniform2f(translation_location_, positions[i % 4].x(),
                positions[i % 4].y());
    // Draw the same quad multiple times to make sure that the time spent on the
    // gpu is more than the cpu time.
    for (int draw = 0; draw < 128; ++draw) {
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
  }

  upload_and_draw_timers.Record();
  MeasurementTimers finish_timers(gpu_timing_client_.get());
  glFinish();
  CheckNoGlError("glFinish");
  finish_timers.Record();

  glDeleteTextures(1, &texture_id);

  for (int i = 0; i < 4; ++i) {
    std::vector<uint8> pixels_rendered(texture_size.GetArea() * 4);
    glReadPixels(texture_size.width() * positions[i].x(),
                 texture_size.height() * positions[i].y(), texture_size.width(),
                 texture_size.height(), GL_RGBA, GL_UNSIGNED_BYTE,
                 &pixels_rendered[0]);
    CheckNoGlError("glReadPixels");
    ASSERT_EQ(pixels[i].size(), pixels_rendered.size());
    EXPECT_EQ(pixels[i], pixels_rendered);
  }

  bool gpu_timer_errors = gpu_timing_client_->IsAvailable() &&
                          gpu_timing_client_->CheckAndResetTimerErrors();
  if (!gpu_timer_errors) {
    upload_and_draw_timers.GetAsMeasurement("upload_and_draw")
        .PrintResult("renaming");
    finish_timers.GetAsMeasurement("finish").PrintResult("renaming");
  }
}

}  // namespace
}  // namespace gpu
