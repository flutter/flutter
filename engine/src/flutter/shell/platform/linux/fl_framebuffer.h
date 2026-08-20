// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_FRAMEBUFFER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_FRAMEBUFFER_H_

#include <epoxy/gl.h>
#include <glib-object.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlFramebuffer, fl_framebuffer, FL, FRAMEBUFFER, GObject)

/**
 * FlFramebuffer:
 *
 * #FlFramebuffer creates framebuffers and their backing textures
 * for use by the Flutter compositor.
 */

/**
 * fl_framebuffer_new:
 * @format: format, e.g. GL_RGB, GL_BGR
 * @width: width of texture.
 * @height: height of texture.
 * @shareable: %TRUE if this framebuffer can be shared between contexts
 * (requires EGL).
 *
 * Creates a new frame buffer. Requires a valid OpenGL context to create.
 *
 * Returns: a new #FlFramebuffer.
 */
FlFramebuffer* fl_framebuffer_new(GLint format,
                                  size_t width,
                                  size_t height,
                                  gboolean shareable);

/**
 * fl_framebuffer_new_multisample:
 * @sized_format: sized format, e.g. GL_RGBA8, GL_BGRA8_EXT.
 * @general_format: general format, e.g. GL_RGBA, GL_BGRA_EXT.
 * @width: width of framebuffer in pixels.
 * @height: height of framebuffer in pixels.
 * @use_msaa: %TRUE to enable multisample anti-aliasing (MSAA) attachments.
 *
 * Creates a new frame buffer, configuring MSAA attachments if supported and
 * @use_msaa is %TRUE.
 *
 * When @use_msaa is %TRUE, the framebuffer will configure 4x MSAA attachments
 * using either implicit MSAA (multisampled texture via
 * GL_EXT_multisampled_render_to_texture) or offscreen MSAA (multisample color
 * renderbuffer). If offscreen MSAA is used, the framebuffer is not backed by a
 * texture (fl_framebuffer_get_texture_id() returns 0) and must be resolved
 * into a single-sample texture via glBlitFramebuffer before compositing.
 *
 * If @use_msaa is %FALSE or MSAA is not supported by the OpenGL context, a
 * standard single-sample texture and depth/stencil renderbuffer are created.
 *
 * Returns: a new #FlFramebuffer.
 */
FlFramebuffer* fl_framebuffer_new_multisample(GLint sized_format,
                                              GLint general_format,
                                              size_t width,
                                              size_t height,
                                              gboolean use_msaa);

/**
 * fl_framebuffer_get_shareable:
 * @framebuffer: an #FlFramebuffer.
 *
 * Checks if this framebuffer can be shared between contexts (using
 * fl_framebuffer_create_sibling).
 *
 * Returns: %TRUE if this framebuffer can be shared.
 */
gboolean fl_framebuffer_get_shareable(FlFramebuffer* framebuffer);

/**
 * fl_framebuffer_create_sibling:
 * @framebuffer: an #FlFramebuffer.
 *
 * Creates a new framebuffer with the same backing texture as the original. This
 * uses EGLImage to share the texture and allows a framebuffer created in one
 * OpenGL context to be used in another.
 *
 * Returns: a new #FlFramebuffer.
 */
FlFramebuffer* fl_framebuffer_create_sibling(FlFramebuffer* framebuffer);

/**
 * fl_framebuffer_get_id:
 * @framebuffer: an #FlFramebuffer.
 *
 * Gets the ID for this framebuffer.
 *
 * Returns: OpenGL framebuffer id or 0 if creation failed.
 */
GLuint fl_framebuffer_get_id(FlFramebuffer* framebuffer);

/**
 * fl_framebuffer_get_texture_id:
 * @framebuffer: an #FlFramebuffer.
 *
 * Gets the ID of the texture associated with this framebuffer.
 *
 * Returns: OpenGL texture id or 0 if creation failed.
 */
GLuint fl_framebuffer_get_texture_id(FlFramebuffer* framebuffer);

/**
 * fl_framebuffer_get_width:
 * @framebuffer: an #FlFramebuffer.
 *
 * Gets the width of the framebuffer in pixels.
 *
 * Returns: width in pixels.
 */
size_t fl_framebuffer_get_width(FlFramebuffer* framebuffer);

/**
 * fl_framebuffer_get_height:
 * @framebuffer: an #FlFramebuffer.
 *
 * Gets the height of the framebuffer in pixels.
 *
 * Returns: height in pixels.
 */
size_t fl_framebuffer_get_height(FlFramebuffer* framebuffer);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_FRAMEBUFFER_H_
