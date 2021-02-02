// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_GL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_GL_H_

#include "flutter/shell/platform/linux/fl_renderer.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlRendererGL, fl_renderer_gl, FL, RENDERER_GL, FlRenderer)

/**
 * FlRendererGL:
 *
 * #FlRendererGL is an implementation of #FlRenderer that renders by OpenGL ES.
 */

/**
 * fl_renderer_gl_new:
 *
 * Creates an object that allows Flutter to render by OpenGL ES.
 *
 * Returns: a new #FlRendererGL.
 */
FlRendererGL* fl_renderer_gl_new();

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_GL_H_
