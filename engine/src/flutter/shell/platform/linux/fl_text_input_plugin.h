// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_
#define FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

/**
 * FlTextInputPluginImFilter:
 * @event: the pointer to the GdkEventKey.
 *
 * The signature for a callback with which a #FlTextInputPlugin allow an input
 * method to internally handle key press and release events.
 *
 * The #gdk_event is an opaque pointer. It will be GdkEvent* in actual
 * applications, or a dummy pointer in unit tests.
 **/
typedef gboolean (*FlTextInputPluginImFilter)(GtkIMContext* im_context,
                                              gpointer gdk_event);

G_BEGIN_DECLS

G_DECLARE_DERIVABLE_TYPE(FlTextInputPlugin,
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

struct _FlTextInputPluginClass {
  GObjectClass parent_class;

  /**
   * Virtual method called to filter a keypress.
   */
  gboolean (*filter_keypress)(FlTextInputPlugin* self, FlKeyEvent* event);
};

/**
 * fl_text_input_plugin_new:
 * @messenger: an #FlBinaryMessenger.
 * @view: the #FlView with which the text input plugin is associated.
 * @im_filter: a function used to allow an input method to internally handle
 * key press and release events. Typically a wrap of
 * #gtk_im_context_filter_keypress. Must not be nullptr.
 *
 * Creates a new plugin that implements SystemChannels.textInput from the
 * Flutter services library.
 *
 * Returns: a new #FlTextInputPlugin.
 */
FlTextInputPlugin* fl_text_input_plugin_new(
    FlBinaryMessenger* messenger,
    FlView* view,
    FlTextInputPluginImFilter im_filter);

/**
 * fl_text_input_plugin_filter_keypress
 * @plugin: an #FlTextInputPlugin.
 * @event: a #FlKeyEvent
 *
 * Process a Gdk key event.
 *
 * Returns: %TRUE if the event was used.
 */
gboolean fl_text_input_plugin_filter_keypress(FlTextInputPlugin* plugin,
                                              FlKeyEvent* event);

G_END_DECLS

#endif  // FLUTTER_SHELL_TEXT_INPUT_LINUX_FL_TEXT_INPUT_PLUGIN_H_
