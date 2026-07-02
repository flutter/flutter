// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_FRAME_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_FRAME_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlOpenGLFrame, fl_opengl_frame, FL, OPENGL_FRAME, GObject)

/**
 * FlOpenGLFrame:
 *
 * #FlOpenGLFrame manages the OpenGL framebuffer a rendered frame is composited
 * into and presented from.
 *
 * When the frame can be shared between OpenGL contexts (EGL) the framebuffer is
 * presented directly. Otherwise (GLX) the composited frame is copied into a CPU
 * buffer so it can be re-uploaded in the presenting context.
 */

/**
 * fl_opengl_frame_new:
 * @shareable: %TRUE if the frame can be shared between OpenGL contexts (EGL),
 * %FALSE if it must be copied via CPU memory (GLX).
 *
 * Creates a new object that manages the framebuffer (and CPU pixel copy when
 * not shareable) a rendered frame is composited into.
 *
 * Returns: a new #FlOpenGLFrame.
 */
FlOpenGLFrame* fl_opengl_frame_new(gboolean shareable);

/**
 * fl_opengl_frame_composite:
 * @frame: an #FlOpenGLFrame.
 * @compositor: the #FlCompositorOpenGL to composite with.
 * @layers: layers to composite.
 * @layers_count: number of layers.
 *
 * Composites @layers into the frame, (re)creating the underlying framebuffer to
 * match the frame size and copying the result into CPU memory when the frame is
 * not shareable. Must be called with an OpenGL context current.
 */
void fl_opengl_frame_composite(FlOpenGLFrame* frame,
                               FlCompositorOpenGL* compositor,
                               const FlutterLayer** layers,
                               size_t layers_count);

/**
 * fl_opengl_frame_get_size:
 * @frame: an #FlOpenGLFrame.
 * @width: (out): location for the width in pixels.
 * @height: (out): location for the height in pixels.
 *
 * Gets the size of the current frame in pixels. The size is zero if no frame
 * has been composited yet.
 */
void fl_opengl_frame_get_size(FlOpenGLFrame* frame,
                              size_t* width,
                              size_t* height);

/**
 * fl_opengl_frame_draw:
 * @frame: an #FlOpenGLFrame.
 * @cr: the Cairo context to draw into.
 * @window: the #GdkWindow being drawn.
 * @scale_factor: the window scale factor.
 * @width: the width to draw in pixels.
 * @height: the height to draw in pixels.
 *
 * Draws the current frame into @cr. Must be called with an OpenGL context
 * current.
 *
 * Returns: %TRUE if a frame was drawn.
 */
gboolean fl_opengl_frame_draw(FlOpenGLFrame* frame,
                              cairo_t* cr,
                              GdkWindow* window,
                              gint scale_factor,
                              size_t width,
                              size_t height);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_OPENGL_FRAME_H_
