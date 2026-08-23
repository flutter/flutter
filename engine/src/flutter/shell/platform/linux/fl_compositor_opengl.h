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
 * #FlCompositorOpenGL is a class that implements compositing using OpenGL.
 *
 * Layers are composited into the OpenGL framebuffer bound to the current
 * OpenGL context. The caller is responsible for binding the target framebuffer
 * and for reading the composited frame back if required.
 */

/**
 * fl_compositor_opengl_new:
 * @opengl_manager: an #FlOpenGLManager
 *
 * Creates a new OpenGL compositor.
 *
 * Returns: a new #FlCompositorOpenGL.
 */
FlCompositorOpenGL* fl_compositor_opengl_new(FlOpenGLManager* opengl_manager);

/**
 * fl_compositor_opengl_composite_layers:
 * @compositor: an #FlCompositorOpenGL.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Composite @layers into the OpenGL framebuffer bound to the current OpenGL
 * context. The caller is responsible for binding the target framebuffer before
 * calling this function.
 */
void fl_compositor_opengl_composite_layers(FlCompositorOpenGL* compositor,
                                           const FlutterLayer** layers,
                                           size_t layers_count);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_OPENGL_H_
