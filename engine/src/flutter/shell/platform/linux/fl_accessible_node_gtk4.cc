// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessible_node_gtk4.h"

struct _FlAccessibleNodeGtk4 {
  GObject parent_instance;

  int32_t node_id;
  GtkAccessibleRole role;
  gchar* label;
  gchar* value;
  FlutterSemanticsFlags flags;
  FlutterSemanticsAction actions;
  FlutterRect rect;
  FlutterTransformation transform;
  FlutterTextDirection text_direction;
  gint text_selection_base;
  gint text_selection_extent;
  GWeakRef parent;
  gint index_in_parent;
  GPtrArray* children;
};

G_DEFINE_TYPE(FlAccessibleNodeGtk4, fl_accessible_node_gtk4, G_TYPE_OBJECT)

static GtkAccessibleRole fl_accessible_node_gtk4_resolve_role(
    const FlAccessibilitySemanticsNode* semantics) {
  const FlutterSemanticsFlags& flags = semantics->flags;
  if (flags.is_button) {
    return GTK_ACCESSIBLE_ROLE_BUTTON;
  }
  if (flags.is_in_mutually_exclusive_group &&
      flags.is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_RADIO;
  }
  if (flags.is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_CHECKBOX;
  }
  if (flags.is_toggled != kFlutterTristateNone) {
    return GTK_ACCESSIBLE_ROLE_CHECKBOX;
  }
  if (flags.is_slider) {
    return GTK_ACCESSIBLE_ROLE_SLIDER;
  }
  if (flags.is_text_field) {
    return GTK_ACCESSIBLE_ROLE_TEXT_BOX;
  }
  if (flags.is_header) {
    return GTK_ACCESSIBLE_ROLE_HEADING;
  }
  if (flags.is_link) {
    return GTK_ACCESSIBLE_ROLE_LINK;
  }
  if (flags.is_image) {
    return GTK_ACCESSIBLE_ROLE_IMG;
  }
  if ((semantics->label != nullptr && semantics->label[0] != '\0') ||
      (semantics->value != nullptr && semantics->value[0] != '\0')) {
    return GTK_ACCESSIBLE_ROLE_LABEL;
  }
  return GTK_ACCESSIBLE_ROLE_GENERIC;
}

static void fl_accessible_node_gtk4_dispose(GObject* object) {
  FlAccessibleNodeGtk4* self = FL_ACCESSIBLE_NODE_GTK4(object);

  g_clear_pointer(&self->children, g_ptr_array_unref);
  g_weak_ref_clear(&self->parent);

  G_OBJECT_CLASS(fl_accessible_node_gtk4_parent_class)->dispose(object);
}

static void fl_accessible_node_gtk4_finalize(GObject* object) {
  FlAccessibleNodeGtk4* self = FL_ACCESSIBLE_NODE_GTK4(object);

  g_clear_pointer(&self->label, g_free);
  g_clear_pointer(&self->value, g_free);

  G_OBJECT_CLASS(fl_accessible_node_gtk4_parent_class)->finalize(object);
}

static void fl_accessible_node_gtk4_class_init(
    FlAccessibleNodeGtk4Class* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_accessible_node_gtk4_dispose;
  object_class->finalize = fl_accessible_node_gtk4_finalize;
}

static void fl_accessible_node_gtk4_init(FlAccessibleNodeGtk4* self) {
  self->role = GTK_ACCESSIBLE_ROLE_GENERIC;
  self->children = g_ptr_array_new_with_free_func(g_object_unref);
  g_weak_ref_init(&self->parent, nullptr);
}

FlAccessibleNodeGtk4* fl_accessible_node_gtk4_new(int32_t node_id) {
  FlAccessibleNodeGtk4* self = FL_ACCESSIBLE_NODE_GTK4(
      g_object_new(fl_accessible_node_gtk4_get_type(), nullptr));
  self->node_id = node_id;
  return self;
}

void fl_accessible_node_gtk4_update_from_semantics(
    FlAccessibleNodeGtk4* self,
    const FlAccessibilitySemanticsNode* semantics) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self));
  g_return_if_fail(semantics != nullptr);

  self->role = fl_accessible_node_gtk4_resolve_role(semantics);
  g_free(self->label);
  self->label = g_strdup(semantics->label);
  g_free(self->value);
  self->value = g_strdup(semantics->value);
  self->flags = semantics->flags;
  self->actions = semantics->actions;
  self->rect = semantics->rect;
  self->transform = semantics->transform;
  self->text_direction = semantics->text_direction;
  self->text_selection_base = semantics->text_selection_base;
  self->text_selection_extent = semantics->text_selection_extent;
}

void fl_accessible_node_gtk4_set_parent(FlAccessibleNodeGtk4* self,
                                        FlAccessibleNodeGtk4* parent,
                                        gint index_in_parent) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self));
  g_return_if_fail(parent == nullptr || FL_IS_ACCESSIBLE_NODE_GTK4(parent));

  g_weak_ref_set(&self->parent, parent);
  self->index_in_parent = index_in_parent;
}

void fl_accessible_node_gtk4_set_children(FlAccessibleNodeGtk4* self,
                                          GPtrArray* children) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self));

  g_ptr_array_set_size(self->children, 0);
  if (children == nullptr) {
    return;
  }

  for (guint i = 0; i < children->len; ++i) {
    FlAccessibleNodeGtk4* child =
        FL_ACCESSIBLE_NODE_GTK4(g_ptr_array_index(children, i));
    g_ptr_array_add(self->children, g_object_ref(child));
  }
}

int32_t fl_accessible_node_gtk4_get_id(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), -1);
  return self->node_id;
}

GtkAccessibleRole fl_accessible_node_gtk4_get_role(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self),
                       GTK_ACCESSIBLE_ROLE_GENERIC);
  return self->role;
}

const gchar* fl_accessible_node_gtk4_get_label(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), nullptr);
  return self->label;
}

const gchar* fl_accessible_node_gtk4_get_value(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), nullptr);
  return self->value;
}

FlutterSemanticsFlags fl_accessible_node_gtk4_get_flags(
    FlAccessibleNodeGtk4* self) {
  FlutterSemanticsFlags empty = {};
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), empty);
  return self->flags;
}

FlutterSemanticsAction fl_accessible_node_gtk4_get_actions(
    FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self),
                       static_cast<FlutterSemanticsAction>(0));
  return self->actions;
}

FlutterRect fl_accessible_node_gtk4_get_rect(FlAccessibleNodeGtk4* self) {
  FlutterRect empty = {};
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), empty);
  return self->rect;
}

FlutterTransformation fl_accessible_node_gtk4_get_transform(
    FlAccessibleNodeGtk4* self) {
  FlutterTransformation empty = {};
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), empty);
  return self->transform;
}

FlAccessibleNodeGtk4* fl_accessible_node_gtk4_get_parent(
    FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), nullptr);
  return FL_ACCESSIBLE_NODE_GTK4(g_weak_ref_get(&self->parent));
}

gint fl_accessible_node_gtk4_get_index_in_parent(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), -1);
  return self->index_in_parent;
}

GPtrArray* fl_accessible_node_gtk4_get_children(FlAccessibleNodeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBLE_NODE_GTK4(self), nullptr);
  return self->children;
}
