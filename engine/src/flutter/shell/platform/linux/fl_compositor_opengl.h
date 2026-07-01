// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorOpenGL,
                     fl_compositor_opengl,
                     FL,
                     COMPOSITOR_OPENGL,
                     GObject)

/**
 * FlCompositorOpenGL:
 *
 * #FlCompositorOpenGL is class that implements compositing using OpenGL.
 *
 * The composited frame is stored in an OpenGL framebuffer (texture).
 *
 * A frame may be written by fl_compositor_opengl_composite_layers using one
 * OpenGL context and read by fl_compositor_opengl_render using another. When
 * the compositor is created as shareable the two contexts must belong to the
 * same share group so the frame texture can be accessed from both, and the
 * writing context issues a glFlush() so the frame is visible to the reading
 * context. When not shareable the frame is copied to CPU memory by the writing
 * context and uploaded into a new texture by the reading context.
 */

/**
 * fl_compositor_opengl_new:
 * @opengl_manager: an #FlOpenGLManager
 * @shareable: %TRUE if the can use a framebuffer that is shared between
 * contexts.
 *
 * Creates a new OpenGL compositor.
 *
 * Returns: a new #FlCompositorOpenGL.
 */
FlCompositorOpenGL* fl_compositor_opengl_new(FlOpenGLManager* opengl_manager,
                                             gboolean shareable);

/**
 * fl_compositor_opengl_composite_layers:
 * @compositor: an #FlCompositorOpenGL.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Composite layers into the stored frame using the current OpenGL context.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_opengl_composite_layers(FlCompositorOpenGL* compositor,
                                               const FlutterLayer** layers,
                                               size_t layers_count);

/**
 * fl_compositor_opengl_get_frame_size:
 * @compositor: an #FlCompositorOpenGL.
 * @width: location to write frame width in pixels.
 * @height: location to write frame height in pixels.
 *
 * Get the size of the layer ready for rendering.
 */
void fl_compositor_opengl_get_frame_size(FlCompositorOpenGL* compositor,
                                         size_t* width,
                                         size_t* height);

/**
 * fl_compositor_opengl_render:
 * @compositor: an #FlCompositorOpenGL.
 * @cr: a Cairo rendering context.
 * @window: window being rendered into.
 *
 * Renders the current frame using the current OpenGL context.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_opengl_render(FlCompositorOpenGL* compositor,
                                     cairo_t* cr,
                                     GdkWindow* window);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_H_
