// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_VULKAN_H_
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_texture_gl_private.h"
#include "flutter/shell/platform/linux/fl_vulkan_manager.h"

// Probe the raster context before the engine starts using it on another thread.
const gchar* fl_gl_texture_check_vulkan_import(FlOpenGLManager* gl);

bool fl_gl_texture_populate_vulkan(FlTextureGL* texture,
                                   FlOpenGLManager* gl,
                                   FlVulkanManager* vk,
                                   uint32_t width,
                                   uint32_t height,
                                   FlutterVulkanExternalTexture* output);
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_VULKAN_H_
