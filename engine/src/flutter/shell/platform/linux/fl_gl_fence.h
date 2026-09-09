// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_FENCE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_FENCE_H_

#include <epoxy/egl.h>
#include <glib-object.h>

#include "flutter/shell/platform/linux/fl_opengl_manager.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlGLFence, fl_gl_fence, FL, GL_FENCE, GObject)

/**
 * FlGLFence:
 *
 * #FlGLFence marks a point in the OpenGL command stream that can be waited on,
 * which is how rendering done in one context is made visible to another.
 * Flushing a context only guarantees its commands have been submitted, not that
 * they have completed, so a texture rendered in one context can't be used in
 * another until a fence taken after the rendering has been reached.
 */

/**
 * fl_gl_fence_new:
 * @opengl_manager: an #FlOpenGLManager.
 *
 * Creates a fence that is reached when the commands submitted to the current
 * OpenGL context so far have completed. Requires the context that did the
 * rendering to be current.
 *
 * Only use this if fl_opengl_manager_can_fence() returns %TRUE; drivers without
 * fences have to fall back to waiting for the rendering to complete, e.g. with
 * glFinish().
 *
 * If the fence can't be created a warning is generated and an #FlGLFence that
 * is not waited for is returned.
 *
 * Returns: a new #FlGLFence.
 */
FlGLFence* fl_gl_fence_new(FlOpenGLManager* opengl_manager);

/**
 * fl_gl_fence_wait:
 * @fence: an #FlGLFence.
 *
 * Makes the current OpenGL context wait for @fence before executing any
 * commands submitted after this point. Requires the context that is going to
 * use the rendered texture to be current.
 *
 * This doesn't block the calling thread, the waiting is done by OpenGL. Falls
 * back to blocking the calling thread if the driver can't wait this way.
 */
void fl_gl_fence_wait(FlGLFence* fence);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_FENCE_H_
