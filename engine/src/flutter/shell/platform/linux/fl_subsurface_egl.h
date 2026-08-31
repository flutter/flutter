// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_EGL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_EGL_H_

#include <epoxy/gl.h>
#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_subsurface.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlSubsurfaceEGL,
                     fl_subsurface_egl,
                     FL,
                     SUBSURFACE_EGL,
                     GObject)

/**
 * FlSubsurfaceEGL:
 *
 * #FlSubsurfaceEGL manages the EGL context and window surface used to present
 * engine frames onto a Wayland subsurface. Its context shares resources with
 * the engine's render context, so the engine's frame texture can be blitted to
 * the subsurface directly, without using EGLImage.
 */

/**
 * fl_subsurface_egl_new:
 * @opengl_manager: the #FlOpenGLManager providing the engine's EGL display and
 * share context.
 * @subsurface: the #FlSubsurface to present onto.
 * @width: the surface width in logical pixels.
 * @height: the surface height in logical pixels.
 * @scale: the surface buffer scale.
 *
 * Creates the EGL context and window surface for presenting frames onto
 * @subsurface. A reference is kept on @subsurface, so its Wayland surface is
 * guaranteed to outlive the EGL surface created here. If this fails a warning
 * is printed and the returned object will fail to present frames, generating
 * the usual EGL/OpenGL errors.
 *
 * Returns: a new #FlSubsurfaceEGL.
 */
FlSubsurfaceEGL* fl_subsurface_egl_new(FlOpenGLManager* opengl_manager,
                                       FlSubsurface* subsurface,
                                       size_t width,
                                       size_t height,
                                       gint scale);

/**
 * fl_subsurface_egl_resize:
 * @egl: an #FlSubsurfaceEGL.
 * @width: the new width in pixels.
 * @height: the new height in pixels.
 *
 * Resizes the native Wayland window backing the EGL surface.
 */
void fl_subsurface_egl_resize(FlSubsurfaceEGL* egl,
                              size_t width,
                              size_t height);

/**
 * fl_subsurface_egl_present:
 * @egl: an #FlSubsurfaceEGL.
 * @texture_id: the OpenGL texture holding the frame to present.
 * @width: the frame width in pixels.
 * @height: the frame height in pixels.
 *
 * Blits @texture_id to the subsurface window surface and swaps buffers, then
 * restores the engine's rendering context. @texture_id must have been rendered
 * by the engine (or a context sharing resources with it).
 */
void fl_subsurface_egl_present(FlSubsurfaceEGL* egl,
                               GLuint texture_id,
                               size_t width,
                               size_t height);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_EGL_H_
