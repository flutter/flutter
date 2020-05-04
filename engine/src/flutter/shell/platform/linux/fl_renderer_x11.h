// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_

#include <gdk/gdkx.h>

#include "flutter/shell/platform/linux/fl_renderer.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlRendererX11,
                     fl_renderer_x11,
                     FL,
                     RENDERER_X11,
                     FlRenderer)

/**
 * FlRendererX11:
 *
 * #FlRendererX11 is an implementation of a #FlRenderer that renders to X11
 * windows.
 */

/**
 * fl_renderer_x11_new:
 *
 * Create an object that allows Flutter to render to X11 windows.
 *
 * Returns: a #FlRendererX11
 */
FlRendererX11* fl_renderer_x11_new();

/**
 * fl_renderer_x11_set_xid:
 * @renderer: a #FlRendererX11
 * @xid: The X window being rendered to
 *
 * Set the X11 window that is being rendered to.
 */
void fl_renderer_x11_set_xid(FlRendererX11* renderer, Window xid);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_
