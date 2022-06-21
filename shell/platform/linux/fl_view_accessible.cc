// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_accessible.h"
#include "flutter/shell/platform/linux/fl_accessible_node.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

struct _FlViewAccessible {
  GtkContainerAccessible parent_instance;

  FlEngine* engine;

  // Semantics nodes keyed by ID
  GHashTable* semantics_nodes_by_id;
};

enum { kProp0, kPropEngine, kPropLast };

G_DEFINE_TYPE(FlViewAccessible,
              fl_view_accessible,
              GTK_TYPE_CONTAINER_ACCESSIBLE)

static void init_engine(FlViewAccessible* self, FlEngine* engine) {
  g_assert(self->engine == nullptr);
  self->engine = engine;
  g_object_add_weak_pointer(G_OBJECT(self),
                            reinterpret_cast<gpointer*>(&self->engine));
}

static FlEngine* get_engine(FlViewAccessible* self) {
  if (self->engine == nullptr) {
    FlView* view = FL_VIEW(gtk_accessible_get_widget(GTK_ACCESSIBLE(self)));
    init_engine(self, fl_view_get_engine(view));
  }
  return self->engine;
}

// Gets the ATK node for the given id.
// If the node doesn't exist it will be created.
static FlAccessibleNode* get_node(FlViewAccessible* self, int32_t id) {
  FlAccessibleNode* node = FL_ACCESSIBLE_NODE(
      g_hash_table_lookup(self->semantics_nodes_by_id, GINT_TO_POINTER(id)));
  if (node != nullptr) {
    return node;
  }

  FlEngine* engine = get_engine(self);
  node = fl_accessible_node_new(engine, id);
  if (id == 0) {
    fl_accessible_node_set_parent(node, ATK_OBJECT(self), 0);
  }
  g_hash_table_insert(self->semantics_nodes_by_id, GINT_TO_POINTER(id),
                      reinterpret_cast<gpointer>(node));

  return node;
}

// Implements AtkObject::get_n_children
static gint fl_view_accessible_get_n_children(AtkObject* accessible) {
  return 1;
}

// Implements AtkObject::ref_child
static AtkObject* fl_view_accessible_ref_child(AtkObject* accessible, gint i) {
  FlViewAccessible* self = FL_VIEW_ACCESSIBLE(accessible);

  if (i != 0) {
    return nullptr;
  }

  FlAccessibleNode* node = get_node(self, 0);
  return ATK_OBJECT(g_object_ref(node));
}

// Implements AtkObject::get_role
static AtkRole fl_view_accessible_get_role(AtkObject* accessible) {
  return ATK_ROLE_PANEL;
}

// Implements GObject::set_property
static void fl_view_accessible_set_property(GObject* object,
                                            guint prop_id,
                                            const GValue* value,
                                            GParamSpec* pspec) {
  FlViewAccessible* self = FL_VIEW_ACCESSIBLE(object);
  switch (prop_id) {
    case kPropEngine:
      init_engine(self, FL_ENGINE(g_value_get_object(value)));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_view_accessible_dispose(GObject* object) {
  FlViewAccessible* self = FL_VIEW_ACCESSIBLE(object);

  if (self->engine != nullptr) {
    g_object_remove_weak_pointer(object,
                                 reinterpret_cast<gpointer*>(&self->engine));
    self->engine = nullptr;
  }

  G_OBJECT_CLASS(fl_view_accessible_parent_class)->dispose(object);
}

static void fl_view_accessible_class_init(FlViewAccessibleClass* klass) {
  ATK_OBJECT_CLASS(klass)->get_n_children = fl_view_accessible_get_n_children;
  ATK_OBJECT_CLASS(klass)->ref_child = fl_view_accessible_ref_child;
  ATK_OBJECT_CLASS(klass)->get_role = fl_view_accessible_get_role;

  G_OBJECT_CLASS(klass)->dispose = fl_view_accessible_dispose;
  G_OBJECT_CLASS(klass)->set_property = fl_view_accessible_set_property;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), kPropEngine,
      g_param_spec_object(
          "engine", "engine", "Flutter engine", fl_engine_get_type(),
          static_cast<GParamFlags>(G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_view_accessible_init(FlViewAccessible* self) {
  self->semantics_nodes_by_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr, g_object_unref);
}

void fl_view_accessible_handle_update_semantics_node(
    FlViewAccessible* self,
    const FlutterSemanticsNode* node) {
  if (node->id == kFlutterSemanticsCustomActionIdBatchEnd) {
    return;
  }

  FlAccessibleNode* atk_node = get_node(self, node->id);

  fl_accessible_node_set_flags(atk_node, node->flags);
  fl_accessible_node_set_actions(atk_node, node->actions);
  fl_accessible_node_set_name(atk_node, node->label);
  fl_accessible_node_set_extents(
      atk_node, node->rect.left + node->transform.transX,
      node->rect.top + node->transform.transY,
      node->rect.right - node->rect.left, node->rect.bottom - node->rect.top);

  g_autoptr(GPtrArray) children = g_ptr_array_new();
  for (size_t i = 0; i < node->child_count; i++) {
    FlAccessibleNode* child =
        get_node(self, node->children_in_traversal_order[i]);
    fl_accessible_node_set_parent(child, ATK_OBJECT(atk_node), i);
    g_ptr_array_add(children, child);
  }
  fl_accessible_node_set_children(atk_node, children);
}
