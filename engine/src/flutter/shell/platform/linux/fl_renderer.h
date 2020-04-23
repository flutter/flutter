// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_

#include <EGL/egl.h>

#include <glib-object.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

G_BEGIN_DECLS

/**
 * FlRendererError:
 * Errors for #FlRenderer objects to set on failures.
 */

typedef enum {
  FL_RENDERER_ERROR_FAILED,
} FlRendererError;

GQuark fl_renderer_error_quark(void) G_GNUC_CONST;

G_DECLARE_DERIVABLE_TYPE(FlRenderer, fl_renderer, FL, RENDERER, GObject)

/**
 * FlRenderer:
 *
 * #FlRenderer is an abstract class that allows Flutter to draw pixels.
 */

struct _FlRendererClass {
  GObjectClass parent_class;

  // Virtual methods
  gboolean (*start)(FlRenderer* renderer, GError** error);
  EGLSurface (*create_surface)(FlRenderer* renderer,
                               EGLDisplay display,
                               EGLConfig config);
};

G_END_DECLS

/**
 * fl_renderer_start:
 * @renderer: a #FlRenderer
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Returns: %TRUE if successfully started.
 */
gboolean fl_renderer_start(FlRenderer* self, GError** error);

/**
 * fl_renderer_get_proc_address:
 * @renderer: a #FlRenderer
 * @name: a function name
 *
 * Gets the rendering API function that matches the given name.
 *
 * Returns: a function pointer
 */
void* fl_renderer_get_proc_address(FlRenderer* renderer, const char* name);

/**
 * fl_renderer_make_current:
 * @renderer: a #FlRenderer
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Makes the rendering context current.
 *
 * Returns %TRUE if successful
 */
gboolean fl_renderer_make_current(FlRenderer* renderer, GError** error);

/**
 * fl_renderer_clear_current:
 * @renderer: a #FlRenderer
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Clears the current rendering context.
 *
 * Returns %TRUE if successful
 */
gboolean fl_renderer_clear_current(FlRenderer* renderer, GError** error);

/**
 * fl_renderer_get_fbo:
 * @renderer: a #FlRenderer
 *
 * Gets the frame buffer object to render to.
 *
 * Returns: a frame buffer object index
 */
guint32 fl_renderer_get_fbo(FlRenderer* renderer);

/**
 * fl_renderer_present:
 * @renderer: a #FlRenderer
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Presents the current frame.
 *
 * Returns %TRUE if successful
 */
gboolean fl_renderer_present(FlRenderer* renderer, GError** error);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_H_
