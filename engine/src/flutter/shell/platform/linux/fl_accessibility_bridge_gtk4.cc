// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_bridge_gtk4.h"

#include <cstring>

typedef struct {
  int32_t id;
  gchar* label;
  gchar* value;
  FlutterSemanticsFlags flags;
  FlutterSemanticsAction actions;
  gint text_selection_base;
  gint text_selection_extent;
  FlutterTextDirection text_direction;
  FlutterRect rect;
  FlutterTransformation transform;
  size_t child_count;
  int32_t* children_in_traversal_order;
} FlGtk4SemanticsNode;

struct _FlAccessibilityBridgeGtk4 {
  GObject parent_instance;

  FlutterViewId view_id;
  GHashTable* semantics_nodes_by_id;
  gboolean root_node_present;
  gchar* last_announcement;
  FlTextDirection last_text_direction;
  FlAssertiveness last_assertiveness;
};

G_DEFINE_TYPE(FlAccessibilityBridgeGtk4,
              fl_accessibility_bridge_gtk4,
              G_TYPE_OBJECT)

static void fl_gtk4_semantics_node_free(gpointer data) {
  FlGtk4SemanticsNode* node = static_cast<FlGtk4SemanticsNode*>(data);
  g_free(node->label);
  g_free(node->value);
  g_free(node->children_in_traversal_order);
  g_free(node);
}

static FlGtk4SemanticsNode* fl_gtk4_semantics_node_new(
    FlutterSemanticsNode2* semantics) {
  FlGtk4SemanticsNode* node = g_new0(FlGtk4SemanticsNode, 1);
  node->id = semantics->id;
  node->label = g_strdup(semantics->label);
  node->value = g_strdup(semantics->value);
  if (semantics->flags2 != nullptr) {
    node->flags = *semantics->flags2;
  } else {
    memset(&node->flags, 0, sizeof(node->flags));
  }
  node->actions = semantics->actions;
  node->text_selection_base = semantics->text_selection_base;
  node->text_selection_extent = semantics->text_selection_extent;
  node->text_direction = semantics->text_direction;
  node->rect = semantics->rect;
  node->transform = semantics->transform;
  node->child_count = semantics->child_count;
  if (semantics->child_count > 0 &&
      semantics->children_in_traversal_order != nullptr) {
    node->children_in_traversal_order = static_cast<int32_t*>(g_memdup(
        semantics->children_in_traversal_order,
        sizeof(int32_t) * semantics->child_count));
  }

  return node;
}

static void fl_accessibility_bridge_gtk4_dispose(GObject* object) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(object);

  g_clear_pointer(&self->semantics_nodes_by_id, g_hash_table_unref);
  g_clear_pointer(&self->last_announcement, g_free);

  G_OBJECT_CLASS(fl_accessibility_bridge_gtk4_parent_class)->dispose(object);
}

static void fl_accessibility_bridge_gtk4_class_init(
    FlAccessibilityBridgeGtk4Class* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_accessibility_bridge_gtk4_dispose;
}

static void fl_accessibility_bridge_gtk4_init(FlAccessibilityBridgeGtk4* self) {
  self->semantics_nodes_by_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr, fl_gtk4_semantics_node_free);
  self->last_text_direction = FL_TEXT_DIRECTION_LTR;
  self->last_assertiveness = FL_ASSERTIVENESS_POLITE;
}

FlAccessibilityBridgeGtk4* fl_accessibility_bridge_gtk4_new(
    FlutterViewId view_id) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(
      g_object_new(fl_accessibility_bridge_gtk4_get_type(), nullptr));
  self->view_id = view_id;
  return self;
}

void fl_accessibility_bridge_gtk4_handle_update_semantics(
    FlAccessibilityBridgeGtk4* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self));
  g_return_if_fail(update != nullptr);

  if (update->view_id != self->view_id) {
    return;
  }

  for (size_t i = 0; i < update->node_count; i++) {
    FlutterSemanticsNode2* semantics = update->nodes[i];
    FlGtk4SemanticsNode* node = fl_gtk4_semantics_node_new(semantics);
    g_hash_table_replace(self->semantics_nodes_by_id, GINT_TO_POINTER(node->id),
                         node);
    if (node->id == 0) {
      self->root_node_present = TRUE;
    }
  }
}

void fl_accessibility_bridge_gtk4_send_announcement(
    FlAccessibilityBridgeGtk4* self,
    const char* message,
    FlTextDirection text_direction,
    FlAssertiveness assertiveness) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self));

  g_free(self->last_announcement);
  self->last_announcement = g_strdup(message);
  self->last_text_direction = text_direction;
  self->last_assertiveness = assertiveness;
}
