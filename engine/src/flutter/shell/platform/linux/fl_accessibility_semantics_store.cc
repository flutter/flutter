// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"
#include "flutter/shell/platform/linux/fl_glib_compat.h"

#include <cstring>

struct _FlAccessibilitySemanticsStore {
  GObject parent_instance;

  FlutterViewId view_id;
  GHashTable* nodes_by_id;
  gboolean root_node_present;
  gboolean structure_changed;
  guint64 revision;
};

G_DEFINE_TYPE(FlAccessibilitySemanticsStore,
              fl_accessibility_semantics_store,
              G_TYPE_OBJECT)

static void fl_accessibility_semantics_node_free(gpointer data) {
  FlAccessibilitySemanticsNode* node =
      static_cast<FlAccessibilitySemanticsNode*>(data);
  g_free(node->label);
  g_free(node->hint);
  g_free(node->value);
  g_free(node->tooltip);
  g_free(node->children_in_traversal_order);
  g_free(node);
}

static FlAccessibilitySemanticsNode* fl_accessibility_semantics_node_new(
    FlutterSemanticsNode2* semantics) {
  FlAccessibilitySemanticsNode* node = g_new0(FlAccessibilitySemanticsNode, 1);
  node->id = semantics->id;
  node->label = g_strdup(semantics->label);
  node->hint = g_strdup(semantics->hint);
  node->value = g_strdup(semantics->value);
  node->tooltip = g_strdup(semantics->tooltip);
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
    node->children_in_traversal_order = static_cast<int32_t*>(
        g_memdup2(semantics->children_in_traversal_order,
                  sizeof(int32_t) * semantics->child_count));
  }
  node->heading_level = semantics->heading_level;

  return node;
}

static void fl_accessibility_semantics_store_dispose(GObject* object) {
  FlAccessibilitySemanticsStore* self =
      FL_ACCESSIBILITY_SEMANTICS_STORE(object);

  g_clear_pointer(&self->nodes_by_id, g_hash_table_unref);

  G_OBJECT_CLASS(fl_accessibility_semantics_store_parent_class)
      ->dispose(object);
}

static void fl_accessibility_semantics_store_class_init(
    FlAccessibilitySemanticsStoreClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_accessibility_semantics_store_dispose;
}

static void fl_accessibility_semantics_store_init(
    FlAccessibilitySemanticsStore* self) {
  self->nodes_by_id =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr,
                            fl_accessibility_semantics_node_free);
}

FlAccessibilitySemanticsStore* fl_accessibility_semantics_store_new(
    FlutterViewId view_id) {
  FlAccessibilitySemanticsStore* self = FL_ACCESSIBILITY_SEMANTICS_STORE(
      g_object_new(fl_accessibility_semantics_store_get_type(), nullptr));
  self->view_id = view_id;
  return self;
}

void fl_accessibility_semantics_store_handle_update(
    FlAccessibilitySemanticsStore* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_SEMANTICS_STORE(self));
  g_return_if_fail(update != nullptr);

  if (update->view_id != self->view_id) {
    return;
  }

  self->structure_changed = FALSE;
  for (size_t i = 0; i < update->node_count; i++) {
    FlutterSemanticsNode2* semantics = update->nodes[i];
    const auto* previous =
        fl_accessibility_semantics_store_lookup_node(self, semantics->id);
    const gboolean same_children =
        previous != nullptr &&
        previous->child_count == semantics->child_count &&
        (semantics->child_count == 0 ||
         (previous->children_in_traversal_order != nullptr &&
          semantics->children_in_traversal_order != nullptr &&
          memcmp(previous->children_in_traversal_order,
                 semantics->children_in_traversal_order,
                 semantics->child_count * sizeof(int32_t)) == 0));
    self->structure_changed |= !same_children;
    FlutterSemanticsFlags flags = {};
    if (semantics->flags2 != nullptr) {
      flags = *semantics->flags2;
    }
    // Byte comparisons are conservative: padding differences may cause an
    // extra update, but never suppress a changed field.
    if (same_children && g_strcmp0(previous->label, semantics->label) == 0 &&
        g_strcmp0(previous->hint, semantics->hint) == 0 &&
        g_strcmp0(previous->value, semantics->value) == 0 &&
        g_strcmp0(previous->tooltip, semantics->tooltip) == 0 &&
        memcmp(&previous->flags, &flags, sizeof(flags)) == 0 &&
        previous->actions == semantics->actions &&
        previous->text_selection_base == semantics->text_selection_base &&
        previous->text_selection_extent == semantics->text_selection_extent &&
        previous->text_direction == semantics->text_direction &&
        memcmp(&previous->rect, &semantics->rect, sizeof(FlutterRect)) == 0 &&
        memcmp(&previous->transform, &semantics->transform,
               sizeof(FlutterTransformation)) == 0 &&
        previous->heading_level == semantics->heading_level) {
      continue;
    }
    FlAccessibilitySemanticsNode* node =
        fl_accessibility_semantics_node_new(semantics);
    node->revision = ++self->revision;
    g_hash_table_replace(self->nodes_by_id, GINT_TO_POINTER(node->id), node);
    if (node->id == 0) {
      self->root_node_present = TRUE;
    }
  }

  if (!self->root_node_present || !self->structure_changed) {
    return;
  }

  // Updates contain only changed nodes. Compute reachability after applying
  // the entire batch so reordered nodes and unchanged descendants survive.
  g_autoptr(GHashTable) reachable =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  g_autoptr(GArray) pending = g_array_new(FALSE, FALSE, sizeof(int32_t));
  int32_t root_id = 0;
  g_array_append_val(pending, root_id);
  while (pending->len > 0) {
    int32_t id = g_array_index(pending, int32_t, pending->len - 1);
    g_array_set_size(pending, pending->len - 1);
    if (!g_hash_table_add(reachable, GINT_TO_POINTER(id))) {
      continue;
    }
    const auto* node = fl_accessibility_semantics_store_lookup_node(self, id);
    if (node != nullptr && node->children_in_traversal_order != nullptr) {
      for (size_t i = 0; i < node->child_count; i++) {
        int32_t child_id = node->children_in_traversal_order[i];
        g_array_append_val(pending, child_id);
      }
    }
  }

  GHashTableIter iter;
  gpointer key;
  g_hash_table_iter_init(&iter, self->nodes_by_id);
  while (g_hash_table_iter_next(&iter, &key, nullptr)) {
    if (!g_hash_table_contains(reachable, key)) {
      g_hash_table_iter_remove(&iter);
    }
  }
}

const FlAccessibilitySemanticsNode*
fl_accessibility_semantics_store_lookup_node(
    FlAccessibilitySemanticsStore* self,
    int32_t node_id) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_SEMANTICS_STORE(self), nullptr);

  return static_cast<const FlAccessibilitySemanticsNode*>(
      g_hash_table_lookup(self->nodes_by_id, GINT_TO_POINTER(node_id)));
}

gboolean fl_accessibility_semantics_store_has_root(
    FlAccessibilitySemanticsStore* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_SEMANTICS_STORE(self), FALSE);

  return self->root_node_present;
}

gboolean fl_accessibility_semantics_store_structure_changed(
    FlAccessibilitySemanticsStore* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_SEMANTICS_STORE(self), FALSE);
  return self->structure_changed;
}
