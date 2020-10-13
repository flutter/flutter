// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_

#include <gdk/gdk.h>

#ifdef GDK_WINDOWING_X11
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
 * #FlRendererX11 is an implementation of #FlRenderer that renders to X11
 * windows.
 */

/**
 * fl_renderer_x11_new:
 *
 * Creates an object that allows Flutter to render to X11 windows.
 *
 * Returns: a new #FlRendererX11.
 */
FlRendererX11* fl_renderer_x11_new();

G_END_DECLS

#endif  // GDK_WINDOWING_X11

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_X11_H_
