// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include "flutter/shell/platform/linux/fl_gl_area.h"

/**
 * fl_view_set_textures:
 * @view: an #FlView.
 * @context: a #GdkGLContext, for #FlGLArea to render.
 * @textures: (transfer none) (element-type FlBackingStoreProvider): a list of
 * #FlBackingStoreProvider.
 *
 * Set the textures for this view to render.
 */
void fl_view_set_textures(FlView* view,
                          GdkGLContext* context,
                          GPtrArray* textures);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
