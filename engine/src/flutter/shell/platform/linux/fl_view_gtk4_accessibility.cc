// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#if FLUTTER_LINUX_GTK4

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

typedef struct _FlGtk4AccessibleNode FlGtk4AccessibleNode;
typedef struct _FlGtk4AccessibleNodeClass FlGtk4AccessibleNodeClass;
typedef struct _FlViewGtk4Accessibility FlViewGtk4Accessibility;

struct _FlViewGtk4Accessibility {
  FlView* view;
  FlutterViewId view_id;
  FlAccessibilitySemanticsStore* semantics_store;
  FlGtk4AccessibleNode* root_node;
};

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) && \
    GTK_CHECK_VERSION(4, 10, 0)
#define FL_TYPE_GTK4_ACCESSIBLE_NODE (fl_gtk4_accessible_node_get_type())
#define FL_GTK4_ACCESSIBLE_NODE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), FL_TYPE_GTK4_ACCESSIBLE_NODE, \
                              FlGtk4AccessibleNode))

struct _FlGtk4AccessibleNode {
  GObject parent_instance;

  FlView* view;
  FlutterViewId view_id;
  GtkAccessibleRole role;
  GtkATContext* at_context;

  GPtrArray* children;
  FlGtk4AccessibleNode* parent;
  FlGtk4AccessibleNode* next_sibling;

  gboolean focusable;
  gboolean focused;
  gboolean active;
  gboolean has_bounds;
  int bounds_x;
  int bounds_y;
  int bounds_width;
  int bounds_height;
};

struct _FlGtk4AccessibleNodeClass {
  GObjectClass parent_class;
};

enum {
  PROP_GTK4_ACCESSIBLE_NODE_0,
  PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
  LAST_GTK4_ACCESSIBLE_NODE_PROPERTY,
};

static void fl_gtk4_accessible_node_accessible_iface_init(
    GtkAccessibleInterface* iface);

G_DEFINE_TYPE_WITH_CODE(FlGtk4AccessibleNode,
                        fl_gtk4_accessible_node,
                        G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(GTK_TYPE_ACCESSIBLE,
                                              fl_gtk4_accessible_node_accessible_iface_init))

static GtkAccessibleRole fl_view_gtk4_accessibility_get_role(
    const FlAccessibilitySemanticsNode* semantics) {
  const FlutterSemanticsFlags* flags = &semantics->flags;

  if (flags->is_text_field && !flags->is_read_only) {
    return GTK_ACCESSIBLE_ROLE_TEXT_BOX;
  }
  if (flags->is_header || semantics->heading_level > 0) {
    return GTK_ACCESSIBLE_ROLE_HEADING;
  }
  if (flags->is_image) {
    return GTK_ACCESSIBLE_ROLE_IMG;
  }
  if (flags->is_link) {
    return GTK_ACCESSIBLE_ROLE_LINK;
  }
  if (flags->is_in_mutually_exclusive_group &&
      flags->is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_RADIO;
  }
  if (flags->is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_CHECKBOX;
  }
  if (flags->is_toggled != kFlutterTristateNone) {
    return GTK_ACCESSIBLE_ROLE_TOGGLE_BUTTON;
  }
  if (flags->is_slider) {
    return GTK_ACCESSIBLE_ROLE_SLIDER;
  }
  if (flags->is_button) {
    return GTK_ACCESSIBLE_ROLE_BUTTON;
  }
  if (semantics->child_count > 0) {
    return GTK_ACCESSIBLE_ROLE_GROUP;
  }
  if (semantics->label != nullptr && semantics->label[0] != '\0') {
    return GTK_ACCESSIBLE_ROLE_LABEL;
  }
  return GTK_ACCESSIBLE_ROLE_GENERIC;
}

static void fl_gtk4_accessible_node_set_string_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    const gchar* value) {
  if (value == nullptr || value[0] == '\0') {
    return;
  }

  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_property_init_value(property, &property_value);
  g_value_set_string(&property_value, value);
  fl_gtk_runtime_accessible_update_property_value(GTK_ACCESSIBLE(self), 1,
                                                  properties, &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_bool_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    gboolean value) {
  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_property_init_value(property, &property_value);
  g_value_set_boolean(&property_value, value);
  fl_gtk_runtime_accessible_update_property_value(GTK_ACCESSIBLE(self), 1,
                                                  properties, &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_int_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    gint value) {
  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_property_init_value(property, &property_value);
  g_value_set_int(&property_value, value);
  fl_gtk_runtime_accessible_update_property_value(GTK_ACCESSIBLE(self), 1,
                                                  properties, &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_state_bool(
    FlGtk4AccessibleNode* self,
    GtkAccessibleState state,
    gboolean value) {
  GtkAccessibleState states[] = {state};
  GValue state_value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_state_init_value(state, &state_value);
  g_value_set_boolean(&state_value, value);
  fl_gtk_runtime_accessible_update_state_value(GTK_ACCESSIBLE(self), 1, states,
                                               &state_value);
  g_value_unset(&state_value);
}

static void fl_gtk4_accessible_node_set_state_tristate(
    FlGtk4AccessibleNode* self,
    GtkAccessibleState state,
    GtkAccessibleTristate value) {
  GtkAccessibleState states[] = {state};
  GValue state_value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_state_init_value(state, &state_value);
  g_value_set_enum(&state_value, value);
  fl_gtk_runtime_accessible_update_state_value(GTK_ACCESSIBLE(self), 1, states,
                                               &state_value);
  g_value_unset(&state_value);
}

static gboolean fl_gtk4_accessible_node_get_platform_state(
    GtkAccessible* accessible,
    GtkAccessiblePlatformState state) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  switch (state) {
    case GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE:
      return self->focusable;
    case GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED:
      return self->focused;
    case GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE:
      return self->active;
  }
  return FALSE;
}

static GtkATContext* fl_gtk4_accessible_node_get_at_context(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->at_context != nullptr) {
    return GTK_AT_CONTEXT(g_object_ref(self->at_context));
  }

  GtkWidget* widget = GTK_WIDGET(self->view);
  GdkDisplay* display = gtk_widget_get_display(widget);
  if (display == nullptr) {
    return nullptr;
  }

  self->at_context =
      gtk_at_context_create(self->role, GTK_ACCESSIBLE(self), display);
  return GTK_AT_CONTEXT(g_object_ref(self->at_context));
}

static GtkAccessible* fl_gtk4_accessible_node_get_accessible_parent(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->parent != nullptr) {
    return GTK_ACCESSIBLE(g_object_ref(self->parent));
  }
  return GTK_ACCESSIBLE(g_object_ref(self->view->render_area));
}

static GtkAccessible* fl_gtk4_accessible_node_get_first_accessible_child(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->children->len == 0) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(
      g_ptr_array_index(self->children, 0)));
}

static GtkAccessible* fl_gtk4_accessible_node_get_next_accessible_sibling(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->next_sibling == nullptr) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(self->next_sibling));
}

static gboolean fl_gtk4_accessible_node_get_bounds(GtkAccessible* accessible,
                                                   int* x,
                                                   int* y,
                                                   int* width,
                                                   int* height) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (!self->has_bounds) {
    return FALSE;
  }

  if (x != nullptr) {
    *x = self->bounds_x;
  }
  if (y != nullptr) {
    *y = self->bounds_y;
  }
  if (width != nullptr) {
    *width = self->bounds_width;
  }
  if (height != nullptr) {
    *height = self->bounds_height;
  }
  return TRUE;
}

static void fl_gtk4_accessible_node_dispose(GObject* object) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  g_clear_object(&self->at_context);
  g_clear_pointer(&self->children, g_ptr_array_unref);

  G_OBJECT_CLASS(fl_gtk4_accessible_node_parent_class)->dispose(object);
}

static void fl_gtk4_accessible_node_get_property(GObject* object,
                                                 guint property_id,
                                                 GValue* value,
                                                 GParamSpec* pspec) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  switch (property_id) {
    case PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE:
      g_value_set_enum(value, self->role);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
      break;
  }
}

static void fl_gtk4_accessible_node_class_init(FlGtk4AccessibleNodeClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->get_property = fl_gtk4_accessible_node_get_property;
  object_class->dispose = fl_gtk4_accessible_node_dispose;

  g_object_class_install_property(
      object_class, PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
      g_param_spec_enum("accessible-role", nullptr, nullptr,
                        GTK_TYPE_ACCESSIBLE_ROLE, GTK_ACCESSIBLE_ROLE_GENERIC,
                        static_cast<GParamFlags>(G_PARAM_READABLE |
                                                G_PARAM_STATIC_STRINGS)));
}

static void fl_gtk4_accessible_node_init(FlGtk4AccessibleNode* self) {
  self->children = g_ptr_array_new_with_free_func(g_object_unref);
}

static void fl_gtk4_accessible_node_accessible_iface_init(
    GtkAccessibleInterface* iface) {
  iface->get_at_context = fl_gtk4_accessible_node_get_at_context;
  iface->get_platform_state = fl_gtk4_accessible_node_get_platform_state;
  iface->get_accessible_parent = fl_gtk4_accessible_node_get_accessible_parent;
  iface->get_first_accessible_child =
      fl_gtk4_accessible_node_get_first_accessible_child;
  iface->get_next_accessible_sibling =
      fl_gtk4_accessible_node_get_next_accessible_sibling;
  iface->get_bounds = fl_gtk4_accessible_node_get_bounds;
}

static FlGtk4AccessibleNode* fl_gtk4_accessible_node_new(
    FlView* view,
    FlutterViewId view_id,
    const FlAccessibilitySemanticsNode* semantics) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(
      g_object_new(FL_TYPE_GTK4_ACCESSIBLE_NODE, nullptr));
  self->view = view;
  self->view_id = view_id;
  self->role = fl_view_gtk4_accessibility_get_role(semantics);

  const FlutterSemanticsFlags* flags = &semantics->flags;
  const gboolean is_enabled = flags->is_enabled != kFlutterTristateFalse;
  const gboolean is_focused = flags->is_focused == kFlutterTristateTrue;
  const gboolean is_hidden = flags->is_hidden;
  const gboolean is_selected = flags->is_selected == kFlutterTristateTrue;
  const gboolean is_expanded = flags->is_expanded == kFlutterTristateTrue;
  const gboolean is_required = flags->is_required == kFlutterTristateTrue;
  const gboolean is_read_only = flags->is_text_field && flags->is_read_only;
  const gboolean is_multiline = flags->is_text_field && flags->is_multiline;

  self->focusable = is_enabled &&
                    (semantics->actions != 0 ||
                     flags->is_button || flags->is_text_field ||
                     flags->is_link || flags->is_slider ||
                     flags->is_checked != kFlutterCheckStateNone ||
                     flags->is_toggled != kFlutterTristateNone);
  self->focused = is_focused;
  self->active = is_focused;
  self->has_bounds = TRUE;
  self->bounds_x = static_cast<int>(semantics->rect.left +
                                    semantics->transform.transX);
  self->bounds_y = static_cast<int>(semantics->rect.top +
                                    semantics->transform.transY);
  self->bounds_width = static_cast<int>(semantics->rect.right -
                                         semantics->rect.left);
  self->bounds_height = static_cast<int>(semantics->rect.bottom -
                                          semantics->rect.top);

  const gchar* label = semantics->label;
  if ((label == nullptr || label[0] == '\0') && semantics->value != nullptr &&
      semantics->value[0] != '\0' && semantics->child_count == 0) {
    label = semantics->value;
  }
  fl_gtk4_accessible_node_set_string_property(self,
                                              GTK_ACCESSIBLE_PROPERTY_LABEL,
                                              label);

  if (semantics->hint != nullptr || semantics->tooltip != nullptr) {
    g_autofree gchar* description = nullptr;
    if (semantics->hint != nullptr && semantics->tooltip != nullptr &&
        semantics->hint[0] != '\0' && semantics->tooltip[0] != '\0') {
      description = g_strjoin("\n", semantics->hint, semantics->tooltip,
                              nullptr);
    } else if (semantics->hint != nullptr && semantics->hint[0] != '\0') {
      description = g_strdup(semantics->hint);
    } else if (semantics->tooltip != nullptr && semantics->tooltip[0] != '\0') {
      description = g_strdup(semantics->tooltip);
    }
    fl_gtk4_accessible_node_set_string_property(
        self, GTK_ACCESSIBLE_PROPERTY_DESCRIPTION, description);
  }

  fl_gtk4_accessible_node_set_string_property(self,
                                              GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT,
                                              semantics->value);
  if (semantics->heading_level > 0) {
    fl_gtk4_accessible_node_set_int_property(self, GTK_ACCESSIBLE_PROPERTY_LEVEL,
                                             semantics->heading_level);
  }

  if (flags->is_text_field) {
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_READ_ONLY, is_read_only);
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_MULTI_LINE, is_multiline);
  }
  if (is_required) {
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_REQUIRED, TRUE);
  }
  if (is_hidden) {
    fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_HIDDEN,
                                           TRUE);
  }
  if (!is_enabled) {
    fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_DISABLED,
                                           TRUE);
  }
  if (is_selected) {
    fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_SELECTED,
                                           TRUE);
  }
  if (is_expanded) {
    fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_EXPANDED,
                                           TRUE);
  }
  if (flags->is_checked != kFlutterCheckStateNone ||
      flags->is_toggled != kFlutterTristateNone) {
    GtkAccessibleTristate checked_value = GTK_ACCESSIBLE_TRISTATE_FALSE;
    if (flags->is_checked == kFlutterCheckStateTrue ||
        flags->is_toggled == kFlutterTristateTrue) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_TRUE;
    } else if (flags->is_checked == kFlutterCheckStateMixed) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_MIXED;
    }
    fl_gtk4_accessible_node_set_state_tristate(
        self, GTK_ACCESSIBLE_STATE_CHECKED, checked_value);
  }
  if (flags->is_toggled != kFlutterTristateNone &&
      self->role == GTK_ACCESSIBLE_ROLE_TOGGLE_BUTTON) {
    fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_PRESSED,
                                           flags->is_toggled ==
                                               kFlutterTristateTrue);
  }

  return self;
}

static void fl_gtk4_accessible_node_attach_children(
    FlGtk4AccessibleNode* parent,
    GPtrArray* children) {
  for (guint i = 0; i < children->len; i++) {
    FlGtk4AccessibleNode* child =
        FL_GTK4_ACCESSIBLE_NODE(g_ptr_array_index(children, i));
    FlGtk4AccessibleNode* next_sibling =
        i + 1 < children->len
            ? FL_GTK4_ACCESSIBLE_NODE(g_ptr_array_index(children, i + 1))
            : nullptr;
    child->parent = parent;
    child->next_sibling = next_sibling;
    g_ptr_array_add(parent->children, child);
    gtk_accessible_set_accessible_parent(GTK_ACCESSIBLE(child),
                                         GTK_ACCESSIBLE(parent),
                                         GTK_ACCESSIBLE(next_sibling));
  }
}

static FlGtk4AccessibleNode* fl_view_gtk4_accessibility_build_native_node(
    FlViewGtk4Accessibility* self,
    const FlAccessibilitySemanticsNode* semantics,
    GHashTable* visited) {
  if (semantics == nullptr) {
    return nullptr;
  }

  if (g_hash_table_contains(visited, GINT_TO_POINTER(semantics->id))) {
    return nullptr;
  }
  g_hash_table_add(visited, GINT_TO_POINTER(semantics->id));

  FlGtk4AccessibleNode* node =
      fl_gtk4_accessible_node_new(self->view, self->view_id, semantics);

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
          fl_view_gtk4_accessibility_build_native_node(self, child, visited);
      if (child_node != nullptr) {
        g_ptr_array_add(children, child_node);
      }
    }
  }

  fl_gtk4_accessible_node_attach_children(node, children);
  return node;
}
#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) &&
        // GTK_CHECK_VERSION(4, 10, 0)

static const gchar* fl_view_gtk4_accessibility_get_root_label(
    FlViewGtk4Accessibility* self) {
  if (self->semantics_store == nullptr) {
    return "Flutter view";
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr || root->label == nullptr || root->label[0] == '\0') {
    return "Flutter view";
  }
  return root->label;
}

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) && \
    GTK_CHECK_VERSION(4, 10, 0)
static void fl_view_gtk4_accessibility_rebuild_native_tree(
    FlViewGtk4Accessibility* self) {
  g_clear_object(&self->root_node);

  if (self->semantics_store == nullptr ||
      !fl_accessibility_semantics_store_has_root(self->semantics_store)) {
    return;
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr) {
    return;
  }

  g_autoptr(GHashTable) visited =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  self->root_node =
      fl_view_gtk4_accessibility_build_native_node(self, root, visited);
  if (self->root_node != nullptr) {
    gtk_accessible_set_accessible_parent(GTK_ACCESSIBLE(self->root_node),
                                         GTK_ACCESSIBLE(self->view->render_area),
                                         nullptr);
  }
}
#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) &&
        // GTK_CHECK_VERSION(4, 10, 0)

FlViewGtk4Accessibility* fl_view_gtk4_accessibility_new(FlView* view,
                                                        FlutterViewId view_id) {
  FlViewGtk4Accessibility* self = g_new0(FlViewGtk4Accessibility, 1);
  self->view = view;
  self->view_id = view_id;
  self->semantics_store = fl_accessibility_semantics_store_new(view_id);
  return self;
}

void fl_view_gtk4_accessibility_dispose(FlViewGtk4Accessibility* self) {
  if (self == nullptr) {
    return;
  }

  g_clear_object(&self->root_node);
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
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) && \
    GTK_CHECK_VERSION(4, 10, 0)
  fl_view_gtk4_accessibility_rebuild_native_tree(self);
  fl_view_gtk4_accessibility_update_accessible_name(self);
#else
  fl_view_gtk4_accessibility_update_accessible_name(self);
  fl_view_gtk4_accessibility_update_accessible_tree(self);
#endif
}

void fl_view_gtk4_accessibility_handle_native_update(
    FlViewGtk4Accessibility* self,
    const FlutterSemanticsUpdate2* update) {
  fl_view_gtk4_accessibility_handle_update(self, update);
}

void fl_view_gtk4_accessibility_update_accessible_name(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

  const gchar* label = fl_view_gtk4_accessibility_get_root_label(self);
  GtkAccessibleProperty property = GTK_ACCESSIBLE_PROPERTY_LABEL;
  GtkAccessibleProperty properties[] = {property};
  GValue value = G_VALUE_INIT;
  fl_gtk_runtime_accessible_property_init_value(property, &value);
  g_value_set_string(&value, label);
  fl_gtk_runtime_accessible_update_property_value(GTK_ACCESSIBLE(self->view), 1,
                                                  properties, &value);
  g_value_unset(&value);
}

void fl_view_gtk4_accessibility_update_accessible_tree(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE) && \
    GTK_CHECK_VERSION(4, 10, 0)
  fl_view_gtk4_accessibility_rebuild_native_tree(self);
#else
  // The current GTK4 accessibility backend stays widget-backed, but this
  // helper is the seam for a future native GtkAccessible tree implementation.
  fl_gtk_runtime_accessible_set_accessible_parent(
      GTK_ACCESSIBLE(self->view->render_area), GTK_ACCESSIBLE(self->view),
      nullptr);
#endif
}

void fl_view_gtk4_accessibility_send_announcement(
    FlViewGtk4Accessibility* self,
    const char* message,
    gboolean assertive) {
  g_return_if_fail(self != nullptr);

  fl_gtk_runtime_accessible_announce(
      GTK_ACCESSIBLE(self->view), message, assertive ? 1 : 0);
}

#endif  // FLUTTER_LINUX_GTK4
