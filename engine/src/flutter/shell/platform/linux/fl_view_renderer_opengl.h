// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_OPENGL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_OPENGL_H_

#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlViewRendererOpenGL,
                     fl_view_renderer_opengl,
                     FL,
                     VIEW_RENDERER_OPENGL,
                     FlViewRenderer)

/**
 * FlViewRendererOpenGL:
 *
 * #FlViewRendererOpenGL is an #FlViewRenderer that renders Flutter frames using
 * OpenGL.
 */

/**
 * fl_view_renderer_opengl_new:
 * @engine: the #FlEngine to render.
 * @sized_to_content: %TRUE if the view size is controlled by Flutter.
 *
 * Creates a new widget that renders Flutter frames using OpenGL.
 *
 * Returns: a new #FlViewRendererOpenGL.
 */
FlViewRendererOpenGL* fl_view_renderer_opengl_new(FlEngine* engine,
                                                  gboolean sized_to_content);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_OPENGL_H_
