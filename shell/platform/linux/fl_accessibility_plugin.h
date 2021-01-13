// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_PLUGIN_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlAccessibilityPlugin,
                     fl_accessibility_plugin,
                     FL,
                     ACCESSIBILITY_PLUGIN,
                     GObject);

/**
 * FlAccessibilityPlugin:
 *
 * #FlAccessibilityPlugin is a plugin that handles semantic node updates and
 * converts them to ATK events.
 */

/**
 * fl_accessibility_plugin_new:
 * @view: an #FlView to export accessibility information to.
 *
 * Creates a new plugin handles semantic node updates.
 *
 * Returns: a new #FlAccessibilityPlugin.
 */
FlAccessibilityPlugin* fl_accessibility_plugin_new(FlView* view);

/**
 * fl_accessibility_plugin_handle_update_semantics_node:
 * @plugin: an #FlAccessibilityPlugin.
 * @node: semantic node information.
 *
 * Handle a semantics node update.
 */
void fl_accessibility_plugin_handle_update_semantics_node(
    FlAccessibilityPlugin* plugin,
    const FlutterSemanticsNode* node);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_PLUGIN_H_
