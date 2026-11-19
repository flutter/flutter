// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_SHADER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_SHADER_H_

#include <glib-object.h>

#include "flutter/shell/platform/linux/fl_opengl_manager.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorOpenGLShader,
                     fl_compositor_opengl_shader,
                     FL,
                     COMPOSITOR_OPENGL_SHADER,
                     GObject)

/**
 * FlCompositorOpenGLShader:
 *
 * #FlCompositorOpenGLShader is the shader program used by #FlCompositorOpenGL
 * to composite Flutter layers onto the framebuffer.
 */

/**
 * fl_compositor_opengl_shader_new:
 * @opengl_manager: an #FlOpenGLManager.
 *
 * Creates and compiles the compositor shader program. Requires a valid OpenGL
 * context to create.
 *
 * Returns: a new #FlCompositorOpenGLShader.
 */
FlCompositorOpenGLShader* fl_compositor_opengl_shader_new(
    FlOpenGLManager* opengl_manager);

/**
 * fl_compositor_opengl_shader_use:
 * @shader: an #FlCompositorOpenGLShader.
 *
 * Binds the shader's vertex buffer, configures the vertex attributes and makes
 * the program current. Requires a valid OpenGL context.
 */
void fl_compositor_opengl_shader_use(FlCompositorOpenGLShader* shader);

/**
 * fl_compositor_opengl_shader_set_offset:
 * @shader: an #FlCompositorOpenGLShader.
 * @x: horizontal offset.
 * @y: vertical offset.
 *
 * Sets the layer offset uniform. The program must be current (see
 * fl_compositor_opengl_shader_use).
 */
void fl_compositor_opengl_shader_set_offset(FlCompositorOpenGLShader* shader,
                                            double x,
                                            double y);

/**
 * fl_compositor_opengl_shader_set_scale:
 * @shader: an #FlCompositorOpenGLShader.
 * @x: horizontal scale.
 * @y: vertical scale.
 *
 * Sets the layer scale uniform. The program must be current (see
 * fl_compositor_opengl_shader_use).
 */
void fl_compositor_opengl_shader_set_scale(FlCompositorOpenGLShader* shader,
                                           double x,
                                           double y);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_SHADER_H_
