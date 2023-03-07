// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_AREA_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_AREA_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/fl_backing_store_provider.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlGLArea, fl_gl_area, FL, GL_AREA, GtkWidget)

/**
 * FlGLArea:
 *
 * #FlGLArea is a OpenGL drawing area that shows Flutter backing store Layer.
 */

/**
 * fl_gl_area_new:
 * @context: an #GdkGLContext.
 *
 * Creates a new #FlGLArea widget.
 *
 * Returns: the newly created #FlGLArea widget.
 */
GtkWidget* fl_gl_area_new(GdkGLContext* context);

/**
 * fl_gl_area_queue_render:
 * @area: an #FlGLArea.
 * @textures: (transfer none) (element-type FlBackingStoreProvider): a list of
 * #FlBackingStoreProvider.
 *
 * Queues textures to be drawn later.
 */
void fl_gl_area_queue_render(FlGLArea* area, GPtrArray* textures);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_AREA_H_
