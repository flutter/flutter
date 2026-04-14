// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_HANDLER_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_DERIVABLE_TYPE(FlAccessibilityHandler,
                         fl_accessibility_handler,
                         FL,
                         ACCESSIBILITY_HANDLER,
                         GObject);

struct _FlAccessibilityHandlerClass {
  GObjectClass parent_class;

  void (*send_announcement)(FlAccessibilityHandler* handler,
                            const char* message);
};

/**
 * FlAccessibilityHandler:
 *
 * #FlAccessibilityHandler is a handler that implements the shell side
 * of SystemChannels.accessibility from the Flutter services library.
 */

/**
 * fl_accessibility_handler_new:
 * @engine: an #FlEngine.
 *
 * Creates a new handler that implements SystemChannels.accessibility from the
 * Flutter services library.
 *
 * Returns: a new #FlAccessibilityHandler
 */
FlAccessibilityHandler* fl_accessibility_handler_new(FlEngine* engine);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_HANDLER_H_
