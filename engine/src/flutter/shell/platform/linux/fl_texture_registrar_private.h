// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXTURE_REGISTRAR_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXTURE_REGISTRAR_PRIVATE_H_

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_texture_registrar.h"

G_BEGIN_DECLS

/**
 * fl_texture_registrar_new:
 * @engine: an #FlEngine.
 *
 * Creates a new #FlTextureRegistrar.
 *
 * Returns: a new #FlTextureRegistrar.
 */
FlTextureRegistrar* fl_texture_registrar_new(FlEngine* engine);

/**
 * fl_texture_registrar_populate_gl_external_texture:
 * @registrar: an #FlTextureRegistrar.
 * @texture_id: ID of texture.
 * @width: width of the texture.
 * @height: height of the texture.
 * @opengl_texture: (out): return an #FlutterOpenGLTexture.
 * @error: (allow-none): #GError location to store the error occurring, or
 * %NULL to ignore.
 *
 * Attempts to populate the given @texture_id.
 *
 * Returns: %TRUE on success.
 */
gboolean fl_texture_registrar_populate_gl_external_texture(
    FlTextureRegistrar* registrar,
    int64_t texture_id,
    uint32_t width,
    uint32_t height,
    FlutterOpenGLTexture* opengl_texture,
    GError** error);

/**
 * fl_texture_registrar_get_texture:
 * @registrar: an #FlTextureRegistrar.
 * @texture_id: ID of texture.
 *
 * Gets a registered texture by @texture_id.
 *
 * Returns: an #FlTexture, or %NULL if not found.
 */
FlTexture* fl_texture_registrar_get_texture(FlTextureRegistrar* registrar,
                                            int64_t texture_id);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXTURE_REGISTRAR_PRIVATE_H_
