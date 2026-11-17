// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_H_

#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

typedef struct _FlGtk4AccessibleNode FlGtk4AccessibleNode;
typedef struct _FlGtk4AccessibleNodeClass FlGtk4AccessibleNodeClass;

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
#define FL_TYPE_GTK4_ACCESSIBLE_NODE (fl_gtk4_accessible_node_get_type())
#define FL_GTK4_ACCESSIBLE_NODE(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), FL_TYPE_GTK4_ACCESSIBLE_NODE, \
                              FlGtk4AccessibleNode))
#define FL_IS_GTK4_ACCESSIBLE_NODE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), FL_TYPE_GTK4_ACCESSIBLE_NODE))

GType fl_gtk4_accessible_node_get_type();

// Returns self unchanged, or an owned replacement if its immutable GTK role or
// interfaces change. The caller must detach and release a replaced node.
FlGtk4AccessibleNode* fl_gtk4_accessible_node_update(
    FlView* view,
    FlutterViewId view_id,
    const FlAccessibilitySemanticsNode* semantics,
    const FlutterTransformation& transform,
    FlGtk4AccessibleNode* self);
void fl_gtk4_accessible_node_detach(FlGtk4AccessibleNode* self);
void fl_gtk4_accessible_node_attach_children(FlGtk4AccessibleNode* parent,
                                             GPtrArray* children);
// Traversal returns a new reference; callers release it with g_object_unref.
GtkAccessible* fl_gtk4_accessible_node_get_first_accessible_child(
    GtkAccessible* accessible);
GtkAccessible* fl_gtk4_accessible_node_get_next_accessible_sibling(
    GtkAccessible* accessible);
gboolean fl_gtk4_accessible_node_get_bounds(GtkAccessible* accessible,
                                            int* x,
                                            int* y,
                                            int* width,
                                            int* height);
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_H_
