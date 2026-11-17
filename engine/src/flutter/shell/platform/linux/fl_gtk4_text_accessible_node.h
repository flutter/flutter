// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_TEXT_ACCESSIBLE_NODE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_TEXT_ACCESSIBLE_NODE_H_

#include "flutter/shell/platform/linux/fl_gtk4_accessible_node.h"

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
#define FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE \
  (fl_gtk4_text_accessible_node_get_type())
#define FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE))

GType fl_gtk4_text_accessible_node_get_type();
GType fl_gtk4_editable_accessible_node_get_type();
void fl_gtk4_text_accessible_node_set_text(FlGtk4AccessibleNode* self,
                                           const gchar* text,
                                           gint selection_base,
                                           gint selection_extent,
                                           gboolean is_obscured);
void fl_gtk4_editable_accessible_node_cancel(FlGtk4AccessibleNode* self);
GBytes* fl_gtk4_text_accessible_node_get_contents(GtkAccessible* accessible,
                                                  unsigned int start,
                                                  unsigned int end);
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_TEXT_ACCESSIBLE_NODE_H_
