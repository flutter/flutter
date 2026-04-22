// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_GTK4_H_

#include <glib-object.h>
#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlAccessibleNodeGtk4,
                     fl_accessible_node_gtk4,
                     FL,
                     ACCESSIBLE_NODE_GTK4,
                     GObject);

FlAccessibleNodeGtk4* fl_accessible_node_gtk4_new(int32_t node_id);

void fl_accessible_node_gtk4_update_from_semantics(
    FlAccessibleNodeGtk4* self,
    const FlAccessibilitySemanticsNode* semantics);

void fl_accessible_node_gtk4_set_parent(FlAccessibleNodeGtk4* self,
                                        FlAccessibleNodeGtk4* parent,
                                        gint index_in_parent);

void fl_accessible_node_gtk4_set_children(FlAccessibleNodeGtk4* self,
                                          GPtrArray* children);

int32_t fl_accessible_node_gtk4_get_id(FlAccessibleNodeGtk4* self);

GtkAccessibleRole fl_accessible_node_gtk4_get_role(FlAccessibleNodeGtk4* self);

const gchar* fl_accessible_node_gtk4_get_label(FlAccessibleNodeGtk4* self);

const gchar* fl_accessible_node_gtk4_get_value(FlAccessibleNodeGtk4* self);

FlutterSemanticsFlags fl_accessible_node_gtk4_get_flags(
    FlAccessibleNodeGtk4* self);

FlutterSemanticsAction fl_accessible_node_gtk4_get_actions(
    FlAccessibleNodeGtk4* self);

FlutterRect fl_accessible_node_gtk4_get_rect(FlAccessibleNodeGtk4* self);

FlutterTransformation fl_accessible_node_gtk4_get_transform(
    FlAccessibleNodeGtk4* self);

FlAccessibleNodeGtk4* fl_accessible_node_gtk4_get_parent(
    FlAccessibleNodeGtk4* self);

gint fl_accessible_node_gtk4_get_index_in_parent(FlAccessibleNodeGtk4* self);

GPtrArray* fl_accessible_node_gtk4_get_children(FlAccessibleNodeGtk4* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_GTK4_H_
