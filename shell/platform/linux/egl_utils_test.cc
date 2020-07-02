// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/egl_utils.h"

TEST(EGLUtils, ErrorToString) {
  const gchar* error_string = egl_error_to_string(EGL_SUCCESS);
  EXPECT_STREQ(error_string, "Success");
}

TEST(EGLUtils, ErrorToStringUnknown) {
  const gchar* error_string = egl_error_to_string(0xffffffff);
  EXPECT_STREQ(error_string, "Unknown Error");
}

TEST(EGLUtils, ErrorToStringNegative) {
  const gchar* error_string = egl_error_to_string(-1);
  EXPECT_STREQ(error_string, "Unknown Error");
}

TEST(EGLUtils, ConfigToString) {
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  EXPECT_TRUE(eglInitialize(display, nullptr, nullptr));
  EGLConfig config;
  EXPECT_TRUE(eglChooseConfig(display, nullptr, &config, 1, nullptr));
  g_autofree gchar* config_string = egl_config_to_string(display, config);
  EXPECT_STREQ(
      config_string,
      "EGL_CONFIG_ID=1 EGL_BUFFER_SIZE=32 EGL_COLOR_BUFFER_TYPE=EGL_RGB_BUFFER "
      "EGL_TRANSPARENT_TYPE=EGL_NONE EGL_LEVEL=1 EGL_RED_SIZE=8 "
      "EGL_GREEN_SIZE=8 EGL_BLUE_SIZE=8 EGL_ALPHA_SIZE=0 EGL_DEPTH_SIZE=0 "
      "EGL_STENCIL_SIZE=0 EGL_SAMPLES=0 EGL_SAMPLE_BUFFERS=0 "
      "EGL_NATIVE_VISUAL_ID=0x1 EGL_NATIVE_VISUAL_TYPE=0x0 "
      "EGL_NATIVE_RENDERABLE=EGL_TRUE EGL_CONFIG_CAVEAT=EGL_NONE "
      "EGL_BIND_TO_TEXTURE_RGB=EGL_TRUE EGL_BIND_TO_TEXTURE_RGBA=EGL_FALSE "
      "EGL_RENDERABLE_TYPE=EGL_OPENGL_ES2_BIT "
      "EGL_CONFORMANT=EGL_OPENGL_ES2_BIT "
      "EGL_SURFACE_TYPE=EGL_PBUFFER_BIT|EGL_WINDOW_BIT "
      "EGL_MAX_PBUFFER_WIDTH=1024 EGL_MAX_PBUFFER_HEIGHT=1024 "
      "EGL_MAX_PBUFFER_PIXELS=1048576 EGL_MIN_SWAP_INTERVAL=0 "
      "EGL_MAX_SWAP_INTERVAL=1000");
}

TEST(EGLUtils, ConfigToStringNullptr) {
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  EXPECT_TRUE(eglInitialize(display, nullptr, nullptr));
  EGLConfig config;
  EXPECT_TRUE(eglChooseConfig(display, nullptr, &config, 1, nullptr));
  g_autofree gchar* config_string1 = egl_config_to_string(nullptr, config);
  EXPECT_STREQ(config_string1, "");
  g_autofree gchar* config_string2 = egl_config_to_string(display, nullptr);
  EXPECT_STREQ(config_string2, "");
  g_autofree gchar* config_string3 = egl_config_to_string(nullptr, nullptr);
  EXPECT_STREQ(config_string3, "");
}
