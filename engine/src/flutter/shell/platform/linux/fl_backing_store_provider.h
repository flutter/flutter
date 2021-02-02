// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_BACKING_STORE_PROVIDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_BACKING_STORE_PROVIDER_H_

#include <gtk/gtk.h>

#include <cstdint>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlBackingStoreProvider,
                     fl_backing_store_provider,
                     FL,
                     BACKING_STORE_PROVIDER,
                     GObject)

/**
 * FlBackingStoreProvider:
 *
 * #FlBackingStoreProvider creates framebuffers and their backing textures
 * for embedder compositor.
 */

/**
 * fl_backing_store_provider_new:
 * @width: width of texture.
 * @height: height of texture.
 *
 * Creates a new frame buffer. fl_renderer_make_current() must be called
 * first.
 *
 * Returns: a new #FlBackingStoreProvider.
 */
FlBackingStoreProvider* fl_backing_store_provider_new(int width, int height);

/**
 * fl_backing_store_provider_get_gl_framebuffer_id:
 * @provider: an #FlBackingStoreProvider.
 *
 * Gets created framebuffer id.
 *
 * Returns: gl framebuffer id, 0 if creation failed.
 */
uint32_t fl_backing_store_provider_get_gl_framebuffer_id(
    FlBackingStoreProvider* provider);

/**
 * fl_backing_store_provider_get_gl_texture_id:
 * @provider: an #FlBackingStoreProvider.
 *
 * Gets created texture id.
 *
 * Returns: gl texture id, 0 if creation failed.
 */
uint32_t fl_backing_store_provider_get_gl_texture_id(
    FlBackingStoreProvider* provider);

/**
 * fl_backing_store_provider_get_gl_target:
 * @provider: an #FlBackingStoreProvider.
 *
 * Gets target texture (example GL_TEXTURE_2D or GL_TEXTURE_RECTANGLE).
 *
 * Returns: target texture.
 */
uint32_t fl_backing_store_provider_get_gl_target(
    FlBackingStoreProvider* provider);

/**
 * fl_backing_store_provider_get_gl_format:
 * @provider: an #FlBackingStoreProvider.
 *
 * Gets texture format (example GL_RGBA8).
 *
 * Returns: texture format.
 */
uint32_t fl_backing_store_provider_get_gl_format(
    FlBackingStoreProvider* provider);

/**
 * fl_backing_store_provider_get_geometry:
 * @provider: an #FlBackingStoreProvider.
 *
 * Gets geometry of framebuffer.
 *
 * Returns: geometry of backing store.
 */
GdkRectangle fl_backing_store_provider_get_geometry(
    FlBackingStoreProvider* provider);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_BACKING_STORE_PROVIDER_H_
