// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_MOUSE_CURSOR_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_MOUSE_CURSOR_HANDLER_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMouseCursorHandler,
                     fl_mouse_cursor_handler,
                     FL,
                     MOUSE_CURSOR_HANDLER,
                     GObject);

/**
 * FlMouseCursorHandler:
 *
 * #FlMouseCursorHandler is a mouse_cursor channel that implements the shell
 * side of SystemChannels.mouseCursor from the Flutter services library.
 */

/**
 * fl_mouse_cursor_handler_new:
 * @messenger: an #FlBinaryMessenger.
 * @view: an #FlView to control.
 *
 * Creates a new handler that implements SystemChannels.mouseCursor from the
 * Flutter services library.
 *
 * Returns: a new #FlMouseCursorHandler.
 */
FlMouseCursorHandler* fl_mouse_cursor_handler_new(FlBinaryMessenger* messenger,
                                                  FlView* view);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_MOUSE_CURSOR_HANDLER_H_
