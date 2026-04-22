// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_bridge_gtk4.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"

struct _FlAccessibilityBridgeGtk4 {
  GObject parent_instance;

  FlAccessibilitySemanticsStore* semantics_store;
  GHashTable* nodes_by_id;
  gchar* last_announcement;
  FlTextDirection last_text_direction;
  FlAssertiveness last_assertiveness;
};

G_DEFINE_TYPE(FlAccessibilityBridgeGtk4,
              fl_accessibility_bridge_gtk4,
              G_TYPE_OBJECT)

static void fl_accessibility_bridge_gtk4_dispose(GObject* object) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(object);

  g_clear_object(&self->semantics_store);
  g_clear_pointer(&self->nodes_by_id, g_hash_table_unref);
  g_clear_pointer(&self->last_announcement, g_free);

  G_OBJECT_CLASS(fl_accessibility_bridge_gtk4_parent_class)->dispose(object);
}

static void fl_accessibility_bridge_gtk4_class_init(
    FlAccessibilityBridgeGtk4Class* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_accessibility_bridge_gtk4_dispose;
}

static void fl_accessibility_bridge_gtk4_init(FlAccessibilityBridgeGtk4* self) {
  self->nodes_by_id = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                            nullptr, g_object_unref);
  self->last_text_direction = FL_TEXT_DIRECTION_LTR;
  self->last_assertiveness = FL_ASSERTIVENESS_POLITE;
}

FlAccessibilityBridgeGtk4* fl_accessibility_bridge_gtk4_new(
    FlutterViewId view_id) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(
      g_object_new(fl_accessibility_bridge_gtk4_get_type(), nullptr));
  self->semantics_store = fl_accessibility_semantics_store_new(view_id);
  return self;
}

void fl_accessibility_bridge_gtk4_handle_update_semantics(
    FlAccessibilityBridgeGtk4* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self));
  fl_accessibility_semantics_store_handle_update(self->semantics_store, update);

  g_autoptr(GHashTable) pending_children =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr,
                            reinterpret_cast<GDestroyNotify>(fl_value_unref));
  for (size_t i = 0; i < update->node_count; ++i) {
    FlutterSemanticsNode2* update_node = update->nodes[i];
    const FlAccessibilitySemanticsNode* semantics =
        fl_accessibility_semantics_store_lookup_node(self->semantics_store,
                                                     update_node->id);
    if (semantics == nullptr) {
      continue;
    }

    FlAccessibleNodeGtk4* node = FL_ACCESSIBLE_NODE_GTK4(
        g_hash_table_lookup(self->nodes_by_id, GINT_TO_POINTER(semantics->id)));
    if (node == nullptr) {
      node = fl_accessible_node_gtk4_new(semantics->id);
      g_hash_table_insert(self->nodes_by_id, GINT_TO_POINTER(semantics->id),
                          g_object_ref(node));
      g_object_unref(node);
    }

    fl_accessible_node_gtk4_update_from_semantics(node, semantics);

    FlValue* children = fl_value_new_int32_list(
        semantics->children_in_traversal_order, semantics->child_count);
    g_hash_table_insert(pending_children, node, children);
  }

  g_hash_table_foreach(
      pending_children,
      [](gpointer key, gpointer value, gpointer user_data) {
        FlAccessibilityBridgeGtk4* self =
            FL_ACCESSIBILITY_BRIDGE_GTK4(user_data);
        FlAccessibleNodeGtk4* parent = FL_ACCESSIBLE_NODE_GTK4(key);
        const int32_t* child_ids =
            fl_value_get_int32_list(static_cast<FlValue*>(value));
        size_t child_count = fl_value_get_length(static_cast<FlValue*>(value));

        g_autoptr(GPtrArray) children =
            g_ptr_array_new_with_free_func(g_object_unref);
        for (size_t i = 0; i < child_count; ++i) {
          FlAccessibleNodeGtk4* child =
              FL_ACCESSIBLE_NODE_GTK4(g_hash_table_lookup(
                  self->nodes_by_id, GINT_TO_POINTER(child_ids[i])));
          if (child == nullptr) {
            continue;
          }
          fl_accessible_node_gtk4_set_parent(child, parent,
                                             static_cast<gint>(i));
          g_ptr_array_add(children, g_object_ref(child));
        }

        fl_accessible_node_gtk4_set_children(parent, children);
      },
      self);
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

FlAccessibilitySemanticsStore* fl_accessibility_bridge_gtk4_get_semantics_store(
    FlAccessibilityBridgeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self), nullptr);

  return self->semantics_store;
}

FlAccessibleNodeGtk4* fl_accessibility_bridge_gtk4_lookup_node(
    FlAccessibilityBridgeGtk4* self,
    int32_t node_id) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self), nullptr);

  return FL_ACCESSIBLE_NODE_GTK4(
      g_hash_table_lookup(self->nodes_by_id, GINT_TO_POINTER(node_id)));
}
