// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_

#include <gtk/gtk.h>

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
 * fl_opengl_manager_create_contexts:
 * @manager: an #FlOpenGLManager.
 * @window: the window that is being rendered on.
 * @error: (allow-none): #GError location to store the error occurring, or
 * %NULL to ignore.
 *
 * Create rendering contexts.
 *
 * Returns: %TRUE if contexts were created, %FALSE if there was an error.
 */
gboolean fl_opengl_manager_create_contexts(FlOpenGLManager* manager,
                                           GdkWindow* window,
                                           GError** error);

/**
 * fl_opengl_manager_get_context:
 * @manager: an #FlOpenGLManager.
 *
 * Returns: the main context used for rendering.
 */
GdkGLContext* fl_opengl_manager_get_context(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_make_current:
 * @manager: an #FlOpenGLManager.
 *
 * Makes the rendering context current.
 */
void fl_opengl_manager_make_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_make_resource_current:
 * @manager: an #FlOpenGLManager.
 *
 * Makes the resource rendering context current.
 */
void fl_opengl_manager_make_resource_current(FlOpenGLManager* manager);

/**
 * fl_opengl_manager_clear_current:
 * @manager: an #FlOpenGLManager.
 *
 * Clears the current rendering context.
 */
void fl_opengl_manager_clear_current(FlOpenGLManager* manager);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_MANAGER_H_
