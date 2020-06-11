// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

#include <gdk/gdk.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlKeyEventPlugin,
                     fl_key_event_plugin,
                     FL,
                     KEY_EVENT_PLUGIN,
                     GObject);

/**
 * FlKeyEventPlugin:
 *
 * #FlKeyEventPlugin is a plugin that implements the shell side
 * of SystemChannels.keyEvent from the Flutter services library.
 */

/**
 * fl_key_event_plugin_new:
 * @messenger: an #FlBinaryMessenger.
 *
 * Creates a new plugin that implements SystemChannels.keyEvent from the
 * Flutter services library.
 *
 * Returns: a new #FlKeyEventPlugin.
 */
FlKeyEventPlugin* fl_key_event_plugin_new(FlBinaryMessenger* messenger);

/**
 * fl_key_event_plugin_send_key_event:
 * @plugin: an #FlKeyEventPlugin.
 * @event: a #GdkEventKey.
 *
 * Sends a key event to Flutter.
 */
void fl_key_event_plugin_send_key_event(FlKeyEventPlugin* plugin,
                                        GdkEventKey* event);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_
