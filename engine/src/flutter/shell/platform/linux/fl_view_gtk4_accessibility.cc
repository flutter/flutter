// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#if FLUTTER_LINUX_GTK4

#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_gtk4_accessible_node.h"
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_gtk4_text_accessible_node.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

struct _FlViewGtk4Accessibility {
  FlView* view;
  FlutterViewId view_id;
  FlAccessibilitySemanticsStore* semantics_store;
  FlGtk4AccessibleNode* root_node;
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  GHashTable* native_nodes_by_id;
#endif
};

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
static FlutterTransformation fl_gtk4_accessibility_identity_transform() {
  return {.scaleX = 1.0, .scaleY = 1.0, .pers2 = 1.0};
}

static FlutterTransformation fl_gtk4_accessibility_compose_transforms(
    const FlutterTransformation& parent,
    const FlutterTransformation& local) {
  const double a[3][3] = {
      {parent.scaleX, parent.skewX, parent.transX},
      {parent.skewY, parent.scaleY, parent.transY},
      {parent.pers0, parent.pers1, parent.pers2 == 0.0 ? 1.0 : parent.pers2}};
  const double b[3][3] = {
      {local.scaleX == 0.0 ? 1.0 : local.scaleX, local.skewX, local.transX},
      {local.skewY, local.scaleY == 0.0 ? 1.0 : local.scaleY, local.transY},
      {local.pers0, local.pers1, local.pers2 == 0.0 ? 1.0 : local.pers2}};
  double c[3][3] = {};
  for (int row = 0; row < 3; row++) {
    for (int column = 0; column < 3; column++) {
      for (int i = 0; i < 3; i++) {
        c[row][column] += a[row][i] * b[i][column];
      }
    }
  }
  return {.scaleX = c[0][0],
          .skewX = c[0][1],
          .transX = c[0][2],
          .skewY = c[1][0],
          .scaleY = c[1][1],
          .transY = c[1][2],
          .pers0 = c[2][0],
          .pers1 = c[2][1],
          .pers2 = c[2][2]};
}

static FlGtk4AccessibleNode* fl_view_gtk4_accessibility_build_native_node(
    FlViewGtk4Accessibility* self,
    const FlAccessibilitySemanticsNode* semantics,
    const FlutterTransformation& parent_transform,
    GHashTable* visited) {
  if (semantics == nullptr) {
    return nullptr;
  }

  if (g_hash_table_contains(visited, GINT_TO_POINTER(semantics->id))) {
    return nullptr;
  }
  g_hash_table_add(visited, GINT_TO_POINTER(semantics->id));

  FlGtk4AccessibleNode* node = FL_GTK4_ACCESSIBLE_NODE(g_hash_table_lookup(
      self->native_nodes_by_id, GINT_TO_POINTER(semantics->id)));
  FlGtk4AccessibleNode* previous_node = node;
  const FlutterTransformation transform =
      fl_gtk4_accessibility_compose_transforms(parent_transform,
                                               semantics->transform);
  node = fl_gtk4_accessible_node_update(self->view, self->view_id, semantics,
                                        transform, node);
  if (node != previous_node) {
    if (previous_node != nullptr) {
      // Clients can retain the replaced object after the cache releases it.
      fl_gtk4_accessible_node_detach(previous_node);
    }
    g_hash_table_insert(self->native_nodes_by_id,
                        GINT_TO_POINTER(semantics->id), node);
  }

  g_autoptr(GPtrArray) children = g_ptr_array_new();
  if (semantics->child_count > 0 &&
      semantics->children_in_traversal_order != nullptr) {
    for (size_t i = 0; i < semantics->child_count; i++) {
      const int32_t child_id = semantics->children_in_traversal_order[i];
      const FlAccessibilitySemanticsNode* child =
          fl_accessibility_semantics_store_lookup_node(self->semantics_store,
                                                       child_id);
      if (child == nullptr) {
        continue;
      }

      FlGtk4AccessibleNode* child_node =
          fl_view_gtk4_accessibility_build_native_node(self, child, transform,
                                                       visited);
      if (child_node != nullptr) {
        g_ptr_array_add(children, child_node);
      }
    }
  }

  fl_gtk4_accessible_node_attach_children(node, children);
  return node;
}
static gboolean fl_view_gtk4_accessibility_find_transform(
    FlViewGtk4Accessibility* self,
    const FlAccessibilitySemanticsNode* semantics,
    int32_t target_id,
    const FlutterTransformation& parent_transform,
    FlutterTransformation* result) {
  if (semantics == nullptr) {
    return FALSE;
  }
  const FlutterTransformation transform =
      fl_gtk4_accessibility_compose_transforms(parent_transform,
                                               semantics->transform);
  if (semantics->id == target_id) {
    *result = transform;
    return TRUE;
  }
  if (semantics->children_in_traversal_order == nullptr) {
    return FALSE;
  }
  for (size_t i = 0; i < semantics->child_count; i++) {
    const auto* child = fl_accessibility_semantics_store_lookup_node(
        self->semantics_store, semantics->children_in_traversal_order[i]);
    if (fl_view_gtk4_accessibility_find_transform(self, child, target_id,
                                                  transform, result)) {
      return TRUE;
    }
  }
  return FALSE;
}

#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

static const gchar* fl_view_gtk4_accessibility_get_root_label(
    FlViewGtk4Accessibility* self) {
  if (self->semantics_store == nullptr) {
    return nullptr;
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr || root->label == nullptr || root->label[0] == '\0') {
    return nullptr;
  }
  return root->label;
}

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
static void fl_view_gtk4_accessibility_rebuild_native_tree(
    FlViewGtk4Accessibility* self) {
  FlRenderTextureGtk4* render_area =
      FL_RENDER_TEXTURE_GTK4(self->view->render_area);

  if (!fl_gtk_runtime_supports_native_accessibility_tree()) {
    return;
  }

  if (self->semantics_store == nullptr ||
      !fl_accessibility_semantics_store_has_root(self->semantics_store)) {
    return;
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr) {
    return;
  }

  GHashTableIter nodes_iter;
  gpointer node_key = nullptr;
  gpointer node_value = nullptr;

  g_autoptr(GHashTable) visited =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  FlGtk4AccessibleNode* previous_root = self->root_node;
  self->root_node = fl_view_gtk4_accessibility_build_native_node(
      self, root, fl_gtk4_accessibility_identity_transform(), visited);
  if (self->root_node != nullptr && self->root_node != previous_root) {
    fl_gtk_runtime_accessible_set_accessible_parent(
        GTK_ACCESSIBLE(self->root_node),
        GTK_ACCESSIBLE(self->view->render_area), nullptr);
    fl_render_texture_gtk4_set_accessible_child(
        render_area, GTK_ACCESSIBLE(self->root_node));
  }

  // Disconnect the entire removed subtree while the table still owns every
  // node. Accessibility clients may retain nodes after their parents are freed.
  g_hash_table_iter_init(&nodes_iter, self->native_nodes_by_id);
  while (g_hash_table_iter_next(&nodes_iter, &node_key, &node_value)) {
    if (!g_hash_table_contains(visited, node_key)) {
      auto* node = FL_GTK4_ACCESSIBLE_NODE(node_value);
      fl_gtk4_accessible_node_detach(node);
    }
  }
  g_hash_table_iter_init(&nodes_iter, self->native_nodes_by_id);
  while (g_hash_table_iter_next(&nodes_iter, &node_key, nullptr)) {
    if (!g_hash_table_contains(visited, node_key)) {
      g_hash_table_iter_remove(&nodes_iter);
    }
  }
}
#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

FlViewGtk4Accessibility* fl_view_gtk4_accessibility_new(FlView* view,
                                                        FlutterViewId view_id) {
  FlViewGtk4Accessibility* self = g_new0(FlViewGtk4Accessibility, 1);
  self->view = view;
  self->view_id = view_id;
  self->semantics_store = fl_accessibility_semantics_store_new(view_id);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  self->native_nodes_by_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr, g_object_unref);
#endif
  return self;
}

void fl_view_gtk4_accessibility_dispose(FlViewGtk4Accessibility* self) {
  if (self == nullptr) {
    return;
  }

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (self->view != nullptr && self->view->render_area != nullptr) {
    fl_render_texture_gtk4_set_accessible_child(
        FL_RENDER_TEXTURE_GTK4(self->view->render_area), nullptr);
  }
  self->root_node = nullptr;
  // Clients can retain native objects after the view is destroyed. Disconnect
  // every node before releasing the table's ownership of parents and siblings.
  GHashTableIter iter;
  gpointer value = nullptr;
  g_hash_table_iter_init(&iter, self->native_nodes_by_id);
  while (g_hash_table_iter_next(&iter, nullptr, &value)) {
    fl_gtk4_accessible_node_detach(FL_GTK4_ACCESSIBLE_NODE(value));
  }
  g_clear_pointer(&self->native_nodes_by_id, g_hash_table_unref);
#endif
  g_clear_object(&self->semantics_store);
  g_free(self);
}

void fl_view_gtk4_accessibility_handle_update(
    FlViewGtk4Accessibility* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(self != nullptr);
  g_return_if_fail(update != nullptr);

  if (self->semantics_store == nullptr || update->view_id != self->view_id) {
    return;
  }

  fl_accessibility_semantics_store_handle_update(self->semantics_store, update);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (fl_gtk_runtime_supports_native_accessibility_tree()) {
    gboolean rebuild = self->root_node == nullptr ||
                       fl_accessibility_semantics_store_structure_changed(
                           self->semantics_store);
    // A changed ancestor transform affects every descendant. Rebuild the
    // hierarchy for such batches; leaf-only updates retain the fast path.
    for (size_t i = 0; !rebuild && i < update->node_count; i++) {
      rebuild = update->nodes[i]->child_count != 0;
    }
    if (!rebuild) {
      for (size_t i = 0; i < update->node_count; i++) {
        const int32_t id = update->nodes[i]->id;
        auto* node = static_cast<FlGtk4AccessibleNode*>(
            g_hash_table_lookup(self->native_nodes_by_id, GINT_TO_POINTER(id)));
        const auto* semantics = fl_accessibility_semantics_store_lookup_node(
            self->semantics_store, id);
        if (node == nullptr || semantics == nullptr) {
          continue;
        }
        FlutterTransformation transform =
            fl_gtk4_accessibility_identity_transform();
        const auto* root = fl_accessibility_semantics_store_lookup_node(
            self->semantics_store, 0);
        if (!fl_view_gtk4_accessibility_find_transform(
                self, root, id, fl_gtk4_accessibility_identity_transform(),
                &transform)) {
          continue;
        }
        auto* updated = fl_gtk4_accessible_node_update(
            self->view, self->view_id, semantics, transform, node);
        if (updated != node) {
          fl_gtk4_accessible_node_detach(node);
          g_hash_table_insert(self->native_nodes_by_id, GINT_TO_POINTER(id),
                              updated);
          rebuild = TRUE;
        }
      }
    }
    if (rebuild) {
      fl_view_gtk4_accessibility_rebuild_native_tree(self);
    }
    fl_view_gtk4_accessibility_update_accessible_name(self);
  } else {
    fl_view_gtk4_accessibility_update_accessible_name(self);
    fl_view_gtk4_accessibility_update_accessible_tree(self);
  }
#else
  fl_view_gtk4_accessibility_update_accessible_name(self);
  fl_view_gtk4_accessibility_update_accessible_tree(self);
#endif
}

void fl_view_gtk4_accessibility_update_accessible_name(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

  const gchar* label = fl_view_gtk4_accessibility_get_root_label(self);
  if (label == nullptr) {
    gtk_accessible_reset_property(GTK_ACCESSIBLE(self->view),
                                  GTK_ACCESSIBLE_PROPERTY_LABEL);
    return;
  }
  GtkAccessibleProperty property = GTK_ACCESSIBLE_PROPERTY_LABEL;
  GtkAccessibleProperty properties[] = {property};
  GValue value = G_VALUE_INIT;
  gtk_accessible_property_init_value(property, &value);
  g_value_set_string(&value, label);
  gtk_accessible_update_property_value(GTK_ACCESSIBLE(self->view), 1,
                                       properties, &value);
  g_value_unset(&value);
}

void fl_view_gtk4_accessibility_update_accessible_tree(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (fl_gtk_runtime_supports_native_accessibility_tree()) {
    fl_view_gtk4_accessibility_rebuild_native_tree(self);
  } else {
    fl_gtk_runtime_accessible_set_accessible_parent(
        GTK_ACCESSIBLE(self->view->render_area), GTK_ACCESSIBLE(self->view),
        nullptr);
  }
#else
  // Older GTK4 runtimes expose the widget-backed render surface only.
  fl_gtk_runtime_accessible_set_accessible_parent(
      GTK_ACCESSIBLE(self->view->render_area), GTK_ACCESSIBLE(self->view),
      nullptr);
#endif
}

void fl_view_gtk4_accessibility_send_announcement(FlViewGtk4Accessibility* self,
                                                  const char* message,
                                                  gboolean assertive) {
  g_return_if_fail(self != nullptr);

  fl_gtk_runtime_accessible_announce(GTK_ACCESSIBLE(self->view), message,
                                     assertive ? 1 : 0);
}

gboolean fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  return fl_gtk_runtime_supports_native_accessibility_tree();
#else
  return FALSE;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_native_root_for_testing(
    FlViewGtk4Accessibility* self) {
  g_return_val_if_fail(self != nullptr, nullptr);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  return self->root_node == nullptr
             ? nullptr
             : GTK_ACCESSIBLE(g_object_ref(self->root_node));
#else
  return nullptr;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_accessible_node_get_first_accessible_child(accessible);
#else
  return nullptr;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_accessible_node_get_next_accessible_sibling(accessible);
#else
  return nullptr;
#endif
}

gboolean fl_view_gtk4_accessibility_get_native_bounds_for_testing(
    GtkAccessible* accessible,
    int* x,
    int* y,
    int* width,
    int* height) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), FALSE);
  return fl_gtk4_accessible_node_get_bounds(accessible, x, y, width, height);
#else
  return FALSE;
#endif
}

GBytes* fl_view_gtk4_accessibility_ref_native_text_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_text_accessible_node_get_contents(accessible, 0, G_MAXUINT);
#else
  return nullptr;
#endif
}

#endif  // FLUTTER_LINUX_GTK4
