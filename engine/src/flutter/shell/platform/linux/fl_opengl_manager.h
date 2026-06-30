// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_

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
 * fl_opengl_manager_get_display:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the EGL display the engine renders to. This can be used to create
 * additional EGL contexts that share resources with the engine.
 *
 * Returns: an %EGLDisplay.
 */
gpointer fl_opengl_manager_get_display(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_get_context:
 * @manager: an #FlOpenGLManager.
 *
 * Gets the EGL context the engine renders with. This can be used as a share
 * context when creating additional EGL contexts so they can access textures
 * rendered by the engine directly (without using EGLImage).
 *
 * Returns: an %EGLContext.
 */
gpointer fl_opengl_manager_get_context(FlOpenGLManager* manager);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
