// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

// ATK doesn't have the g_autoptr macros, so add them manually.
// https://gitlab.gnome.org/GNOME/atk/-/issues/10
G_DEFINE_AUTOPTR_CLEANUP_FUNC(AtkObject, g_object_unref)

G_DECLARE_FINAL_TYPE(FlAccessibleNode,
                     fl_accessible_node,
                     FL,
                     ACCESSIBLE_NODE,
                     AtkObject);

/**
 * FlAccessibleNode:
 *
 * #FlAccessibleNode is an object that exposes a Flutter accessibility node to
 * ATK.
 */

/**
 * fl_accessible_node_new:
 * @engine: the #FlEngine this node came from.
 * @id: the semantics node ID this object represents.
 *
 * Creates a new accessibility object that exposes Flutter accessibility
 * information to ATK.
 *
 * Returns: a new #FlAccessibleNode.
 */
FlAccessibleNode* fl_accessible_node_new(FlEngine* engine, int32_t id);

/**
 * fl_accessible_node_new:
 * @node: an #FlAccessibleNode.
 * @parent: an #AtkObject.
 *
 * Sets the parent of this node. The parent can be changed at any time.
 */
void fl_accessible_node_set_parent(FlAccessibleNode* node, AtkObject* parent);

/**
 * fl_accessible_node_new:
 * @node: an #FlAccessibleNode.
 * @children: (transfer none) (element-type AtkObject): a list of #AtkObject.
 *
 * Sets the children of this node. The children can be changed at any time.
 */
void fl_accessible_node_set_children(FlAccessibleNode* node,
                                     GPtrArray* children);

/**
 * fl_accessible_node_set_name:
 * @node: an #FlAccessibleNode.
 * @name: a node name.
 *
 * Sets the name of this node as reported to the a11y consumer.
 */
void fl_accessible_node_set_name(FlAccessibleNode* node, const gchar* name);

/**
 * fl_accessible_node_set_extents:
 * @node: an #FlAccessibleNode.
 * @x: x co-ordinate of this node relative to its parent.
 * @y: y co-ordinate of this node relative to its parent.
 * @width: width of this node in pixels.
 * @height: height of this node in pixels.
 *
 * Sets the position and size of this node.
 */
void fl_accessible_node_set_extents(FlAccessibleNode* node,
                                    gint x,
                                    gint y,
                                    gint width,
                                    gint height);

/**
 * fl_accessible_node_set_flags:
 * @node: an #FlAccessibleNode.
 * @flags: the flags for this node.
 *
 * Sets the flags for this node.
 */
void fl_accessible_node_set_flags(FlAccessibleNode* node,
                                  FlutterSemanticsFlag flags);

/**
 * fl_accessible_node_set_actions:
 * @node: an #FlAccessibleNode.
 * @actions: the actions this node can perform.
 *
 * Sets the actions that this node can perform.
 */
void fl_accessible_node_set_actions(FlAccessibleNode* node,
                                    FlutterSemanticsAction actions);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBLE_NODE_H_
