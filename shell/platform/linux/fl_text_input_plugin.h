// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_
#define FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlTextInputPlugin,
                     fl_text_input_plugin,
                     FL,
                     TEXT_INPUT_PLUGIN,
                     GObject);

/**
 * FlTextInputPlugin:
 *
 * #FlTextInputPlugin is a plugin that implements the shell side
 * of SystemChannels.textInput from the Flutter services library.
 */

/**
 * fl_text_input_plugin_new:
 * @messenger: an #FlBinaryMessenger.
 * @view: the #FlView with which the text input plugin is associated.
 *
 * Creates a new plugin that implements SystemChannels.textInput from the
 * Flutter services library.
 *
 * Returns: a new #FlTextInputPlugin.
 */
FlTextInputPlugin* fl_text_input_plugin_new(FlBinaryMessenger* messenger,
                                            FlView* view);

/**
 * fl_text_input_plugin_filter_keypress
 * @plugin: an #FlTextInputPlugin.
 * @event: a #GdkEventKey
 *
 * Process a Gdk key event.
 *
 * Returns: %TRUE if the event was used.
 */
gboolean fl_text_input_plugin_filter_keypress(FlTextInputPlugin* plugin,
                                              GdkEventKey* event);

G_END_DECLS

#endif  // FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_
