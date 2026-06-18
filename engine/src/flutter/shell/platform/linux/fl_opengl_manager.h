// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_

#include <epoxy/gl.h>
#include <glib-object.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlOpenGLManager,
                     fl_opengl_manager,
                     FL,
                     OPENGL_MANAGER,
                     GObject)

/**
 * fl_opengl_manager_new:
 *
 * Creates an object that allows Flutter to render by OpenGL ES.
 *
 * Returns: a new #FlOpenGLManager.
 */
FlOpenGLManager* fl_opengl_manager_new();

/**
 * fl_opengl_manager_make_current:
 * @manager: an #FlOpenGLManager.
 *
 * Makes the rendering context current.
 *
 * Returns: %TRUE if the context made current.
 */
gboolean fl_opengl_manager_make_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_make_resource_current:
 * @manager: an #FlOpenGLManager.
 *
 * Makes the resource rendering context current.
 *
 * Returns: %TRUE if the context made current.
 */
gboolean fl_opengl_manager_make_resource_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_make_platform_current:
 * @manager: an #FlOpenGLManager.
 *
 * Makes the platform rendering context current.
 *
 * Returns: %TRUE if the context made current.
 */
gboolean fl_opengl_manager_make_platform_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_clear_current:
 * @manager: an #FlOpenGLManager.
 *
 * Clears the current rendering context.
 *
 * Returns: %TRUE if the context cleared.
 */
gboolean fl_opengl_manager_clear_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_get_program:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the shader program used for rendering Flutter content.
 *
 * Returns: the shader program.
 */
GLuint fl_opengl_manager_get_program(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_get_vertex_buffer:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the vertex buffer object containing vertices for a uniform square.
 *
 * Returns: the vertex buffer object.
 */
GLuint fl_opengl_manager_get_vertex_buffer(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_get_offset_location:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the location of the offset uniform in the shader program.
 *
 * Returns: the location of the offset uniform.
 */
GLuint fl_opengl_manager_get_offset_location(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_get_scale_location:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the location of the scale uniform in the shader program.
 *
 * Returns: the location of the scale uniform.
 */
GLuint fl_opengl_manager_get_scale_location(FlOpenGLManager* manager);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
