// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include "flutter/shell/platform/linux/fl_gl_area.h"

/**
 * fl_view_begin_frame:
 * @view: an #FlView.
 *
 * Reset children of #FlView a stacked #GtkContainer.
 * This function is always paired with fl_view_end_frame.
 */
void fl_view_begin_frame(FlView* view);

/**
 * fl_view_add_gl_area:
 * @view: an #FlView.
 * @context: (transfer full): a #GdkGLContext, for #FlGLArea to render.
 * @texture: (transfer full): texture for OpenGL area to render.
 *
 * Append an #FlGLArea at top of stacked children of #FlView.
 * This function must be called after fl_view_begin_frame, and
 * before fl_view_end_frame.
 */
void fl_view_add_gl_area(FlView* view,
                         GdkGLContext* context,
                         FlBackingStoreProvider* texture);

/**
 * fl_view_add_widget:
 * @view: an #FlView.
 * @widget: a #GtkWidget.
 * @geometry: geometry of the widget.
 *
 * Append a #GtkWidget at top of stacked children of #FlView.
 */
void fl_view_add_widget(FlView* view,
                        GtkWidget* widget,
                        GdkRectangle* geometry);

/**
 * fl_view_end_frame:
 * @view: an #FlView.
 *
 * Apply changes made by fl_view_add_gl_area and fl_view_add_widget.
 */
void fl_view_end_frame(FlView* view);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
