// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_swangle_utils.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <cstring>

#include "flutter/fml/logging.h"

namespace flutter::testing {

namespace {

bool HasExtension(const char* extensions, const char* name) {
  const char* r = strstr(extensions, name);
  auto len = strlen(name);
  // check that the extension name is terminated by space or null terminator
  return r != nullptr && (r[len] == ' ' || r[len] == 0);
}

}  // namespace

EGLDisplay CreateSwangleDisplay() {
  const char* extensions = ::eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);

  if (!extensions) {
    FML_LOG(ERROR) << "Could not query EGL extensions.";
    return EGL_NO_DISPLAY;
  }

  if (!HasExtension(extensions, "EGL_EXT_platform_base")) {
    FML_LOG(ERROR) << "EGL_EXT_platform_base extension not available";
    return EGL_NO_DISPLAY;
  }

  if (!HasExtension(extensions, "EGL_ANGLE_platform_angle_vulkan")) {
    FML_LOG(ERROR) << "EGL_ANGLE_platform_angle_vulkan extension not available";
    return EGL_NO_DISPLAY;
  }

  if (!HasExtension(extensions,
                    "EGL_ANGLE_platform_angle_device_type_swiftshader")) {
    FML_LOG(ERROR) << "EGL_ANGLE_platform_angle_device_type_swiftshader "
                      "extension not available";
    return EGL_NO_DISPLAY;
  }

  PFNEGLGETPLATFORMDISPLAYEXTPROC egl_get_platform_display_EXT =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));

  if (!egl_get_platform_display_EXT) {
    FML_LOG(ERROR) << "eglGetPlatformDisplayEXT not available.";
    return EGL_NO_DISPLAY;
  }

  const EGLint display_config[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_SWIFTSHADER_ANGLE,
      EGL_PLATFORM_ANGLE_NATIVE_PLATFORM_TYPE_ANGLE,
      EGL_PLATFORM_VULKAN_DISPLAY_MODE_HEADLESS_ANGLE,
      EGL_NONE,
  };

  return egl_get_platform_display_EXT(
      EGL_PLATFORM_ANGLE_ANGLE,
      reinterpret_cast<EGLNativeDisplayType*>(EGL_DEFAULT_DISPLAY),
      display_config);
}

}  // namespace flutter::testing
