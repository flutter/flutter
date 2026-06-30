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
 */

/**
 * FlCompositorOpenGLFrameSharing:
 * @FL_COMPOSITOR_OPENGL_FRAME_SHARING_EGL_IMAGE: the rendered frame is shared
 * with the consuming context using an EGLImage. Used when the consumer renders
 * with a separate, non-shared EGL context (e.g. GTK's GL context on Wayland).
 * @FL_COMPOSITOR_OPENGL_FRAME_SHARING_SHARED_CONTEXT: the consuming context
 * shares resources with the engine context, so the frame's texture is accessed
 * directly without an EGLImage.
 * @FL_COMPOSITOR_OPENGL_FRAME_SHARING_CPU_COPY: the rendered frame is copied to
 * CPU memory. Used when the contexts cannot share textures (e.g. GLX on X11).
 */
typedef enum {
  FL_COMPOSITOR_OPENGL_FRAME_SHARING_EGL_IMAGE,
  FL_COMPOSITOR_OPENGL_FRAME_SHARING_SHARED_CONTEXT,
  FL_COMPOSITOR_OPENGL_FRAME_SHARING_CPU_COPY,
} FlCompositorOpenGLFrameSharing;

/**
 * fl_compositor_opengl_new:
 * @opengl_manager: an #FlOpenGLManager
 * @frame_sharing: how rendered frames are shared with the consuming context.
 *
 * Creates a new OpenGL compositor.
 *
 * Returns: a new #FlCompositorOpenGL.
 */
FlCompositorOpenGL* fl_compositor_opengl_new(
    FlOpenGLManager* opengl_manager,
    FlCompositorOpenGLFrameSharing frame_sharing);

/**
 * fl_compositor_opengl_present_layers:
 * @compositor: an #FlCompositorOpenGL.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Composite layers. Called from the Flutter rendering thread.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_opengl_present_layers(FlCompositorOpenGL* compositor,
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
 * fl_compositor_opengl_get_framebuffer:
 * @compositor: an #FlCompositorOpenGL.
 *
 * Get the framebuffer containing the last composited frame, or %NULL if no
 * frame has been composited.
 *
 * Returns: (nullable): an #FlFramebuffer.
 */
FlFramebuffer* fl_compositor_opengl_get_framebuffer(
    FlCompositorOpenGL* compositor);

/**
 * fl_compositor_opengl_render:
 * @compositor: an #FlCompositorOpenGL.
 * @cr: a Cairo rendering context.
 * @window: window being rendered into.
 *
 * Renders the current frame. Called from the GTK thread.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_opengl_render(FlCompositorOpenGL* compositor,
                                     cairo_t* cr,
                                     GdkWindow* window);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_H_
